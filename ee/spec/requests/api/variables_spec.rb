require 'spec_helper'

describe API::Variables do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  describe 'POST /projects/:id/variables' do
    context 'with variable environment scope available' do
      before do
        stub_licensed_features(variable_environment_scope: true)

        project.add_maintainer(user)
      end

      it 'creates variable with a specific environment scope' do
        expect do
          post api("/projects/#{project.id}/variables", user), key: 'TEST_VARIABLE_2', value: 'VALUE_2', environment_scope: 'review/*'
        end.to change { project.variables(true).count }.by(1)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['key']).to eq('TEST_VARIABLE_2')
        expect(json_response['value']).to eq('VALUE_2')
        expect(json_response['environment_scope']).to eq('review/*')
      end

      it 'allows duplicated variable key given different environment scopes' do
        variable = create(:ci_variable, project: project)

        expect do
          post api("/projects/#{project.id}/variables", user), key: variable.key, value: 'VALUE_2', environment_scope: 'review/*'
        end.to change { project.variables(true).count }.by(1)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['key']).to eq(variable.key)
        expect(json_response['value']).to eq('VALUE_2')
        expect(json_response['environment_scope']).to eq('review/*')
      end
    end
  end

  describe 'PUT /projects/:id/variables' do
    before do
      stub_licensed_features(variable_environment_scope: true)

      project.add_maintainer(user)
    end

    let!(:production_variable) { create(:ci_variable, key: 'TEST_VAR', value: 'prd', environment_scope: 'production', project: project) }
    let!(:wildcard_variable) { create(:ci_variable, key: 'TEST_VAR', value: 'wildcard', environment_scope: '*', project: project) }

    context 'when environment scope is specified' do
      before do
        put api("/projects/#{project.id}/variables/TEST_VAR", user), value: 'new', environment_scope: 'production'

        production_variable.reload
        wildcard_variable.reload
      end

      it 'updates a variable with the specific environment scope' do
        expect(response).to have_gitlab_http_status(201)
        expect(production_variable.value).to eq('new')
        expect(wildcard_variable.value).to eq('wildcard')
      end
    end

    context 'when environment scope is not specified' do
      before do
        put api("/projects/#{project.id}/variables/TEST_VAR", user), value: 'new'

        production_variable.reload
        wildcard_variable.reload
      end

      it 'updates all variables across all environments' do
        expect(response).to have_gitlab_http_status(201)
        expect(production_variable.value).to eq('new')
        expect(wildcard_variable.value).to eq('new')
      end
    end
  end
end
