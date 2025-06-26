module OTP
  module JWT
    class MagicLink < ::ActiveRecord::Base
      self.table_name = "otp_jwt_magic_links"
      
      belongs_to :user
      
      validates :token, presence: true, uniqueness: true
      validates :expires_at, presence: true
      
      before_create :set_expires_at
      
      def active?
        !revoked? && !expired?
      end

      def revoked?
        revoked_at.present?
      end

      def expired?
        expires_at < Time.current
      end

      def revoke!
        update!(revoked_at: Time.current)
      end

      private

      def set_expires_at
        self.expires_at ||= Time.current + OTP::JWT.config.otp_expiration
      end
    end
  end
end
