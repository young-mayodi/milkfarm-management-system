class AnalyticsUpdateJob < ApplicationJob
  queue_as :default

  def perform(farm_id: nil, force_refresh: false)
    Rails.logger.info "Starting analytics update job for farm: #{farm_id || 'all'}"
    
    if force_refresh
      clear_analytics_cache(farm_id)
    end
    
    # Pre-calculate and cache analytics data
    preload_analytics_data(farm_id)
    
    Rails.logger.info "Analytics update job completed"
  end

  private

  def clear_analytics_cache(farm_id)
    patterns = [
      "analytics*",
      "top_performers*", 
      "production_summary*",
      "weekly_trends*"
    ]
    
    patterns << "*farm_#{farm_id}*" if farm_id
    
    patterns.each do |pattern|
      Rails.cache.delete_matched(pattern)
    end
  end

  def preload_analytics_data(farm_id)
    service = ProductionAnalyticsService.new(farm_id: farm_id)
    
    # Preload dashboard data
    service.dashboard_data
    
    # Preload weekly trends
    service.weekly_trends(4)
    
    # Preload top performers for different time ranges
    service.top_performers(5)
    service.recent_high_producers(20, 5)
    
    # Preload production summaries
    service.production_summary
    
    Rails.logger.info "Analytics data preloaded successfully"
  rescue StandardError => e
    Rails.logger.error "Error preloading analytics data: #{e.message}"
    raise e
  end
end
