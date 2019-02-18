require 'spec_helper'

describe Geo::ProjectRegistryFinder, :geo do
  include ::EE::GeoHelpers

  # Using let() instead of set() because set() does not work properly
  # when using the :delete DatabaseCleaner strategy, which is required for FDW
  # tests because a foreign table can't see changes inside a transaction of a
  # different connection.
  let(:secondary) { create(:geo_node) }
  let(:synced_group) { create(:group) }
  let!(:project_not_synced) { create(:project) }
  let(:project_synced) { create(:project) }
  let(:project_repository_dirty) { create(:project) }
  let(:project_wiki_dirty) { create(:project) }
  let(:project_repository_verified) { create(:project) }
  let(:project_repository_verification_failed) { create(:project) }
  let(:project_wiki_verified) { create(:project) }
  let(:project_wiki_verification_failed) { create(:project) }

  subject { described_class.new(current_node: secondary) }

  before do
    stub_current_geo_node(secondary)
  end

  shared_examples 'counts all the things' do
    describe '#count_synced_repositories' do
      it 'counts repositories that have been synced' do
        create(:geo_project_registry, :sync_failed)
        create(:geo_project_registry, :synced, project: project_synced)
        create(:geo_project_registry, :synced, :repository_dirty, project: project_repository_dirty)
        create(:geo_project_registry, :synced, :wiki_dirty, project: project_wiki_dirty)

        expect(subject.count_synced_repositories).to eq 2
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts projects that has been synced' do
          project_1_in_synced_group = create(:project, group: synced_group)
          project_2_in_synced_group = create(:project, group: synced_group)

          create(:geo_project_registry, :synced, project: project_synced)
          create(:geo_project_registry, :synced, project: project_1_in_synced_group)
          create(:geo_project_registry, :sync_failed, project: project_2_in_synced_group)

          expect(subject.count_synced_repositories).to eq 1
        end
      end
    end

    describe '#count_synced_wikis' do
      it 'counts wiki that have been synced' do
        create(:geo_project_registry, :sync_failed)
        create(:geo_project_registry, :synced, project: project_synced)
        create(:geo_project_registry, :synced, :repository_dirty, project: project_repository_dirty)
        create(:geo_project_registry, :synced, :wiki_dirty, project: project_wiki_dirty)

        expect(subject.count_synced_wikis).to eq 2
      end

      it 'counts synced wikis with nil wiki_access_level (which means enabled wiki)' do
        project_synced.project_feature.update!(wiki_access_level: nil)

        create(:geo_project_registry, :synced, project: project_synced)

        expect(subject.count_synced_wikis).to eq 1
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'counts projects that has been synced' do
          project_1_in_synced_group = create(:project, group: synced_group)
          project_2_in_synced_group = create(:project, group: synced_group)

          create(:geo_project_registry, :synced, project: project_synced)
          create(:geo_project_registry, :synced, project: project_1_in_synced_group)
          create(:geo_project_registry, :sync_failed, project: project_2_in_synced_group)

          expect(subject.count_synced_wikis).to eq 1
        end
      end
    end

    describe '#count_failed_repositories' do
      it 'delegates to #find_failed_project_registries' do
        expect(subject).to receive(:find_failed_project_registries).with('repository').and_call_original

        subject.count_failed_repositories
      end

      it 'counts projects that sync has failed' do
        create(:geo_project_registry, :synced)
        create(:geo_project_registry, :sync_failed, project: project_synced)
        create(:geo_project_registry, :repository_sync_failed, project: project_repository_dirty)
        create(:geo_project_registry, :wiki_sync_failed, project: project_wiki_dirty)

        expect(subject.count_failed_repositories).to eq 2
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'delegates to #find_failed_repositories' do
          expect(subject).to receive(:find_failed_project_registries).with('repository').and_call_original

          subject.count_failed_repositories
        end

        it 'counts projects that sync has failed' do
          project_1_in_synced_group = create(:project, group: synced_group)
          project_2_in_synced_group = create(:project, group: synced_group)

          create(:geo_project_registry, :sync_failed, project: project_synced)
          create(:geo_project_registry, :repository_sync_failed, project: project_1_in_synced_group)
          create(:geo_project_registry, :synced, project: project_2_in_synced_group)

          expect(subject.count_failed_repositories).to eq 1
        end
      end
    end

    describe '#count_failed_wikis' do
      it 'delegates to #find_failed_project_registries' do
        expect(subject).to receive(:find_failed_project_registries).with('wiki').and_call_original

        subject.count_failed_wikis
      end

      it 'counts projects that sync has failed' do
        create(:geo_project_registry, :synced)
        create(:geo_project_registry, :sync_failed, project: project_synced)
        create(:geo_project_registry, :repository_sync_failed, project: project_repository_dirty)
        create(:geo_project_registry, :wiki_sync_failed, project: project_wiki_dirty)

        expect(subject.count_failed_wikis).to eq 2
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'delegates to #find_failed_wikis' do
          expect(subject).to receive(:find_failed_project_registries).with('wiki').and_call_original

          subject.count_failed_wikis
        end

        it 'counts projects that sync has failed' do
          project_1_in_synced_group = create(:project, group: synced_group)
          project_2_in_synced_group = create(:project, group: synced_group)

          create(:geo_project_registry, :sync_failed, project: project_synced)
          create(:geo_project_registry, :wiki_sync_failed, project: project_1_in_synced_group)
          create(:geo_project_registry, :synced, project: project_2_in_synced_group)

          expect(subject.count_failed_wikis).to eq 1
        end
      end
    end

    describe '#count_verified_repositories' do
      it 'delegates to #find_verified_repositories when use_legacy_queries is false' do
        expect(subject).to receive(:use_legacy_queries?).and_return(false)

        expect(subject).to receive(:find_verified_repositories).and_call_original

        subject.count_verified_repositories
      end

      it 'delegates to #legacy_find_verified_repositories when use_legacy_queries is true' do
        expect(subject).to receive(:use_legacy_queries?).and_return(true)

        expect(subject).to receive(:legacy_find_verified_repositories).and_call_original

        subject.count_verified_repositories
      end

      it 'counts projects that verified' do
        create(:geo_project_registry, :repository_verified, project: project_repository_verified)
        create(:geo_project_registry, :repository_verified, project: build(:project))
        create(:geo_project_registry, :repository_verification_failed, project: project_repository_verification_failed)

        expect(subject.count_verified_repositories).to eq 2
      end
    end

    describe '#count_verified_wikis' do
      it 'delegates to the correct method' do
        expect(subject).to receive("#{method_prefix}_find_verified_wikis".to_sym).and_call_original

        subject.count_verified_wikis
      end

      it 'counts wikis that verified' do
        create(:geo_project_registry, :wiki_verified, project: project_wiki_verified)
        create(:geo_project_registry, :wiki_verified, project: build(:project))
        create(:geo_project_registry, :wiki_verification_failed, project: project_wiki_verification_failed)

        expect(subject.count_verified_wikis).to eq 2
      end
    end

    describe '#count_verification_failed_repositories' do
      it 'delegates to #find_verification_failed_project_registries' do
        expect(subject).to receive(:find_verification_failed_project_registries).with('repository').and_call_original

        subject.count_verification_failed_repositories
      end

      it 'delegates to #legacy_find_filtered_verification_failed_projects when use_legacy_queries is true' do
        expect(subject).to receive(:use_legacy_queries?).and_return(true)

        expect(subject).to receive(:legacy_find_filtered_verification_failed_projects).with('repository').and_call_original

        subject.count_verification_failed_repositories
      end

      it 'delegates to #find_filtered_verification_failed_project_registries when use_legacy_queries is false' do
        expect(subject).to receive(:use_legacy_queries?).and_return(false)

        expect(subject).to receive(:find_filtered_verification_failed_project_registries).with('repository').and_call_original

        subject.count_verification_failed_repositories
      end

      it 'counts projects that verification has failed' do
        create(:geo_project_registry, :repository_verified, project: project_repository_verified)
        create(:geo_project_registry, :repository_verification_failed, project: project_repository_verification_failed)
        create(:geo_project_registry, :wiki_verified, project: project_wiki_verified)
        create(:geo_project_registry, :wiki_verification_failed, project: project_wiki_verification_failed)

        expect(subject.count_verification_failed_repositories).to eq 1
      end

      it 'counts projects that verification has failed' do
        create(:geo_project_registry, :repository_verified, project: project_repository_verified)
        create(:geo_project_registry, :repository_verification_failed, project: project_repository_verification_failed)
        create(:geo_project_registry, :wiki_verified, project: project_wiki_verified)
        create(:geo_project_registry, :wiki_verification_failed, project: project_wiki_verification_failed)

        expect(subject.count_verification_failed_repositories).to eq 1
      end
    end

    describe '#count_verification_failed_wikis' do
      it 'delegates to #find_verification_failed_project_registries' do
        expect(subject).to receive(:find_verification_failed_project_registries).with('wiki').and_call_original

        subject.count_verification_failed_wikis
      end

      it 'delegates to #legacy_find_filtered_verification_failed_projects when use_legacy_queries is true' do
        expect(subject).to receive(:use_legacy_queries?).and_return(true)

        expect(subject).to receive(:legacy_find_filtered_verification_failed_projects).with('wiki').and_call_original

        subject.count_verification_failed_wikis
      end

      it 'delegates to #find_filtered_verification_failed_project_registries when use_legacy_queries is false' do
        expect(subject).to receive(:use_legacy_queries?).and_return(false)

        expect(subject).to receive(:find_filtered_verification_failed_project_registries).with('wiki').and_call_original

        subject.count_verification_failed_wikis
      end

      it 'counts projects that verification has failed' do
        create(:geo_project_registry, :repository_verified, project: project_repository_verified)
        create(:geo_project_registry, :repository_verification_failed, project: project_repository_verification_failed)
        create(:geo_project_registry, :wiki_verified, project: project_wiki_verified)
        create(:geo_project_registry, :wiki_verification_failed, project: project_wiki_verification_failed)

        expect(subject.count_verification_failed_wikis).to eq 1
      end
    end
  end

  describe '#find_checksum_mismatch_project_registries' do
    it 'delegates to #find_filtered_checksum_mismatch_project_registries' do
      expect(subject).to receive(:find_filtered_checksum_mismatch_project_registries).and_call_original

      subject.find_checksum_mismatch_project_registries
    end

    it 'delegates to #legacy_find_filtered_checksum_mismatch_projects when use_legacy_queries is true' do
      expect(subject).to receive(:use_legacy_queries?).and_return(true)

      expect(subject).to receive(:legacy_find_filtered_checksum_mismatch_projects).and_call_original

      subject.find_checksum_mismatch_project_registries
    end

    it 'delegates to #find_filtered_checksum_mismatch_project_registries when use_legacy_queries is false' do
      expect(subject).to receive(:use_legacy_queries?).and_return(false)

      expect(subject).to receive(:find_filtered_checksum_mismatch_project_registries).and_call_original

      subject.find_checksum_mismatch_project_registries
    end

    it 'counts projects with a checksum mismatch' do
      repository_mismatch1 = create(:geo_project_registry, :repository_checksum_mismatch)
      repository_mismatch2 = create(:geo_project_registry, :repository_checksum_mismatch)
      create(:geo_project_registry, :wiki_verified)
      wiki_mismatch = create(:geo_project_registry, :wiki_checksum_mismatch)

      expect(subject.find_checksum_mismatch_project_registries('wiki')).to match_array(wiki_mismatch)
      expect(subject.find_checksum_mismatch_project_registries('repository')).to match_array([repository_mismatch1, repository_mismatch2])
      expect(subject.find_checksum_mismatch_project_registries(nil)).to match_array([repository_mismatch1, repository_mismatch2, wiki_mismatch])
    end

    context 'with selective sync' do
      before do
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
      end

      it 'delegates to #legacy_find_filtered_checksum_mismatch_projects' do
        expect(subject).to receive(:legacy_find_filtered_checksum_mismatch_projects).and_call_original

        subject.find_checksum_mismatch_project_registries
      end

      it 'returns projects with a checksum mismatch' do
        project_1_in_synced_group = create(:project, group: synced_group)
        project_1_registry_record = create(:geo_project_registry, :repository_checksum_mismatch, project: project_1_in_synced_group)

        projects = subject.find_checksum_mismatch_project_registries('repository')

        expect(projects).to match_ids(project_1_registry_record)
      end
    end
  end

  shared_examples 'finds all the things' do
    describe '#find_unsynced_projects' do
      it 'delegates to the correct method' do
        expect(subject).to receive("#{method_prefix}_find_unsynced_projects".to_sym).and_call_original

        subject.find_unsynced_projects(batch_size: 10)
      end

      it 'returns projects without an entry on the tracking database' do
        create(:geo_project_registry, :synced, :repository_dirty, project: project_repository_dirty)

        projects = subject.find_unsynced_projects(batch_size: 10)

        expect(projects).to match_ids(project_not_synced)
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'delegates to #legacy_find_unsynced_projects' do
          expect(subject).to receive(:legacy_find_unsynced_projects).and_call_original

          subject.find_unsynced_projects(batch_size: 10)
        end

        it 'returns untracked projects in the synced group' do
          project_1_in_synced_group = create(:project, group: synced_group)
          project_2_in_synced_group = create(:project, group: synced_group)

          create(:geo_project_registry, :sync_failed, project: project_1_in_synced_group)

          projects = subject.find_unsynced_projects(batch_size: 10)

          expect(projects).to match_ids(project_2_in_synced_group)
        end
      end
    end

    describe '#find_projects_updated_recently' do
      it 'delegates to the correct method' do
        expect(subject).to receive("#{method_prefix}_find_projects_updated_recently".to_sym).and_call_original

        subject.find_projects_updated_recently(batch_size: 10)
      end

      it 'returns projects with a dirty entry on the tracking database' do
        create(:geo_project_registry, :synced, :repository_dirty, project: project_repository_dirty)
        create(:geo_project_registry, :synced, :wiki_dirty, project: project_wiki_dirty)

        projects = subject.find_projects_updated_recently(batch_size: 10)

        expect(projects).to match_ids([project_repository_dirty, project_wiki_dirty])
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'delegates to #legacy_find_projects_updated_recently' do
          expect(subject).to receive(:legacy_find_projects_updated_recently).and_call_original

          subject.find_projects_updated_recently(batch_size: 10)
        end

        it 'returns dirty projects in the synced group' do
          project_1_in_synced_group = create(:project, group: synced_group)
          project_2_in_synced_group = create(:project, group: synced_group)
          project_3_in_synced_group = create(:project, group: synced_group)
          create(:project, group: synced_group)

          create(:geo_project_registry, :synced, :repository_dirty, project: project_1_in_synced_group)
          create(:geo_project_registry, :synced, :wiki_dirty, project: project_2_in_synced_group)
          create(:geo_project_registry, :synced, project: project_3_in_synced_group)

          projects = subject.find_projects_updated_recently(batch_size: 10)

          expect(projects).to match_ids(project_1_in_synced_group, project_2_in_synced_group)
        end
      end
    end

    describe '#find_failed_project_registries' do
      let(:project_1_in_synced_group) { create(:project, group: synced_group) }
      let(:project_2_in_synced_group) { create(:project, group: synced_group) }

      let!(:synced) { create(:geo_project_registry, :synced) }
      let!(:sync_failed) { create(:geo_project_registry, :sync_failed, project: project_synced) }
      let!(:repository_sync_failed) { create(:geo_project_registry, :repository_sync_failed, project: project_1_in_synced_group) }
      let!(:wiki_sync_failed) { create(:geo_project_registry, :wiki_sync_failed, project: project_2_in_synced_group) }

      it 'delegates to #find_failed_project_registries' do
        expect(subject).to receive(:find_failed_project_registries).with('repository').and_call_original

        subject.count_failed_repositories
      end

      it 'returns only project registries that repository sync has failed' do
        expect(subject.find_failed_project_registries('repository')).to match_array([sync_failed, repository_sync_failed])
      end

      it 'returns only project registries that wiki sync has failed' do
        expect(subject.find_failed_project_registries('wiki')).to match_array([sync_failed, wiki_sync_failed])
      end

      context 'with selective sync' do
        before do
          secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
        end

        it 'delegates to #legacy_find_filtered_failed_projects' do
          expect(subject).to receive(:legacy_find_filtered_failed_projects).and_call_original

          subject.find_failed_project_registries
        end

        it 'returns project registries that sync has failed' do
          expect(subject.find_failed_project_registries).to match_array([repository_sync_failed, wiki_sync_failed])
        end

        it 'returns only project registries that repository sync has failed' do
          create(:geo_project_registry, :repository_sync_failed)

          expect(subject.find_failed_project_registries('repository')).to match_array([repository_sync_failed])
        end

        it 'returns only project registries that wiki sync has failed' do
          create(:geo_project_registry, :wiki_sync_failed)

          expect(subject.find_failed_project_registries('wiki')).to match_array([wiki_sync_failed])
        end
      end
    end

    describe '#find_registries_to_verify' do
      it 'delegates to the correct method' do
        expect(subject).to receive("#{method_prefix}_find_registries_to_verify".to_sym).and_call_original

        subject.find_registries_to_verify(shard_name: 'default', batch_size: 10)
      end

      it 'does not return registries that are verified on primary and secondary' do
        project_verified    = create(:repository_state, :repository_verified, :wiki_verified).project
        repository_verified = create(:repository_state, :repository_verified).project
        wiki_verified       = create(:repository_state, :wiki_verified).project

        create(:geo_project_registry, :repository_verified, :wiki_verified, project: project_verified)
        create(:geo_project_registry, :repository_verified, project: repository_verified)
        create(:geo_project_registry, :wiki_verified, project: wiki_verified)

        expect(subject.find_registries_to_verify(shard_name: 'default', batch_size: 100)).to be_empty
      end

      it 'does not return registries that were unverified/outdated on primary' do
        project_unverified_primary  = create(:project)
        project_outdated_primary    = create(:repository_state, :repository_outdated, :wiki_outdated).project
        repository_outdated_primary = create(:repository_state, :repository_outdated, :wiki_verified).project
        wiki_outdated_primary       = create(:repository_state, :repository_verified, :wiki_outdated).project

        create(:geo_project_registry, project: project_unverified_primary)
        create(:geo_project_registry, :repository_verification_outdated, :wiki_verification_outdated, project: project_outdated_primary)
        create(:geo_project_registry, :repository_verified, :wiki_verified, project: repository_outdated_primary)
        create(:geo_project_registry, :repository_verified, :wiki_verified, project: wiki_outdated_primary)

        expect(subject.find_registries_to_verify(shard_name: 'default', batch_size: 100)).to be_empty
      end

      it 'returns registries that were unverified/outdated on secondary' do
        # Secondary unverified/outdated
        project_unverified_secondary  = create(:repository_state, :repository_verified, :wiki_verified).project
        project_outdated_secondary    = create(:repository_state, :repository_verified, :wiki_verified).project
        repository_outdated_secondary = create(:repository_state, :repository_verified, :wiki_verified).project
        wiki_outdated_secondary       = create(:repository_state, :repository_verified, :wiki_verified).project

        registry_unverified_secondary          = create(:geo_project_registry, :synced, project: project_unverified_secondary)
        registry_outdated_secondary            = create(:geo_project_registry, :synced, :repository_verification_outdated, :wiki_verification_outdated, project: project_outdated_secondary)
        registry_repository_outdated_secondary = create(:geo_project_registry, :synced, :repository_verification_outdated, :wiki_verified, project: repository_outdated_secondary)
        registry_wiki_outdated_secondary       = create(:geo_project_registry, :synced, :repository_verified, :wiki_verification_outdated, project: wiki_outdated_secondary)

        expect(subject.find_registries_to_verify(shard_name: 'default', batch_size: 100))
          .to match_array([
            registry_unverified_secondary,
            registry_outdated_secondary,
            registry_repository_outdated_secondary,
            registry_wiki_outdated_secondary
          ])
      end

      it 'does not return registries that failed on primary' do
        verification_failed_primary = create(:repository_state, :repository_failed, :wiki_failed).project

        create(:geo_project_registry, project: verification_failed_primary)

        expect(subject.find_registries_to_verify(shard_name: 'default', batch_size: 100)).to be_empty
      end

      it 'returns registries where one failed and one verified on the primary' do
        verification_failed_primary = create(:repository_state, :repository_failed, :wiki_failed).project
        repository_failed_primary   = create(:repository_state, :repository_failed, :wiki_verified).project
        wiki_failed_primary         = create(:repository_state, :repository_verified, :wiki_failed).project

        create(:geo_project_registry, :synced, project: verification_failed_primary)
        registry_repository_failed_primary = create(:geo_project_registry, :synced, project: repository_failed_primary)
        registry_wiki_failed_primary       = create(:geo_project_registry, :synced, project: wiki_failed_primary)

        expect(subject.find_registries_to_verify(shard_name: 'default', batch_size: 100))
          .to match_array([
            registry_repository_failed_primary,
            registry_wiki_failed_primary
          ])
      end

      it 'does not return registries where verification failed on secondary' do
        # Verification failed on secondary
        verification_failed_secondary = create(:repository_state, :repository_verified, :wiki_verified).project
        repository_failed_secondary   = create(:repository_state, :repository_verified).project
        wiki_failed_secondary         = create(:repository_state, :wiki_verified).project

        create(:geo_project_registry, :repository_verification_failed, :wiki_verification_failed, project: verification_failed_secondary)
        create(:geo_project_registry, :repository_verification_failed, project: repository_failed_secondary)
        create(:geo_project_registry, :wiki_verification_failed, project: wiki_failed_secondary)

        expect(subject.find_registries_to_verify(shard_name: 'default', batch_size: 100)).to be_empty
      end

      it 'does not return registries when the repo needs to be resynced' do
        project_verified = create(:repository_state, :repository_verified).project
        create(:geo_project_registry, :repository_sync_failed, project: project_verified)

        expect(subject.find_registries_to_verify(shard_name: 'default', batch_size: 100)).to be_empty
      end

      it 'does not return registries when the wiki needs to be resynced' do
        project_verified = create(:repository_state, :wiki_verified).project
        create(:geo_project_registry, :wiki_sync_failed, project: project_verified)

        expect(subject.find_registries_to_verify(shard_name: 'default', batch_size: 100)).to be_empty
      end

      it 'does not return registries when the repository is missing on primary' do
        project_verified = create(:repository_state, :repository_verified).project
        create(:geo_project_registry, :synced, project: project_verified, repository_missing_on_primary: true)

        expect(subject.find_registries_to_verify(shard_name: 'default', batch_size: 100)).to be_empty
      end

      it 'does not return registries when the wiki is missing on primary' do
        project_verified = create(:repository_state, :wiki_verified).project
        create(:geo_project_registry, :synced, project: project_verified, wiki_missing_on_primary: true)

        expect(subject.find_registries_to_verify(shard_name: 'default', batch_size: 100)).to be_empty
      end
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  context 'FDW', :delete do
    before do
      skip('FDW is not configured') if Gitlab::Database.postgresql? && !Gitlab::Geo::Fdw.enabled?
    end

    context 'with use_fdw_queries_for_selective_sync disabled' do
      before do
        stub_feature_flags(use_fdw_queries_for_selective_sync: false)
      end

      include_examples 'counts all the things'
    end

    context 'with use_fdw_queries_for_selective_sync enabled' do
      before do
        stub_feature_flags(use_fdw_queries_for_selective_sync: true)
      end

      include_examples 'counts all the things'
    end

    include_examples 'finds all the things' do
      let(:method_prefix) { 'fdw' }
    end
  end

  context 'Legacy' do
    before do
      stub_fdw_disabled
    end

    include_examples 'counts all the things'

    include_examples 'finds all the things' do
      let(:method_prefix) { 'legacy' }
    end
  end
end
