class ProductionAnalyticsService
  include ActiveModel::Model

  attr_accessor :farm_id, :date_range

  def initialize(farm_id: nil, date_range: 1.week.ago..Date.current)
    @farm_id = farm_id
    @date_range = date_range
  end

  def dashboard_data
    Rails.cache.fetch(dashboard_cache_key, expires_in: 30.minutes) do
      {
        top_performers: top_performers,
        recent_high_producers: recent_high_producers,
        production_summary: production_summary,
        weekly_trends: weekly_trends
      }
    end
  end

  def top_performers(limit: 5)
    Rails.cache.fetch(top_performers_cache_key(limit), expires_in: 1.hour) do
      base_production_query
        .where(production_date: @date_range)
        .group('cows.id', 'cows.name', 'cows.tag_number')
        .order(Arel.sql('SUM(production_records.total_production) DESC'))
        .limit(limit)
        .pluck(
          'cows.id',
          'cows.name', 
          'cows.tag_number', 
          'SUM(production_records.total_production)'
        )
        .map { |id, name, tag, total| 
          { 
            id: id, 
            name: name, 
            tag: tag, 
            total: total.to_f.round(1) 
          } 
        }
    rescue StandardError => e
      Rails.logger.error "Error fetching top performers: #{e.message}"
      []
    end
  end

  def recent_high_producers(threshold: 20, limit: 5)
    Rails.cache.fetch(high_producers_cache_key(threshold, limit), expires_in: 1.hour) do
      base_production_query
        .where(production_date: 3.days.ago..Date.current)
        .where('production_records.total_production > ?', threshold)
        .group('cows.id', 'cows.name', 'cows.tag_number')
        .order(Arel.sql('AVG(production_records.total_production) DESC'))
        .limit(limit)
        .pluck(
          'cows.id',
          'cows.name',
          'cows.tag_number',
          'AVG(production_records.total_production)'
        )
        .map { |id, name, tag, avg| 
          { 
            id: id, 
            name: name, 
            tag: tag, 
            avg: avg.to_f.round(1) 
          } 
        }
    rescue StandardError => e
      Rails.logger.error "Error fetching recent high producers: #{e.message}"
      []
    end
  end

  def production_summary
    Rails.cache.fetch(summary_cache_key, expires_in: 1.hour) do
      records = filtered_production_records
      
      {
        total_records: records.count,
        total_production: records.sum(:total_production).to_f.round(1),
        average_daily: (records.average(:total_production) || 0).to_f.round(1),
        this_week_records: records.where(production_date: Date.current.beginning_of_week..Date.current).count,
        active_cows: records.joins(:cow).distinct.count('cows.id'),
        best_day: best_production_day(records),
        production_trend: calculate_trend(records)
      }
    rescue StandardError => e
      Rails.logger.error "Error calculating production summary: #{e.message}"
      default_summary
    end
  end

  def weekly_trends(weeks: 4)
    Rails.cache.fetch(weekly_trends_cache_key(weeks), expires_in: 2.hours) do
      weeks.times.map do |i|
        week_start = i.weeks.ago.beginning_of_week
        week_end = i.weeks.ago.end_of_week
        
        week_records = filtered_production_records
          .where(production_date: week_start..week_end)
        
        {
          week: week_start.strftime('%b %d'),
          total_production: week_records.sum(:total_production).to_f.round(1),
          average_daily: (week_records.average(:total_production) || 0).to_f.round(1),
          record_count: week_records.count,
          active_cows: week_records.joins(:cow).distinct.count('cows.id')
        }
      end.reverse
    rescue StandardError => e
      Rails.logger.error "Error calculating weekly trends: #{e.message}"
      []
    end
  end

  def cow_performance_metrics(cow_id)
    Rails.cache.fetch("cow_performance_#{cow_id}_#{cache_date}", expires_in: 1.hour) do
      cow_records = ProductionRecord.where(cow_id: cow_id)
        .where(production_date: 30.days.ago..Date.current)
        .order(:production_date)

      {
        daily_production: daily_production_data(cow_records),
        weekly_averages: weekly_averages_data(cow_records),
        performance_metrics: calculate_cow_metrics(cow_records),
        recent_trend: calculate_cow_trend(cow_records)
      }
    rescue StandardError => e
      Rails.logger.error "Error calculating cow performance metrics: #{e.message}"
      {}
    end
  end

  # Class method for clearing cache
  def self.clear_cache(farm_id: nil)
    pattern = farm_id ? "*analytics*#{farm_id}*" : "*analytics*"
    Rails.cache.delete_matched(pattern)
  end

  private

  def base_production_query
    query = ProductionRecord.joins(:cow)
    query = query.where(farm_id: @farm_id) if @farm_id
    query
  end

  def filtered_production_records
    records = ProductionRecord.includes(:cow, :farm)
    records = records.where(farm_id: @farm_id) if @farm_id
    records
  end

  def daily_production_data(cow_records)
    cow_records.pluck(:production_date, :total_production).map do |date, production|
      {
        date: date.strftime('%b %d'),
        production: production.to_f.round(1)
      }
    end
  end

  def weekly_averages_data(cow_records)
    cow_records
      .group_by { |record| record.production_date.beginning_of_week }
      .map do |week_start, records|
        avg_production = records.sum(&:total_production) / records.size.to_f
        {
          week: week_start.strftime('%b %d'),
          average: avg_production.round(1)
        }
      end
      .sort_by { |data| data[:week] }
  end

  def calculate_cow_metrics(cow_records)
    return {} if cow_records.empty?

    productions = cow_records.pluck(:total_production).map(&:to_f)
    
    {
      total_production: productions.sum.round(1),
      average_daily: (productions.sum / productions.size).round(1),
      best_day: productions.max.round(1),
      consistency_score: calculate_consistency(productions),
      production_days: productions.size
    }
  end

  def calculate_cow_trend(cow_records)
    return 'stable' if cow_records.size < 7

    recent_week = cow_records.last(7).pluck(:total_production).map(&:to_f).sum
    previous_week = cow_records.limit(7).offset(7).pluck(:total_production).map(&:to_f).sum

    return 'stable' if previous_week.zero?

    change_percent = ((recent_week - previous_week) / previous_week) * 100

    case change_percent
    when 10..Float::INFINITY then 'improving'
    when -10..10 then 'stable'
    else 'declining'
    end
  end

  def calculate_consistency(productions)
    return 100 if productions.size <= 1

    mean = productions.sum / productions.size
    variance = productions.sum { |x| (x - mean) ** 2 } / productions.size
    std_dev = Math.sqrt(variance)
    
    # Consistency score: higher is better (less variation)
    coefficient_of_variation = std_dev / mean
    consistency = [100 - (coefficient_of_variation * 50), 0].max.round(1)
    
    [consistency, 100].min
  end

  def best_production_day(records)
    return nil if records.empty?

    best_record = records.order(total_production: :desc).first
    {
      date: best_record.production_date.strftime('%B %d, %Y'),
      production: best_record.total_production.to_f.round(1),
      cow: best_record.cow.name
    }
  end

  def calculate_trend(records)
    return 'stable' if records.size < 14

    recent_week = records.where(production_date: 1.week.ago..Date.current)
                        .sum(:total_production).to_f
    previous_week = records.where(production_date: 2.weeks.ago..1.week.ago)
                          .sum(:total_production).to_f

    return 'stable' if previous_week.zero?

    change_percent = ((recent_week - previous_week) / previous_week) * 100

    case change_percent
    when 5..Float::INFINITY then 'increasing'
    when -5..5 then 'stable'
    else 'decreasing'
    end
  end

  def default_summary
    {
      total_records: 0,
      total_production: 0.0,
      average_daily: 0.0,
      this_week_records: 0,
      active_cows: 0,
      best_day: nil,
      production_trend: 'stable'
    }
  end

  # Cache key generators
  def dashboard_cache_key
    "analytics_dashboard_#{@farm_id}_#{cache_date}"
  end

  def top_performers_cache_key(limit)
    "top_performers_#{@farm_id}_#{@date_range.begin}_#{@date_range.end}_#{limit}"
  end

  def high_producers_cache_key(threshold, limit)
    "high_producers_#{@farm_id}_#{threshold}_#{limit}_#{Date.current}"
  end

  def summary_cache_key
    "production_summary_#{@farm_id}_#{cache_date}"
  end

  def weekly_trends_cache_key(weeks)
    "weekly_trends_#{@farm_id}_#{weeks}_#{cache_date}"
  end

  def cache_date
    Date.current.strftime('%Y%m%d')
  end
end
