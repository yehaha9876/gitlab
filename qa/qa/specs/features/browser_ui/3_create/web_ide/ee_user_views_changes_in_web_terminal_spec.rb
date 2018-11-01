# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Web IDE web terminal' do
      before do
        @runner_name = "qa-runner-#{Time.now.to_i}"
      end

      after do
        # Remove the runner even if the test fails
        Service::Runner.new(@runner_name).remove!
      end

      it 'user makes changes in the Web IDE and views changes in a web terminal' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        @project = Factory::Resource::Project.fabricate! do |resource|
          resource.name = 'web-terminal-project'
        end

        file_name = '.gitlab-ci.yml'
        Factory::Repository::ProjectPush.fabricate! do |resource|
          resource.project = @project
          resource.file_name = file_name
          resource.commit_message = 'Add .gitlab-ci.yml'
          resource.file_content = <<~YAML
            test-web-terminal:
              tags:
                - web-ide
              script:
                - echo "no op"
          YAML
        end

        Factory::Resource::Runner.fabricate! do |resource|
          resource.project = @project
          resource.name = @runner_name
          resource.tags = %w[qa docker web-ide]
          resource.image = 'gitlab/gitlab-runner:ubuntu'
        end

        # Start the web terminal and display the contents of .gitlab-ci.yml
        @project.visit!
        Page::Project::Show.perform(&:open_web_ide!)

        # Push a change to .gitlab-ci.yml
        Page::Project::WebIDE::Edit.perform do |ide|
          ide.edit file_name
          ide.append_text "# edited"
          ide.commit_changes
        end

        # Restart the web terminal and display the new contents of .gitlab-ci.yml
        # Stop the web terminal
      end
    end
  end
end