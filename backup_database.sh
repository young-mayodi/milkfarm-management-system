#!/bin/bash

# Database Backup Script for Milk Production System
# Usage: ./backup_database.sh [environment]

set -e  # Exit on error

# Configuration
ENVIRONMENT=${1:-production}
BACKUP_DIR="$HOME/farm-bar/milk_production_system/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="milk_production_${ENVIRONMENT}_${TIMESTAMP}.dump"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"

# Retention settings (days)
RETENTION_DAYS=30

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Milk Production System Database Backup ===${NC}"
echo -e "Environment: ${YELLOW}${ENVIRONMENT}${NC}"
echo -e "Timestamp: ${YELLOW}${TIMESTAMP}${NC}"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Get database URL from environment or config
if [ "$ENVIRONMENT" = "production" ]; then
    if [ -z "$DATABASE_URL" ]; then
        echo -e "${RED}ERROR: DATABASE_URL not set for production${NC}"
        echo "Run: export DATABASE_URL='postgresql://user:password@host:port/database'"
        exit 1
    fi
    DB_URL="$DATABASE_URL"
elif [ "$ENVIRONMENT" = "development" ]; then
    DB_NAME="milk_production_system_development"
    DB_URL="postgresql://localhost:5432/${DB_NAME}"
else
    echo -e "${RED}ERROR: Invalid environment. Use 'production' or 'development'${NC}"
    exit 1
fi

# Perform backup
echo -e "${GREEN}Starting backup...${NC}"
if [ "$ENVIRONMENT" = "production" ]; then
    # Production backup (from DATABASE_URL)
    pg_dump "$DB_URL" -Fc -f "$BACKUP_PATH"
else
    # Development backup (local PostgreSQL)
    pg_dump -Fc -f "$BACKUP_PATH" "$DB_NAME"
fi

# Check if backup was successful
if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
    echo -e "${GREEN}✓ Backup completed successfully${NC}"
    echo -e "File: ${YELLOW}${BACKUP_FILE}${NC}"
    echo -e "Size: ${YELLOW}${BACKUP_SIZE}${NC}"
    echo -e "Path: ${YELLOW}${BACKUP_PATH}${NC}"
else
    echo -e "${RED}✗ Backup failed${NC}"
    exit 1
fi

# Cleanup old backups
echo -e "${GREEN}Cleaning up old backups (older than ${RETENTION_DAYS} days)...${NC}"
DELETED_COUNT=$(find "$BACKUP_DIR" -name "milk_production_${ENVIRONMENT}_*.dump" -type f -mtime +${RETENTION_DAYS} -delete -print | wc -l)
if [ "$DELETED_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ Deleted ${DELETED_COUNT} old backup(s)${NC}"
else
    echo -e "${YELLOW}No old backups to delete${NC}"
fi

# List recent backups
echo -e "${GREEN}Recent backups:${NC}"
ls -lh "$BACKUP_DIR" | grep "milk_production_${ENVIRONMENT}" | tail -5

# Create a latest symlink
ln -sf "$BACKUP_PATH" "${BACKUP_DIR}/milk_production_${ENVIRONMENT}_latest.dump"

echo -e "${GREEN}=== Backup Complete ===${NC}"
echo ""
echo -e "To restore this backup, run:"
echo -e "${YELLOW}pg_restore -d database_name ${BACKUP_PATH}${NC}"
echo ""
echo -e "Or use the restore script:"
echo -e "${YELLOW}./restore_database.sh ${ENVIRONMENT} ${BACKUP_FILE}${NC}"
