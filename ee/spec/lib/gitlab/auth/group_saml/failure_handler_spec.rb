require 'spec_helper'

describe Gitlab::Auth::GroupSaml::FailureHandler do
  include Gitlab::Routing

  let(:parent_handler) { double }

  subject { described_class.new(parent_handler) }

  def failure_env(path, strategy)
    params = {
      'omniauth.error.strategy' => strategy,
      'devise.mapping' => Devise.mappings[:user],
      'warden' => Warden::Proxy.new({}, Warden::Manager.new(nil))
    }
    Rack::MockRequest.env_for(path, params)
  end

  it 'calls Groups::OmniauthCallbacksController#failure for GroupSaml' do
    strategy = OmniAuth::Strategies::GroupSaml.new({})
    callback_path = callback_group_saml_providers_path(create(:group))
    env = failure_env(callback_path, strategy)

    expect_any_instance_of(Groups::OmniauthCallbacksController).to receive(:failure).and_call_original

    subject.call(env)
  end

  it 'falls back to parent on_failure handler' do
    env = failure_env('/', double)

    expect(parent_handler).to receive(:call).with(env)

    subject.call(env)
  end
end
