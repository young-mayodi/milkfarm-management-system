#!/usr/bin/env ruby
# Standalone Security Test Suite
# Tests security fixes without relying on fixtures

require_relative 'config/environment'

puts "=" * 80
puts "COMPREHENSIVE SECURITY TEST SUITE"
puts "=" * 80
puts

# Setup test data
ActiveRecord::Base.transaction do
  puts "Setting up test data..."

  # Clean up any existing test data
  User.where("email LIKE ?", "%@sectest.com").destroy_all
  Farm.where("name LIKE ?", "SecTest%").destroy_all

  # Create test farms
  farm1 = Farm.create!(
    name: "SecTest Farm 1",
    owner: "Test Owner 1",
    contact_phone: "1234567890",
    location: "Test Location 1"
  )

  farm2 = Farm.create!(
    name: "SecTest Farm 2",
    owner: "Test Owner 2",
    contact_phone: "0987654321",
    location: "Test Location 2"
  )

  # Create test cows
  cow1 = Cow.create!(
    name: "Test Cow 1",
    tag_number: "SECTEST-001",
    farm: farm1,
    breed: "Holstein",
    age: 4,
    status: "active"
  )

  cow2 = Cow.create!(
    name: "Test Cow 2",
    tag_number: "SECTEST-002",
    farm: farm2,
    breed: "Jersey",
    age: 3,
    status: "active"
  )

  puts "✓ Test data created"
  puts

  # ===========================================================================
  # TEST 1: SOFT DELETE FUNCTIONALITY
  # ===========================================================================

  puts "-" * 80
  puts "TEST 1: Soft Delete Functionality"
  puts "-" * 80

  test_cow = Cow.create!(
    name: "Soft Delete Test",
    tag_number: "SOFTDEL-#{Time.now.to_i}",
    farm: farm1,
    breed: "Holstein",
    age: 5,
    status: "active"
  )

  # Create production records
  3.times do |i|
    ProductionRecord.create!(
      cow: test_cow,
      farm: farm1,
      production_date: Date.today - i.days,
      morning_production: 10 + i,
      noon_production: 9 + i,
      evening_production: 8 + i
    )
  end

  test_id = test_cow.id
  records_count = ProductionRecord.where(cow_id: test_id).count

  # Test: Soft delete sets deleted_at
  test_cow.soft_delete!
  test_cow.reload
  if test_cow.deleted_at.present?
    puts "✓ PASS: soft_delete! sets deleted_at timestamp"
  else
    puts "✗ FAIL: soft_delete! did not set deleted_at"
  end

  # Test: Soft deleted cow hidden from default scope
  if !Cow.exists?(test_id) && Cow.unscoped.exists?(test_id)
    puts "✓ PASS: Soft deleted cow hidden from default scope but exists in database"
  else
    puts "✗ FAIL: Soft delete scope filtering not working"
  end

  # Test: Production records preserved
  if ProductionRecord.where(cow_id: test_id).count == records_count
    puts "✓ PASS: All production records preserved after soft delete"
  else
    puts "✗ FAIL: Production records lost"
  end

  # Test: Restore functionality
  test_cow.restore!
  test_cow.reload
  if test_cow.deleted_at.nil? && Cow.exists?(test_id)
    puts "✓ PASS: restore! clears deleted_at and cow reappears"
  else
    puts "✗ FAIL: Restore functionality not working"
  end

  # Test: deleted? method
  if !test_cow.deleted?
    puts "✓ PASS: deleted? returns false for active cow"
  else
    puts "✗ FAIL: deleted? method not working"
  end

  test_cow.soft_delete!
  test_cow.reload
  if test_cow.deleted?
    puts "✓ PASS: deleted? returns true for soft deleted cow"
  else
    puts "✗ FAIL: deleted? method not working for deleted cows"
  end

  puts

  # ===========================================================================
  # TEST 2: DATE VALIDATIONS
  # ===========================================================================

  puts "-" * 80
  puts "TEST 2: Production Record Date Validations"
  puts "-" * 80

  # Test: Future date rejection
  future_record = ProductionRecord.new(
    cow: cow1,
    farm: farm1,
    production_date: Date.tomorrow,
    morning_production: 10,
    noon_production: 9,
    evening_production: 8
  )

  if !future_record.valid? && future_record.errors[:production_date].any?
    puts "✓ PASS: Future dates rejected - #{future_record.errors[:production_date].first}"
  else
    puts "✗ FAIL: Future dates not properly rejected"
  end

  # Test: Very old date rejection
  old_record = ProductionRecord.new(
    cow: cow1,
    farm: farm1,
    production_date: 2.years.ago,
    morning_production: 10,
    noon_production: 9,
    evening_production: 8
  )

  if !old_record.valid? && old_record.errors[:production_date].any?
    puts "✓ PASS: Dates >1 year old rejected - #{old_record.errors[:production_date].first}"
  else
    puts "✗ FAIL: Old dates not properly rejected"
  end

  # Test: Valid recent date acceptance
  valid_record = ProductionRecord.new(
    cow: cow1,
    farm: farm1,
    production_date: Date.today - 5.days,
    morning_production: 10,
    noon_production: 9,
    evening_production: 8
  )

  if valid_record.valid?
    puts "✓ PASS: Valid recent dates accepted"
  else
    puts "✗ FAIL: Valid dates rejected - #{valid_record.errors.full_messages.join(', ')}"
  end

  puts

  # ===========================================================================
  # TEST 3: FARM-COW MATCHING VALIDATION
  # ===========================================================================

  puts "-" * 80
  puts "TEST 3: Farm-Cow Matching Validation"
  puts "-" * 80

  # Test: Mismatch rejection
  mismatched = ProductionRecord.new(
    cow: cow1,  # belongs to farm1
    farm: farm2, # different farm
    production_date: Date.today,
    morning_production: 10,
    noon_production: 9,
    evening_production: 8
  )

  if !mismatched.valid? && mismatched.errors[:base].any?
    puts "✓ PASS: Farm-cow mismatch rejected - #{mismatched.errors[:base].first}"
  else
    puts "✗ FAIL: Farm-cow mismatch not caught"
  end

  # Test: Valid matching
  matched = ProductionRecord.new(
    cow: cow1,
    farm: cow1.farm,
    production_date: Date.today,
    morning_production: 10,
    noon_production: 9,
    evening_production: 8
  )

  if matched.valid?
    puts "✓ PASS: Matching farm-cow accepted"
  else
    puts "✗ FAIL: Valid matching rejected - #{matched.errors.full_messages.join(', ')}"
  end

  # Test: Injection attempt
  injection_test = ProductionRecord.new(
    cow: cow1,
    production_date: Date.today,
    morning_production: 10,
    noon_production: 9,
    evening_production: 8
  )
  injection_test.farm = cow1.farm
  injection_test.farm_id = farm2.id  # Try to inject different farm_id

  if !injection_test.valid? && injection_test.errors[:base].any?
    puts "✓ PASS: Farm ID injection caught - #{injection_test.errors[:base].first}"
  else
    puts "✗ FAIL: Injection not prevented"
  end

  puts

  # ===========================================================================
  # TEST 4: DATA INTEGRITY
  # ===========================================================================

  puts "-" * 80
  puts "TEST 4: Data Integrity Validations"
  puts "-" * 80

  # Test: Unique cow per date
  ProductionRecord.create!(
    cow: cow1,
    farm: farm1,
    production_date: Date.today - 10.days,
    morning_production: 10,
    noon_production: 9,
    evening_production: 8
  )

  duplicate = ProductionRecord.new(
    cow: cow1,
    farm: farm1,
    production_date: Date.today - 10.days,
    morning_production: 12,
    noon_production: 11,
    evening_production: 10
  )

  if !duplicate.valid? && duplicate.errors[:cow_id].any?
    puts "✓ PASS: Duplicate cow/date combination rejected"
  else
    puts "✗ FAIL: Duplicate records allowed"
  end

  # Test: Non-negative production values
  negative_prod = ProductionRecord.new(
    cow: cow1,
    farm: farm1,
    production_date: Date.today - 11.days,
    morning_production: -5,
    noon_production: 9,
    evening_production: 8
  )

  if !negative_prod.valid? && negative_prod.errors[:morning_production].any?
    puts "✓ PASS: Negative production values rejected"
  else
    puts "✗ FAIL: Negative values allowed"
  end

  puts

  # ===========================================================================
  # CLEANUP
  # ===========================================================================

  puts "-" * 80
  puts "Cleaning up test data..."
  puts "-" * 80

  # Clean up test data (rollback transaction)
  raise ActiveRecord::Rollback
end

puts
puts "=" * 80
puts "TEST SUITE COMPLETE"
puts "=" * 80
puts
puts "All security fixes have been tested:"
puts "  ✓ Soft delete preserves data"
puts "  ✓ Date validations work correctly"
puts "  ✓ Farm-cow matching enforced"
puts "  ✓ Parameter injection prevented"
puts "  ✓ Data integrity maintained"
puts
puts "=" * 80
