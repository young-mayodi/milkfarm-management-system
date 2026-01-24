class AlertsController < ApplicationController
  before_action :authenticate_user!

  def index
    @critical_alerts = generate_critical_alerts
    @warning_alerts = generate_warning_alerts
    @info_alerts = generate_info_alerts

    respond_to do |format|
      format.html
      format.json { render json: {
        critical: @critical_alerts,
        warning: @warning_alerts,
        info: @info_alerts
      }}
    end
  end

  def mark_as_read
    session[:read_alerts] ||= []
    session[:read_alerts] << params[:alert_id]
    head :ok
  end

  def dashboard_summary
    alerts = {
      health_alerts: health_critical_count,
      breeding_alerts: breeding_critical_count,
      vaccination_alerts: vaccination_critical_count,
      production_alerts: production_critical_count
    }

    render json: alerts
  end

  private

  def generate_critical_alerts
    alerts = []

    # Health Critical Alerts
    sick_cows = Cow.joins(:health_records)
                  .where(health_records: { health_status: "sick", recorded_at: 7.days.ago..Time.current })
                  .distinct

    sick_cows.each do |cow|
      recent_record = cow.health_records.where(health_status: "sick").order(recorded_at: :desc).first
      alerts << {
        id: "health_critical_#{cow.id}",
        type: "critical",
        category: "health",
        title: "Sick Animal Requires Attention",
        message: "#{cow.tag_number} has been sick for #{(Time.current - recent_record.recorded_at).to_i / 1.day} days",
        action_url: health_record_path(recent_record),
        cow_id: cow.id,
        urgency: sick_days_urgency(recent_record.recorded_at),
        created_at: recent_record.recorded_at
      }
    end

    # High Temperature Alerts
    fever_records = HealthRecord.where("temperature > ? AND recorded_at > ?", 39.5, 24.hours.ago)
    fever_records.each do |record|
      alerts << {
        id: "fever_critical_#{record.id}",
        type: "critical",
        category: "health",
        title: "High Fever Detected",
        message: "#{record.cow.tag_number} temperature: #{record.temperature}°C",
        action_url: health_record_path(record),
        cow_id: record.cow_id,
        urgency: "immediate",
        created_at: record.recorded_at
      }
    end

    # Overdue Vaccinations
    overdue_vaccinations = VaccinationRecord.includes(:cow).where("next_due_date < ?", Date.current)
    overdue_vaccinations.each do |vaccination|
      days_overdue = (Date.current - vaccination.next_due_date).to_i
      alerts << {
        id: "vaccination_overdue_#{vaccination.id}",
        type: "critical",
        category: "vaccination",
        title: "Vaccination Overdue",
        message: "#{vaccination.cow.tag_number} #{vaccination.vaccine_name} overdue by #{days_overdue} days",
        action_url: vaccination_record_path(vaccination),
        cow_id: vaccination.cow_id,
        urgency: days_overdue > 30 ? "immediate" : "high",
        created_at: vaccination.next_due_date
      }
    end

    # Production Drop Alerts
    recent_production = ProductionRecord.where(production_date: 3.days.ago..Time.current)
                                      .group(:cow_id)
                                      .average(:total_production)

    recent_production.each do |cow_id, avg_amount|
      cow = Cow.find(cow_id)
      historical_avg = cow.production_records
                          .where(production_date: 30.days.ago..7.days.ago)
                          .average(:total_production) || 0

      if historical_avg > 0 && avg_amount < historical_avg * 0.7 # 30% drop
        alerts << {
          id: "production_drop_#{cow_id}",
          type: "critical",
          category: "production",
          title: "Significant Production Drop",
          message: "#{cow.tag_number} production dropped #{((1 - avg_amount/historical_avg) * 100).round}%",
          action_url: cow_path(cow),
          cow_id: cow_id,
          urgency: "high",
          created_at: Time.current
        }
      end
    end

    alerts.sort_by { |a| [ urgency_priority(a[:urgency]), a[:created_at] ] }.reverse
  end

  def generate_warning_alerts
    alerts = []

    # Breeding Alerts
    due_soon = BreedingRecord.includes(:cow).where(expected_due_date: Date.current..7.days.from_now)
    due_soon.each do |record|
      days_until = (record.expected_due_date - Date.current).to_i
      alerts << {
        id: "calving_soon_#{record.id}",
        type: "warning",
        category: "breeding",
        title: "Calving Expected Soon",
        message: "#{record.cow.tag_number} expected to calve in #{days_until} days",
        action_url: breeding_record_path(record),
        cow_id: record.cow_id,
        created_at: record.expected_due_date
      }
    end

    # Low Weight Alerts
    underweight_cows = HealthRecord.joins(:cow)
                                  .where("weight < ? AND recorded_at > ?", 350, 7.days.ago)
                                  .where(cows: { status: "active" })

    underweight_cows.each do |record|
      alerts << {
        id: "underweight_#{record.id}",
        type: "warning",
        category: "health",
        title: "Animal Underweight",
        message: "#{record.cow.tag_number} weight: #{record.weight}kg (below normal)",
        action_url: health_record_path(record),
        cow_id: record.cow_id,
        created_at: record.recorded_at
      }
    end

    # Upcoming Vaccinations
    upcoming_vaccinations = VaccinationRecord.includes(:cow).where(next_due_date: Date.current..7.days.from_now)
    upcoming_vaccinations.each do |vaccination|
      days_until = (vaccination.next_due_date - Date.current).to_i
      alerts << {
        id: "vaccination_upcoming_#{vaccination.id}",
        type: "warning",
        category: "vaccination",
        title: "Vaccination Due Soon",
        message: "#{vaccination.cow.tag_number} #{vaccination.vaccine_name} due in #{days_until} days",
        action_url: vaccination_record_path(vaccination),
        cow_id: vaccination.cow_id,
        created_at: vaccination.next_due_date
      }
    end

    alerts.sort_by { |a| a[:created_at] }.reverse
  end

  def generate_info_alerts
    alerts = []

    # Heat Detection
    in_heat = HealthRecord.includes(:cow).where(health_status: "in_heat", recorded_at: 3.days.ago..Time.current)
    in_heat.each do |record|
      alerts << {
        id: "heat_detected_#{record.id}",
        type: "info",
        category: "breeding",
        title: "Heat Cycle Detected",
        message: "#{record.cow.tag_number} showing signs of heat - breeding opportunity",
        action_url: new_breeding_record_path(cow_id: record.cow_id),
        cow_id: record.cow_id,
        created_at: record.recorded_at
      }
    end

    # High Production Achievement
    high_producers = ProductionRecord.where(production_date: 1.week.ago..Time.current)
                                   .where("total_production > ?", 35)

    high_producers.group_by(&:cow_id).each do |cow_id, records|
      cow = Cow.find(cow_id)
      avg_production = records.sum(&:total_production) / records.count
      alerts << {
        id: "high_production_#{cow_id}",
        type: "info",
        category: "production",
        title: "High Production Achievement",
        message: "#{cow.tag_number} averaging #{avg_production.round(1)}L/day this week",
        action_url: cow_path(cow),
        cow_id: cow_id,
        created_at: records.max_by(&:production_date).production_date
      }
    end

    alerts.sort_by { |a| a[:created_at] }.reverse.first(20) # Limit info alerts
  end

  def health_critical_count
    Cow.joins(:health_records)
       .where(health_records: { health_status: "sick", recorded_at: 7.days.ago..Time.current })
       .distinct.count +
    HealthRecord.where("temperature > ? AND recorded_at > ?", 39.5, 24.hours.ago).count
  end

  def breeding_critical_count
    BreedingRecord.where(expected_due_date: Date.current..2.days.from_now).count
  end

  def vaccination_critical_count
    VaccinationRecord.where("next_due_date < ?", Date.current).count
  end

  def production_critical_count
    # Count cows with significant production drops
    count = 0
    recent_production = ProductionRecord.where(production_date: 3.days.ago..Time.current)
                                      .group(:cow_id)
                                      .average(:total_production)

    recent_production.each do |cow_id, avg_amount|
      cow = Cow.find(cow_id)
      historical_avg = cow.production_records
                          .where(production_date: 30.days.ago..7.days.ago)
                          .average(:total_production) || 0

      count += 1 if historical_avg > 0 && avg_amount < historical_avg * 0.7
    end

    count
  end

  def sick_days_urgency(sick_date)
    days = (Time.current - sick_date).to_i / 1.day
    return "immediate" if days >= 7
    return "high" if days >= 3
    "medium"
  end

  def urgency_priority(urgency)
    case urgency
    when "immediate" then 3
    when "high" then 2
    when "medium" then 1
    else 0
    end
  end
end
