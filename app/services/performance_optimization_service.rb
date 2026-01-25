class PerformanceOptimizationService
  class << self
    # Cache clearing methods
    def clear_health_stats_cache(cow_id = nil)
      if cow_id
        Rails.cache.delete_matched("*health_stats_#{cow_id}_*")
      else
        Rails.cache.delete_matched("*health_stats_*")
      end
    end

    def clear_vaccination_stats_cache(cow_id = nil)
      if cow_id
        Rails.cache.delete_matched("*vaccination_stats_#{cow_id}_*")
      else
        Rails.cache.delete_matched("*vaccination_stats_*")
      end
    end

    def clear_breeding_stats_cache(cow_id = nil)
      if cow_id
        Rails.cache.delete_matched("*breeding_stats_#{cow_id}_*")
      else
        Rails.cache.delete_matched("*breeding_stats_*")
      end
    end

    def clear_all_record_caches
      clear_health_stats_cache
      clear_vaccination_stats_cache
      clear_breeding_stats_cache
    end

    # Performance monitoring methods
    def monitor_query_performance(&block)
      start_time = Time.current
      result = block.call
      end_time = Time.current
      
      execution_time = (end_time - start_time) * 1000 # Convert to milliseconds
      
      if execution_time > 1000 # Log slow queries over 1 second
        Rails.logger.warn "Slow query detected: #{execution_time.round(2)}ms"
      end
      
      result
    end

    # Database optimization methods
    def analyze_query_performance
      queries = {
        health_records: -> { HealthRecord.includes(:cow).limit(100) },
        vaccination_records: -> { VaccinationRecord.includes(:cow).limit(100) },
        breeding_records: -> { BreedingRecord.includes(:cow).limit(100) }
      }

      results = {}
      
      queries.each do |name, query|
        start_time = Time.current
        records = query.call.to_a
        end_time = Time.current
        
        execution_time = (end_time - start_time) * 1000
        
        results[name] = {
          record_count: records.count,
          execution_time_ms: execution_time.round(2),
          status: execution_time < 500 ? 'optimal' : execution_time < 1000 ? 'acceptable' : 'slow'
        }
      end

      results
    end

    # Memory optimization methods
    def optimize_memory_usage
      # Clear unnecessary caches
      Rails.cache.clear unless Rails.env.production?
      
      # Force garbage collection
      GC.start
      
      # Log memory usage
      memory_usage = `ps -o pid,rss -p #{Process.pid}`.split("\n").last.split.last.to_i
      Rails.logger.info "Memory usage after optimization: #{memory_usage / 1024}MB"
    end

    # Database connection optimization
    def optimize_database_connections
      ActiveRecord::Base.connection_pool.disconnect!
      ActiveRecord::Base.establish_connection
      Rails.logger.info "Database connections optimized"
    end

    # Complete system optimization
    def perform_complete_optimization
      puts "🚀 Starting Performance Optimization..."
      
      # Clear caches
      puts "📊 Clearing record caches..."
      clear_all_record_caches
      
      # Analyze query performance
      puts "🔍 Analyzing query performance..."
      performance_results = analyze_query_performance
      performance_results.each do |record_type, stats|
        puts "  #{record_type.to_s.humanize}: #{stats[:record_count]} records, #{stats[:execution_time_ms]}ms (#{stats[:status]})"
      end
      
      # Optimize memory usage
      puts "🧹 Optimizing memory usage..."
      optimize_memory_usage
      
      # Optimize database connections
      puts "🗄️  Optimizing database connections..."
      optimize_database_connections
      
      puts "✅ Performance optimization complete!"
      
      performance_results
    end

    # Preload common associations for better performance
    def preload_common_associations
      Rails.cache.fetch('common_associations_preload', expires_in: 1.hour) do
        {
          active_cows: Cow.active.includes(:farm, :health_records, :vaccination_records, :breeding_records).to_a,
          recent_health_records: HealthRecord.recent.includes(:cow).limit(50).to_a,
          recent_vaccination_records: VaccinationRecord.recent.includes(:cow).limit(50).to_a,
          recent_breeding_records: BreedingRecord.recent.includes(:cow).limit(50).to_a
        }
      end
    end
  end
end
