# frozen_string_literal: true

namespace :jira_connect do
  get 'app_descriptor' => 'app_descriptor#show'

  namespace :events do
    post 'installed'
    post 'uninstalled'
    post 'enabled'
    post 'disabled'
  end
end
