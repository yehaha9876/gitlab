require 'spec_helper'

describe RepositoryCheck::BatchWorker do
  let(:shard_name) { 'default' }
  subject { described_class.new }

  before do
    Gitlab::ShardHealthCache.update([shard_name])
  end

  it 'prefers projects that have never been checked' do
    projects = create_list(:project, 3, created_at: 1.week.ago)
    projects[0].update_column(:last_repository_check_at, 4.months.ago)
    projects[2].update_column(:last_repository_check_at, 3.months.ago)

    expect(subject.perform(shard_name)).to eq(projects.values_at(1, 0, 2).map(&:id))
  end

  it 'sorts projects by last_repository_check_at' do
    projects = create_list(:project, 3, created_at: 1.week.ago)
    projects[0].update_column(:last_repository_check_at, 2.months.ago)
    projects[1].update_column(:last_repository_check_at, 4.months.ago)
    projects[2].update_column(:last_repository_check_at, 3.months.ago)

    expect(subject.perform(shard_name)).to eq(projects.values_at(1, 2, 0).map(&:id))
  end

  it 'excludes projects that were checked recently' do
    projects = create_list(:project, 3, created_at: 1.week.ago)
    projects[0].update_column(:last_repository_check_at, 2.days.ago)
    projects[1].update_column(:last_repository_check_at, 2.months.ago)
    projects[2].update_column(:last_repository_check_at, 3.days.ago)

    expect(subject.perform(shard_name)).to eq([projects[1].id])
  end

  it 'excludes projects on another shard' do
    projects = create_list(:project, 2, created_at: 1.week.ago)
    projects[0].update_column(:repository_storage, 'other')

    expect(subject.perform(shard_name)).to eq([projects[1].id])
  end

  it 'does nothing when repository checks are disabled' do
    create(:project, created_at: 1.week.ago)

    stub_application_setting(repository_checks_enabled: false)

    expect(subject.perform(shard_name)).to eq(nil)
  end

  it 'does nothing when shard is unhealthy' do
    shard_name = 'broken'
    create(:project, created_at: 1.week.ago, repository_storage: shard_name)

    expect(subject.perform(shard_name)).to eq(nil)
  end

  it 'skips projects created less than 24 hours ago' do
    project = create(:project)
    project.update_column(:created_at, 23.hours.ago)

    expect(subject.perform(shard_name)).to eq([])
  end

  context 'multiple shards' do
    let(:second_shard) { 'test-1' }

    before do
      Gitlab::ShardHealthCache.update([shard_name, second_shard])
      projects = create_list(:project, 2, created_at: 1.week.ago)
      stub_const("#{described_class}::BATCH_SIZE", 2)
    end

    it 'limits batch size to 1 per shard' do
      allow(subject).to receive(:batch_size).and_call_original

      expect(subject.perform(shard_name).count).to eq(1)
    end

    it 'schedules no checks if shards are all unhealthy' do
      Gitlab::ShardHealthCache.update([])

      expect(subject.perform(shard_name)).to be_nil
    end
  end
end
