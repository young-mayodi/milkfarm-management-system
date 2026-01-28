# filepath: /Users/youngmayodi/farm-bar/milk_production_system/test_production_trends_performance.rb
# Load Rails environment
require_relative 'config/environment'
require 'benchmark'

puts "========================================================"
puts "PRODUCTION TRENDS PERFORMANCE VERIFICATION"
puts "========================================================"

# Setup Test Data
puts "\n1. Setting up test context..."
# Create a dedicated test farm to avoid polluting production data significantly or issues with existing data
if Farm.respond_to?(:owner_name)
  farm = Farm.find_by(name: "Performance Test Farm") || Farm.create!(name: "Performance Test Farm", owner_name: "Test Owner", contact_phone: "0712345678", owner: "Test Owner")
else
  # Fallback for old schema without owner_name
  farm = Farm.find_by(name: "Performance Test Farm") || Farm.create!(name: "Performance Test Farm", contact_phone: "0712345678", owner: "Test Owner")
end
puts "   Using Farm: #{farm.name}"

# Ensure we have enough cows
cow_count = farm.cows.count
if cow_count < 50
  puts "   Generating specialized test cows..."
  (50 - cow_count).times do |i|
    Cow.create!(
      farm: farm, 
      name: "PerfCow #{SecureRandom.hex(2)}", 
      tag_number: "P#{SecureRandom.hex(3).upcase}",
      breed: "Holstein",
      status: "active",
      age: 3 # Fixed validation error
    )
  end
end
puts "   Total Cows: #{farm.cows.count}"

# Ensure we have enough records for the last 30 days
start_date = 30.days.ago.to_date
end_date = Date.current
date_range = start_date..end_date

puts "   Checking records for range: #{start_date} to #{end_date}"

# Quick check if we have data
existing_count = ProductionRecord.where(farm: farm, production_date: date_range).count
total_days = (end_date - start_date).to_i + 1
expected_count = farm.cows.count * total_days

if existing_count < (expected_count * 0.5)
  puts "   Generating sample production records (this might take a moment)..."
  records_to_insert = []
  
  farm.cows.each do |cow|
    date_range.each do |date|
      # Skip if exists
      next if ProductionRecord.exists?(cow: cow, production_date: date)
      
      morning = rand(5.0..12.0).round(1)
      noon = rand(4.0..10.0).round(1)
      evening = rand(4.0..10.0).round(1)
      night = rand(0.0..5.0).round(1)
      
      records_to_insert << {
        cow_id: cow.id,
        farm_id: farm.id,
        production_date: date,
        morning_production: morning,
        noon_production: noon,
        evening_production: evening,
        night_production: night,
        total_production: (morning + noon + evening + night).round(1),
        created_at: Time.current,
        updated_at: Time.current
      }
    end
  end
  
  if records_to_insert.any?
    ProductionRecord.insert_all(records_to_insert)
    puts "   Inserted #{records_to_insert.count} test records."
  end
else
  puts "   Sufficient data exists (#{existing_count} records)."
end

# Initialize Controller
controller = ProductionRecordsController.new

puts "\n2. Running Performance Test..."
puts "   Executing generate_detailed_trends_data via send..."

result = nil
time = Benchmark.realtime do
  # Using send because it's a private method
  result = controller.send(:generate_detailed_trends_data, date_range, farm)
end

puts "\n3. Performance Results:"
puts "   -------------------------------------------------"
puts "   Calculation Time: #{time.round(4)} seconds"
puts "   Status: #{time < 1.0 ? '✅ PASSED (Under 1s)' : '⚠️ WARNING (Over 1s)'}"
puts "   -------------------------------------------------"

puts "\n4. Data Integrity Check:"
if result[:error]
  puts "   ❌ ERROR: #{result[:summary][:message]}"
else
  summary = result[:summary]
  puts "   ✅ Success! Data structure returned."
  puts "   - Total Records: #{summary[:total_records]}"
  puts "   - Total Milk: #{summary[:totals][:grand_total]}"
  
  # Verify specific keys that were causing issues in view
  missing_keys = []
  [:cow_totals, :daily_data, :daily_totals_summary].each do |key|
    missing_keys << key unless result.key?(key)
  end
  
  if missing_keys.empty?
    puts "   ✅ All required view keys present."
  else
    puts "   ❌ MISSING KEYS: #{missing_keys.join(', ')}" 
  end
  
  # Verify cow_totals structure
  if result[:cow_totals]&.any?
    puts "   ✅ cow_totals has data."
  else
    puts "   ⚠️ cow_totals is empty."
  end
end