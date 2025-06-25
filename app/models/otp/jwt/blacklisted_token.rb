module Otp
  module Jwt
    class BlacklistedToken < ApplicationRecord
      self.table_name = "otp_jwt_blacklisted_tokens"

      def self.cleanup_expired
        where('expires_at < ?', Time.current).delete_all
      end
    end
  end
end
