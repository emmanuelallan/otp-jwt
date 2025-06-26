require 'rails/generators'
require 'rails/generators/active_record'

module OTP
  module JWT
    module Generators
      class UserGenerator < ::ActiveRecord::Generators::Base
        source_root File.expand_path("../templates", __FILE__)

        def add_otp_jwt_to_user
          inject_into_class "app/models/#{file_name}.rb", class_name do
            "  include OTP::JWT::Concerns::User\n"
          end
        end

        def copy_migration
          migration_template "migration.rb", "db/migrate/add_otp_jwt_to_#{table_name}.rb"
        end
      end
    end
  end
end
