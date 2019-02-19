require 'spec_helper'

describe GeoNode, type: :model do
  using RSpec::Parameterized::TableSyntax
  include ::EE::GeoHelpers

  let(:dummy_url) { 'https://localhost:3000/gitlab' }
  let(:new_node_attrs) { { url: dummy_url } }
  let(:new_node) { create(:geo_node, new_node_attrs) }
  let(:new_primary_node) { create(:geo_node, :primary, new_node_attrs) }
  let(:empty_node) { described_class.new }
  let(:primary_node) { create(:geo_node, :primary) }
  let(:node) { create(:geo_node) }

  let(:url_helpers) { Gitlab::Routing.url_helpers }
  let(:api_version) { API::API.version }

  context 'associations' do
    it { is_expected.to belong_to(:oauth_application).dependent(:destroy) }

    it { is_expected.to have_many(:geo_node_namespace_links) }
    it { is_expected.to have_many(:namespaces).through(:geo_node_namespace_links) }
  end

  context 'validations' do
    it { is_expected.to validate_inclusion_of(:selective_sync_type).in_array([nil, *GeoNode::SELECTIVE_SYNC_TYPES]) }
    it { is_expected.to validate_numericality_of(:repos_max_capacity).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:files_max_capacity).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:verification_max_capacity).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:minimum_reverification_interval).is_greater_than_or_equal_to(1) }

    context 'primary node' do
      it 'cannot be disabled' do
        primary_node.enabled = false

        expect(primary_node).not_to be_valid
        expect(primary_node.errors).to include(:enabled)
      end
    end

    context 'url' do
      subject { build(:geo_node, url: url) }

      context 'when url is http' do
        let(:url) { 'http://foo' }

        it { is_expected.to be_valid }
      end

      context 'when url is https' do
        let(:url) { 'https://foo' }

        it { is_expected.to be_valid }
      end

      context 'when url is not http or https' do
        let(:url) { 'nothttp://foo' }

        it { is_expected.not_to be_valid }
      end
    end

    context 'alternate_url' do
      subject { build(:geo_node, alternate_url: alternate_url) }

      context 'when alternate_url is http' do
        let(:alternate_url) { 'http://foo' }

        it { is_expected.to be_valid }
      end

      context 'when alternate_url is https' do
        let(:alternate_url) { 'https://foo' }

        it { is_expected.to be_valid }
      end

      context 'when alternate_url is not http or https' do
        let(:alternate_url) { 'nothttp://foo' }

        it { is_expected.not_to be_valid }
      end
    end
  end

  context 'default values' do
    where(:attribute, :value) do
      :url                | Gitlab::Routing.url_helpers.root_url
      :primary            | false
      :repos_max_capacity | 25
      :files_max_capacity | 10
    end

    with_them do
      it { expect(empty_node[attribute]).to eq(value) }
    end
  end

  context 'prevent locking yourself out' do
    it 'does not accept adding a non primary node with same details as current_node' do
      node = build(:geo_node, :primary, primary: false)

      expect(node).not_to be_valid
      expect(node.errors.full_messages.count).to eq(1)
      expect(node.errors[:base].first).to match('locking yourself out')
    end
  end

  context 'dependent models and attributes for GeoNode' do
    context 'on validation (and therefore on save)' do
      context 'when it is a secondary node' do
        before do
          node
        end

        context 'when the oauth_application is missing' do
          before do
            node.oauth_application.destroy
            node.oauth_application = nil
          end

          it 'builds an oauth_application' do
            expect(node.valid?).to be_truthy

            expect(node.oauth_application).to be
            expect(node.oauth_application.redirect_uri).to be_present
          end
        end

        context 'when the oauth_application redirect_uri does not contain oauth_callback_url' do
          it 'ensures oauth_callback_url is included' do
            node.oauth_application.redirect_uri = 'http://wrong-callback-url'
            node.oauth_application.save!

            expect(node.valid?).to be_truthy

            expect(node.oauth_application.redirect_uri.split).to include(node.oauth_callback_url)
          end
        end
      end

      context 'when it is a primary node' do
        before do
          primary_node
        end

        context 'when it does not have an oauth_application' do
          it 'does not create an oauth_application' do
            primary_node.oauth_application = nil

            expect(primary_node.valid?).to be_truthy

            expect(primary_node.oauth_application).to be_nil
          end
        end

        context 'when it does not have an oauth_application' do
          # TODO Should it instead be destroyed?
          it 'disassociates the oauth_application' do
            primary_node.oauth_application = create(:oauth_application)

            expect(primary_node.valid?).to be_truthy

            expect(primary_node.oauth_application).to be_nil
          end
        end

        context 'when clone_url_prefix is nil' do
          it 'sets current clone_url_prefix' do
            primary_node.clone_url_prefix = nil

            expect(primary_node.valid?).to be_truthy

            expect(primary_node.clone_url_prefix).to eq(Gitlab.config.gitlab_shell.ssh_path_prefix)
          end
        end

        context 'when clone_url_prefix has changed' do
          it 'sets current clone_url_prefix' do
            primary_node.clone_url_prefix = 'foo'

            expect(primary_node.valid?).to be_truthy

            expect(primary_node.clone_url_prefix).to eq(Gitlab.config.gitlab_shell.ssh_path_prefix)
          end
        end
      end
    end
  end

  context 'cache expiration' do
    let(:new_node) { FactoryBot.build(:geo_node) }

    it 'expires cache when saved' do
      expect(new_node).to receive(:expire_cache!).at_least(:once)

      new_node.save!
    end

    it 'expires cache when removed' do
      expect(node).to receive(:expire_cache!) # 1 for creation 1 for deletion

      node.destroy
    end
  end

  describe '.primary_node' do
    before do
      create(:geo_node)
    end

    it 'returns the primary' do
      primary = create(:geo_node, :primary)

      expect(described_class.primary_node).to eq(primary)
    end

    it 'returns nil if there is no primary' do
      expect(described_class.primary_node).to be_nil
    end
  end

  describe '.secondary_nodes' do
    before do
      create(:geo_node, :primary)
    end

    it 'returns all secondary nodes' do
      secondaries = create_list(:geo_node, 2)

      expect(described_class.secondary_nodes).to match_array(secondaries)
    end

    it 'returns empty array if there are not any secondary nodes' do
      expect(described_class.secondary_nodes).to be_empty
    end
  end

  describe '.unhealthy_nodes' do
    before do
      create(:geo_node_status, :healthy)
    end

    subject(:unhealthy_nodes) { described_class.unhealthy_nodes }

    it 'returns a node without status' do
      geo_node = create(:geo_node)

      expect(unhealthy_nodes).to contain_exactly(geo_node)
    end

    it 'returns a node not having a cursor last event id' do
      geo_node_status = create(:geo_node_status, :healthy, cursor_last_event_id: nil)

      expect(unhealthy_nodes).to contain_exactly(geo_node_status.geo_node)
    end

    it 'returns a node with missing status check timestamp' do
      geo_node_status = create(:geo_node_status, :healthy, last_successful_status_check_at: nil)

      expect(unhealthy_nodes).to contain_exactly(geo_node_status.geo_node)
    end

    it 'returns a node with an old status check timestamp' do
      geo_node_status = create(:geo_node_status, :healthy, last_successful_status_check_at: 16.minutes.ago)

      expect(unhealthy_nodes).to contain_exactly(geo_node_status.geo_node)
    end
  end

  describe '.min_cursor_last_event_id' do
    it 'returns the minimum of cursor_last_event_id across all nodes' do
      create(:geo_node_status, cursor_last_event_id: 10)
      create(:geo_node_status, cursor_last_event_id: 8)

      expect(described_class.min_cursor_last_event_id).to eq(8)
    end
  end

  describe '.find_by_oauth_application_id' do
    context 'when the Geo node exists' do
      it 'returns the Geo node' do
        found = described_class.find_by_oauth_application_id(node.oauth_application_id)

        expect(found).to eq(node)
      end
    end

    context 'when the Geo node does not exist' do
      it 'returns nil' do
        found = described_class.find_by_oauth_application_id(-1)

        expect(found).to be_nil
      end
    end
  end

  describe '#repair' do
    it 'creates an oauth application for a Geo secondary node' do
      stub_current_geo_node(node)
      node.update_attribute(:oauth_application, nil)

      node.repair

      expect(node.oauth_application).to be_present
    end
  end

  describe '#current?' do
    it 'returns true when node is the current node' do
      node = described_class.new(url: described_class.current_node_url)

      expect(node.current?).to be_truthy
    end

    it 'returns false when node is not the current node' do
      node = described_class.new(url: 'http://another.node.com:8080/foo')

      expect(node.current?).to be_falsy
    end
  end

  describe '#uri' do
    context 'when all fields are filled' do
      it 'returns an URI object' do
        expect(new_node.uri).to be_a URI
      end

      it 'includes schema, host, port and relative_url_root with a terminating /' do
        expected_uri = URI.parse(dummy_url)
        expected_uri.path += '/'
        expect(new_node.uri).to eq(expected_uri)
      end
    end

    context 'when required fields are not filled' do
      it 'returns an URI object' do
        expect(empty_node.uri).to be_a URI
      end
    end
  end

  describe '#url' do
    it 'returns a string' do
      expect(new_node.url).to be_a String
    end

    it 'includes schema home port and relative_url with a terminating /' do
      expected_url = 'https://localhost:3000/gitlab/'
      expect(new_node.url).to eq(expected_url)
    end

    it 'defaults to existing HTTPS and relative URL with a terminating / if present' do
      stub_config_setting(port: 443)
      stub_config_setting(protocol: 'https')
      stub_config_setting(relative_url_root: '/gitlab')

      expect(empty_node.url).to eq('https://localhost/gitlab/')
    end
  end

  describe '#url=' do
    subject { new_node }

    it 'sets schema field based on url' do
      expect(subject.uri.scheme).to eq('https')
    end

    it 'sets host field based on url' do
      expect(subject.uri.host).to eq('localhost')
    end

    it 'sets port field based on specified by url' do
      expect(subject.uri.port).to eq(3000)
    end

    context 'when unspecified ports' do
      let(:dummy_http) { 'http://example.com/' }
      let(:dummy_https) { 'https://example.com/' }

      it 'sets port 80 when http and no port is specified' do
        subject.url = dummy_http

        expect(subject.uri.port).to eq(80)
      end

      it 'sets port 443 when https and no port is specified' do
        subject.url = dummy_https

        expect(subject.uri.port).to eq(443)
      end
    end
  end

  describe '#alternate_uri' do
    let(:alternate_url) { 'https://foo:3003/bar' }
    let(:node) { create(:geo_node, url: 'https://localhost:3000/gitlab', alternate_url: alternate_url) }

    context 'when all fields are filled' do
      it 'returns an URI object' do
        expect(node.alternate_uri).to be_a URI
      end

      it 'includes schema, host, port and relative_url_root with a terminating /' do
        expected_uri = URI.parse(alternate_url)
        expected_uri.path += '/'
        expect(node.alternate_uri).to eq(expected_uri)
      end
    end
  end

  describe '#alternate_url' do
    let(:alternate_url) { 'https://foo:3003/bar' }
    let(:node) { create(:geo_node, url: 'https://localhost:3000/gitlab', alternate_url: alternate_url) }

    it 'returns a string' do
      expect(node.alternate_url).to be_a String
    end

    it 'includes schema home port and relative_url with a terminating /' do
      expected_url = alternate_url + '/'
      expect(node.alternate_url).to eq(expected_url)
    end

    it 'can be nil' do
      stub_config_setting(port: 443)
      stub_config_setting(protocol: 'https')
      stub_config_setting(relative_url_root: '/gitlab')

      expect(empty_node.alternate_url).to be_nil
    end
  end

  describe '#alternate_url=' do
    subject { GeoNode.new(alternate_url: 'https://foo:3003/bar') }

    it 'sets schema field based on url' do
      expect(subject.alternate_uri.scheme).to eq('https')
    end

    it 'sets host field based on url' do
      expect(subject.alternate_uri.host).to eq('foo')
    end

    it 'sets port field based on specified by url' do
      expect(subject.alternate_uri.port).to eq(3003)
    end

    context 'when unspecified ports' do
      let(:dummy_http) { 'http://example.com/' }
      let(:dummy_https) { 'https://example.com/' }

      it 'sets port 80 when http and no port is specified' do
        subject.alternate_url = dummy_http

        expect(subject.alternate_uri.port).to eq(80)
      end

      it 'sets port 443 when https and no port is specified' do
        subject.alternate_url = dummy_https

        expect(subject.alternate_uri.port).to eq(443)
      end
    end
  end

  describe '#geo_transfers_url' do
    let(:transfers_url) { "https://localhost:3000/gitlab/api/#{api_version}/geo/transfers/lfs/1" }

    it 'returns api url based on node uri' do
      expect(new_node.geo_transfers_url(:lfs, 1)).to eq(transfers_url)
    end
  end

  describe '#geo_status_url' do
    let(:status_url) { "https://localhost:3000/gitlab/api/#{api_version}/geo/status" }

    it 'returns api url based on node uri' do
      expect(new_node.status_url).to eq(status_url)
    end
  end

  describe '#snapshot_url' do
    let(:project) { create(:project) }
    let(:snapshot_url) { "https://localhost:3000/gitlab/api/#{api_version}/projects/#{project.id}/snapshot" }

    it 'returns snapshot URL based on node URI' do
      expect(new_node.snapshot_url(project.repository)).to eq(snapshot_url)
    end

    it 'adds ?wiki=1 to the snapshot URL when the repository is a wiki' do
      expect(new_node.snapshot_url(project.wiki.repository)).to eq(snapshot_url + "?wiki=1")
    end
  end

  describe '#find_or_build_status' do
    it 'returns a new status' do
      status = new_node.find_or_build_status

      expect(status).to be_a(GeoNodeStatus)

      status.save

      expect(new_node.find_or_build_status).to eq(status)
    end
  end

  describe '#oauth_callback_url' do
    let(:oauth_callback_url) { 'https://localhost:3000/gitlab/oauth/geo/callback' }

    it 'returns oauth callback url based on node uri' do
      expect(new_node.oauth_callback_url).to eq(oauth_callback_url)
    end

    it 'returns url that matches rails url_helpers generated one' do
      route = url_helpers.oauth_geo_callback_url(protocol: 'https:', host: 'localhost', port: 3000, script_name: '/gitlab')
      expect(new_node.oauth_callback_url).to eq(route)
    end
  end

  describe '#oauth_logout_url' do
    let(:fake_state) { CGI.escape('fakestate') }
    let(:oauth_logout_url) { "https://localhost:3000/gitlab/oauth/geo/logout?state=#{fake_state}" }

    it 'returns oauth logout url based on node uri' do
      expect(new_node.oauth_logout_url(fake_state)).to eq(oauth_logout_url)
    end

    it 'returns url that matches rails url_helpers generated one' do
      route = url_helpers.oauth_geo_logout_url(protocol: 'https:', host: 'localhost', port: 3000, script_name: '/gitlab', state: fake_state)
      expect(new_node.oauth_logout_url(fake_state)).to eq(route)
    end
  end

  describe '#geo_projects_url' do
    it 'returns the Geo Projects url for the specific node' do
      expected_url = 'https://localhost:3000/gitlab/admin/geo/projects'

      expect(new_node.geo_projects_url).to eq(expected_url)
    end

    it 'returns nil when node is a primary one' do
      expect(primary_node.geo_projects_url).to be_nil
    end
  end

  describe '#missing_oauth_application?' do
    context 'on a primary node' do
      it 'returns false' do
        expect(primary_node).not_to be_missing_oauth_application
      end
    end

    it 'returns false when present' do
      expect(node).not_to be_missing_oauth_application
    end

    it 'returns true when it is not present' do
      node.oauth_application.destroy!
      node.reload
      expect(node).to be_missing_oauth_application
    end
  end

  describe '#projects_include?' do
    let(:unsynced_project) { create(:project, :broken_storage) }

    it 'returns true without selective sync' do
      expect(node.projects_include?(unsynced_project.id)).to eq true
    end

    context 'selective sync by namespaces' do
      let(:synced_group) { create(:group) }

      before do
        node.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
      end

      it 'returns true when project belongs to one of the namespaces' do
        project_in_synced_group = create(:project, group: synced_group)

        expect(node.projects_include?(project_in_synced_group.id)).to be_truthy
      end

      it 'returns false when project does not belong to one of the namespaces' do
        expect(node.projects_include?(unsynced_project.id)).to be_falsy
      end
    end

    context 'selective sync by shards' do
      before do
        node.update!(selective_sync_type: 'shards', selective_sync_shards: ['default'])
      end

      it 'returns true when project belongs to one of the namespaces' do
        project_in_synced_shard = create(:project)

        expect(node.projects_include?(project_in_synced_shard.id)).to be_truthy
      end

      it 'returns false when project does not belong to one of the namespaces' do
        expect(node.projects_include?(unsynced_project.id)).to be_falsy
      end
    end
  end

  describe '#projects' do
    let(:group_1) { create(:group) }
    let(:group_2) { create(:group) }
    let(:nested_group_1) { create(:group, parent: group_1) }
    let!(:project_1) { create(:project, group: group_1) }
    let!(:project_2) { create(:project, group: nested_group_1) }
    let!(:project_3) { create(:project, :broken_storage, group: group_2) }

    it 'returns all projects without selective sync' do
      expect(node.projects).to match_array([project_1, project_2, project_3])
    end

    it 'returns projects that belong to the namespaces with selective sync by namespace' do
      node.update!(selective_sync_type: 'namespaces', namespaces: [group_1, nested_group_1])

      expect(node.projects).to match_array([project_1, project_2])
    end

    it 'returns projects that belong to the shards with selective sync by shard' do
      node.update!(selective_sync_type: 'shards', selective_sync_shards: ['default'])

      expect(node.projects).to match_array([project_1, project_2])
    end

    it 'returns nothing if an unrecognised selective sync type is used' do
      node.update_attribute(:selective_sync_type, 'unknown')

      expect(node.projects).to be_empty
    end
  end

  describe '#selective_sync?' do
    subject { node.selective_sync? }

    it 'returns true when selective sync is by namespaces' do
      node.update!(selective_sync_type: 'namespaces')

      is_expected.to be_truthy
    end

    it 'returns true when selective sync is by shards' do
      node.update!(selective_sync_type: 'shards')

      is_expected.to be_truthy
    end

    it 'returns false when selective sync is disabled' do
      node.update!(
        selective_sync_type: '',
        namespaces: [create(:group)],
        selective_sync_shards: ['default']
      )

      is_expected.to be_falsy
    end
  end
end
