# frozen_string_literal: true

class Rack::Attack
  ### Configure Cache ###

  # If you don't want to use Rails.cache (Rack::Attack's default), uncomment this:
  # Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Spammy Clients ###

  # Throttle all requests by IP (60 requests per minute)
  throttle("req/ip", limit: 60, period: 1.minute) do |req|
    req.ip
  end

  # Throttle POST requests to /login by IP address
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # Throttle POST requests to /login by email param
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Normalize email to prevent case-sensitivity bypasses
      req.params["email"].to_s.downcase.presence
    end
  end

  ### Prevent Brute-Force Login Attacks ###

  # Block IP addresses that have made more than 10 failed login attempts in 5 minutes
  blocklist("fail2ban pentesters") do |req|
    # `filter` returns truthy value if request fails, or if it's from a previously banned IP
    # so request is blocked
    Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 10, findtime: 5.minutes, bantime: 10.minutes) do
      # The count for the IP is incremented if the return value is truthy
      req.path == "/users/sign_in" && req.post?
    end
  end

  ### Custom Throttle Response ###

  # Return a 429 (Too Many Requests) status code
  self.throttled_responder = lambda do |env|
    retry_after = (env["rack.attack.match_data"] || {})[:period]
    [
      429,
      {
        "Content-Type" => "text/html",
        "Retry-After" => retry_after.to_s
      },
      [ "<html><body><h1>Too Many Requests</h1><p>You have made too many requests. Please try again in #{retry_after} seconds.</p></body></html>" ]
    ]
  end

  ### Logging ###

  # Log blocked requests
  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
    req = payload[:request]
    if req.env["rack.attack.matched"]
      Rails.logger.warn("[Rack::Attack] #{req.env['rack.attack.match_type']} #{req.ip} #{req.request_method} #{req.fullpath}")
    end
  end
end
