# frozen_string_literal: true

require 'spec_helper'

describe Geo::LegacyProjectRegistrySyncedFinder, :geo do
  include EE::GeoHelpers

  describe '#execute' do
    let(:node) { create(:geo_node) }
    let(:group_1) { create(:group) }
    let(:group_2) { create(:group) }
    let(:nested_group_1) { create(:group, parent: group_1) }
    let(:project_1) { create(:project, group: group_1) }
    let(:project_2) { create(:project, group: nested_group_1) }
    let(:project_3) { create(:project, group: nested_group_1) }
    let(:project_4) { create(:project, :broken_storage, group: group_2) }
    let(:project_5) { create(:project, :broken_storage, group: group_2) }
    let!(:registry_synced) { create(:geo_project_registry, :synced, project: project_1) }
    let!(:registry_repository_dirty) { create(:geo_project_registry, :synced, :repository_dirty, project: project_2) }
    let!(:registry_wiki_dirty) { create(:geo_project_registry, :synced, :wiki_dirty, project: project_3) }
    let!(:registry_wiki_dirty_broken_shard) { create(:geo_project_registry, :synced, :wiki_dirty, project: project_4) }
    let!(:registry_repository_dirty_broken_shard) { create(:geo_project_registry, :synced, :repository_dirty, project: project_5) }
    let!(:registry_sync_failed) { create(:geo_project_registry, :sync_failed) }

    shared_examples 'finds synced registries' do
      context 'with repository type' do
        subject { described_class.new(current_node: node, type: :repository) }

        context 'without selective sync' do
          it 'returns all synced registries' do
            expect(subject.execute).to match_array([registry_synced, registry_wiki_dirty, registry_wiki_dirty_broken_shard])
          end
        end

        context 'with selective sync by namespace' do
          it 'returns synced registries where projects belongs to the namespaces' do
            node.update!(selective_sync_type: 'namespaces', namespaces: [group_1, nested_group_1])

            expect(subject.execute).to match_array([registry_synced, registry_wiki_dirty])
          end
        end

        context 'with selective sync by shard' do
          it 'returns synced registries where projects belongs to the shards' do
            node.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

            expect(subject.execute).to match_array([registry_wiki_dirty_broken_shard])
          end
        end
      end

      context 'with wiki type' do
        subject { described_class.new(current_node: node, type: :wiki) }

        context 'without selective sync' do
          it 'returns all synced registries' do
            expect(subject.execute).to match_array([registry_synced, registry_repository_dirty, registry_repository_dirty_broken_shard])
          end
        end

        context 'with selective sync by namespace' do
          it 'returns synced registries where projects belongs to the namespaces' do
            node.update!(selective_sync_type: 'namespaces', namespaces: [group_1, nested_group_1])

            expect(subject.execute).to match_array([registry_synced, registry_repository_dirty])
          end
        end

        context 'with selective sync by shard' do
          it 'returns synced registries where projects belongs to the shards' do
            node.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

            expect(subject.execute).to match_array([registry_repository_dirty_broken_shard])
          end
        end
      end

      context 'with invalid type' do
        subject { described_class.new(current_node: node, type: :invalid) }

        it 'returns nothing' do
          expect(subject.execute).to be_empty
        end
      end
    end

    # Disable transactions via :delete method because a foreign table
    # can't see changes inside a transaction of a different connection.
    context 'FDW', :delete do
      before do
        skip('FDW is not configured') unless Gitlab::Geo::Fdw.enabled?
      end

      include_examples 'finds synced registries'
    end

    context 'Legacy' do
      before do
        stub_fdw_disabled
      end

      include_examples 'finds synced registries'
    end
  end
end
