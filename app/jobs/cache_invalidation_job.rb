class CacheInvalidationJob < ApplicationJob
  queue_as :default

  def perform(farm_id:, cow_id:, production_date:)
    # Clear farm-specific caches with specific keys
    clear_farm_caches(farm_id)
    clear_cow_caches(cow_id)
    clear_date_caches(farm_id, production_date)
    clear_analytics_caches
  end

  private

  def clear_farm_caches(farm_id)
    # Clear specific farm-related caches
    Rails.cache.delete("daily_farm_total_#{farm_id}_#{Date.current}")
    Rails.cache.delete("monthly_farm_total_#{farm_id}_#{Date.current.month}_#{Date.current.year}")
    
    # Clear previous month as well if we're early in the month
    if Date.current.day <= 3
      prev_month = Date.current.last_month
      Rails.cache.delete("monthly_farm_total_#{farm_id}_#{prev_month.month}_#{prev_month.year}")
    end
  end

  def clear_cow_caches(cow_id)
    # Clear cow-specific caches (use specific keys if they exist)
    # Currently there are no specific cow caches, but this is for future use
  end

  def clear_date_caches(farm_id, production_date)
    date_key = production_date.to_date
    
    # Clear production summary caches for various date ranges
    Rails.cache.delete("production_summary_#{farm_id}_#{date_key}_#{date_key}")
    
    # Clear weekly range cache
    week_start = date_key.beginning_of_week
    week_end = date_key.end_of_week
    Rails.cache.delete("production_summary_#{farm_id}_#{week_start}_#{week_end}")
    
    # Clear monthly range cache
    month_start = date_key.beginning_of_month
    month_end = date_key.end_of_month
    Rails.cache.delete("production_summary_#{farm_id}_#{month_start}_#{month_end}")
  end

  def clear_analytics_caches
    # Clear only the most commonly used analytics caches
    # Use specific date ranges instead of wildcards
    current_week = Date.current.beginning_of_week
    last_week = 1.week.ago.beginning_of_week
    
    Rails.cache.delete("top_performers_#{last_week}_#{Date.current}_5")
    Rails.cache.delete("top_performers_#{current_week}_#{Date.current}_5")
    
    # Clear current month's summary
    month_start = Date.current.beginning_of_month
    Rails.cache.delete("production_summary__#{month_start}_#{Date.current}")
  end
end
