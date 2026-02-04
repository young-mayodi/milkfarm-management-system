# Performance and Caching Configuration
Rails.application.configure do
  # Simplified Redis configuration - let Rails handle defaults
  # The detailed configuration is in config/environments/production.rb

  # Enable fragment caching
  config.action_controller.perform_caching = true

  # Query caching is enabled by default in Rails 8
  # Eager loading optimization
  config.eager_load_paths += %W[#{config.root}/app/services #{config.root}/app/jobs]

  # Asset optimization
  config.assets.compile = true
  config.assets.digest = true
end

# Production optimizations
if Rails.env.production?
  Rails.application.configure do
    # Database connection optimization
    config.active_record.cache_versioning = true

    # Enable automatic cache key versioning
    config.active_record.collection_cache_versioning = true

    # Memory optimization
    config.log_level = :info
  end
end
