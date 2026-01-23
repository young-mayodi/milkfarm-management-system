class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!

  private

  def current_user
    return nil unless session[:user_id]
    
    @current_user ||= begin
      User.find(session[:user_id])
    rescue ActiveRecord::RecordNotFound
      # Clear invalid session data
      session[:user_id] = nil
      nil
    end
  end
  helper_method :current_user

  def current_farm
    current_user&.farm
  end
  helper_method :current_farm

  def authenticate_user!
    redirect_to login_path unless current_user
  end

  def require_farm_management!
    redirect_to dashboard_path, alert: "Access denied" unless current_user&.can_manage_farm?
  end

  def require_reports_access!
    redirect_to dashboard_path, alert: "Access denied" unless current_user&.can_view_reports?
  end
end
