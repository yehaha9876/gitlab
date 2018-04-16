require 'spec_helper'

describe EE::Ci::Runner do
  describe 'scopes' do
    context 'specific' do
      before do
        create_list(:ci_runner, 2)
        create(:ci_runner, :web_ide_only)
        create_list(:ci_runner, 3, :shared)
      end

      it 'returns specific jobs with web_ide_only disabled' do
        expect(Ci::Runner.specific.count).to eq 2
      end

      it 'returns shared runners no matter web_ide_only value' do
        create(:ci_runner, :shared, web_ide_only: true)

        expect(Ci::Runner.shared.count).to eq 4
      end
    end
  end

  describe 'before initialization' do
    context 'web_ide_only' do
      it 'is set to false if is_shared' do
        runner = build(:ci_runner, :shared, web_ide_only: true)

        expect(runner.web_ide_only).to be_truthy

        runner.valid?

        expect(runner.web_ide_only).to be_falsey
      end
    end
  end

  describe '#tick_runner_queue' do
    it 'sticks the runner to the primary and calls the original method' do
      runner = create(:ci_runner)

      allow(Gitlab::Database::LoadBalancing).to receive(:enable?)
        .and_return(true)

      expect(Gitlab::Database::LoadBalancing::Sticking).to receive(:stick)
        .with(:runner, runner.token)

      expect(Gitlab::Workhorse).to receive(:set_key_and_notify)

      runner.tick_runner_queue
    end

    describe '#web_ide_only?' do
      it 'returns true if web_ide_only and not shared' do
        expect(build(:ci_runner, :shared).web_ide_only?).to be_falsey
        expect(build(:ci_runner, :web_ide_only).web_ide_only?).to be_truthy
        expect(build(:ci_runner).web_ide_only?).to be_falsey
      end
    end
  end
end
