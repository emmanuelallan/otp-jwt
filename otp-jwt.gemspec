lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "otp/jwt/version"

Gem::Specification.new do |spec|
  spec.name          = "otp-jwt"
  spec.version       = OTP::JWT::VERSION
  spec.authors       = ["Stas Suscov", "Gemini"]
  spec.email         = ["stas@nerd.ro"]

  spec.summary       = "A complete passwordless authentication solution for Rails APIs."
  spec.description   = "Handles OTP/magic link delivery (email, SMS), JWT generation, token refresh, secure sign-out, and account locking. A full-featured alternative to Devise for modern passwordless flows."
  spec.homepage      = "https://github.com/stas/otp-jwt"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.4.0"

  spec.files         = Dir["{app,config,db,lib}/**/*", "LICENSE.txt", "Rakefile", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", "~> 8.0.0.alpha"
  spec.add_dependency "jwt", "~> 2.7"
  spec.add_dependency "rotp", "~> 6.2"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "ffaker"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "rubocop", "1.64.1"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "yardstick"
end
