require 'spec_helper'

describe Gitlab::Ci::Reports::Security::Report do
  let(:report) { described_class.new('sast') }
  let(:vulnerability) { { foo: :bar } }

  it { expect(report.type).to eq('sast') }

  describe '#add_vulnerability' do
    it 'stores data correctly' do
      report.add_vulnerability(vulnerability)

      expect(report.vulnerabilities).to eq([vulnerability])
    end
  end
end
