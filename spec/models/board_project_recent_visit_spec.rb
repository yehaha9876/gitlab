require 'spec_helper'

describe BoardProjectRecentVisit do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let(:board)   { create(:board, project: project) }

  describe 'relationships' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:board) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:board) }
  end

  describe '#visited' do
    it 'creates a visit if one does not exists' do
      expect { described_class.visited(user, board) }.to change(described_class, :count).by(1)
    end

    it 'updates the timestamp' do
      create :board_project_recent_visit, project: board.project, board: board, user: user, updated_at: 7.days.ago

      Timecop.freeze do
        described_class.visited(user, board)

        expect(described_class.count).to eq 1
        expect(described_class.first.updated_at).to be_like_time(Time.zone.now)
      end
    end
  end

  describe '#latest' do
    it 'returns the most recent visited' do
      board2 = create(:board, project: project)
      board3 = create(:board, project: project)

      create :board_project_recent_visit, project: board.project, board: board, user: user, updated_at: 7.days.ago
      create :board_project_recent_visit, project: board2.project, board: board2, user: user, updated_at: 5.days.ago
      recent = create :board_project_recent_visit, project: board3.project, board: board3, user: user, updated_at: 1.day.ago

      expect(described_class.latest(user, project)).to eq recent
    end
  end
end
