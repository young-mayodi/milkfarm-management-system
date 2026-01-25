#!/usr/bin/env ruby
# Test script to verify edit forms are working correctly

require_relative 'config/environment'

puts "🔬 Testing Edit Forms for Livestock Management System"
puts "=" * 60

# Test that models exist and have proper attributes
def test_models
  puts "\n📊 Testing Models..."

  begin
    # Test HealthRecord model
    health_attrs = HealthRecord.attribute_names
    puts "✅ HealthRecord model: #{health_attrs.join(', ')}"

    # Test VaccinationRecord model
    vaccination_attrs = VaccinationRecord.attribute_names
    puts "✅ VaccinationRecord model: #{vaccination_attrs.join(', ')}"

    # Test BreedingRecord model
    breeding_attrs = BreedingRecord.attribute_names
    puts "✅ BreedingRecord model: #{breeding_attrs.join(', ')}"

    true
  rescue => e
    puts "❌ Model test failed: #{e.message}"
    false
  end
end

# Test that edit routes exist
def test_routes
  puts "\n🛣️  Testing Routes..."

  begin
    routes = Rails.application.routes.routes.map(&:path).map(&:spec)

    health_edit = routes.any? { |route| route.include?('health_records') && route.include?('edit') }
    vaccination_edit = routes.any? { |route| route.include?('vaccination_records') && route.include?('edit') }
    breeding_edit = routes.any? { |route| route.include?('breeding_records') && route.include?('edit') }

    puts health_edit ? "✅ Health Records edit route exists" : "❌ Health Records edit route missing"
    puts vaccination_edit ? "✅ Vaccination Records edit route exists" : "❌ Vaccination Records edit route missing"
    puts breeding_edit ? "✅ Breeding Records edit route exists" : "❌ Breeding Records edit route missing"

    health_edit && vaccination_edit && breeding_edit
  rescue => e
    puts "❌ Route test failed: #{e.message}"
    false
  end
end

# Test that edit view files exist
def test_view_files
  puts "\n📄 Testing View Files..."

  health_edit_exists = File.exist?('app/views/health_records/edit.html.erb')
  vaccination_edit_exists = File.exist?('app/views/vaccination_records/edit.html.erb')
  breeding_edit_exists = File.exist?('app/views/breeding_records/edit.html.erb')

  puts health_edit_exists ? "✅ Health Records edit.html.erb exists" : "❌ Health Records edit.html.erb missing"
  puts vaccination_edit_exists ? "✅ Vaccination Records edit.html.erb exists" : "❌ Vaccination Records edit.html.erb missing"
  puts breeding_edit_exists ? "✅ Breeding Records edit.html.erb exists" : "❌ Breeding Records edit.html.erb missing"

  health_edit_exists && vaccination_edit_exists && breeding_edit_exists
end

# Test that controllers have edit actions
def test_controller_actions
  puts "\n🎮 Testing Controller Actions..."

  begin
    # Check if controllers exist and have edit methods
    health_controller = HealthRecordsController.new
    vaccination_controller = VaccinationRecordsController.new
    breeding_controller = BreedingRecordsController.new

    health_has_edit = health_controller.respond_to?(:edit)
    vaccination_has_edit = vaccination_controller.respond_to?(:edit)
    breeding_has_edit = breeding_controller.respond_to?(:edit)

    puts health_has_edit ? "✅ HealthRecordsController has edit action" : "❌ HealthRecordsController missing edit action"
    puts vaccination_has_edit ? "✅ VaccinationRecordsController has edit action" : "❌ VaccinationRecordsController missing edit action"
    puts breeding_has_edit ? "✅ BreedingRecordsController has edit action" : "❌ BreedingRecordsController missing edit action"

    health_has_edit && vaccination_has_edit && breeding_has_edit
  rescue => e
    puts "❌ Controller test failed: #{e.message}"
    false
  end
end

# Test sample data creation (optional)
def test_sample_data_creation
  puts "\n🌱 Testing Sample Data Creation..."

  begin
    # Check if we have at least one cow to work with
    cow_count = Cow.count
    puts "📈 Total cows in system: #{cow_count}"

    if cow_count == 0
      puts "⚠️  No cows found - creating sample cow for testing..."

      # Create a sample farm if needed
      farm = Farm.first || Farm.create!(
        name: "Test Farm",
        location: "Test Location",
        owner_name: "Test Owner"
      )

      # Create a sample cow
      cow = Cow.create!(
        tag_number: "TEST001",
        breed: "Holstein",
        date_of_birth: 3.years.ago,
        farm: farm,
        gender: "female"
      )

      puts "✅ Sample cow created: #{cow.tag_number}"
      cow
    else
      puts "✅ Sample data exists"
      Cow.first
    end

  rescue => e
    puts "❌ Sample data creation failed: #{e.message}"
    nil
  end
end

# Main test runner
def run_tests
  puts "\n🚀 Running Edit Forms Tests..."

  models_ok = test_models
  routes_ok = test_routes
  views_ok = test_view_files
  controllers_ok = test_controller_actions
  sample_cow = test_sample_data_creation

  puts "\n" + "=" * 60
  puts "📋 TEST RESULTS SUMMARY"
  puts "=" * 60

  puts "Models: #{models_ok ? '✅ PASS' : '❌ FAIL'}"
  puts "Routes: #{routes_ok ? '✅ PASS' : '❌ FAIL'}"
  puts "Views: #{views_ok ? '✅ PASS' : '❌ FAIL'}"
  puts "Controllers: #{controllers_ok ? '✅ PASS' : '❌ FAIL'}"
  puts "Sample Data: #{sample_cow ? '✅ PASS' : '❌ FAIL'}"

  all_tests_passed = models_ok && routes_ok && views_ok && controllers_ok

  puts "\n🎯 OVERALL RESULT: #{all_tests_passed ? '✅ ALL TESTS PASSED' : '❌ SOME TESTS FAILED'}"

  if all_tests_passed
    puts "\n🎉 Edit forms are ready for testing!"
    puts "You can now:"
    puts "1. Navigate to any health, vaccination, or breeding record"
    puts "2. Click the 'Edit' button"
    puts "3. Test the form functionality"
    puts "4. Verify data updates correctly"
  end

  all_tests_passed
end

# Run the tests
run_tests
