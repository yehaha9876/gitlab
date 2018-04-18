module EE
  module Search
    module GroupService
      extend ::Gitlab::Utils::Override

      private

      override :allowed_scopes
      def allowed_scopes
        super.reject { |scope| scope == 'epics' }
      end
    end
  end
end
