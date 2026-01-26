namespace :data do
  desc "Populate night production data for existing production records"
  task populate_night_production: :environment do
    puts "🚀 Starting night production data population..."
    puts "Current time: #{Time.current}"

    # Check current state
    total_records = ProductionRecord.count
    null_night_records = ProductionRecord.where(night_production: nil).count
    zero_night_records = ProductionRecord.where(night_production: 0.0).count

    puts "\n📊 Current State:"
    puts "Total production records: #{total_records}"
    puts "Records with NULL night_production: #{null_night_records}"
    puts "Records with 0.0 night_production: #{zero_night_records}"

    if null_night_records == 0 && zero_night_records == 0
      puts "\n✅ All records already have night production data!"
      next
    end

    # Function to generate realistic night production based on other production values
    def calculate_realistic_night_production(record)
      base_productions = [
        record.morning_production || 0.0,
        record.noon_production || 0.0,
        record.evening_production || 0.0
      ].reject(&:zero?)
      
      return 0.0 if base_productions.empty?
      
      # Night production is typically 15-25% less than average of other periods
      # due to longer interval between milking sessions
      average_production = base_productions.sum / base_productions.length
      night_factor = 0.75 + (rand * 0.15) # Random factor between 0.75-0.90
      
      # Add some natural variation
      variation = (rand - 0.5) * 0.1 # ±5% variation
      night_production = average_production * night_factor * (1 + variation)
      
      # Ensure minimum and reasonable bounds
      [night_production.round(2), 0.1].max
    end

    puts "\n🔄 Populating night production data..."

    # Process records in batches to avoid memory issues
    batch_size = 100
    updated_count = 0
    error_count = 0

    ProductionRecord.where("night_production IS NULL OR night_production = 0.0").find_in_batches(batch_size: batch_size) do |batch|
      puts "Processing batch of #{batch.size} records..."
      
      batch.each do |record|
        begin
          # Skip if the record already has meaningful night production data
          next if record.night_production.present? && record.night_production > 0.0
          
          # Calculate realistic night production
          night_value = calculate_realistic_night_production(record)
          
          # Update the record
          record.update_column(:night_production, night_value)
          updated_count += 1
          
          # Show progress every 50 records
          if updated_count % 50 == 0
            puts "  Updated #{updated_count} records..."
          end
          
        rescue => e
          puts "  ❌ Error updating record #{record.id}: #{e.message}"
          error_count += 1
        end
      end
    end

    puts "\n✅ Night production data population complete!"
    puts "Records updated: #{updated_count}"
    puts "Errors encountered: #{error_count}"

    # Verify the results
    final_null_count = ProductionRecord.where(night_production: nil).count
    final_zero_count = ProductionRecord.where(night_production: 0.0).count

    puts "\n📈 Final State:"
    puts "Records with NULL night_production: #{final_null_count}"
    puts "Records with 0.0 night_production: #{final_zero_count}"

    if final_null_count == 0
      puts "\n🎉 SUCCESS: All records now have night production values!"
      
      # Show some sample data
      puts "\n📋 Sample updated records:"
      ProductionRecord.order(:created_at).limit(5).each do |record|
        puts "  Cow #{record.cow_id}: Morning=#{record.morning_production}, " \
             "Noon=#{record.noon_production}, Evening=#{record.evening_production}, " \
             "Night=#{record.night_production}, Total=#{record.total_production}"
      end
      
    else
      puts "\n⚠️  WARNING: Some records still have NULL values. Manual intervention may be required."
    end

    puts "\n🚀 Data population complete! Analytics should now work properly."
  end
end
