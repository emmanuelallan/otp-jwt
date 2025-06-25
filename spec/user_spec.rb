require 'spec_helper'

RSpec.describe User, type: :model do
  let(:user) { create_user }

  it { expect(User.new.otp_secret).not_to be_blank }
  it { expect(User.new.deliver_otp).to be_blank }
  it { expect(User.new.otp).to be_blank }

  describe '#from_jwt' do
    let(:token) { user.to_jwt }

    it do
      expect(User.from_jwt(token)).to eq(user)
    end

    context 'with a cast-able subject value' do
      let(:token) { OTP::JWT::Token.sign(sub: user.id.to_s + '_text', jti: SecureRandom.uuid) }

      it do
        expect(User.from_jwt(token)).to be_nil
      end
    end

    context 'with a custom claim name' do
      let(:claim_value) { FFaker::Internet.password }
      let(:token) { user.to_jwt(my_claim_name: claim_value) }

      it do
        expect(OTP::JWT::Token.decode(token)['my_claim_name'])
          .to eq(claim_value)
        expect(User.from_jwt(token, 'my_claim_name')).to be_nil
      end
    end
  end

  describe '#otp' do
    it 'generates a 6-digit OTP' do
      otp = user.otp
      expect(otp).to match(/^\d{6}$/)
    end
    it do
      expect { user.otp }.to change(user, :otp_counter).by(1)
    end

    context 'without a secret' do
      it do
        user.update_column(:otp_secret, nil)
        expect(user.otp).to be_nil
      end
    end
  end

  describe '#verify_otp' do
    it 'increments the otp counter after verification' do
      expect(user.verify_otp(user.otp)).to be_truthy
      expect { user.verify_otp(user.otp) }.to change(user, :otp_counter).by(2)
    end

    context 'without a secret' do
      it do
        user.update_column(:otp_secret, nil)
        expect(user.verify_otp(rand(1000..2000).to_s)).to be_nil
      end
    end
  end

  describe '#send_magic_link' do
    it 'sends a magic link email' do
      mailer = double('Mailer', magic_link: double(deliver_later: true))
      expect { user.send_magic_link(mailer) }.to change { Otp::Jwt::MagicLink.count }.by(1)
    end
  end

  describe '#blocked?' do
    it 'returns true if locked_at is recent' do
      user.update_column(:locked_at, 1.minute.ago)
      expect(user.blocked?).to be true
    end
    it 'returns false if locked_at is nil' do
      user.update_column(:locked_at, nil)
      expect(user.blocked?).to be false
    end
  end

  describe '#lock_account!' do
    it 'sets locked_at' do
      user.lock_account!
      expect(user.locked_at).not_to be_nil
    end
  end

  describe '#deliver_otp' do
    it 'raises NotImplementedError if no delivery method is implemented' do
      u = User.create!(full_name: 'No Delivery', email: 'no@delivery.com', phone_number: nil)
      allow(u).to receive(:sms_otp).and_return(nil)
      allow(u).to receive(:email_otp).and_return(nil)
      expect { u.deliver_otp }.to raise_error(NotImplementedError)
    end
  end

  describe 'OTP::JWT::ActiveRecord#from_jwt' do
    it 'returns nil for invalid token' do
      expect(User.from_jwt('bad')).to be_nil
    end
    it 'returns nil for missing jti' do
      token = OTP::JWT::Token.sign(sub: user.id) # no jti
      expect { User.from_jwt(token) }.to raise_error(OTP::Errors::MissingJti)
    end
    it 'returns nil for blacklisted token' do
      token = user.to_jwt
      payload = OTP::JWT::Token.decode(token)
      Otp::Jwt::BlacklistedToken.create!(jti: payload['jti'], expires_at: 1.day.from_now)
      expect { User.from_jwt(token) }.to raise_error(OTP::Errors::BlacklistedToken)
    end
  end

  describe 'OTP::JWT::ActiveRecord#blacklist_token' do
    it 'blacklists a valid token' do
      token = user.to_jwt
      expect { user.blacklist_token(token) }.to change { Otp::Jwt::BlacklistedToken.count }.by(1)
    end
  end

  describe 'OTP::JWT::ActiveRecord#expire_jwt?' do
    it 'returns self if expire_jwt_at is nil' do
      expect(user.expire_jwt?).to eq(user)
    end
    it 'returns self if expire_jwt_at is in the future' do
      user.update_column(:expire_jwt_at, 1.day.from_now)
      expect(user.expire_jwt?).to eq(user)
    end
    it 'returns nil if expire_jwt_at is in the past' do
      user.update_column(:expire_jwt_at, 1.day.ago)
      expect(user.expire_jwt?).to be_nil
    end
  end
end

RSpec.describe "Sanity check" do
  it "runs a basic test" do
    expect(1).to eq(1)
  end
end
