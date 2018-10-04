# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::Occurrence do
  it { is_expected.to define_enum_for(:report_type) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:pipeline) }
    it { is_expected.to belong_to(:scanner).class_name('Vulnerabilities::Scanner') }
    it { is_expected.to have_many(:identifiers).class_name('Vulnerabilities::Identifier') }
    it { is_expected.to have_many(:occurrence_identifiers).class_name('Vulnerabilities::OccurrenceIdentifier') }
  end

  describe 'validations' do
    let(:occurrence) { build(:vulnerabilities_occurrence) }

    it { is_expected.to validate_presence_of(:scanner) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:pipeline) }
    it { is_expected.to validate_presence_of(:ref) }
    it { is_expected.to validate_presence_of(:uuid) }
    it { is_expected.to validate_presence_of(:project_fingerprint) }
    it { is_expected.to validate_presence_of(:primary_identifier_fingerprint) }
    it { is_expected.to validate_presence_of(:location_fingerprint) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:report_type) }
    it { is_expected.to validate_presence_of(:metadata_version) }
    it { is_expected.to validate_presence_of(:raw_metadata) }
    it { is_expected.to validate_presence_of(:severity) }
    it { is_expected.to validate_inclusion_of(:severity).in_array(described_class::LEVELS.keys) }
    it { is_expected.to validate_presence_of(:confidence) }
    it { is_expected.to validate_inclusion_of(:confidence).in_array(described_class::LEVELS.keys) }
  end

  context 'database uniqueness' do
    let(:occurrence) { create(:vulnerabilities_occurrence) }
    let(:new_occurrence) { occurrence.dup.tap { |o| o.uuid = SecureRandom.uuid } }

    it "when all index attributes are identical" do
      expect { new_occurrence.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    describe 'when some parameters are changed' do
      using RSpec::Parameterized::TableSyntax

      # we use block to delay object creations
      where(:key, :value_block) do
        :primary_identifier_fingerprint | -> { '005b6966dd100170b4b1ad599c7058cce91b57b4' }
        :ref | -> { 'another_ref' }
        :scanner | -> { create(:vulnerabilities_scanner) }
        :pipeline | -> { create(:ci_pipeline) }
        :project | -> { create(:project) }
      end

      with_them do
        it "is valid" do
          expect { new_occurrence.update!({ key => value_block.call }) }.not_to raise_error
        end
      end
    end
  end

  describe '.latest_pipeline_id_for' do
    let(:report_type) { :sast }
    let(:ref) { 'master' }

    subject { described_class.latest_pipeline_id_for(report_type, ref) }

    context 'when occurrence has the corresponding report type and ref' do
      let!(:occurrence) { create(:vulnerabilities_occurrence, report_type: report_type, ref: ref) }

      it 'returns the pipeline_id' do
        is_expected.to eq(occurrence.pipeline_id)
      end
    end

    # This case is unlikely to happen has we cleanup occurences from previous pipeline
    context 'when there are occurrences from different pipelines for the corresponding report type and ref' do
      let!(:occurrence_1) { create(:vulnerabilities_occurrence, report_type: report_type, ref: ref) }
      let!(:occurrence_2) { create(:vulnerabilities_occurrence, :uuid, report_type: report_type, ref: ref) }

      it 'returns the latest pipeline_id' do
        is_expected.to eq(occurrence_2.pipeline_id)
      end
    end

    context 'when there is no occurrences with corresponding report type and ref' do
      let!(:occurrence) { create(:vulnerabilities_occurrence, report_type: :dependency_scanning) }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '.report_type' do
    let(:report_type) { :sast }

    subject { described_class.report_type(report_type) }

    context 'when occurrence has the corresponding report type' do
      let!(:occurrence) { create(:vulnerabilities_occurrence, report_type: report_type) }

      it 'selects the occurrence' do
        is_expected.to eq([occurrence])
      end
    end

    context 'when occurrence does not have security reports' do
      let!(:occurrence) { create(:vulnerabilities_occurrence, report_type: :dependency_scanning) }

      it 'does not select the occurrence' do
        is_expected.to be_empty
      end
    end
  end

  describe '.excluding_pipeline' do
    let(:pipeline) { create(:ci_pipeline) }

    subject { described_class.excluding_pipeline(pipeline.id) }

    context 'when occurrence belongs to the given pipeline' do
      let!(:occurrence) { create(:vulnerabilities_occurrence, pipeline: pipeline) }

      it 'does not select the occurrence' do
        is_expected.to be_empty
      end
    end

    context 'when occurrence does not belong to pipeline' do
      let!(:occurrence) { create(:vulnerabilities_occurrence) }

      it 'selects the occurrence' do
        is_expected.to eq([occurrence])
      end
    end
  end
end
