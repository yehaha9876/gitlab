require 'rails_helper'

describe ProjectMirrorData, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe 'when create' do
    it 'sets next execution timestamp to now' do
      project = create(:project)

      Timecop.freeze(Time.now) do
        project.create_import_state

        expect(project.import_state.next_execution_timestamp).to eq(Time.now)
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
      allow_any_instance_of(ProjectMirrorData).to receive(:rand).and_return(jitter)
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
