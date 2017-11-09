require 'constraints/group_url_constrainer'

resources :groups, only: [:index, :new, :create] do
  post :preview_markdown
end

constraints(GroupUrlConstrainer.new) do
  scope(path: 'groups/*id',
        controller: :groups,
        constraints: { id: Gitlab::PathRegex.full_namespace_route_regex, format: /(html|json|atom)/ }) do
    scope(path: '-') do
      get :edit, as: :edit_group
      get :issues, as: :issues_group
      get :merge_requests, as: :merge_requests_group
      get :projects, as: :projects_group
      get :activity, as: :activity_group
      get :subgroups, as: :subgroups_group ## EE-specific
    end

    get '/', action: :show, as: :group_canonical
  end

  scope(path: 'groups/*group_id/-',
        module: :groups,
        as: :group,
        constraints: { group_id: Gitlab::PathRegex.full_namespace_route_regex }) do
    namespace :settings do
      resource :ci_cd, only: [:show], controller: 'ci_cd'
    end

    resources :variables, only: [:index, :show, :update, :create, :destroy]

    resources :children, only: [:index]

    resources :labels, except: [:show] do
      post :toggle_subscription, on: :member
    end

    resources :milestones, constraints: { id: /[^\/]+/ }, only: [:index, :show, :edit, :update, :new, :create] do
      member do
        get :merge_requests
        get :participants
        get :labels
      end
    end

    resource :avatar, only: [:destroy]

    resources :group_members, only: [:index, :create, :update, :destroy], concerns: :access_requestable do
      post :resend_invite, on: :member
      delete :leave, on: :collection
      patch :override, on: :member ## EE-specific
    end

    ## EE-specific
    resource :analytics, only: [:show]
    resource :ldap, only: [] do
      member do
        put :sync
      end
    end

    resources :ldap_group_links, only: [:index, :create, :destroy]

    resource :notification_setting, only: [:update]
    resources :audit_events, only: [:index]
    resources :pipeline_quota, only: [:index]

    resources :hooks, only: [:index, :create, :destroy], constraints: { id: /\d+/ } do
      member do
        get :test
      end
    end

    resources :billings, only: [:index]
    resources :boards, only: [:index, :show, :create, :update, :destroy]
    resources :epics do
      member do
        get :realtime_changes
      end
    end

    legacy_ee_group_boards_redirect = redirect do |params, request|
      path = "/groups/#{params[:group_id]}/-/boards"
      path << "/#{params[:extra_params]}" if params[:extra_params].present?
      path << "?#{request.query_string}" if request.query_string.present?
      path
    end
    get 'boards(/*extra_params)', as: :legacy_ee_group_boards_redirect, to: legacy_ee_group_boards_redirect
    ## EE-specific
  end

  scope(path: '*id',
        as: :group,
        constraints: { id: Gitlab::PathRegex.full_namespace_route_regex, format: /(html|json|atom)/ },
        controller: :groups) do
    get '/', action: :show
    patch '/', action: :update
    put '/', action: :update
    delete '/', action: :destroy
  end

  # Legacy paths should be defined last, so they would be ignored if routes with
  # one of the previously reserved words exist.
  scope(path: 'groups/*group_id') do
    Gitlab::Routing.redirect_legacy_paths(self, :labels, :milestones, :group_members,
                                          :edit, :issues, :merge_requests, :projects,
                                          :activity)

    ## EE-specific
    Gitlab::Routing.redirect_legacy_paths(self, :analytics, :ldap, :ldap_group_links,
                                          :notification_setting, :audit_events,
                                          :pipeline_quota, :hooks, :boards)
    ## EE-specific
  end
end
