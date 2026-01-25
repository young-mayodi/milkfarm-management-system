module ApplicationHelper
  def chart_data_json(data)
    data.to_json.html_safe
  end

  def chart_options_json(options)
    options.to_json.html_safe
  end

  # Badge classes for health status
  def health_status_badge_class(status)
    case status.to_s.downcase
    when "healthy"
      "bg-success"
    when "sick", "critical"
      "bg-danger"
    when "recovering", "quarantine"
      "bg-warning"
    when "in_heat"
      "bg-info"
    when "injured"
      "bg-secondary"
    else
      "bg-secondary"
    end
  end

  # Badge classes for breeding status
  def breeding_status_badge_class(status)
    case status.to_s.downcase
    when "confirmed"
      "bg-success"
    when "attempted", "pending_confirmation"
      "bg-info"
    when "failed", "aborted"
      "bg-danger"
    when "completed"
      "bg-primary"
    else
      "bg-secondary"
    end
  end
end
