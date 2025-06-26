module OTP
  module JWT
    module Generators
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path('templates', __dir__)

        def copy_config
          template 'otp_jwt.rb', 'config/initializers/otp_jwt.rb'
        end

        def create_models
          template 'models/user.rb', 'app/models/user.rb'
        end

        def create_migrations
          migration_template 'migrate/create_otp_jwt_tables.rb', 'db/migrate/create_otp_jwt_tables.rb'
        end

        def create_controllers
          template 'controllers/sessions_controller.rb', 'app/controllers/sessions_controller.rb'
        end

        def create_views
          directory 'views', 'app/views/sessions'
        end

        def create_routes
          route "mount OTP::JWT::Engine => '/auth'"
        end
      end
    end
  end
end
