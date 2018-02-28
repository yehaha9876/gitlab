module EE
  module Import
    module GithubController
      extend ::Gitlab::Utils::Override

      override :extra_project_attrs
      def extra_project_attrs
        super.merge(ci_cd_only: params[:ci_cd_only])
      end

      override :new_import_url
      def new_import_url
        append_extra_params(super)
      end

      override :status_import_url
      def status_import_url
        append_extra_params(super)
      end

      override :callback_import_url
      def callback_import_url
        append_extra_params(super)
      end

      private

      def append_extra_params(url)
        url += "?ci_cd_only=true" if params[:ci_cd_only].present?

        url
      end
    end
  end
end
