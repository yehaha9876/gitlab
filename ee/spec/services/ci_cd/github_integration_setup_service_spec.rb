require 'spec_helper'

describe CiCd::GithubIntegrationSetupService do
  let(:repo_full_name) { "MyUser/my-project" }
  let(:api_token) { "abcdefghijk123" }
  let(:import_url) { "https://#{api_token}@github.com/#{repo_full_name}.git" }
  let(:credentials) { { user: api_token } }
  let(:project) do
    create(:project, :mirror,
                     import_source: repo_full_name,
                     import_url: import_url,
                     import_data_attributes: { credentials: credentials } )
  end

  subject { described_class.new(project) }

  before do
    subject.execute
  end

  describe 'sets up GitHub service integration' do
    let(:integration) { project.github_service }

    it 'enables the integration' do
      expect(integration).to be_active
    end

    it 'leaves API token blank so it can default to mirror settings' do
      expect(integration.token).to eq nil
    end

    it 'leaves repo URL blank so it can default to mirror settings' do
      expect(integration.repository_url).to eq nil
    end

    it 'defaults to mirror settings' do
      expect(integration.owner).to eq 'MyUser'
      expect(integration.repository_name).to eq 'my-project'
    end
  end
end
