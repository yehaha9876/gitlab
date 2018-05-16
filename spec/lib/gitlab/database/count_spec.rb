require 'spec_helper'

describe Gitlab::Database::Count do
  before do
    create_list(:project, 3)
  end

  describe '.approximate_count' do
    context 'when reltuples have not been updated' do
      it 'counts all projects the normal way' do
        allow(described_class).to receive(:reltuples_updated_recently?).and_return(false)

        expect(Project).to receive(:count).and_call_original
        expect(described_class.approximate_count(Project)).to eq(3)
      end
    end

    context 'no permission' do
      it 'falls back to standard query' do
        allow(described_class).to receive(:reltuples_updated_recently?).and_raise(PG::InsufficientPrivilege)

        expect(Project).to receive(:count).and_call_original
        expect(described_class.approximate_count(Project)).to eq(3)
      end
    end

    describe 'when reltuples have been updated', :postgresql do
      before do
        ActiveRecord::Base.connection.execute('ANALYZE projects')
      end

      it 'counts all projects in the fast way' do
        expect(described_class).to receive(:postgresql_estimate_query).with(Project).and_call_original

        expect(described_class.approximate_count(Project)).to eq(3)
      end
    end
  end
end
