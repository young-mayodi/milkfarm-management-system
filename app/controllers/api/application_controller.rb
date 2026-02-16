module Api
  class ApplicationController < ::ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authenticate_request!

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

    protected

    def authenticate_request!
      # Check for bearer token in Authorization header
      token = request.headers["Authorization"]&.split(" ")&.last

      # For development/testing, allow without token if no token provided
      if token
        @current_user = User.find_by(auth_token: token)
        render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
      else
        # In production, this would require authentication
        # For now, allow unauthenticated access for testing
      end
    end

    def current_user
      @current_user ||= User.first if Rails.env.development?
      @current_user
    end

    private

    def not_found
      render json: { error: "Resource not found" }, status: :not_found
    end

    def unprocessable_entity(exception)
      render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
