module DashboardHelper
  def chart_data_json(data)
    data.to_json.html_safe
  end
  
  def chart_options_json(options)
    options.to_json.html_safe
  end
end
