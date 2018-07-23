require 'spec_helper'

describe Boards::MilestonesFinder do
  describe '#execute' do
    let(:group) { create(:group) }
    let(:project) { create(:project, group: group) }
    let(:user) { create(:user) }

    let(:finder) { described_class.new(board, user) }

    context 'when project board' do
      let(:board) { create(:board, project: project) }
      let!(:group_milestone) { create(:milestone, group: group, project: nil) }
      let!(:milestone) { create(:milestone, group: nil, project: project) }

      it 'returns milestones from project and its namespace' do
        results = finder.execute

        expect(results).to contain_exactly(group_milestone, milestone)
      end
    end

    context 'when group board', :nested_groups do
      let(:nested_group) { create(:group, parent: group) }

      let(:group_project) { create(:project, group: group) }
      let(:nested_group_project) { create(:project, group: nested_group) }

      let!(:group_milestone) { create(:milestone, group: group, project: nil) }
      let!(:nested_group_milestone) { create(:milestone, group: nested_group, project: nil) }
      let!(:group_project_milestone) { create(:milestone, group: nil, project: group_project) }
      let!(:nested_group_project_milestone) { create(:milestone, group: nil, project: nested_group_project) }

      let(:board) { create(:board, project: nil, group: group) }

      context 'when user has access to top level group' do
        before do
          group.add_developer(user)
        end

        it 'returns milestones from ancestor groups and its projects' do
          results = finder.execute

          expect(results).to contain_exactly(group_milestone,
                                             nested_group_milestone,
                                             group_project_milestone,
                                             nested_group_project_milestone)
        end
      end

      context 'when user has access only to nested level group' do
        before do
          nested_group.add_developer(user)
        end

        it 'returns milestones from ancestor groups and its projects' do
          results = finder.execute

          expect(results).to contain_exactly(nested_group_milestone,
                                             nested_group_project_milestone)
        end
      end
    end
  end
end
