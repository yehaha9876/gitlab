require 'spec_helper'

describe Gitlab::Middleware::ReadOnly do
  include Rack::Test::Methods
  using RSpec::Parameterized::TableSyntax

  RSpec::Matchers.define :be_a_redirect do
    match do |response|
      response.status == 301
    end
  end

  RSpec::Matchers.define :disallow_request do
    match do |middleware|
      alert = middleware.env['rack.session'].to_hash
        .dig('flash', 'flashes', 'alert')

      alert&.include?('You cannot perform write operations')
    end
  end

  let(:rack_stack) do
    rack = Rack::Builder.new do
      use ActionDispatch::Session::CacheStore
      use ActionDispatch::Flash
      use ActionDispatch::ParamsParser
    end

    rack.run(subject)
    rack.to_app
  end

  let(:observe_env) do
    Module.new do
      attr_reader :env

      def call(env)
        @env = env
        super
      end
    end
  end

  let(:request) { Rack::MockRequest.new(rack_stack) }

  subject do
    described_class.new(fake_app).tap do |app|
      app.extend(observe_env)
    end
  end

  context 'normal requests to a read-write Gitlab instance' do
    let(:fake_app) { lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }

    before do
      allow(Gitlab::Database).to receive(:read_only?) { false }
    end

    it 'expects PATCH requests to be allowed' do
      response = request.patch('/test_request')

      expect(response).not_to be_a_redirect
      expect(subject).not_to disallow_request
    end

    it 'expects PUT requests to be allowed' do
      response = request.put('/test_request')

      expect(response).not_to be_a_redirect
      expect(subject).not_to disallow_request
    end

    it 'expects POST requests to be allowed' do
      response = request.post('/test_request')

      expect(response).not_to be_a_redirect
      expect(subject).not_to disallow_request
    end

    it 'expects DELETE requests to be allowed' do
      response = request.delete('/test_request')

      expect(response).not_to be_a_redirect
      expect(subject).not_to disallow_request
    end
  end
end
