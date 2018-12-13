# frozen_string_literal: true

require 'spec_helper'

describe Security::VulnerabilitiesFinder do
  describe '#execute' do
    set(:group) { create(:group) }
    set(:project1) { create(:project, :private, :repository, group: group) }
    set(:project2) { create(:project, :private, :repository, group: group) }
    set(:pipeline1) { create(:ci_pipeline, :success, project: project1) }
    set(:pipeline2) { create(:ci_pipeline, :success, project: project2) }

    set(:vulnerability1) { create(:vulnerabilities_occurrence, report_type: :sast, severity: :high, pipelines: [pipeline1], project: project1) }
    set(:vulnerability2) { create(:vulnerabilities_occurrence, report_type: :dependency_scanning, severity: :medium, pipelines: [pipeline2], project: project2) }
    set(:vulnerability3) { create(:vulnerabilities_occurrence, report_type: :sast, severity: :low, pipelines: [pipeline2], project: project2) }
    set(:vulnerability4) { create(:vulnerabilities_occurrence, report_type: :dast, severity: :medium, pipelines: [pipeline1], project: project1) }

    subject { described_class.new(group: group, params: params).execute }

    context 'by report type' do
      context 'when sast' do
        let(:params) { { report_type: [0] } }
        it 'include only sast' do
          is_expected.to contain_exactly(vulnerability1, vulnerability3)
        end
      end
      context 'when dependency_scanning' do
        let(:params) { { report_type: [1] } }
        it 'include only depscan' do
          is_expected.to contain_exactly(vulnerability2)
        end
      end
    end

    context 'by severity' do
      context 'when high' do
        let(:params) { { severity: [6, 4]} }
        it 'include only high' do
          is_expected.to contain_exactly(vulnerability1, vulnerability3)
        end
      end
      context 'when medium' do
        let(:params) { { severity: [5] } }
        it 'include only medium' do
          is_expected.to contain_exactly(vulnerability2, vulnerability4)
        end
      end
    end

    context 'by project' do
      let(:params) { { project_id: [project2.id] } }
      it 'include only vulnerabilities for one project' do
        is_expected.to contain_exactly(vulnerability2, vulnerability3)
      end
    end

    context 'by all filters' do
      context 'with found entity' do
        let(:params) { { severity: [6, 5, 4], project_id: [project1.id, project2.id], report_type: [0, 3] } }
        it 'filter by all params' do
          is_expected.to contain_exactly(vulnerability1, vulnerability3, vulnerability4)
        end
      end
      context 'without search entity' do
        let(:params) { { severity: [4], project_id: [project1.id], report_type: [0] } }
        it 'did not find anything' do
          expect(subject.size).to eq 0
        end
      end
    end

    context 'by some filters' do
      context 'with found entity' do
        let(:params) { { project_id: [project2.id], severity: [5,4] } }
        it 'filter by all params' do
          is_expected.to contain_exactly(vulnerability2, vulnerability3)
        end
      end
      context 'without search entity' do
        let(:params) { { project_id: project1.id, severity: 4 } }
        it 'did not find anything' do
          expect(subject.size).to eq 0
        end
      end
    end
  end
end