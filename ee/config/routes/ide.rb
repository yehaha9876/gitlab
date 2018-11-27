scope path: 'ide', module: :ide do
  resources :terminals, only: [:create], defaults: { format: :json } do
    collection do
      post :check_config
    end
  end
end
