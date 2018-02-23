require 'spec_helper'

describe Geo::RepositoryVerifySecondaryService do
  include ::EE::GeoHelpers

  let(:primary)   { create(:geo_node, :primary) }
  let(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#execute' do
    let(:project_repository_state) { create(:project_repository_state, project: create(:project, :repository))}
    let(:registry) do
      registry = create(:geo_project_registry, project: project_repository_state.project)
      registry.project.last_repository_updated_at = 7.hours.ago
      registry.project.repository_state.last_repository_verification_at = 5.hours.ago
      registry.last_repository_successful_sync_at = 5.hours.ago
      registry.project.repository_state.repository_verification_checksum = 'my_checksum'

      registry
    end
    let(:service)  { described_class.new(registry, :repository) }

    it 'only works on the secondary' do
      stub_current_geo_node(primary)

      expect(service).not_to receive(:log_info)

      service.execute
    end

    it 'sets checksum when the checksum matches' do
      allow(service).to receive(:calculate_checksum).and_return('my_checksum')

      expect(service).to receive(:record_status).once.with(checksum: 'my_checksum')

      service.execute
    end

    it 'sets failure message when repository not found' do
      registry = create(:geo_project_registry)
      service  = described_class.new(registry, :repository)

      allow(described_class).to receive(:should_verify_repository?).and_return(true)

      expect(service).to receive(:record_status).once.with(error: 'Repository was not found')

      service.execute
    end
  end

  shared_examples 'should_verify_repository? for repositories/wikis' do |type|
    let(:project_repository_state) { create(:project_repository_state, project: create(:project, :repository))}
    let(:registry) do
      registry = create(:geo_project_registry, project: project_repository_state.project)
      registry.project.last_repository_updated_at = 7.hours.ago
      registry.project.repository_state.send("last_#{type}_verification_at=", 5.hours.ago)
      registry.send("last_#{type}_successful_sync_at=", 5.hours.ago)
      registry.project.repository_state.send("#{type}_verification_checksum=", 'my_checksum')

      registry
    end

    it 'verifies the repository' do
      expect(described_class.should_verify_repository?(registry, type)).to be_truthy
    end

    it 'does not verify if repository was updated after checksum' do
      registry.project.last_repository_updated_at = 4.hours.ago
      registry.project.repository_state.send("last_#{type}_verification_at=", 5.hours.ago)

      expect(described_class.should_verify_repository?(registry, type)).to be_falsy
    end

    it 'does not verify if repository was updated after sync as done' do
      registry.project.last_repository_updated_at = 4.hours.ago
      registry.send("last_#{type}_successful_sync_at=", 5.hours.ago)

      expect(described_class.should_verify_repository?(registry, type)).to be_falsy
    end

    it 'does not verify if never synced' do
      registry.send("last_#{type}_successful_sync_at=", nil)

      expect(described_class.should_verify_repository?(registry, type)).to be_falsy
    end

    it 'does not verify if there is no checksum' do
      registry.project.repository_state.send("#{type}_verification_checksum=", nil)

      expect(described_class.should_verify_repository?(registry, type)).to be_falsy
    end

    it 'has been at least 6 hours since the primary repository was updated' do
      registry.project.last_repository_updated_at = 7.hours.ago

      expect(described_class.should_verify_repository?(registry, type)).to be_truthy
    end

    it 'does not verify unless at least 6 hours since the primary repository was updated' do
      registry.project.last_repository_updated_at = 5.5.hours.ago

      expect(described_class.should_verify_repository?(registry, type)).to be_falsy
    end
  end

  describe '#should_verify_repository?' do
    context 'repository' do
      include_examples 'should_verify_repository? for repositories/wikis', :repository
    end

    context 'wiki' do
      include_examples 'should_verify_repository? for repositories/wikis', :wiki
    end
  end

  shared_examples 'record_status for repositories/wikis' do |type|
    it 'records a successful verification' do
      service.send(:record_status, checksum: 'my_checksum')
      registry.reload

      expect(registry.send("#{type}_verification_checksum")).to eq 'my_checksum'
      expect(registry.send("last_#{type}_verification_at")).not_to be_nil
      expect(registry.send("last_#{type}_verification_failure")).to be_nil
    end

    it 'records a failure' do
      service.send(:record_status, error: 'Repository checksum did not match')
      registry.reload

      expect(registry.send("#{type}_verification_checksum")).to be_nil
      expect(registry.send("last_#{type}_verification_at")).not_to be_nil
      expect(registry.send("last_#{type}_verification_failure")).to eq 'Repository checksum did not match'
    end
  end

  describe '#record_status' do
    let(:registry) { create(:geo_project_registry) }

    context 'for a repository' do
      let(:service)  { described_class.new(registry, :repository) }

      include_examples 'record_status for repositories/wikis', :repository
    end

    context 'for a wiki' do
      let(:service)  { described_class.new(registry, :wiki) }

      include_examples 'record_status for repositories/wikis', :wiki
    end
  end
end
