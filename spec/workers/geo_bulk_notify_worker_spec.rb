require 'rails_helper'

describe GeoBulkNotifyWorker do
  describe '#perform' do
    it 'executes Geo::NotifyNodesService if can obtain a lease' do
      allow_any_instance_of(Gitlab::ExclusiveLease)
        .to receive(:try_obtain).and_return(true)
      expect_any_instance_of(Geo::NotifyNodesService).to receive(:execute)

      described_class.new.perform
    end

    it 'just returns if cannot obtain a lease' do
      allow_any_instance_of(Gitlab::ExclusiveLease)
        .to receive(:try_obtain).and_return(false)
      expect_any_instance_of(Geo::NotifyNodesService).not_to receive(:execute)

      described_class.new.perform
    end
  end
end
