require "otp/jwt/engine"
require "otp/jwt/version"
require "otp/jwt/token"
require "otp/jwt/active_record"
require "otp/jwt/action_controller"
require "otp/jwt/concerns/user"
require "otp/jwt/concerns/authenticatable"
require "otp/jwt/concerns/tokenable"
require "otp/jwt/concerns/lockable"
require "otp/jwt/concerns/magic_linkable"

module OTP
  module JWT
    class << self
      attr_accessor :config

      def configure
        @config ||= Configuration.new
        yield(@config) if block_given?
        @config
      end

      class Configuration
        def initialize
          @otp_length = 6
          @otp_expiration = 15.minutes
          @jwt_expiration = 24.hours
          @refresh_token_expiration = 7.days
          @max_failed_attempts = 5
          @lockout_duration = 1.hour
          @on_forbidden_request = ->(controller) { controller.render json: { error: 'Invalid credentials' }, status: :forbidden }
        end

        attr_accessor :otp_length, :otp_expiration, :jwt_expiration, :refresh_token_expiration,
                      :max_failed_attempts, :lockout_duration, :on_forbidden_request
      end
    end
  end
end
