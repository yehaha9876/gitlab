module QA
  module Page
    module Admin
      module Settings
        class Repository < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/admin/application_settings/_repository_storage.html.haml' do
            element :repository_settings
          end

          def expand_repository_storage(&block)
            expand_section(:repository_settings) do
              Component::RepositoryStorage.perform(&block)
            end
          end
        end
      end
    end
  end
end
