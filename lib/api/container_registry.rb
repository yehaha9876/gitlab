module API
  class ContainerRegistry < Grape::API
    resource :container_registry do
      content_type :json, "application/vnd.docker.distribution.events.v1+json"
      format :json

      # before { authorize! :container_registry, user_project }

      params do
        requires :events, type: Array
      end

      post 'events' do
        status 200

        ::ContainerRegistry::EventHandler.new(params['events']).execute

        { status: 'ok' }
      end
    end
  end
end
