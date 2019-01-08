# frozen_string_literal: true

module EE
  module UserCalloutEnums
    extend ActiveSupport::Concern

    class_methods do
      extend ::Gitlab::Utils::Override

      override :feature_names
      def feature_names
        super.merge(gold_trial: 4, canary_deployment: 5)
      end
    end
  end
end
