#!/bin/bash

# Database Restore Script for Milk Production System
# Usage: ./restore_database.sh [environment] [backup_file]

set -e  # Exit on error

# Configuration
ENVIRONMENT=${1:-production}
BACKUP_DIR="$HOME/farm-bar/milk_production_system/backups"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Milk Production System Database Restore ===${NC}"
echo -e "Environment: ${YELLOW}${ENVIRONMENT}${NC}"

# Determine backup file
if [ -n "$2" ]; then
    BACKUP_FILE="$2"
    BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"
else
    # Use latest backup
    BACKUP_PATH="${BACKUP_DIR}/milk_production_${ENVIRONMENT}_latest.dump"
    if [ ! -f "$BACKUP_PATH" ]; then
        echo -e "${RED}ERROR: No backup file specified and no latest backup found${NC}"
        echo "Usage: ./restore_database.sh [environment] [backup_file]"
        exit 1
    fi
fi

# Verify backup file exists
if [ ! -f "$BACKUP_PATH" ]; then
    echo -e "${RED}ERROR: Backup file not found: ${BACKUP_PATH}${NC}"
    echo "Available backups:"
    ls -lh "$BACKUP_DIR" | grep "milk_production_${ENVIRONMENT}"
    exit 1
fi

echo -e "Backup file: ${YELLOW}${BACKUP_PATH}${NC}"

# Confirmation prompt
echo -e "${RED}WARNING: This will drop and recreate the database!${NC}"
echo -e "All current data in ${YELLOW}${ENVIRONMENT}${NC} environment will be lost."
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Restore cancelled${NC}"
    exit 0
fi

# Get database details
if [ "$ENVIRONMENT" = "production" ]; then
    if [ -z "$DATABASE_URL" ]; then
        echo -e "${RED}ERROR: DATABASE_URL not set for production${NC}"
        exit 1
    fi
    
    # Parse DATABASE_URL (format: postgresql://user:pass@host:port/dbname)
    DB_URL="$DATABASE_URL"
    
    echo -e "${GREEN}Restoring to production database...${NC}"
    pg_restore --clean --no-acl --no-owner -d "$DB_URL" "$BACKUP_PATH"
    
elif [ "$ENVIRONMENT" = "development" ]; then
    DB_NAME="milk_production_system_development"
    
    echo -e "${GREEN}Dropping existing database...${NC}"
    dropdb --if-exists "$DB_NAME"
    
    echo -e "${GREEN}Creating new database...${NC}"
    createdb "$DB_NAME"
    
    echo -e "${GREEN}Restoring backup...${NC}"
    pg_restore -d "$DB_NAME" "$BACKUP_PATH"
else
    echo -e "${RED}ERROR: Invalid environment${NC}"
    exit 1
fi

# Check if restore was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database restored successfully${NC}"
    
    # Run migrations to ensure schema is up to date
    if [ "$ENVIRONMENT" = "development" ]; then
        echo -e "${GREEN}Running migrations...${NC}"
        cd "$(dirname "$0")"
        RAILS_ENV=$ENVIRONMENT bundle exec rails db:migrate
    fi
    
    echo -e "${GREEN}=== Restore Complete ===${NC}"
else
    echo -e "${RED}✗ Restore failed${NC}"
    exit 1
fi
