require 'spec_helper'

RSpec.describe OTP::JWT::Token, type: :model do
  let(:payload) { { 'sub' => FFaker::Internet.password } }
  let(:token) do
    JWT.encode(
      payload.dup.merge(exp: Time.now.to_i + described_class.jwt_lifetime),
      described_class.jwt_signature_key,
      described_class.jwt_algorithm
    )
  end

  describe '#sign' do
    it { expect(described_class.sign(payload)).to eq(token) }
    it 'includes a 6-digit OTP in the payload if present' do
      user = create_user
      otp = user.otp
      token = described_class.sign(sub: user.id, otp: otp)
      decoded = described_class.decode(token)
      expect(decoded['otp']).to match(/^\d{6}$/)
    end

    context 'with the none algorithm' do
      before do
        OTP::JWT::Token.jwt_algorithm = 'none'
      end

      after do
        OTP::JWT::Token.jwt_algorithm = 'HS256'
      end

      it { expect(described_class.sign(payload)).to eq(token) }
    end
  end

  describe '#verify' do
    it do
      expect(described_class.verify(token).first).to include(payload)
    end

    it 'with a bad token' do
      expect { described_class.verify(FFaker::Internet.password) }
        .to raise_error(JWT::DecodeError)
    end

    it 'with an expired token' do
      token = OTP::JWT::Token.sign(
        sub: FFaker::Internet.password, exp: DateTime.now.to_i
      )
      expect { described_class.verify(token) }
        .to raise_error(JWT::ExpiredSignature)
    end

    context 'with an RSA key' do
      before do
        OTP::JWT::Token.jwt_signature_key = OpenSSL::PKey::RSA.new(2048)
        OTP::JWT::Token.jwt_algorithm = 'RS256'
      end

      after do
        OTP::JWT::Token.jwt_signature_key = '_'
        OTP::JWT::Token.jwt_algorithm = 'HS256'
      end

      it do
        expect(described_class.verify(token).first).to include(payload)
      end
    end
  end

  describe '#decode' do
    let(:user) { create_user }
    let(:payload) { { 'sub' => user.id } }

    it do
      expect(
        described_class.decode(token) { |p| User.find(p['sub']) }
      ).to eq(user)
    end

    context 'with a bad token' do
      let(:token) { FFaker::Internet.password }

      it do
        expect(described_class.decode(token)).to eq(nil)
      end
    end

    context 'with the none algorithm' do
      before do
        OTP::JWT::Token.jwt_algorithm = 'none'
      end

      after do
        OTP::JWT::Token.jwt_algorithm = 'HS256'
      end

      it do
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
