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
