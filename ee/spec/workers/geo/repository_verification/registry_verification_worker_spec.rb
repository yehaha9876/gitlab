require 'spec_helper'

describe Geo::RepositoryVerification::RegistryVerificationWorker, :geo do
  include ::EE::GeoHelpers

  let(:primary)   { create(:geo_node, :primary) }
  let(:secondary) { create(:geo_node) }
  let(:registry)  { create(:geo_project_registry, project: create(:project, :repository)) }

  before do
    stub_current_geo_node(secondary)
    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(true)
  end

  subject(:worker) { described_class.new }

  describe '#perform' do
    it 'only works on the secondary' do
      stub_current_geo_node(primary)

      expect(worker).not_to receive(:schedule_job)

      worker.perform
    end

    it 'only works when node is enabled' do
      allow_any_instance_of(GeoNode).to receive(:enabled?) { false }

      expect(worker).not_to receive(:schedule_job)

      worker.perform
    end

    it 'verifies both repository and wiki' do
      allow(Geo::RepositoryVerifySecondaryService).to receive(:should_verify_repository?).with(registry, :repository).and_return(true)
      allow(Geo::RepositoryVerifySecondaryService).to receive(:should_verify_repository?).with(registry, :wiki).and_return(true)

      expect(Geo::RepositoryVerification::VerifySecondaryWorker).to receive(:perform_async).with(registry, :repository).once
      expect(Geo::RepositoryVerification::VerifySecondaryWorker).to receive(:perform_async).with(registry, :wiki).once

      worker.perform
    end

    it 'verifies only the repository' do
      allow(Geo::RepositoryVerifySecondaryService).to receive(:should_verify_repository?).with(registry, :repository).and_return(true)
      allow(Geo::RepositoryVerifySecondaryService).to receive(:should_verify_repository?).with(registry, :wiki).and_return(false)

      expect(Geo::RepositoryVerification::VerifySecondaryWorker).to receive(:perform_async).with(registry, :repository).once
      expect(Geo::RepositoryVerification::VerifySecondaryWorker).not_to receive(:perform_async).with(registry, :wiki)

      worker.perform
    end

    it 'verifies only the wiki' do
      allow(Geo::RepositoryVerifySecondaryService).to receive(:should_verify_repository?).with(registry, :repository).and_return(false)
      allow(Geo::RepositoryVerifySecondaryService).to receive(:should_verify_repository?).with(registry, :wiki).and_return(true)

      expect(Geo::RepositoryVerification::VerifySecondaryWorker).not_to receive(:perform_async).with(registry, :repository)
      expect(Geo::RepositoryVerification::VerifySecondaryWorker).to receive(:perform_async).with(registry, :wiki).once

      worker.perform
    end

    it 'verifies several projects' do
      allow(Geo::RepositoryVerifySecondaryService).to receive(:should_verify_repository?).and_return(true)

      create(:geo_project_registry)
      create(:geo_project_registry)
      create(:geo_project_registry, :repository_verified, :wiki_verified)

      expect(Geo::RepositoryVerification::VerifySecondaryWorker).to receive(:perform_async).exactly(4).times

      worker.perform
    end
  end
end
