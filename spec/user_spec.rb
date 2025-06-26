require 'spec_helper'

RSpec.describe User, type: :model do
  let(:user) { create_user }
  let(:mailer) { double('mailer') }

  before do
    allow(mailer).to receive(:magic_link).and_return(double('mail', deliver_later: true))
  end

  it { expect(user.otp).not_to be_blank }
  it { expect(user.otp_secret).not_to be_blank }
  it { expect(user.otp_counter).not_to be_blank }

  describe '#from_jwt' do
    let(:token) { user.to_jwt }

    it { expect(User.from_jwt(token)).to eq user }

    context 'with a cast-able subject value' do
      let(:token) { OTP::JWT::Token.sign(sub: user.id, jti: SecureRandom.uuid) }

      it { expect(User.from_jwt(token, 'my_claim_name')).to be_nil }
    end

    context 'with a custom claim name' do
      let(:token) { OTP::JWT::Token.sign(my_claim_name: user.id, jti: SecureRandom.uuid) }

      it { expect(User.from_jwt(token, 'my_claim_name')).to eq user }
      it { expect(OTP::JWT::Token.decode(token)['my_claim_name']).to eq user.id }
    end
  end

  describe '#otp' do
    it 'generates a 6-digit OTP' do
      expect(user.otp).to match(/^\d{6}$/)
    end

    it { expect { user.otp }.to change { user.otp_counter }.by(1) }

    context 'without a secret' do
      before { user.update!(otp_secret: nil) }

      it { expect(user.otp).to be_nil }
    end
  end

  describe '#verify_otp' do
    it 'increments the otp counter after verification' do
      otp = user.otp
      expect { user.verify_otp(otp) }.to change { user.otp_counter }.by(1)
    end

    context 'without a secret' do
      before { user.update!(otp_secret: nil) }

      it { expect(user.verify_otp('123456')).to be_nil }
    end
  end

  describe '#send_magic_link' do
    it 'sends a magic link email' do
      expect { user.send_magic_link(mailer) }.to change { OTP::JWT::MagicLink.count }.by(1)
    end
  end

  describe '#blocked?' do
    context 'when locked_at is recent' do
      before { user.update!(locked_at: 5.minutes.ago) }

      it { expect(user.blocked?).to be true }
    end

    context 'when locked_at is nil' do
      before { user.update!(locked_at: nil) }

      it { expect(user.blocked?).to be false }
    end
  end

  describe '#lock_account!' do
    it 'sets locked_at' do
      expect { user.lock_account! }.to change { user.locked_at }.from(nil)
    end
  end

  describe '#deliver_otp' do
    it 'raises NotImplementedError if no delivery method is implemented' do
      allow(user).to receive(:email_otp).and_return(nil)
      allow(user).to receive(:sms_otp).and_return(nil)
      expect { user.deliver_otp }.to raise_error(NotImplementedError)
    end
  end

  describe 'OTP::JWT::ActiveRecord#from_jwt' do
    context 'with missing jti' do
      it 'returns nil for missing jti' do
        token = OTP::JWT::Token.sign(sub: user.id) # no jti
        expect(User.from_jwt(token)).to be_nil
      end
    end

    context 'with blacklisted token' do
      let(:token) { OTP::JWT::Token.sign(sub: user.id, jti: SecureRandom.uuid) }

      before do
        payload = OTP::JWT::Token.decode(token)
        OTP::JWT::BlacklistedToken.create!(jti: payload['jti'], expires_at: 1.day.from_now)
      end

      it { expect(User.from_jwt(token)).to be_nil }
    end
  end

  describe 'OTP::JWT::ActiveRecord#blacklist_token' do
    let(:token) { OTP::JWT::Token.sign(sub: user.id, jti: SecureRandom.uuid) }

    it 'blacklists a valid token' do
      expect { user.blacklist_token(token) }.to change { OTP::JWT::BlacklistedToken.count }.by(1)
    end
  end

  describe 'OTP::JWT::ActiveRecord#expire_jwt?' do
    context 'when expire_jwt_at is nil' do
      it { expect(user.expire_jwt?).to eq user }
    end

    context 'when expire_jwt_at is in the future' do
      before { user.update!(expire_jwt_at: 1.day.from_now) }

      it { expect(user.expire_jwt?).to eq user }
    end

    context 'when expire_jwt_at is in the past' do
      before { user.update!(expire_jwt_at: 1.day.ago) }

      it { expect(user.expire_jwt?).to be_nil }
    end
  end
end

RSpec.describe "Sanity check" do
  it "runs a basic test" do
    expect(1).to eq(1)
  end
end
