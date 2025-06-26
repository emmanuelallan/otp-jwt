require 'spec_helper'

RSpec.describe OTP::JWT::MagicLink, type: :model do
  let(:user) { create_user }
  let(:magic_link) { user.magic_links.create!(token: SecureRandom.urlsafe_base64) }

  it { should belong_to(:user) }
  it { should validate_presence_of(:token) }
  it { should validate_uniqueness_of(:token) }
  it { should validate_presence_of(:expires_at) }

  describe '#active?' do
    context 'when not revoked and not expired' do
      it 'returns true' do
        expect(magic_link.active?).to be true
      end
    end

    context 'when revoked' do
      it 'returns false' do
        magic_link.update!(revoked_at: Time.current)
        expect(magic_link.active?).to be false
      end
    end

    context 'when expired' do
      it 'returns false' do
        travel_to(magic_link.expires_at + 1.minute) do
          expect(magic_link.active?).to be false
        end
      end
    end
  end

  describe '#revoke!' do
    it 'sets the revoked_at timestamp' do
      expect { magic_link.revoke! }.to change { magic_link.revoked_at }.from(nil)
      expect(magic_link.revoked_at).to be_within(1.second).of(Time.current)
    end
  end
end
