# frozen_string_literal: true

constraints(::Constraints::ProjectUrlConstrainer.new) do
  scope(path: '*namespace_id',
        as: :namespace,
        namespace_id: Gitlab::PathRegex.full_namespace_route_regex) do
    scope(path: ':project_id',
          constraints: { project_id: Gitlab::PathRegex.project_route_regex },
          as: :project) do
      scope path: 'ide', module: :ide do
        resources :terminals, only: [:create, :show], defaults: { format: :json } do
          member do
            post :cancel
            post :retry
            get :terminal
            get '/terminal.ws/authorize', to: 'terminals#terminal_websocket_authorize', constraints: { format: nil }
          end

          collection do
            post :check_config
          end
        end
      end
    end
  end
end
