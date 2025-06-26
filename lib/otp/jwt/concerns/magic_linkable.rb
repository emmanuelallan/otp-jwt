module OTP
  module JWT
    module Concerns
      module MagicLinkable
        extend ActiveSupport::Concern

        included do
          has_many :magic_links, class_name: 'OTP::JWT::MagicLink', dependent: :destroy
          
          validates :email, presence: true
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

        def deliver_magic_link(magic_link)
          raise NotImplementedError, "You must implement #{self.class}##{__method__}" 
        end

        private

        def magic_link_expiration
          OTP::JWT.config.otp_expiration
        end
      end
    end
  end
end
