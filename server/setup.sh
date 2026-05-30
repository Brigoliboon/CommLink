#!/bin/bash
echo "Setting up CommLink PostgreSQL database..."

# Create database (adjust user as needed)
createdb commlink 2>/dev/null || echo "Database 'commlink' may already exist"

# Test connection
PGPASSWORD=postgres psql -h localhost -U postgres -d commlink -c "SELECT 1;" 2>/dev/null || \
PGPASSWORD=password psql -h localhost -U postgres -d commlink -c "SELECT 1;" 2>/dev/null || \
echo "Please configure PostgreSQL credentials in .env file"

echo "Run 'npm start' to start the server"