require 'spec_helper'

describe Security::StoreReportsService, '#execute' do
  let(:pipeline) { create(:ci_pipeline) }

  subject { described_class.new(pipeline).execute }

  context 'when there are reports' do
    before do
      create(:ee_ci_build, :security_reports, pipeline: pipeline)
    end

    it 'initializes a new StoreReportService and execute it' do
      expect(Security::StoreReportService).to receive(:new)
        .with(pipeline).and_call_original

      expect_any_instance_of(Security::StoreReportService).to receive(:execute)
        .once.and_call_original

      subject
    end

    context 'when StoreReportService returns an error for a report' do
      let(:reports) { Gitlab::Ci::Reports::Security::Reports.new(pipeline) }
      let(:sast_report) { reports.get_report('sast') }
      let(:dast_report) { reports.get_report('dast') }
      let(:success) { { status: :success } }
      let(:error) { { status: :error, message: "something went wrong" } }

      before do
        allow(pipeline).to receive(:security_reports).and_return(reports)
        allow_any_instance_of(Security::StoreReportService).to receive(:execute)
          .with(sast_report).and_return(error)
        allow_any_instance_of(Security::StoreReportService).to receive(:execute)
          .with(dast_report).and_return(success)
      end

      it 'returns the errors after having processed all reports' do
        expect(Security::StoreReportService).to receive(:new)
        .twice.with(pipeline).and_call_original

        is_expected.to eq(error)
      end
    end
  end
end
