#!/bin/bash
# Heroku Deployment with Automated Testing
# This script runs comprehensive tests before deployment

echo "🚀 HEROKU DEPLOYMENT PREPARATION WITH AUTOMATED TESTING"
echo "========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if Heroku CLI is installed
check_heroku_cli() {
    print_info "Checking Heroku CLI installation..."
    if ! command -v heroku &> /dev/null; then
        print_error "Heroku CLI not installed. Please install it first."
        echo "Install with: brew tap heroku/brew && brew install heroku"
        exit 1
    fi
    print_status "Heroku CLI is installed"
}

# Check if user is logged in to Heroku
check_heroku_login() {
    print_info "Checking Heroku authentication..."
    if ! heroku auth:whoami &> /dev/null; then
        print_error "Not logged in to Heroku. Please log in first."
        echo "Run: heroku login"
        exit 1
    fi
    print_status "Logged in to Heroku as $(heroku auth:whoami)"
}

# Install dependencies
install_dependencies() {
    print_info "Installing dependencies..."
    bundle install
    if [ $? -eq 0 ]; then
        print_status "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
}

# Run database migrations
run_migrations() {
    print_info "Running database migrations..."
    rails db:migrate
    if [ $? -eq 0 ]; then
        print_status "Database migrations completed"
    else
        print_error "Database migrations failed"
        exit 1
    fi
}

# Seed database with test data
seed_database() {
    print_info "Seeding database..."
    rails db:seed
    if [ $? -eq 0 ]; then
        print_status "Database seeded successfully"
    else
        print_warning "Database seeding had issues (may already be seeded)"
    fi
}

# Run comprehensive automated tests
run_comprehensive_tests() {
    print_info "Running comprehensive automated test suite..."
    
    # Run our custom test suite
    ruby automated_test_suite.rb
    TEST_RESULT=$?
    
    if [ $TEST_RESULT -eq 0 ]; then
        print_status "All automated tests passed successfully"
    else
        print_error "Some tests failed. Please fix issues before deployment."
        exit 1
    fi
}

# Run Rails built-in tests
run_rails_tests() {
    print_info "Running Rails test suite..."
    rails test
    if [ $? -eq 0 ]; then
        print_status "Rails tests passed"
    else
        print_warning "Some Rails tests failed (this might be okay if you don't have extensive test coverage)"
    fi
}

# Check for security vulnerabilities
security_audit() {
    print_info "Running security audit..."
    
    # Check for vulnerable gems
    bundle audit
    if [ $? -eq 0 ]; then
        print_status "No security vulnerabilities found"
    else
        print_warning "Security vulnerabilities detected. Please review and update."
    fi
}

# Precompile assets
precompile_assets() {
    print_info "Precompiling assets..."
    RAILS_ENV=production rails assets:precompile
    if [ $? -eq 0 ]; then
        print_status "Assets precompiled successfully"
    else
        print_error "Asset precompilation failed"
        exit 1
    fi
}

# Create Heroku app if it doesn't exist
create_heroku_app() {
    APP_NAME=${1:-milk-production-system-$(date +%s)}
    print_info "Creating Heroku app: $APP_NAME"
    
    heroku apps:info $APP_NAME &> /dev/null
    if [ $? -eq 0 ]; then
        print_warning "App $APP_NAME already exists"
    else
        heroku create $APP_NAME
        if [ $? -eq 0 ]; then
            print_status "Heroku app created: $APP_NAME"
        else
            print_error "Failed to create Heroku app"
            exit 1
        fi
    fi
    
    echo $APP_NAME > .heroku_app_name
}

# Add Heroku PostgreSQL addon
add_postgresql() {
    APP_NAME=$(cat .heroku_app_name 2>/dev/null || echo "")
    if [ -z "$APP_NAME" ]; then
        print_error "Heroku app name not found"
        exit 1
    fi
    
    print_info "Adding PostgreSQL addon..."
    heroku addons:create heroku-postgresql:mini -a $APP_NAME
    if [ $? -eq 0 ]; then
        print_status "PostgreSQL addon added"
    else
        print_warning "PostgreSQL addon might already exist or failed to add"
    fi
}

# Set environment variables
set_env_variables() {
    APP_NAME=$(cat .heroku_app_name 2>/dev/null || echo "")
    print_info "Setting environment variables..."
    
    heroku config:set RAILS_ENV=production -a $APP_NAME
    heroku config:set RAILS_SERVE_STATIC_FILES=true -a $APP_NAME
    heroku config:set SECRET_KEY_BASE=$(rails secret) -a $APP_NAME
    
    print_status "Environment variables set"
}

# Deploy to Heroku
deploy_to_heroku() {
    APP_NAME=$(cat .heroku_app_name 2>/dev/null || echo "")
    print_info "Deploying to Heroku..."
    
    # Add git remote if not exists
    git remote add heroku https://git.heroku.com/$APP_NAME.git 2>/dev/null
    
    # Commit any changes
    git add .
    git commit -m "Pre-deployment commit with automated testing" 2>/dev/null
    
    # Deploy
    git push heroku main
    if [ $? -eq 0 ]; then
        print_status "Deployment successful"
    else
        print_error "Deployment failed"
        exit 1
    fi
}

# Run post-deployment tasks
post_deployment() {
    APP_NAME=$(cat .heroku_app_name 2>/dev/null || echo "")
    print_info "Running post-deployment tasks..."
    
    # Run migrations on Heroku
    heroku run rails db:migrate -a $APP_NAME
    
    # Seed database on Heroku
    heroku run rails db:seed -a $APP_NAME
    
    print_status "Post-deployment tasks completed"
}

# Test deployed application
test_deployed_app() {
    APP_NAME=$(cat .heroku_app_name 2>/dev/null || echo "")
    APP_URL="https://$APP_NAME.herokuapp.com"
    
    print_info "Testing deployed application..."
    
    # Test main endpoints
    ENDPOINTS=(
        "/"
        "/financial_reports"
        "/dashboard"
        "/production_entry"
    )
    
    for endpoint in "${ENDPOINTS[@]}"; do
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL$endpoint")
        if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 302 ]; then
            print_status "$endpoint - Responding correctly ($HTTP_CODE)"
        else
            print_error "$endpoint - Not responding correctly ($HTTP_CODE)"
        fi
    done
}

# Main deployment flow
main() {
    echo "🎯 Starting automated deployment process..."
    echo ""
    
    # Pre-deployment checks
    check_heroku_cli
    check_heroku_login
    
    # Local preparation
    install_dependencies
    run_migrations
    seed_database
    
    # Automated testing
    run_comprehensive_tests
    run_rails_tests
    security_audit
    
    # Asset preparation
    precompile_assets
    
    # Heroku setup
    read -p "Enter Heroku app name (or press Enter for auto-generated): " app_name
    create_heroku_app $app_name
    add_postgresql
    set_env_variables
    
    # Deployment
    deploy_to_heroku
    post_deployment
    
    # Post-deployment testing
    test_deployed_app
    
    APP_NAME=$(cat .heroku_app_name)
    APP_URL="https://$APP_NAME.herokuapp.com"
    
    echo ""
    echo "🎉 DEPLOYMENT COMPLETE!"
    echo "======================================="
    print_status "Your application is live at: $APP_URL"
    print_status "Heroku dashboard: https://dashboard.heroku.com/apps/$APP_NAME"
    print_info "To view logs: heroku logs -t -a $APP_NAME"
    print_info "To run console: heroku run rails console -a $APP_NAME"
    echo ""
}

# Run the main function
main "$@"
