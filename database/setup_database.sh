#!/bin/bash

# F1 Predictor 2.0 Database Setup Script
# This script helps set up the PostgreSQL database for F1 Predictor 2.0
# Usage: ./setup_database.sh <db_name> <db_user> <db_host> [db_port]

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DB_NAME="${1:-f1predictor}"
DB_USER="${2:-f1_app}"
DB_HOST="${3:-localhost}"
DB_PORT="${4:-5432}"
DB_PASSWORD="${DB_USER}_$(date +%s)"

echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}F1 Predictor 2.0 Database Setup${NC}"
echo -e "${YELLOW}================================${NC}"
echo ""

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo -e "${RED}Error: PostgreSQL client (psql) is not installed.${NC}"
    echo "Please install PostgreSQL:"
    echo "  macOS: brew install postgresql"
    echo "  Ubuntu: sudo apt-get install postgresql-client"
    exit 1
fi

echo -e "${YELLOW}Database Configuration:${NC}"
echo "  Database Name: $DB_NAME"
echo "  User: $DB_USER"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo ""

# Check connection to PostgreSQL
echo -e "${YELLOW}Checking PostgreSQL connection...${NC}"
if ! psql -h "$DB_HOST" -U postgres -d postgres -c "SELECT 1" &>/dev/null; then
    echo -e "${RED}Error: Cannot connect to PostgreSQL at $DB_HOST:$DB_PORT${NC}"
    echo "Make sure PostgreSQL is running and accessible."
    exit 1
fi
echo -e "${GREEN}✓ PostgreSQL connection successful${NC}"
echo ""

# Create database
echo -e "${YELLOW}Creating database '$DB_NAME'...${NC}"
psql -h "$DB_HOST" -U postgres -d postgres -c "CREATE DATABASE $DB_NAME;" 2>/dev/null || echo -e "${YELLOW}Database already exists${NC}"
echo -e "${GREEN}✓ Database ready${NC}"
echo ""

# Create application user
echo -e "${YELLOW}Creating application user '$DB_USER'...${NC}"
psql -h "$DB_HOST" -U postgres -d postgres -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || echo -e "${YELLOW}User already exists${NC}"
echo -e "${GREEN}✓ User created (password stored)${NC}"
echo ""

# Grant privileges
echo -e "${YELLOW}Granting privileges to user...${NC}"
psql -h "$DB_HOST" -U postgres -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
psql -h "$DB_HOST" -U postgres -d "$DB_NAME" -c "GRANT USAGE ON SCHEMA public TO $DB_USER;"
echo -e "${GREEN}✓ Privileges granted${NC}"
echo ""

# Load schema
echo -e "${YELLOW}Loading database schema...${NC}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/schema.sql" ]; then
    psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$SCRIPT_DIR/schema.sql" > /dev/null 2>&1
    echo -e "${GREEN}✓ Schema loaded successfully${NC}"
else
    echo -e "${RED}Error: schema.sql not found in $SCRIPT_DIR${NC}"
    exit 1
fi
echo ""

# Create .env file
echo -e "${YELLOW}Creating .env file for application...${NC}"
ENV_FILE="$SCRIPT_DIR/../.env.local"
cat > "$ENV_FILE" << EOF
# F1 Predictor Database Configuration
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
EOF
echo -e "${GREEN}✓ Configuration saved to .env.local${NC}"
echo ""

# Display connection info
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Database Setup Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${YELLOW}Connection Details:${NC}"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo ""
echo -e "${YELLOW}Connect with psql:${NC}"
echo "  psql -h $DB_HOST -U $DB_USER -d $DB_NAME"
echo ""
echo -e "${YELLOW}Connection string for applications:${NC}"
echo "  postgresql://$DB_USER:***@$DB_HOST:$DB_PORT/$DB_NAME"
echo ""

# Verify tables created
echo -e "${YELLOW}Verifying table creation...${NC}"
TABLE_COUNT=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" -t)
echo -e "${GREEN}✓ Created $TABLE_COUNT tables${NC}"
echo ""

# Show next steps
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Start ingesting historical F1 data"
echo "  2. Create model training scripts"
echo "  3. Set up API backend to query predictions"
echo "  4. Build frontend dashboard"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo "  psql -h $DB_HOST -U $DB_USER -d $DB_NAME"
echo "  psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c '\\dt'  # List tables"
echo "  psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c '\\di'  # List indexes"
echo ""
