require 'spec_helper'

describe Geo::CiTraceRegistryFinder, :geo do
  using RSpec::Parameterized::TableSyntax
  include ::EE::GeoHelpers

  set(:secondary) { create(:geo_node) }
  set(:synced_group) { create(:group) }
  set(:synced_project) { create(:project, group: synced_group) }
  set(:unsynced_project) { create(:project) }

  subject { described_class.new(current_node: secondary) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#count_synced_ci_traces' do
    let(:ci_build_1) { create(:ci_build, :success, project: synced_project) }
    let(:ci_build_2) { create(:ci_build, :canceled, project: synced_project) }
    let(:ci_build_3) { create(:ci_build, :failed, project: unsynced_project) }

    it 'delegates to #find_synced_ci_traces_registries' do
      expect(subject).to receive(:find_synced_ci_traces_registries).and_call_original

      subject.count_synced_ci_traces
    end

    it 'counts CI traces that have been synced' do
      create(:geo_file_registry, :ci_trace, file_id: ci_build_1.id, success: false)
      create(:geo_file_registry, :ci_trace, file_id: ci_build_2.id)
      create(:geo_file_registry, :ci_trace, file_id: ci_build_3.id)

      expect(subject.count_synced_ci_traces).to eq 2
    end

    context 'with selective sync' do
      before do
        secondary.update_attribute(:namespaces, [synced_group])
      end

      it 'delegates to #legacy_find_synced_ci_traces' do
        expect(subject).to receive(:legacy_find_synced_ci_traces).and_call_original

        subject.count_synced_ci_traces
      end

      it 'counts CI traces that have been synced' do
        create(:geo_file_registry, :ci_trace, file_id: ci_build_1.id, success: false)
        create(:geo_file_registry, :ci_trace, file_id: ci_build_2.id)
        create(:geo_file_registry, :ci_trace, file_id: ci_build_3.id)

        expect(subject.count_synced_ci_traces).to eq 1
      end
    end
  end

  describe '#count_failed_ci_traces' do
    let(:ci_build_1) { create(:ci_build, :success, project: synced_project) }
    let(:ci_build_2) { create(:ci_build, :canceled, project: synced_project) }
    let(:ci_build_3) { create(:ci_build, :failed, project: unsynced_project) }

    it 'delegates to #find_failed_ci_traces_registries' do
      expect(subject).to receive(:find_failed_ci_traces_registries).and_call_original

      subject.count_failed_ci_traces
    end

    it 'counts CI traces that sync has failed' do
      create(:geo_file_registry, :ci_trace, file_id: ci_build_1.id, success: false)
      create(:geo_file_registry, :ci_trace, file_id: ci_build_2.id)
      create(:geo_file_registry, :ci_trace, file_id: ci_build_3.id, success: false)

      expect(subject.count_failed_ci_traces).to eq 2
    end

    context 'with selective sync' do
      before do
        secondary.update_attribute(:namespaces, [synced_group])
      end

      it 'delegates to #legacy_find_failed_ci_traces' do
        expect(subject).to receive(:legacy_find_failed_ci_traces).and_call_original

        subject.count_failed_ci_traces
      end

      it 'counts CI traces that sync has failed' do
        create(:geo_file_registry, :ci_trace, file_id: ci_build_1.id, success: false)
        create(:geo_file_registry, :ci_trace, file_id: ci_build_2.id)
        create(:geo_file_registry, :ci_trace, file_id: ci_build_3.id, success: false)

        expect(subject.count_failed_ci_traces).to eq 1
      end
    end
  end

  describe '#ci_traces' do
    context 'without selective sync' do
      where(:build_status, :has_old_trace, :expected) do
        'success'  | nil         | true
        'failed'   | nil         | true
        'canceled' | nil         | true
        'created'  | nil         | false
        'pending'  | nil         | false
        'running'  | nil         | false
        'skipped'  | nil         | false
        'manual'   | nil         | false
        'success'  | 'some_data' | false
        'failed'   | 'some_data' | false
        'canceled' | 'some_data' | false
        'created'  | 'some_data' | false
        'pending'  | 'some_data' | false
        'running'  | 'some_data' | false
        'skipped'  | 'some_data' | false
        'manual'   | 'some_data' | false
      end

      with_them do
        let!(:build) { create(:ci_build, status: build_status) }

        before do
          build.update_column(:trace, has_old_trace)
        end

        it 'includes or does not include the build as expected' do
          expect(subject.ci_traces.include?(build)).to eq(expected)
        end
      end
    end

    context 'with selective sync' do
      before do
        secondary.update_attribute(:namespaces, [synced_group])
      end

      context 'when the build is in an synced project' do
        where(:build_status, :has_old_trace, :expected) do
          'success'  | nil         | true
          'failed'   | nil         | true
          'canceled' | nil         | true
          'created'  | nil         | false
          'pending'  | nil         | false
          'running'  | nil         | false
          'skipped'  | nil         | false
          'manual'   | nil         | false
          'success'  | 'some_data' | false
          'failed'   | 'some_data' | false
          'canceled' | 'some_data' | false
          'created'  | 'some_data' | false
          'pending'  | 'some_data' | false
          'running'  | 'some_data' | false
          'skipped'  | 'some_data' | false
          'manual'   | 'some_data' | false
        end

        with_them do
          let!(:build) { create(:ci_build, status: build_status, project: synced_project) }

          before do
            build.update_column(:trace, has_old_trace)
          end

          it 'excludes the build' do
            expect(subject.ci_traces.include?(build)).to eq(expected)
          end
        end
      end

      context 'when the build is in an unsynced project' do
        where(build_status: %w[success failed canceled created pending running skipped manual], has_old_trace: [nil, 'some_data'])

        with_them do
          let!(:build) { create(:ci_build, status: build_status, project: unsynced_project) }

          before do
            build.update_column(:trace, has_old_trace)
          end

          it 'excludes the build' do
            expect(subject.ci_traces.include?(build)).to be_falsy
          end
        end
      end
    end
  end
end
