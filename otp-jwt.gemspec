require "date"

require "otp/jwt/version"

Gem::Specification.new do |spec|
  spec.name                 = "otp-jwt"
  spec.version              = OTP::JWT::VERSION
  spec.authors              = ["Emmanuel Allan"]
  spec.email                = ["imma.allan@gmail.com"]

  spec.summary              = "A complete passwordless authentication solution for Rails APIs using OTP and JWT."
  spec.description          = "A modern, secure passwordless authentication solution for Rails APIs that supports OTP delivery via email/SMS, magic links, JWT authentication, token refresh, secure sign-out, and account locking."
  spec.homepage             = "https://github.com/emmanuelallan/otp-jwt"
  spec.license              = "MIT"

  spec.files                = Dir["{app,config,db,lib}/**/*", "LICENSE.txt", "Rakefile", "README.md"]
  spec.require_paths        = ["lib"]

  spec.add_dependency 'activesupport'
  spec.add_dependency 'jwt', '~> 2'
  spec.add_dependency 'rotp', '~> 6'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'ffaker'
  spec.add_development_dependency 'rails', ENV['RAILS_VERSION']
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rubocop', ENV['RUBOCOP_VERSION']
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rails_config'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'sqlite3', ENV['SQLITE3_VERSION']
  spec.add_development_dependency 'tzinfo-data'
  spec.add_development_dependency 'yardstick'
end