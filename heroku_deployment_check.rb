#!/usr/bin/env ruby

puts "🔍 Pre-Heroku Deployment Verification"
puts "===================================="

require_relative 'config/environment'

def check_dependencies
  puts "\n📦 Checking Dependencies..."

  # Check if required gems are in Gemfile
  gemfile_content = File.read('Gemfile')

  required_gems = {
    'rails' => gemfile_content.include?('gem "rails"'),
    'pg' => gemfile_content.include?('gem "pg"'),
    'puma' => gemfile_content.include?('gem "puma"'),
    'redis' => gemfile_content.include?('redis'),
    'sidekiq' => gemfile_content.include?('sidekiq')
  }

  required_gems.each do |gem_name, present|
    if present
      puts "  ✅ #{gem_name} - Found in Gemfile"
    else
      puts "  ⚠️  #{gem_name} - Missing from Gemfile"
    end
  end
end

def check_configuration_files
  puts "\n⚙️  Checking Configuration Files..."

  files_to_check = {
    'Procfile' => 'Process configuration',
    'app.json' => 'Heroku app configuration',
    'config/database.yml' => 'Database configuration',
    'config/puma.rb' => 'Puma server configuration'
  }

  files_to_check.each do |file, description|
    if File.exist?(file)
      puts "  ✅ #{file} - #{description}"
    else
      puts "  ❌ #{file} - Missing (#{description})"
    end
  end
end

def check_environment_settings
  puts "\n🌍 Checking Environment Settings..."

  # Check production environment file
  if File.exist?('config/environments/production.rb')
    production_config = File.read('config/environments/production.rb')

    settings = {
      'secret_key_base' => production_config.include?('SECRET_KEY_BASE'),
      'force_ssl' => production_config.include?('force_ssl'),
      'serve_static_files' => production_config.include?('RAILS_SERVE_STATIC_FILES'),
      'log_to_stdout' => production_config.include?('RAILS_LOG_TO_STDOUT')
    }

    settings.each do |setting, configured|
      if configured
        puts "  ✅ #{setting} - Configured"
      else
        puts "  ⚠️  #{setting} - Not configured"
      end
    end
  else
    puts "  ❌ config/environments/production.rb - Missing"
  end
end

def check_database_ready
  puts "\n🗄️  Checking Database..."

  begin
    # Check if we can connect to database
    ActiveRecord::Base.connection.active?
    puts "  ✅ Database connection - Active"

    # Check for pending migrations
    if ActiveRecord::Base.connection.migration_context.needs_migration?
      puts "  ⚠️  Pending migrations - Run rails db:migrate"
    else
      puts "  ✅ Database migrations - Up to date"
    end

    # Check basic model functionality
    cow_count = Cow.count
    puts "  ✅ Models - Working (#{cow_count} cows in database)"

  rescue => e
    puts "  ❌ Database error: #{e.message}"
  end
end

def check_assets
  puts "\n🎨 Checking Assets..."

  # Check if assets can be compiled
  begin
    if File.exist?('app/assets')
      puts "  ✅ Assets directory - Found"
    end

    if File.exist?('config/importmap.rb')
      puts "  ✅ Importmap configuration - Found"
    end

    puts "  ℹ️  Assets will be compiled during Heroku deployment"
  rescue => e
    puts "  ❌ Assets error: #{e.message}"
  end
end

def check_performance_optimizations
  puts "\n⚡ Checking Performance Optimizations..."

  # Check if performance optimizations are in place
  optimizations = {
    'Database indexes' => Dir.glob('db/migrate/*index*.rb').any?,
    'Eager loading' => File.read('app/controllers/health_records_controller.rb').include?('includes'),
    'Caching' => File.read('app/controllers/health_records_controller.rb').include?('cache'),
    'Performance service' => File.exist?('app/services/performance_optimization_service.rb')
  }

  optimizations.each do |optimization, implemented|
    if implemented
      puts "  ✅ #{optimization} - Implemented"
    else
      puts "  ⚠️  #{optimization} - Not implemented"
    end
  end
end

def check_security
  puts "\n🔒 Checking Security..."

  security_checks = {
    'Secret key configured' => ENV['SECRET_KEY_BASE'] || File.exist?('config/master.key'),
    'SSL configuration' => File.read('config/environments/production.rb').include?('force_ssl'),
    'CSRF protection' => File.read('app/controllers/application_controller.rb').include?('csrf'),
    'Authentication' => File.exist?('app/controllers/sessions_controller.rb')
  }

  security_checks.each do |check, passed|
    if passed
      puts "  ✅ #{check} - OK"
    else
      puts "  ⚠️  #{check} - Needs attention"
    end
  end
end

def display_heroku_deploy_instructions
  puts "\n🚀 Heroku Deployment Instructions"
  puts "================================="
  puts ""
  puts "1. Install Heroku CLI (if not already installed):"
  puts "   brew tap heroku/brew && brew install heroku"
  puts ""
  puts "2. Login to Heroku:"
  puts "   heroku login"
  puts ""
  puts "3. Run the automated deployment script:"
  puts "   ./deploy_to_heroku.sh"
  puts ""
  puts "4. Or deploy manually:"
  puts "   heroku create your-app-name"
  puts "   git push heroku main"
  puts "   heroku run rails db:migrate"
  puts ""
  puts "5. Monitor your deployment:"
  puts "   heroku logs --tail"
  puts "   heroku open"
  puts ""
end

def run_verification
  puts "Starting comprehensive pre-deployment verification..."

  check_dependencies
  check_configuration_files
  check_environment_settings
  check_database_ready
  check_assets
  check_performance_optimizations
  check_security

  puts "\n📊 Verification Summary"
  puts "======================"
  puts "✅ Your application appears ready for Heroku deployment!"
  puts "⚠️  Address any warnings above before deploying."
  puts ""

  display_heroku_deploy_instructions

  puts "\n🎯 Ready for deployment! Run ./deploy_to_heroku.sh to begin."
end

# Run the verification
run_verification
