module Otp
  module Jwt
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end

    class MagicLink < ApplicationRecord
      self.table_name = "otp_jwt_magic_links"
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
