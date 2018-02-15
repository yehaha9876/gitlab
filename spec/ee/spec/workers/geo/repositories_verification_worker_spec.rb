require 'spec_helper'

describe Geo::RepositoriesVerificationWorker do
  include ::EE::GeoHelpers

  let(:primary)   { create(:geo_node, :primary) }
  let(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(true)
  end

  subject { described_class.new }

  describe '#perform' do
    it 'only works on the secondary' do
      stub_current_geo_node(primary)

      expect(subject).not_to receive(:try_obtain_lease)

      subject.perform
    end

    it 'verifies several projects' do
      create(:geo_project_registry)
      create(:geo_project_registry)
      create(:geo_project_registry, :repository_checksum)

      expect(subject).to receive(:verify_project).twice

      subject.perform
    end
  end

  describe '#verify_project' do
    let(:registry) { create(:geo_project_registry, project: create(:project, :repository)) }

    it 'verifies both repository and wiki' do
      allow(Geo::RepositoryVerifySecondaryService).to receive(:should_verify_repository?).with(registry, :repository).and_return(true)
      allow(Geo::RepositoryVerifySecondaryService).to receive(:should_verify_repository?).with(registry, :wiki).and_return(true)

      expect(Geo::RepositoryVerifySecondaryWorker).to receive(:perform_async).with(registry, :repository).once
      expect(Geo::RepositoryVerifySecondaryWorker).to receive(:perform_async).with(registry, :wiki).once

      subject.verify_project(registry)
    end

    it 'verifies only the repository' do
      allow(Geo::RepositoryVerifySecondaryService).to receive(:should_verify_repository?).with(registry, :repository).and_return(true)
      allow(Geo::RepositoryVerifySecondaryService).to receive(:should_verify_repository?).with(registry, :wiki).and_return(false)

      expect(Geo::RepositoryVerifySecondaryWorker).to receive(:perform_async).once

      subject.verify_project(registry)
    end

    it 'verifies only the wiki' do
      allow(Geo::RepositoryVerifySecondaryService).to receive(:should_verify_repository?).with(registry, :repository).and_return(false)
      allow(Geo::RepositoryVerifySecondaryService).to receive(:should_verify_repository?).with(registry, :wiki).and_return(true)

      expect(Geo::RepositoryVerifySecondaryWorker).to receive(:perform_async).once

      subject.verify_project(registry)
    end
  end

  it '#find_registries_without_checksum' do
    create(:geo_project_registry)
    create(:geo_project_registry, :repository_checksum)
    create(:geo_project_registry, :repository_checksum)

    expect(subject.send(:find_registries_without_checksum).count).to eq 1
  end
end
