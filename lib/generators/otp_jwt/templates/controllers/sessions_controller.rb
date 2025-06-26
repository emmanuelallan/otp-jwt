class SessionsController < ApplicationController
  before_action :authenticate_user!, only: [:destroy]

  def create
    user = User.find_by(email: params[:email])
    return render json: { error: 'User not found' }, status: :not_found unless user

    if user.locked?
      render json: { error: 'Account is locked' }, status: :forbidden
      return
    end

    if params[:otp]
      if user.verify_otp!(params[:otp])
        render json: { token: user.generate_jwt }
      else
        render json: { error: 'Invalid OTP' }, status: :unauthorized
      end
    elsif params[:magic_link_token]
      if user.verify_magic_link_token(params[:magic_link_token])
        render json: { token: user.generate_jwt }
      else
        render json: { error: 'Invalid magic link' }, status: :unauthorized
      end
    else
      user.generate_and_send_otp
      render json: { message: 'OTP sent successfully' }
    end
  end

  def destroy
    current_user.sign_out
    render json: { message: 'Signed out successfully' }
  end

  private

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    return render json: { error: 'Unauthorized' }, status: :unauthorized unless token

    user = User.find_by(refresh_token: token)
    return render json: { error: 'Unauthorized' }, status: :unauthorized unless user

    @current_user = user
  end

  helper_method :current_user
end
