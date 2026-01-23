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
    @farms = Farm.all
    @total_farms = @farms.count
    @total_cows = Cow.count
    @active_cows = Cow.active.count
    
    # Today's production
    @today_production = ProductionRecord.where(production_date: Date.current).sum(:total_production)
    
    # Yesterday's production for comparison
    @yesterday_production = ProductionRecord.where(production_date: Date.yesterday).sum(:total_production)
    
    # This month's production
    @monthly_production = ProductionRecord.for_month(Date.current.month, Date.current.year).sum(:total_production)
    
    # Recent production records
    @recent_records = ProductionRecord.includes(:cow, :farm).recent.limit(10)
    
    # Farm-wise production today
    @farm_production_today = Farm.all.map do |farm|
      {
        farm: farm,
        production: ProductionRecord.daily_farm_total(farm, Date.current)
      }
    end
    
    # Monthly sales
    @monthly_sales = SalesRecord.for_month(Date.current.month, Date.current.year).sum(:total_sales)
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
end
