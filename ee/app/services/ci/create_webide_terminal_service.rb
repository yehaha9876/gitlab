# frozen_string_literal: true

module Ci
  class CreateWebideTerminalService < ::BaseService
    include ::Gitlab::Utils::StrongMemoize

    TerminalCreationError = Class.new(StandardError)

    attr_reader :pipeline

    def execute
      @pipeline = build_pipeline

      begin
        check_access!
        validate_data!
        config_processor = validate_config!
        load_stages(config_processor)

        pipeline.save!
        pipeline_created_counter.increment(source: :webide)
        pipeline.process!
      rescue TerminalCreationError => e
        error(e.message)
      rescue ActiveRecord::RecordInvalid => e
        error("Failed to persist the pipeline: #{e}")
      end

      pipeline
    end

    private

    def check_access!
      unless project.builds_enabled?
        raise TerminalCreationError, 'Pipelines are disabled!'
      end

      unless can?(current_user, :ide_terminal_enabled, project)
        raise TerminalCreationError, 'Insufficient permissions to create a terminal'
      end

      if terminal_running?
        raise TerminalCreationError, 'There is already a terminal running'
      end
    end

    def validate_data!
      if pipeline.sha.blank?
        raise TerminalCreationError, 'Invalid ref'
      end

      unless branch_exists?
        raise TerminalCreationerror, 'Invalid branch'
      end
    end

    def validate_config!
      result = WebideConfigValidatorService.new(project, current_user, project: project, sha: sha).execute

      raise TerminalCreationError, result[:message] if result[:status] != :success

      result[:config_processor]
    end

    def build_pipeline
      Ci::Pipeline.new(
        project: project,
        user: current_user,
        source: :webide,
        config_source: :webide_source,
        ref: ref,
        sha: sha,
        before_sha: Gitlab::Git::BLANK_SHA,
        protected: protected_ref?, # We fill this value, but we want to be able to create terminals in protected branches
        variables_attributes: Array(params[:variables_attributes])
      )
    end

    def load_stages(config_processor)
      webide_stage_seeds(config_processor).each do |stage|
        pipeline.stages << stage.to_resource
      end
    end

    def pipeline_created_counter
      @pipeline_created_counter ||= Gitlab::Metrics
        .counter(:pipelines_created_total, "Counter of pipelines created")
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def terminal_running?
      project.pipelines.where(source: :webide, status: :running, user: current_user).any?
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def error(message)
      pipeline.errors.add(:base, message)
    end

    def ref
      strong_memoize(:ref) do
        Gitlab::Git.ref_name(params[:ref])
      end
    end

    def branch_exists?
      project.repository.branch_exists?(ref)
    end

    def sha
      project.commit(params[:ref]).try(:id)
    end

    def protected_ref?
      project.protected_for?(ref)
    end

    def webide_stage_seeds(config_processor)
      seeds = config_processor.stages_attributes.map do |attributes|
        ::Gitlab::Ci::Pipeline::Seed::Stage.new(pipeline, attributes)
      end

      seeds.select(&:included?)
    end
  end
end
