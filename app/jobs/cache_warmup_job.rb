class CacheWarmupJob < ApplicationJob
  queue_as :low_priority

  def perform(farm_id)
    farm = Farm.find(farm_id)
    
    # Warm up critical caches
    Rails.cache.fetch("animal_counts_#{farm.id}_#{Date.current}", expires_in: 5.minutes) do
      {
        adult_cows: Cow.adult_cows.where(farm: farm).count,
        calves: Cow.calves.where(farm: farm).count,
        active_cows: Cow.active.where(farm: farm).count
      }
    end
    
    # Cache latest production records
    Rails.cache.fetch("latest_production_#{farm.id}_#{Date.current}", expires_in: 10.minutes) do
      ProductionRecord.includes(:cow)
                      .where(farm: farm)
                      .where(production_date: Date.current)
                      .order(created_at: :desc)
                      .limit(100)
                      .to_a
    end
    
    Rails.logger.info("Cache warmed up for farm #{farm.id}")
  end
end
