require 'spec_helper'

describe Geo::BuildErasedEventStore do
  set(:secondary_node) { create(:geo_node) }
  let(:build) { create(:ci_build, :success, :trace) }

  subject(:event_store) { described_class.new(build) }

  describe '#create' do
    it 'does not create an event when not running on a primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect { event_store.create }.not_to change(Geo::BuildErasedEvent, :count)
    end

    context 'when running on a primary node' do
      before do
        allow(Gitlab::Geo).to receive(:primary?) { true }
      end

      it 'does not create an event when there are no secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { event_store.create }.not_to change(Geo::BuildErasedEvent, :count)
      end

      it 'creates a build erased event' do
        expect { event_store.create }.to change(Geo::BuildErasedEvent, :count).by(1)
      end

      it 'tracks build ID' do
        event_store.create

        event = Geo::BuildErasedEvent.last

        expect(event).to have_attributes(build_id: build.id)
      end
    end
  end
end
