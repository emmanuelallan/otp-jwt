module OTP
  module JWT
    class BlacklistedToken < ::ActiveRecord::Base
      self.table_name = "otp_jwt_blacklisted_tokens"
      
      validates :token, presence: true, uniqueness: true
      validates :expires_at, presence: true
      
      after_create :schedule_cleanup
      
      def self.cleanup_expired
        where('expires_at < ?', Time.current).delete_all
      end
      
      private
      
      def schedule_cleanup
        cleanup_job = OTP::JWT::CleanupBlacklistedTokensJob.new
        cleanup_job.perform_later
      end
    end
  end
end
