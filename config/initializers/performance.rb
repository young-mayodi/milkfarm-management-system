# Performance and Caching Configuration
Rails.application.configure do
  # Redis cache store for production, memory store for development
  if ENV["REDIS_URL"].present?
    config.cache_store = :redis_cache_store, {
      url: ENV["REDIS_URL"],
      namespace: "milk_production_cache",
      expires_in: 1.hour,
      reconnect_attempts: 3,
      error_handler: -> (method:, returning:, exception:) {
        Rails.logger.error("Redis cache error: #{exception.message}")
        # Continue without cache if Redis fails
      },
      driver: :ruby
    }
  else
    config.cache_store = :memory_store, { size: 128.megabytes }
  end

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
