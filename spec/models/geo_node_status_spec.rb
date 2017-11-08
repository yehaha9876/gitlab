require 'spec_helper'

describe GeoNodeStatus, :geo do
  include ::EE::GeoHelpers

  set(:primary)  { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  set(:group)     { create(:group) }
  set(:project_1) { create(:project, group: group) }
  set(:project_2) { create(:project, group: group) }
  set(:project_3) { create(:project) }
  set(:project_4) { create(:project) }

  subject { described_class.current_node_status }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#healthy?' do
    context 'when health is blank' do
      it 'returns true' do
        subject.status_message = ''

        expect(subject.healthy?).to be true
      end
    end

    context 'when health is present' do
      it 'returns true' do
        subject.status_message = 'Healthy'

        expect(subject.healthy?).to be true
      end

      it 'returns false' do
        subject.status_message = 'something went wrong'

        expect(subject.healthy?).to be false
      end
    end
  end

  describe '#status_message' do
    it 'delegates to the HealthCheck' do
      expect(HealthCheck::Utils).to receive(:process_checks).with(['geo']).once

      subject
    end
  end

  describe '#attachments_synced_count' do
    it 'only counts successful syncs' do
      create_list(:user, 3, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png'))
      uploads = Upload.all.pluck(:id)

      create(:geo_file_registry, :avatar, file_id: uploads[0])
      create(:geo_file_registry, :avatar, file_id: uploads[1])
      create(:geo_file_registry, :avatar, file_id: uploads[2], success: false)

      expect(subject.attachments_synced_count).to eq(2)
    end

    it 'does not count synced files that were replaced' do
      user = create(:user, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png'))

      expect(subject.attachments_count).to eq(1)
      expect(subject.attachments_synced_count).to eq(0)

      upload = Upload.find_by(model: user, uploader: 'AvatarUploader')
      create(:geo_file_registry, :avatar, file_id: upload.id)

      subject = described_class.current_node_status

      expect(subject.attachments_count).to eq(1)
      expect(subject.attachments_synced_count).to eq(1)

      user.update(avatar: fixture_file_upload(Rails.root + 'spec/fixtures/rails_sample.jpg', 'image/jpg'))

      subject = described_class.current_node_status

      expect(subject.attachments_count).to eq(1)
      expect(subject.attachments_synced_count).to eq(0)

      upload = Upload.find_by(model: user, uploader: 'AvatarUploader')
      create(:geo_file_registry, :avatar, file_id: upload.id)

      subject = described_class.current_node_status

      expect(subject.attachments_count).to eq(1)
      expect(subject.attachments_synced_count).to eq(1)
    end
  end

  describe '#attachments_failed_count' do
    it 'counts failed avatars, attachment, personal snippets and files' do
      # These two should be ignored
      create(:geo_file_registry, :lfs, success: false)
      create(:geo_file_registry)

      create(:geo_file_registry, file_type: :personal_file, success: false)
      create(:geo_file_registry, file_type: :attachment, success: false)
      create(:geo_file_registry, :avatar, success: false)
      create(:geo_file_registry, success: false)

      expect(subject.attachments_failed_count).to eq(4)
    end
  end

  describe '#attachments_synced_in_percentage' do
    let(:avatar) { fixture_file_upload(Rails.root.join('spec/fixtures/dk.png')) }
    let(:upload_1) { create(:upload, model: group, path: avatar) }
    let(:upload_2) { create(:upload, model: project_1, path: avatar) }

    before do
      create(:upload, model: create(:group), path: avatar)
      create(:upload, model: project_3, path: avatar)
    end

    it 'returns 0 when no objects are available' do
      expect(subject.attachments_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage with no group restrictions' do
      create(:geo_file_registry, :avatar, file_id: upload_1.id)
      create(:geo_file_registry, :avatar, file_id: upload_2.id)

      expect(subject.attachments_synced_in_percentage).to be_within(0.0001).of(50)
    end

    it 'returns the right percentage with group restrictions' do
      secondary.update_attribute(:namespaces, [group])
      create(:geo_file_registry, :avatar, file_id: upload_1.id)
      create(:geo_file_registry, :avatar, file_id: upload_2.id)

      expect(subject.attachments_synced_in_percentage).to be_within(0.0001).of(100)
    end
  end

  describe '#db_replication_lag_seconds' do
    it 'returns the set replication lag if secondary' do
      allow(Gitlab::Geo).to receive(:secondary?).and_return(true)
      allow(Gitlab::Geo::HealthCheck).to receive(:db_replication_lag_seconds).and_return(1000)

      expect(subject.db_replication_lag_seconds).to eq(1000)
    end

    it "doesn't attempt to set replication lag if primary" do
      stub_current_geo_node(primary)
      expect(Gitlab::Geo::HealthCheck).not_to receive(:db_replication_lag_seconds)

      expect(subject.db_replication_lag_seconds).to eq(nil)
    end
  end

  describe '#lfs_objects_failed' do
    it 'counts failed LFS objects' do
      # These four should be ignored
      create(:geo_file_registry, success: false)
      create(:geo_file_registry, :avatar, success: false)
      create(:geo_file_registry, file_type: :attachment, success: false)
      create(:geo_file_registry, :lfs)

      create(:geo_file_registry, :lfs, success: false)

      expect(subject.lfs_objects_failed_count).to eq(1)
    end
  end

  describe '#lfs_objects_synced_in_percentage' do
    let(:lfs_object_project) { create(:lfs_objects_project, project: project_1) }

    before do
      allow(ProjectCacheWorker).to receive(:perform_async).and_return(true)

      create(:lfs_objects_project, project: project_1)
      create_list(:lfs_objects_project, 2, project: project_3)
    end

    it 'returns 0 when no objects are available' do
      expect(subject.lfs_objects_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage with no group restrictions' do
      create(:geo_file_registry, :lfs, file_id: lfs_object_project.lfs_object_id, success: true)

      expect(subject.lfs_objects_synced_in_percentage).to be_within(0.0001).of(25)
    end

    it 'returns the right percentage with group restrictions' do
      secondary.update_attribute(:namespaces, [group])
      create(:geo_file_registry, :lfs, file_id: lfs_object_project.lfs_object_id, success: true)

      expect(subject.lfs_objects_synced_in_percentage).to be_within(0.0001).of(50)
    end
  end

  describe '#repositories_failed_count' do
    before do
      create(:geo_project_registry, :sync_failed, project: project_1)
      create(:geo_project_registry, :sync_failed, project: project_3)
    end

    it 'returns the right number of failed repos with no group restrictions' do
      expect(subject.repositories_failed_count).to eq(2)
    end

    it 'returns the right number of failed repos with group restrictions' do
      secondary.update_attribute(:namespaces, [group])

      expect(subject.repositories_failed_count).to eq(1)
    end
  end

  describe '#repositories_synced_in_percentage' do
    it 'returns 0 when no projects are available' do
      expect(subject.repositories_synced_in_percentage).to eq(0)
    end

    it 'returns 0 when project count is unknown' do
      allow(subject).to receive(:repositories_count).and_return(nil)

      expect(subject.repositories_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage with no group restrictions' do
      create(:geo_project_registry, :synced, project: project_1)

      expect(subject.repositories_synced_in_percentage).to be_within(0.0001).of(25)
    end

    it 'returns the right percentage with group restrictions' do
      secondary.update_attribute(:namespaces, [group])
      create(:geo_project_registry, :synced, project: project_1)

      expect(subject.repositories_synced_in_percentage).to be_within(0.0001).of(50)
    end
  end

  describe '#last_event_id and #last_event_date' do
    it 'returns nil when no events are available' do
      expect(subject.last_event_id).to be_nil
      expect(subject.last_event_date).to be_nil
    end

    it 'returns the latest event' do
      created_at = Date.today.to_time(:utc)
      event = create(:geo_event_log, created_at: created_at)

      expect(subject.last_event_id).to eq(event.id)
      expect(subject.last_event_date).to eq(created_at)
    end
  end

  describe '#cursor_last_event_id and #cursor_last_event_date' do
    it 'returns nil when no events are available' do
      expect(subject.cursor_last_event_id).to be_nil
      expect(subject.cursor_last_event_date).to be_nil
    end

    it 'returns the latest event ID if secondary' do
      allow(Gitlab::Geo).to receive(:secondary?).and_return(true)
      event = create(:geo_event_log_state)

      expect(subject.cursor_last_event_id).to eq(event.event_id)
    end

    it "doesn't attempt to retrieve cursor if primary" do
      stub_current_geo_node(primary)
      create(:geo_event_log_state)

      expect(subject.cursor_last_event_date).to eq(nil)
      expect(subject.cursor_last_event_id).to eq(nil)
    end
  end

  describe '#[]' do
    it 'returns values for each attribute' do
      expect(subject[:repositories_count]).to eq(4)
      expect(subject[:repositories_synced_count]).to eq(0)
    end

    it 'raises an error for invalid attributes' do
      expect { subject[:testme] }.to raise_error(NoMethodError)
    end
  end

  shared_examples 'timestamp parameters' do |timestamp_column, date_column|
    it 'returns the value it was assigned via UNIX timestamp' do
      now = Time.now.beginning_of_day.utc
      subject.update_attribute(timestamp_column, now.to_i)

      expect(subject.public_send(date_column)).to eq(now)
      expect(subject.public_send(timestamp_column)).to eq(now.to_i)
    end
  end

  describe '#last_successful_status_check_timestamp' do
    it_behaves_like 'timestamp parameters', :last_successful_status_check_timestamp, :last_successful_status_check_at
  end

  describe '#last_event_timestamp' do
    it_behaves_like 'timestamp parameters', :last_event_timestamp, :last_event_date
  end

  describe '#cursor_last_event_timestamp' do
    it_behaves_like 'timestamp parameters', :cursor_last_event_timestamp, :cursor_last_event_date
  end

  describe '#from_json' do
    it 'returns a new GeoNodeStatus excluding parameters' do
      status = create(:geo_node_status)

      data = status.as_json
      data[:id] = 10000

      result = GeoNodeStatus.from_json(data)

      expect(result.id).to be_nil
      expect(result.attachments_count).to eq(status.attachments_count)
      expect(result.cursor_last_event_date).to eq(status.cursor_last_event_date)
    end
  end
end
