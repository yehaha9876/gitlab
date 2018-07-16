require 'spec_helper'

describe DeleteRestrictedTodosService do
  let(:group)          { create(:group, :public) }
  let(:project)        { create(:project, :public, group: group) }
  let(:user)           { create(:user) }
  let(:project_member) { create(:user) }
  let(:issue)          { create(:issue, project: project) }
  let(:merge_request)  { create(:merge_request, source_project: project) }

  let!(:todos) do
    [
      create(:todo, user: user, target: issue, project_id: project.id),
      create(:todo, user: user, target: merge_request, project_id: project.id),
      create(:todo, user: user),
      create(:todo, user: project_member, target: issue, project_id: project.id)
    ]
  end

  describe '#execute' do
    before do
      project.add_developer(project_member)
    end

    context 'when a project visibility changes (project_id in params)' do
      subject { described_class.new(private_project_id: project.id).execute }

      context 'when project stays public' do
        it 'does not remove any todos' do
          expect { subject }.not_to change { Todo.count }
        end
      end

      context 'when project visibility was changed to internal' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        end

        it 'does not remove any todos' do
          expect { subject }.not_to change { Todo.count }
        end
      end

      context 'when project visibility was changed to private' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end

        it 'removes todos for a user who is not a project member' do
          expect { subject }.to change { Todo.count }.from(4).to(2)

          expect(user.todos).to match_array([todos[2]])
          expect(project_member.todos).to match_array([todos[3]])
        end
      end
    end

    context 'when issue confidentality changes' do
      subject { described_class.new(confidential_issue_id: issue.id).execute }

      before do
        issue.update!(confidential: true)
      end

      it 'removes issue todos for a user who is not a project member' do
        expect { subject }.to change { Todo.count }.from(4).to(3)

        expect(user.todos).to match_array([todos[1], todos[2]])
        expect(project_member.todos).to match_array([todos[3]])
      end
    end

    context 'when a user leaves a project' do
      subject do
        described_class.new(private_project_id: project.id, removed_user_id: user.id).execute
      end

      context 'when a project is public' do
        it 'does not remove any todos' do
          expect { subject }.not_to change { Todo.count }
        end
      end

      context 'when a project is internal' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        end

        it 'does not remove any todos' do
          expect { subject }.not_to change { Todo.count }
        end
      end

      context 'when a project is private' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end

        it 'removes todos for the user and the project' do
          expect { subject }.to change { Todo.count }.from(4).to(2)
        end
      end
    end

    context 'when a user leaves a group' do
      subject { described_class.new(private_group_id: group.id, removed_user_id: user.id).execute }

      context 'when a group is public' do
        it 'does not remove any todos' do
          expect { subject }.not_to change { Todo.count }
        end
      end

      context 'when a group is internal' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
          group.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        end

        it 'does not remove any todos' do
          expect { subject }.not_to change { Todo.count }
        end
      end

      context 'when a group is private' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end

        it 'removes todos for the user and group projects' do
          expect { subject }.to change { Todo.count }.from(4).to(2)
        end
      end
    end

    context 'when a user leaves a group with projects in subgroups', :nested_groups do
      let(:subgroup) { create(:group, :private, parent: group) }
      let(:sub_project) { create(:project, :private, group: subgroup) }
      let!(:other_todo) { create(:todo, user: user, project: sub_project) }

      subject { described_class.new(private_group_id: group.id, removed_user_id: user.id).execute }

      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'removes todos for the user and group projects including dubgroups' do
        expect { subject }.to change { Todo.count }.from(5).to(2)
      end
    end
  end
end
