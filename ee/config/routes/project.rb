# frozen_string_literal: true

constraints(::Constraints::ProjectUrlConstrainer.new) do
  scope(path: '*namespace_id',
        as: :namespace,
        namespace_id: Gitlab::PathRegex.full_namespace_route_regex) do
    scope(path: ':project_id',
          constraints: { project_id: Gitlab::PathRegex.project_route_regex },
          module: :projects,
          as: :project) do

      resource :tracing, only: [:show]

      namespace :settings do
        resource :operations, only: [:show, :update, :create]
      end

      resources :autocomplete_sources, only: [] do
        collection do
          get 'epics'
        end
      end

      resources :ide_terminals, only: [:create, :show], constraints: { id: /\d+/, format: :json } do
        member do
          post :cancel
          post :retry
          get :terminal, constraints: { format: nil }
          get '/terminal.ws/authorize', to: 'ide_terminals#terminal_websocket_authorize', constraints: { format: nil }
        end

        collection do
          post :check_config
        end
      end
    end
  end
end
