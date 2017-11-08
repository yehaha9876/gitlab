require 'spec_helper'

describe Projects::HashedStorageMigrationService do
  let(:project) { create(:project, :empty_repo, :wiki_repo) }
  let(:service) { described_class.new(project) }
  let(:legacy_storage) { Storage::LegacyProject.new(project) }
  let(:hashed_storage) { Storage::HashedProject.new(project) }

  describe '#execute' do
    set(:primary) { create(:geo_node, :primary) }
    set(:secondary) { create(:geo_node) }

    it 'creates a Geo::HashedStorageMigratedEvent on success' do
      expect { service.execute }.to change(Geo::EventLog, :count).by(1)

      event = Geo::EventLog.first.event

      expect(event).to be_a(Geo::HashedStorageMigratedEvent)
      expect(event).to have_attributes(
        old_storage_version: nil,
        new_storage_version: Storage::HashedProject::STORAGE_VERSION,
        old_disk_path: legacy_storage.disk_path,
        new_disk_path: hashed_storage.disk_path,
        old_wiki_disk_path: legacy_storage.disk_path + '.wiki',
        new_wiki_disk_path: hashed_storage.disk_path + '.wiki'
      )
    end

    it 'does not create a Geo event on failure' do
      from_name = project.disk_path
      to_name = hashed_storage.disk_path

      allow(service).to receive(:move_repository).and_call_original
      allow(service).to receive(:move_repository).with(from_name, to_name).once { false } # will disable first move only

      expect { service.execute }.not_to change { Geo::EventLog.count }
    end
  end
end
