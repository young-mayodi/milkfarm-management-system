# ⚡ Report Cache Service - Optimized Report Generation with Caching
# This service pre-calculates and caches expensive report queries

class ReportCacheService
  class << self
    # Farm Summary Report - cached for 1 hour
    def farm_summary_data(force_refresh: false)
      cache_key = ['farm_summary', Date.current].join('/')
      
      Rails.cache.fetch(cache_key, force: force_refresh, expires_in: 1.hour) do
        calculate_farm_summary
      end
    end
    
    # Cow Summary Report - cached for 1 hour per date range and farm
    def cow_summary_data(date_range: 30, farm_id: nil, force_refresh: false)
      cache_key = ['cow_summary', date_range, farm_id, Date.current].join('/')
      
      Rails.cache.fetch(cache_key, force: force_refresh, expires_in: 1.hour) do
        calculate_cow_summary(date_range, farm_id)
      end
    end
    
    # Production Trends - cached for 30 minutes
    def production_trends_data(days: 30, farm_id: nil, cow_id: nil, force_refresh: false)
      cache_key = ['production_trends', days, farm_id, cow_id, Date.current].join('/')
      
      Rails.cache.fetch(cache_key, force: force_refresh, expires_in: 30.minutes) do
        calculate_production_trends(days, farm_id, cow_id)
      end
    end
    
    # Chart data generation - cached separately
    def chart_data(report_type, data, force_refresh: false)
      cache_key = ['chart_data', report_type, data.hash, Date.current].join('/')
      
      Rails.cache.fetch(cache_key, force: force_refresh, expires_in: 1.hour) do
        case report_type
        when 'farm_summary'
          generate_farm_charts(data)
        when 'cow_summary'
          generate_cow_charts(data)
        when 'production_trends'
          generate_trend_charts(data)
        end
      end
    end
    
    private
    
    # Calculate farm summary with optimized queries
    def calculate_farm_summary
      start_date = 30.days.ago.to_date
      
      # Single optimized query with LEFT JOINS and aggregations
      Farm.left_joins(:production_records, :sales_records, :cows)
        .select(
          'farms.*',
          'COUNT(DISTINCT cows.id) as total_cows',
          'COUNT(DISTINCT CASE WHEN cows.status = \'active\' THEN cows.id END) as active_cows',
          "COALESCE(SUM(CASE WHEN production_records.production_date >= '#{start_date}' THEN production_records.total_production END), 0) as recent_production",
          "COALESCE(AVG(CASE WHEN production_records.production_date >= '#{start_date}' THEN production_records.total_production END), 0) as avg_daily_production",
          "COALESCE(SUM(CASE WHEN sales_records.sale_date >= '#{start_date}' THEN sales_records.milk_sold END), 0) as recent_sales_volume",
          "COALESCE(SUM(CASE WHEN sales_records.sale_date >= '#{start_date}' THEN sales_records.total_sales END), 0) as recent_sales_revenue"
        )
        .group('farms.id')
        .map do |farm|
          {
            farm: farm,
            total_cows: farm.total_cows.to_i,
            active_cows: farm.active_cows.to_i,
            recent_production: farm.recent_production.to_f,
            avg_daily_production: farm.avg_daily_production.to_f,
            recent_sales_volume: farm.recent_sales_volume.to_f,
            recent_sales_revenue: farm.recent_sales_revenue.to_f
          }
        end
    end
    
    # Calculate cow summary with single optimized query
    def calculate_cow_summary(date_range, farm_id)
      start_date = date_range.to_i.days.ago.to_date
      
      # Optimized single query with LEFT JOIN and aggregations
      sql = <<-SQL.squish
        SELECT 
          cows.id,
          cows.name,
          cows.tag_number,
          farms.name as farm_name,
          farms.id as farm_id,
          COALESCE(SUM(pr.total_production), 0) as total_production,
          COALESCE(AVG(pr.total_production), 0) as avg_daily_production,
          COUNT(pr.id) as record_count,
          MAX(pr.total_production) as best_day
        FROM cows
        LEFT JOIN farms ON farms.id = cows.farm_id
        LEFT JOIN production_records pr ON pr.cow_id = cows.id 
          AND pr.production_date BETWEEN ? AND ?
        WHERE cows.status = 'active'
        #{farm_id ? "AND cows.farm_id = ?" : ""}
        GROUP BY cows.id, cows.name, cows.tag_number, farms.name, farms.id
        ORDER BY total_production DESC
        LIMIT 20
      SQL
      
      binds = [start_date, Date.current]
      binds << farm_id if farm_id
      
      ActiveRecord::Base.connection.exec_query(
        ActiveRecord::Base.sanitize_sql_array([sql, *binds])
      ).to_a
    end
    
    # Calculate production trends efficiently
    def calculate_production_trends(days, farm_id, cow_id)
      start_date = days.days.ago.to_date
      
      query = ProductionRecord
        .where(production_date: start_date..Date.current)
        .group(:production_date)
        .order(:production_date)
      
      query = query.where(farm_id: farm_id) if farm_id
      query = query.where(cow_id: cow_id) if cow_id
      
      query.sum(:total_production)
    end
    
    # Generate farm summary charts
    def generate_farm_charts(farm_stats)
      {
        production_chart: {
          labels: farm_stats.map { |stat| stat[:farm].name },
          datasets: [{
            label: "30-Day Total Production (L)",
            data: farm_stats.map { |stat| stat[:recent_production].round(1).to_f },
            backgroundColor: chart_colors,
            borderColor: chart_border_colors,
            borderWidth: 2
          }]
        },
        trend_chart: generate_daily_trend_chart
      }
    end
    
    # Generate cow summary charts
    def generate_cow_charts(cow_data)
      top_10 = cow_data.first(10)
      
      {
        production_chart: {
          labels: top_10.map { |c| "#{c['name']} (#{c['farm_name']})" },
          datasets: [{
            label: "Total Production (L)",
            data: top_10.map { |c| c['total_production'].to_f.round(1) },
            backgroundColor: "rgba(54, 162, 235, 0.8)",
            borderColor: "rgba(54, 162, 235, 1)",
            borderWidth: 2
          }]
        },
        avg_chart: {
          labels: top_10.map { |c| c['name'] },
          datasets: [{
            label: "Average Daily Production (L)",
            data: top_10.map { |c| c['avg_daily_production'].to_f.round(1) },
            backgroundColor: chart_colors,
            borderWidth: 2
          }]
        }
      }
    end
    
    # Generate production trend charts
    def generate_trend_charts(trend_data)
      {
        labels: trend_data.keys.map { |date| date.strftime("%m/%d") },
        datasets: [{
          label: "Daily Production (L)",
          data: trend_data.values.map { |val| val.to_f.round(1) },
          borderColor: "rgba(75, 192, 192, 1)",
          backgroundColor: "rgba(75, 192, 192, 0.2)",
          tension: 0.4,
          fill: true
        }]
      }
    end
    
    # Generate daily trend for farm summary
    def generate_daily_trend_chart
      daily_production = ProductionRecord
        .where(production_date: 30.days.ago..Date.current)
        .group(:production_date)
        .sum(:total_production)
      
      {
        labels: daily_production.keys.map { |date| date.strftime("%m/%d") },
        datasets: [{
          label: "Daily Total Production (L)",
          data: daily_production.values.map { |val| val.round(1).to_f },
          borderColor: "rgba(75, 192, 192, 1)",
          backgroundColor: "rgba(75, 192, 192, 0.2)",
          tension: 0.4,
          fill: true
        }]
      }
    end
    
    # Chart color palettes
    def chart_colors
      [
        "rgba(54, 162, 235, 0.8)",
        "rgba(255, 99, 132, 0.8)",
        "rgba(255, 205, 86, 0.8)",
        "rgba(75, 192, 192, 0.8)",
        "rgba(153, 102, 255, 0.8)",
        "rgba(255, 159, 64, 0.8)",
        "rgba(199, 199, 199, 0.8)",
        "rgba(83, 102, 255, 0.8)",
        "rgba(255, 99, 255, 0.8)",
        "rgba(99, 255, 132, 0.8)"
      ]
    end
    
    def chart_border_colors
      [
        "rgba(54, 162, 235, 1)",
        "rgba(255, 99, 132, 1)",
        "rgba(255, 205, 86, 1)",
        "rgba(75, 192, 192, 1)",
        "rgba(153, 102, 255, 1)",
        "rgba(255, 159, 64, 1)",
        "rgba(199, 199, 199, 1)",
        "rgba(83, 102, 255, 1)",
        "rgba(255, 99, 255, 1)",
        "rgba(99, 255, 132, 1)"
      ]
    end
  end
end
