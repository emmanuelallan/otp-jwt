require 'spec_helper'

RSpec.describe OTP::JWT::BlacklistedToken, type: :model do
  let(:token) { SecureRandom.hex(32) }
  let(:blacklisted_token) { OTP::JWT::BlacklistedToken.create!(token: token) }

  it { should validate_presence_of(:token) }
  it { should validate_uniqueness_of(:token) }
  it { should validate_presence_of(:expires_at) }

  describe '.cleanup_expired' do
    it 'deletes expired tokens' do
      expired_token = OTP::JWT::BlacklistedToken.create!(
        token: SecureRandom.hex(32),
        expires_at: Time.current - 1.minute
      )

      expect { OTP::JWT::BlacklistedToken.cleanup_expired }
        .to change { OTP::JWT::BlacklistedToken.count }.by(-1)
    end
  end
end
