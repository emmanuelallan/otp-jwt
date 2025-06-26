require 'bundler/setup'
require 'simplecov'
require 'rails/all'

SimpleCov.start do
  add_group 'Lib', 'lib'
  add_group 'Tests', 'spec'
end
SimpleCov.minimum_coverage 100

# Add lib directory to load path
$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

# Load Rails application
require_relative 'dummy'

# Load all OTP::JWT files
require 'otp/jwt'
require 'otp/jwt/engine'
require 'otp/jwt/concerns/authenticatable'
require 'otp/jwt/concerns/tokenable'
require 'otp/jwt/concerns/lockable'
require 'otp/jwt/concerns/magic_linkable'
require 'otp/jwt/models/magic_link'
require 'otp/jwt/models/blacklisted_token'
require 'otp/jwt/jobs/cleanup_blacklisted_tokens_job'
require 'otp/jwt/controllers/sessions_controller'
require 'otp/jwt/errors'
require 'otp/jwt/token'
require 'otp/jwt/test_helpers'

# Load test dependencies
require 'ffaker'
require 'rspec/rails'
require 'webmock/rspec'
require 'shoulda/matchers'

# Configure Rails application
Rails.application.eager_load!
require 'otp/jwt/token'
require 'otp/jwt/test_helpers'

module OTP
  module JWT
    module FactoryHelpers
      def create_user(attrs = {})
        user = User.create!(
          email: attrs[:email] || FFaker::Internet.email,
          otp_secret: attrs[:otp_secret] || SecureRandom.hex(32),
          refresh_token: attrs[:refresh_token] || SecureRandom.hex(32),
          otp_attempts: attrs[:otp_attempts] || 0,
          locked_at: attrs[:locked_at]
        )
        user
      end
    end
  end
end

module Rails4RequestMethods
  [:get, :post, :put, :delete].each do |method_name|
    define_method(method_name) do |path, named_args|
      if Rails::VERSION::MAJOR >= 5
        super(path, named_args)
      else
        super(path, named_args[:params], named_args[:headers])
      end
    end
  end
end

RSpec.configure do |config|
  config.include OTP::JWT::FactoryHelpers
  config.include Rails4RequestMethods
  config.include RSpec::Rails::RequestExampleGroup, type: :request
  config.include RSpec::Rails::ControllerExampleGroup, type: :controller
  config.include RSpec::Rails::ModelExampleGroup, type: :model
  config.include RSpec::Rails::FeatureExampleGroup, type: :feature
  config.include RSpec::Rails::ViewExampleGroup, type: :view
  
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end
  
  config.before(:each) do
    DatabaseCleaner.start
    WebMock.disable_net_connect!(allow: ['localhost'])
  end
  
  config.after(:each) do
    DatabaseCleaner.clean
    WebMock.allow_net_connect!
  end
  
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  
  config.shared_context_metadata_behavior = :apply_to_host_groups
  
  config.filter_run_when_matching :focus
  
  config.example_status_persistence_file_path = "spec/examples.txt"
  
  config.disable_monkey_patching!
  
  config.warnings = true
  
  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end
  
  config.profile_examples = 10
  
  config.order = :random
  
  Kernel.srand config.seed
end

# Generator spec helper
module GeneratorSpecHelper
  def run_generator(generator, args)
    silence_stream(STDOUT) do
      generator.start(args)
    end
  end

  def silence_stream(stream)
    old_stream = stream.dup
    stream.reopen(File::NULL)
    stream.sync = true
    yield
  ensure
    stream.reopen(old_stream)
    old_stream.close
  end
end

Rails.cache = ActiveSupport::Cache::MemoryStore.new

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.mock_with :rspec
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include OTP::JWT::TestHelpers, type: :model
  config.include OTP::JWT::FactoryHelpers, type: :model
  config.include ActiveJob::TestHelper, type: :model

  config.include OTP::JWT::TestHelpers, type: :request
  config.include OTP::JWT::FactoryHelpers, type: :request
  config.include ActiveJob::TestHelper, type: :request
  config.include Dummy.routes.url_helpers, type: :request

  if ::Rails::VERSION::MAJOR == 4
    config.include Rails4RequestMethods, type: :request
    config.include Rails4RequestMethods, type: :controller
  end

  config.include GeneratorSpecHelper, type: :generator
  config.include Rails.application.routes.url_helpers
end