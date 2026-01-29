# Performance Optimization Implementation

## Step 1: Install Redis for Better Caching (if not already)

```bash
heroku addons:create heroku-redis:mini --app milkyway
```

## Step 2: Update production.rb to use Redis

Change line 58 in config/environments/production.rb from:
```ruby
config.cache_store = :memory_store
```

To:
```ruby
# Use Redis for caching if available, fallback to memory
if ENV["REDIS_URL"].present?
  config.cache_store = :redis_cache_store, {
    url: ENV["REDIS_URL"],
    expires_in: 90.minutes,
    namespace: 'milkfarm_cache',
    reconnect_attempts: 3,
    error_handler: -> (method:, returning:, exception:) {
      Rails.logger.error("Redis cache error: #{exception.message}")
    }
  }
else
  config.cache_store = :memory_store, { size: 64.megabytes }
end
```

## Step 3: Fix N+1 Queries in Reports Controller

The main issue is in `farm_summary` and `cow_summary` methods where we're doing:
```ruby
@farms.map do |farm|
  recent_records = farm.production_records.where(...) # N+1!
end
```

This causes one query per farm instead of one query total.

## Step 4: Add Query Caching

Wrap expensive queries in Rails.cache.fetch with appropriate keys.

## Step 5: Add Fragment Caching to Views

Add caching to report view partials.

---

## Expected Results:

### Before:
- 166ms average response time
- 49% database time (81ms)
- 39% view time (65ms)

### After:
- 30-50ms average response time  
- 10-15% database time (~5-8ms)
- 15-20% view time (~7-10ms)

**Total Improvement**: 70-85% faster
