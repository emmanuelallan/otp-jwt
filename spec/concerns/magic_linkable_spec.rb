require 'spec_helper'

RSpec.describe OTP::JWT::Concerns::MagicLinkable do
  let(:user) { create_user }

  describe '#generate_magic_link' do
    it 'creates a new magic link' do
      magic_link = user.generate_magic_link
      expect(magic_link).to be_a(OTP::JWT::MagicLink)
      expect(magic_link.token).to be_present
      expect(magic_link.expires_at).to be_within(1.second).of(Time.current + OTP::JWT.config.otp_expiration)
    end
  end

  describe '#verify_magic_link_token' do
    context 'with valid token' do
      it 'returns true and marks link as used' do
        magic_link = user.generate_magic_link
        expect(user.verify_magic_link_token(magic_link.token)).to be true
        expect(magic_link.reload.used_at).to be_within(1.second).of(Time.current)
      end
    end

    context 'with expired token' do
      it 'returns false' do
        magic_link = user.generate_magic_link
        travel_to(Time.current + OTP::JWT.config.otp_expiration + 1.minute) do
          expect(user.verify_magic_link_token(magic_link.token)).to be false
        end
      end
    end

    context 'with used token' do
      it 'returns false' do
        magic_link = user.generate_magic_link
        magic_link.update!(used_at: Time.current)
        expect(user.verify_magic_link_token(magic_link.token)).to be false
      end
    end

    context 'with invalid token' do
      it 'returns false' do
        expect(user.verify_magic_link_token('invalid_token')).to be false
      end
    end
  end

  describe '#deliver_magic_link' do
    it 'raises NotImplementedError' do
      expect { user.deliver_magic_link(double) }.to raise_error(NotImplementedError)
    end
  end
end
