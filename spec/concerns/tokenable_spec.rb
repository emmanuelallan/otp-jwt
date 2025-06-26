require 'spec_helper'

RSpec.describe OTP::JWT::Concerns::Tokenable do
  let(:user) { create_user }
  let(:token) { OTP::JWT::Concerns::Tokenable::Token.new(user) }

  describe '#generate' do
    it 'creates a valid JWT token' do
      token_string = token.generate
      expect(token_string).to be_a(String)
      
      payload = JWT.decode(token_string, user.otp_secret, true, { algorithm: 'HS256' }).first
      expect(payload['user_id']).to eq(user.id)
      expect(payload['exp']).to be_within(1).of((Time.current + OTP::JWT.config.jwt_expiration).to_i)
    end
  end

  describe '#refresh' do
    it 'refreshes an existing token' do
      token_string = token.generate
      refreshed_token = token.refresh
      
      expect(refreshed_token).not_to eq(token_string)
      
      payload = JWT.decode(refreshed_token, user.otp_secret, true, { algorithm: 'HS256' }).first
      expect(payload['user_id']).to eq(user.id)
      expect(payload['exp']).to be_within(1).of((Time.current + OTP::JWT.config.jwt_expiration).to_i)
    end
  end

  describe '#decode_token' do
    context 'with valid token' do
      it 'returns the token payload' do
        token_string = token.generate
        payload = token.decode_token
        expect(payload['user_id']).to eq(user.id)
      end
    end

    context 'with expired token' do
      it 'raises TokenExpired error' do
        allow_any_instance_of(Time).to receive(:current).and_return(Time.current + OTP::JWT.config.jwt_expiration + 1.minute)
        token_string = token.generate
        
        expect { token.decode_token }.to raise_error(OTP::JWT::Errors::TokenExpired)
      end
    end

    context 'with blacklisted token' do
      it 'raises TokenBlacklisted error' do
        token_string = token.generate
        user.blacklist_token(token_string)
        
        expect { token.decode_token }.to raise_error(OTP::JWT::Errors::TokenBlacklisted)
      end
    end
  end
end
