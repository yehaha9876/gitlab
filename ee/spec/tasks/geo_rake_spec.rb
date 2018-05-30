require 'rake_helper'

describe 'geo rake tasks', :geo do
  include ::EE::GeoHelpers

  before do
    Rake.application.rake_require 'tasks/geo'
    stub_licensed_features(geo: true)
  end

  describe 'set_primary_node task' do
    before do
      stub_config_setting(protocol: 'https')
    end

    it 'creates a GeoNode' do
      expect(GeoNode.count).to eq(0)

      run_rake_task('geo:set_primary_node')

      expect(GeoNode.count).to eq(1)

      node = GeoNode.first

      expect(node.uri.scheme).to eq('https')
      expect(node.primary).to be_truthy
    end
  end

  describe 'set_secondary_as_primary task' do
    let!(:current_node) { create(:geo_node) }
    let!(:primary_node) { create(:geo_node, :primary) }

    before do
      stub_current_geo_node(current_node)
    end

    it 'removes primary and sets secondary as primary' do
      run_rake_task('geo:set_secondary_as_primary')

      expect(current_node.primary?).to be_truthy
      expect(GeoNode.count).to eq(1)
    end
  end

  describe 'update_primary_node_url task' do
    let(:primary_node) { create(:geo_node, :primary, url: 'https://secondary.geo.example.com') }

    before do
      allow(GeoNode).to receive(:current_node_url).and_return('https://primary.geo.example.com')
      stub_current_geo_node(primary_node)
    end

    it 'updates Geo primary node URL' do
      run_rake_task('geo:update_primary_node_url')

      expect(primary_node.reload.url).to eq 'https://primary.geo.example.com/'
    end
  end

  describe 'status task' do
    let!(:current_node) { create(:geo_node) }
    let!(:primary_node) { create(:geo_node, :primary) }
    let!(:geo_event_log) { create(:geo_event_log) }

    before do
      expect(Gitlab::Geo).to receive(:license_allows?).and_return(true).at_least(:once)
      expect(GeoNodeStatus).to receive(:current_node_status).and_call_original

      stub_current_geo_node(current_node)
    end

    it 'runs with no error' do
      expect { run_rake_task('geo:status') }.to output(/Sync settings: Full/).to_stdout
    end
  end

  describe 'cleanup' do
    let(:storages) do
      {
        'default' => Gitlab::GitalyClient::StorageSettings.new(@default_storage_hash.merge('path' => 'tmp/tests/default_storage'))
      }
    end

    before(:all) do
      @default_storage_hash = Gitlab.config.repositories.storages.default.to_h
    end

    before do
      FileUtils.mkdir(Settings.absolute('tmp/tests/default_storage'))
      allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
    end

    after do
      FileUtils.rm_rf(Settings.absolute('tmp/tests/default_storage'))
    end

    describe 'cleanup:repository_temp_dirs' do
      let(:repo_path) { 'tmp/tests/default_storage/namespace_1/project_4eb93a5272496a.git' }
      let(:repo_subgroup_path) { 'tmp/tests/default_storage/namespace_1/subgroup_1/subgroup_2/project_4eb93a5272496a.git' }
      let(:repo_spaced_path) { 'tmp/tests/default_storage/namespace_1/project with spaces_4eb93a5272496a.git' }
      let(:wiki_path) { 'tmp/tests/default_storage/namespace_1/project_4eb93a5272496a.wiki.git' }
      let(:hashed_path) { 'tmp/tests/default_storage/@hashed/12/34/5678.git' }
      let(:geo_temporary_path) { 'tmp/tests/default_storage/@geo-temporary/project_1234567890abcd.git' }
      let(:malformed1_path) { 'tmp/tests/default_storage/namespace_1/project_4eb93a5272496abac.git' }
      let(:malformed2_path) { 'tmp/tests/default_storage/namespace_1/project_4eb93a5272496a.git+deleted' }
      let(:malformed3_path) { 'tmp/tests/default_storage/namespace_1/project-4eb93a5272496a.git' }
      let(:malformed4_path) { 'tmp/tests/default_storage/namespace_1/project-xxxxxxxzzzzzzz.git' }
      let(:file_path) { 'tmp/tests/default_storage/namespace_1/file_4eb93a5272496a.git' }

      before do
        allow(Gitlab::Geo).to receive(:secondary?).and_return(true)
        expect(Gitlab::Geo).to receive(:license_allows?).and_return(true).at_least(:once)

        FileUtils.mkdir_p(Settings.absolute(repo_path))
        FileUtils.mkdir_p(Settings.absolute(wiki_path))
        FileUtils.mkdir_p(Settings.absolute(hashed_path))
        FileUtils.mkdir_p(Settings.absolute(geo_temporary_path))
      end

      it 'does not run on a primary node' do
        allow(Gitlab::Geo).to receive(:secondary?).and_return(false)

        expect { run_rake_task('geo:cleanup:repository_temp_dirs') }.to raise_error(SystemExit)
      end

      it 'removes old temporary directories' do
        stub_env('REMOVE', 'true')
        run_rake_task('geo:cleanup:repository_temp_dirs')

        expect(Dir.exist?(Settings.absolute(repo_path))).to be_falsey
        expect(Dir.exist?(Settings.absolute(wiki_path))).to be_falsey
        expect(Dir.exist?(Settings.absolute(repo_subgroup_path))).to be_falsey
        expect(Dir.exist?(Settings.absolute(repo_spaced_path))).to be_falsey
      end

      it 'does not remove if REMOVE not specified' do
        run_rake_task('geo:cleanup:repository_temp_dirs')

        expect(Dir.exist?(Settings.absolute(repo_path))).to be_truthy
        expect(Dir.exist?(Settings.absolute(wiki_path))).to be_truthy
      end

      it 'ignores all directories beginning with @, such as @hashed, @geo-temporary, etc' do
        stub_env('REMOVE', 'true')
        run_rake_task('geo:cleanup:repository_temp_dirs')

        expect(Dir.exist?(Settings.absolute(hashed_path))).to be_truthy
        expect(Dir.exist?(Settings.absolute(geo_temporary_path))).to be_truthy
      end

      it 'only finds directories' do
        FileUtils.touch(file_path)

        expect(File.exists?(file_path)).to be_truthy

        stub_env('REMOVE', 'true')
        run_rake_task('geo:cleanup:repository_temp_dirs')

        expect(File.exists?(file_path)).to be_truthy
      end

      it 'only removes directories that have no associated project' do
        namespace = create(:namespace, name: 'namespace_1')
        project   = create(:project, name: 'project_4eb93a5272496a', namespace: namespace)

        stub_env('REMOVE', 'true')
        run_rake_task('geo:cleanup:repository_temp_dirs')

        expect(Dir.exist?(Settings.absolute(repo_path))).to be_truthy
      end

      it 'ignores anything not matching the temporary naming' do
        FileUtils.mkdir_p(Settings.absolute(malformed1_path))
        FileUtils.mkdir_p(Settings.absolute(malformed2_path))
        FileUtils.mkdir_p(Settings.absolute(malformed3_path))
        FileUtils.mkdir_p(Settings.absolute(malformed4_path))

        stub_env('REMOVE', 'true')
        run_rake_task('geo:cleanup:repository_temp_dirs')

        expect(Dir.exist?(Settings.absolute(malformed1_path))).to be_truthy
        expect(Dir.exist?(Settings.absolute(malformed2_path))).to be_truthy
        expect(Dir.exist?(Settings.absolute(malformed3_path))).to be_truthy
        expect(Dir.exist?(Settings.absolute(malformed4_path))).to be_truthy
      end
    end
  end
end
