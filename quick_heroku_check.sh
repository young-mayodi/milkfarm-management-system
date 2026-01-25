#!/bin/bash

echo "🚀 Quick Heroku Deployment Check"
echo "================================"

echo ""
echo "📋 Pre-deployment Checklist:"

# Check Git status
if [ -z "$(git status --porcelain)" ]; then
    echo "✅ Git repository - Clean (all changes committed)"
else
    echo "⚠️  Git repository - Has uncommitted changes"
    echo "   Run: git add -A && git commit -m 'Deploy to Heroku'"
fi

# Check required files
files=("Procfile" "app.json" "config/database.yml" "config/puma.rb")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file - Found"
    else
        echo "❌ $file - Missing"
    fi
done

# Check Gemfile for Heroku requirements
if grep -q "rails_12factor" Gemfile; then
    echo "✅ Gemfile - Contains Heroku gems"
else
    echo "⚠️  Gemfile - Missing Heroku optimization gems"
fi

# Check Heroku CLI
if command -v heroku &> /dev/null; then
    echo "✅ Heroku CLI - Installed"
    
    # Check authentication
    if heroku auth:whoami &> /dev/null; then
        echo "✅ Heroku Auth - Logged in as $(heroku auth:whoami)"
    else
        echo "❌ Heroku Auth - Not logged in"
        echo "   Run: heroku login"
    fi
else
    echo "❌ Heroku CLI - Not installed"
    echo "   Run: brew tap heroku/brew && brew install heroku"
fi

echo ""
echo "🎯 Ready to Deploy!"
echo "Run: ./deploy_to_heroku.sh"
echo ""
