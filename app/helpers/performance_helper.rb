module PerformanceHelper
  extend ActiveSupport::Concern

  # Cache helper for expensive queries
  def cache_with_versioning(key, expires_in: 5.minutes, &block)
    Rails.cache.fetch(key, expires_in: expires_in, race_condition_ttl: 10.seconds, &block)
  end

  # Cached animal counts for dashboard
  def cached_animal_counts(farm_id = nil)
    farm_id ||= current_user&.farm_id
    return {} unless farm_id

    cache_with_versioning("animal_counts_#{farm_id}_#{Date.current}") do
      {
        adult_cows: Cow.adult_cows.where(farm_id: farm_id).count,
        calves: Cow.calves.where(farm_id: farm_id).count,
        active_cows: Cow.active.where(farm_id: farm_id).count,
        total_cows: Cow.where(farm_id: farm_id).count
      }
    end
  end

  # Cached health alerts
  def cached_health_alerts_count(farm_id = nil)
    farm_id ||= current_user&.farm_id
    return 0 unless farm_id

    cache_with_versioning("health_alerts_#{farm_id}_#{Date.current}") do
      HealthRecord.where(
        health_status: [ "sick", "injured", "critical" ],
        recorded_at: 7.days.ago..Time.current
      ).joins(:cow).where(cows: { farm_id: farm_id }).count
    end
  end

  # Cached vaccination alerts
  def cached_vaccination_alerts_count(farm_id = nil)
    farm_id ||= current_user&.farm_id
    return 0 unless farm_id

    cache_with_versioning("vaccination_alerts_#{farm_id}_#{Date.current}") do
      VaccinationRecord.where("next_due_date < ?", 7.days.from_now)
                       .joins(:cow)
                       .where(cows: { farm_id: farm_id })
                       .count
    end
  end

  # Cached breeding alerts
  def cached_breeding_alerts_count(farm_id = nil)
    farm_id ||= current_user&.farm_id
    return 0 unless farm_id

    cache_with_versioning("breeding_alerts_#{farm_id}_#{Date.current}") do
      BreedingRecord.where(expected_due_date: Date.current..14.days.from_now)
                    .joins(:cow)
                    .where(cows: { farm_id: farm_id })
                    .count
    end
  end

  # Cached latest production records
  def cached_latest_production(farm_id, limit = 100)
    cache_with_versioning("latest_production_#{farm_id}_#{Date.current}", expires_in: 10.minutes) do
      ProductionRecord.includes(:cow)
                      .where(farm_id: farm_id)
                      .where(production_date: Date.current)
                      .order(created_at: :desc)
                      .limit(limit)
                      .to_a
    end
  end

  # Cached production statistics
  def cached_production_stats(farm_id, days = 7)
    cache_with_versioning("production_stats_#{farm_id}_#{days}days_#{Date.current}", expires_in: 15.minutes) do
      ProductionRecord.where(farm_id: farm_id)
                      .where(production_date: days.days.ago..Date.current)
                      .group(:production_date)
                      .sum(:morning_production, :noon_production, :evening_production)
    end
  end

  # Invalidate cache for a specific farm
  def invalidate_farm_cache(farm_id)
    patterns = [
      "animal_counts_#{farm_id}_*",
      "health_alerts_#{farm_id}_*",
      "vaccination_alerts_#{farm_id}_*",
      "breeding_alerts_#{farm_id}_*",
      "latest_production_#{farm_id}_*",
      "production_stats_#{farm_id}_*"
    ]

    patterns.each do |pattern|
      Rails.cache.delete_matched(pattern)
    end
  end

  # Fragment cache helper with automatic key versioning
  def fragment_cache_key(name, record_or_array)
    if record_or_array.is_a?(Array)
      "#{name}/#{record_or_array.map { |r| "#{r.class.name}/#{r.id}/#{r.updated_at.to_i}" }.join('-')}"
    else
      "#{name}/#{record_or_array.class.name}/#{record_or_array.id}/#{record_or_array.updated_at.to_i}"
    end
  end
end
