require 'spec_helper'

describe Geo::FileDownloadWorker, :geo do
  describe '#perform' do
    it 'instantiates and executes FileDownloadService, and converts object_type to a symbol' do
      service = double(:service)
      expect(service).to receive(:execute)
      expect(Geo::FileDownloadService).to receive(:new).with(:ci_trace, 1).and_return(service)
      described_class.new.perform('ci_trace', 1)
    end
  end
end
