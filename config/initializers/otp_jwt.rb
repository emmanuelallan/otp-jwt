OTP::JWT.configure do |config|
  # ==> User Model Configuration
  # Configure the user model class name (default: 'User')
  # config.user_model = 'User'

  # ==> Mailer Configuration
  # Configure the e-mail address which will be used in the mailer "from" header.
  # config.mailer_from = "please-change-me-at-config-initializers-otp-jwt@example.com"

  # ==> OTP Configuration
  # Configure the number of digits for the OTP.
  # config.otp_digits = 6

  # ==> Token Configuration
  # Configure the secret key used to sign the JWT.
  # config.jwt_signature_key = ENV["OTP_JWT_SIGNATURE_KEY"]

  # Configure the algorithm used to sign the JWT.
  # config.jwt_algorithm = "HS256"

  # Configure the lifetime of the JWT.
  # config.jwt_lifetime = 1.hour

  # ==> Attempt Tracking and Account Locking
  # Configure the maximum number of failed OTP attempts before locking the account.
  # config.max_otp_attempts = 5

  # Configure the duration for which the account remains locked.
  # config.unlock_in = 15.minutes
end

# Set default JWT configuration
OTP::JWT::Token.jwt_signature_key = ENV['OTP_JWT_SIGNATURE_KEY'] || 'your-secret-key-change-in-production'
OTP::JWT::Token.jwt_lifetime = 1.hour
