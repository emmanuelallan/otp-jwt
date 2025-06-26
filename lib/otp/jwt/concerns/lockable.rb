module OTP
  module JWT
    module Concerns
      module Lockable
        extend ActiveSupport::Concern

        included do
          has_secure_token :lock_token
          
          validates :lock_token, presence: true
          
          before_create :generate_lock_token
        end

        def locked?
          locked_at && locked_at > Time.current - OTP::JWT.config.lockout_duration
        end

        def lock_account
          update_column(:locked_at, Time.current)
        end

        def unlock_account
          update_column(:locked_at, nil)
        end

        def increment_otp_attempts
          update_column(:otp_attempts, otp_attempts.to_i + 1)
          lock_account if otp_attempts.to_i >= OTP::JWT.config.max_failed_attempts
        end

        def reset_otp_attempts
          update_columns(otp_attempts: 0, locked_at: nil)
        end

        private

        def generate_lock_token
          self.lock_token = SecureRandom.hex(32)
        end
      end
    end
  end
end
