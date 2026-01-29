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

  # PERFORMANCE: Cache expensive navigation counts
  def navigation_stats
    @navigation_stats ||= Rails.cache.fetch(
      ['navigation-stats', current_user&.id, Date.current],
      expires_in: 5.minutes
    ) do
      return {} unless current_user

      {
        adult_cows_count: Cow.adult_cows.where(farm: current_user.accessible_farms).count,
        calves_count: Cow.calves.where(farm: current_user.accessible_farms).count,
        health_alerts_count: health_alerts_count_optimized,
        vaccination_alerts_count: VaccinationRecord.overdue.count,
        breeding_alerts_count: BreedingRecord.overdue.count,
        system_alerts_count: system_alerts_count_optimized
      }
    end
  end
  helper_method :navigation_stats

  private

  def health_alerts_count_optimized
    # Use database query instead of loading all cows into memory
    Cow.active
       .joins(:health_records)
       .where(health_records: { 
         health_status: ['sick', 'injured', 'critical', 'quarantine'],
         recorded_at: 30.days.ago..Time.current 
       })
       .distinct
       .count
  rescue
    0
  end

  def system_alerts_count_optimized
    critical_count = Cow.joins(:health_records)
                       .where(health_records: { health_status: 'sick', recorded_at: 7.days.ago..Time.current })
                       .distinct.count +
                    HealthRecord.where('temperature > ? AND recorded_at > ?', 39.5, 24.hours.ago).count +
                    VaccinationRecord.where('next_due_date < ?', Date.current).count
    
    warning_count = BreedingRecord.where(expected_due_date: Date.current..7.days.from_now).count
    
    critical_count + warning_count
  rescue
    0
  end
end
