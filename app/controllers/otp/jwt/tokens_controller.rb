module Otp
  module Jwt
    class TokensController < ActionController::Base
      protect_from_forgery with: :null_session
      include OTP::JWT::ActionController

      skip_before_action :current_user!, only: [:request_otp, :verify_otp]

      def render_error(code, message, status)
        render json: { error: { code: code, message: message } }, status: status
      end

      def rate_limited?(key, limit: 5, period: 10.minutes)
        count = Rails.cache.read(key).to_i
        if count >= limit
          true
        else
          Rails.cache.write(key, count + 1, expires_in: period)
          false
        end
      end

      def request_otp
        ip_key = "otp_req_ip:#{request.remote_ip}"
        user_key = "otp_req_user:#{params[:email]&.downcase}"
        if rate_limited?(ip_key) || rate_limited?(user_key)
          return render_error('RATE_LIMITED', 'Too many OTP requests. Please try again later.', :too_many_requests)
        end
        user = User.find_by(email: params[:email]&.downcase)
        if user.present?
          user.email_otp
          render json: { message: "OTP sent to #{params[:email]}. Check your inbox." }, status: :ok
        else
          render json: { message: "If your email is registered, an OTP has been sent." }, status: :ok
        end
      rescue => e
        render_error('OTP_SEND_FAILED', "Failed to send OTP: #{e.message}", :internal_server_error)
      end

      def verify_otp
        jwt_from_otp(User.find_by(email: params[:email]&.downcase), params[:otp]) do |auth_user|
          if auth_user.blocked?
            return render_error('ACCOUNT_BLOCKED', 'Your account is blocked. Please contact support.', :forbidden)
          end
          auth_user.update(current_sign_in_at: Time.current, current_sign_in_ip: request.remote_ip, sign_in_count: auth_user.sign_in_count + 1)
          render json: { token: auth_user.to_jwt, user: { id: auth_user.id, email: auth_user.email } }, status: :ok
        end
      rescue OTP::Errors::Invalid
        render_error('OTP_INVALID', 'The provided OTP is invalid.', :unauthorized)
      rescue OTP::Errors::Expired
        render_error('OTP_EXPIRED', 'The provided OTP has expired.', :unauthorized)
      rescue OTP::Errors::UserNotFound
        render_error('USER_NOT_FOUND', 'The user was not found.', :unauthorized)
      rescue => e
        render_error('AUTH_FAILED', "Authentication failed: #{e.message}", :internal_server_error)
      end

      def refresh
        refresh_token = OTP::JWT::RefreshToken.find_by(token: params[:refresh_token])

        if refresh_token&.active?
          new_access_token, new_refresh_token = refresh_token.user.issue_new_tokens
          render json: { token: new_access_token, refresh_token: new_refresh_token.token }, status: :ok
        else
          render json: { error: "Invalid refresh token" }, status: :unauthorized
        end
      end

      def sign_out
        token = request_authorization_header
        current_user.blacklist_token(token) if token
        head :no_content
      end

      def magic_link
        ip_key = "magic_link_req_ip:#{request.remote_ip}"
        token_key = "magic_link_req_token:#{params[:token]}"
        if rate_limited?(ip_key) || rate_limited?(token_key)
          return render_error('RATE_LIMITED', 'Too many magic link requests. Please try again later.', :too_many_requests)
        end
        magic_link = Otp::Jwt::MagicLink.find_by(token: params[:token])
        if magic_link&.active?
          magic_link.revoke!
          new_access_token, new_refresh_token = magic_link.user.issue_new_tokens
          render json: { token: new_access_token, refresh_token: new_refresh_token.token }, status: :ok
        else
          render_error('INVALID_MAGIC_LINK', 'Invalid magic link', :unauthorized)
        end
      end

      private

      def current_user
        @jwt_user ||= User.from_jwt(request_authorization_header)
      end

      def current_user!
        current_user || raise('User authentication failed')
      rescue
        head(:unauthorized)
      end
    end
  end
end
