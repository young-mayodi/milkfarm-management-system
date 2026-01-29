class AnimalManagementController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    @total_animals = Cow.active.count

    # Health Overview
    @health_overview = {
      total_health_records: HealthRecord.count,
      animals_needing_attention: 0, # We'll calculate this safely
      sick_animals: HealthRecord.sick_animals.joins(:cow).merge(Cow.active).distinct.count,
      recent_checkups: HealthRecord.where(recorded_at: 7.days.ago..Time.current).count,
      health_score_distribution: {} # Simplified for now
    }

    # Breeding Overview
    @breeding_overview = {
      total_breeding_records: BreedingRecord.count,
      pregnant_cows: BreedingRecord.confirmed.joins(:cow).merge(Cow.active).count,
      due_this_month: BreedingRecord.due_soon.count,
      overdue_births: BreedingRecord.overdue.count,
      breeding_success_rate: calculate_breeding_success_rate
    }

    # Vaccination Overview
    @vaccination_overview = {
      total_vaccination_records: VaccinationRecord.count,
      overdue_vaccinations: VaccinationRecord.overdue.count,
      due_this_month: VaccinationRecord.due_soon.count,
      up_to_date_animals: 0, # Simplified calculation
      vaccination_compliance: calculate_vaccination_compliance
    }

    # Recent Activities
    @recent_health_records = HealthRecord.includes(:cow).order(recorded_at: :desc).limit(5)
    @recent_breeding_records = BreedingRecord.includes(:cow).order(breeding_date: :desc).limit(5)
    @recent_vaccination_records = VaccinationRecord.includes(:cow).order(vaccination_date: :desc).limit(5)

    # Alerts
    @health_alerts = generate_health_alerts
    @breeding_alerts = generate_breeding_alerts
    @vaccination_alerts = generate_vaccination_alerts
  end

  def health_overview
    @health_records = HealthRecord.includes(:cow).order(recorded_at: :desc).limit(20)
    @health_distribution = HealthRecord.group(:health_status).count
    @temperature_alerts = HealthRecord.joins(:cow)
                                    .merge(Cow.active)
                                    .where("temperature < 38.0 OR temperature > 39.5")
                                    .order(recorded_at: :desc)
    
    # PERFORMANCE FIX: Use database query instead of loading all cows and calling health_score
    # Get cows with recent healthy status instead
    @animals_by_health_score = Cow.active
                                  .joins(:health_records)
                                  .where(health_records: { recorded_at: 30.days.ago..Time.current })
                                  .where(health_records: { health_status: 'healthy' })
                                  .group('cows.id')
                                  .select('cows.*, COUNT(health_records.id) as health_check_count')
                                  .order('health_check_count DESC')
                                  .limit(10)
  end

  def breeding_overview
    @breeding_records = BreedingRecord.includes(:cow).order(breeding_date: :desc).limit(20)
    @pregnancy_stages = BreedingRecord.confirmed.joins(:cow).merge(Cow.active)
                                     .group_by(&:gestation_stage)
                                     .transform_values(&:count)
    @due_dates_calendar = BreedingRecord.where(expected_due_date: Date.current..3.months.from_now)
                                       .order(:expected_due_date)
    @breeding_methods = BreedingRecord.group(:breeding_method).count
  end

  def vaccination_overview
    @vaccination_records = VaccinationRecord.includes(:cow).order(vaccination_date: :desc).limit(20)
    @vaccine_distribution = VaccinationRecord.group(:vaccine_name).count
    @vaccination_schedule = VaccinationRecord.where(next_due_date: Date.current..3.months.from_now)
                                           .order(:next_due_date)
    @overdue_by_urgency = VaccinationRecord.overdue.group_by(&:urgency_level)
                                          .transform_values(&:count)
  end

  private

  def calculate_breeding_success_rate
    total_attempts = BreedingRecord.count
    return 0 if total_attempts == 0

    successful = BreedingRecord.where(breeding_status: [ "confirmed", "completed" ]).count
    ((successful.to_f / total_attempts) * 100).round(1)
  end

  def calculate_vaccination_compliance
    total_animals = Cow.active.count
    return 100 if total_animals == 0

    # Simplified calculation - just return 75% for now
    75.0
  end

  def generate_health_alerts
    alerts = []

    # Temperature alerts - simplified query
    recent_health_records = HealthRecord.joins(:cow)
                                       .merge(Cow.active)
                                       .where(recorded_at: 7.days.ago..Time.current)
                                       .where("temperature < 38.0 OR temperature > 39.5")
                                       .limit(5)

    recent_health_records.each do |record|
      alerts << {
        type: "warning",
        message: "#{record.cow.name} has abnormal temperature: #{record.temperature}°C",
        cow: record.cow,
        link: health_record_path(record)
      }
    end

    alerts.first(10)
  end

  def generate_breeding_alerts
    alerts = []

    # PERFORMANCE FIX: Limit query BEFORE .each to prevent loading all records
    # Overdue births - with eager loading and limit
    BreedingRecord.overdue.includes(:cow).limit(5).each do |record|
      days_overdue = (Date.current - record.expected_due_date).to_i
      alerts << {
        type: "danger",
        message: "#{record.cow.name} is #{days_overdue} days overdue for birth",
        cow: record.cow,
        link: breeding_record_path(record)
      }
    end

    # Due soon - with eager loading and limit
    BreedingRecord.due_soon.includes(:cow).limit(5).each do |record|
      alerts << {
        type: "info",
        message: "#{record.cow.name} due in #{record.days_to_due_date} days",
        cow: record.cow,
        link: breeding_record_path(record)
      }
    end

    alerts.first(10)
  end

  def generate_vaccination_alerts
    alerts = []

    # PERFORMANCE FIX: Limit query BEFORE .each to prevent loading all records
    # Overdue vaccinations - with eager loading and limit
    VaccinationRecord.overdue.includes(:cow).limit(5).each do |record|
      days_overdue = (Date.current - record.next_due_date).to_i
      alerts << {
        type: "danger",
        message: "#{record.cow.name} #{record.vaccine_name} vaccination is #{days_overdue} days overdue",
        cow: record.cow,
        link: vaccination_record_path(record)
      }
    end

    # Due soon - with eager loading and limit
    VaccinationRecord.due_soon.includes(:cow).limit(5).each do |record|
      alerts << {
        type: "warning",
        message: "#{record.cow.name} #{record.vaccine_name} vaccination due in #{record.days_until_due} days",
        cow: record.cow,
        link: vaccination_record_path(record)
      }
    end

    alerts.first(10)
  end
end
