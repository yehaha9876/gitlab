# frozen_string_literal: true

module Ci
  class BuildSchedule < ActiveRecord::Base
    extend Gitlab::Ci::Model
    include Importable
    include AfterCommitQueue

    belongs_to :build

    after_create unless: :importing? do |build|
      run_after_commit { Ci::PlayBuildWorker.perform_at(self.execute_at, self.build_id) }
    end

    def execute_in
      self.execute_at - Time.now
    end
  end
end
