require 'spec_helper'

describe Gitlab::Geo::CiTraceDownloader, :geo do
  context '#execute' do
    context 'when the build exists' do
      let(:build) { create(:ci_build, :success) }

      it 'returns the result of CiTraceTransfer#download_from_primary' do
        transfer = double(:transfer)
        expect(transfer).to receive(:download_from_primary).and_return(1234)
        expect(Ci::Build).to receive(:find_by).and_return(build)
        expect(Gitlab::Geo::CiTraceTransfer).to receive(:new).and_return(transfer)

        expect(described_class.new(:ci_trace, build.id).execute).to eq(1234)
      end
    end

    context 'when the build does not exist' do
      it 'returns nil' do
        downloader = described_class.new(:ci_trace, 10000)
        expect(Gitlab::Geo::CiTraceTransfer).not_to receive(:new)

        expect(downloader.execute).to be_nil
      end
    end
  end
end
