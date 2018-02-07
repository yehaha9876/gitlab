require 'spec_helper'

describe Geo::RepositoryVerificationWorker do
  include ::EE::GeoHelpers

  let(:primary)   { create(:geo_node, :primary) }
  let(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(true)
  end

  subject { described_class.new }

  describe '#perform' do
    it 'logs error if invalid geo node' do
      expect(subject).to receive(:log_error)

      subject.perform(0)
    end

    it 'only works on the secondary' do
      stub_current_geo_node(primary)

      expect(subject).not_to receive(:try_obtain_lease)

      subject.perform(primary.id)
    end

    it 'verifies several projects' do
      registry_1 = create(:geo_project_registry)
      registry_2 = create(:geo_project_registry)
      registry_3 = create(:geo_project_registry, :repository_checksum)

      expect(subject).to receive(:verify_project).twice

      subject.perform(secondary.id)
    end
  end

  describe '#verify_project' do
    let(:registry) { create(:geo_project_registry, project: create(:project, :repository)) }

    it 'verifies both repository and wiki' do
      allow(subject).to receive(:should_verify_repository?).with(registry, :repository).and_return(true)
      allow(subject).to receive(:should_verify_repository?).with(registry, :wiki).and_return(true)

      expect(subject).to receive(:verify_repository).twice

      subject.verify_project(registry)
    end

    it 'verifies only the repository' do
      allow(subject).to receive(:should_verify_repository?).with(registry, :repository).and_return(true)
      allow(subject).to receive(:should_verify_repository?).with(registry, :wiki).and_return(false)

      expect(subject).to receive(:verify_repository).once

      subject.verify_project(registry)
    end

    it 'verifies only the wiki' do
      allow(subject).to receive(:should_verify_repository?).with(registry, :repository).and_return(false)
      allow(subject).to receive(:should_verify_repository?).with(registry, :wiki).and_return(true)

      expect(subject).to receive(:verify_repository).once

      subject.verify_project(registry)
    end
  end

  describe '#verify_repository' do
    it 'sets checksum when the checksum matches' do
      registry = create(:geo_project_registry, project: create(:project, :repository))
      allow(subject).to receive(:calculate_checksum).and_return('my_checksum')

      expect(subject).to receive(:record_status).once.with(registry, :repository, 'my_checksum')

      subject.verify_repository(registry, registry.project.repository, 'my_checksum', :repository)
    end

    it 'sets failure message when repository not found' do
      registry = create(:geo_project_registry)

      expect(subject).to receive(:record_status).once.with(registry, :repository, nil, 'Repository was not found')

      subject.verify_repository(registry, registry.project.repository, 'my_checksum', :repository)
    end
  end

  it '#find_registries_without_checksum' do
    registry_1 = create(:geo_project_registry)
    registry_2 = create(:geo_project_registry, :repository_checksum)
    registry_3 = create(:geo_project_registry, :repository_checksum)

    expect(subject.send(:find_registries_without_checksum).count).to eq 1
  end

  describe '#should_verify_repository?' do
    context 'repository' do
      let(:project_state) { create(:project_state, project: create(:project, :repository))}
      let(:registry) do
        registry = create(:geo_project_registry, project: project_state.project)
        registry.project.last_repository_updated_at     = 7.hours.ago
        registry.project.state.last_repository_check_at = 5.hours.ago
        registry.last_repository_successful_sync_at     = 5.hours.ago

        registry
      end

      it 'verifies the repository' do
        expect(subject.send(:should_verify_repository?, registry, :repository)).to be_truthy
      end

      it 'does not verify if repository was updated after checksum' do
        registry.project.last_repository_updated_at     = 4.hours.ago
        registry.project.state.last_repository_check_at = 5.hours.ago

        expect(subject.send(:should_verify_repository?, registry, :repository)).to be_falsy
      end

      it 'does not verify if repository was updated after sync as done' do
        registry.project.last_repository_updated_at = 4.hours.ago
        registry.last_repository_successful_sync_at = 5.hours.ago

        expect(subject.send(:should_verify_repository?, registry, :repository)).to be_falsy
      end

      it 'does not verify if never synced' do
        registry.last_repository_successful_sync_at = nil

        expect(subject.send(:should_verify_repository?, registry, :repository)).to be_falsy
      end

      it 'has been at least 6 hours since the primary repository was updated' do
        registry.project.last_repository_updated_at = 7.hours.ago

        expect(subject.send(:should_verify_repository?, registry, :repository)).to be_truthy

        registry.project.last_repository_updated_at = (5.5).hours.ago

        expect(subject.send(:should_verify_repository?, registry, :repository)).to be_falsy
      end
    end

    context 'wiki' do
      let(:project_state) { create(:project_state, project: create(:project, :repository))}
      let(:registry) do
        registry = create(:geo_project_registry, project: project_state.project)
        registry.project.last_repository_updated_at = 7.hours.ago
        registry.project.state.last_wiki_check_at = 5.hours.ago
        registry.last_wiki_successful_sync_at     = 5.hours.ago

        registry
      end

      it 'verifies the repository' do
        expect(subject.send(:should_verify_repository?, registry, :wiki)).to be_truthy
      end

      it 'does not verify if repository was updated after checksum' do
        registry.project.last_repository_updated_at = 4.hours.ago
        registry.project.state.last_wiki_check_at   = 5.hours.ago

        expect(subject.send(:should_verify_repository?, registry, :wiki)).to be_falsy
      end

      it 'does not verify if repository was updated after sync as done' do
        registry.project.last_repository_updated_at = 4.hours.ago
        registry.last_wiki_successful_sync_at = 5.hours.ago

        expect(subject.send(:should_verify_repository?, registry, :wiki)).to be_falsy
      end

      it 'does not verify if never synced' do
        registry.last_wiki_successful_sync_at = nil

        expect(subject.send(:should_verify_repository?, registry, :wiki)).to be_falsy
      end

      it 'has been at least 6 hours since the primary repository was updated' do
        registry.project.last_repository_updated_at = 7.hours.ago

        expect(subject.send(:should_verify_repository?, registry, :wiki)).to be_truthy

        registry.project.last_repository_updated_at = (5.5).hours.ago

        expect(subject.send(:should_verify_repository?, registry, :wiki)).to be_falsy
      end
    end
  end

  describe '#record_status' do
    let(:registry) { create(:geo_project_registry) }

    context 'for a repository' do
      it 'records a successful verification' do
        subject.send(:record_status, registry, :repository, checksum: 'my_checksum')
        registry.reload

        expect(registry.repository_checksum).to eq 'my_checksum'
        expect(registry.last_repository_verification_at).not_to be_nil
        expect(registry.last_repository_verification_failure).to be_nil
      end

      it 'records a failure' do
        subject.send(:record_status, registry, :repository, error: 'Repository checksum did not match')
        registry.reload

        expect(registry.repository_checksum).to be_nil
        expect(registry.last_repository_verification_at).to be_nil
        expect(registry.last_repository_verification_failure).to eq 'Repository checksum did not match'
      end
    end

    context 'for a wiki' do
      it 'records a successful verification' do
        subject.send(:record_status, registry, :wiki, checksum: 'my_checksum')
        registry.reload

        expect(registry.wiki_checksum).to eq 'my_checksum'
        expect(registry.last_wiki_verification_at).not_to be_nil
        expect(registry.last_wiki_verification_failure).to be_nil
      end

      it 'records a failure' do
        subject.send(:record_status, registry, :wiki, error: 'Wiki checksum did not match')
        registry.reload

        expect(registry.wiki_checksum).to be_nil
        expect(registry.last_wiki_verification_at).to be_nil
        expect(registry.last_wiki_verification_failure).to eq 'Wiki checksum did not match'
      end
    end
  end
end
