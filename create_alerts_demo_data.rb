# Script to create demo data for alerts system demonstration
puts "🚨 Creating Alert Demo Data..."

farm = Farm.first
if farm.nil?
  puts "❌ No farm found. Creating demo farm..."
  farm = Farm.create!(name: "Bama Demo Farm", location: "Kenya", contact_info: "Demo Farm")
end

# Create demo cows if not exist
demo_cows = []
5.times do |i|
  cow = Cow.find_or_create_by(name: "Alert Demo Cow #{i+1}") do |c|
    c.tag_number = "ALERT#{i+1}"
    c.farm = farm
    c.age = rand(24..60)
    c.breed = ['Holstein', 'Jersey', 'Crossbred'].sample
    c.status = 'active'
    c.birth_date = c.age.months.ago
    c.current_weight = rand(400..600)
  end
  demo_cows << cow
end

puts "✅ Created #{demo_cows.count} demo cows"

# 1. Create overdue vaccinations (Critical alerts)
puts "\n📍 Creating overdue vaccination scenarios..."
demo_cows.first(2).each_with_index do |cow, index|
  # Create past vaccination with overdue next date
  VaccinationRecord.find_or_create_by(
    cow: cow,
    vaccine_name: ['BVD (Bovine Viral Diarrhea)', 'Blackleg (Clostridium chauvoei)'][index]
  ) do |v|
    v.vaccination_date = 14.months.ago
    v.next_due_date = (7 + index*3).days.ago # Make them overdue by different amounts
    v.administered_by = "Dr. Demo"
    v.batch_number = "BATCH#{rand(1000..9999)}"
    v.notes = "Demo vaccination for alerts testing"
  end
end

# 2. Create upcoming vaccinations (Warning alerts)
puts "📍 Creating upcoming vaccination scenarios..."
demo_cows[2..3].each_with_index do |cow, index|
  VaccinationRecord.find_or_create_by(
    cow: cow,
    vaccine_name: ['IBR (Infectious Bovine Rhinotracheitis)', 'Leptospirosis'][index]
  ) do |v|
    v.vaccination_date = 11.months.ago
    v.next_due_date = (2 + index*2).days.from_now # Due in next few days
    v.administered_by = "Dr. Demo"
    v.batch_number = "BATCH#{rand(1000..9999)}"
    v.notes = "Demo vaccination for alerts testing"
  end
end

# 3. Create overdue births (Critical alerts)
puts "📍 Creating overdue birth scenarios..."
demo_cows[0].update!(status: 'pregnant')
BreedingRecord.find_or_create_by(cow: demo_cows[0]) do |b|
  b.breeding_date = 10.months.ago
  b.breeding_method = 'artificial_insemination'
  b.breeding_status = 'confirmed'
  b.expected_due_date = 5.days.ago # Overdue
  b.sire_details = "Demo Bull 123"
  b.notes = "Demo breeding for alerts testing"
end

# 4. Create upcoming births (Info alerts)
puts "📍 Creating upcoming birth scenarios..."
demo_cows[1].update!(status: 'pregnant')
BreedingRecord.find_or_create_by(cow: demo_cows[1]) do |b|
  b.breeding_date = 8.months.ago
  b.breeding_method = 'natural_service'
  b.breeding_status = 'confirmed'
  b.expected_due_date = 3.days.from_now # Due soon
  b.sire_details = "Demo Bull 456"
  b.notes = "Demo breeding for alerts testing"
end

# 5. Create health issues (Critical alerts)
puts "📍 Creating health alert scenarios..."
demo_cows[2..3].each_with_index do |cow, index|
  HealthRecord.find_or_create_by(
    cow: cow,
    recorded_at: (1 + index).days.ago
  ) do |h|
    h.health_status = ['sick', 'injured'][index]
    h.temperature = [39.8, 38.2][index] # One high fever, one low
    h.weight = cow.current_weight - rand(10..30)
    h.symptoms = ['High fever, loss of appetite', 'Limping, visible injury'][index]
    h.diagnosis = ['Possible infection', 'Leg injury'][index]
    h.treatment = ['Antibiotics prescribed', 'Rest and monitoring'][index]
    h.veterinarian = "Dr. Demo Health"
    h.notes = "Demo health record for alerts testing"
  end
end

# 6. Create low production scenarios (Warning alerts)
puts "📍 Creating low production alert scenarios..."
demo_cows[3..4].each do |cow|
  # Create recent low production records
  7.times do |day|
    ProductionRecord.find_or_create_by(
      cow: cow,
      farm: farm,
      production_date: day.days.ago.to_date
    ) do |p|
      p.morning_production = rand(3..6) # Low production
      p.evening_production = rand(4..7) # Low production
      p.total_production = p.morning_production + p.evening_production
      p.fat_content = rand(3.2..3.8)
      p.protein_content = rand(2.8..3.4)
      p.notes = "Demo low production for alerts testing"
    end
  end
end

# 7. Create animals needing health checkups (Info alerts)
puts "📍 Creating health checkup reminders..."
demo_cows[4].tap do |cow|
  # Remove any recent health records to trigger checkup reminder
  cow.health_records.where('recorded_at > ?', 35.days.ago).destroy_all
end

puts "\n🎉 Alert Demo Data Creation Complete!"
puts "="*50
puts "Demo Scenarios Created:"
puts "🔴 Critical Alerts:"
puts "   - #{demo_cows.first(2).map(&:name).join(', ')}: Overdue vaccinations"
puts "   - #{demo_cows[0].name}: Overdue birth"
puts "   - #{demo_cows[2..3].map(&:name).join(', ')}: Health issues"
puts ""
puts "🟠 Warning Alerts:"
puts "   - #{demo_cows[2..3].map(&:name).join(', ')}: Upcoming vaccinations"
puts "   - #{demo_cows[3..4].map(&:name).join(', ')}: Low milk production"
puts ""
puts "🔵 Info Alerts:"
puts "   - #{demo_cows[1].name}: Upcoming birth"
puts "   - #{demo_cows[4].name}: Health checkup due"
puts ""
puts "🌡️ Seasonal Alerts:"
puts "   - Heat stress monitoring (if current month is summer)"
puts ""
puts "Navigate to the dashboard to see the alerts in action!"
puts "="*50
