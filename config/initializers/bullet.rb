# Performance Monitoring Configuration

if Rails.env.development?
  # Bullet configuration for N+1 query detection
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  
  # Rack Mini Profiler configuration
  Rack::MiniProfiler.config.position = 'bottom-right'
  Rack::MiniProfiler.config.show_children = true
  
  # Skip profiling for certain paths
  Rack::MiniProfiler.config.skip_paths = ['/assets']
  
  # Memory profiling
  Rack::MiniProfiler.config.enable_advanced_debugging_tools = true
end

# Custom performance tracking
module PerformanceTracking
  def self.track_database_queries
    start_time = Time.current
    query_count = ActiveRecord::Base.connection.query_cache.size
    
    result = yield
    
    end_time = Time.current
    final_query_count = ActiveRecord::Base.connection.query_cache.size
    
    Rails.logger.info "Performance: #{end_time - start_time}s, Queries: #{final_query_count - query_count}"
    
    result
  end
  
  def self.track_memory_usage
    before_memory = `ps -o pid,rss -p #{Process.pid}`.split("\n").last.split.last.to_i
    
    result = yield
    
    after_memory = `ps -o pid,rss -p #{Process.pid}`.split("\n").last.split.last.to_i
    memory_diff = after_memory - before_memory
    
    Rails.logger.info "Memory usage: #{memory_diff} KB increase" if memory_diff > 1000
    
    result
  end
end

# Add performance tracking to controllers (disabled temporarily to fix dashboard)
# Rails.application.config.to_prepare do
#   ActionController::Base.class_eval do
#     around_action :track_performance, only: [:index, :show] if Rails.env.development?
#     
#     private
#     
#     def track_performance
#       start_time = Time.current
#       memory_before = `ps -o pid,rss -p #{Process.pid}`.split("\n").last.split.last.to_i rescue 0
#       
#       yield
#       
#       end_time = Time.current
#       memory_after = `ps -o pid,rss -p #{Process.pid}`.split("\n").last.split.last.to_i rescue 0
#       memory_diff = memory_after - memory_before
#       
#       if end_time - start_time > 0.5 || memory_diff > 5000
#         Rails.logger.warn "PERFORMANCE WARNING: #{controller_name}##{action_name} took #{(end_time - start_time).round(3)}s, memory: +#{memory_diff}KB"
#       end
#     end
#   end
# end
