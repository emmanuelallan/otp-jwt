require 'active_support/concern'

module OTP
  module JWT
    # [ActiveRecord] concern.
    module ActiveRecord
      extend ActiveSupport::Concern

      class_methods do
        # Returns a record based on the [JWT] token subject
        #
        # @param token [String] representing a [JWT] token
        # @param claim_name [String] the claim name to be used, default is `sub`
        # @return [ActiveRecord::Base] model
        def from_jwt(token, claim_name = 'sub')
          OTP::JWT::Token.decode(token) do |payload|
            raise OTP::Errors::MissingJti unless payload['jti']
            raise OTP::Errors::BlacklistedToken if Otp::Jwt::BlacklistedToken.exists?(jti: payload['jti'])

            val = payload[claim_name]
            pk_col = self.column_for_attribute(self.primary_key)


            # Arel casts the values to the primary key type,
            # which means that an UUID becomes an integer by default...
            if self.connection.respond_to?(:lookup_cast_type_from_column)
              pk_type = self.connection.lookup_cast_type_from_column(pk_col)
              casted_val = pk_type.serialize(val)
            else
              casted_val = self.connection.type_cast(val, pk_col)
            end

            return if casted_val.to_s != val.to_s.strip

            self.find_by(self.primary_key => val)&.expire_jwt?
          end
        end
      end

      # Returns a [JWT] token for this record
      #
      # @param claims [Hash] extra claims to be included
      # @return [ActiveRecord::Base] model
      def to_jwt(claims = nil)
        jti = SecureRandom.uuid
        OTP::JWT::Token.sign(
          sub: self.send(self.class.primary_key),
          jti: jti,
          **(claims || {})
        )
      end

      def blacklist_token(token)
        decoded_token = OTP::JWT::Token.decode(token)
        jti = decoded_token['jti']
        exp = decoded_token['exp']
        Otp::Jwt::BlacklistedToken.create!(jti: jti, expires_at: Time.at(exp))
      end

      def issue_new_tokens
        new_access_token = to_jwt
        new_refresh_token = OTP::JWT::RefreshToken.create!(user: self, token: SecureRandom.hex(32), expires_at: 1.year.from_now)
        [new_access_token, new_refresh_token]
      end

      # Reset the [JWT] token if it is set to expire
      #
      # This method allows you to expire any token, independently from
      # the JWT flags/payload.
      #
      # @return nil if the expiration worked, otherwise returns the model
      def expire_jwt?
        return self unless self.respond_to?(:expire_jwt_at)
        return self unless expire_jwt_at? && expire_jwt_at.past?
      end
    end
  end
end
