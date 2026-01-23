class DashboardController < ApplicationController
  def index
    load_dashboard_data
    prepare_chart_data
  end

  def chart_data
    load_dashboard_data
    prepare_chart_data
    
    render json: {
      weekly_trend: @weekly_trend_chart,
      farm_comparison: @farm_comparison_chart,
      production_vs_sales: @production_vs_sales_chart,
      updated_at: Time.current.iso8601
    }
  end

  private

  def load_dashboard_data
    # Cache expensive queries for 5 minutes
    @farms = Rails.cache.fetch("dashboard_farms", expires_in: 5.minutes) do
      current_user.admin? ? Farm.all : [current_user.farm]
    end
    
    cache_key = "dashboard_data_#{@farms.map(&:id).join('_')}"
    cached_data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      farms_to_query = @farms
      
      # Calculate metrics for each farm
      farms_data = farms_to_query.map do |farm|
        calculate_farm_metrics(farm)
      end
      
      # Aggregate totals
      {
        farms_data: farms_data,
        total_cows: farms_data.sum { |f| f[:total_cows] },
        total_production: farms_data.sum { |f| f[:total_production] },
        total_sales: farms_data.sum { |f| f[:total_sales] },
        avg_production: farms_data.sum { |f| f[:avg_production] } / farms_data.size.to_f
      }
    end
    
    @farms_data = cached_data[:farms_data]
    @total_cows = cached_data[:total_cows] 
    @total_production = cached_data[:total_production]
    @total_sales = cached_data[:total_sales]
    @avg_production = cached_data[:avg_production]
    @total_farms = @farms.count
    @active_cows = Cow.active.count
    
    # Cache daily metrics for 10 minutes
    daily_cache_key = "dashboard_daily_#{Date.current}"
    daily_data = Rails.cache.fetch(daily_cache_key, expires_in: 10.minutes) do
      {
        today_production: ProductionRecord.where(production_date: Date.current).sum(:total_production),
        yesterday_production: ProductionRecord.where(production_date: Date.yesterday).sum(:total_production),
        monthly_production: ProductionRecord.for_month(Date.current.month, Date.current.year).sum(:total_production),
        monthly_sales: SalesRecord.for_month(Date.current.month, Date.current.year).sum(:total_sales)
      }
    end
    
    @today_production = daily_data[:today_production]
    @yesterday_production = daily_data[:yesterday_production] 
    @monthly_production = daily_data[:monthly_production]
    @monthly_sales = daily_data[:monthly_sales]
    @monthly_revenue = @monthly_sales * 1.0
    
    # Recent records - cache for 2 minutes
    @recent_records = Rails.cache.fetch("dashboard_recent_records", expires_in: 2.minutes) do
      ProductionRecord.includes(:cow, :farm).recent.limit(10).to_a
    end
    
    # Farm production today - cache for 10 minutes  
    @farm_production_today = Rails.cache.fetch("farm_production_today_#{Date.current}", expires_in: 10.minutes) do
      @farms.map do |farm|
        {
          farm: farm,
          production: ProductionRecord.daily_farm_total(farm, Date.current)
        }
      end
    end
  end

  def prepare_chart_data
    # Simple chart data for the main chart
    last_7_days = (7.days.ago.to_date..Date.current).to_a
    daily_data = last_7_days.map do |date|
      production = ProductionRecord.where(production_date: date).sum(:total_production)
      [date.strftime('%m/%d'), production.round(1).to_f]
    end
    
    @chart_data = {
      labels: daily_data.map(&:first),
      data: daily_data.map(&:last)
    }
    
    # 1. Weekly production trend - simplified approach
    recent_records = ProductionRecord
      .where(production_date: 6.weeks.ago..Date.current)
      .order(:production_date)
    
    weekly_data = {}
    recent_records.each do |record|
      week_start = record.production_date.beginning_of_week
      weekly_data[week_start] = (weekly_data[week_start] || 0) + record.total_production
    end
    
    @weekly_trend_chart = {
      labels: weekly_data.keys.map { |date| "Week of #{date.strftime('%m/%d')}" },
      datasets: [
        {
          label: 'Weekly Total Production (L)',
          data: weekly_data.values.map { |val| val.round(1).to_f },
          borderColor: 'rgba(75, 192, 192, 1)',
          backgroundColor: 'rgba(75, 192, 192, 0.2)',
          tension: 0.4,
          fill: true
        }
      ]
    }
    
    # 2. Farm production comparison (current month)
    farm_comparison = @farms.map do |farm|
      production = farm.production_records
        .where(production_date: Date.current.beginning_of_month..Date.current)
        .sum(:total_production)
      [farm.name, production.round(1).to_f]
    end
    
    @farm_comparison_chart = {
      labels: farm_comparison.map(&:first),
      datasets: [
        {
          label: 'Monthly Production (L)',
          data: farm_comparison.map { |farm_data| farm_data.last.to_f },
          backgroundColor: [
            'rgba(255, 99, 132, 0.8)',
            'rgba(54, 162, 235, 0.8)',
            'rgba(255, 205, 86, 0.8)',
            'rgba(75, 192, 192, 0.8)',
            'rgba(153, 102, 255, 0.8)',
            'rgba(255, 159, 64, 0.8)'
          ],
          borderWidth: 2
        }
      ]
    }
    
    # 3. Production vs Sales comparison (last 7 days)
    last_7_days = (7.days.ago.to_date..Date.current).to_a
    daily_comparison = last_7_days.map do |date|
      production = ProductionRecord.where(production_date: date).sum(:total_production)
      sales = SalesRecord.where(sale_date: date).sum(:milk_sold)
      {
        date: date.strftime('%m/%d'),
        production: production.round(1).to_f,
        sales: sales.round(1).to_f
      }
    end
    
    @production_vs_sales_chart = {
      labels: daily_comparison.map { |data| data[:date] },
      datasets: [
        {
          label: 'Production (L)',
          data: daily_comparison.map { |data| data[:production].to_f },
          borderColor: 'rgba(54, 162, 235, 1)',
          backgroundColor: 'rgba(54, 162, 235, 0.2)',
          tension: 0.4
        },
        {
          label: 'Sales (L)',
          data: daily_comparison.map { |data| data[:sales].to_f },
          borderColor: 'rgba(255, 99, 132, 1)',
          backgroundColor: 'rgba(255, 99, 132, 0.2)',
          tension: 0.4
        }
      ]
    }
  end
  
  def calculate_farm_metrics(farm)
    {
      farm: farm,
      total_cows: farm.cows.count,
      total_production: ProductionRecord.where(cow: farm.cows).sum(:total_production),
      total_sales: SalesRecord.where(farm: farm).sum(:total_sales),
      avg_production: ProductionRecord.where(cow: farm.cows).average(:total_production) || 0
    }
  end
end
