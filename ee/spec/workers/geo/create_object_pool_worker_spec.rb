# frozen_string_literal: true

require 'spec_helper'

describe Geo::CreateObjectPoolWorker do
  let(:pool) { create(:pool_repository, :ready) }

  subject { described_class.new }

  describe '#perform' do
    context 'when there is no object pool' do
      before do
        pool.delete_object_pool
      end

      it 'creates the object pool' do
        expect( subject ).to receive(:perform_pool_creation)

        subject.perform(pool.id)
      end
    end

    context 'when an object pool already exists' do
      it "doesn't try to create another object pool" do
        expect( subject ).not_to receive(:perform_pool_creation)

        subject.perform(pool.id)
      end
    end
  end
end
