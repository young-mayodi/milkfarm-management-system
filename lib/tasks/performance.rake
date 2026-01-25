namespace :performance do
  desc "Optimize application performance"
  task optimize: :environment do
    PerformanceOptimizationService.perform_complete_optimization
  end

  desc "Clear all record caches"
  task clear_caches: :environment do
    puts "🧹 Clearing all record caches..."
    PerformanceOptimizationService.clear_all_record_caches
    puts "✅ All caches cleared!"
  end

  desc "Analyze query performance"
  task analyze: :environment do
    puts "🔍 Analyzing query performance..."
    results = PerformanceOptimizationService.analyze_query_performance

    puts "\n📊 Query Performance Results:"
    results.each do |record_type, stats|
      status_emoji = case stats[:status]
      when "optimal" then "🟢"
      when "acceptable" then "🟡"
      when "slow" then "🔴"
      else "⚪"
      end

      puts "#{status_emoji} #{record_type.to_s.humanize}: #{stats[:record_count]} records, #{stats[:execution_time_ms]}ms"
    end
  end

  desc "Run database optimization"
  task optimize_db: :environment do
    puts "🗄️  Running database optimization..."
    PerformanceOptimizationService.optimize_database_connections
    puts "✅ Database optimization complete!"
  end

  desc "Test edit forms performance"
  task test_forms: :environment do
    puts "🔬 Testing Edit Forms Performance..."

    # Test health records edit form
    puts "\n📋 Testing Health Records..."
    health_record = HealthRecord.includes(:cow).first
    if health_record
      start_time = Time.current
      health_record.cow.display_name # Simulate view access
      end_time = Time.current
      puts "✅ Health record load time: #{((end_time - start_time) * 1000).round(2)}ms"
    else
      puts "⚠️  No health records found"
    end

    # Test vaccination records edit form
    puts "\n💉 Testing Vaccination Records..."
    vaccination_record = VaccinationRecord.includes(:cow).first
    if vaccination_record
      start_time = Time.current
      vaccination_record.cow.display_name # Simulate view access
      end_time = Time.current
      puts "✅ Vaccination record load time: #{((end_time - start_time) * 1000).round(2)}ms"
    else
      puts "⚠️  No vaccination records found"
    end

    # Test breeding records edit form
    puts "\n🐄 Testing Breeding Records..."
    breeding_record = BreedingRecord.includes(:cow).first
    if breeding_record
      start_time = Time.current
      breeding_record.cow.display_name # Simulate view access
      end_time = Time.current
      puts "✅ Breeding record load time: #{((end_time - start_time) * 1000).round(2)}ms"
    else
      puts "⚠️  No breeding records found"
    end

    puts "\n🎯 Edit forms performance test complete!"
  end
end
