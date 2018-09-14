# frozen_string_literal: true

module EE
  module Ci
    module CreatePipelineService
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      override :related_merge_requests
      def related_merge_requests
        return ::MergeRequest.none if pipeline.webide? # rubocop: disable CodeReuse/ActiveRecord

        super
      end
    end
  end
end
