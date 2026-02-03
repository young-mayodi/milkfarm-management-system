require "sidekiq"

if ENV["REDIS_URL"].present?
  # Configure Redis connection pool
  redis_config = {
    url: ENV["REDIS_URL"],
    network_timeout: 5,
    reconnect_attempts: 3,
    reconnect_delay: 0.5,
    reconnect_delay_max: 2
  }

  Sidekiq.configure_server do |config|
    config.redis = redis_config.merge(
      size: ENV.fetch("SIDEKIQ_SERVER_POOL_SIZE", 10).to_i
    )
    
    # Enable reliable fetch (requires Sidekiq Pro)
    # config.reliable_fetch!
    
    # Server-side middleware
    config.server_middleware do |chain|
      # Add custom middleware here if needed
    end
  end

  Sidekiq.configure_client do |config|
    config.redis = redis_config.merge(
      size: ENV.fetch("SIDEKIQ_CLIENT_POOL_SIZE", 5).to_i
    )
  end

  # Configure Rails to use Sidekiq for background jobs
  Rails.application.config.active_job.queue_adapter = :sidekiq
  
  # Set default queue
  Sidekiq.default_job_options = { 
    'backtrace' => true,
    'retry' => 3
  }
else
  # Fallback to async adapter if Redis is not available
  Rails.application.config.active_job.queue_adapter = :async
  Rails.logger.warn("REDIS_URL not set - using async job adapter (not recommended for production)")
end
