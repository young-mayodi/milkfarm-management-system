class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!
  layout "application"

  def not_found
    @error_code = 404
    @error_message = "Page Not Found"
    @error_description = "The page you're looking for doesn't exist or has been moved."
    render status: :not_found
  end

  def internal_server_error
    @error_code = 500
    @error_message = "Internal Server Error"
    @error_description = "Something went wrong on our end. We've been notified and are working on it."
    render status: :internal_server_error
  end

  def unprocessable_entity
    @error_code = 422
    @error_message = "Unprocessable Entity"
    @error_description = "The change you wanted was rejected."
    render status: :unprocessable_entity
  end
end
