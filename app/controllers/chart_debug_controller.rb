class ChartDebugController < ApplicationController
  def index
    # Test data queries
    @total_production_records = ProductionRecord.count
    @total_sales_records = SalesRecord.count
    @farms = Farm.all
    
    # Test weekly trend data
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
          data: weekly_data.values.map { |val| val.round(1) },
          borderColor: 'rgba(75, 192, 192, 1)',
          backgroundColor: 'rgba(75, 192, 192, 0.2)',
          tension: 0.4,
          fill: true
        }
      ]
    }
    
    # Test farm comparison data
    farm_comparison = @farms.map do |farm|
      production = farm.production_records
        .where(production_date: Date.current.beginning_of_month..Date.current)
        .sum(:total_production)
      [farm.name, production.round(1)]
    end
    
    @farm_comparison_chart = {
      labels: farm_comparison.map(&:first),
      datasets: [
        {
          label: 'Monthly Production (L)',
          data: farm_comparison.map(&:last),
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
    
    # Test production vs sales data
    last_7_days = (7.days.ago.to_date..Date.current).to_a
    daily_comparison = last_7_days.map do |date|
      production = ProductionRecord.where(production_date: date).sum(:total_production)
      sales = SalesRecord.where(sale_date: date).sum(:milk_sold)
      {
        date: date.strftime('%m/%d'),
        production: production.round(1),
        sales: sales.round(1)
      }
    end
    
    @production_vs_sales_chart = {
      labels: daily_comparison.map { |data| data[:date] },
      datasets: [
        {
          label: 'Production (L)',
          data: daily_comparison.map { |data| data[:production] },
          borderColor: 'rgba(54, 162, 235, 1)',
          backgroundColor: 'rgba(54, 162, 235, 0.2)',
          tension: 0.4
        },
        {
          label: 'Sales (L)',
          data: daily_comparison.map { |data| data[:sales] },
          borderColor: 'rgba(255, 99, 132, 1)',
          backgroundColor: 'rgba(255, 99, 132, 0.2)',
          tension: 0.4
        }
      ]
    }
  end
end
