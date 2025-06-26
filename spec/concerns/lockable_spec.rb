require 'spec_helper'

RSpec.describe OTP::JWT::Concerns::Lockable do
  let(:user) { create_user }

  describe '#locked?' do
    context 'when account is not locked' do
      it 'returns false' do
        expect(user.locked?).to be false
      end
    end

    context 'when account is locked' do
      before { user.lock_account }

      it 'returns true' do
        expect(user.locked?).to be true
      end

      context 'after lockout duration' do
        it 'returns false' do
          travel_to(Time.current + OTP::JWT.config.lockout_duration + 1.minute) do
            expect(user.locked?).to be false
          end
        end
      end
    end
  end

  describe '#lock_account' do
    it 'sets the locked_at timestamp' do
      expect { user.lock_account }.to change { user.locked_at }.from(nil)
      expect(user.locked_at).to be_within(1.second).of(Time.current)
    end
  end

  describe '#unlock_account' do
    before { user.lock_account }

    it 'resets the locked_at timestamp' do
      expect { user.unlock_account }.to change { user.locked_at }.to(nil)
    end
  end

  describe '#increment_otp_attempts' do
    it 'increases the otp_attempts counter' do
      expect { user.increment_otp_attempts }.to change { user.otp_attempts }.by(1)
    end

    it 'locks the account after max attempts' do
      OTP::JWT.config.max_failed_attempts.times { user.increment_otp_attempts }
      expect(user.locked?).to be true
    end
  end

  describe '#reset_otp_attempts' do
    before { user.increment_otp_attempts }

    it 'resets the otp_attempts counter' do
      expect { user.reset_otp_attempts }.to change { user.otp_attempts }.to(0)
    end

    it 'unlocks the account' do
      user.lock_account
      user.reset_otp_attempts
      expect(user.locked?).to be false
    end
  end
end
