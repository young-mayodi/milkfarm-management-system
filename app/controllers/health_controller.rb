# Health check and monitoring test controller
class HealthController < ApplicationController
  skip_before_action :authenticate_user!, if: :json_request?
  skip_before_action :verify_authenticity_token
  
  # GET /health
  def index
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      environment: Rails.env,
      database: database_status,
      bugsnag: bugsnag_status,
      skylight: skylight_status
    }
  end
  
  # GET /health/bugsnag_test
  # This endpoint intentionally raises an error to test Bugsnag
  def bugsnag_test
    if Rails.env.production?
      # Only allow in production with a secret parameter
      if params[:secret] == ENV['BUGSNAG_TEST_SECRET']
        raise StandardError, "Bugsnag test error - #{Time.current}"
      else
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    else
      # In development, just raise the error
      raise StandardError, "Bugsnag test error - #{Time.current}"
    end
  end
  
  private
  
  def json_request?
    request.format.json? || request.path.start_with?('/health')
  end
  
  def database_status
    ActiveRecord::Base.connection.active? ? 'connected' : 'disconnected'
  rescue => e
    "error: #{e.message}"
  end
  
  def bugsnag_status
    if defined?(Bugsnag)
      {
        configured: Bugsnag.configuration.api_key.present?,
        api_key_present: ENV['BUGSNAG_API_KEY'].present?,
        release_stage: Bugsnag.configuration.release_stage
      }
    else
      'not loaded'
    end
  end
  
  def skylight_status
    if defined?(Skylight)
      {
        configured: true,
        api_key_present: ENV['SKYLIGHT_AUTHENTICATION'].present?
      }
    else
      'not loaded'
    end
  end
end
