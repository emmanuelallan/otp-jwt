module OTP
  module JWT
    module Concerns
      module Authenticatable
        extend ActiveSupport::Concern

        included do
          has_secure_token :otp_secret
          has_secure_token :refresh_token
          
          has_many :magic_links, class_name: 'OTP::JWT::MagicLink', dependent: :destroy
          
          validates :otp_secret, presence: true
          validates :refresh_token, presence: true
          
          before_create :generate_otp_secret
          before_create :generate_refresh_token
        end

        def generate_and_send_otp
          generate_otp
          deliver_otp(@otp)
        end

        def generate_otp
          @otp = ROTP::TOTP.new(otp_secret, digits: otp_length).now
          update_column(:otp_counter, Time.current)
          @otp
        end

        def verify_otp(code)
          verify_otp!(code)
        rescue OTP::JWT::Errors::InvalidOTP
          false
        end

        def verify_otp!(code)
          raise OTP::JWT::Errors::InvalidOTP if locked?
          
          totp = ROTP::TOTP.new(otp_secret, digits: otp_length)
          
          if totp.verify(code, drift_behind: 1, drift_ahead: 1)
            reset_otp_attempts
            true
          else
            increment_otp_attempts
            raise OTP::JWT::Errors::InvalidOTP
          end
        end

        def generate_magic_link
          magic_links.create!(token: SecureRandom.urlsafe_base64)
        end

        def verify_magic_link_token(token)
          magic_link = magic_links.find_by(token: token, used_at: nil)
          return false unless magic_link && !magic_link.expired?
          
          magic_link.update!(used_at: Time.current)
          reset_otp_attempts
          true
        end

        def generate_jwt
          OTP::JWT::Token.new(self).generate
        end

        def refresh_jwt
          OTP::JWT::Token.new(self).refresh
        end

        def sign_out
          blacklist_token(refresh_token)
          generate_refresh_token
        end

        def blacklist_token(token)
          OTP::JWT::BlacklistedToken.create!(token: token)
        end

        def locked?
          locked_at && locked_at > Time.current - OTP::JWT.config.lockout_duration
        end

        def increment_otp_attempts
          update_column(:otp_attempts, otp_attempts.to_i + 1)
          lock_account if otp_attempts.to_i >= OTP::JWT.config.max_failed_attempts
        end

        def reset_otp_attempts
          update_columns(otp_attempts: 0, locked_at: nil)
        end

        def lock_account
          update_column(:locked_at, Time.current)
        end

        private

        def generate_otp_secret
          self.otp_secret = SecureRandom.hex(32)
        end

        def generate_refresh_token
          self.refresh_token = SecureRandom.hex(32)
        end

        def deliver_otp(otp)
          raise NotImplementedError, "You must implement #{self.class}##{__method__}" 
        end

        def otp_length
          OTP::JWT.config.otp_length
        end
      end
    end
  end
end
