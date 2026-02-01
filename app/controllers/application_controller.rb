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

  # PERFORMANCE: Lazy-load and cache expensive navigation counts
  def navigation_stats
    return @navigation_stats if defined?(@navigation_stats)

    @navigation_stats = Rails.cache.fetch(
      ['navigation-stats-v2', current_user&.id, Date.current],
      expires_in: 15.minutes,
      race_condition_ttl: 10.seconds
    ) do
      return {} unless current_user

      # Use counter cache or simple counts - avoid joins
      accessible_farm_ids = current_user.accessible_farms.pluck(:id)

      {
        adult_cows_count: Cow.where(farm_id: accessible_farm_ids, cow_type: 'adult').count,
        calves_count: Cow.where(farm_id: accessible_farm_ids, cow_type: 'calf').count,
        health_alerts_count: health_alerts_count_optimized(accessible_farm_ids),
        vaccination_alerts_count: vaccination_alerts_count_optimized,
        breeding_alerts_count: breeding_alerts_count_optimized,
        system_alerts_count: system_alerts_count_optimized(accessible_farm_ids)
      }
    rescue => e
      Rails.logger.error "Navigation stats error: #{e.message}"
      {}
    end
  end
  helper_method :navigation_stats

  private

  def health_alerts_count_optimized(farm_ids = nil)
    # Simplified query - only count recent sick animals
    scope = HealthRecord.where(
      health_status: ['sick', 'injured', 'critical', 'quarantine'],
      recorded_at: 7.days.ago..Time.current
    )

    scope = scope.joins(:cow).where(cows: { farm_id: farm_ids, status: 'active' }) if farm_ids.present?

    scope.select(:cow_id).distinct.count
  rescue => e
    Rails.logger.error "Health alerts count error: #{e.message}"
    0
  end

  def vaccination_alerts_count_optimized
    VaccinationRecord.where('next_due_date < ?', 7.days.from_now).limit(100).count
  rescue
    0
  end

  def breeding_alerts_count_optimized
    BreedingRecord.where(expected_due_date: Date.current..14.days.from_now).limit(100).count
  rescue
    0
  end

  def system_alerts_count_optimized(farm_ids = nil)
    # Simple count without multiple joins
    health_critical = HealthRecord.where(
      health_status: ['sick', 'critical'],
      recorded_at: 7.days.ago..Time.current
    ).limit(100).count

    temp_alerts = HealthRecord.where('temperature > ? AND recorded_at > ?', 39.5, 24.hours.ago)
                             .limit(100).count

    vaccine_overdue = VaccinationRecord.where('next_due_date < ?', Date.current)
                                      .limit(100).count

    health_critical + temp_alerts + vaccine_overdue
  rescue => e
    Rails.logger.error "System alerts count error: #{e.message}"
    0
  end
end
