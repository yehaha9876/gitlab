require 'spec_helper'

describe ProjectMirrorEntity do
  subject(:entity) { described_class.new(project).as_json.deep_symbolize_keys }

  describe 'pull mirror' do
    let(:project) { create(:project, :mirror) }
    let(:import_data) { project.import_data }

    context 'password authentication' do
      before do
        import_data.update!(auth_method: 'password', password: 'fake password')
      end

      it 'represents the pull mirror' do
        is_expected.to eq(
          id: project.id,
          mirror: true,
          import_url: project.import_url,
          username_only_import_url: project.username_only_import_url,
          mirror_user_id: project.mirror_user_id,
          mirror_trigger_builds: project.mirror_trigger_builds,
          import_data_attributes: {
            id: import_data.id,
            auth_method: 'password',
            ssh_known_hosts: nil,
            ssh_known_hosts_fingerprints: [],
            ssh_known_hosts_verified_at: nil,
            ssh_known_hosts_verified_by_id: nil,
            ssh_public_key: nil
          },
          remote_mirrors_attributes: []
        )
      end
    end

    context 'SSH public-key authentication' do
      before do
        project.import_url = "ssh://example.com"
        import_data.update!(auth_method: 'ssh_public_key', ssh_known_hosts: "example.com #{SSHKeygen.generate}")
      end

      it 'represents the pull mirror' do
        is_expected.to eq(
          id: project.id,
          mirror: true,
          import_url: project.import_url,
          username_only_import_url: project.username_only_import_url,
          mirror_user_id: project.mirror_user_id,
          mirror_trigger_builds: project.mirror_trigger_builds,
          import_data_attributes: {
            id: import_data.id,
            auth_method: 'ssh_public_key',
            ssh_known_hosts: import_data.ssh_known_hosts,
            ssh_known_hosts_fingerprints: import_data.ssh_known_hosts_fingerprints.as_json,
            ssh_known_hosts_verified_at: import_data.ssh_known_hosts_verified_at,
            ssh_known_hosts_verified_by_id: import_data.ssh_known_hosts_verified_by_id,
            ssh_public_key: import_data.ssh_public_key
          },
          remote_mirrors_attributes: []
        )
      end
    end
  end

  describe 'push mirror' do
    let(:project) { create(:project, :repository, :remote_mirror) }
    let(:remote_mirror) { project.remote_mirrors.first }

    it 'represents the push mirror' do
      is_expected.to eq(
        id: project.id,
        mirror: false,
        import_url: nil,
        username_only_import_url: nil,
        mirror_user_id: nil,
        mirror_trigger_builds: false,
        import_data_attributes: nil,
        remote_mirrors_attributes: [
          {
            id: remote_mirror.id,
            url: remote_mirror.url,
            enabled: true
          }
        ]
      )
    end
  end
end
