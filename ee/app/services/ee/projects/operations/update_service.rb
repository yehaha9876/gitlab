# frozen_string_literal: true

module EE
  module Projects
    module Operations
      module UpdateService
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        override :project_update_params
        def project_update_params
          super.merge(tracing_setting_params)
        end

        private

        def tracing_setting_params
          attr = params[:tracing_setting_attributes]
          return {} unless attr

          destroy = attr[:external_url].blank?

          { tracing_setting_attributes: attr.merge(_destroy: destroy) }
        end
      end
    end
  end
end