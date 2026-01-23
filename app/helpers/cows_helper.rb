module CowsHelper
  def filter_params
    params.slice(:search, :farm_id, :status, :breed, :age_range, :view).to_unsafe_h
  end
  
  def next_sort_direction(column)
    if params[:sort] == column && params[:direction] == 'asc'
      'desc'
    else
      'asc'
    end
  end
  
  def sort_arrow(column)
    return 'up-down' unless params[:sort] == column
    
    params[:direction] == 'asc' ? 'up' : 'down'
  end
  
  def cow_status_badge_class(status)
    case status
    when 'active'
      'success'
    when 'sick'
      'danger'
    when 'dry'
      'warning'
    when 'pregnant'
      'info'
    when 'retired'
      'secondary'
    else
      'primary'
    end
  end
  
  def production_trend_indicator(current, previous)
    return 'stable' if previous.zero?
    
    percentage_change = ((current - previous) / previous) * 100
    
    if percentage_change > 5
      'up'
    elsif percentage_change < -5
      'down'
    else
      'stable'
    end
  end
  
  def format_production_display(production_value)
    if production_value && production_value > 0
      number_with_precision(production_value, precision: 1) + 'L'
    else
      'No data'
    end
  end
end
