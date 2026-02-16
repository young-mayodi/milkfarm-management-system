# frozen_string_literal: true

# Service for managing and generating farm alerts
# Monitors various metrics and creates notifications for farm owners
class AlertEngineService < ApplicationService
  attr_reader :farm

  # Alert thresholds
  LOW_PRODUCTION_THRESHOLD = 0.7 # 70% of average
  HIGH_PRODUCTION_THRESHOLD = 1.3 # 130% of average
  MISSED_MILKING_HOURS = 12
  HEALTH_CHECK_OVERDUE_DAYS = 90
  VACCINE_DUE_DAYS = 7
  BREEDING_DUE_DAYS = 285 # ~9 months + buffer

  def initialize(farm:)
    @farm = farm
    @alerts = []
  end

  def call
    log_info("Running alert checks for farm ##{farm.id}")

    check_low_production
    check_missed_milkings
    check_health_overdue
    check_vaccinations_due
    check_breeding_due
    check_inactive_cows
    check_inventory_low

    log_info("Generated #{@alerts.size} alerts")
    @alerts
  end

  # Get critical alerts only
  def critical_alerts
    call.select { |alert| alert[:severity] == "critical" }
  end

  # Get alerts grouped by type
  def grouped_alerts
    call.group_by { |alert| alert[:type] }
  end

  private

  def add_alert(type:, severity:, title:, message:, cow: nil, count: 0, data: {})
    @alerts << {
      type: type,
      severity: severity, # info, warning, critical
      title: title,
      message: message,
      cow_id: cow&.id,
      cow_name: cow&.name,
      count: count,
      data: data,
      created_at: Time.current
    }
  end

  def check_low_production
    farm.cows.active.each do |cow|
      avg_production = cow.avg_production
      next if avg_production.nil? || avg_production.zero?

      latest_production = cow.production_records.order(production_date: :desc).first
      next unless latest_production

      total_production = latest_production.morning_production + latest_production.night_production

      if total_production < (avg_production * LOW_PRODUCTION_THRESHOLD)
        add_alert(
          type: "low_production",
          severity: "warning",
          title: "Low Production Alert",
          message: "#{cow.display_name} produced only #{total_production}L (avg: #{avg_production.round(2)}L)",
          cow: cow,
          data: { current: total_production, average: avg_production }
        )
      end
    end
  end

  def check_missed_milkings
    cutoff_time = MISSED_MILKING_HOURS.hours.ago

    farm.cows.active.each do |cow|
      last_record = cow.production_records.order(production_date: :desc).first
      next unless last_record

      last_milking = last_record.production_date.to_datetime

      if last_milking < cutoff_time
        add_alert(
          type: "missed_milking",
          severity: "critical",
          title: "Missed Milking",
          message: "#{cow.display_name} hasn't been milked in #{((Time.current - last_milking) / 1.hour).round} hours",
          cow: cow,
          data: { last_milking: last_milking, hours_ago: ((Time.current - last_milking) / 1.hour).round }
        )
      end
    end
  end

  def check_health_overdue
    overdue_cows = farm.cows.active.includes(:health_records).select do |cow|
      last_checkup = cow.health_records.order(checkup_date: :desc).first&.checkup_date
      last_checkup.nil? || last_checkup < HEALTH_CHECK_OVERDUE_DAYS.days.ago.to_date
    end

    if overdue_cows.any?
      add_alert(
        type: "health_overdue",
        severity: "warning",
        title: "Health Checkups Overdue",
        message: "#{overdue_cows.size} cow(s) need health checkups (over #{HEALTH_CHECK_OVERDUE_DAYS} days)",
        count: overdue_cows.size,
        data: { cow_ids: overdue_cows.map(&:id) }
      )
    end
  end

  def check_vaccinations_due
    upcoming_vaccines = farm.vaccination_records
      .where("next_due_date BETWEEN ? AND ?", Date.current, VACCINE_DUE_DAYS.days.from_now.to_date)
      .includes(:cow)

    if upcoming_vaccines.any?
      add_alert(
        type: "vaccination_due",
        severity: "info",
        title: "Vaccinations Due Soon",
        message: "#{upcoming_vaccines.size} vaccination(s) due in the next #{VACCINE_DUE_DAYS} days",
        count: upcoming_vaccines.size,
        data: { record_ids: upcoming_vaccines.map(&:id) }
      )
    end

    # Critical: overdue vaccinations
    overdue_vaccines = farm.vaccination_records
      .where("next_due_date < ?", Date.current)
      .includes(:cow)

    if overdue_vaccines.any?
      add_alert(
        type: "vaccination_overdue",
        severity: "critical",
        title: "Vaccinations Overdue",
        message: "#{overdue_vaccines.size} vaccination(s) are overdue!",
        count: overdue_vaccines.size,
        data: { record_ids: overdue_vaccines.map(&:id) }
      )
    end
  end

  def check_breeding_due
    pregnant_cows = farm.breeding_records
      .where(pregnancy_status: "pregnant")
      .where("expected_due_date BETWEEN ? AND ?", Date.current, 7.days.from_now.to_date)
      .includes(:cow)

    if pregnant_cows.any?
      add_alert(
        type: "calving_due",
        severity: "warning",
        title: "Calving Expected Soon",
        message: "#{pregnant_cows.size} cow(s) expected to calve in the next 7 days",
        count: pregnant_cows.size,
        data: { record_ids: pregnant_cows.map(&:id) }
      )
    end
  end

  def check_inactive_cows
    inactive_days = 30
    inactive_cows = farm.cows.where(status: "active")
      .left_joins(:production_records)
      .group("cows.id")
      .having("MAX(production_records.production_date) < ? OR MAX(production_records.production_date) IS NULL",
              inactive_days.days.ago.to_date)

    count = inactive_cows.count

    if count > 0
      add_alert(
        type: "inactive_cows",
        severity: "warning",
        title: "Inactive Cows Detected",
        message: "#{count} active cow(s) have no production records in #{inactive_days} days",
        count: count,
        data: { cow_ids: inactive_cows.pluck(:id) }
      )
    end
  end

  def check_inventory_low
    # This is a placeholder - implement when inventory system is added
    # Check feed levels, medicine stock, etc.
  end
end
