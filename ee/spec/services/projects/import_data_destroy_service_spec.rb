# frozen_string_literal: true

require 'spec_helper'

describe Projects::ImportDataDestroyService do
  set(:project) { create(:project, :mirror) }

  def destroy(user)
    described_class.new(project, user).execute
  end

  case_name = lambda {|user_type| "like a project #{user_type}"}

  context 'as an authorized user' do
    let(:owner) { project.owner }
    let(:maintainer) { project.add_maintainer(create(:user)).user }
    let(:authorized_users) { { owner: owner, maintainer: maintainer } }

    where(case_names: case_name, user_type: [:owner, :maintainer])

    with_them do
      let(:user) { authorized_users[user_type] }

      it 'deletes mirror' do
        returned_project = destroy(user)

        project.reload

        expect(returned_project).to eq(project)
        expect(project.import_data).to be_nil
        expect(project).not_to be_mirror
      end
    end
  end

  context 'as an unauthorized user' do
    let(:developer) { project.add_developer(create(:user)).user }
    let(:reporter) { project.add_reporter(create(:user)).user }
    let(:guest) { project.add_guest(create(:user)).user }
    let(:unauthorized_users) { { developer: developer, reporter: reporter, guest: guest } }

    where(case_names: case_name, user_type: [:developer, :reporter, :guest])

    with_them do
      let(:user) { unauthorized_users[user_type] }

      it 'raises an error' do
        expect { destroy(user) }.to raise_error Gitlab::Access::AccessDeniedError
      end
    end
  end
end
