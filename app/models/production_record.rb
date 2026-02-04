class ProductionRecord < ApplicationRecord
  # Associations
  belongs_to :cow, counter_cache: true
  belongs_to :farm, counter_cache: true

  # Validations
  validates :production_date, presence: true
  validates :morning_production, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :noon_production, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :evening_production, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :cow_id, uniqueness: { scope: :production_date, message: "already has a production record for this date" }

  # SECURITY: Prevent future dates and very old dates
  validate :production_date_not_in_future
  validate :production_date_not_too_old
  validate :farm_matches_cow

  private

  def production_date_not_in_future
    if production_date.present? && production_date > Date.current
      errors.add(:production_date, "cannot be in the future")
    end
  end

  def production_date_not_too_old
    if production_date.present? && production_date < 1.year.ago
      errors.add(:production_date, "cannot be more than 1 year in the past")
    end
  end

  def farm_matches_cow
    if cow.present? && farm.present? && cow.farm_id != farm_id
      errors.add(:base, "Farm must match the cow's farm")
    end
  end

  public

  # Callbacks
  before_save :calculate_total_production
  after_commit :invalidate_analytics_cache, on: [ :create, :update, :destroy ]

  # Scopes
  scope :for_date, ->(date) { where(production_date: date) }
  scope :for_date_range, ->(start_date, end_date) { where(production_date: start_date..end_date) }
  scope :for_month, ->(month, year) {
    where(production_date: Date.new(year, month, 1)..Date.new(year, month, -1))
  }
  scope :recent, -> { order(production_date: :desc) }
  scope :high_production, ->(threshold = 20) { where("total_production > ?", threshold) }
  scope :with_cow_and_farm, -> { includes(:cow, :farm) }
  scope :optimized_for_analytics, -> {
    joins(:cow, :farm)
      .select("production_records.*, cows.name as cow_name, cows.tag_number, farms.name as farm_name")
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
        .group("cows.id", "cows.name", "cows.tag_number")
        .order("SUM(production_records.total_production) DESC")
        .limit(limit)
        .pluck("cows.id", "cows.name", "cows.tag_number", "SUM(production_records.total_production)")
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
        active_cows: records.joins(:cow).distinct.count("cows.id")
      }
    end
  end

  # Enhanced analytics methods
  def self.weekly_trend_analysis(weeks_back: 8)
    end_date = Date.current
    start_date = weeks_back.weeks.ago.beginning_of_week

    records = where(production_date: start_date..end_date)
    weekly_data = {}
    weekly_productions = []

    (0..weeks_back-1).each do |week_offset|
      week_start = end_date.beginning_of_week - week_offset.weeks
      week_end = week_start.end_of_week

      week_production = records.where(production_date: week_start..week_end).sum(:total_production)
      weekly_productions << week_production

      weekly_data[week_start] = {
        production: week_production,
        average_daily: week_production / 7.0,
        week_number: week_start.strftime("W%W"),
        trend: nil # Will be calculated below
      }
    end

    # Calculate trends for each week based on comparison with previous week
    sorted_weeks = weekly_data.keys.sort.reverse # Most recent first
    sorted_weeks.each_with_index do |(week, data), index|
      if index > 0 # Skip first week (most recent) since it has no previous week to compare
        previous_week = sorted_weeks[index - 1]
        current_production = weekly_data[week][:production]
        previous_production = weekly_data[previous_week][:production]

        if previous_production > 0
          percentage_change = ((current_production - previous_production) / previous_production.to_f) * 100
          if percentage_change > 5
            weekly_data[week][:trend] = "increasing"
          elsif percentage_change < -5
            weekly_data[week][:trend] = "decreasing"
          else
            weekly_data[week][:trend] = "stable"
          end
        else
          weekly_data[week][:trend] = current_production > 0 ? "increasing" : "stable"
        end
      else
        # For the most recent week, compare with average of last 3 weeks
        if weekly_productions.length >= 3
          recent_avg = weekly_productions[1..3].sum / 3.0
          current_production = weekly_productions[0]
          if recent_avg > 0
            percentage_change = ((current_production - recent_avg) / recent_avg) * 100
            if percentage_change > 5
              weekly_data[week][:trend] = "increasing"
            elsif percentage_change < -5
              weekly_data[week][:trend] = "decreasing"
            else
              weekly_data[week][:trend] = "stable"
            end
          else
            weekly_data[week][:trend] = "stable"
          end
        else
          weekly_data[week][:trend] = "stable"
        end
      end
    end

    weekly_data
  end

  def self.monthly_trend_analysis(months_back: 6)
    monthly_data = {}

    (0..months_back-1).each do |month_offset|
      date = month_offset.months.ago
      month_production = for_month(date.month, date.year).sum(:total_production)
      days_in_month = Date.new(date.year, date.month, -1).day

      monthly_data[date.beginning_of_month] = {
        production: month_production,
        average_daily: month_production / days_in_month,
        month_name: date.strftime("%B %Y")
      }
    end

    monthly_data
  end

  def self.predictive_analysis(farm = nil)
    # Get last 12 weeks of data for prediction
    base_query = farm ? where(farm: farm) : self
    last_12_weeks = base_query.where(production_date: 12.weeks.ago..Date.current)

    # Calculate weekly averages
    weekly_totals = []
    (0..11).each do |week_offset|
      week_start = Date.current.beginning_of_week - week_offset.weeks
      week_end = week_start.end_of_week
      weekly_total = last_12_weeks.where(production_date: week_start..week_end).sum(:total_production)
      weekly_totals << weekly_total
    end

    # Simple linear trend calculation
    weeks = (0..11).to_a
    mean_weeks = weeks.sum / weeks.length.to_f
    mean_production = weekly_totals.sum / weekly_totals.length.to_f

    # Calculate slope (trend)
    numerator = weeks.zip(weekly_totals).sum { |x, y| (x - mean_weeks) * (y - mean_production) }
    denominator = weeks.sum { |x| (x - mean_weeks) ** 2 }
    slope = denominator != 0 ? numerator / denominator.to_f : 0

    # Predict next 4 weeks
    predictions = []
    (1..4).each do |future_week|
      predicted_value = mean_production + (slope * (12 + future_week - mean_weeks))
      predictions << {
        week: (Date.current + future_week.weeks).beginning_of_week,
        predicted_production: [ predicted_value, 0 ].max.round(1),
        confidence: calculate_prediction_confidence(weekly_totals, slope)
      }
    end

    {
      trend: slope > 0 ? "increasing" : (slope < 0 ? "decreasing" : "stable"),
      trend_percentage: ((slope / mean_production) * 100).round(2),
      predictions: predictions,
      current_average: mean_production.round(1)
    }
  end

  def self.calculate_prediction_confidence(data, slope)
    # Simple confidence calculation based on data variance
    variance = data.map { |x| (x - data.sum/data.length.to_f) ** 2 }.sum / data.length.to_f
    coefficient_of_variation = Math.sqrt(variance) / (data.sum/data.length.to_f)

    # Higher variance = lower confidence
    confidence = [ 100 - (coefficient_of_variation * 50), 20 ].max
    confidence.round(0)
  end

  private

  def calculate_total_production
    self.total_production = (morning_production || 0) + (noon_production || 0) + (evening_production || 0)
  end

  # Immediate cache invalidation for critical operations
  def invalidate_analytics_cache
    # Clear only the most critical caches immediately
    Rails.cache.delete("daily_farm_total_#{farm_id}_#{production_date}")
    Rails.cache.delete("monthly_farm_total_#{farm_id}_#{production_date.month}_#{production_date.year}")

    # Clear production summary for this farm and date range
    date_key = production_date.to_date
    Rails.cache.delete("production_summary_#{farm_id}_#{date_key}_#{date_key}")

    # TODO: Move comprehensive cache invalidation back to background job
    # For now, clear a few more important caches immediately
    Rails.cache.delete_matched("top_performers_*")
    Rails.cache.delete_matched("production_summary_#{farm_id}_*")
  end
end
