# frozen_string_literal: true

require 'rails_helper'

describe API::ProjectRemoteMirrors do
  set(:project) { create(:project, :repository, :remote_mirror) }

  describe 'DELETE /projects/:project_id/remote_mirrors/:id/' do
    let(:remote_mirror) { project.remote_mirrors.first }
    let(:endpoint) { endpoint_path(project.id, remote_mirror.id) }

    case_name = lambda {|user_type| "like a project #{user_type}"}

    context 'as an authorized user' do
      let(:owner) { project.owner }
      let(:maintainer) { project.add_maintainer(create(:user)).user }
      let(:authorized_users) { { owner: owner, maintainer: maintainer } }

      where(case_names: case_name, user_type: [:owner, :maintainer])

      with_them do
        let(:user) { authorized_users[user_type] }

        it 'deletes remote mirror' do
          delete api(endpoint, user)

          expect(response).to have_gitlab_http_status(204)
          expect(project.remote_mirrors.count).to eq(0)
        end

        it_behaves_like '412 response' do
          let(:request) { api(endpoint, user) }
        end

        context 'for an invalid remote mirror id' do
          it_behaves_like '404 response' do
            let(:message) { '404 Remote Mirror Not Found' }
            let(:request) { delete api(endpoint_path(project.id, '1234'), user) }
          end
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

        it_behaves_like '403 response' do
          let(:request) { delete api(endpoint, user) }
        end
      end

      context 'as an anonymous user' do
        it_behaves_like '401 response' do
          let(:request) { delete api(endpoint, nil) }
        end
      end
    end
  end

  def endpoint_path(project_id, remote_mirror_id)
    "/projects/#{project_id}/remote_mirrors/#{remote_mirror_id}"
  end
end
