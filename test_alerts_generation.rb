#!/usr/bin/env ruby
# Test the alerts generation system

require_relative './config/environment'

# Simulate the dashboard controller logic
class AlertsTester
  def initialize(farm = nil)
    @farm = farm || Farm.first
  end

  def generate_comprehensive_alerts
    return [] unless @farm

    alerts = []

    # 1. Critical Health Alerts
    sick_animals = HealthRecord.joins(:cow)
                               .where(cows: { farm: @farm })
                               .where(health_status: [ 'sick', 'injured', 'critical', 'quarantine' ])
                               .where(recorded_at: 24.hours.ago..Time.current)
                               .includes(:cow)

    sick_animals.each do |health_record|
      alerts << {
        title: "#{health_record.cow.name} requires immediate attention",
        message: "Status: #{health_record.health_status.humanize}#{health_record.temperature ? " | Temp: #{health_record.temperature}°C" : ""}",
        priority: 'critical',
        category: 'health',
        link: "/cows/#{health_record.cow.id}",
        created_at: health_record.recorded_at
      }
    end

    # 2. Overdue Vaccinations (Critical)
    overdue_vaccinations = VaccinationRecord.joins(:cow)
                                           .where(cows: { farm: @farm })
                                           .where("next_due_date < ?", Date.current)
                                           .includes(:cow)

    overdue_vaccinations.each do |vaccination|
      days_overdue = (Date.current - vaccination.next_due_date).to_i
      alerts << {
        title: "#{vaccination.cow.name} - Overdue Vaccination",
        message: "#{vaccination.vaccine_name} | #{days_overdue} days overdue",
        priority: 'critical',
        category: 'vaccination',
        link: "/cows/#{vaccination.cow.id}",
        created_at: Time.current
      }
    end

    # 3. Due Vaccinations (Warning)
    due_vaccinations = VaccinationRecord.joins(:cow)
                                       .where(cows: { farm: @farm })
                                       .where(next_due_date: Date.current..2.weeks.from_now)
                                       .includes(:cow)

    due_vaccinations.each do |vaccination|
      days_until_due = (vaccination.next_due_date - Date.current).to_i
      alerts << {
        title: "#{vaccination.cow.name} - Vaccination Due Soon",
        message: "#{vaccination.vaccine_name} | Due in #{days_until_due} days",
        priority: 'high',
        category: 'vaccination',
        link: "/cows/#{vaccination.cow.id}",
        created_at: Time.current
      }
    end

    # 4. Overdue Births (Critical)
    overdue_births = BreedingRecord.joins(:cow)
                                  .where(cows: { farm: @farm })
                                  .where("expected_due_date < ? AND breeding_status = ?", Date.current, "confirmed")
                                  .includes(:cow)

    overdue_births.each do |breeding|
      days_overdue = (Date.current - breeding.expected_due_date).to_i
      alerts << {
        title: "#{breeding.cow.name} - Birth Overdue",
        message: "Expected birth #{days_overdue} days ago",
        priority: 'critical',
        category: 'breeding',
        link: "/cows/#{breeding.cow.id}",
        created_at: Time.current
      }
    end

    # 5. Due Births (Info)
    due_births = BreedingRecord.joins(:cow)
                              .where(cows: { farm: @farm })
                              .where(expected_due_date: Date.current..2.weeks.from_now)
                              .where(breeding_status: "confirmed")
                              .includes(:cow)

    due_births.each do |breeding|
      days_until_due = (breeding.expected_due_date - Date.current).to_i
      alerts << {
        title: "#{breeding.cow.name} - Birth Expected Soon",
        message: "Expected in #{days_until_due} days",
        priority: 'medium',
        category: 'breeding',
        link: "/cows/#{breeding.cow.id}",
        created_at: Time.current
      }
    end

    # 6. Low Milk Production (Warning)
    production_alerts = check_low_production
    alerts.concat(production_alerts)

    # 7. Health Checkup Reminders
    cows_needing_checkup = @farm.cows.active
                                 .left_joins(:health_records)
                                 .where(
                                   health_records: { id: nil }
                                 ).or(
                                   @farm.cows.active
                                       .joins(:health_records)
                                       .where(health_records: { recorded_at: ...30.days.ago })
                                 ).distinct.limit(5)

    cows_needing_checkup.each do |cow|
      last_checkup = cow.health_records.order(:recorded_at).last
      days_since = last_checkup ? (Date.current - last_checkup.recorded_at.to_date).to_i : 999

      alerts << {
        title: "#{cow.name} - Health Checkup Needed",
        message: last_checkup ? "Last checkup #{days_since} days ago" : "No recent health records",
        priority: 'low',
        category: 'health',
        link: "/cows/#{cow.id}",
        created_at: Time.current
      }
    end

    # Sort by priority and creation time
    priority_order = { 'critical' => 1, 'high' => 2, 'medium' => 3, 'low' => 4 }
    alerts.sort_by { |alert| [ priority_order[alert[:priority]], alert[:created_at] ] }
  end

  private

  def check_low_production
    alerts = []

    # Get cows with recent production records
    recent_producers = @farm.cows.active
                            .joins(:production_records)
                            .where(production_records: { production_date: 7.days.ago..Date.current })
                            .distinct

    recent_producers.each do |cow|
      recent_avg = cow.production_records
                      .where(production_date: 3.days.ago..Date.current)
                      .average(:total_production)&.to_f || 0

      baseline_avg = cow.production_records
                        .where(production_date: 10.days.ago..4.days.ago)
                        .average(:total_production)&.to_f || 0

      if recent_avg > 0 && baseline_avg > 0 && recent_avg < (baseline_avg * 0.7)
        percentage_drop = ((baseline_avg - recent_avg) / baseline_avg * 100).round(1)

        alerts << {
          title: "#{cow.name} - Low Milk Production",
          message: "Production dropped #{percentage_drop}% (#{recent_avg.round(1)}L vs #{baseline_avg.round(1)}L avg)",
          priority: 'high',
          category: 'production',
          link: "/cows/#{cow.id}",
          created_at: Time.current
        }
      end
    end

    alerts
  end
end

puts "🧪 Testing Alerts Generation System"
puts "=" * 50

farm = Farm.first
if farm
  puts "📍 Testing with farm: #{farm.name}"

  tester = AlertsTester.new(farm)
  alerts = tester.generate_comprehensive_alerts

  puts "\n📊 ALERTS SUMMARY:"
  puts "Total alerts generated: #{alerts.count}"

  if alerts.any?
    # Group by priority
    by_priority = alerts.group_by { |alert| alert[:priority] }

    puts "\nBy Priority:"
    %w[critical high medium low].each do |priority|
      count = by_priority[priority]&.count || 0
      next if count == 0

      emoji = case priority
      when 'critical' then '🔴'
      when 'high' then '🟠'
      when 'medium' then '🔵'
      when 'low' then '⚪'
      end

      puts "#{emoji} #{priority.capitalize}: #{count}"
    end

    puts "\n📋 DETAILED ALERTS:"
    alerts.each_with_index do |alert, index|
      priority_emoji = case alert[:priority]
      when 'critical' then '🔴'
      when 'high' then '🟠'
      when 'medium' then '🔵'
      when 'low' then '⚪'
      end

      puts "#{index + 1}. #{priority_emoji} [#{alert[:category].upcase}] #{alert[:title]}"
      puts "   #{alert[:message]}"
      puts "   Link: #{alert[:link]}"
      puts ""
    end
  else
    puts "✅ No alerts generated - All systems green!"
  end

  puts "\n🔍 Raw Data Check:"
  puts "Sick animals (last 24h): #{HealthRecord.joins(:cow).where(cows: { farm: farm }).where(health_status: [ 'sick', 'injured', 'critical', 'quarantine' ]).where(recorded_at: 24.hours.ago..Time.current).count}"
  puts "Overdue vaccinations: #{VaccinationRecord.joins(:cow).where(cows: { farm: farm }).where('next_due_date < ?', Date.current).count}"
  puts "Due vaccinations: #{VaccinationRecord.joins(:cow).where(cows: { farm: farm }).where(next_due_date: Date.current..2.weeks.from_now).count}"
  puts "Overdue births: #{BreedingRecord.joins(:cow).where(cows: { farm: farm }).where('expected_due_date < ? AND breeding_status = ?', Date.current, 'confirmed').count}"
  puts "Due births: #{BreedingRecord.joins(:cow).where(cows: { farm: farm }).where(expected_due_date: Date.current..2.weeks.from_now).where(breeding_status: 'confirmed').count}"

else
  puts "❌ No farm found in database!"
end

puts "\n" + "=" * 50
puts "✅ Alerts testing completed!"
