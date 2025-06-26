require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults Rails.version.to_f

    # Configuration for the application, engines, and railties goes here.
    # 
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Configure classic autoloader
    config.autoloader = :classic
    config.eager_load_paths << Rails.root.join('lib')
    
    # Configure Active Job
    config.active_job.queue_adapter = :test

    # Configure Action Mailer
    config.action_mailer.delivery_method = :test
    config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  end
end
