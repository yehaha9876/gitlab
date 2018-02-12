require 'spec_helper'

describe Gitlab::Ci::Trace::Migrator do
  include TraceHelpers

  describe '#perform' do
    let!(:job) { create(:ci_build, :success) }
    let(:trace_content) { File.read(expand_fixture_path('trace/sample_trace')) }

    let(:builds_path) { Rails.root.join('tmp/tests/builds').to_s }
    let(:yyyy_mm) { job.created_at.utc.strftime("%Y_%m") }
    let(:project_id) { job.project.id }
    let(:job_id) { job.id }

    context 'when trace file is found' do
      context 'when project of job is found' do
        context 'when job is found' do
          context 'when job is complete' do
            context 'when job does not have trace artifact' do
              it 'migrates' do
                create_trace_file(builds_path, yyyy_mm, project_id, job_id, trace_content) do |path|
                  described_class.new(path.remove(builds_path)).perform

                  expect(job.job_artifacts_trace.file.exists?).to be_truthy
                  expect(job.trace.raw).to eq(trace_content)
                  expect(File.exist?(path)).to be_falsy
                  expect(File.exist?(extend_path(path, :migrated))).to be_truthy
                  expect(File.exist?(extend_path(path, :tmp))).to be_falsy
                end
              end

              context 'when checksum is mismatched between trace artifact and src file' do
                it 'raises an error' do
                  allow_any_instance_of(JobArtifactUploader).to receive(:read) { 'data is not same' }

                  create_trace_file(builds_path, yyyy_mm, project_id, job_id, trace_content) do |path|
                    expect { described_class.new(path.remove(builds_path)).perform }
                      .to raise_error(Gitlab::Ci::Trace::Migrator::ChecksumMismatchError)

                    expect(job.job_artifacts_trace).to be_nil
                    expect(File.exist?(path)).to be_truthy
                    expect(File.exist?(extend_path(path, :tmp))).to be_falsy
                  end
                end
              end
            end

            context 'when job has trace artifact' do
              before do
                create(:ci_job_artifact, :trace, job: job)
              end

              it 'does not migrates but moves file' do
                create_trace_file(builds_path, yyyy_mm, project_id, job_id, trace_content) do |path|
                  described_class.new(path.remove(builds_path)).perform

                  expect(job.job_artifacts_trace).to exist
                  expect(File.exist?(path)).to be_falsy
                  expect(File.exist?(extend_path(path, :duplicate))).to be_truthy
                  expect(File.exist?(extend_path(path, :tmp))).to be_falsy
                end
              end
            end
          end

          context 'when job is not complete' do
            let!(:job) { create(:ci_build, :running) }

            it 'does not migrate' do
              create_trace_file(builds_path, yyyy_mm, project_id, job_id, trace_content) do |path|
                expect { described_class.new(path.remove(builds_path)).perform }
                  .to raise_error(Gitlab::Ci::Trace::Migrator::JobNotCompletedError)

                expect(job.job_artifacts_trace).to be_nil
                expect(File.exist?(path)).to be_truthy
                expect(File.exist?(extend_path(path, :tmp))).to be_falsy
              end
            end
          end
        end

        context 'when job is not found' do
          let(:job_id) { 12345 }

          it 'does not migrates but moves file' do
            create_trace_file(builds_path, yyyy_mm, project_id, job_id, trace_content) do |path|
              described_class.new(path.remove(builds_path)).perform

              expect(job.job_artifacts_trace).to be_nil
              expect(File.exist?(path)).to be_falsy
              expect(File.exist?(extend_path(path, :not_found))).to be_truthy
              expect(File.exist?(extend_path(path, :tmp))).to be_falsy
            end
          end
        end
      end

      context 'when project of job is not found' do
        it 'does not migrates but moves file' do
          create_trace_file(builds_path, yyyy_mm, project_id, job_id, trace_content) do |path|
            job.update_attribute(:project_id, nil)

            described_class.new(path.remove(builds_path)).perform

            expect(job.job_artifacts_trace).to be_nil
            expect(File.exist?(path)).to be_falsy
            expect(File.exist?(extend_path(path, :not_found))).to be_truthy
            expect(File.exist?(extend_path(path, :tmp))).to be_falsy
          end
        end
      end
    end

    context 'when trace file is not found' do
      let(:path) { File.join(builds_path, yyyy_mm, project_id.to_s, "#{job_id}.log") }

      it 'raises error' do
        expect { described_class.new(path).perform }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when trace file is in yyyy_mm_migrated directory' do
      let(:yyyy_mm) { "#{job.created_at.utc.strftime("%Y_%m")}_migrated" }

      it 'raises error' do
        create_trace_file(builds_path, yyyy_mm, project_id, job_id, trace_content) do |path|
          expect { described_class.new(path.remove(builds_path)).perform }
            .to raise_error('Invalid trace path format')

          expect(job.job_artifacts_trace).to be_nil
          expect(File.exist?(path)).to be_truthy
          expect(File.exist?(extend_path(path, :tmp))).to be_falsy
        end
      end
    end
  end
end
