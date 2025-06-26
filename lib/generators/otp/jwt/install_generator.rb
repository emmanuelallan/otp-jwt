require "rails/generators/base"

module OTP
  module JWT
    module Generators
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path("../templates", __FILE__)

        def copy_initializer
          template "otp_jwt.rb", "config/initializers/otp_jwt.rb"
        end
      end
    end
  end
end
