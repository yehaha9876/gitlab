require 'spec_helper'

describe Geo::RepositoryBackfillService, services: true do
  let(:project) { create(:empty_project) }
  let(:subject) { described_class.new(project) }

  describe '#execute' do
    before do
      allow_any_instance_of(described_class).to receive(:geo_primary_project_ssh_url)
      allow(project.repository).to receive(:fetch_geo_mirror)
    end

    context 'when no repository exists' do
      before do
        allow(project).to receive(:repository_exists?) { false }
        allow(project).to receive(:empty_repo?) { true }
      end

      it 'creates a new repository' do
        expect(project).to receive(:create_repository)

        subject.execute
      end

      it 'executes after_create hook' do
        expect(project.repository).to receive(:after_create).at_least(:once)

        subject.execute
      end

      it 'fetches the Geo mirror' do
        expect(project.repository).to receive(:fetch_geo_mirror)

        subject.execute
      end
    end

    context 'when repository exists' do
      before do
        allow(project).to receive(:repository_exists?) { true }
        allow(project).to receive(:empty_repo?) { false }
      end

      it 'does not create a new repository' do
        expect(project).not_to receive(:create_repository)

        subject.execute
      end

      it 'does not execute after_create hook' do
        expect(project.repository).not_to receive(:after_create)

        subject.execute
      end

      it 'fetches the Geo mirror' do
        expect(project.repository).to receive(:fetch_geo_mirror)

        subject.execute
      end
    end
  end
end
