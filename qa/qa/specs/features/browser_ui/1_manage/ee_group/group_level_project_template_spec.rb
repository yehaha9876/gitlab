# frozen_string_literal: true
require 'securerandom'

module QA
  context :manage do
    describe 'Group level project template' do
      it 'user creates a project from a group level project template' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        template_container_group = "template-container-group-#{SecureRandom.hex(8)}"

        template_project_1 = Resource::Project.fabricate! do |project|
          project.name = 'template-project-1'
          project.group_path = template_container_group
        end

        template_project_2 = Resource::Project.fabricate! do |project|
          project.name = 'template-project-2'
          project.group_path = template_container_group
        end

        Page::Main::Menu.perform(&:go_to_groups)

        Page::Dashboard::Groups.perform { |page| page.go_to_group(Runtime::Namespace.sandbox_name) }

        Page::Project::Menu.perform(&:go_to_settings)

        Page::Group::Settings::Main.perform do |settings|
          settings.expand_general_settings do |page|
            page.choose_custom_project_template("#{Runtime::Namespace.sandbox_name} / #{template_container_group}")
          end
        end

        Page::Main::Menu.perform(&:go_to_groups)

        Page::Dashboard::Groups.perform { |page| page.go_to_group(Runtime::Namespace.sandbox_name) }

        Page::Group::Show.perform(&:go_to_new_project)

        Page::Project::New.perform do |page|
          page.go_to_create_from_template_group_tab
          expect(page.group_template_tab_badge_text).to eq "2"
          expect(page).to have_text(template_container_group)
          expect(page).to have_text(template_project_1.name)
          expect(page).to have_text(template_project_2.name)
        end
      end
    end
  end
end
