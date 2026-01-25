#!/usr/bin/env ruby
# Create comprehensive demo data to test all alert categories

require_relative './config/environment'

puts "🚀 Creating comprehensive alerts demo data..."
puts "Current date: #{Date.current}"

# Get the first farm for testing
farm = Farm.first
unless farm
  puts "❌ No farms found. Creating a demo farm..."
  farm = Farm.create!(
    name: "Demo Farm",
    location: "Test Location",
    contact_phone: "123-456-7890",
    owner: "John Doe"
  )
end

puts "📍 Using farm: #{farm.name}"

# Create test cows if needed
if farm.cows.count < 10
  puts "🐄 Creating test cows..."
  (10 - farm.cows.count).times do |i|
    cow = farm.cows.create!(
      name: "TestCow#{farm.cows.count + i + 1}",
      tag_number: "TC#{sprintf('%03d', farm.cows.count + i + 1)}",
      breed: [ "Holstein", "Jersey", "Guernsey" ].sample,
      age: rand(2..8),
      status: "active",
      birth_date: rand(2..8).years.ago
    )
  end
end

cows = farm.cows.active.limit(10)
puts "🐄 Using #{cows.count} cows for demo data"

# Clear existing records to avoid conflicts
puts "🧹 Clearing existing test data..."
HealthRecord.where(cow: cows).destroy_all
VaccinationRecord.where(cow: cows).destroy_all
BreedingRecord.where(cow: cows).destroy_all
ProductionRecord.where(cow: cows, production_date: 30.days.ago..Date.current).destroy_all

puts "\n🔴 Creating CRITICAL HEALTH ALERTS..."

# 1. Critical Health Alerts - Sick animals with high temperature
cow1 = cows[0]
HealthRecord.create!(
  cow: cow1,
  health_status: "sick",
  temperature: 41.5,  # High fever
  recorded_at: 1.hour.ago,
  notes: "High fever, loss of appetite, lethargy",
  recorded_by: "Farm Worker"
)

cow2 = cows[1]
HealthRecord.create!(
  cow: cow2,
  health_status: "injured",
  temperature: 38.8,
  recorded_at: 2.hours.ago,
  notes: "Injured leg, difficulty walking",
  recorded_by: "Veterinarian"
)

cow3 = cows[2]
HealthRecord.create!(
  cow: cow3,
  health_status: "critical",
  temperature: 42.1,  # Very high fever
  recorded_at: 30.minutes.ago,
  notes: "Critical condition, difficulty breathing, requires immediate attention",
  recorded_by: "Emergency Vet"
)

puts "✅ Created 3 critical health alerts"

puts "\n🟠 Creating OVERDUE VACCINATION ALERTS..."

# 2. Overdue Vaccination Alerts
cow4 = cows[3]
VaccinationRecord.create!(
  cow: cow4,
  vaccine_name: "BVD (Bovine Viral Diarrhea)",
  vaccination_date: 13.months.ago,
  next_due_date: 1.month.ago,  # Overdue by 1 month
  administered_by: "Dr. Smith",
  notes: "Annual vaccination overdue"
)

cow5 = cows[4]
VaccinationRecord.create!(
  cow: cow5,
  vaccine_name: "Mastitis Prevention",
  vaccination_date: 8.months.ago,
  next_due_date: 2.weeks.ago,  # Overdue by 2 weeks
  administered_by: "Farm Vet",
  notes: "Bi-annual vaccination overdue"
)

puts "✅ Created 2 overdue vaccination alerts"

puts "\n🟡 Creating DUE VACCINATION ALERTS..."

# 3. Due Vaccination Alerts (within next 2 weeks)
cow6 = cows[5]
VaccinationRecord.create!(
  cow: cow6,
  vaccine_name: "IBR (Infectious Bovine Rhinotracheitis)",
  vaccination_date: 11.months.ago,
  next_due_date: 1.week.from_now,  # Due next week
  administered_by: "Dr. Johnson",
  notes: "Annual vaccination due soon"
)

cow7 = cows[6]
VaccinationRecord.create!(
  cow: cow7,
  vaccine_name: "Leptospirosis",
  vaccination_date: 5.months.ago,
  next_due_date: 3.days.from_now,  # Due in 3 days
  administered_by: "Farm Vet",
  notes: "Bi-annual vaccination due soon"
)

puts "✅ Created 2 due vaccination alerts"

puts "\n🔴 Creating OVERDUE BREEDING ALERTS..."

# 4. Overdue Breeding Alerts
cow8 = cows[7]
BreedingRecord.create!(
  cow: cow8,
  breeding_date: 10.months.ago,
  breeding_method: "artificial_insemination",
  breeding_status: "confirmed",
  expected_due_date: 1.week.ago,  # Overdue by 1 week
  bull_name: "Champion Bull 001",
  veterinarian: "Dr. Brown"
)

puts "✅ Created 1 overdue breeding alert"

puts "\n🔵 Creating DUE BREEDING ALERTS..."

# 5. Due Breeding Alerts (within next 2 weeks)
cow9 = cows[8]
BreedingRecord.create!(
  cow: cow9,
  breeding_date: 8.5.months.ago,
  breeding_method: "artificial_insemination",
  breeding_status: "confirmed",
  expected_due_date: 5.days.from_now,  # Due in 5 days
  bull_name: "Premium Bull 002",
  veterinarian: "Dr. Wilson"
)

puts "✅ Created 1 due breeding alert"

puts "\n🟠 Creating LOW PRODUCTION ALERTS..."

# 6. Low Production Alerts - Create recent production records with low output
cow10 = cows[9]

# Create normal production for comparison
7.days.ago.upto(3.days.ago) do |date|
  ProductionRecord.create!(
    cow: cow10,
    farm: farm,
    production_date: date,
    morning_production: 15.0,
    noon_production: 12.0,
    evening_production: 13.0,
    total_production: 40.0
  )
end

# Create low production for last 2 days
2.days.ago.upto(Date.current) do |date|
  ProductionRecord.create!(
    cow: cow10,
    farm: farm,
    production_date: date,
    morning_production: 8.0,   # Significantly lower
    noon_production: 6.0,
    evening_production: 7.0,
    total_production: 21.0      # 50% drop from normal
  )
end

puts "✅ Created low production scenario for #{cow10.name}"

puts "\n🔵 Creating HEALTH CHECKUP REMINDERS..."

# 7. Health Checkup Reminders - Animals without recent health records
# cow1, cow2, cow3 already have recent health records from critical alerts
# Let's mark some cows as needing checkups (no recent health records)
checkup_cows = [ cow4, cow5, cow6 ]
checkup_cows.each do |cow|
  # Create old health record to show they need recent checkup
  HealthRecord.create!(
    cow: cow,
    health_status: "healthy",
    temperature: 38.5,
    recorded_at: 35.days.ago,  # More than 30 days ago
    notes: "Regular checkup - all normal",
    recorded_by: "Farm Worker"
  )
end

puts "✅ Created health checkup scenarios for 3 cows"

puts "\n📊 DEMO DATA SUMMARY:"
puts "=" * 50

# Health alerts
sick_cows = HealthRecord.joins(:cow)
                        .where(cows: { farm: farm })
                        .where(health_status: [ 'sick', 'injured', 'critical', 'quarantine' ])
                        .where(recorded_at: 24.hours.ago..Time.current)
                        .count

puts "🔴 Critical Health Alerts: #{sick_cows}"

# Vaccination alerts
overdue_vaccinations = VaccinationRecord.joins(:cow)
                                       .where(cows: { farm: farm })
                                       .where("next_due_date < ?", Date.current)
                                       .count

due_vaccinations = VaccinationRecord.joins(:cow)
                                  .where(cows: { farm: farm })
                                  .where(next_due_date: Date.current..2.weeks.from_now)
                                  .count

puts "🔴 Overdue Vaccinations: #{overdue_vaccinations}"
puts "🟡 Due Vaccinations: #{due_vaccinations}"

# Breeding alerts
overdue_births = BreedingRecord.joins(:cow)
                              .where(cows: { farm: farm })
                              .where("expected_due_date < ? AND breeding_status = ?", Date.current, "confirmed")
                              .count

due_births = BreedingRecord.joins(:cow)
                          .where(cows: { farm: farm })
                          .where(expected_due_date: Date.current..2.weeks.from_now)
                          .where(breeding_status: "confirmed")
                          .count

puts "🔴 Overdue Births: #{overdue_births}"
puts "🔵 Due Births: #{due_births}"

# Production alerts
low_production_count = 1  # We created one scenario
puts "🟠 Low Production Alerts: #{low_production_count}"

# Health checkup reminders
checkup_needed = farm.cows.active
                      .left_joins(:health_records)
                      .where(
                        health_records: { id: nil }
                      ).or(
                        farm.cows.active
                            .joins(:health_records)
                            .where(health_records: { recorded_at: ...30.days.ago })
                      ).distinct.count

puts "🔵 Health Checkups Needed: #{checkup_needed}"

puts "\n" + "=" * 50
puts "✅ Demo data creation completed successfully!"
puts "🌐 Visit your dashboard to see the alerts in action"
puts "📱 The alerts should display with proper color coding and priorities"

puts "\n🔍 Quick verification commands:"
puts "- rails console"
puts "- User.first&.farm&.cows&.count"
puts "- HealthRecord.where(health_status: ['sick', 'injured', 'critical']).count"
puts "- VaccinationRecord.where('next_due_date < ?', Date.current).count"
