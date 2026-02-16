# frozen_string_literal: true

# Base service class for all application services
# Provides common functionality and conventions
class ApplicationService
  # Class method to call the service
  # Usage: ServiceClass.call(params)
  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  # Instance method to be implemented by subclasses
  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  private

  # Log service execution
  def log_info(message)
    Rails.logger.info("[#{self.class.name}] #{message}")
  end

  def log_error(message, exception = nil)
    Rails.logger.error("[#{self.class.name}] #{message}")
    Rails.logger.error(exception.full_message) if exception
  end

  # Wrap operation in transaction
  def with_transaction(&block)
    ActiveRecord::Base.transaction(&block)
  end

  # Cache helper with automatic key generation
  def cache_fetch(key, expires_in: 1.hour, &block)
    Rails.cache.fetch("#{self.class.name}:#{key}", expires_in: expires_in, &block)
  end
end
