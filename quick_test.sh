#!/bin/bash
# Quick System Health Check
# Usage: ./quick_test.sh

echo "=================================="
echo "🏥 QUICK SYSTEM HEALTH CHECK"
echo "=================================="
echo ""

# Check Rails server
echo "📡 Checking Rails server..."
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "  ✅ Server is running"
else
    echo "  ❌ Server is NOT running - Start with: rails server"
    exit 1
fi

# Check database connection
echo ""
echo "🗄️  Checking database..."
rails runner "puts Cow.count rescue 'ERROR'" > /tmp/db_check.txt 2>&1
if grep -q "ERROR" /tmp/db_check.txt; then
    echo "  ❌ Database connection error"
else
    echo "  ✅ Database connected"
fi

# Check key files
echo ""
echo "📁 Checking key files..."
FILES=(
    "app/javascript/controllers/form_validation_controller.js"
    "app/javascript/controllers/loading_controller.js"
    "app/assets/stylesheets/loading.css"
    "config/initializers/rack_attack.rb"
    "config/initializers/rack_timeout.rb"
    "app/controllers/errors_controller.rb"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file MISSING"
    fi
done

# Check services
echo ""
echo "⚙️  Checking services..."
rails runner "
begin
  puts '  ✅ ApplicationService' if defined?(ApplicationService)
  puts '  ✅ ProductionAnalyticsService' if defined?(ProductionAnalyticsService)
  puts '  ✅ AlertEngineService' if defined?(AlertEngineService)
  puts '  ✅ NotificationService' if defined?(NotificationService)
rescue => e
  puts '  ❌ Service error: ' + e.message
end
"

# Check performance
echo ""
echo "⚡ Quick performance check..."
rails runner "
require 'benchmark'
time = Benchmark.realtime { Farm.all.to_a; Cow.count; ProductionRecord.recent.limit(10).to_a }
ms = (time * 1000).round(2)
if ms < 500
  puts '  ✅ Dashboard queries: ' + ms.to_s + 'ms (FAST)'
else
  puts '  ⚠️  Dashboard queries: ' + ms.to_s + 'ms (Could be faster)'
end
"

echo ""
echo "=================================="
echo "✅ Health check complete!"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Run full tests: ruby feature_tests.rb"
echo "2. Test in browser: http://localhost:3000"
echo "3. Read testing guide: TESTING_GUIDE.md"
