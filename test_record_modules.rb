#!/usr/bin/env ruby

# Test script to verify all three record modules work without 500 errors
# This tests the form rendering and basic functionality

require 'net/http'
require 'uri'
require 'json'

class RecordModulesTest
  BASE_URL = 'http://localhost:3000'

  def initialize
    @results = {}
  end

  def test_all_modules
    puts "🧪 Testing Record Modules for 500 Errors"
    puts "=" * 50

    test_health_records
    test_vaccination_records
    test_breeding_records

    print_summary
  end

  private

  def test_health_records
    puts "\n🏥 Testing Health Records Module"

    # Test index page
    response = get_request('/health_records')
    @results[:health_index] = check_response(response, 'Health Records Index')

    # Test new form page
    response = get_request('/health_records/new')
    @results[:health_new] = check_response(response, 'Health Records New Form')
  end

  def test_vaccination_records
    puts "\n💉 Testing Vaccination Records Module"

    # Test index page
    response = get_request('/vaccination_records')
    @results[:vaccination_index] = check_response(response, 'Vaccination Records Index')

    # Test new form page
    response = get_request('/vaccination_records/new')
    @results[:vaccination_new] = check_response(response, 'Vaccination Records New Form')
  end

  def test_breeding_records
    puts "\n🐄 Testing Breeding Records Module"

    # Test index page
    response = get_request('/breeding_records')
    @results[:breeding_index] = check_response(response, 'Breeding Records Index')

    # Test new form page
    response = get_request('/breeding_records/new')
    @results[:breeding_new] = check_response(response, 'Breeding Records New Form')
  end

  def get_request(path)
    uri = URI("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 10

    begin
      response = http.get(uri.path)
      {
        code: response.code.to_i,
        body: response.body,
        headers: response.to_hash
      }
    rescue => e
      {
        error: e.message,
        code: 0
      }
    end
  end

  def check_response(response, test_name)
    if response[:error]
      puts "❌ #{test_name}: Connection Error - #{response[:error]}"
      return { status: :error, message: response[:error] }
    end

    case response[:code]
    when 200
      puts "✅ #{test_name}: SUCCESS (200)"

      # Check for common error indicators in body
      if response[:body].include?('Internal Server Error') || response[:body].include?('500')
        puts "⚠️  #{test_name}: Contains 500 error content"
        return { status: :warning, message: "500 error in content" }
      end

      { status: :success, message: "200 OK" }
    when 500
      puts "❌ #{test_name}: FAILED (500 Internal Server Error)"
      { status: :failed, message: "500 Internal Server Error" }
    when 404
      puts "⚠️  #{test_name}: Not Found (404)"
      { status: :not_found, message: "404 Not Found" }
    when 302, 301
      puts "↗️  #{test_name}: Redirect (#{response[:code]})"
      { status: :redirect, message: "Redirect #{response[:code]}" }
    else
      puts "⚠️  #{test_name}: Unexpected status (#{response[:code]})"
      { status: :unexpected, message: "Status #{response[:code]}" }
    end
  end

  def print_summary
    puts "\n📊 TEST SUMMARY"
    puts "=" * 50

    success_count = @results.values.count { |r| r[:status] == :success }
    total_count = @results.size

    puts "✅ Successful: #{success_count}/#{total_count}"

    failed_tests = @results.select { |_, r| r[:status] == :failed }
    if failed_tests.any?
      puts "\n❌ Failed Tests:"
      failed_tests.each do |test, result|
        puts "   - #{test}: #{result[:message]}"
      end
    end

    warning_tests = @results.select { |_, r| [ :warning, :not_found, :unexpected ].include?(r[:status]) }
    if warning_tests.any?
      puts "\n⚠️  Warning Tests:"
      warning_tests.each do |test, result|
        puts "   - #{test}: #{result[:message]}"
      end
    end

    if success_count == total_count
      puts "\n🎉 ALL TESTS PASSED! No 500 errors found."
    elsif failed_tests.any?
      puts "\n❌ TESTS FAILED! 500 errors still present."
    else
      puts "\n⚠️  TESTS COMPLETED with warnings."
    end
  end
end

# Run the tests
tester = RecordModulesTest.new
tester.test_all_modules
