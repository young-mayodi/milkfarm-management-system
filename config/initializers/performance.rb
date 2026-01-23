# Performance and Caching Configuration
Rails.application.configure do
  # Memory store for development, Redis for production
  config.cache_store = :memory_store, { size: 64.megabytes }
  
  # Enable fragment caching in development for testing
  config.action_controller.perform_caching = true
  
  # Query caching
  config.active_record.query_cache_enabled = true
  
  # Eager loading optimization
  config.eager_load_paths += %W[#{config.root}/app/services]
  
  # Asset optimization
  config.assets.compile = true
  config.assets.digest = true
end

# Production optimizations
if Rails.env.production?
  Rails.application.configure do
    # Redis cache store for production
    config.cache_store = :redis_cache_store, {
      url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'),
      pool_size: 5,
      pool_timeout: 5,
      reconnect_attempts: 3
    }
    
    # Database connection optimization
    config.active_record.database_selector = { delay: 2.seconds }
    config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
    config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
    
    # Query optimization
    config.active_record.query_cache_enabled = true
    config.active_record.cache_versioning = true
    
    # Memory optimization
    config.force_ssl = true
    config.log_level = :info
  end
end
