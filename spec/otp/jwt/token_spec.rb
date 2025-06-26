require 'spec_helper'

RSpec.describe OTP::JWT::Token do
  let(:user) { create_user }
  let(:token) { described_class.new(user) }
  let(:payload) { { user_id: user.id, exp: Time.current.to_i + OTP::JWT.config.jwt_expiration.to_i } }

  describe '#generate' do
    it 'creates a valid JWT token' do
      token_string = token.generate
      expect(token_string).to be_a(String)
      
      decoded = JWT.decode(token_string, user.otp_secret, true, { algorithm: 'HS256' }).first
      expect(decoded['user_id']).to eq(user.id)
      expect(decoded['exp']).to be_within(1).of((Time.current + OTP::JWT.config.jwt_expiration).to_i)
    end
  end

  describe '#refresh' do
    it 'refreshes an existing token' do
      token_string = token.generate
      refreshed_token = token.refresh
      
      expect(refreshed_token).not_to eq(token_string)
      
      decoded = JWT.decode(refreshed_token, user.otp_secret, true, { algorithm: 'HS256' }).first
      expect(decoded['user_id']).to eq(user.id)
      expect(decoded['exp']).to be_within(1).of((Time.current + OTP::JWT.config.jwt_expiration).to_i)
    end
  end

  describe '#decode' do
    context 'with valid token' do
      it 'returns the token payload' do
        token_string = token.generate
        payload = token.decode
        expect(payload['user_id']).to eq(user.id)
      end
    end

    context 'with expired token' do
      it 'raises TokenExpired error' do
        allow_any_instance_of(Time).to receive(:current).and_return(Time.current + OTP::JWT.config.jwt_expiration + 1.minute)
        token_string = token.generate
        
        expect { token.decode }.to raise_error(OTP::JWT::Errors::TokenExpired)
      end
    end

    context 'with blacklisted token' do
      it 'raises TokenBlacklisted error' do
        token_string = token.generate
        user.blacklist_token(token_string)
        
        expect { token.decode }.to raise_error(OTP::JWT::Errors::TokenBlacklisted)
      end
    end
  end

  describe '#blacklist' do
    it 'creates a blacklisted token record' do
      token_string = token.generate
      user.blacklist_token(token_string)
      
      expect(OTP::JWT::BlacklistedToken.exists?(token: token_string)).to be true
    end
  end

  describe '#verify' do
    context 'with valid token' do
      it 'returns true' do
        token_string = token.generate
        expect(token.verify(token_string)).to be true
      end
    end

    context 'with invalid token' do
      it 'returns false' do
        expect(token.verify('invalid_token')).to be false
      end
    end

    context 'with expired token' do
      it 'returns false' do
        token_string = token.generate
        allow_any_instance_of(Time).to receive(:current).and_return(Time.current + OTP::JWT.config.jwt_expiration + 1.minute)
        expect(token.verify(token_string)).to be false
      end
    end

    context 'with blacklisted token' do
      it 'returns false' do
        token_string = token.generate
        user.blacklist_token(token_string)
        expect(token.verify(token_string)).to be false
        expect(
          described_class.decode(token) { |p| User.find(p['sub']) }
        ).to eq(user)
      end
    end
  end

  describe 'magic link JWT' do
    let(:user) { create_user }
    let(:magic_link) { OTP::JWT::MagicLink.create!(user: user, token: SecureRandom.hex(32), expires_at: 15.minutes.from_now) }
    it 'issues a JWT via magic link' do
      token, refresh_token = user.issue_new_tokens
      expect(token).not_to be_nil
      expect(refresh_token.token).not_to be_nil
    end
  end
end
