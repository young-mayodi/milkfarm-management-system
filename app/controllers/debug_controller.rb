class DebugController < ApplicationController
  def index
    # Create simple test chart data
    @test_chart_data = {
      labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
      datasets: [
        {
          label: 'Test Data',
          data: [10, 20, 15, 30, 25],
          borderColor: 'rgb(75, 192, 192)',
          backgroundColor: 'rgba(75, 192, 192, 0.2)',
          tension: 0.4
        }
      ]
    }

    # Get the actual dashboard chart data for comparison
    farms = Farm.all
    
    # Weekly production trend - simplified
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
  end
end
