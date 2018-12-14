# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module New
          def self.prepended(page)
            page.module_eval do
              view 'ee/app/views/projects/_project_templates.html.haml' do
                element :group_templates_tab
                element :group_template_tab_badge
              end
            end
          end

          def go_to_create_from_template_group_tab
            go_to_create_from_template
            click_element(:group_templates_tab)
          end

          def group_template_tab_badge_text
            find_element(:group_template_tab_badge).text
          end
        end
      end
    end
  end
end
