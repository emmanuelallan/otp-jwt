require 'rails/engine'

module Otp
  module Jwt
    class Engine < ::Rails::Engine
      isolate_namespace Otp::Jwt
    end
  end
end
