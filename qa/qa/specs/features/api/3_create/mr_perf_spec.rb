# frozen_string_literal: true
require 'faker'

module QA
  context :performance do
    describe 'Merge Request Performance' do
      before(:context) do
        @api_client = Runtime::API::Client.new(:gitlab)
        @group_id = create_group
        @project_id = create_project
      end

      def create_request(api_endpoint)
        Runtime::API::Request.new(@api_client, api_endpoint)
      end

      def create_group
        group_name = "group_#{SecureRandom.hex(8)}"
        create_group_request = create_request("/groups")
        post create_group_request.url, name: group_name, path: group_name
        expect_status(201)
        json_body[:id]
      end

      def create_project
        project_name = "project_#{SecureRandom.hex(8)}"
        create_project_request = create_request('/projects')
        post create_project_request.url, path: project_name, name: project_name, namespace_id: @group_id
        expect_status(201)
        json_body[:id]
      end

      def create_branch
        request = create_request("/projects/#{@project_id}/repository/branches")
        post request.url, branch: 'perf-testing', ref: 'master'
        expect_status(201)
      end

      def upload_file(branch, content, commit_message, file_path, exists = false)
        request = create_request("/projects/#{@project_id}/repository/files/#{file_path}")
        if exists
          put request.url, branch: branch, content: content, commit_message: commit_message
          expect_status(200)
        else
          post request.url, branch: branch, content: content, commit_message: commit_message
          puts json_body
          expect_status(201)
        end
      end

      it 'Create MR' do
        content = Faker::Lorem.sentence(2) # Generates 2 lines
        upload_file('master', content, 'Add README.md', 'README.md')
        create_branch
        # content = Faker::Lorem.sentences(2)
        # upload_file('perf-testing', content, 'Update README.md', 'README.md', true)
        # request = create_request("/projects/#{@project_id}/merge_requests")
        # post request.url, source_branch: 'perf-testing', target_branch: 'master', title: 'My MR'
        # puts json_body.to_s
        # expect_status(201)
      end
    end
  end
end
