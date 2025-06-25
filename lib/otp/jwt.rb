require "otp/jwt/engine"
require "otp/jwt/version"

module Otp
  module Jwt
    mattr_accessor :max_otp_attempts
    self.max_otp_attempts = 5

    mattr_accessor :unlock_in
    self.unlock_in = 15.minutes
  end
end
