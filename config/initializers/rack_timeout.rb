# frozen_string_literal: true

# Rack::Timeout configuration
# Prevents requests from hanging indefinitely

if defined?(Rack::Timeout)
  # Configure via environment variables (newer API)
  # Service timeout (total request time): 30 seconds
  ENV["RACK_TIMEOUT_SERVICE_TIMEOUT"] ||= "30"

  # Wait timeout (time spent waiting in queue): 5 seconds
  # ENV['RACK_TIMEOUT_WAIT_TIMEOUT'] ||= '5'

  # Add middleware
  Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Timeout
end
