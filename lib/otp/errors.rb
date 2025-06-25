module OTP
  module Errors
    class Error < StandardError; end

    class Invalid < Error
      def message
        'The provided OTP is invalid.'
      end
    end

    class Expired < Error
      def message
        'The provided OTP has expired.'
      end
    end

    class UserNotFound < Error
      def message
        'The user was not found.'
      end
    end

    class MissingJti < Error
      def message
        'The provided token is missing the jti claim.'
      end
    end

    class BlacklistedToken < Error
      def message
        'The provided token has been blacklisted.'
      end
    end

    class AccountLocked < Error
      def message
        'Your account is locked. Please try again later.'
      end
    end
  end
end
