require 'spec_helper'

describe Gitlab::Geo::GeoTasks do
  include ::EE::GeoHelpers

  describe '.clean_orphaned_project_registry!' do
    set(:secondary) { create(:geo_node) }
    set(:project) { create(:project) }
    set(:registry_first) { create(:geo_project_registry, project: project) }
    set(:registry_second) { create(:geo_project_registry) }

    before do
      stub_current_geo_node(secondary)
      allow($stdout).to receive(:puts)
    end

    it 'removes orphaned registry entries' do
      registry_second.update_column(:project_id, 1000)

      expect(described_class).to receive(:prompt).and_return('delete')
      expect { subject.clean_orphaned_project_registry! }.to change { ::Geo::ProjectRegistry.count }.by(-1)

      expect(Project.count).to eq(2)
      expect(Project.first.id).to eq(project.id)
      expect(::Geo::ProjectRegistry.count).to eq(1)
      expect(::Geo::ProjectRegistry.first.project_id).to eq(project.id)
      expect { subject.clean_orphaned_project_registry! }.not_to change { ::Geo::ProjectRegistry.count }
    end
  end

  describe '.set_primary_geo_node' do
    before do
      allow(GeoNode).to receive(:current_node_url).and_return('https://primary.geo.example.com')
    end

    it 'sets the primary node' do
      expect { subject.set_primary_geo_node }.to output(%r{https://primary.geo.example.com/ is now the primary Geo node}).to_stdout
    end

    it 'returns error when there is already a Primary node' do
      create(:geo_node, :primary)

      expect { subject.set_primary_geo_node }.to output(/Error saving Geo node:/).to_stdout
    end
  end
end
