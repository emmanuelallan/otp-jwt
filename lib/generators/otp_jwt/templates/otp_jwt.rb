OTP::JWT.configure do |config|
  # OTP Settings
  config.otp_length = 6
  config.otp_expiration = 15.minutes
  
  # JWT Settings
  config.jwt_expiration = 24.hours
  config.refresh_token_expiration = 7.days
  
  # Account Locking
  config.max_failed_attempts = 5
  config.lockout_duration = 1.hour
  
  # Custom Error Handling
  config.on_forbidden_request = ->(controller) do
    controller.render json: { error: 'Invalid credentials' }, status: :forbidden
  end
end
