#!/usr/bin/env ruby
# Quick performance test script

require_relative 'config/environment'
require 'benchmark'

puts "=== Performance Test ==="
puts "Testing dashboard queries...\n\n"

# Test dashboard queries
time = Benchmark.realtime do
  @farms = Farm.all
  @total_cows = Cow.count
  @active_cows = Cow.active.count
  @today_production = ProductionRecord.where(production_date: Date.current).sum(:total_production)
  @recent_records = ProductionRecord.includes(:cow, :farm).recent.limit(10).to_a
  @recent_active_cows = Cow.active.includes(:farm).order(created_at: :desc).limit(10).to_a
end

puts "Dashboard queries: #{(time * 1000).round(2)}ms"

# Test production trends
puts "\nTesting production trends (slow page)..."
time = Benchmark.realtime do
  farm = Farm.first
  if farm
    records = farm.production_records.limit(1000)
    dates = records.group("DATE(production_date)").count
  end
end

puts "Production trends: #{(time * 1000).round(2)}ms"

# Test with service
puts "\nTesting with ProductionAnalyticsService..."
time = Benchmark.realtime do
  farm = Farm.first
  if farm
    service = ProductionAnalyticsService.new(farm_id: farm.id)
    data = service.dashboard_data
  end
end

puts "Service-based analytics: #{(time * 1000).round(2)}ms"

puts "\n=== Test Complete ==="
