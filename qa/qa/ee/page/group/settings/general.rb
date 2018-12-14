# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Settings
          module General
            include QA::Page::Component::Select2
            def self.prepended(page)
              page.module_eval do
                view 'ee/app/views/groups/_custom_project_templates_setting.html.haml' do
                  element :custom_project_template_select
                  element :save_changes_button
                end
              end
            end

            def choose_custom_project_template(path)
              remove_custom_project_template_current_selection_if_present
              click_element :custom_project_template_select
              select_item(path)
              click_element :save_changes_button
            end

            def remove_custom_project_template_current_selection_if_present
              within_element(:custom_project_template_select) do
                if has_css?('a > abbr.select2-search-choice-close', visible: true, wait: 1.0)
                  find('a > abbr.select2-search-choice-close').click
                end
              end
            end
          end
        end
      end
    end
  end
end
