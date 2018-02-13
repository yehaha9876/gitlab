require 'spec_helper'

describe Gitlab::Ci::Trace::FileIterator do
  include TraceHelpers

  describe '#legacy_trace_files' do
    let(:builds_path) { Rails.root.join('tmp/tests/builds').to_s }

    before do
      create_trace_file(builds_path, '2018_02', '19', 1, '')
      create_trace_file(builds_path, '2018_02', '19', 2, '')
      create_trace_file(builds_path, '2018_02', '19', 3, '')
      create_trace_file(builds_path, '2018_02', '19', 4, '')
      create_trace_file(builds_path, '2018_02', '22', 5, '')
      create_trace_file(builds_path, '2018_02', '22', 6, '')
      create_trace_file(builds_path, '2018_03', '2', 7, '')
      create_trace_file(builds_path, '2018_03', '2', 8, '')
      create_trace_file(builds_path, '2018_03', '3', 9, '')
    end

    context 'when relative path points root' do
      context 'when relative path is dot' do
        let(:relative_path) { '.' }

        it 'iterates' do
          expect { |b| described_class.new(relative_path).legacy_trace_files(&b) }
            .to yield_control.exactly(9).times
        end
      end

      context 'when relative path with dot and slash' do
        let(:relative_path) { './' }

        it 'iterates' do
          expect { |b| described_class.new(relative_path).legacy_trace_files(&b) }
            .to yield_control.exactly(9).times
        end
      end
    end

    context 'when relative path points yyyy_mm' do
      let(:relative_path) { '2018_02' }

      it 'iterates' do
        expect { |b| described_class.new(relative_path).legacy_trace_files(&b) }
          .to yield_control.exactly(6).times
      end

      context 'when relative path is following dot and slash' do
        let(:relative_path) { './2018_02' }

        it 'iterates' do
          expect { |b| described_class.new(relative_path).legacy_trace_files(&b) }
            .to yield_control.exactly(6).times
        end
      end

      context 'when relative path is followed by slash' do
        let(:relative_path) { '2018_02/' }

        it 'iterates' do
          expect { |b| described_class.new(relative_path).legacy_trace_files(&b) }
            .to yield_control.exactly(6).times
        end
      end

      context 'when relative path does not exist' do
        let(:relative_path) { '2019_02' }

        it 'does not iterates' do
          expect { |b| described_class.new(relative_path).legacy_trace_files(&b) }
            .to raise_error(Errno::ENOENT)
        end
      end

      context 'when relative path includes unexpected characters' do
        let(:relative_path) { '2018_02/*' }

        it 'does not iterates' do
          expect { |b| described_class.new(relative_path).legacy_trace_files(&b) }
            .to raise_error(Errno::ENOENT)
        end
      end
    end

    context 'when relative path points project_id' do
      let(:relative_path) { '2018_03/2' }

      it 'iterates' do
        expect { |b| described_class.new(relative_path).legacy_trace_files(&b) }
          .to yield_control.exactly(2).times
      end
    end

    context 'when relative path points trace file' do
      let(:relative_path) { '2018_03/3/9.log' }

      it 'iterates' do
        expect { |b| described_class.new(relative_path).legacy_trace_files(&b) }
          .to yield_control.exactly(1).times
      end

      context 'when relative path with dot and slash' do
        let(:relative_path) { './2018_03/3/9.log' }

        it 'iterates' do
          expect { |b| described_class.new(relative_path).legacy_trace_files(&b) }
            .to yield_control.exactly(1).times
        end
      end

      context 'when file does not exist' do
        let(:relative_path) { '2018_03/3/900.log' }

        it 'does not iterates' do
          expect { |b| described_class.new(relative_path).legacy_trace_files(&b) }
            .to raise_error(Errno::ENOENT)
        end
      end
    end
  end
end
