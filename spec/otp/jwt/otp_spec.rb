require 'spec_helper'

RSpec.describe OTP::JWT::Concerns::Authenticatable do
  let(:user) { create_user }

  describe '#generate_otp' do
    it 'generates a valid OTP' do
      otp = user.generate_otp
      expect(otp).to be_a(String)
      expect(otp.length).to eq(OTP::JWT.config.otp_length)
      expect(otp).to match(/\A\d{#{OTP::JWT.config.otp_length}}\z/)
    end

    it 'updates the otp_counter' do
      expect { user.generate_otp }
        .to change { user.otp_counter }
        .from(nil)
        .to(be_within(1.second).of(Time.current))
    end
  end

  describe '#verify_otp!' do
    context 'with valid OTP' do
      it 'returns true' do
        otp = user.generate_otp
        expect(user.verify_otp!(otp)).to be true
      end

      it 'resets otp_attempts' do
        user.increment_otp_attempts
        otp = user.generate_otp
        user.verify_otp!(otp)
        expect(user.otp_attempts).to eq(0)
      end

      it 'resets locked_at' do
        user.lock_account
        otp = user.generate_otp
        user.verify_otp!(otp)
        expect(user.locked_at).to be_nil
      end
    end

    context 'with invalid OTP' do
      it 'raises InvalidOTP error' do
        expect { user.verify_otp!('123456') }
          .to raise_error(OTP::JWT::Errors::InvalidOTP)
      end

      it 'increments otp_attempts' do
        expect { user.verify_otp!('123456') }
          .to change { user.otp_attempts }
          .by(1)
      end
    end

    context 'with locked account' do
      it 'raises AccountLocked error' do
        user.lock_account
        otp = user.generate_otp
        expect { user.verify_otp!(otp) }
          .to raise_error(OTP::JWT::Errors::AccountLocked)
      end
    end
  end

  describe '#increment_otp_attempts' do
    it 'increments the otp_attempts counter' do
      expect { user.increment_otp_attempts }
        .to change { user.otp_attempts }
        .by(1)
    end

    it 'locks the account after max attempts' do
      OTP::JWT.config.max_failed_attempts.times { user.increment_otp_attempts }
      expect(user.locked?).to be true
    end
  end

  describe '#reset_otp_attempts' do
    before { user.increment_otp_attempts }

    it 'resets the otp_attempts counter' do
      expect { user.reset_otp_attempts }
        .to change { user.otp_attempts }
        .to(0)
    end

    it 'unlocks the account' do
      user.lock_account
      user.reset_otp_attempts
      expect(user.locked?).to be false
    end
  end
end
