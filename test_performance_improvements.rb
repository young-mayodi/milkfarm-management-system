#!/usr/bin/env ruby
# Performance test script to verify N+1 query fixes
# Run this while the Rails server is running in another terminal

require 'net/http'
require 'json'
require 'benchmark'
require 'date'

BASE_URL = 'http://localhost:3000'

def check_server
  uri = URI("#{BASE_URL}/health")
  response = Net::HTTP.get_response(uri) rescue nil
  if response.nil?
    puts "❌ Server not responding at #{BASE_URL}"
    puts "Please start the server with: bin/rails server"
    exit 1
  end
end

def test_endpoint(name, path, method: :get)
  puts "\n" + "=" * 60
  puts "Testing: #{name}"
  puts "URL: #{path}"
  puts "=" * 60

  uri = URI("#{BASE_URL}#{path}")

  response_time = Benchmark.realtime do
    response = case method
    when :get
      Net::HTTP.get_response(uri)
    when :post
      Net::HTTP.post_form(uri, {})
    end

    if response.code == '200'
      puts "✅ Status: 200 OK"
    elsif response.code == '302'
      puts "⚠️  Status: 302 Redirect (may need login)"
    else
      puts "❌ Status: #{response.code}"
    end
  end

  puts "⏱️  Response Time: #{(response_time * 1000).round(2)}ms"
  response_time
end

# Test results storage
results = {}

# Check if server is running
check_server

puts "\n" + "🧪 PERFORMANCE TEST SUITE - N+1 Query Fixes" + "\n"
puts "Testing fixes for critical N+1 queries..."
puts "Note: Times include network overhead. Check server logs for actual query counts."

# Test 1: Cow Show Page (Fixed N+1 queries)
results[:cow_show] = test_endpoint(
  "Cow Show Page (N+1 Fixes Applied)",
  "/cows/236"
)

# Test 2: Cows Index Page
results[:cows_index] = test_endpoint(
  "Cows Index Page",
  "/cows"
)

# Test 3: Production Records Enhanced Bulk Entry
results[:bulk_entry] = test_endpoint(
  "Production Records Bulk Entry (N+1 Fixes Applied)",
  "/production_records/enhanced_bulk_entry?farm_id=16&date=#{Date.today}"
)

# Test 4: Dashboard
results[:dashboard] = test_endpoint(
  "Dashboard",
  "/dashboard"
)

# Test 5: Farms Index
results[:farms_index] = test_endpoint(
  "Farms Index (Null Safety Fixes)",
  "/farms"
)

# Summary
puts "\n" + "=" * 60
puts "📊 PERFORMANCE TEST SUMMARY"
puts "=" * 60

results.each do |test, time|
  status = time < 1 ? "🟢 Excellent" : time < 2 ? "🟡 Good" : "🔴 Needs Optimization"
  puts "#{test.to_s.ljust(30)} #{(time * 1000).round(2).to_s.rjust(8)}ms  #{status}"
end

puts "\n" + "=" * 60
puts "✅ Tests Complete!"
puts "=" * 60
puts "\n📝 Check Rails server logs for detailed query information:"
puts "   - Look for reduced query counts"
puts "   - Verify no N+1 warnings from Bullet gem"
puts "   - Check total ActiveRecord query time"
puts "\n"
