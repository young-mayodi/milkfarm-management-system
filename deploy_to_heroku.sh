#!/bin/bash

# Heroku Deployment Script for Livestock Management System
# ===========================================================

set -e

echo "🚀 Starting Heroku Deployment for Livestock Management System"
echo "============================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Heroku CLI is installed
if ! command -v heroku &> /dev/null; then
    print_error "Heroku CLI not found. Please install it first:"
    echo "  brew tap heroku/brew && brew install heroku"
    exit 1
fi

print_success "Heroku CLI found"

# Check if user is logged in to Heroku
if ! heroku auth:whoami &> /dev/null; then
    print_warning "Not logged in to Heroku. Please login:"
    heroku login
fi

print_success "Logged in to Heroku as $(heroku auth:whoami)"

# Ask for app name
echo ""
print_status "Enter your Heroku app name (or press Enter for auto-generated name):"
read -r APP_NAME

# Create Heroku app
if [ -z "$APP_NAME" ]; then
    print_status "Creating Heroku app with auto-generated name..."
    heroku create
    APP_NAME=$(heroku info --json | grep '"name"' | cut -d'"' -f4)
else
    print_status "Creating Heroku app: $APP_NAME"
    if heroku create "$APP_NAME"; then
        print_success "App created successfully"
    else
        print_error "Failed to create app. App name might be taken."
        print_status "Trying to use existing app..."
        heroku git:remote -a "$APP_NAME"
    fi
fi

print_success "Using Heroku app: $APP_NAME"

# Configure buildpacks
print_status "Configuring buildpacks..."
heroku buildpacks:clear --app "$APP_NAME"
heroku buildpacks:add heroku/nodejs --app "$APP_NAME"
heroku buildpacks:add heroku/ruby --app "$APP_NAME"
print_success "Buildpacks configured"

# Add PostgreSQL addon
print_status "Adding PostgreSQL addon..."
if heroku addons:create heroku-postgresql:mini --app "$APP_NAME"; then
    print_success "PostgreSQL addon added"
else
    print_warning "PostgreSQL addon might already exist"
fi

# Add Redis addon for caching and background jobs
print_status "Adding Redis addon..."
if heroku addons:create heroku-redis:mini --app "$APP_NAME"; then
    print_success "Redis addon added"
else
    print_warning "Redis addon might already exist"
fi

# Set environment variables
print_status "Setting environment variables..."

# Set Rails environment
heroku config:set RAILS_ENV=production --app "$APP_NAME"

# Generate and set secret key base
SECRET_KEY_BASE=$(openssl rand -hex 64)
heroku config:set SECRET_KEY_BASE="$SECRET_KEY_BASE" --app "$APP_NAME"

# Set Rails master key
if [ -f "config/master.key" ]; then
    MASTER_KEY=$(cat config/master.key)
    heroku config:set RAILS_MASTER_KEY="$MASTER_KEY" --app "$APP_NAME"
    print_success "Rails master key set"
else
    print_warning "config/master.key not found. You may need to set RAILS_MASTER_KEY manually."
fi

# Set performance and scaling variables
heroku config:set RAILS_MAX_THREADS=5 --app "$APP_NAME"
heroku config:set WEB_CONCURRENCY=2 --app "$APP_NAME"
heroku config:set RAILS_SERVE_STATIC_FILES=true --app "$APP_NAME"
heroku config:set RAILS_LOG_TO_STDOUT=true --app "$APP_NAME"

# Set timezone
heroku config:set TZ="UTC" --app "$APP_NAME"

print_success "Environment variables set"

# Ensure we're in the right directory and have the latest changes
print_status "Preparing for deployment..."

# Check if there are uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    print_warning "You have uncommitted changes. Committing them now..."
    git add -A
    git commit -m "Prepare for Heroku deployment - $(date)"
fi

# Deploy to Heroku
print_status "Deploying to Heroku..."
echo "This may take several minutes..."

if git push heroku main; then
    print_success "Deployment completed successfully!"
else
    print_error "Deployment failed. Checking logs..."
    heroku logs --tail --app "$APP_NAME"
    exit 1
fi

# Run database migration
print_status "Running database migrations..."
if heroku run rails db:migrate --app "$APP_NAME"; then
    print_success "Database migrations completed"
else
    print_error "Database migration failed"
    heroku logs --app "$APP_NAME"
fi

# Run database seeds (optional)
print_status "Do you want to run database seeds? (y/n):"
read -r RUN_SEEDS

if [ "$RUN_SEEDS" = "y" ] || [ "$RUN_SEEDS" = "Y" ]; then
    print_status "Running database seeds..."
    if heroku run rails db:seed --app "$APP_NAME"; then
        print_success "Database seeds completed"
    else
        print_warning "Database seeds failed or no seeds to run"
    fi
fi

# Scale dynos
print_status "Scaling dynos..."
heroku ps:scale web=1 worker=0 --app "$APP_NAME"
print_success "Dynos scaled"

# Open the application
print_status "Opening application in browser..."
heroku open --app "$APP_NAME"

# Show app info
echo ""
print_success "🎉 Deployment Complete!"
echo ""
print_status "App Details:"
echo "  📱 App Name: $APP_NAME"
echo "  🌐 URL: https://$APP_NAME.herokuapp.com"
echo "  📊 Dashboard: https://dashboard.heroku.com/apps/$APP_NAME"
echo ""

print_status "Useful Commands:"
echo "  📋 View logs:           heroku logs --tail --app $APP_NAME"
echo "  🔄 Restart app:         heroku restart --app $APP_NAME"
echo "  💾 Run console:         heroku run rails console --app $APP_NAME"
echo "  🗄️  Run migrations:      heroku run rails db:migrate --app $APP_NAME"
echo "  🌱 Run seeds:           heroku run rails db:seed --app $APP_NAME"
echo "  📈 View metrics:        heroku addons:open heroku-postgresql --app $APP_NAME"
echo ""

# Performance optimization for Heroku
print_status "Setting up performance optimizations..."

# Enable log-runtime-metrics
heroku labs:enable log-runtime-metrics --app "$APP_NAME"

# Configure Puma for Heroku
heroku config:set PUMA_WORKERS=2 --app "$APP_NAME"

print_success "Performance optimizations enabled"

# Show final status
print_status "Final deployment verification..."
if heroku ps --app "$APP_NAME" | grep -q "web.1"; then
    print_success "✅ Web dyno is running"
else
    print_warning "⚠️  Web dyno might not be running properly"
fi

echo ""
print_success "🚀 Livestock Management System successfully deployed to Heroku!"
print_status "Visit https://$APP_NAME.herokuapp.com to see your application"
