require 'sidekiq'

if ENV['REDIS_URL'].present?
  Sidekiq.configure_server do |config|
    config.redis = { url: ENV['REDIS_URL'] }
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: ENV['REDIS_URL'] }
  end

  # Configure Rails to use Sidekiq for background jobs
  Rails.application.config.active_job.queue_adapter = :sidekiq
end
