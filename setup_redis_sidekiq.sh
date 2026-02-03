#!/bin/bash
# Redis and Sidekiq Setup Script for Heroku/Railway

echo "================================"
echo "Redis & Sidekiq Setup"
echo "================================"
echo

# Check if REDIS_URL is set
if [ -z "$REDIS_URL" ]; then
  echo "⚠️  REDIS_URL environment variable not set"
  echo
  echo "To set up Redis:"
  echo
  echo "For Heroku:"
  echo "  heroku addons:create heroku-redis:mini -a YOUR_APP_NAME"
  echo "  # Or use hobby tier:"
  echo "  heroku addons:create heroku-redis:hobby-dev -a YOUR_APP_NAME"
  echo
  echo "For Railway:"
  echo "  1. Go to Railway dashboard"
  echo "  2. Add 'Redis' service from marketplace"
  echo "  3. Connect it to your application"
  echo "  4. REDIS_URL will be automatically set"
  echo
  echo "For local development:"
  echo "  brew install redis  # macOS"
  echo "  redis-server  # Start Redis"
  echo "  export REDIS_URL=redis://localhost:6379/0"
  echo
else
  echo "✅ REDIS_URL is set"
  echo "   ${REDIS_URL:0:30}..."
  echo
fi

# Install dependencies
echo "Installing dependencies..."
bundle install

# Run database migrations
echo "Running migrations..."
bundle exec rails db:migrate

# Reset counter caches
echo "Resetting counter caches..."
bundle exec rails runner '
  puts "Updating Farm counter caches..."
  Farm.find_each do |farm|
    Farm.reset_counters(farm.id, :production_records)
    Farm.reset_counters(farm.id, :cows)
  end
  
  puts "Updating Cow counter caches..."
  Cow.find_each do |cow|
    Cow.reset_counters(cow.id, :production_records)
    Cow.reset_counters(cow.id, :health_records)
    Cow.reset_counters(cow.id, :breeding_records)
    Cow.reset_counters(cow.id, :vaccination_records)
  end
  
  puts "✅ Counter caches updated"
'

echo
echo "================================"
echo "Setup Complete!"
echo "================================"
echo
echo "Next steps:"
echo "1. Start Redis (if running locally):"
echo "   redis-server"
echo
echo "2. Start Sidekiq worker:"
echo "   bundle exec sidekiq -C config/sidekiq.yml"
echo
echo "3. Start Rails server:"
echo "   rails server"
echo
echo "4. View Sidekiq dashboard:"
echo "   http://localhost:3000/sidekiq"
echo
echo "For production deployment:"
echo "  git add ."
echo "  git commit -m 'Add Redis and Sidekiq performance optimizations'"
echo "  git push heroku main"
echo "  # or"
echo "  git push origin main  # for Railway"
echo
