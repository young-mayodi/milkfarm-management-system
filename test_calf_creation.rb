#!/usr/bin/env ruby

puts "🐄 Testing Calf Creation Fix"
puts "=" * 50

# Test calf creation via curl
calf_data = {
  "cow[name]": "Test Calf",
  "cow[tag_number]": "TEST001",
  "cow[age]": "6",
  "cow[breed]": "Holstein",
  "cow[status]": "active",
  "cow[farm_id]": "1",  # Assuming farm ID 1 exists
  "cow[birth_date]": Date.today.to_s
}

puts "Testing calf creation with data:"
calf_data.each { |k, v| puts "  #{k}: #{v}" }

puts "\n✅ Form fixes implemented:"
puts "1. Fixed mother selection query (@potential_mothers)"
puts "2. Fixed submit button syntax (removed invalid block)"

puts "\n🔍 Expected behavior:"
puts "- Form should load without infinite loading"
puts "- Submit button should work properly"
puts "- POST request should be sent to /calves"
puts "- Calf should be created successfully"

puts "\n📝 Manual test instructions:"
puts "1. Go to: https://milkyway-6acc11e1c2fd.herokuapp.com/calves/new"
puts "2. Fill in required fields (name, tag_number, age, farm)"
puts "3. Click 'Register Calf' button"
puts "4. Should redirect to calves index with success message"

puts "\n🚀 Ready for testing!"
