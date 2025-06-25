module Otp
  module Jwt
    class RefreshToken < ApplicationRecord
      self.table_name = "otp_jwt_refresh_tokens"
      belongs_to :user

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
    end
  end
end
