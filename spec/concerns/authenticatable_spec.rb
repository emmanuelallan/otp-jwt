require 'spec_helper'

RSpec.describe OTP::JWT::Concerns::Authenticatable do
  let(:user) { create_user }

  describe '#generate_and_send_otp' do
    it 'generates and sends an OTP' do
      expect(user).to receive(:deliver_otp)
      otp = user.generate_and_send_otp
      expect(otp).to be_a(String)
      expect(otp.length).to eq(OTP::JWT.config.otp_length)
    end
  end

  describe '#verify_otp' do
    context 'with valid OTP' do
      it 'returns true' do
        otp = user.generate_and_send_otp
        expect(user.verify_otp(otp)).to be true
      end
    end

    context 'with invalid OTP' do
      it 'returns false' do
        expect(user.verify_otp('123456')).to be false
      end
    end

    context 'when account is locked' do
      it 'raises AccountLocked error' do
        user.lock_account
        expect { user.verify_otp('123456') }.to raise_error(OTP::JWT::Errors::AccountLocked)
      end
    end
  end

  describe '#generate_magic_link' do
    it 'creates a new magic link' do
      expect {
        user.generate_magic_link
      }.to change(user.magic_links, :count).by(1)
    end
  end

  describe '#verify_magic_link_token' do
    context 'with valid token' do
      it 'returns true' do
        magic_link = user.generate_magic_link
        expect(user.verify_magic_link_token(magic_link.token)).to be true
      end
    end

    context 'with invalid token' do
      it 'returns false' do
        expect(user.verify_magic_link_token('invalid_token')).to be false
      end
    end
  end

  describe '#generate_jwt' do
    it 'returns a valid JWT token' do
      token = user.generate_jwt
      expect(token).to be_a(String)
      payload = JWT.decode(token, user.otp_secret, true, { algorithm: 'HS256' }).first
      expect(payload['user_id']).to eq(user.id)
    end
  end

  describe '#sign_out' do
    it 'blacklists the refresh token and generates a new one' do
      old_refresh_token = user.refresh_token
      user.sign_out
      
      expect(OTP::JWT::BlacklistedToken.exists?(token: old_refresh_token)).to be true
      expect(user.refresh_token).not_to eq(old_refresh_token)
    end
  end
end
