module QA
  module Page
    module Admin
      module Settings
        class Main < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/admin/application_settings/show.html.haml' do
            element :terms_settings
          end
        end
      end
    end
  end
end
