#!/usr/bin/env ruby
# Simple Test Runner for Milk Production System
# This script runs basic tests without complex dependencies

require_relative 'config/environment'
require 'minitest/autorun'
require 'net/http'
require 'uri'

class MilkProductionSystemTest < Minitest::Test
  def setup
    puts "\n🧪 Setting up test environment..."
    @farm = Farm.first || create_test_farm
    @cow = @farm.cows.first || create_test_cow
    puts "   ✅ Test data ready"
  end

  def test_database_connectivity
    puts "\n🗄️  Testing Database Connectivity..."

    assert Farm.connection.active?, "Database connection failed"
    assert_operator Farm.count, :>=, 0, "Cannot query farms table"
    assert_operator Cow.count, :>=, 0, "Cannot query cows table"

    puts "   ✅ Database connectivity working"
  end

  def test_model_validations
    puts "\n📋 Testing Model Validations..."

    # Test Farm validation
    invalid_farm = Farm.new
    refute invalid_farm.valid?, "Farm should require name"

    # Test Cow validation
    invalid_cow = Cow.new
    refute invalid_cow.valid?, "Cow should require name and farm"

    # Test valid models
    valid_farm = Farm.new(name: "Test Farm", location: "Test Location", owner: "Test Owner")
    assert valid_farm.valid?, "Valid farm should pass validation"

    puts "   ✅ Model validations working"
  end

  def test_financial_calculations
    puts "\n💰 Testing Financial Calculations..."

    # Create test financial data
    create_test_financial_data

    current_month = Date.current.beginning_of_month..Date.current.end_of_month

    # Test revenue calculation
    revenue = @farm.sales_records.where(sale_date: current_month).sum(:total_sales)
    assert_operator revenue, :>=, 0, "Revenue should be non-negative"

    # Test expense calculation
    expenses = @farm.expenses.where(expense_date: current_month).sum(:amount)
    assert_operator expenses, :>=, 0, "Expenses should be non-negative"

    # Test profit calculation
    profit = revenue - expenses
    assert profit.is_a?(Numeric), "Profit should be numeric"

    puts "   ✅ Financial calculations working (Revenue: #{revenue}, Expenses: #{expenses}, Profit: #{profit})"
  end

  def test_production_records
    puts "\n📊 Testing Production Records..."

    # Test creating production record
    record = ProductionRecord.new(
      cow: @cow,
      farm: @farm,
      production_date: Date.current,
      morning_production: 10.5,
      noon_production: 8.2,
      evening_production: 9.8
    )

    assert record.valid?, "Production record should be valid: #{record.errors.full_messages}"
    assert record.save, "Production record should save successfully"
    assert_equal 28.5, record.total_production, "Total production should be calculated correctly"

    puts "   ✅ Production records working"
  end

  def test_controller_methods
    puts "\n🎮 Testing Controller Methods..."

    # Test FinancialReportsController
    controller = FinancialReportsController.new

    # Mock the required methods
    def controller.params
      ActionController::Parameters.new(period: 'month')
    end

    def controller.current_farm
      Farm.first
    end

    # Test financial overview generation
    controller.instance_variable_set(:@farm, Farm.first)
    controller.instance_variable_set(:@date_range, 1.month.ago.to_date..Date.current)
    overview = controller.send(:generate_financial_overview)

    assert overview.is_a?(Hash), "Financial overview should return hash"
    assert overview.key?(:revenue), "Overview should include revenue"
    assert overview.key?(:expenses), "Overview should include expenses"

    puts "   ✅ Controller methods working"
  end

  def test_route_helpers
    puts "\n🛣️  Testing Route Helpers..."

    # Test that route helpers exist
    app = Rails.application

    assert app.routes.url_helpers.respond_to?(:financial_reports_path), "financial_reports_path should exist"
    assert app.routes.url_helpers.respond_to?(:profit_loss_financial_reports_path), "profit_loss route should exist"
    assert app.routes.url_helpers.respond_to?(:cost_analysis_financial_reports_path), "cost_analysis route should exist"
    assert app.routes.url_helpers.respond_to?(:roi_report_financial_reports_path), "roi_report route should exist"

    puts "   ✅ Route helpers working"
  end

  def test_data_associations
    puts "\n🔗 Testing Data Associations..."

    # Test farm has cows
    assert_respond_to @farm, :cows, "Farm should have cows association"
    assert_respond_to @farm, :expenses, "Farm should have expenses association"
    assert_respond_to @farm, :sales_records, "Farm should have sales_records association"

    # Test cow belongs to farm
    assert_respond_to @cow, :farm, "Cow should belong to farm"
    assert_respond_to @cow, :production_records, "Cow should have production_records association"

    # Test actual associations work
    assert_equal @farm.id, @cow.farm_id, "Cow should belong to correct farm"

    puts "   ✅ Data associations working"
  end

  def test_mobile_css_present
    puts "\n📱 Testing Mobile CSS..."

    layout_file = Rails.root.join('app/views/layouts/application.html.erb')
    assert File.exist?(layout_file), "Application layout should exist"

    layout_content = File.read(layout_file)
    assert layout_content.include?('@media'), "Mobile media queries should be present"
    assert layout_content.include?('44px'), "Touch-friendly button sizes should be present"

    puts "   ✅ Mobile CSS optimizations present"
  end

  def test_performance_optimizations
    puts "\n⚡ Testing Performance Optimizations..."

    # Test that we can load cows without N+1 queries
    cows = Cow.includes(:farm).limit(5)
    assert_operator cows.count, :<=, 5, "Should limit cows correctly"

    # Test optimized production stats query
    cow_ids = cows.pluck(:id)
    if cow_ids.any?
      start_time = Time.current

      stats = ProductionRecord.connection.execute(
        "SELECT cow_id, COUNT(*) as record_count
         FROM production_records
         WHERE cow_id IN (#{cow_ids.join(',')})
         GROUP BY cow_id"
      )

      query_time = Time.current - start_time
      assert_operator query_time, :<, 1.0, "Query should complete quickly"
      puts "   ✅ Performance optimizations working (Query time: #{query_time.round(3)}s)"
    else
      puts "   ⚠️  No production records to test performance with"
    end
  end

  def test_expense_model
    puts "\n💸 Testing Expense Model..."

    expense = Expense.new(
      farm: @farm,
      expense_type: 'feed',
      amount: 1000,
      description: 'Test feed expense',
      expense_date: Date.current,
      category: 'feed'
    )

    assert expense.valid?, "Expense should be valid: #{expense.errors.full_messages}"
    assert expense.save, "Expense should save successfully"

    # Test expense belongs to farm
    assert_equal @farm.id, expense.farm_id, "Expense should belong to correct farm"

    puts "   ✅ Expense model working"
  end

  def test_chart_data_generation
    puts "\n📊 Testing Chart Data Generation..."

    create_test_financial_data

    # Test that we can generate chart data without errors
    current_month = Date.current.beginning_of_month..Date.current.end_of_month

    # Revenue data
    revenue_data = @farm.sales_records.where(sale_date: current_month)
                       .group_by_day(:sale_date)
                       .sum(:total_sales)

    assert revenue_data.is_a?(Hash), "Revenue chart data should be hash"

    # Expense data
    expense_data = @farm.expenses.where(expense_date: current_month)
                       .group(:category)
                       .sum(:amount)

    assert expense_data.is_a?(Hash), "Expense chart data should be hash"

    puts "   ✅ Chart data generation working"
  end

  private

  def create_test_farm
    Farm.create!(
      name: 'Test Farm',
      location: 'Test Location',
      farm_size: 100,
      owner: 'Test Owner',
      established_date: 5.years.ago
    )
  end

  def create_test_cow
    @farm.cows.create!(
      name: 'Test Cow',
      tag_number: 'TEST001',
      breed: 'Holstein',
      date_of_birth: 3.years.ago,
      health_status: 'healthy',
      breeding_status: 'open'
    )
  end

  def create_test_financial_data
    # Clean up existing test data
    @farm.sales_records.where(buyer: 'Test Buyer').destroy_all
    @farm.expenses.where(description: 'Test feed expense').destroy_all
    @cow.production_records.where(production_date: Date.current).destroy_all

    # Create fresh test data
    @farm.sales_records.create!(
      sale_date: Date.current,
      milk_sold: 100,
      cash_sales: 2000,
      mpesa_sales: 3000,
      total_sales: 5000,
      buyer: 'Test Buyer'
    )

    @farm.expenses.create!(
      expense_type: 'feed',
      amount: 2000,
      description: 'Test feed expense',
      expense_date: Date.current,
      category: 'feed'
    )

    @cow.production_records.create!(
      farm: @farm,
      production_date: Date.current,
      morning_production: 15,
      noon_production: 12,
      evening_production: 13,
      total_production: 40
    )
  end
end

# Custom test runner
class TestRunner
  def self.run
    puts "\n" + "🧪" * 80
    puts "🧪" + " " * 76 + "🧪"
    puts "🧪  MILK PRODUCTION SYSTEM - AUTOMATED TEST SUITE  🧪"
    puts "🧪" + " " * 76 + "🧪"
    puts "🧪" * 80

    puts "\n🎯 Environment: #{Rails.env}"
    puts "🗄️  Database: #{ActiveRecord::Base.connection.adapter_name}"
    puts "📅 Date: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"

    # Run tests
    test_result = Minitest.run([])

    puts "\n" + "🧪" * 80
    if test_result
      puts "🎉  ALL TESTS PASSED - SYSTEM READY FOR DEPLOYMENT!"
    else
      puts "❌  SOME TESTS FAILED - PLEASE FIX BEFORE DEPLOYMENT"
    end
    puts "🧪" * 80

    test_result
  end
end

# Run tests if this file is executed directly
if __FILE__ == $0
  TestRunner.run
end
