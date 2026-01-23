class ProductionRecord < ApplicationRecord
  # Associations
  belongs_to :cow
  belongs_to :farm

  # Validations
  validates :production_date, presence: true
  validates :morning_production, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :noon_production, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :evening_production, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :cow_id, uniqueness: { scope: :production_date, message: "already has a production record for this date" }

  # Callbacks
  before_save :calculate_total_production
  after_create :invalidate_analytics_cache
  after_update :invalidate_analytics_cache
  after_destroy :invalidate_analytics_cache

  # Scopes
  scope :for_date, ->(date) { where(production_date: date) }
  scope :for_date_range, ->(start_date, end_date) { where(production_date: start_date..end_date) }
  scope :for_month, ->(month, year) { 
    where(production_date: Date.new(year, month, 1)..Date.new(year, month, -1)) 
  }
  scope :recent, -> { order(production_date: :desc) }
  scope :high_production, ->(threshold = 20) { where('total_production > ?', threshold) }
  scope :with_cow_and_farm, -> { includes(:cow, :farm) }
  scope :optimized_for_analytics, -> { 
    joins(:cow, :farm)
      .select('production_records.*, cows.name as cow_name, cows.tag_number, farms.name as farm_name')
  }

  # Class methods
  def self.daily_farm_total(farm, date)
    Rails.cache.fetch("daily_farm_total_#{farm.id}_#{date}", expires_in: 2.hours) do
      where(farm: farm, production_date: date).sum(:total_production)
    end
  end

  def self.monthly_farm_total(farm, month = Date.current.month, year = Date.current.year)
    cache_key = "monthly_farm_total_#{farm.id}_#{month}_#{year}"
    Rails.cache.fetch(cache_key, expires_in: 4.hours) do
      where(farm: farm)
        .where(production_date: Date.new(year, month, 1)..Date.new(year, month, -1))
        .sum(:total_production)
    end
  end

  def self.top_performers(limit: 5, date_range: 1.week.ago..Date.current)
    Rails.cache.fetch("top_performers_#{date_range.begin}_#{date_range.end}_#{limit}", expires_in: 1.hour) do
      joins(:cow)
        .where(production_date: date_range)
        .group('cows.id', 'cows.name', 'cows.tag_number')
        .order('SUM(production_records.total_production) DESC')
        .limit(limit)
        .pluck('cows.id', 'cows.name', 'cows.tag_number', 'SUM(production_records.total_production)')
        .map { |id, name, tag, total| 
          { id: id, name: name, tag: tag, total: total.to_f.round(1) } 
        }
    end
  end

  def self.production_summary(farm_id: nil, date_range: 30.days.ago..Date.current)
    cache_key = "production_summary_#{farm_id}_#{date_range.begin.to_date}_#{date_range.end.to_date}"
    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      records = farm_id ? where(farm_id: farm_id) : all
      records = records.where(production_date: date_range)
      
      {
        total_records: records.count,
        total_production: records.sum(:total_production).to_f.round(1),
        average_daily: (records.average(:total_production) || 0).to_f.round(1),
        best_day_production: records.maximum(:total_production)&.to_f&.round(1) || 0.0,
        active_cows: records.joins(:cow).distinct.count('cows.id')
      }
    end
  end

  private

  def calculate_total_production
    self.total_production = (morning_production || 0) + (noon_production || 0) + (evening_production || 0)
  end

  def invalidate_analytics_cache
    # Clear farm-specific caches (using proper regex patterns)
    Rails.cache.delete_matched(/.*farm_#{farm_id}.*/)
    Rails.cache.delete_matched(/.*cow_#{cow_id}.*/)
    
    # Clear general analytics caches
    Rails.cache.delete_matched(/top_performers.*/)
    Rails.cache.delete_matched(/production_summary.*/)
    Rails.cache.delete_matched(/analytics.*/)
    Rails.cache.delete_matched(/weekly_trends.*/)
    
    # Clear daily and monthly totals
    Rails.cache.delete_matched(/.*daily_farm_total.*/)
    Rails.cache.delete_matched(/.*monthly_farm_total.*/)
  end
end
