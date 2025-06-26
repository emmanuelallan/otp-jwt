module OTP
  module JWT
    module Concerns
      module Tokenable
        extend ActiveSupport::Concern

        class Token
          def initialize(user)
            @user = user
          end

          def generate
            payload = {
              user_id: @user.id,
              exp: expiration_time.to_i,
              iat: Time.current.to_i
            }

            JWT.encode(payload, secret_key, 'HS256')
          end

          def refresh
            payload = decode_token
            payload[:exp] = expiration_time.to_i
            JWT.encode(payload, secret_key, 'HS256')
          end

          private

          def decode_token
            token = @user.refresh_token
            raise OTP::JWT::Errors::TokenExpired if token_expired?(token)
            raise OTP::JWT::Errors::TokenBlacklisted if token_blacklisted?(token)
            
            JWT.decode(token, secret_key, true, { algorithm: 'HS256' }).first
          end

          def token_expired?(token)
            decoded = JWT.decode(token, secret_key, false, { algorithm: 'HS256' }).first
            Time.at(decoded['exp']) < Time.current
          end

          def token_blacklisted?(token)
            OTP::JWT::BlacklistedToken.exists?(token: token)
          end

          def secret_key
            @user.otp_secret
          end

          def expiration_time
            Time.current + OTP::JWT.config.jwt_expiration
          end
        end
      end
    end
  end
end
