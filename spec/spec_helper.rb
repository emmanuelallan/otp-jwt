puts "spec_helper.rb loaded"
require 'bundler/setup'
require 'simplecov'
require 'rails/all'

SimpleCov.start do
  add_group 'Lib', 'lib'
  add_group 'Tests', 'spec'
end
SimpleCov.minimum_coverage 90

require 'otp'
require 'otp/jwt'
require 'otp/jwt/token'
require 'otp/jwt/test_helpers'
require_relative 'dummy'
require 'ffaker'
require 'rspec/rails'
require_relative '../app/models/otp/jwt/magic_link'
require_relative '../app/models/otp/jwt/blacklisted_token'
require_relative '../app/models/otp/jwt/refresh_token'

OTP::JWT::Token.jwt_signature_key = '_'
OTP::Mailer.default from: '_'
ActiveJob::Base.queue_adapter = :test
ActionMailer::Base.delivery_method = :test

module OTP::JWT::FactoryHelpers
  # Creates an user
  #
  # @return [User]
  def create_user(attrs = {})
    User.create!(
      full_name: FFaker::Name.name,
      email: FFaker::Internet.email,
      phone_number: FFaker::PhoneNumber.phone_number,
      **attrs
    )
  end
end

module Rails4RequestMethods
  [:get, :post, :put, :delete].each do |method_name|
    define_method(method_name) do |path, named_args|
      super(
        path,
        named_args.delete(:params),
        named_args.delete(:headers)
      )
    end
  end
end

# Generator spec helper
module GeneratorSpecHelper
  def run_generator(generator, *args)
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
