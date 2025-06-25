require "rails/generators/active_record"

module Otp
  module Jwt
    module Generators
      class UserGenerator < ActiveRecord::Generators::Base
        source_root File.expand_path("../templates", __FILE__)

        def add_otp_jwt_to_user
          inject_into_class "app/models/#{file_name}.rb", class_name, "  include Otp::Jwt::Concerns::User\n"
        end

        def copy_migration
          migration_template "migration.rb", "db/migrate/add_otp_jwt_to_#{table_name}.rb"
        end
      end
    end
  end
end
