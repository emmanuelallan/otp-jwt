require 'spec_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) { create_user }

  describe 'POST #create' do
    context 'with valid email' do
      it 'sends an OTP and returns success' do
        post :create, params: { email: user.email }
        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('OTP sent successfully')
      end

      context 'with valid OTP' do
        it 'returns a JWT token' do
          otp = user.generate_and_send_otp
          post :create, params: { email: user.email, otp: otp }
          expect(response).to have_http_status(:ok)
          expect(json_response['token']).to be_present
        end
      end

      context 'with invalid OTP' do
        it 'returns unauthorized' do
          post :create, params: { email: user.email, otp: '123456' }
          expect(response).to have_http_status(:unauthorized)
          expect(json_response['error']).to eq('Invalid OTP')
        end
      end

      context 'with magic link' do
        it 'returns a JWT token' do
          magic_link = user.generate_magic_link
          post :create, params: { email: user.email, magic_link_token: magic_link.token }
          expect(response).to have_http_status(:ok)
          expect(json_response['token']).to be_present
        end
      end
    end

    context 'with invalid email' do
      it 'returns not found' do
        post :create, params: { email: 'invalid@example.com' }
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('User not found')
      end
    end

    context 'with locked account' do
      it 'returns forbidden' do
        user.lock_account
        post :create, params: { email: user.email }
        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('Account is locked')
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      request.headers['Authorization'] = "Bearer #{user.generate_jwt}"
    end

    it 'signs out the user' do
      delete :destroy
      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to eq('Signed out successfully')
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        request.headers['Authorization'] = 'Bearer invalid_token'
        delete :destroy
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
