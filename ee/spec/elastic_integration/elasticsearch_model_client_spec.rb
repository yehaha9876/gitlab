require 'spec_helper'

# This module is monkey-patched in config/initializers/elastic_client_setup.rb
describe "Monkey-patches to ::Elasticsearch::Model::Client" do
  before do
    # Use a configuration unlikely to be reused elsewhere to make sure
    # the stubbed client doesn't affect other tests due to the memoized nature of
    # the elasticsearch client
    stub_ee_application_setting(elasticsearch_url: ['http://example.com:9300'], elasticsearch_aws_region: ':lhasruh')
  end

  it 'uses the same client instance for all subclasses' do
    a = Class.new { include ::Elasticsearch::Model }
    b = Class.new { include ::Elasticsearch::Model }
    c = Class.new(b)

    expect(::Gitlab::Elastic::Client).to receive(:build).with(anything) { :fake_client }.once

    # Ensure that the same client instance is used between classes and between
    # requests
    [a, b, c, b, c, b, a].each do |klass|
      expect(klass.__elasticsearch__.client).to eq(:fake_client)
    end
  end
end
