require 'rotp'
require 'active_support/concern'
require 'active_support/configurable'
require_relative 'errors'

module OTP
  # [ActiveRecord] concern.
  module ActiveRecord
    include ActiveSupport::Configurable
    extend ActiveSupport::Concern

    # Length of the generated OTP, defaults to 6.
    OTP_DIGITS = 6

    included do
      after_initialize :setup_otp
    end

    # Generates the OTP
    #
    # @return [String] or nil if no OTP is set
    def otp
      return nil if !valid? || !persisted? || otp_secret.blank?

      otp_digits = self.class.const_get(:OTP_DIGITS)
      hotp = ROTP::HOTP.new(otp_secret, digits: otp_digits)

      transaction do
        increment!(:otp_counter)
        hotp.at(otp_counter)
      end
    end

    # Verifies the OTP
    #
    # @return otp_counter on success, nil on failure
    def verify_otp(otp)
      raise OTP::Errors::AccountLocked if blocked?
      raise OTP::Errors::Invalid if otp.blank?
      return nil if otp_secret.blank?

      otp_digits = self.class.const_get(:OTP_DIGITS)
      hotp = ROTP::HOTP.new(otp_secret, digits: otp_digits)
      transaction do
        unless hotp.verify(otp.to_s, otp_counter)
          increment!(:otp_attempts)
          lock_account! if otp_attempts >= self.class.max_otp_attempts
          raise OTP::Errors::Invalid
        end
        update!(otp_attempts: 0)
        increment!(:otp_counter)
      end
    end

    def blocked?
      locked_at.present? && locked_at > self.class.unlock_in.ago
    end

    def lock_account!
      update!(locked_at: Time.current)
    end

    def send_magic_link(mailer)
      magic_link = Otp::Jwt::MagicLink.create!(user: self, token: SecureRandom.hex(32), expires_at: 15.minutes.from_now)
      mailer.magic_link(self, magic_link).deliver_later
    end

    # Helper to send the OTP using the SMS job
    #
    # Does nothing. Implement your own handler.
    #
    # @return [OTP::API::SMSOTPJob] instance of the job
    def sms_otp
    end

    # Helper to email the OTP using a job
    #
    # Does nothing. Implement your own handler.
    #
    # @return [OTP::API::Mailer] instance of the job
    def email_otp
    end

    # Helper to deliver the OTP
    #
    # Will use the SMS job if the phone number is available.
    # Will default to the email delivery.
    #
    # @return [ActiveJob::Base] instance of the job
    def deliver_otp
      return unless persisted?
      sms_otp || email_otp || raise(NotImplementedError, self)
    end

    private
    # Provides a default value for the OTP secret attribute
    #
    # @return [String]
    def setup_otp
      self.otp_secret ||= ROTP::Base32.random_base32
      self.otp_counter ||= 0
    end
  end
end
