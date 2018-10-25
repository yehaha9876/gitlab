require 'spec_helper'

describe API::Groups do
  set(:group) { create(:group) }
  set(:project) { create(:project, group: group) }
  set(:user) { create(:user) }
  set(:admin) { create(:user, :admin) }

  describe 'PUT /groups/:id' do
    before do
      group.add_owner(user)
    end

    subject(:do_it) { put api("/groups/#{group.id}", user), file_template_project_id: project.id }

    it 'does not update file_template_project_id if unlicensed' do
      stub_licensed_features(custom_file_templates_for_namespace: false)

      expect { do_it }.not_to change { group.reload.file_template_project_id }
      expect(response).to have_gitlab_http_status(200)
      expect(json_response).not_to have_key('file_template_project_id')
    end

    it 'updates file_template_project_id if licensed' do
      stub_licensed_features(custom_file_templates_for_namespace: true)

      expect { do_it }.to change { group.reload.file_template_project_id }.to(project.id)
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['file_template_project_id']).to eq(project.id)
    end
  end

  describe 'POST /subscription' do
    let(:params) do
      { seats: 10,
        start_date: '01/01/2018',
        end_date: '01/01/2019' }
    end

    def do_post(current_user, payload)
      post api("/groups/#{group.id}/subscription", current_user), payload
    end

    it 'is only accessible by the admin' do
      do_post(user, params)

      expect(response).to have_gitlab_http_status(403)
    end

    it 'fails when some attrs are missing' do
      params.keys.each do |name|
        do_post(admin, params.except(name))

        expect(response).to have_gitlab_http_status(400)
      end
    end

    it 'creates a subscription for the Group' do
      do_post(admin, params)

      expect(response).to have_gitlab_http_status(201)
      expect(group.gitlab_subscription).to be_present
    end
  end
end
