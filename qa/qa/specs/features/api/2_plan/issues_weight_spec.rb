# frozen_string_literal: true

module QA
  context :plan do
    describe 'Issues Weights Tests' do
      before(:context) do
        @api_client = Runtime::API::Client.new(:gitlab)
        @project_id = create_project
      end

      def send_request(api_endpoint)
        Runtime::API::Request.new(@api_client, api_endpoint)
      end

      def create_project
        project_name = "project_#{SecureRandom.hex(8)}"
        create_project_request = send_request('/projects')
        post create_project_request.url, path: project_name, name: project_name

        expect_status(201)
        json_body[:id]
      end

      it 'Add Negative Issue Weights to Issues' do
        request = send_request("/projects/#{@project_id}/issues")
        post request.url, title: 'My Test Issue', weight: -1

        expect_status(400)
        expect_json('message.weight.0', 'must be greater than or equal to 0')
      end

      it 'Add Issue Weights to Issues' do
        request = send_request("/projects/#{@project_id}/issues")
        post request.url, title: 'My Test Issue', weight: 1000

        expect_status(201)
        expect_json('weight', 1000)
      end

      it 'Update Issue with 0 Issue Weight' do
        request = send_request("/projects/#{@project_id}/issues")
        post request.url, title: 'My Test Issue', weight: 8.9

        expect_status(201)
        expect_json('weight', 8)
        issue_iid = json_body[:iid]

        # Update Issue
        request = send_request("/projects/#{@project_id}/issues/#{issue_iid}")
        put request.url, weight: 0
        expect_status(200)
        expect_json('weight', 0)
      end

      it 'Remove Issues Weight' do
        request = send_request("/projects/#{@project_id}/issues")
        post request.url, title: 'My Test Issue', weight: 800
        issue_iid = json_body[:iid]

        request = send_request("/projects/#{@project_id}/issues/#{issue_iid}")
        put request.url, weight: nil

        expect_status(200)
        expect_json('weight', nil)
      end
    end
  end
end
