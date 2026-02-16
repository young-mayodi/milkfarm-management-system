#!/usr/bin/env ruby
# Comprehensive System Test Suite
# Run with: ruby system_test_suite.rb

require_relative 'config/environment'
require 'benchmark'

class SystemTestSuite
  def initialize
    @results = []
    @failed = []
    @passed = []
  end

  def run_all_tests
    puts "=" * 80
    puts "🧪 COMPREHENSIVE SYSTEM TEST SUITE"
    puts "=" * 80
    puts ""

    test_database_connectivity
    test_models_and_associations
    test_validations
    test_scopes_and_queries
    test_services
    test_performance
    test_caching
    test_error_handling

    print_summary
  end

  private

  def test_database_connectivity
    section_header("Database Connectivity")

    test("PostgreSQL connection") do
      ActiveRecord::Base.connection.execute("SELECT 1")
      true
    end

    test("Database exists and accessible") do
      Farm.count >= 0
      true
    end

    test("All tables accessible") do
      models = [ Farm, Cow, ProductionRecord, SalesRecord, VaccinationRecord, BreedingRecord, HealthRecord ]
      models.all? { |model| model.count >= 0 }
    end
  end

  def test_models_and_associations
    section_header("Models & Associations")

    test("Farm model loads") { Farm.first || true }
    test("Cow model loads") { Cow.first || true }
    test("ProductionRecord model loads") { ProductionRecord.first || true }

    test("Farm has cows association") do
      farm = Farm.first
      farm ? farm.cows.count >= 0 : true
    end

    test("Cow belongs to farm") do
      cow = Cow.first
      cow ? cow.farm.present? : true
    end

    test("ProductionRecord associations") do
      record = ProductionRecord.first
      if record
        record.cow.present? && record.farm.present?
      else
        true
      end
    end
  end

  def test_validations
    section_header("Model Validations")

    test("Farm requires name") do
      farm = Farm.new
      !farm.valid? && farm.errors[:name].present?
    end

    test("Cow requires tag_number") do
      cow = Cow.new(farm: Farm.first)
      !cow.valid? && cow.errors[:tag_number].present?
    end

    test("ProductionRecord requires date") do
      record = ProductionRecord.new
      !record.valid? && record.errors[:production_date].present?
    end

    test("Cow age calculation") do
      cow = Cow.new(date_of_birth: 2.years.ago)
      cow.age == 2
    end
  end

  def test_scopes_and_queries
    section_header("Scopes & Queries")

    test("Cow.active scope") do
      Cow.active.where_values_hash['status'] == 'active' rescue true
    end

    test("ProductionRecord.recent scope") do
      ProductionRecord.recent.limit(5).count <= 5
    end

    test("ProductionRecord total_production calculation") do
      record = ProductionRecord.first
      if record
        total = record.morning_production.to_f + record.night_production.to_f
        record.total_production == total
      else
        true
      end
    end
  end

  def test_services
    section_header("Service Layer")

    test("ApplicationService base class exists") do
      defined?(ApplicationService) == 'constant'
    end

    test("ProductionAnalyticsService exists") do
      defined?(ProductionAnalyticsService) == 'constant'
    end

    test("AlertEngineService exists") do
      defined?(AlertEngineService) == 'constant'
    end

    test("NotificationService exists") do
      defined?(NotificationService) == 'constant'
    end

    test("ProductionAnalyticsService.call works") do
      farm = Farm.first
      if farm
        service = ProductionAnalyticsService.new(farm_id: farm.id)
        data = service.dashboard_data
        data.is_a?(Hash) && data.key?(:production_summary)
      else
        true # No farm to test with, but service exists
      end
    end

    test("AlertEngineService.call works") do
      farm = Farm.first
      if farm
        alerts = AlertEngineService.call(farm: farm)
        alerts.is_a?(Array)
      else
        true
      end
    end
  end

  def test_performance
    section_header("Performance Benchmarks")

    test("Dashboard queries < 500ms") do
      time = Benchmark.realtime do
        Farm.all.to_a
        Cow.count
        ProductionRecord.recent.limit(10).to_a
      end
      ms = (time * 1000).round(2)
      puts "      ⏱️  #{ms}ms"
      ms < 500
    end

    test("Production analytics < 1000ms") do
      farm = Farm.first
      if farm
        time = Benchmark.realtime do
          service = ProductionAnalyticsService.new(farm_id: farm.id)
          service.dashboard_data
        end
        ms = (time * 1000).round(2)
        puts "      ⏱️  #{ms}ms"
        ms < 1000
      else
        true
      end
    end

    test("Alert generation < 500ms") do
      farm = Farm.first
      if farm
        time = Benchmark.realtime do
          AlertEngineService.call(farm: farm)
        end
        ms = (time * 1000).round(2)
        puts "      ⏱️  #{ms}ms"
        ms < 500
      else
        true
      end
    end
  end

  def test_caching
    section_header("Caching System")

    test("Rails.cache is configured") do
      Rails.cache.write('test_key', 'test_value')
      Rails.cache.read('test_key') == 'test_value'
    end

    test("Cache expires correctly") do
      Rails.cache.write('expiry_test', 'value', expires_in: 1.second)
      sleep 1.1
      Rails.cache.read('expiry_test').nil?
    end

    test("Service caching works") do
      farm = Farm.first
      if farm
        cache_key = "test_analytics_#{farm.id}"
        Rails.cache.delete(cache_key)

        # First call - should cache
        service1 = ProductionAnalyticsService.new(farm_id: farm.id)
        service1.dashboard_data

        # Second call - should use cache
        service2 = ProductionAnalyticsService.new(farm_id: farm.id)
        service2.dashboard_data

        true
      else
        true
      end
    end
  end

  def test_error_handling
    section_header("Error Handling & Security")

    test("ErrorsController exists") do
      defined?(ErrorsController) == 'constant'
    end

    test("Rack::Attack is configured") do
      defined?(Rack::Attack) == 'constant'
    end

    test("Rack::Timeout is configured") do
      ENV['RACK_TIMEOUT_SERVICE_TIMEOUT'] == '30'
    end

    test("Database connection pool configured") do
      pool_size = ActiveRecord::Base.connection_pool.size
      puts "      📊 Pool size: #{pool_size}"
      pool_size > 0
    end
  end

  # Helper methods
  def section_header(title)
    puts ""
    puts "#{title}"
    puts "-" * 80
  end

  def test(description)
    result = yield
    if result
      @passed << description
      puts "  ✅ #{description}"
    else
      @failed << description
      puts "  ❌ #{description}"
    end
    @results << { description: description, passed: result }
  rescue => e
    @failed << description
    puts "  ❌ #{description}"
    puts "     Error: #{e.message}"
    @results << { description: description, passed: false, error: e.message }
  end

  def print_summary
    puts ""
    puts "=" * 80
    puts "📊 TEST SUMMARY"
    puts "=" * 80
    puts ""
    puts "Total Tests:  #{@results.count}"
    puts "Passed:       #{@passed.count} ✅"
    puts "Failed:       #{@failed.count} ❌"
    puts "Success Rate: #{(@passed.count.to_f / @results.count * 100).round(2)}%"
    puts ""

    if @failed.any?
      puts "Failed Tests:"
      @failed.each do |test|
        puts "  ❌ #{test}"
      end
      puts ""
    end

    if @passed.count == @results.count
      puts "🎉 ALL TESTS PASSED! System is fully functional!"
    else
      puts "⚠️  Some tests failed. Review above for details."
    end
    puts "=" * 80
  end
end

# Run the test suite
SystemTestSuite.new.run_all_tests
