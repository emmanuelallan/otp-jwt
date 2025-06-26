require 'active_support/concern'

module OTP
  module JWT
    module Concerns
      module User
        extend ActiveSupport::Concern
        
        included do
          include OTP::ActiveRecord
          include OTP::JWT::ActiveRecord
          
          # Add any user-specific OTP/JWT methods here
          def deliver_otp
            return unless persisted?
            sms_otp || email_otp || raise(NotImplementedError, "No OTP delivery method configured")
          end
          
          def email_otp
            # Override this method in your User model to implement email delivery
            # Example:
            # UserMailer.otp_email(self, otp).deliver_later
            raise NotImplementedError, "email_otp method not implemented"
          end
          
          def sms_otp
            # Override this method in your User model to implement SMS delivery
            # Example:
            # SmsService.send_otp(phone_number, otp)
            nil
          end
        end
      end
    end
  end
end 