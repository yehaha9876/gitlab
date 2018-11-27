# frozen_string_literal: true

module Gitlab
  module Ci
    class WebideYamlProcessor < ::Gitlab::Ci::YamlProcessor
      TERMINAL_JOB_NAME = :terminal
      ALLOWED_ATTRIBUTES = %i[image before_script script variables].freeze

      private

      def initial_parsing
        @stages = @ci_config.stages
        @jobs = ::Gitlab::Ci::Config::Normalizer.new(@ci_config.jobs).normalize_jobs

        validate_unique_terminal_job!
        validate_terminal_job_presence!
        validate_terminal_config_attributes!
      end

      def validate_unique_terminal_job!
        return unless (@config.keys - [TERMINAL_JOB_NAME]).any?

        raise ::Gitlab::Ci::YamlProcessor::ValidationError, "Only job '#{TERMINAL_JOB_NAME}' can be present in the configuration"
      end

      def validate_terminal_job_presence!
        if @config[TERMINAL_JOB_NAME].blank?
          raise ::Gitlab::Ci::YamlProcessor::ValidationError, "The job '#{TERMINAL_JOB_NAME}' is required to be present in the configuration"
        end
      end

      def validate_terminal_config_attributes!
        unless valid_terminal_job_attributes?
          raise ::Gitlab::Ci::YamlProcessor::ValidationError, "Only the attributes: #{ALLOWED_ATTRIBUTES.join(', ')} are allowed"
        end
      end

      def valid_terminal_job_attributes?
        (@config[TERMINAL_JOB_NAME].keys - ALLOWED_ATTRIBUTES).empty?
      end
    end
  end
end
