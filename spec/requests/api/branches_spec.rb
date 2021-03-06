require 'spec_helper'

describe API::Branches do
  let(:user) { create(:user) }
  let(:guest) { create(:user).tap { |u| project.add_guest(u) } }
  let(:project) { create(:project, :repository, creator: user, path: 'my.project') }
  let(:branch_name) { 'feature' }
  let(:branch_sha) { '0b4bc9a49b562e85de7cc9e834518ea6828729b9' }
  let(:branch_with_dot) { project.repository.find_branch('ends-with.json') }
  let(:branch_with_slash) { project.repository.find_branch('improve/awesome') }

  let(:project_id) { project.id }
  let(:current_user) { nil }

  before do
    project.add_master(user)
  end

  describe "GET /projects/:id/repository/branches" do
    let(:route) { "/projects/#{project_id}/repository/branches" }

    shared_examples_for 'repository branches' do
      it 'returns the repository branches' do
        get api(route, current_user), per_page: 100

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/branches')
        expect(response).to include_pagination_headers
        branch_names = json_response.map { |x| x['name'] }
        expect(branch_names).to match_array(project.repository.branch_names)
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { get api(route, current_user) }
        end
      end
    end

    context 'when unauthenticated', 'and project is public' do
      let(:project) { create(:project, :public, :repository) }

      it_behaves_like 'repository branches'
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a master' do
      let(:current_user) { user }

      it_behaves_like 'repository branches'

      context 'requesting with the escaped project full path' do
        let(:project_id) { CGI.escape(project.full_path) }

        it_behaves_like 'repository branches'
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get api(route, guest) }
      end
    end
  end

  describe "GET /projects/:id/repository/branches/:branch" do
    let(:route) { "/projects/#{project_id}/repository/branches/#{branch_name}" }

    shared_examples_for 'repository branch' do
      context 'HEAD request' do
        it 'returns 204 No Content' do
          head api(route, user)

          expect(response).to have_gitlab_http_status(204)
          expect(response.body).to be_empty
        end

        it 'returns 404 Not Found' do
          head api("/projects/#{project_id}/repository/branches/unknown", user)

          expect(response).to have_gitlab_http_status(404)
          expect(response.body).to be_empty
        end
      end

      it 'returns the repository branch' do
        get api(route, current_user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/branch')
        expect(json_response['name']).to eq(CGI.unescape(branch_name))
      end

      context 'when branch does not exist' do
        let(:branch_name) { 'unknown' }

        it_behaves_like '404 response' do
          let(:request) { get api(route, current_user) }
          let(:message) { '404 Branch Not Found' }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { get api(route, current_user) }
        end
      end
    end

    context 'when unauthenticated', 'and project is public' do
      let(:project) { create(:project, :public, :repository) }

      it_behaves_like 'repository branch'
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { get api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a master' do
      let(:current_user) { user }

      it_behaves_like 'repository branch'

      context 'when branch contains a dot' do
        let(:branch_name) { branch_with_dot.name }

        it_behaves_like 'repository branch'
      end

      context 'when branch contains a slash' do
        let(:branch_name) { branch_with_slash.name }

        it_behaves_like '404 response' do
          let(:request) { get api(route, current_user) }
        end
      end

      context 'when branch contains an escaped slash' do
        let(:branch_name) { CGI.escape(branch_with_slash.name) }

        it_behaves_like 'repository branch'
      end

      context 'requesting with the escaped project full path' do
        let(:project_id) { CGI.escape(project.full_path) }

        it_behaves_like 'repository branch'

        context 'when branch contains a dot' do
          let(:branch_name) { branch_with_dot.name }

          it_behaves_like 'repository branch'
        end
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { get api(route, guest) }
      end
    end
  end

  describe 'PUT /projects/:id/repository/branches/:branch/protect' do
    let(:route) { "/projects/#{project_id}/repository/branches/#{branch_name}/protect" }

    shared_examples_for 'repository new protected branch' do
      it 'protects a single branch' do
        put api(route, current_user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/branch')
        expect(json_response['name']).to eq(CGI.unescape(branch_name))
        expect(json_response['protected']).to eq(true)
      end

      it 'protects a single branch and developers can push' do
        put api(route, current_user), developers_can_push: true

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/branch')
        expect(json_response['name']).to eq(CGI.unescape(branch_name))
        expect(json_response['protected']).to eq(true)
        expect(json_response['developers_can_push']).to eq(true)
        expect(json_response['developers_can_merge']).to eq(false)
      end

      it 'protects a single branch and developers can merge' do
        put api(route, current_user), developers_can_merge: true

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/branch')
        expect(json_response['name']).to eq(CGI.unescape(branch_name))
        expect(json_response['protected']).to eq(true)
        expect(json_response['developers_can_push']).to eq(false)
        expect(json_response['developers_can_merge']).to eq(true)
      end

      it 'protects a single branch and developers can push and merge' do
        put api(route, current_user), developers_can_push: true, developers_can_merge: true

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/branch')
        expect(json_response['name']).to eq(CGI.unescape(branch_name))
        expect(json_response['protected']).to eq(true)
        expect(json_response['developers_can_push']).to eq(true)
        expect(json_response['developers_can_merge']).to eq(true)
      end

      context 'when branch does not exist' do
        let(:branch_name) { 'unknown' }

        it_behaves_like '404 response' do
          let(:request) { put api(route, current_user) }
          let(:message) { '404 Branch Not Found' }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { put api(route, current_user) }
        end
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { put api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { put api(route, guest) }
      end
    end

    context 'when authenticated', 'as a master' do
      let(:current_user) { user }

      context "when a protected branch doesn't already exist" do
        it_behaves_like 'repository new protected branch'

        context 'when branch contains a dot' do
          let(:branch_name) { branch_with_dot.name }

          it_behaves_like 'repository new protected branch'
        end

        context 'when branch contains a slash' do
          let(:branch_name) { branch_with_slash.name }

          it_behaves_like '404 response' do
            let(:request) { put api(route, current_user) }
          end
        end

        context 'when branch contains an escaped slash' do
          let(:branch_name) { CGI.escape(branch_with_slash.name) }

          it_behaves_like 'repository new protected branch'
        end

        context 'requesting with the escaped project full path' do
          let(:project_id) { CGI.escape(project.full_path) }

          it_behaves_like 'repository new protected branch'

          context 'when branch contains a dot' do
            let(:branch_name) { branch_with_dot.name }

            it_behaves_like 'repository new protected branch'
          end
        end
      end

      context 'when protected branch already exists' do
        before do
          project.repository.add_branch(user, protected_branch.name, 'master')
        end

        context 'when developers can push and merge' do
          let(:protected_branch) { create(:protected_branch, :developers_can_push, :developers_can_merge, project: project, name: 'protected_branch') }

          it 'updates that a developer cannot push or merge' do
            put api("/projects/#{project.id}/repository/branches/#{protected_branch.name}/protect", user),
                developers_can_push: false, developers_can_merge: false

            expect(response).to have_gitlab_http_status(200)
            expect(response).to match_response_schema('public_api/v4/branch')
            expect(json_response['name']).to eq(protected_branch.name)
            expect(json_response['protected']).to eq(true)
            expect(json_response['developers_can_push']).to eq(false)
            expect(json_response['developers_can_merge']).to eq(false)
            expect(protected_branch.reload.push_access_levels.first.access_level).to eq(Gitlab::Access::MASTER)
            expect(protected_branch.reload.merge_access_levels.first.access_level).to eq(Gitlab::Access::MASTER)
          end
        end

        context 'when developers cannot push or merge' do
          let(:protected_branch) { create(:protected_branch, project: project, name: 'protected_branch') }

          it 'updates that a developer can push and merge' do
            put api("/projects/#{project.id}/repository/branches/#{protected_branch.name}/protect", user),
                developers_can_push: true, developers_can_merge: true

            expect(response).to have_gitlab_http_status(200)
            expect(response).to match_response_schema('public_api/v4/branch')
            expect(json_response['name']).to eq(protected_branch.name)
            expect(json_response['protected']).to eq(true)
            expect(json_response['developers_can_push']).to eq(true)
            expect(json_response['developers_can_merge']).to eq(true)
          end
        end

        context "when no one can push" do
          let(:protected_branch) { create(:protected_branch, :no_one_can_push, project: project, name: 'protected_branch') }

          it "updates 'developers_can_push' without removing the 'no_one' access level" do
            put api("/projects/#{project.id}/repository/branches/#{protected_branch.name}/protect", user),
                developers_can_push: true, developers_can_merge: true

            expect(response).to have_gitlab_http_status(200)
            expect(json_response['name']).to eq(protected_branch.name)
            expect(protected_branch.reload.push_access_levels.pluck(:access_level)).to include(Gitlab::Access::NO_ACCESS)
          end
        end
      end
    end
  end

  describe 'PUT /projects/:id/repository/branches/:branch/unprotect' do
    let(:route) { "/projects/#{project_id}/repository/branches/#{branch_name}/unprotect" }

    shared_examples_for 'repository unprotected branch' do
      it 'unprotects a single branch' do
        put api(route, current_user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/branch')
        expect(json_response['name']).to eq(CGI.unescape(branch_name))
        expect(json_response['protected']).to eq(false)
      end

      context 'when branch does not exist' do
        let(:branch_name) { 'unknown' }

        it_behaves_like '404 response' do
          let(:request) { put api(route, current_user) }
          let(:message) { '404 Branch Not Found' }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { put api(route, current_user) }
        end
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { put api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { put api(route, guest) }
      end
    end

    context 'when authenticated', 'as a master' do
      let(:current_user) { user }

      context "when a protected branch doesn't already exist" do
        it_behaves_like 'repository unprotected branch'

        context 'when branch contains a dot' do
          let(:branch_name) { branch_with_dot.name }

          it_behaves_like 'repository unprotected branch'
        end

        context 'when branch contains a slash' do
          let(:branch_name) { branch_with_slash.name }

          it_behaves_like '404 response' do
            let(:request) { put api(route, current_user) }
          end
        end

        context 'when branch contains an escaped slash' do
          let(:branch_name) { CGI.escape(branch_with_slash.name) }

          it_behaves_like 'repository unprotected branch'
        end

        context 'requesting with the escaped project full path' do
          let(:project_id) { CGI.escape(project.full_path) }

          it_behaves_like 'repository unprotected branch'

          context 'when branch contains a dot' do
            let(:branch_name) { branch_with_dot.name }

            it_behaves_like 'repository unprotected branch'
          end
        end
      end
    end
  end

  describe 'POST /projects/:id/repository/branches' do
    let(:route) { "/projects/#{project_id}/repository/branches" }

    shared_examples_for 'repository new branch' do
      it 'creates a new branch' do
        post api(route, current_user), branch: 'feature1', ref: branch_sha

        expect(response).to have_gitlab_http_status(201)
        expect(response).to match_response_schema('public_api/v4/branch')
        expect(json_response['name']).to eq('feature1')
        expect(json_response['commit']['id']).to eq(branch_sha)
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { post api(route, current_user) }
        end
      end
    end

    context 'when unauthenticated', 'and project is private' do
      it_behaves_like '404 response' do
        let(:request) { post api(route) }
        let(:message) { '404 Project Not Found' }
      end
    end

    context 'when authenticated', 'as a guest' do
      it_behaves_like '403 response' do
        let(:request) { post api(route, guest) }
      end
    end

    context 'when authenticated', 'as a master' do
      let(:current_user) { user }

      context "when a protected branch doesn't already exist" do
        it_behaves_like 'repository new branch'

        context 'requesting with the escaped project full path' do
          let(:project_id) { CGI.escape(project.full_path) }

          it_behaves_like 'repository new branch'
        end
      end
    end

    it 'returns 400 if branch name is invalid' do
      post api(route, user), branch: 'new design', ref: branch_sha

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq('Branch name is invalid')
    end

    it 'returns 400 if branch already exists' do
      post api(route, user), branch: 'new_design1', ref: branch_sha

      expect(response).to have_gitlab_http_status(201)

      post api(route, user), branch: 'new_design1', ref: branch_sha

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq('Branch already exists')
    end

    it 'returns 400 if ref name is invalid' do
      post api(route, user), branch: 'new_design3', ref: 'foo'

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']).to eq('Invalid reference name')
    end
  end

  describe 'DELETE /projects/:id/repository/branches/:branch' do
    before do
      allow_any_instance_of(Repository).to receive(:rm_branch).and_return(true)
    end

    it 'removes branch' do
      delete api("/projects/#{project.id}/repository/branches/#{branch_name}", user)

      expect(response).to have_gitlab_http_status(204)
    end

    it 'removes a branch with dots in the branch name' do
      delete api("/projects/#{project.id}/repository/branches/#{branch_with_dot.name}", user)

      expect(response).to have_gitlab_http_status(204)
    end

    it 'returns 404 if branch not exists' do
      delete api("/projects/#{project.id}/repository/branches/foobar", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/projects/#{project.id}/repository/branches/#{branch_name}", user) }
    end
  end

  describe 'DELETE /projects/:id/repository/merged_branches' do
    before do
      allow_any_instance_of(Repository).to receive(:rm_branch).and_return(true)
    end

    it 'returns 202 with json body' do
      delete api("/projects/#{project.id}/repository/merged_branches", user)

      expect(response).to have_gitlab_http_status(202)
      expect(json_response['message']).to eql('202 Accepted')
    end

    it 'returns a 403 error if guest' do
      delete api("/projects/#{project.id}/repository/merged_branches", guest)

      expect(response).to have_gitlab_http_status(403)
    end
  end
end
