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
    # Simple data loading without complex caching
    @farms = current_user.farm_owner? ? Farm.all : [ current_user.farm ]
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

    # Recent active cows with high production
    @recent_active_cows = Cow.where(status: "active")
                             .joins(:production_records)
                             .where(production_records: { production_date: 1.week.ago..Date.current })
                             .group("cows.id")
                             .select("cows.*, AVG(production_records.total_production) as avg_production")
                             .limit(5)
                             .order("avg_production DESC")

    # Farm-wise production today
    @farm_production_today = @farms.map do |farm|
      {
        farm: farm,
        production: ProductionRecord.daily_farm_total(farm, Date.current)
      }
    end

    # Monthly sales
    @monthly_sales = SalesRecord.for_month(Date.current.month, Date.current.year).sum(:total_sales)

    # Monthly revenue calculation
    @monthly_revenue = @monthly_sales * 1.0 # Assuming total sales is the revenue

    # Add vaccination and breeding notifications
    load_notifications_data

    # Enhanced Analytics Data
    load_enhanced_analytics
  end

  def load_enhanced_analytics
    # Weekly trend analysis
    @weekly_trends = ProductionRecord.weekly_trend_analysis(weeks_back: 8)

    # Monthly trend analysis
    @monthly_trends = ProductionRecord.monthly_trend_analysis(months_back: 6)

    # Predictive analytics
    @production_predictions = ProductionRecord.predictive_analysis

    # Profit/Loss analysis for each farm
    @farm_profit_analysis = @farms.map do |farm|
      {
        farm: farm,
        current_month: SalesRecord.profit_loss_analysis(farm, Date.current.beginning_of_month..Date.current),
        last_month: SalesRecord.profit_loss_analysis(farm, 1.month.ago.beginning_of_month..1.month.ago.end_of_month)
      }
    end

    # Overall profit trend
    @profit_trends = @farms.first ? SalesRecord.monthly_profit_trend(@farms.first, months_back: 6) : {}

    # Cost breakdown
    @cost_breakdown = @farms.first ? SalesRecord.cost_breakdown_analysis(@farms.first) : {}
  end

  def prepare_chart_data
    # Simple chart data for the main chart
    last_7_days = (7.days.ago.to_date..Date.current).to_a
    daily_data = last_7_days.map do |date|
      production = ProductionRecord.where(production_date: date).sum(:total_production)
      [ date.strftime("%m/%d"), production.round(1).to_f ]
    end

    @chart_data = {
      labels: daily_data.map(&:first),
      data: daily_data.map(&:last)
    }

    # 1. Enhanced Weekly production trend with predictions
    @weekly_trend_chart = prepare_weekly_trend_chart

    # 2. Farm production comparison (current month)
    @farm_comparison_chart = prepare_farm_comparison_chart

    # 3. Production vs Sales comparison (last 7 days)
    @production_vs_sales_chart = prepare_production_vs_sales_chart

    # 4. NEW: Monthly profit/loss trend
    @profit_loss_chart = prepare_profit_loss_chart

    # 5. NEW: Cost breakdown chart
    @cost_breakdown_chart = prepare_cost_breakdown_chart

    # 6. NEW: Predictive production chart
    @prediction_chart = prepare_prediction_chart
  end

  private

  def prepare_weekly_trend_chart
    # Use the weekly trends data from analytics
    sorted_weeks = @weekly_trends.keys.sort

    {
      labels: sorted_weeks.map { |date| "Week #{date.strftime('%m/%d')}" },
      datasets: [
        {
          label: "Weekly Production (L)",
          data: sorted_weeks.map { |date| @weekly_trends[date][:production].round(1) },
          borderColor: "rgba(75, 192, 192, 1)",
          backgroundColor: "rgba(75, 192, 192, 0.2)",
          tension: 0.4,
          fill: true
        },
        {
          label: "Daily Average",
          data: sorted_weeks.map { |date| @weekly_trends[date][:average_daily].round(1) },
          borderColor: "rgba(255, 159, 64, 1)",
          backgroundColor: "rgba(255, 159, 64, 0.2)",
          tension: 0.4,
          borderDash: [ 5, 5 ]
        }
      ]
    }
  end

  def prepare_farm_comparison_chart
    farm_comparison = @farms.map do |farm|
      production = farm.production_records
        .where(production_date: Date.current.beginning_of_month..Date.current)
        .sum(:total_production)
      [ farm.name, production.round(1).to_f ]
    end

    {
      labels: farm_comparison.map(&:first),
      datasets: [
        {
          label: "Monthly Production (L)",
          data: farm_comparison.map { |farm_data| farm_data.last.to_f },
          backgroundColor: [
            "rgba(255, 99, 132, 0.8)",
            "rgba(54, 162, 235, 0.8)",
            "rgba(255, 205, 86, 0.8)",
            "rgba(75, 192, 192, 0.8)",
            "rgba(153, 102, 255, 0.8)",
            "rgba(255, 159, 64, 0.8)"
          ],
          borderWidth: 2
        }
      ]
    }
  end

  def prepare_production_vs_sales_chart
    last_7_days = (7.days.ago.to_date..Date.current).to_a
    daily_comparison = last_7_days.map do |date|
      production = ProductionRecord.where(production_date: date).sum(:total_production)
      sales = SalesRecord.where(sale_date: date).sum(:milk_sold)
      {
        date: date.strftime("%m/%d"),
        production: production.round(1).to_f,
        sales: sales.round(1).to_f
      }
    end

    {
      labels: daily_comparison.map { |data| data[:date] },
      datasets: [
        {
          label: "Production (L)",
          data: daily_comparison.map { |data| data[:production].to_f },
          borderColor: "rgba(54, 162, 235, 1)",
          backgroundColor: "rgba(54, 162, 235, 0.2)",
          tension: 0.4
        },
        {
          label: "Sales (L)",
          data: daily_comparison.map { |data| data[:sales].to_f },
          borderColor: "rgba(255, 99, 132, 1)",
          backgroundColor: "rgba(255, 99, 132, 0.2)",
          tension: 0.4
        }
      ]
    }
  end

  def prepare_profit_loss_chart
    return {} unless @profit_trends.any?

    sorted_months = @profit_trends.keys.sort

    {
      labels: sorted_months.map { |date| date.strftime("%b %Y") },
      datasets: [
        {
          label: "Revenue (KES)",
          data: sorted_months.map { |date| @profit_trends[date][:total_revenue] },
          borderColor: "rgba(75, 192, 192, 1)",
          backgroundColor: "rgba(75, 192, 192, 0.2)",
          yAxisID: "y"
        },
        {
          label: "Costs (KES)",
          data: sorted_months.map { |date| @profit_trends[date][:total_costs] },
          borderColor: "rgba(255, 99, 132, 1)",
          backgroundColor: "rgba(255, 99, 132, 0.2)",
          yAxisID: "y"
        },
        {
          label: "Profit Margin (%)",
          data: sorted_months.map { |date| @profit_trends[date][:profit_margin] },
          borderColor: "rgba(153, 102, 255, 1)",
          backgroundColor: "rgba(153, 102, 255, 0.2)",
          type: "line",
          yAxisID: "y1"
        }
      ]
    }
  end

  def prepare_cost_breakdown_chart
    return {} unless @cost_breakdown.any?

    {
      labels: [ "Feed", "Labor", "Veterinary", "Maintenance" ],
      datasets: [
        {
          data: [
            @cost_breakdown[:feed_costs],
            @cost_breakdown[:labor_costs],
            @cost_breakdown[:veterinary_costs],
            @cost_breakdown[:maintenance_costs]
          ],
          backgroundColor: [
            "rgba(255, 99, 132, 0.8)",
            "rgba(54, 162, 235, 0.8)",
            "rgba(255, 205, 86, 0.8)",
            "rgba(75, 192, 192, 0.8)"
          ],
          borderWidth: 2
        }
      ]
    }
  end

  def prepare_prediction_chart
    return {} unless @production_predictions.any?

    # Combine historical weekly data with predictions
    historical_weeks = @weekly_trends.keys.sort.last(4)
    historical_data = historical_weeks.map { |date| @weekly_trends[date][:production] }

    prediction_weeks = @production_predictions[:predictions].map { |p| p[:week] }
    prediction_data = @production_predictions[:predictions].map { |p| p[:predicted_production] }

    all_weeks = historical_weeks + prediction_weeks
    all_labels = all_weeks.map { |date| date.strftime("%m/%d") }

    # Create datasets with historical and predicted data
    historical_dataset = historical_data + [ nil ] * prediction_data.length
    prediction_dataset = [ nil ] * historical_data.length + prediction_data

    {
      labels: all_labels,
      datasets: [
        {
          label: "Historical Production",
          data: historical_dataset,
          borderColor: "rgba(75, 192, 192, 1)",
          backgroundColor: "rgba(75, 192, 192, 0.2)",
          tension: 0.4
        },
        {
          label: "Predicted Production",
          data: prediction_dataset,
          borderColor: "rgba(255, 159, 64, 1)",
          backgroundColor: "rgba(255, 159, 64, 0.2)",
          tension: 0.4,
          borderDash: [ 10, 5 ]
        }
      ]
    }
  end

  def load_notifications_data
    # Overdue vaccinations
    @overdue_vaccinations = VaccinationRecord.joins(:cow)
                                            .where("next_due_date < ?", Date.current)
                                            .where(cows: { status: "active" })
                                            .includes(:cow)
                                            .limit(10)

    # Vaccinations due this week
    @due_vaccinations = VaccinationRecord.joins(:cow)
                                        .where(next_due_date: Date.current..7.days.from_now)
                                        .where(cows: { status: "active" })
                                        .includes(:cow)
                                        .limit(10)

    # Overdue breeding cycles (pregnant cows past due date)
    @overdue_births = BreedingRecord.joins(:cow)
                                   .where("expected_due_date < ?", Date.current)
                                   .where(breeding_status: "confirmed")
                                   .where(cows: { status: [ "active", "pregnant" ] })
                                   .includes(:cow)
                                   .limit(10)

    # Breeding cycles due this week
    @due_births = BreedingRecord.joins(:cow)
                               .where(expected_due_date: Date.current..7.days.from_now)
                               .where(breeding_status: "confirmed")
                               .where(cows: { status: [ "active", "pregnant" ] })
                               .includes(:cow)
                               .limit(10)

    # Enhanced alert system - upcoming events
    @system_alerts = generate_comprehensive_alerts

    # Count totals for quick display
    @overdue_vaccinations_count = @overdue_vaccinations.count
    @due_vaccinations_count = @due_vaccinations.count
    @overdue_births_count = @overdue_births.count
    @due_births_count = @due_births.count
  end

  def generate_comprehensive_alerts
    alerts = []

    # Critical Health Alerts (Red)
    sick_animals = HealthRecord.joins(:cow)
                              .where(health_status: ['sick', 'critical', 'injured'])
                              .where(recorded_at: 7.days.ago..Time.current)
                              .includes(:cow)
                              .limit(5)

    sick_animals.each do |record|
      alerts << {
        type: 'danger',
        category: 'Health',
        title: "#{record.cow.name} requires attention",
        message: "Status: #{record.health_status.humanize}#{record.temperature ? " (#{record.temperature}°C)" : ''}",
        date: record.recorded_at,
        priority: 'critical',
        icon: 'heart-pulse',
        link: health_record_path(record),
        cow: record.cow
      }
    end

    # Overdue Vaccinations (Red)
    @overdue_vaccinations.each do |vaccination|
      days_overdue = (Date.current - vaccination.next_due_date).to_i
      alerts << {
        type: 'danger',
        category: 'Vaccination',
        title: "#{vaccination.cow.name} - Overdue vaccination",
        message: "#{vaccination.vaccine_name} (#{days_overdue} days overdue)",
        date: vaccination.next_due_date,
        priority: 'critical',
        icon: 'shield-exclamation',
        link: vaccination_records_path,
        cow: vaccination.cow
      }
    end

    # Due Vaccinations (Warning - Orange)
    @due_vaccinations.each do |vaccination|
      days_until_due = (vaccination.next_due_date - Date.current).to_i
      alerts << {
        type: 'warning',
        category: 'Vaccination',
        title: "#{vaccination.cow.name} - Vaccination due",
        message: "#{vaccination.vaccine_name} (due in #{days_until_due} days)",
        date: vaccination.next_due_date,
        priority: 'high',
        icon: 'shield-check',
        link: vaccination_records_path,
        cow: vaccination.cow
      }
    end

    # Overdue Births (Red)
    @overdue_births.each do |breeding|
      days_overdue = (Date.current - breeding.expected_due_date).to_i
      alerts << {
        type: 'danger',
        category: 'Breeding',
        title: "#{breeding.cow.name} - Birth overdue",
        message: "Expected due date was #{breeding.expected_due_date.strftime('%b %d')} (#{days_overdue} days ago)",
        date: breeding.expected_due_date,
        priority: 'critical',
        icon: 'heart-exclamation',
        link: breeding_records_path,
        cow: breeding.cow
      }
    end

    # Due Births (Info - Blue)
    @due_births.each do |breeding|
      days_until_due = (breeding.expected_due_date - Date.current).to_i
      alerts << {
        type: 'info',
        category: 'Breeding',
        title: "#{breeding.cow.name} - Birth expected",
        message: "Due date: #{breeding.expected_due_date.strftime('%b %d')} (in #{days_until_due} days)",
        date: breeding.expected_due_date,
        priority: 'medium',
        icon: 'heart-fill',
        link: breeding_records_path,
        cow: breeding.cow
      }
    end

    # Low Milk Production Alerts (Warning)
    low_producers = ProductionRecord.joins(:cow)
                                   .where(production_date: 7.days.ago..Date.current)
                                   .where(cows: { status: 'active' })
                                   .group(:cow_id)
                                   .having('AVG(total_production) < ?', 15) # Less than 15L average
                                   .includes(:cow)
                                   .limit(3)

    low_producers.each do |record|
      avg_production = ProductionRecord.where(cow: record.cow, production_date: 7.days.ago..Date.current)
                                      .average(:total_production)&.round(1) || 0
      alerts << {
        type: 'warning',
        category: 'Production',
        title: "#{record.cow.name} - Low production",
        message: "Average: #{avg_production}L/day (below 15L threshold)",
        date: Date.current,
        priority: 'medium',
        icon: 'droplet-half',
        link: cow_path(record.cow),
        cow: record.cow
      }
    end

    # Upcoming Health Checkups (monthly reminders)
    animals_due_checkup = Cow.active.includes(:health_records)
                             .select do |cow|
                               last_checkup = cow.health_records.order(recorded_at: :desc).first
                               !last_checkup || last_checkup.recorded_at < 30.days.ago
                             end
                             .first(5)

    animals_due_checkup.each do |cow|
      last_checkup = cow.health_records.order(recorded_at: :desc).first
      days_since = last_checkup ? (Date.current - last_checkup.recorded_at.to_date).to_i : 99
      
      alerts << {
        type: 'info',
        category: 'Health',
        title: "#{cow.name} - Health checkup due",
        message: last_checkup ? "Last checkup #{days_since} days ago" : "No previous health records",
        date: Date.current,
        priority: 'low',
        icon: 'clipboard-heart',
        link: new_health_record_path(cow_id: cow.id),
        cow: cow
      }
    end

    # Weather/Seasonal Alerts (if applicable)
    if Date.current.month.in?([6, 7, 8]) # Summer months
      alerts << {
        type: 'warning',
        category: 'Weather',
        title: 'Heat stress monitoring',
        message: 'Monitor animals for heat stress during peak summer',
        date: Date.current,
        priority: 'medium',
        icon: 'thermometer-high',
        link: health_records_path,
        cow: nil
      }
    end

    # Sort alerts by priority and date
    alerts.sort_by do |alert|
      priority_order = { 'critical' => 1, 'high' => 2, 'medium' => 3, 'low' => 4 }
      [priority_order[alert[:priority]], alert[:date]]
    end
  end
end
