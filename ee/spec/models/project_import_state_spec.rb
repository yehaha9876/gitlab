require 'rails_helper'

describe ProjectImportState, type: :model do
  describe 'when create' do
    it 'sets next execution timestamp to now' do
      Timecop.freeze(Time.now) do
        import_state = create(:project, :mirror).import_state

        expect(import_state.next_execution_timestamp).to eq(Time.now)
      end
    end
  end

  describe '#mirror_waiting_duration' do
    it 'returns in seconds the time spent in the queue' do
      import_state = create(:project, :mirror, :import_scheduled).import_state

      import_state.update_attributes(last_update_started_at: import_state.last_update_scheduled_at + 5.minutes)

      expect(import_state.waiting_duration).to eq(300)
    end
  end

  describe '#update_duration' do
    it 'returns in seconds the time spent updating' do
      import_state = create(:project, :mirror, :import_started).import_state

      import_state.update_attributes(last_update_at: import_state.last_update_started_at + 5.minutes)

      expect(import_state.update_duration).to eq(300)
    end
  end

  describe  '#mirror?' do
    context 'when repository is empty' do
      it 'returns false' do
        import_state = create(:project, :mirror, :import_started).import_state

        expect(import_state.updating?).to be false
      end
    end

    context 'when project is not a mirror' do
      it 'returns false' do
        import_state = create(:project, :import_started).import_state

        expect(import_state.updating?).to be false
      end
    end

    context 'when mirror is started' do
      it 'returns true' do
        import_state = create(:project, :mirror, :import_started, :repository).import_state

        expect(import_state.updating?).to be true
      end
    end

    context 'when mirror is scheduled' do
      it 'returns true' do
        import_state = create(:project, :mirror, :import_scheduled, :repository).import_state

        expect(import_state.updating?).to be true
      end
    end
  end

  describe '#mirror_about_to_update?' do
    context 'when mirror is expected to run soon' do
      it 'returns true' do
        timestamp = Time.now
        import_state = create(:project, :mirror, :import_finished, :repository).import_state
        import_state.last_update_at = timestamp - 3.minutes
        import_state.next_execution_timestamp = timestamp - 2.minutes

        expect(import_state.about_to_update?).to be true
      end
    end

    context 'when mirror was scheduled' do
      it 'returns false' do
        import_state = create(:project, :mirror, :import_scheduled, :repository).import_state

        expect(import_state.about_to_update?).to be false
      end
    end

    context 'when mirror is hard_failed' do
      it 'returns false' do
        import_state = create(:project, :mirror, :import_hard_failed).import_state

        expect(import_state.about_to_update?).to be false
      end
    end
  end

  describe '#last_update_status' do
    let(:import_state) { create(:project, :mirror).import_state }

    context 'when mirror has not updated' do
      it 'returns nil' do
        expect(import_state.last_update_status).to be_nil
      end
    end

    context 'when mirror has updated' do
      let(:timestamp) { Time.now }

      before do
        import_state.last_update_at = timestamp
      end

      context 'when last update time equals the time of the last successful update' do
        it 'returns success' do
          import_state.last_successful_update_at = timestamp

          expect(import_state.last_update_status).to eq(:success)
        end
      end

      context 'when last update time does not equal the time of the last successful update' do
        it 'returns failed' do
          import_state.last_successful_update_at = Time.now - 1.minute

          expect(import_state.last_update_status).to eq(:failed)
        end
      end
    end
  end

  describe '#import_in_progress?' do
    let(:traits) { [] }
    let(:import_state) { create(:project, *traits, import_url: Project::UNKNOWN_IMPORT_URL).import_state }

    shared_examples 'import in progress' do
      context 'when project is a mirror' do
        before do
          traits << :mirror
        end

        context 'when repository is empty' do
          it 'returns true' do
            expect(import_state.import_in_progress?).to be_truthy
          end
        end

        context 'when repository is not empty' do
          before do
            traits << :repository
          end

          it 'returns false' do
            expect(import_state.import_in_progress?).to be_falsey
          end
        end
      end

      context 'when project is not a mirror' do
        it 'returns true' do
          expect(import_state.import_in_progress?).to be_truthy
        end
      end
    end

    context 'when import status is scheduled' do
      before do
        traits << :import_scheduled
      end

      it_behaves_like 'import in progress'
    end

    context 'when import status is started' do
      before do
        traits << :import_started
      end

      it_behaves_like 'import in progress'
    end

    context 'when import status is finished' do
      before do
        traits << :import_finished
      end

      it 'returns false' do
        expect(import_state.import_in_progress?).to be_falsey
      end
    end
  end

  describe '#reset_retry_count' do
    let(:import_state) { create(:project, :mirror, :import_finished).import_state }

    it 'resets retry_count to 0' do
      import_state.retry_count = 3

      expect { import_state.reset_retry_count }.to change { import_state.retry_count }.from(3).to(0)
    end
  end

  describe '#increment_retry_count' do
    let(:import_state) { create(:project, :mirror, :import_finished).import_state }

    it 'increments retry_count' do
      expect { import_state.increment_retry_count }.to change { import_state.retry_count }.from(0).to(1)
    end
  end

  describe '#set_next_execution_timestamp' do
    let(:import_state) { create(:project, :mirror, :import_finished).import_state }
    let!(:timestamp) { Time.now }
    let!(:jitter) { 2.seconds }

    before do
      allow_any_instance_of(ProjectImportState).to receive(:rand).and_return(jitter)
    end

    context 'when base delay is lower than mirror_max_delay' do
      before do
        import_state.last_update_started_at = timestamp - 2.minutes
      end

      context 'when retry count is 0' do
        it 'applies transition successfully' do
          expect_next_execution_timestamp(import_state, timestamp + 52.minutes)
        end
      end

      context 'when incrementing retry count' do
        it 'applies transition successfully' do
          import_state.retry_count = 2
          import_state.increment_retry_count

          expect_next_execution_timestamp(import_state, timestamp + 156.minutes)
        end
      end
    end

    context 'when boundaries are surpassed' do
      let!(:mirror_jitter) { 30.seconds }

      before do
        allow(Gitlab::Mirror).to receive(:rand).and_return(mirror_jitter)
      end

      context 'when last_update_started_at is nil' do
        it 'applies transition successfully' do
          expect_next_execution_timestamp(import_state, timestamp + 30.minutes + mirror_jitter)
        end
      end

      context 'when base delay is lower than mirror min_delay' do
        before do
          import_state.last_update_started_at = timestamp - 1.second
        end

        context 'when resetting retry count' do
          it 'applies transition successfully' do
            expect_next_execution_timestamp(import_state, timestamp + 30.minutes + mirror_jitter)
          end
        end

        context 'when incrementing retry count' do
          it 'applies transition successfully' do
            import_state.retry_count = 3
            import_state.increment_retry_count

            expect_next_execution_timestamp(import_state, timestamp + 122.minutes)
          end
        end
      end

      context 'when base delay is higher than mirror_max_delay' do
        let(:max_timestamp) { timestamp + Gitlab::CurrentSettings.mirror_max_delay.minutes }

        before do
          import_state.last_update_started_at = timestamp - 1.hour
        end

        context 'when resetting retry count' do
          it 'applies transition successfully' do
            expect_next_execution_timestamp(import_state, max_timestamp + mirror_jitter)
          end
        end

        context 'when incrementing retry count' do
          it 'applies transition successfully' do
            import_state.retry_count = 2
            import_state.increment_retry_count

            expect_next_execution_timestamp(import_state, max_timestamp + mirror_jitter)
          end
        end
      end
    end

    def expect_next_execution_timestamp(import_state, new_timestamp)
      Timecop.freeze(timestamp) do
        expect do
          import_state.set_next_execution_timestamp
        end.to change { import_state.next_execution_timestamp }.to eq(new_timestamp)
      end
    end
  end
end
