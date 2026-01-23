# Performance and Caching Configuration
Rails.application.configure do
  # Memory store for development, Redis for production
  config.cache_store = :memory_store, { size: 64.megabytes }
  
  # Enable fragment caching in development for testing
  config.action_controller.perform_caching = true
  
  # Query caching is enabled by default in Rails 8
  # config.active_record.query_cache_enabled = true # Removed - not needed in Rails 8
  
  # Eager loading optimization
  config.eager_load_paths += %W[#{config.root}/app/services]
  
  # Asset optimization
  config.assets.compile = true
  config.assets.digest = true
end

# Production optimizations
if Rails.env.production?
  Rails.application.configure do
    # Use memory store for Railway deployment (simpler than Redis)
    config.cache_store = :memory_store, { size: 128.megabytes }
    
    # Database connection optimization (Rails 8 compatible)
    # config.active_record.database_selector = { delay: 2.seconds } # Removed for Rails 8
    # config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver # Removed for Rails 8
    # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session # Removed for Rails 8
    
    # Query optimization (Rails 8 compatible)
    # config.active_record.query_cache_enabled = true # Removed - enabled by default in Rails 8
    config.active_record.cache_versioning = true
    
    # Memory optimization
    config.force_ssl = false # Disabled for Railway
    config.log_level = :info
  end
end
