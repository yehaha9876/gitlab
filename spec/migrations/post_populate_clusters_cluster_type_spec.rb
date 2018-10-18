# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20181018211523_post_populate_clusters_cluster_type.rb')

describe PostPopulateClustersClusterType, :migration do
  let(:clusters) { table(:clusters) }
  let(:cluster_type_project_type) { PostPopulateClustersClusterType::PROJECT_CLUSTER_TYPE }
  let(:cluster_type_group_type) { 2 }

  before do
    clusters.create(name: 'old-cluster')
    clusters.create(name: 'project-cluster', cluster_type: cluster_type_project_type)
    clusters.create(name: 'group-cluster', cluster_type: cluster_type_group_type)
  end

  it 'populates all rows only where empty' do
    migrate!

    expect(clusters.where(cluster_type: nil).count).to eq(0)
    expect(clusters.where(cluster_type: cluster_type_project_type).count).to eq(2)
    expect(clusters.where(cluster_type: cluster_type_group_type).count).to eq(1)
  end
end
