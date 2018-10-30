# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Codeowners' do
      it 'merge request suggests owners specified in CODEOWNERS file in master' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        # Create one user to be the suggested approver and another user who will
        # not be an approver
        approver = Factory::Resource::User.fabricate!
        non_approver = Factory::Resource::User.fabricate!

        # Log out the last user that just registered and then sign back in as admin
        Page::Main::Menu.perform { |menu| menu.sign_out }
        Page::Main::Login.perform { |login_page| login_page.sign_in_using_credentials }

        project = Factory::Resource::Project.fabricate! do |project|
          project.name = "suggest-codeowners"
        end
        project.visit!

        Page::Project::Menu.perform { |menu| menu.click_members_settings }
        Page::Project::Settings::Members.perform do |members_page|
          members_page.add_member(approver.username)
          members_page.add_member(non_approver.username)
        end

        # Push CODEOWNERS to master
        project_push = Factory::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.file_name = 'CODEOWNERS'
          push.file_content = <<~CONTENT
            CODEOWNERS @#{approver.username}
          CONTENT
          push.commit_message = 'Add CODEOWNERS and test files'
        end

        Page::Project::Show.perform do |project_page|
          project_page.wait_for_push
        end

        # Push a new CODEOWNERS file and create a merge request
        Factory::Resource::MergeRequest.fabricate! do |merge_request|
          merge_request.title = 'This is a merge request'
          merge_request.description = 'Change code owners'
          merge_request.project = project_push.project
          merge_request.file_name = 'CODEOWNERS'
          merge_request.file_content = <<~CONTENT
            CODEOWNERS @#{non_approver.username}
          CONTENT
        end

        # Check that the merge request suggests the original code owner because
        # the current CODEOWNERS file in the master branch doesn't have the new
        # owner yet
        Page::MergeRequest::Show.perform(&:edit!)

        expect(page).to have_content("Suggested approvers: #{approver.name}")
        expect(page).not_to have_content(non_approver.name)
      end
    end
  end
end
