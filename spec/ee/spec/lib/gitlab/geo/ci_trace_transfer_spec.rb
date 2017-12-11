require 'spec_helper'

describe Gitlab::Geo::CiTraceTransfer, :geo do
  let(:build) { create(:ci_build, :success) }

  context '#initialize' do
    it 'sets file_type to :ci_trace' do
      expect(described_class.new(build).file_type).to eq(:ci_trace)
    end

    it 'sets file_id to the build ID' do
      expect(described_class.new(build).file_id).to eq(build.id)
    end

    it 'sets filename to build default_path' do
      expect(described_class.new(build).filename).to eq(build.trace.default_path)
    end

    it 'sets request_data with file_id and file_type' do
      expect(described_class.new(build).request_data).to eq(id: build.id, type: :ci_trace)
    end
  end
end
