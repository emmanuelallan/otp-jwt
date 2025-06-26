module OTP
  module JWT
    class CleanupBlacklistedTokensJob < ApplicationJob
      queue_as :default

      def perform
        BlacklistedToken.cleanup_expired
      end
    end
  end
end
