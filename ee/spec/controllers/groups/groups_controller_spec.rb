require 'spec_helper'

describe GroupsController do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    sign_in(user)
  end

  describe 'external authorization' do
    before do
      group.add_owner(user)
    end

    context 'with external authorization service enabled' do
      before do
        enable_external_authorization_service_check
      end

      describe 'GET #show' do
        it 'is successful' do
          get :show, params: { id: group.to_param }

          expect(response).to have_gitlab_http_status(200)
        end

        it 'does not allow other formats' do
          get :show, params: { id: group.to_param }, format: :atom

          expect(response).to have_gitlab_http_status(403)
        end
      end

      describe 'GET #edit' do
        it 'is successful' do
          get :edit, params: { id: group.to_param }

          expect(response).to have_gitlab_http_status(200)
        end
      end

      describe 'GET #new' do
        it 'is successful' do
          get :new

          expect(response).to have_gitlab_http_status(200)
        end
      end

      describe 'GET #index' do
        it 'is successful' do
          get :index

          # Redirects to the dashboard
          expect(response).to have_gitlab_http_status(302)
        end
      end

      describe 'POST #create' do
        it 'creates a group' do
          expect do
            post :create, params: { group: { name: 'a name', path: 'a-name' } }
          end.to change { Group.count }.by(1)
        end
      end

      describe 'PUT #update' do
        it 'updates a group' do
          expect do
            put :update, params: { id: group.to_param, group: { name: 'world' } }
          end.to change { group.reload.name }
        end

        context 'no license' do
          it 'does not update the file_template_project_id successfully' do
            project = create(:project, group: group)

            stub_licensed_features(custom_file_templates_for_namespace: false)

            expect do
              post :update, params: { id: group.to_param, group: { file_template_project_id: project.id } }
            end.not_to change { group.reload.file_template_project_id }
          end
        end

        context 'with license' do
          it 'updates the file_template_project_id successfully' do
            project = create(:project, group: group)

            stub_licensed_features(custom_file_templates_for_namespace: true)

            expect do
              post :update, params: { id: group.to_param, group: { file_template_project_id: project.id } }
            end.to change { group.reload.file_template_project_id }.to(project.id)
          end
        end
      end

      describe 'DELETE #destroy' do
        it 'deletes the group' do
          delete :destroy, params: { id: group.to_param }

          expect(response).to have_gitlab_http_status(302)
        end
      end
    end

    describe 'GET #activity' do
      subject { get :activity, params: { id: group.to_param } }

      it_behaves_like 'disabled when using an external authorization service'
    end

    describe 'GET #issues' do
      subject { get :issues, params: { id: group.to_param } }

      it_behaves_like 'disabled when using an external authorization service'
    end

    describe 'GET #merge_requests' do
      subject { get :merge_requests, params: { id: group.to_param } }

      it_behaves_like 'disabled when using an external authorization service'
    end
  end

  describe '"group overview content" preference behaviour' do
    describe 'GET #show' do
      subject { get :show, id: group.to_param, format: format }

      let(:format) { :html }

      context 'with user having proper permissions and feature enabled' do
        before do
          stub_licensed_features(security_dashboard: true)
          group.add_developer(user)
        end

        context 'with group view set as default' do
          it 'should render the expected template' do
            expect(subject).to render_template('groups/details') # 'show' action renders the 'details' action by default
          end
        end

        context 'with group view set to security dashboard' do
          let(:user) { super().tap { |u| u.update!(group_view: :security_dashboard) } }

          context 'in HTML format' do
            it 'should render the security dashboard' do
              expect(subject).to render_template('groups/security/dashboard/show')
            end
          end

          context 'in Atom format' do
            let(:format) { :atom }

            it 'should not render the security dashboard' do
              expect(subject).not_to render_template('groups/security/dashboard/show')
            end
          end

          context 'and the feature flag is disabled' do
            before do
              stub_feature_flags(group_overview_security_dashboard: false)
            end

            it 'should render the expected template' do
              expect(subject).to render_template('groups/details')
            end
          end
        end
      end

      it_behaves_like 'ensures security dashboard permissions' do
        let(:user) { create(:user, group_view: :security_dashboard) } # not a member of a group
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(group_overview_security_dashboard: false)
        end

        let(:user) { create(:user, group_view: :security_dashboard) } # not a member of a group

        context 'when security dashboard feature is enabled' do
          before do
            stub_licensed_features(security_dashboard: true)
          end

          context 'when user is not allowed to access group security dashboard' do
            it 'works because security dashboard is not rendered' do
              expect(subject).to have_gitlab_http_status(200)
            end
          end
        end

        context 'when security dashboard feature is disabled' do
          it 'works because security dashboard is not rendered' do
            expect(subject).to have_gitlab_http_status(200)
          end
        end
      end
    end
  end
end
