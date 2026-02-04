if defined?(Bugsnag)
  Bugsnag.configure do |config|
    config.api_key = ENV['BUGSNAG_API_KEY'] || "2672ee0b55d434f8f910b27eceebca73"
    config.notify_release_stages = %w[production staging]
    config.release_stage = ENV['RAILS_ENV'] || 'development'
  end
end
