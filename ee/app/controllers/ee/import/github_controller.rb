module EE
  module Import
    module GithubController
      extend ::Gitlab::Utils::Override

      override :extra_project_attrs
      def extra_project_attrs
        super.merge({
          ci_cd_only: params[:ci_cd_only]
        })
      end
    end
  end
end
