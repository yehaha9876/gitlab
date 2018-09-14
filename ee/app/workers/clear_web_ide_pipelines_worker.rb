# frozen_string_literal: true

class ClearWebIdePipelinesWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    return unless License.feature_available?(:webide)

    Ci::Pipeline.webide
                .finished
                .where('finished_at < ?', Time.now.beginning_of_day)
                .delete_all
  end
end
