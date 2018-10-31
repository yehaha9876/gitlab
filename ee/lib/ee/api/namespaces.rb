module EE
  module API
    module Namespaces
      extend ActiveSupport::Concern

      prepended do
        resource :namespaces do
          desc 'Update a namespace' do
            success Entities::Namespace
          end
          params do
            optional :plan, type: String, desc: "Namespace or Group plan"
            optional :shared_runners_minutes_limit, type: Integer, desc: "Pipeline minutes quota for this namespace"
            optional :trial_ends_on, type: Date, desc: "Trial expiration date"
          end
          put ':id' do
            authenticated_as_admin!

            namespace = find_namespace(params[:id])
            trial_ends_on = params[:trial_ends_on]

            break not_found!('Namespace') unless namespace
            break bad_request!("Invalid trial expiration date") if trial_ends_on&.past?

            if namespace.update(declared_params)
              present namespace, with: ::API::Entities::Namespace, current_user: current_user
            else
              render_validation_error!(namespace)
            end
          end

          desc 'Create a subscription for the namespace' do
            success ::EE::API::Entities::GitlabSubscription
          end
          params do
            requires :id, type: Integer, desc: 'The ID of the namespace'
            requires :seats, type: Integer, desc: 'The number of seats purchased'
            requires :plan_code, type: String, desc: 'The code of the purchased plan'
            requires :plan_name, type: String, desc: 'The name of the purchased plan'
            requires :start_date, type: Date, desc: 'The date when subscription was started'
            requires :end_date, type: Date, desc: 'The date when subscription expires'

            optional :trial, type: Grape::API::Boolean, desc: 'Wether the subscription is trial'
          end
          post ":id/gitlab_subscription" do
            authenticated_as_admin!

            namespace = find_namespace!(params[:id])

            subscription_params = declared_params(include_missing: false)
            subscription = namespace.create_gitlab_subscription(subscription_params)
            if subscription.persisted?
              present subscription, with: ::EE::API::Entities::GitlabSubscription
            else
              render_validation_error!(subscription)
            end
          end

          desc 'Returns the subscription for the namespace' do
            success ::EE::API::Entities::GitlabSubscription
          end
          params do
            requires :id, type: Integer, desc: 'The ID of the namespace'
          end
          get ":id/gitlab_subscription" do
            namespace = find_namespace!(params[:id])
            authorize! :admin_namespace, namespace

            present namespace.gitlab_subscription || {}, with: ::EE::API::Entities::GitlabSubscription
          end

          desc 'Update the subscription for the namespace' do
            success ::EE::API::Entities::GitlabSubscription
          end
          params do
            optional :seats, type: Integer, desc: 'The number of seats purchased'
            optional :plan_code, type: String, desc: 'The code of the purchased plan'
            optional :plan_name, type: String, desc: 'The name of the purchased plan'
            optional :start_date, type: Date, desc: 'The date when subscription was started'
            optional :end_date, type: Date, desc: 'The date when subscription expires'
            optional :trial, type: Grape::API::Boolean, desc: 'Wether the subscription is trial'
          end
          put ":id/gitlab_subscription" do
            authenticated_as_admin!

            namespace = find_namespace!(params[:id])
            subscription = namespace.gitlab_subscription

            break not_found!('GitlabSubscription') unless subscription

            if subscription.update(declared_params)
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
