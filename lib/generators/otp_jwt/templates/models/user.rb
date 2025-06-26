class User < ApplicationRecord
  include OTP::JWT::Concerns::Authenticatable
  include OTP::JWT::Concerns::Tokenable
  include OTP::JWT::Concerns::Lockable
  include OTP::JWT::Concerns::MagicLinkable

  # Customize OTP delivery
  def deliver_otp(otp)
    UserMailer.otp(self, otp).deliver_later
  end

  def deliver_magic_link(magic_link)
    UserMailer.magic_link(self, magic_link).deliver_later
  end
end
