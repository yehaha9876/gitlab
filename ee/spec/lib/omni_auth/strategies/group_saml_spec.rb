require 'spec_helper'

describe OmniAuth::Strategies::GroupSaml, type: :strategy do
  let(:strategy) { [OmniAuth::Strategies::GroupSaml, {}] }
  let!(:group) { create(:group, name: 'my-group') }
  let(:idp_sso_url) { 'https://saml.example.com/adfs/ls' }
  let(:fingerprint) { 'C1:59:74:2B:E8:0C:6C:A9:41:0F:6E:83:F6:D1:52:25:45:58:89:FB' }
  let!(:saml_provider) { create(:saml_provider, group: group, sso_url: idp_sso_url, certificate_fingerprint: fingerprint) }
  let!(:unconfigured_group) { create(:group, name: 'unconfigured-group') }
  let(:saml_response) do
    fixture = File.read('ee/spec/fixtures/saml/response.xml')
    Base64.encode64(fixture)
  end

  before do
    stub_licensed_features(group_saml: true)
  end

  describe 'callback_path option' do
    let(:callback_path) { OmniAuth::Strategies::GroupSaml.default_options[:callback_path] }

    def check(path)
      callback_path.call( "PATH_INFO" => path )
    end

    it 'dynamically detects /groups/:group_path/-/saml/callback' do
      expect(check("/groups/some-group/-/saml/callback")).to be_truthy
    end

    it 'rejects default callback paths' do
      expect(check('/saml/callback')).to be_falsey
      expect(check('/auth/saml/callback')).to be_falsey
      expect(check('/auth/group_saml/callback')).to be_falsey
      expect(check('/users/auth/saml/callback')).to be_falsey
      expect(check('/users/auth/group_saml/callback')).to be_falsey
    end
  end

  describe 'POST /groups/:group_path/-/saml/callback' do
    context 'with valid SAMLResponse' do
      before do
        allow_any_instance_of(OneLogin::RubySaml::Response).to receive(:validate_signature) { true }
        allow_any_instance_of(OneLogin::RubySaml::Response).to receive(:validate_session_expiration) { true }
        allow_any_instance_of(OneLogin::RubySaml::Response).to receive(:validate_subject_confirmation) { true }
        allow_any_instance_of(OneLogin::RubySaml::Response).to receive(:validate_conditions) { true }
      end

      it 'sets the auth hash based on the response' do
        post "/groups/my-group/-/saml/callback", SAMLResponse: saml_response

        expect(auth_hash[:info]['email']).to eq("user@example.com")
      end

      it 'sets omniauth setings from configured settings' do
        post "/groups/my-group/-/saml/callback", SAMLResponse: saml_response

        options = last_request.env['omniauth.strategy'].options
        expect(options['idp_cert_fingerprint']).to eq fingerprint
      end
    end

    context 'with invalid SAMLResponse' do
      it 'redirects somewhere so failure messages can be displayed' do
        post "/groups/my-group/-/saml/callback", SAMLResponse: saml_response

        expect(last_response.location).to include('failure')
      end
    end

    it 'returns 404 when the group is not found' do
      expect do
        post "/groups/not-a-group/-/saml/callback", SAMLResponse: saml_response
      end.to raise_error(ActionController::RoutingError)
    end

    context 'Group SAML not licensed for group' do
      before do
        stub_licensed_features(group_saml: false)
      end

      it 'returns 404' do
        expect do
          post "/groups/my-group/-/saml/callback", SAMLResponse: saml_response
        end.to raise_error(ActionController::RoutingError)
      end
    end
  end

  describe 'POST /users/auth/group_saml' do
    it 'redirects to the provider login page' do
      post '/users/auth/group_saml', group_path: 'my-group'

      expect(last_response).to redirect_to(/#{Regexp.quote(idp_sso_url)}/)
    end

    it 'returns 404 for groups without SAML configured' do
      expect do
        post '/users/auth/group_saml', group_path: 'unconfigured-group'
      end.to raise_error(ActionController::RoutingError)
    end

    it 'returns 404 when the group is not found' do
      expect do
        post '/users/auth/group_saml', group_path: 'not-a-group'
      end.to raise_error(ActionController::RoutingError)
    end

    it 'returns 404 when missing group_path param' do
      expect do
        post '/users/auth/group_saml'
      end.to raise_error(ActionController::RoutingError)
    end
  end

  describe 'POST /users/auth/group_saml/metadata' do
    it 'returns 404 when the group is not found' do
      expect do
        post '/users/auth/group_saml/metadata', group_path: 'not-a-group'
      end.to raise_error(ActionController::RoutingError)
    end

    it 'returns 404 to avoid disclosing group existence' do
      expect do
        post '/users/auth/group_saml/metadata', group_path: 'my-group'
      end.to raise_error(ActionController::RoutingError)
    end

    it 'returns 404 when feature disabled' do
      stub_feature_flags(group_saml_metadata_available: false)

      post '/users/auth/group_saml/metadata', group_path: 'my-group', token: group.saml_discovery_token

      expect(last_response.status).to eq 404
    end

    it 'suceeds when feature enabled for an individual group' do
      stub_feature_flags(group_saml_metadata_available: false)
      allow(Feature).to receive(:enabled?).with(:group_saml_metadata_available, group) { true }

      post '/users/auth/group_saml/metadata', group_path: 'my-group', token: group.saml_discovery_token

      expect(last_response.status).to eq 200
    end

    it 'returns metadata when a valid token is provided' do
      post '/users/auth/group_saml/metadata', group_path: 'my-group', token: group.saml_discovery_token

      expect(last_response.status).to eq 200
      expect(last_response.body).to start_with('<?xml')
      expect(last_response.header["Content-Type"]).to eq "application/xml"
    end

    it 'returns 404 when an invalid token is provided' do
      expect do
        post '/users/auth/group_saml/metadata', group_path: 'my-group', token: 'invalidtoken'
      end.to raise_error(ActionController::RoutingError)
    end

    it 'returns 404 when if group is not found but a token is provided' do
      expect do
        post '/users/auth/group_saml/metadata', group_path: 'not-a-group', token: 'dummytoken'
      end.to raise_error(ActionController::RoutingError)
    end

    it 'sets omniauth setings from default settings' do
      post '/users/auth/group_saml/metadata', group_path: 'my-group', token: group.saml_discovery_token

      options = last_request.env['omniauth.strategy'].options
      expect(options['assertion_consumer_service_url']).to end_with "/groups/my-group/-/saml/callback"
    end
  end

  describe 'POST /users/auth/group_saml/slo' do
    it 'returns 404 to avoid disclosing group existence' do
      post '/users/auth/group_saml/slo', group_path: 'my-group'

      expect(last_response).to be_not_found
    end
  end

  describe 'POST /users/auth/group_saml/spslo' do
    it 'returns 404 to avoid disclosing group existence' do
      post '/users/auth/group_saml/spslo', group_path: 'my-group'

      expect(last_response).to be_not_found
    end
  end
end
