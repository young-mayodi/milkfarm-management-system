namespace :farm_data do
  desc "Populate production records for April 24, 2025"
  task populate_april_24: :environment do
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
          puts "✗ Failed: #{cow_name}: #{record.errors.full_messages.join(', ')}"
        end
      else
        if record.save
          updated_count += 1
          puts "↻ Updated: #{cow_name.ljust(15)} | M: #{morning.to_s.rjust(5)} | N: #{noon.to_s.rjust(5)} | E: #{evening.to_s.rjust(5)} | Total: #{total.round(1)}"
        else
          puts "✗ Failed: #{cow_name}: #{record.errors.full_messages.join(', ')}"
        end
      end
    rescue => e
      puts "✗ Error: #{cow_name}: #{e.message}"
    end

    puts "\n" + "=" * 80
    puts "CREATING SALES RECORDS"
    puts "=" * 80

    sales_data = [
      { time: "Morning", milk_sold: 82.0, cash_sales: 400, mpesa_sales: 3600, buyer: "Morning Sales" },
      { time: "Noon", milk_sold: 82.0, cash_sales: 390, mpesa_sales: 350, buyer: "Noon Sales" },
      { time: "Evening", milk_sold: 82.5, cash_sales: 400, mpesa_sales: 900, buyer: "Evening Sales" }
    ]

    sales_count = 0
    sales_data.each do |sale_info|
      record = SalesRecord.find_or_initialize_by(
        farm: farm,
        sale_date: record_date,
        buyer: sale_info[:buyer]
      )
      
      record.milk_sold = sale_info[:milk_sold]
      record.cash_sales = sale_info[:cash_sales]
      record.mpesa_sales = sale_info[:mpesa_sales]
      
      if record.save
        sales_count += 1
        puts "✓ #{sale_info[:time]}: #{sale_info[:milk_sold]}L | Cash: #{sale_info[:cash_sales]} | M-Pesa: #{sale_info[:mpesa_sales]}"
      else
        puts "✗ Failed: #{record.errors.full_messages.join(', ')}"
      end
    rescue => e
      puts "✗ Error: #{e.message}"
    end

    puts "\n" + "=" * 80
    puts "SUMMARY FOR #{record_date}"
    puts "=" * 80
    puts "Production records created: #{created_count}"
    puts "Production records updated: #{updated_count}"
    puts "Sales records created: #{sales_count}"
    
    total_production = ProductionRecord.where(production_date: record_date, farm: farm).sum(:total_production)
    total_revenue = SalesRecord.where(sale_date: record_date, farm: farm).sum(:total_sales)
    
    puts "Total milk produced: #{total_production.round(1)}L"
    puts "Total revenue: KES #{total_revenue.round(0)}"
    puts "=" * 80

    # Backfill missing dates
    puts "\n" + "=" * 80
    puts "BACKFILLING MISSING DATES"
    puts "=" * 80

    start_date = Date.new(2025, 4, 25)
    end_date = Date.today
    date_range = (start_date..end_date).to_a
    
    puts "Date range: #{start_date} to #{end_date} (#{date_range.length} days)"

    backfill_count = 0
    farm.cows.where(status: "active").find_each do |cow|
      existing_records = ProductionRecord.where(cow: cow)
      
      next if existing_records.empty?
      
      avg_morning = existing_records.average(:morning_production).to_f.round(1)
      avg_noon = existing_records.average(:noon_production).to_f.round(1)
      avg_evening = existing_records.average(:evening_production).to_f.round(1)
      avg_total = (avg_morning + avg_noon + avg_evening).round(1)
      
      existing_dates = existing_records.pluck(:production_date).to_set
      missing_dates = date_range.reject { |date| existing_dates.include?(date) }
      
      next if missing_dates.empty?
      
      puts "#{cow.name}: Filling #{missing_dates.length} dates (Avg: #{avg_total}L)"
      
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
        
        backfill_count += 1 if record.save
      end
    end

    puts "\n" + "=" * 80
    puts "BACKFILL COMPLETE"
    puts "=" * 80
    puts "Records created: #{backfill_count}"
    puts "Total production records: #{ProductionRecord.where(farm: farm).count}"
    puts "=" * 80
  end
end
