require 'spec_helper'

describe Geo::RepositorySyncService do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  set(:primary) { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }
  set(:project) { create(:project_empty_repo) }

  let(:repository) { project.repository }
  let(:lease_key) { "geo_sync_service:repository:#{project.id}" }
  let(:lease_uuid) { 'uuid'}

  subject { described_class.new(project) }

  before do
    stub_current_geo_node(secondary)
  end

  it_behaves_like 'geo base sync execution'
  it_behaves_like 'geo base sync fetch and repack'
  it_behaves_like 'reschedules sync due to race condition instead of waiting for backfill'

  describe '#execute' do
    let(:url_to_repo) { "#{primary.url}#{project.full_path}.git" }

    before do
      stub_exclusive_lease(lease_key, lease_uuid)
      stub_exclusive_lease("geo_project_housekeeping:#{project.id}")

      allow_any_instance_of(Repository).to receive(:fetch_as_mirror)
        .and_return(true)

      allow_any_instance_of(Repository)
        .to receive(:find_remote_root_ref)
        .with('geo')
        .and_return('master')
    end

    it 'fetches project repository with JWT credentials' do
      expect(repository).to receive(:with_config)
        .with("http.#{url_to_repo}.extraHeader" => anything)
        .twice
        .and_call_original

      expect(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .once

      subject.execute
    end

    it 'expires repository caches' do
      expect_any_instance_of(Repository).to receive(:expire_all_method_caches).once
      expect_any_instance_of(Repository).to receive(:expire_branch_cache).once
      expect_any_instance_of(Repository).to receive(:expire_content_cache).once

      subject.execute
    end

    it 'ensures object pool' do
      expect(project).to receive(:ensure_object_pool).once

      subject.execute
    end

    it 'returns the lease when succeed' do
      expect_to_cancel_exclusive_lease(lease_key, lease_uuid)

      subject.execute
    end

    it 'voids the failure message when it succeeds after an error' do
      registry = create(:geo_project_registry, project: project, last_repository_sync_failure: 'error')

      expect { subject.execute }.to change { registry.reload.last_repository_sync_failure}.to(nil)
    end

    it 'returns the lease when sync fail' do
      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Shell::Error)

      expect_to_cancel_exclusive_lease(lease_key, lease_uuid)

      subject.execute
    end

    it 'does not fetch project repository if cannot obtain a lease' do
      stub_exclusive_lease_taken(lease_key)

      expect(repository).not_to receive(:fetch_as_mirror)

      subject.execute
    end

    it 'rescues when Gitlab::Shell::Error is raised' do
      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Shell::Error)

      expect { subject.execute }.not_to raise_error
    end

    it 'rescues exception and fires after_create hook when Gitlab::Git::Repository::NoRepository is raised' do
      allow(repository).to receive(:fetch_as_mirror)
      .with(url_to_repo, remote_name: 'geo', forced: true)
      .and_raise(Gitlab::Git::Repository::NoRepository)

      expect(repository).to receive(:after_create)

      expect { subject.execute }.not_to raise_error
    end

    it 'increases retry count when Gitlab::Git::Repository::NoRepository is raised' do
      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Git::Repository::NoRepository)

      subject.execute

      expect(Geo::ProjectRegistry.last).to have_attributes(
        resync_repository: true,
        repository_retry_count: 1
      )
    end

    it 'marks sync as successful if no repository found' do
      registry = create(:geo_project_registry, project: project)

      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Shell::Error.new(Gitlab::GitAccess::ERROR_MESSAGES[:no_repo]))

      subject.execute

      expect(registry.reload).to have_attributes(
        resync_repository: false,
        last_repository_successful_sync_at: be_present,
        repository_missing_on_primary: true
      )
    end

    it 'marks resync as true after a failure' do
      described_class.new(project).execute

      expect(Geo::ProjectRegistry.last.resync_repository).to be false

      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Git::Repository::NoRepository)

      subject.execute

      expect(Geo::ProjectRegistry.last.resync_repository).to be true
    end

    context 'tracking database' do
      context 'temporary repositories' do
        include_examples 'cleans temporary repositories' do
          let(:repository) { project.repository }
        end
      end

      it 'creates a new registry if does not exists' do
        expect { subject.execute }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      it 'does not create a new registry if one exist' do
        create(:geo_project_registry, project: project)

        expect { subject.execute }.not_to change(Geo::ProjectRegistry, :count)
      end

      context 'when repository sync succeed' do
        let(:registry) { Geo::ProjectRegistry.find_by(project_id: project.id) }

        it 'sets last_repository_synced_at' do
          subject.execute

          expect(registry.last_repository_synced_at).not_to be_nil
        end

        it 'sets last_repository_successful_sync_at' do
          subject.execute

          expect(registry.last_repository_successful_sync_at).not_to be_nil
        end

        it 'resets the repository_verification_checksum_sha' do
          subject.execute

          expect(registry.repository_verification_checksum_sha).to be_nil
        end

        it 'resets the last_repository_verification_failure' do
          subject.execute

          expect(registry.last_repository_verification_failure).to be_nil
        end

        it 'resets the repository_checksum_mismatch' do
          subject.execute

          expect(registry.repository_checksum_mismatch).to eq false
        end

        it 'logs success with timings' do
          allow(Gitlab::Geo::Logger).to receive(:info).and_call_original
          expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message, :update_delay_s, :download_time_s)).and_call_original

          subject.execute
        end

        it 'sets repository_retry_count and repository_retry_at to nil' do
          registry = create(:geo_project_registry, project: project, repository_retry_count: 2, repository_retry_at: Date.yesterday)

          subject.execute

          expect(registry.reload.repository_retry_count).to be_nil
          expect(registry.repository_retry_at).to be_nil
        end

        context 'with non empty repositories' do
          let(:project) { create(:project, :repository) }

          context 'when when HEAD change' do
            before do
              allow(project.repository)
                .to receive(:find_remote_root_ref)
                .with('geo')
                .and_return('feature')
            end

            it 'syncs gitattributes to info/attributes' do
              expect(repository).to receive(:copy_gitattributes)

              subject.execute
            end

            it 'updates the default branch with JWT credentials' do
              expect(repository).to receive(:with_config)
                .with("http.#{url_to_repo}.extraHeader" => anything)
                .twice
                .and_call_original

              expect(project).to receive(:change_head).with('feature').once

              subject.execute
            end
          end

          context 'when HEAD does not change' do
            before do
              allow(project.repository)
                .to receive(:find_remote_root_ref)
                .with('geo')
                .and_return(project.default_branch)
            end

            it 'syncs gitattributes to info/attributes' do
              expect(repository).to receive(:copy_gitattributes)

              subject.execute
            end

            it 'updates the default branch with JWT credentials' do
              expect(repository).to receive(:with_config)
                .with("http.#{url_to_repo}.extraHeader" => anything)
                .twice
                .and_call_original

              expect(project).to receive(:change_head).with('master').once

              subject.execute
            end
          end
        end
      end

      context 'when repository sync fail' do
        let(:registry) { Geo::ProjectRegistry.find_by(project_id: project.id) }

        before do
          allow(repository).to receive(:fetch_as_mirror)
            .with(url_to_repo, remote_name: 'geo', forced: true)
            .and_raise(Gitlab::Shell::Error.new('shell error'))
        end

        it 'sets correct values for registry record' do
          subject.execute

          expect(registry).to have_attributes(last_repository_synced_at: be_present,
                                              last_repository_successful_sync_at: nil,
                                              repository_retry_count: 1,
                                              repository_retry_at: be_present,
                                              last_repository_sync_failure: 'Error syncing repository: shell error'
                                             )
        end

        it 'calls repository cleanup' do
          expect(repository).to receive(:clean_stale_repository_files)

          subject.execute
        end
      end
    end

    context 'retries' do
      it 'tries to fetch repo' do
        create(:geo_project_registry, project: project, repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD - 1)

        expect(subject).to receive(:sync_repository)

        subject.execute
      end

      it 'sets the redownload flag to false after success' do
        registry = create(:geo_project_registry, project: project, repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD + 1, force_to_redownload_repository: true)

        subject.execute

        expect(registry.reload.force_to_redownload_repository).to be false
      end

      it 'tries to redownload repo' do
        create(:geo_project_registry, project: project, repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD + 1)

        expect(subject).to receive(:sync_repository).and_call_original
        expect(subject.gitlab_shell).to receive(:mv_repository).exactly(2).times.and_call_original

        expect(subject.gitlab_shell).to receive(:add_namespace).with(
          project.repository_storage,
          "@failed-geo-sync/#{File.dirname(repository.disk_path)}"
        ).and_call_original

        expect(subject.gitlab_shell).to receive(:add_namespace).with(
          project.repository_storage,
          File.dirname(repository.disk_path)
        ).and_call_original

        expect(subject.gitlab_shell).to receive(:remove_repository).exactly(2).times.and_call_original

        subject.execute

        repo_path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
          project.repository.path
        end

        expect(File.directory?(repo_path)).to be true
      end

      it 'tries to redownload repo when force_redownload flag is set' do
        create(
          :geo_project_registry,
          project: project,
          repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD - 1,
          force_to_redownload_repository: true
        )

        expect(subject).to receive(:sync_repository)

        subject.execute
      end

      it 'cleans temporary repo after redownload' do
        create(
          :geo_project_registry,
          project: project,
          repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD - 1,
          force_to_redownload_repository: true
        )

        expect(subject).to receive(:fetch_geo_mirror)
        expect(subject).to receive(:clean_up_temporary_repository).twice.and_call_original
        expect(subject.gitlab_shell).to receive(:exists?).twice.with(project.repository_storage, /.git$/)

        subject.execute
      end

      it 'successfully redownloads the repository even if the retry time exceeds max value' do
        timestamp = Time.now.utc
        registry = create(
          :geo_project_registry,
          project: project,
          repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD + 2000,
          repository_retry_at: timestamp,
          force_to_redownload_repository: true
        )

        subject.execute

        # The repository should be redownloaded and cleared without errors. If
        # the timestamp were not capped, we would have seen a "timestamp out
        # of range" in the first update to the project registry.
        registry.reload
        expect(registry.repository_retry_at).to be_nil
      end

      context 'no repository' do
        let(:project) { create(:project) }

        it 'does not raise an error' do
          create(
            :geo_project_registry,
            project: project,
            force_to_redownload_repository: true
          )

          expect(project.repository).to receive(:expire_exists_cache).twice.and_call_original
          expect(subject).not_to receive(:fail_registry!)

          subject.execute
        end
      end
    end

    it_behaves_like 'sync retries use the snapshot RPC' do
      let(:repository) { project.repository }
    end
  end

  describe '#schedule_repack' do
    it 'schedule GitGarbageCollectWorker for full repack' do
      Sidekiq::Testing.fake! do
        expect { subject.send(:schedule_repack) }.to change { GitGarbageCollectWorker.jobs.count }.by(1)
      end
    end
  end

  context 'repository housekeeping' do
    let(:registry) { Geo::ProjectRegistry.find_or_initialize_by(project_id: project.id) }

    it 'increases sync count after execution' do
      expect { subject.execute }.to change { registry.syncs_since_gc }.by(1)
    end

    it 'initiate housekeeping at end of execution' do
      expect_any_instance_of(Geo::ProjectHousekeepingService).to receive(:execute)

      subject.execute
    end
  end
end
