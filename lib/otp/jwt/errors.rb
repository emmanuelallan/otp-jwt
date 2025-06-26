module OTP
  module JWT
    module Errors
      class InvalidOTP < StandardError
        def initialize(message = "Invalid OTP code")
          super(message)
        end
      end

      class TokenExpired < StandardError
        def initialize(message = "Token has expired")
          super(message)
        end
      end

      class TokenBlacklisted < StandardError
        def initialize(message = "Token has been blacklisted")
          super(message)
        end
      end

      class AccountLocked < StandardError
        def initialize(message = "Account is locked")
          super(message)
        end
      end

      class RateLimited < StandardError
        def initialize(message = "Too many failed attempts. Please try again later.")
          super(message)
        end
      end
    end
  end
end
