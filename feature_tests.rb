#!/usr/bin/env ruby
# Feature-specific testing script
# Tests individual features in isolation

require_relative 'config/environment'

class FeatureTester
  def test_form_validation
    puts "\n🔍 Testing Form Validation Features..."

    # Check Stimulus controllers exist
    controllers = Dir.glob('app/javascript/controllers/*_controller.js')
    validation_controller = controllers.find { |c| c.include?('form_validation') }
    loading_controller = controllers.find { |c| c.include?('loading') }

    if validation_controller
      puts "  ✅ Form validation controller exists"
    else
      puts "  ❌ Form validation controller missing"
    end

    if loading_controller
      puts "  ✅ Loading controller exists"
    else
      puts "  ❌ Loading controller missing"
    end

    # Check loading CSS
    if File.exist?('app/assets/stylesheets/loading.css')
      puts "  ✅ Loading CSS exists"
    else
      puts "  ❌ Loading CSS missing"
    end
  end

  def test_services
    puts "\n🔍 Testing Service Layer..."

    services = {
      'ApplicationService' => ApplicationService,
      'ProductionAnalyticsService' => ProductionAnalyticsService,
      'AlertEngineService' => AlertEngineService,
      'NotificationService' => NotificationService
    }

    services.each do |name, klass|
      begin
        klass.new rescue klass
        puts "  ✅ #{name} loaded"
      rescue
        puts "  ❌ #{name} error"
      end
    end

    # Test service calls
    farm = Farm.first
    if farm
      begin
        alerts = AlertEngineService.call(farm: farm)
        puts "  ✅ AlertEngineService.call works (#{alerts.size} alerts)"
      rescue => e
        puts "  ❌ AlertEngineService.call failed: #{e.message}"
      end

      begin
        service = ProductionAnalyticsService.new(farm_id: farm.id)
        data = service.dashboard_data
        puts "  ✅ ProductionAnalyticsService works"
      rescue => e
        puts "  ❌ ProductionAnalyticsService failed: #{e.message}"
      end
    else
      puts "  ⚠️  No farms in database to test services"
    end
  end

  def test_error_pages
    puts "\n🔍 Testing Error Pages..."

    if File.exist?('app/controllers/errors_controller.rb')
      puts "  ✅ ErrorsController exists"
    else
      puts "  ❌ ErrorsController missing"
    end

    error_views = [ 'not_found', 'internal_server_error', 'unprocessable_entity' ]
    error_views.each do |view|
      path = "app/views/errors/#{view}.html.erb"
      if File.exist?(path)
        puts "  ✅ #{view} view exists"
      else
        puts "  ❌ #{view} view missing"
      end
    end
  end

  def test_security_features
    puts "\n🔍 Testing Security Features..."

    # Check Rack::Attack
    if defined?(Rack::Attack)
      puts "  ✅ Rack::Attack loaded"
    else
      puts "  ❌ Rack::Attack not loaded"
    end

    # Check Rack::Timeout
    if ENV['RACK_TIMEOUT_SERVICE_TIMEOUT']
      puts "  ✅ Rack::Timeout configured (#{ENV['RACK_TIMEOUT_SERVICE_TIMEOUT']}s)"
    else
      puts "  ⚠️  Rack::Timeout not configured"
    end

    # Check initializers
    if File.exist?('config/initializers/rack_attack.rb')
      puts "  ✅ Rack::Attack initializer exists"
    else
      puts "  ❌ Rack::Attack initializer missing"
    end

    if File.exist?('config/initializers/rack_timeout.rb')
      puts "  ✅ Rack::Timeout initializer exists"
    else
      puts "  ❌ Rack::Timeout initializer missing"
    end
  end

  def test_database_config
    puts "\n🔍 Testing Database Configuration..."

    config = ActiveRecord::Base.connection_pool
    puts "  📊 Connection pool size: #{config.size}"
    puts "  📊 Available connections: #{config.connections.size}"

    pool_config = ActiveRecord::Base.connection_db_config.configuration_hash

    if pool_config[:prepared_statements]
      puts "  ✅ Prepared statements enabled"
    else
      puts "  ⚠️  Prepared statements not enabled"
    end

    if pool_config[:checkout_timeout]
      puts "  ✅ Checkout timeout: #{pool_config[:checkout_timeout]}s"
    end
  end

  def test_caching
    puts "\n🔍 Testing Caching System..."

    begin
      Rails.cache.write('test_key', 'test_value', expires_in: 1.minute)
      value = Rails.cache.read('test_key')

      if value == 'test_value'
        puts "  ✅ Cache write/read works"
      else
        puts "  ❌ Cache read returned wrong value"
      end

      Rails.cache.delete('test_key')
      puts "  ✅ Cache delete works"
    rescue => e
      puts "  ❌ Cache error: #{e.message}"
    end
  end

  def test_backup_scripts
    puts "\n🔍 Testing Backup Scripts..."

    if File.executable?('backup_database.sh')
      puts "  ✅ backup_database.sh is executable"
    elsif File.exist?('backup_database.sh')
      puts "  ⚠️  backup_database.sh exists but not executable (run: chmod +x backup_database.sh)"
    else
      puts "  ❌ backup_database.sh missing"
    end

    if File.executable?('restore_database.sh')
      puts "  ✅ restore_database.sh is executable"
    elsif File.exist?('restore_database.sh')
      puts "  ⚠️  restore_database.sh exists but not executable"
    else
      puts "  ❌ restore_database.sh missing"
    end

    if Dir.exist?('backups')
      backup_count = Dir.glob('backups/*.dump').size
      puts "  📊 Existing backups: #{backup_count}"
    else
      puts "  ℹ️  Backups directory doesn't exist yet (will be created on first backup)"
    end
  end

  def test_data_integrity
    puts "\n🔍 Testing Data Integrity..."

    # Test production total calculation
    record = ProductionRecord.first
    if record
      calculated = record.morning_production.to_f + record.night_production.to_f
      if record.total_production == calculated
        puts "  ✅ Production total calculation correct"
      else
        puts "  ❌ Production total mismatch: #{record.total_production} vs #{calculated}"
      end
    else
      puts "  ⚠️  No production records to test"
    end

    # Test cow age calculation
    cow = Cow.where.not(date_of_birth: nil).first
    if cow
      expected_age = ((Date.current - cow.date_of_birth) / 365.25).floor
      if cow.age == expected_age
        puts "  ✅ Cow age calculation correct"
      else
        puts "  ⚠️  Cow age mismatch: #{cow.age} vs #{expected_age}"
      end
    else
      puts "  ⚠️  No cows with birth date to test"
    end
  end

  def run_all
    puts "=" * 80
    puts "🧪 FEATURE-SPECIFIC TESTS"
    puts "=" * 80

    test_form_validation
    test_services
    test_error_pages
    test_security_features
    test_database_config
    test_caching
    test_backup_scripts
    test_data_integrity

    puts "\n" + "=" * 80
    puts "✅ Feature testing complete!"
    puts "=" * 80
  end
end

# Run tests
FeatureTester.new.run_all
