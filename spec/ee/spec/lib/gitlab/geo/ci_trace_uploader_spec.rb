require 'spec_helper'

describe Gitlab::Geo::CiTraceUploader, :geo do
  context '#execute' do
    subject { described_class.new(build.id, {}).execute }

    context 'when the build exists' do
      context 'when the build has a trace' do
        let(:build) { create(:ci_build, :success, :trace) }

        it 'returns the file in a success hash' do
          file = double(:file)
          expect(CarrierWave::SanitizedFile).to receive(:new).with(build.trace.current_path).and_return(file)

          expect(subject).to eq(code: :ok, message: 'Success', file: file)
        end
      end

      context 'when the build does not have a trace' do
        let(:build) { create(:ci_build, :success) }

        it 'returns an error hash' do
          expect(subject).to eq(code: :not_found, message: "File not found")
        end
      end
    end

    context 'when the build does not exist' do
      let(:build) { double(id: 10000) }

      it 'returns an error hash' do
        expect(subject).to eq(code: :not_found, message: "File not found")
      end
    end
  end
end
