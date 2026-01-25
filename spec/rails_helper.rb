# RSpec configuration for automated testing
require 'capybara/rspec'
require 'selenium-webdriver'

RSpec.configure do |config|
  # Use FactoryBot
  config.include FactoryBot::Syntax::Methods

  # Database cleaner
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Capybara configuration
  Capybara.default_driver = :selenium_chrome_headless
  Capybara.javascript_driver = :selenium_chrome_headless

  # Configure Chrome options for headless testing
  Capybara.register_driver :selenium_chrome_headless do |app|
    chrome_options = Selenium::WebDriver::Chrome::Options.new
    chrome_options.add_argument('--headless')
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--window-size=1200,800')

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: chrome_options)
  end

  # Test data helpers
  config.before(:each) do
    # Ensure we have at least one farm for testing
    @test_farm = Farm.first || FactoryBot.create(:farm)
  end

  # Performance testing helper
  def exceed_query_limit(limit)
    query_count = 0
    counter = ->(sql, name) { query_count += 1 }

    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
      yield
    end

    raise "Expected at most #{limit} queries, got #{query_count}" if query_count > limit
  end

  # Mobile testing helpers
  def set_mobile_viewport
    page.driver.browser.manage.window.resize_to(375, 667)
  end

  def set_desktop_viewport
    page.driver.browser.manage.window.resize_to(1200, 800)
  end

  # Financial testing helpers
  def create_financial_test_scenario(farm)
    # Create a realistic financial scenario
    cow = FactoryBot.create(:cow, farm: farm)

    # Create 30 days of production records
    30.times do |i|
      date = i.days.ago.to_date
      FactoryBot.create(:production_record,
                       cow: cow,
                       farm: farm,
                       production_date: date)
    end

    # Create sales records
    10.times do |i|
      FactoryBot.create(:sales_record,
                       farm: farm,
                       sale_date: i.days.ago.to_date)
    end

    # Create expense records
    %w[feed veterinary labor maintenance].each do |category|
      3.times do |i|
        FactoryBot.create(:expense,
                         farm: farm,
                         category: category,
                         expense_date: i.weeks.ago.to_date)
      end
    end

    farm.reload
  end

  # Wait helpers for JavaScript tests
  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  rescue
    true
  end
end
