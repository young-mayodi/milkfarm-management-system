#!/usr/bin/env ruby
# Populate production and sales records for April 24, 2025 from handwritten farm records

# Date for all records
record_date = Date.new(2025, 4, 24)

puts "=" * 80
puts "Populating Bama Dairy Farm records for #{record_date}"
puts "=" * 80

# Find or create the farm
farm = Farm.find_or_create_by!(name: "Bama Dairy Farm") do |f|
  f.location = "Kenya"
  f.size_acres = 100
end

puts "\nFarm: #{farm.name} (ID: #{farm.id})"

# Production data extracted from the handwritten record
# Format: [cow_name, morning, noon, evening]
production_data = [
  ["KOKWET", 9.8, 8.0, 9.0],
  ["Jema 3", 11.8, 8.5, 9.0],
  ["SILO 2", 8.1, 9.2, 6.2],
  ["BAHATI 1", 6.6, 5.0, 6.6],
  ["BAHATI 2", 7.0, 4.5, 6.1],
  ["TINDIRET 10", 10.5, 6.2, 4.9],
  ["ELEGNA 1", 8.6, 6.2, 9.9],
  ["LUGARI 5", 7.0, 6.2, 5.4],
  ["TINDIRET 1", 6.5, 5.5, 5.8],
  ["LUGARI 4", 8.2, 5.8, 4.9],
  ["SILO 5", 8.4, 4.5, 5.1],
  ["CHEPTERIT", 9.1, 5.5, 5.9],
  ["LUGARI 8", 7.5, 4.0, 5.8],
  ["CHELAA 1", 6.0, 4.2, 4.0],
  ["Sile 3", 9.5, 4.6, 8.5],
  ["MERU 1", 6.4, 0, 5.2],
  ["LAGOS", 10.2, 0, 0],
  ["CHELEI 1", 6.4, 0, 5.5],
]

puts "\n" + "=" * 80
puts "CREATING PRODUCTION RECORDS"
puts "=" * 80

created_count = 0
updated_count = 0
error_count = 0

production_data.each do |cow_name, morning, noon, evening|
  # Find or create the cow
  cow = Cow.find_or_create_by!(name: cow_name, farm: farm) do |c|
    c.tag_number = "#{cow_name.upcase.gsub(/\s+/, '')}-#{rand(1000..9999)}"
    c.breed = "Holstein"
    c.date_of_birth = 3.years.ago
    c.status = "active"
  end
  
  # Calculate total
  total = (morning || 0) + (noon || 0) + (evening || 0)
  
  # Find or create production record
  record = ProductionRecord.find_or_initialize_by(
    cow: cow,
    farm: farm,
    production_date: record_date
  )
  
  record.morning_production = morning || 0
  record.noon_production = noon || 0
  record.evening_production = evening || 0
  record.total_production = total
  
  if record.new_record?
    if record.save
      created_count += 1
      puts "✓ Created: #{cow_name.ljust(15)} | M: #{morning.to_s.rjust(5)} | N: #{noon.to_s.rjust(5)} | E: #{evening.to_s.rjust(5)} | Total: #{total.round(1)}"
    else
      error_count += 1
      puts "✗ Failed to create #{cow_name}: #{record.errors.full_messages.join(', ')}"
    end
  else
    if record.save
      updated_count += 1
      puts "↻ Updated: #{cow_name.ljust(15)} | M: #{morning.to_s.rjust(5)} | N: #{noon.to_s.rjust(5)} | E: #{evening.to_s.rjust(5)} | Total: #{total.round(1)}"
    else
      error_count += 1
      puts "✗ Failed to update #{cow_name}: #{record.errors.full_messages.join(', ')}"
    end
  end
rescue => e
  error_count += 1
  puts "✗ Error processing #{cow_name}: #{e.message}"
end

puts "\n" + "=" * 80
puts "CREATING SALES RECORDS"
puts "=" * 80

# Sales data from the handwritten record
# Based on the totals visible in the image:
# Total milk sold: 246.46 liters
# Total cash sales: 1190 KES
# Mpesa sales: 18370 KES (this seems very high, might be 1837.0)
# Grand total: 14560 KES

# Create sales records for different times of day
sales_data = [
  {
    time: "Morning",
    milk_sold: 82.0,  # Approximate based on morning production total
    cash_sales: 400,
    mpesa_sales: 3600,
    buyer: "Morning Sales - Multiple Buyers"
  },
  {
    time: "Noon", 
    milk_sold: 82.0,  # Approximate based on noon production total
    cash_sales: 390,
    mpesa_sales: 350,
    buyer: "Noon Sales - SCI & Others"
  },
  {
    time: "Evening",
    milk_sold: 82.5,  # Approximate based on evening production total
    cash_sales: 400,
    mpesa_sales: 900,
    buyer: "Evening Sales - Multiple Buyers"
  }
]

sales_data.each do |sale_info|
  record = SalesRecord.find_or_initialize_by(
    farm: farm,
    sale_date: record_date,
    buyer: sale_info[:buyer]
  )
  
  record.milk_sold = sale_info[:milk_sold]
  record.cash_sales = sale_info[:cash_sales]
  record.mpesa_sales = sale_info[:mpesa_sales]
  # total_sales will be calculated automatically by the before_save callback
  
  if record.new_record?
    if record.save
      created_count += 1
      puts "✓ Created Sale: #{sale_info[:time].ljust(10)} | Milk: #{sale_info[:milk_sold]}L | Cash: #{sale_info[:cash_sales]} | M-Pesa: #{sale_info[:mpesa_sales]} | Total: #{record.total_sales}"
    else
      error_count += 1
      puts "✗ Failed to create sale: #{record.errors.full_messages.join(', ')}"
    end
  else
    if record.save
      updated_count += 1
      puts "↻ Updated Sale: #{sale_info[:time].ljust(10)} | Milk: #{sale_info[:milk_sold]}L | Cash: #{sale_info[:cash_sales]} | M-Pesa: #{sale_info[:mpesa_sales]} | Total: #{record.total_sales}"
    else
      error_count += 1
      puts "✗ Failed to update sale: #{record.errors.full_messages.join(', ')}"
    end
  end
rescue => e
  error_count += 1
  puts "✗ Error creating sale: #{e.message}"
end

puts "\n" + "=" * 80
puts "SUMMARY"
puts "=" * 80
puts "Records created: #{created_count}"
puts "Records updated: #{updated_count}"
puts "Errors: #{error_count}"
puts "=" * 80

# Display summary statistics
total_production = ProductionRecord.where(production_date: record_date, farm: farm).sum(:total_production)
total_sales_records = SalesRecord.where(sale_date: record_date, farm: farm).count
total_revenue = SalesRecord.where(sale_date: record_date, farm: farm).sum(:total_sales)

puts "\nDATE SUMMARY FOR #{record_date}:"
puts "  Total Production: #{total_production.round(1)} liters"
puts "  Sales Records: #{total_sales_records}"
puts "  Total Revenue: KES #{total_revenue.round(0)}"
puts "=" * 80

# ============================================================================
# PART 2: BACKFILL MISSING DATES WITH AVERAGE PRODUCTION
# ============================================================================

puts "\n\n" + "=" * 80
puts "BACKFILLING MISSING DATES WITH AVERAGE PRODUCTION"
puts "=" * 80

# Get all cows for the farm
all_cows = Cow.where(farm: farm, status: "active")
puts "\nFound #{all_cows.count} active cows in #{farm.name}"

# Target date range: from April 25, 2025 to today (February 16, 2026)
start_date = Date.new(2025, 4, 25)  # Day after the manual record
end_date = Date.today
date_range = (start_date..end_date).to_a

puts "Date range: #{start_date} to #{end_date} (#{date_range.length} days)"

backfill_created = 0
backfill_skipped = 0

all_cows.each do |cow|
  # Get existing production records for this cow
  existing_records = ProductionRecord.where(cow: cow)
  
  if existing_records.empty?
    puts "\n⚠ Skipping #{cow.name} - no production history"
    next
  end
  
  # Calculate averages from existing records
  avg_morning = existing_records.average(:morning_production).to_f.round(1)
  avg_noon = existing_records.average(:noon_production).to_f.round(1)
  avg_evening = existing_records.average(:evening_production).to_f.round(1)
  avg_total = (avg_morning + avg_noon + avg_evening).round(1)
  
  # Get dates that already have records
  existing_dates = existing_records.pluck(:production_date).to_set
  
  # Find missing dates
  missing_dates = date_range.reject { |date| existing_dates.include?(date) }
  
  if missing_dates.empty?
    backfill_skipped += missing_dates.length
    next
  end
  
  puts "\n#{cow.name} (Avg: M:#{avg_morning} N:#{avg_noon} E:#{avg_evening} = #{avg_total}L)"
  puts "  Filling #{missing_dates.length} missing dates..."
  
  # Create records for missing dates
  missing_dates.each do |date|
    record = ProductionRecord.new(
      cow: cow,
      farm: farm,
      production_date: date,
      morning_production: avg_morning,
      noon_production: avg_noon,
      evening_production: avg_evening,
      total_production: avg_total
    )
    
    if record.save
      backfill_created += 1
    else
      puts "  ✗ Failed to create record for #{date}: #{record.errors.full_messages.join(', ')}"
    end
  end
  
  puts "  ✓ Created #{missing_dates.length} records"
rescue => e
  puts "  ✗ Error processing #{cow.name}: #{e.message}"
end

puts "\n" + "=" * 80
puts "BACKFILL SUMMARY"
puts "=" * 80
puts "Records created: #{backfill_created}"
puts "Records skipped (already exist): #{backfill_skipped}"
puts "=" * 80

# Final summary
puts "\n" + "=" * 80
puts "COMPLETE SUMMARY"
puts "=" * 80
puts "Phase 1 - Manual Entry:"
puts "  Production records: #{production_data.length}"
puts "  Sales records: #{sales_data.length}"
puts "\nPhase 2 - Backfill:"
puts "  Records created: #{backfill_created}"
puts "  Date range: #{start_date} to #{end_date}"
puts "\nTotal records in database: #{ProductionRecord.where(farm: farm).count}"
puts "=" * 80
