Kaminari.configure do |config|
  # Default settings
  config.default_per_page = 20
  config.max_per_page = 100
  config.window = 4
  config.outer_window = 1
  config.left = 0
  config.right = 0

  # Page method name
  config.page_method_name = :page
  config.param_name = :page

  # Maximum pages shown in pagination
  config.max_pages = nil
end
