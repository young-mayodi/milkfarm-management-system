require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Secret key base for production
  config.secret_key_base = ENV['SECRET_KEY_BASE'] || ENV['RAILS_MASTER_KEY']

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Railway-specific SSL configuration
  if ENV['RAILWAY_ENVIRONMENT']
    config.assume_ssl = false
    config.force_ssl = false
  elsif ENV['HEROKU_APP_NAME'] || ENV['DYNO']
    # Heroku-specific configuration
    config.assume_ssl = true
    config.force_ssl = true
  else
    # Assume all access to the app is happening through a SSL-terminating reverse proxy.
    config.assume_ssl = true
    # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
    config.force_ssl = true
  end

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Simple cache store for Railway
  config.cache_store = :memory_store

  # Simple job queue for Railway  
  config.active_job.queue_adapter = :async

  # Set host to be used by links generated in mailer templates.
  # Use Heroku, Railway's provided domain or localhost for development
  config.action_mailer.default_url_options = { 
    host: ENV.fetch('HEROKU_APP_NAME', ENV.fetch('RAILWAY_PUBLIC_DOMAIN', 'localhost:3000')) + 
          (ENV['HEROKU_APP_NAME'] ? '.herokuapp.com' : '')
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # Allow requests from Railway and Heroku domains
  config.hosts = [
    /.*\.railway\.app/,     # Allow Railway domains
    /.*\.up\.railway\.app/, # Allow Railway preview domains
    /.*\.herokuapp\.com/,   # Allow Heroku domains
  ]
  
  # Skip DNS rebinding protection for the default health check endpoint.
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
  
  # Heroku and Railway-specific configuration
  config.force_ssl = false if ENV['RAILWAY_ENVIRONMENT']
  config.assume_ssl = false if ENV['RAILWAY_ENVIRONMENT']
end
