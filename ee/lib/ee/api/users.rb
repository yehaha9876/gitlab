module EE
  module API
    module Users
      extend ActiveSupport::Concern

      prepended do
        resource :users do
          desc 'Create a subscription for the user' do
            success ::EE::API::Entities::GitlabSubscription
          end
          params do
            requires :seats, type: Integer, desc: 'The number of seats purchased'
            requires :start_date, type: Date, desc: 'The date when subscription was started'
            requires :end_date, type: Date, desc: 'The date when subscription expires'
          end
          post ":id/subscription" do
            authenticated_as_admin!

            user = ::User.find_by(id: params[:id])
            not_found!('User') unless user

            subscription_params = declared_params(include_missing: false)
            subscription = user.namespace.create_gitlab_subscription(subscription_params)
            if subscription.persisted?
              present subscription, with: ::EE::API::Entities::GitlabSubscription
            else
              render_validation_error!(subscription)
            end
          end
        end
      end
    end
  end
end
