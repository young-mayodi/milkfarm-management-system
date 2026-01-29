class ReportsController < ApplicationController
  def index
    @report_options = [
      {
        title: "Farm Summary",
        description: "Overview of all farms with production statistics and charts",
        path: farm_summary_reports_path,
        icon: "bi-building"
      },
      {
        title: "Cow Summary",
        description: "Detailed cow production analysis with visual comparisons",
        path: cow_summary_reports_path,
        icon: "bi-list-ul"
      },
      {
        title: "Production Trends",
        description: "Interactive charts showing production trends over time",
        path: production_trends_reports_path,
        icon: "bi-graph-up"
      },
      {
        title: "Production Trends Analysis",
        description: "Comprehensive cow-level production analysis by milking periods (Morning, Noon, Evening, Night)",
        path: production_trends_production_records_path,
        icon: "bi-graph-up-arrow"
      },
      {
        title: "Data Export",
        description: "Export data to CSV format",
        path: export_reports_path,
        icon: "bi-download"
      }
    ]
  end

  def farm_summary
    # PERFORMANCE FIX: Use single optimized query instead of N+1
    @farm_stats = Farm.left_joins(:production_records, :sales_records, :cows)
      .select(
        'farms.*',
        'COUNT(DISTINCT cows.id) as total_cows',
        'COUNT(DISTINCT CASE WHEN cows.status = \'active\' THEN cows.id END) as active_cows',
        'COALESCE(SUM(CASE WHEN production_records.production_date >= ? THEN production_records.total_production END), 0) as recent_production',
        'COALESCE(AVG(CASE WHEN production_records.production_date >= ? THEN production_records.total_production END), 0) as avg_daily_production',
        'COALESCE(SUM(CASE WHEN sales_records.sale_date >= ? THEN sales_records.milk_sold END), 0) as recent_sales_volume',
        'COALESCE(SUM(CASE WHEN sales_records.sale_date >= ? THEN sales_records.total_sales END), 0) as recent_sales_revenue'
      )
      .where('production_records.production_date >= ? OR production_records.production_date IS NULL', 30.days.ago.to_date)
      .where('sales_records.sale_date >= ? OR sales_records.sale_date IS NULL', 30.days.ago.to_date)
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

    # PERFORMANCE FIX: Cache chart data generation
    @farm_chart_data = Rails.cache.fetch(['farm-chart-data', Date.current], expires_in: 1.hour) do
      {
        labels: @farm_stats.map { |stat| stat[:farm].name },
        datasets: [
          {
            label: "30-Day Total Production (L)",
            data: @farm_stats.map { |stat| stat[:recent_production].round(1).to_f },
            backgroundColor: [
              "rgba(54, 162, 235, 0.8)",
              "rgba(255, 99, 132, 0.8)",
              "rgba(255, 205, 86, 0.8)",
              "rgba(75, 192, 192, 0.8)",
              "rgba(153, 102, 255, 0.8)",
              "rgba(255, 159, 64, 0.8)"
            ],
            borderColor: [
              "rgba(54, 162, 235, 1)",
              "rgba(255, 99, 132, 1)",
              "rgba(255, 205, 86, 1)",
              "rgba(75, 192, 192, 1)",
              "rgba(153, 102, 255, 1)",
              "rgba(255, 159, 64, 1)"
            ],
            borderWidth: 2
          }
        ]
      }
    end

    # PERFORMANCE FIX: Cache daily production trend with optimized query
    @trend_chart_data = Rails.cache.fetch(['daily-production-trend', Date.current], expires_in: 1.hour) do
      # Use single optimized query with grouping
      daily_production = ProductionRecord
        .where(production_date: 30.days.ago..Date.current)
        .group(:production_date)
        .sum(:total_production)

      {
        labels: daily_production.keys.map { |date| date.strftime("%m/%d") },
        datasets: [
          {
            label: "Daily Total Production (L)",
            data: daily_production.values.map { |val| val.round(1).to_f },
            borderColor: "rgba(75, 192, 192, 1)",
            backgroundColor: "rgba(75, 192, 192, 0.2)",
            tension: 0.4,
            fill: true
          }
        ]
      }
    end
  end

  def cow_summary
    @date_range = params[:date_range] || "30"
    start_date = @date_range.to_i.days.ago.to_date

    # Load cows without production_records to avoid eager loading issues
    @cows = Cow.includes(:farm)
    @cows = @cows.where(farm_id: params[:farm_id]) if params[:farm_id].present?

    # Get all cows for charts (not paginated)
    @all_cows = @cows.limit(20) # Show top 20 for charts
    @cows = @cows.page(params[:page]).per(20)

    # Pre-fetch production statistics for all cows in one efficient query
    cow_ids = @all_cows.pluck(:id)

    # Use raw SQL for better performance
    production_stats = ProductionRecord.connection.execute(
      "SELECT
         cow_id,
         SUM(total_production) as total_production,
         AVG(total_production) as avg_daily_production,
         COUNT(*) as record_count,
         MAX(total_production) as best_day
       FROM production_records
       WHERE cow_id IN (#{cow_ids.join(',')})
         AND production_date BETWEEN '#{start_date}' AND '#{Date.current}'
       GROUP BY cow_id"
    )

    # Convert results to hash
    @cow_stats = {}
    production_stats.each do |row|
      @cow_stats[row["cow_id"].to_i] = {
        total_production: row["total_production"].to_f,
        avg_daily_production: row["avg_daily_production"].to_f,
        record_count: row["record_count"].to_i,
        best_day: row["best_day"].to_f
      }
    end

    # Initialize stats for cows with no production records
    cow_ids.each do |cow_id|
      unless @cow_stats[cow_id]
        @cow_stats[cow_id] = {
          total_production: 0,
          avg_daily_production: 0,
          record_count: 0,
          best_day: 0
        }
      end
    end

    # Chart data for top producing cows
    top_cows = @all_cows.sort_by { |cow| @cow_stats[cow.id][:total_production] }.reverse.first(10)

    @cow_chart_data = {
      labels: top_cows.map { |cow| "#{cow.name} (#{cow.farm.name})" },
      datasets: [
        {
          label: "#{@date_range}-Day Total Production (L)",
          data: top_cows.map { |cow| @cow_stats[cow.id][:total_production].round(1).to_f },
          backgroundColor: "rgba(54, 162, 235, 0.8)",
          borderColor: "rgba(54, 162, 235, 1)",
          borderWidth: 2
        }
      ]
    }

    # Average daily production comparison
    @avg_chart_data = {
      labels: top_cows.map { |cow| cow.name },
      datasets: [
        {
          label: "Average Daily Production (L)",
          data: top_cows.map { |cow| @cow_stats[cow.id][:avg_daily_production].round(1).to_f },
          backgroundColor: [
            "rgba(255, 99, 132, 0.8)",
            "rgba(54, 162, 235, 0.8)",
            "rgba(255, 205, 86, 0.8)",
            "rgba(75, 192, 192, 0.8)",
            "rgba(153, 102, 255, 0.8)",
            "rgba(255, 159, 64, 0.8)",
            "rgba(199, 199, 199, 0.8)",
            "rgba(83, 102, 255, 0.8)",
            "rgba(255, 99, 255, 0.8)",
            "rgba(99, 255, 132, 0.8)"
          ],
          borderWidth: 2
        }
      ]
    }

    # Least performing cows analysis
    least_performing_cows = @all_cows.sort_by { |cow| @cow_stats[cow.id][:total_production] }.first(10)

    @least_cow_chart_data = {
      labels: least_performing_cows.map { |cow| "#{cow.name} (#{cow.farm.name})" },
      datasets: [
        {
          label: "#{@date_range}-Day Total Production (L)",
          data: least_performing_cows.map { |cow| @cow_stats[cow.id][:total_production].round(1).to_f },
          backgroundColor: "rgba(220, 53, 69, 0.8)",
          borderColor: "rgba(220, 53, 69, 1)",
          borderWidth: 2
        }
      ]
    }

    @farms = Farm.all
  end

  def production_trends
    @farm = Farm.find(params[:farm_id]) if params[:farm_id].present?
    @cow = Cow.find(params[:cow_id]) if params[:cow_id].present?
    @days = params[:days]&.to_i || 30

    start_date = @days.days.ago.to_date

    if @cow
      # Individual cow production trend
      daily_production = @cow.production_records
        .where(production_date: start_date..Date.current)
        .group(:production_date)
        .sum(:total_production)

      @chart_data = {
        labels: daily_production.keys.map { |date| date.strftime("%m/%d") },
        datasets: [
          {
            label: "#{@cow.name} Daily Production (L)",
            data: daily_production.values.map { |val| val.round(1).to_f },
            borderColor: "rgba(54, 162, 235, 1)",
            backgroundColor: "rgba(54, 162, 235, 0.2)",
            tension: 0.4,
            fill: true
          }
        ]
      }

      @title = "#{@cow.name} Production Trend (#{@days} days)"
    elsif @farm
      # Farm production trend by cow
      cows = @farm.cows.active.limit(5) # Show top 5 active cows
      colors = [
        "rgba(255, 99, 132, 1)",
        "rgba(54, 162, 235, 1)",
        "rgba(255, 205, 86, 1)",
        "rgba(75, 192, 192, 1)",
        "rgba(153, 102, 255, 1)"
      ]

      datasets = cows.map.with_index do |cow, index|
        daily_production = cow.production_records
          .where(production_date: start_date..Date.current)
          .group(:production_date)
          .sum(:total_production)

        {
          label: cow.name,
          data: daily_production.values.map { |val| val.round(1).to_f },
          borderColor: colors[index],
          backgroundColor: colors[index].gsub("1)", "0.2)"),
          tension: 0.4,
          fill: false
        }
      end

      # Get all dates in range for consistent labels
      all_dates = (start_date..Date.current).to_a

      @chart_data = {
        labels: all_dates.map { |date| date.strftime("%m/%d") },
        datasets: datasets
      }

      @title = "#{@farm.name} Production Trends by Cow (#{@days} days)"
    else
      # All farms comparison
      farms = Farm.includes(:production_records).limit(5)
      colors = [
        "rgba(255, 99, 132, 1)",
        "rgba(54, 162, 235, 1)",
        "rgba(255, 205, 86, 1)",
        "rgba(75, 192, 192, 1)",
        "rgba(153, 102, 255, 1)"
      ]

      datasets = farms.map.with_index do |farm, index|
        daily_production = farm.production_records
          .where(production_date: start_date..Date.current)
          .group(:production_date)
          .sum(:total_production)

        {
          label: farm.name,
          data: daily_production.values.map { |val| val.round(1).to_f },
          borderColor: colors[index],
          backgroundColor: colors[index].gsub("1)", "0.2)"),
          tension: 0.4,
          fill: false
        }
      end

      all_dates = (start_date..Date.current).to_a

      @chart_data = {
        labels: all_dates.map { |date| date.strftime("%m/%d") },
        datasets: datasets
      }

      @title = "All Farms Production Trends (#{@days} days)"
    end

    @farms = Farm.all
    @cows = @farm ? @farm.cows.active : Cow.includes(:farm).active.limit(20)
  end

  def export
    @export_options = [
      { name: "Production Records", format: "CSV", endpoint: production_records_path(format: :csv) },
      { name: "Sales Records", format: "CSV", endpoint: sales_records_path(format: :csv) },
      { name: "Cow Information", format: "CSV", endpoint: cows_path(format: :csv) },
      { name: "Farm Summary", format: "CSV", endpoint: farms_path(format: :csv) }
    ]
  end
end
