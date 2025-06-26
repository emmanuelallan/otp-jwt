require 'spec_helper'

RSpec.describe OTP::JWT::CleanupBlacklistedTokensJob, type: :job do
  let(:job) { described_class.new }

  describe '#perform' do
    it 'calls cleanup_expired on BlacklistedToken' do
      expect(OTP::JWT::BlacklistedToken).to receive(:cleanup_expired)
      job.perform
    end
  end
end
