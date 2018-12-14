# frozen_string_literal: true

module QA
  module Page
    module Group
      module Settings
        class Main < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/groups/edit.html.haml' do
            element :general_settings
          end

          def expand_general_settings(&block)
            expand_section(:general_settings)
            General.perform(&block)
          end
        end
      end
    end
  end
end
