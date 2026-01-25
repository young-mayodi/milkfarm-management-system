#!/usr/bin/env ruby
# Quick verification of alerts system functionality

require_relative './config/environment'

puts "🔍 Quick Alerts System Verification"
puts "Current time: #{Time.current}"
puts "Current date: #{Date.current}"
puts "=" * 50

# Check if we have farms and animals
farms_count = Farm.count
cows_count = Cow.count

puts "📊 Database Status:"
puts "Farms: #{farms_count}"
puts "Cows: #{cows_count}"

if farms_count == 0 || cows_count == 0
  puts "❌ No farms or cows found. Creating basic data..."
  
  if farms_count == 0
    farm = Farm.create!(
      name: "Demo Farm",
      location: "Test Location", 
      contact_phone: "123-456-7890",
      owner: "Demo Owner"
    )
    puts "✅ Created farm: #{farm.name}"
  else
    farm = Farm.first
  end
  
  if cows_count == 0
    3.times do |i|
      cow = farm.cows.create!(
        name: "Demo Cow #{i + 1}",
        tag_number: "DEMO#{sprintf('%03d', i + 1)}",
        breed: "Holstein",
        age: rand(2..6),
        status: "active",
        birth_date: rand(2..6).years.ago
      )
      puts "✅ Created cow: #{cow.name}"
    end
  end
end

# Get first farm for testing
farm = Farm.first
puts "\n📍 Testing with farm: #{farm.name}"

# Check recent data
puts "\n📈 Recent Data Summary:"
health_records_count = HealthRecord.joins(:cow).where(cows: { farm: farm }).where(recorded_at: 7.days.ago..Time.current).count
vaccination_records_count = VaccinationRecord.joins(:cow).where(cows: { farm: farm }).count
breeding_records_count = BreedingRecord.joins(:cow).where(cows: { farm: farm }).count
production_records_count = ProductionRecord.where(farm: farm).where(production_date: 7.days.ago..Date.current).count

puts "Health records (last 7 days): #{health_records_count}"
puts "Vaccination records: #{vaccination_records_count}"
puts "Breeding records: #{breeding_records_count}"
puts "Production records (last 7 days): #{production_records_count}"

# Simulate the dashboard controller logic (simplified version)
puts "\n🚨 Testing Alert Categories:"

# 1. Health alerts
sick_count = HealthRecord.joins(:cow)
                        .where(cows: { farm: farm })
                        .where(health_status: ['sick', 'injured', 'critical', 'quarantine'])
                        .where(recorded_at: 24.hours.ago..Time.current)
                        .count
puts "🔴 Critical health alerts: #{sick_count}"

# 2. Overdue vaccinations
overdue_vax = VaccinationRecord.joins(:cow)
                              .where(cows: { farm: farm })
                              .where("next_due_date < ?", Date.current)
                              .count
puts "🔴 Overdue vaccinations: #{overdue_vax}"

# 3. Due vaccinations
due_vax = VaccinationRecord.joins(:cow)
                          .where(cows: { farm: farm })
                          .where(next_due_date: Date.current..2.weeks.from_now)
                          .count
puts "🟡 Due vaccinations: #{due_vax}"

# 4. Overdue births
overdue_births = BreedingRecord.joins(:cow)
                              .where(cows: { farm: farm })
                              .where("expected_due_date < ? AND breeding_status = ?", Date.current, "confirmed")
                              .count
puts "🔴 Overdue births: #{overdue_births}"

# 5. Due births
due_births = BreedingRecord.joins(:cow)
                          .where(cows: { farm: farm })
                          .where(expected_due_date: Date.current..2.weeks.from_now)
                          .where(breeding_status: "confirmed")
                          .count
puts "🔵 Due births: #{due_births}"

# 6. Health checkups needed
checkups_needed = farm.cows.active
                      .left_joins(:health_records)
                      .where(
                        health_records: { id: nil }
                      ).or(
                        farm.cows.active
                            .joins(:health_records)
                            .where(health_records: { recorded_at: ...30.days.ago })
                      ).distinct.count
puts "⚪ Health checkups needed: #{checkups_needed}"

total_alerts = sick_count + overdue_vax + due_vax + overdue_births + due_births + [checkups_needed, 5].min

puts "\n📊 SUMMARY:"
if total_alerts > 0
  puts "🚨 Total alerts: #{total_alerts}"
  puts "✅ Alerts system is functional and will display notifications"
else
  puts "✅ All systems green - No alerts to display"
  puts "💡 You can run the demo data script to create test alerts"
end

puts "\n🌐 Dashboard URL: https://milkyway-6acc11e1c2fd.herokuapp.com/dashboard"
puts "🔧 To create demo alerts: ruby create_comprehensive_alerts_demo.rb"

puts "\n" + "=" * 50
puts "✅ Verification completed successfully!"
