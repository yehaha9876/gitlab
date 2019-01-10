# frozen_string_literal: true

module QA
  module EE
    module Page
      module Admin
        module Settings
          class Templates < QA::Page::Base
            include ::QA::Page::Settings::Common
            include ::QA::Page::Component::Select2

            view 'ee/app/views/admin/application_settings/_custom_templates_form.html.haml' do
              element :custom_project_template_section
              element :custom_project_templates
              element :save_changes_button
            end

            def choose_custom_project_template(path)
              expand_section(:custom_project_template_section)

              within_element(:custom_project_template_select) do
                clear_current_selection_if_present
              end
              click_element :custom_project_template_select
              search_and_select(path)
              click_element :save_changes_button
            end
          end
        end
      end
    end
  end
end
