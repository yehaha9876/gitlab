module EE
  module Note
    extend ActiveSupport::Concern

    def for_epic?
      noteable.is_a?(Epic)
    end

    def for_project_noteable?
      !for_epic? && super
    end

    def touch_noteable
      # We re-use the object returned by the normal method, removing the need
      # for re-querying the noteable (and thus losing any changes).
      #
      # `super` will return `nil` when used for a Commit note, hence we're using
      # the `&.` operator here.
      noteable = super

      if noteable.is_a?(Elastic::ApplicationSearch)
        run_after_commit do
          noteable&.schedule_elastic_search_index_for_update
        end
      end

      noteable
    end
  end
end
