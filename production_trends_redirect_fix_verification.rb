require_relative 'config/environment'
require 'uri'
require 'net/http'

puts "Verifying Production Trends Redirect Issue..."

# Find a valid farm and date
farm = Farm.first
if farm
  puts "Using Farm: #{farm.name} (ID: #{farm.id})"
else
  puts "No farm found, creating test farm..."
  farm = Farm.create!(name: "Test Farm", owner_name: "Test User")
end

controller = ProductionRecordsController.new
# Mock request and params
# This is hard to do without a full request spec. 
# Instead, let's call the method directly and see if it raises.

begin
  # Simulate params
  params = ActionController::Parameters.new({
    farm_id: farm.id,
    start_date: 7.days.ago.to_date.to_s,
    end_date: Date.current.to_s
  })
  
  # We can't easily call controller actions directly in a standalone script without request context
  # But we can try to invoke the helper method that might be failing
  
  puts "Testing `generate_detailed_trends_data`..."
  date_range = 7.days.ago.to_date..Date.current
  
  # We need to access the private method or public if it is public
  # It seems to be public based on indentation in the file provided
  
  begin
    result = controller.send(:generate_detailed_trends_data, date_range, farm)
    if result.is_a?(Hash) && result[:error]
       puts "Result returned generic error structure: #{result.inspect}"
    else
       puts "generate_detailed_trends_data returned success structure."
    end
  rescue => e
    puts "generate_detailed_trends_data RAISED exception: #{e.class} - #{e.message}"
    puts e.backtrace.join("\n")
  end

rescue => e
  puts "Script failed: #{e.message}"
end