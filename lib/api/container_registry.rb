module API
  class ContainerRegistry < Grape::API
    resource :container_registry do
      # before { authorize! :container_registry, user_project }
      params do
        # requires :events, type: Array, desc: 'Events'
      end

      post 'events' do
        status 200
        {status: 'ok'}
      end
    end
  end
end
