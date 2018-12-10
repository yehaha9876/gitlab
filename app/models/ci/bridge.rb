# frozen_string_literal: true

module Ci
  class Bridge < CommitStatus
    include Importable
    include AfterCommitQueue
    include TokenAuthenticatable
    include Gitlab::Utils::StrongMemoize

    belongs_to :project, inverse_of: :builds
    has_many :sourced_pipelines, class_name: Ci::Sources::Pipeline, foreign_key: :source_job_id

    serialize :options # rubocop:disable Cop/ActiveRecordSerialize
    validates :ref, presence: true

    before_save :ensure_token
    before_destroy { unscoped_project }

    add_authentication_token_field :token, encrypted: true

    def self.retry(bridge, current_user)
      raise NotImplementedError
    end

    state_machine :status do
      after_transition any => [:pending] do |bridge|
        bridge.run_after_commit do
        end
      end

      after_transition pending: :running do |bridge|
        bridge.run_after_commit do
        end
      end

      after_transition any => [:success, :failed, :canceled] do |bridge|
        bridge.run_after_commit do
        end
      end

      after_transition any => [:success] do |bridge|
        bridge.run_after_commit do
        end
      end

      before_transition any => [:failed] do |bridge|
      end

      after_transition pending: :running do |bridge|
      end
    end

    def tags
      [:bridge]
    end

    def detailed_status(current_user)
      Gitlab::Ci::Status::Bridge::Factory
        .new(self, current_user)
        .fabricate!
    end

    def predefined_variables
      raise NotImplementedError
    end

    def execute_hooks
      raise NotImplementedError
    end
  end
end
