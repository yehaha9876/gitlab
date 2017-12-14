require './spec/simplecov_env'
SimpleCovEnv.start!

ENV["RAILS_ENV"] = 'test'
ENV["IN_MEMORY_APPLICATION_SETTINGS"] = 'true'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'shoulda/matchers'
require 'rspec/retry'
require 'rspec-parameterized'

rspec_profiling_is_configured =
  ENV['RSPEC_PROFILING_POSTGRES_URL'].present? ||
  ENV['RSPEC_PROFILING']
branch_can_be_profiled =
  ENV['GITLAB_DATABASE'] == 'postgresql' &&
  (ENV['CI_COMMIT_REF_NAME'] == 'master' ||
    ENV['CI_COMMIT_REF_NAME'] =~ /rspec-profile/)

if rspec_profiling_is_configured && (!ENV.key?('CI') || branch_can_be_profiled)
  require 'rspec_profiling/rspec'
end

if ENV['CI'] && !ENV['NO_KNAPSACK']
  require 'knapsack'
  Knapsack::Adapters::RSpecAdapter.bind
end

# require rainbow gem String monkeypatch, so we can test SystemChecks
require 'rainbow/ext/string'

# EE specific support
Dir[Rails.root.join("spec/ee/support/**/*.rb")].each { |f| require f }

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.use_instantiated_fixtures  = false
  config.mock_with :rspec

  config.verbose_retry = true
  config.display_try_failure_messages = true

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include Warden::Test::Helpers, type: :request
  config.include LoginHelpers, type: :feature
  config.include SearchHelpers, type: :feature
  config.include CookieHelper, :js
  config.include InputHelper, :js
  config.include SelectionHelper, :js
  config.include InspectRequests, :js
  config.include WaitForRequests, :js
  config.include LiveDebugger, :js
  config.include StubConfiguration
  config.include EmailHelpers, :mailer, type: :mailer
  config.include TestEnv
  config.include ActiveJob::TestHelper
  config.include ActiveSupport::Testing::TimeHelpers
  config.include StubGitlabCalls
  config.include StubGitlabData
  config.include ApiHelpers, :api
  config.include Gitlab::Routing, type: :routing
  config.include MigrationsHelpers, :migration
  config.include StubFeatureFlags
  config.include StubENV

  # EE only
  config.include EE::LicenseHelpers
  config.include Rails.application.routes.url_helpers, type: :routing

  config.infer_spec_type_from_file_location!

  config.define_derived_metadata(file_path: %r{/spec/}) do |metadata|
    location = metadata[:location]

    metadata[:api] = true if location =~ %r{/spec/requests/api/}

    # do not overwrite type if it's already set
    next if metadata.key?(:type)

    match = location.match(%r{/spec/([^/]+)/})
    metadata[:type] = match[1].singularize.to_sym if match
  end

  config.raise_errors_for_deprecations!

  if ENV['CI']
    # This includes the first try, i.e. tests will be run 4 times before failing.
    config.default_retry_count = 4
    config.reporter.register_listener(
      RspecFlaky::Listener.new,
      :example_passed,
      :dump_summary)
  end

  config.before(:suite) do
    puts "=== Start time time: #{Time.now}"
    Timecop.safe_mode = true
    TestEnv.init
  end

  config.before(:all) do
    License.destroy_all
    TestLicense.init
  end

  config.after(:suite) do
    puts "=== Current time: #{Time.now}"
    TestEnv.cleanup
  end

  config.before(:example) do
    # Skip pre-receive hook check so we can use the web editor and merge.
    allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return([true, nil])
    # Enable all features by default for testing
    allow(Feature).to receive(:enabled?) { true }
  end

  config.before(:example, :request_store) do
    RequestStore.begin!
  end

  config.after(:example, :request_store) do
    RequestStore.end!
    RequestStore.clear!
  end

  config.before(:example, :mailer) do
    reset_delivered_emails!
  end

  # Stub the `ForkedStorageCheck.storage_available?` method unless
  # `:broken_storage` metadata is defined
  #
  # This check can be slow and is unnecessary in a test environment where we
  # know the storage is available, because we create it at runtime
  config.before(:example) do |example|
    unless example.metadata[:broken_storage]
      allow(Gitlab::Git::Storage::ForkedStorageCheck)
        .to receive(:storage_available?).and_return(true)
    end
  end

  config.around(:each, :use_clean_rails_memory_store_caching) do |example|
    caching_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    example.run

    Rails.cache = caching_store
  end

  config.around(:each, :clean_gitlab_redis_cache) do |example|
    Gitlab::Redis::Cache.with(&:flushall)

    example.run

    Gitlab::Redis::Cache.with(&:flushall)
  end

  config.around(:each, :clean_gitlab_redis_shared_state) do |example|
    Gitlab::Redis::SharedState.with(&:flushall)
    Sidekiq.redis(&:flushall)

    example.run

    Gitlab::Redis::SharedState.with(&:flushall)
    Sidekiq.redis(&:flushall)
  end

  config.before(:each, :migration) do
    schema_migrate_down!
  end

  config.after(:context, :migration) do
    schema_migrate_up!
  end

  config.around(:each, :nested_groups) do |example|
    example.run if Group.supports_nested_groups?
  end

  config.around(:each, :geo) do |example|
    example.run if Gitlab::Database.postgresql?
  end

  config.around(:each, :postgresql) do |example|
    example.run if Gitlab::Database.postgresql?
  end
end

# add simpler way to match asset paths containing digest strings
RSpec::Matchers.define :match_asset_path do |expected|
  match do |actual|
    path = Regexp.escape(expected)
    extname = Regexp.escape(File.extname(expected))
    digest_regex = Regexp.new(path.sub(extname, "(?:-\\h+)?#{extname}") << '$')
    digest_regex =~ actual
  end

  failure_message do |actual|
    "expected that #{actual} would include an asset path for #{expected}"
  end

  failure_message_when_negated do |actual|
    "expected that #{actual} would not include an asset path for  #{expected}"
  end
end

FactoryGirl::SyntaxRunner.class_eval do
  include RSpec::Mocks::ExampleMethods
end

ActiveRecord::Migration.maintain_test_schema!

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Prevent Rugged from picking up local developer gitconfig.
Rugged::Settings['search_path_global'] = Rails.root.join('tmp/tests').to_s
