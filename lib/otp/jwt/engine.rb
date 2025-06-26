require 'rails/engine'

module OTP
  module JWT
    class Engine < ::Rails::Engine
      isolate_namespace OTP::JWT

      initializer 'otp_jwt.load_migrations' do |app|
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end

      initializer 'otp_jwt.load_config' do |app|
        OTP::JWT.configure do |config|
          config.otp_length = app.config.otp_jwt&.otp_length || 6
          config.otp_expiration = app.config.otp_jwt&.otp_expiration || 15.minutes
          config.jwt_expiration = app.config.otp_jwt&.jwt_expiration || 24.hours
          config.refresh_token_expiration = app.config.otp_jwt&.refresh_token_expiration || 7.days
          config.max_failed_attempts = app.config.otp_jwt&.max_failed_attempts || 5
          config.lockout_duration = app.config.otp_jwt&.lockout_duration || 1.hour
        end
      end

      initializer 'otp_jwt.load_routes' do |app|
        app.routes.draw do
          namespace :otp_jwt do
            post 'sessions', to: 'sessions#create'
            delete 'sessions', to: 'sessions#destroy'
          end
        end
      end

      initializer 'otp_jwt.load_controllers' do
        config.to_prepare do
          Dir.glob(Rails.root.join('app/controllers/otp/jwt/**/*.rb')).each do |controller|
            require_dependency controller
          end
        end
      end
    end
  end
end
