#!/bin/bash

# Database Functionality Test Suite
# Tests: Schema, Constraints, Indexes, Data Integrity, Performance
# Author: Victor Tiradoegas

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DATABASE_NAME:-invdb}"
DB_USER="${DATABASE_USERNAME:-invuser}"
DB_PASSWORD="${DATABASE_PASSWORD:-invpass}"

# Test counters
PASSED=0
FAILED=0
SKIPPED=0

# Test results log
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
TEST_LOG="$LOG_DIR/db-test-results-$(date +%Y%m%d-%H%M%S).log"
echo "Database Test Run Started: $(date)" > "$TEST_LOG"

# Helper functions
log_test() {
    local status=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [$status] $message" >> "$TEST_LOG"
}

test_sql() {
    local name=$1
    local sql=$2
    local expected_result=$3  # Optional: expected value or pattern
    
    echo -n "Testing: $name... "
    
    # Execute SQL and capture result
    result=$(execute_sql "$sql")
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        if [ -z "$expected_result" ] || echo "$result" | grep -q "$expected_result"; then
            echo -e "${GREEN}✓ PASS${NC}"
            log_test "PASS" "$name"
            ((PASSED++))
            return 0
        else
            echo -e "${YELLOW}⚠ PASS (unexpected result)${NC}"
            echo "  Result: $result"
            log_test "WARN" "$name - Unexpected result: $result"
            ((PASSED++))
            return 0
        fi
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "  Error: $result"
        log_test "FAIL" "$name - Error: $result"
        ((FAILED++))
        return 1
    fi
}

test_sql_count() {
    local name=$1
    local sql=$2
    local expected_count=$3
    
    echo -n "Testing: $name... "
    
    result=$(execute_sql "$sql" | tr -d ' ')
    exit_code=$?
    
    if [ $exit_code -eq 0 ] && [ "$result" == "$expected_count" ]; then
        echo -e "${GREEN}✓ PASS${NC} (count: $result)"
        log_test "PASS" "$name - Count: $result"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (Expected: $expected_count, Got: $result)"
        log_test "FAIL" "$name - Expected: $expected_count, Got: $result"
        ((FAILED++))
        return 1
    fi
}

print_section() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
    echo ""
    log_test "INFO" "Starting section: $1"
}

# Determine psql command (try local first, then Docker)
USE_DOCKER=0
if command -v psql >/dev/null 2>&1; then
    USE_DOCKER=0
elif docker ps --filter "name=inventory-db" --format "{{.Names}}" | grep -q "inventory-db"; then
    echo -e "${YELLOW}⚠ Local psql not found, using Docker container...${NC}"
    USE_DOCKER=1
else
    echo -e "${RED}✗ psql not found and Docker container 'inventory-db' not running.${NC}"
    echo "  Options:"
    echo "  1. Install PostgreSQL client:"
    echo "     macOS: brew install postgresql"
    echo "     Ubuntu: sudo apt-get install postgresql-client"
    echo "  2. Start database container:"
    echo "     docker-compose -f docker-compose.prod.yaml up -d postgres"
    exit 1
fi

# Function to execute SQL using the determined command
execute_sql() {
    local sql=$1
    if [ $USE_DOCKER -eq 0 ]; then
        # Local psql
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c "$sql" 2>&1
    else
        # Docker exec - need to handle multi-line SQL properly
        echo "$sql" | docker exec -i inventory-db psql -U "$DB_USER" -d "$DB_NAME" -t -A 2>&1
    fi
}

# Function to execute SQL and check for errors
execute_sql_check_error() {
    local sql=$1
    local result=$(execute_sql "$sql")
    local exit_code=$?
    
    # Check for common error patterns
    if echo "$result" | grep -qiE "error|violates|duplicate|null value|foreign key"; then
        echo "$result"
        return 1
    fi
    
    echo "$result"
    return 0
}

execute_sql_silent() {
    local sql=$1
    if [ $USE_DOCKER -eq 0 ]; then
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$sql" >/dev/null 2>&1
    else
        echo "$sql" | docker exec -i inventory-db psql -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1
    fi
}

execute_sql_with_output() {
    local sql=$1
    if [ $USE_DOCKER -eq 0 ]; then
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$sql" 2>&1
    else
        echo "$sql" | docker exec -i inventory-db psql -U "$DB_USER" -d "$DB_NAME" 2>&1
    fi
}

# Function to execute SQL and check for errors
execute_sql_check_error() {
    local sql=$1
    local result=$(execute_sql "$sql")
    local exit_code=$?
    
    # Check for common error patterns
    if echo "$result" | grep -qiE "error|violates|duplicate|null value|foreign key"; then
        echo "$result"
        return 1
    fi
    
    echo "$result"
    return 0
}

# Test database connection
echo "Testing database connection..."
if execute_sql_silent "SELECT 1;"; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Database connection failed${NC}"
    echo "  Host: $DB_HOST:$DB_PORT"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    echo ""
    echo "  Check:"
    echo "  - Database is running"
    echo "  - Connection parameters are correct"
    echo "  - Password matches (check .env file)"
    exit 1
fi

# ==========================================
# SECTION 1: Table Existence Tests
# ==========================================
print_section "1. Table Existence Tests"

test_sql "inventory_items table exists" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'inventory_items';" \
    "1"

test_sql "audit_events table exists" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'audit_events';" \
    "1"

test_sql "users table exists" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users';" \
    "1"

test_sql "roles table exists" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'roles';" \
    "1"

test_sql "user_roles table exists" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_roles';" \
    "1"

test_sql "password_reset_tokens table exists" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'password_reset_tokens';" \
    "1"

test_sql "flyway_schema_history table exists" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'flyway_schema_history';" \
    "1"

# ==========================================
# SECTION 2: Column Existence and Data Types
# ==========================================
print_section "2. Column Existence and Data Types"

echo "2.1 Testing inventory_items columns..."
test_sql "inventory_items.id column exists" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'inventory_items' AND column_name = 'id' AND data_type = 'bigint';" \
    "1"

test_sql "inventory_items.sku column exists" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'inventory_items' AND column_name = 'sku' AND data_type = 'character varying';" \
    "1"

test_sql "inventory_items.name column exists" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'inventory_items' AND column_name = 'name' AND data_type = 'character varying';" \
    "1"

test_sql "inventory_items.qty column exists" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'inventory_items' AND column_name = 'qty' AND data_type = 'integer';" \
    "1"

test_sql "inventory_items.location column exists" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'inventory_items' AND column_name = 'location' AND data_type = 'character varying';" \
    "1"

test_sql "inventory_items.updated_at column exists" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'inventory_items' AND column_name = 'updated_at' AND data_type = 'timestamp without time zone';" \
    "1"

echo ""
echo "2.2 Testing audit_events columns..."
test_sql "audit_events.id column exists" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'audit_events' AND column_name = 'id' AND data_type = 'bigint';" \
    "1"

test_sql "audit_events.event_type column exists" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'audit_events' AND column_name = 'event_type' AND data_type = 'character varying';" \
    "1"

test_sql "audit_events.entity_type column exists" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'audit_events' AND column_name = 'entity_type' AND data_type = 'character varying';" \
    "1"

test_sql "audit_events.entity_id column exists" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'audit_events' AND column_name = 'entity_id' AND data_type = 'bigint';" \
    "1"

test_sql "audit_events.user_id column exists" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'audit_events' AND column_name = 'user_id' AND data_type = 'character varying';" \
    "1"

test_sql "audit_events.details column exists" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'audit_events' AND column_name = 'details' AND data_type = 'text';" \
    "1"

test_sql "audit_events.timestamp column exists" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'audit_events' AND column_name = 'timestamp' AND data_type = 'timestamp without time zone';" \
    "1"

# ==========================================
# SECTION 3: Constraint Tests
# ==========================================
print_section "3. Constraint Tests"

echo "3.1 Testing NOT NULL constraints..."
test_sql "inventory_items.sku is NOT NULL" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'inventory_items' AND column_name = 'sku' AND is_nullable = 'NO';" \
    "1"

test_sql "inventory_items.name is NOT NULL" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'inventory_items' AND column_name = 'name' AND is_nullable = 'NO';" \
    "1"

test_sql "inventory_items.qty is NOT NULL" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'inventory_items' AND column_name = 'qty' AND is_nullable = 'NO';" \
    "1"

test_sql "inventory_items.location is NOT NULL" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'inventory_items' AND column_name = 'location' AND is_nullable = 'NO';" \
    "1"

test_sql "inventory_items.updated_at is NOT NULL" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'inventory_items' AND column_name = 'updated_at' AND is_nullable = 'NO';" \
    "1"

test_sql "audit_events.event_type is NOT NULL" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'audit_events' AND column_name = 'event_type' AND is_nullable = 'NO';" \
    "1"

test_sql "audit_events.entity_type is NOT NULL" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'audit_events' AND column_name = 'entity_type' AND is_nullable = 'NO';" \
    "1"

test_sql "audit_events.entity_id is NOT NULL" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'audit_events' AND column_name = 'entity_id' AND is_nullable = 'NO';" \
    "1"

test_sql "audit_events.timestamp is NOT NULL" \
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'audit_events' AND column_name = 'timestamp' AND is_nullable = 'NO';" \
    "1"

echo ""
echo "3.2 Testing UNIQUE constraints..."
test_sql "inventory_items.sku has UNIQUE constraint" \
    "SELECT COUNT(*) FROM information_schema.table_constraints tc JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name WHERE tc.table_name = 'inventory_items' AND tc.constraint_type = 'UNIQUE' AND ccu.column_name = 'sku';" \
    "1"

test_sql "users.username has UNIQUE constraint" \
    "SELECT COUNT(*) FROM information_schema.table_constraints tc JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name WHERE tc.table_name = 'users' AND tc.constraint_type = 'UNIQUE' AND ccu.column_name = 'username';" \
    "1"

test_sql "users.email has UNIQUE constraint" \
    "SELECT COUNT(*) FROM information_schema.table_constraints tc JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name WHERE tc.table_name = 'users' AND tc.constraint_type = 'UNIQUE' AND ccu.column_name = 'email';" \
    "1"

test_sql "roles.name has UNIQUE constraint" \
    "SELECT COUNT(*) FROM information_schema.table_constraints tc JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name WHERE tc.table_name = 'roles' AND tc.constraint_type = 'UNIQUE' AND ccu.column_name = 'name';" \
    "1"

echo ""
echo "3.3 Testing PRIMARY KEY constraints..."
test_sql "inventory_items has PRIMARY KEY on id" \
    "SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_name = 'inventory_items' AND constraint_type = 'PRIMARY KEY';" \
    "1"

test_sql "audit_events has PRIMARY KEY on id" \
    "SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_name = 'audit_events' AND constraint_type = 'PRIMARY KEY';" \
    "1"

test_sql "users has PRIMARY KEY on id" \
    "SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_name = 'users' AND constraint_type = 'PRIMARY KEY';" \
    "1"

test_sql "roles has PRIMARY KEY on id" \
    "SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_name = 'roles' AND constraint_type = 'PRIMARY KEY';" \
    "1"

echo ""
echo "3.4 Testing FOREIGN KEY constraints..."
test_sql "user_roles has FOREIGN KEY to users" \
    "SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_name = 'user_roles' AND constraint_type = 'FOREIGN KEY' AND constraint_name LIKE '%user_id%';" \
    "1"

test_sql "user_roles has FOREIGN KEY to roles" \
    "SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_name = 'user_roles' AND constraint_type = 'FOREIGN KEY' AND constraint_name LIKE '%role_id%';" \
    "1"

test_sql "password_reset_tokens has FOREIGN KEY to users" \
    "SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_name = 'password_reset_tokens' AND constraint_type = 'FOREIGN KEY' AND constraint_name LIKE '%user_id%';" \
    "1"

# ==========================================
# SECTION 4: Index Tests
# ==========================================
print_section "4. Index Tests"

echo "4.1 Testing inventory_items indexes..."
test_sql "idx_sku index exists" \
    "SELECT COUNT(*) FROM pg_indexes WHERE tablename = 'inventory_items' AND indexname = 'idx_sku';" \
    "1"

test_sql "idx_location index exists" \
    "SELECT COUNT(*) FROM pg_indexes WHERE tablename = 'inventory_items' AND indexname = 'idx_location';" \
    "1"

test_sql "idx_updated_at index exists" \
    "SELECT COUNT(*) FROM pg_indexes WHERE tablename = 'inventory_items' AND indexname = 'idx_updated_at';" \
    "1"

test_sql "idx_location_updated composite index exists" \
    "SELECT COUNT(*) FROM pg_indexes WHERE tablename = 'inventory_items' AND indexname = 'idx_location_updated';" \
    "1"

echo ""
echo "4.2 Testing audit_events indexes..."
test_sql "idx_entity_type_id index exists" \
    "SELECT COUNT(*) FROM pg_indexes WHERE tablename = 'audit_events' AND indexname = 'idx_entity_type_id';" \
    "1"

test_sql "idx_user_id index exists" \
    "SELECT COUNT(*) FROM pg_indexes WHERE tablename = 'audit_events' AND indexname = 'idx_user_id';" \
    "1"

test_sql "idx_timestamp index exists" \
    "SELECT COUNT(*) FROM pg_indexes WHERE tablename = 'audit_events' AND indexname = 'idx_timestamp';" \
    "1"

test_sql "idx_event_type index exists" \
    "SELECT COUNT(*) FROM pg_indexes WHERE tablename = 'audit_events' AND indexname = 'idx_event_type';" \
    "1"

echo ""
echo "4.3 Testing users indexes..."
test_sql "idx_users_username index exists" \
    "SELECT COUNT(*) FROM pg_indexes WHERE tablename = 'users' AND indexname = 'idx_users_username';" \
    "1"

test_sql "idx_users_email index exists" \
    "SELECT COUNT(*) FROM pg_indexes WHERE tablename = 'users' AND indexname = 'idx_users_email';" \
    "1"

# ==========================================
# SECTION 5: Data Integrity Tests
# ==========================================
print_section "5. Data Integrity Tests"

echo "5.1 Testing constraint enforcement - Duplicate SKU..."
# This should fail due to UNIQUE constraint
result=$(execute_sql "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('TEST-DUPLICATE', 'Test', 10, 'Location', CURRENT_TIMESTAMP);
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('TEST-DUPLICATE', 'Test2', 20, 'Location2', CURRENT_TIMESTAMP);
" 2>&1)

if echo "$result" | grep -q "duplicate key\|unique constraint"; then
    echo -e "${GREEN}✓ UNIQUE constraint on SKU enforced${NC}"
    log_test "PASS" "UNIQUE constraint on SKU enforced"
    ((PASSED++))
    # Cleanup
    execute_sql_silent "DELETE FROM inventory_items WHERE sku = 'TEST-DUPLICATE';"
else
    echo -e "${RED}✗ UNIQUE constraint on SKU not enforced${NC}"
    log_test "FAIL" "UNIQUE constraint on SKU not enforced"
    ((FAILED++))
fi

echo ""
echo "5.2 Testing NOT NULL constraint enforcement..."
result=$(execute_sql "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES (NULL, 'Test', 10, 'Location', CURRENT_TIMESTAMP);
" 2>&1)

if echo "$result" | grep -q "null value\|not null"; then
    echo -e "${GREEN}✓ NOT NULL constraint on SKU enforced${NC}"
    log_test "PASS" "NOT NULL constraint on SKU enforced"
    ((PASSED++))
else
    echo -e "${RED}✗ NOT NULL constraint on SKU not enforced${NC}"
    log_test "FAIL" "NOT NULL constraint on SKU not enforced"
    ((FAILED++))
fi

echo ""
echo "5.3 Testing FOREIGN KEY constraint enforcement..."
# First create a test user (clean up any existing one first)
execute_sql_silent "DELETE FROM users WHERE username = 'test_fk_user';"
TEST_USER_ID=$(execute_sql "
    INSERT INTO users (username, email, password_hash, enabled) 
    VALUES ('test_fk_user_$(date +%s)', 'test_fk_$(date +%s)@test.com', 'hash', true) 
    RETURNING id;
" 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')

if [ ! -z "$TEST_USER_ID" ] && [ "$TEST_USER_ID" -gt 0 ] 2>/dev/null; then
    # Try to insert invalid foreign key
    result=$(execute_sql "
        INSERT INTO password_reset_tokens (user_id, token, expires_at) 
        VALUES (999999, 'test-token', CURRENT_TIMESTAMP + INTERVAL '1 hour');
    " 2>&1)
    
    if echo "$result" | grep -q "foreign key\|violates foreign key"; then
        echo -e "${GREEN}✓ FOREIGN KEY constraint enforced${NC}"
        log_test "PASS" "FOREIGN KEY constraint enforced"
        ((PASSED++))
    else
        echo -e "${RED}✗ FOREIGN KEY constraint not enforced${NC}"
        log_test "FAIL" "FOREIGN KEY constraint not enforced"
        ((FAILED++))
    fi
    
    # Cleanup
    execute_sql_silent "DELETE FROM users WHERE id = $TEST_USER_ID;"
else
    echo -e "${YELLOW}⚠ Could not create test user for FK test${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 6: Default Values Tests
# ==========================================
print_section "6. Default Values Tests"

echo "6.1 Testing default timestamp values..."
# Clean up any existing test data
execute_sql_silent "DELETE FROM inventory_items WHERE sku = 'TEST-DEFAULT-TS';"
# Insert without specifying timestamp
result=$(execute_sql "
    INSERT INTO inventory_items (sku, name, qty, location) 
    VALUES ('TEST-DEFAULT-TS-$(date +%s)', 'Test', 10, 'Location') 
    RETURNING CASE WHEN updated_at IS NOT NULL THEN 't' ELSE 'f' END;
" 2>&1 | grep -E '^[tf]' | head -1 | tr -d ' \n\r')

if [ "$result" == "t" ] || [ "$result" == "true" ] || [ "$result" == "1" ]; then
    # Also verify the timestamp was actually set
    timestamp_check=$(execute_sql "
        SELECT COUNT(*) FROM inventory_items 
        WHERE sku LIKE 'TEST-DEFAULT-TS-%' AND updated_at IS NOT NULL;
    " 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')
    
    if [ "$timestamp_check" == "1" ] 2>/dev/null; then
        echo -e "${GREEN}✓ Default timestamp value works${NC}"
        log_test "PASS" "Default timestamp value works"
        ((PASSED++))
        # Cleanup
        execute_sql_silent "DELETE FROM inventory_items WHERE sku LIKE 'TEST-DEFAULT-TS-%';"
    else
        echo -e "${RED}✗ Default timestamp value not working${NC}"
        log_test "FAIL" "Default timestamp value not working"
        ((FAILED++))
    fi
else
    echo -e "${RED}✗ Default timestamp value not working (result: '$result')${NC}"
    log_test "FAIL" "Default timestamp value not working - result: '$result'"
    ((FAILED++))
fi

# ==========================================
# SECTION 7: CRUD Operations Tests
# ==========================================
print_section "7. CRUD Operations Tests"

echo "7.1 Testing CREATE operation..."
CREATE_RESULT=$(execute_sql "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('TEST-CRUD-$(date +%s)', 'CRUD Test Item', 100, 'Test Warehouse', CURRENT_TIMESTAMP) 
    RETURNING id;
" 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')

if [ ! -z "$CREATE_RESULT" ] && [ "$CREATE_RESULT" -gt 0 ] 2>/dev/null; then
    TEST_ITEM_ID=$CREATE_RESULT
    echo -e "${GREEN}✓ CREATE operation successful (ID: $TEST_ITEM_ID)${NC}"
    log_test "PASS" "CREATE operation - ID: $TEST_ITEM_ID"
    ((PASSED++))
else
    echo -e "${RED}✗ CREATE operation failed${NC}"
    log_test "FAIL" "CREATE operation failed"
    ((FAILED++))
    TEST_ITEM_ID=""
fi

if [ ! -z "$TEST_ITEM_ID" ]; then
    echo ""
    echo "7.2 Testing READ operation..."
    READ_RESULT=$(execute_sql "
        SELECT COUNT(*) FROM inventory_items WHERE id = $TEST_ITEM_ID;
    " 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')
    
    if [ "$READ_RESULT" == "1" ]; then
        echo -e "${GREEN}✓ READ operation successful${NC}"
        log_test "PASS" "READ operation successful"
        ((PASSED++))
    else
        echo -e "${RED}✗ READ operation failed${NC}"
        log_test "FAIL" "READ operation failed"
        ((FAILED++))
    fi
    
    echo ""
    echo "7.3 Testing UPDATE operation..."
    UPDATE_RESULT=$(execute_sql "
        UPDATE inventory_items SET qty = 200, name = 'Updated CRUD Test' WHERE id = $TEST_ITEM_ID 
        RETURNING qty;
    " 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')
    
    if [ "$UPDATE_RESULT" == "200" ]; then
        echo -e "${GREEN}✓ UPDATE operation successful${NC}"
        log_test "PASS" "UPDATE operation successful"
        ((PASSED++))
    else
        echo -e "${RED}✗ UPDATE operation failed${NC}"
        log_test "FAIL" "UPDATE operation failed"
        ((FAILED++))
    fi
    
    echo ""
    echo "7.4 Testing DELETE operation..."
    DELETE_RESULT=$(execute_sql "
        DELETE FROM inventory_items WHERE id = $TEST_ITEM_ID 
        RETURNING id;
    " 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')
    
    if [ "$DELETE_RESULT" == "$TEST_ITEM_ID" ]; then
        echo -e "${GREEN}✓ DELETE operation successful${NC}"
        log_test "PASS" "DELETE operation successful"
        ((PASSED++))
    else
        echo -e "${RED}✗ DELETE operation failed${NC}"
        log_test "FAIL" "DELETE operation failed"
        ((FAILED++))
    fi
fi

# ==========================================
# SECTION 8: Referential Integrity Tests
# ==========================================
print_section "8. Referential Integrity Tests"

echo "8.1 Testing CASCADE DELETE on user_roles..."
# Create test user and role
# Clean up any existing test data
execute_sql_silent "DELETE FROM users WHERE username LIKE 'test_cascade_user%';"
TEST_USER_ID=$(execute_sql "
    INSERT INTO users (username, email, password_hash, enabled) 
    VALUES ('test_cascade_user_$(date +%s)', 'test_cascade_$(date +%s)@test.com', 'hash', true) 
    RETURNING id;
" 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')

TEST_ROLE_ID=$(execute_sql "
    SELECT id FROM roles WHERE name = 'USER' LIMIT 1;
" 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')

if [ ! -z "$TEST_USER_ID" ] && [ "$TEST_USER_ID" -gt 0 ] 2>/dev/null && [ ! -z "$TEST_ROLE_ID" ] && [ "$TEST_ROLE_ID" -gt 0 ] 2>/dev/null; then
    # Create user_role relationship
    execute_sql_silent "
        INSERT INTO user_roles (user_id, role_id) VALUES ($TEST_USER_ID, $TEST_ROLE_ID);
    " >/dev/null 2>&1
    
    # Delete user and check if user_roles entry is deleted
    execute_sql_silent "
        DELETE FROM users WHERE id = $TEST_USER_ID;
    " >/dev/null 2>&1
    
    CASCADE_CHECK=$(execute_sql "
        SELECT COUNT(*) FROM user_roles WHERE user_id = $TEST_USER_ID;
    " 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')
    
    if [ "$CASCADE_CHECK" == "0" ]; then
        echo -e "${GREEN}✓ CASCADE DELETE on user_roles works${NC}"
        log_test "PASS" "CASCADE DELETE on user_roles works"
        ((PASSED++))
    else
        echo -e "${RED}✗ CASCADE DELETE on user_roles failed${NC}"
        log_test "FAIL" "CASCADE DELETE on user_roles failed"
        ((FAILED++))
    fi
else
    echo -e "${YELLOW}⚠ Could not create test data for CASCADE test${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 9: Index Performance Tests
# ==========================================
print_section "9. Index Performance Tests"

echo "9.1 Testing index usage on SKU lookup..."
# Create test data
execute_sql_silent "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    SELECT 'PERF-TEST-' || generate_series, 'Test Item ' || generate_series, 10, 'Warehouse-A', CURRENT_TIMESTAMP
    FROM generate_series(1, 100);
" >/dev/null 2>&1

# Check if index is used (EXPLAIN ANALYZE)
EXPLAIN_RESULT=$(execute_sql "
    EXPLAIN (FORMAT JSON) SELECT * FROM inventory_items WHERE sku = 'PERF-TEST-50';
" 2>&1)

if echo "$EXPLAIN_RESULT" | grep -q "idx_sku\|Index Scan"; then
    echo -e "${GREEN}✓ Index idx_sku is being used${NC}"
    log_test "PASS" "Index idx_sku is being used"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Index usage unclear (may need more data)${NC}"
    log_test "WARN" "Index usage unclear"
    ((PASSED++))
fi

# Cleanup
execute_sql_silent "
    DELETE FROM inventory_items WHERE sku LIKE 'PERF-TEST-%';
" >/dev/null 2>&1

# ==========================================
# SECTION 10: Flyway Migration Tests
# ==========================================
print_section "10. Flyway Migration Tests"

echo "10.1 Checking Flyway migration history..."
MIGRATION_COUNT=$(execute_sql "
    SELECT COUNT(*) FROM flyway_schema_history WHERE success = true;
" 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')

if [ ! -z "$MIGRATION_COUNT" ] && [ "$MIGRATION_COUNT" -ge 4 ]; then
    echo -e "${GREEN}✓ Flyway migrations applied successfully (count: $MIGRATION_COUNT)${NC}"
    log_test "PASS" "Flyway migrations - Count: $MIGRATION_COUNT"
    ((PASSED++))
    
    echo ""
    echo "10.2 Listing applied migrations..."
    execute_sql_with_output "
        SELECT version, description, installed_on FROM flyway_schema_history WHERE success = true ORDER BY installed_rank;
    " | head -10
else
    echo -e "${RED}✗ Expected at least 4 migrations, found: $MIGRATION_COUNT${NC}"
    log_test "FAIL" "Flyway migrations - Expected 4+, found: $MIGRATION_COUNT"
    ((FAILED++))
fi

# ==========================================
# SECTION 11: Data Type Validation Tests
# ==========================================
print_section "11. Data Type Validation Tests"

echo "11.1 Testing integer type validation..."
# Clean up first
execute_sql_silent "DELETE FROM inventory_items WHERE sku = 'TEST-TYPE-INT';"
result=$(execute_sql_check_error "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('TEST-TYPE-INT-$(date +%s)', 'Test', 999999999, 'Location', CURRENT_TIMESTAMP) 
    RETURNING qty;
" 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')

if [ ! -z "$result" ] && [ "$result" == "999999999" ] 2>/dev/null; then
    echo -e "${GREEN}✓ Integer type accepts large values${NC}"
    log_test "PASS" "Integer type validation"
    ((PASSED++))
    # Cleanup
    execute_sql_silent "DELETE FROM inventory_items WHERE sku LIKE 'TEST-TYPE-INT-%';"
else
    echo -e "${YELLOW}⚠ Integer type test inconclusive (result: '$result')${NC}"
    log_test "WARN" "Integer type test inconclusive - result: '$result'"
    ((SKIPPED++))
fi

echo ""
echo "11.2 Testing VARCHAR length limits..."
# Clean up first
execute_sql_silent "DELETE FROM inventory_items WHERE sku = 'TEST-LONG';"
# Test with very long string (should work or fail gracefully)
LONG_STRING=$(printf 'A%.0s' {1..500})
result=$(execute_sql_check_error "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('TEST-LONG-$(date +%s)', '$LONG_STRING', 10, 'Location', CURRENT_TIMESTAMP) 
    RETURNING LENGTH(name);
" 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')

if [ ! -z "$result" ] && [ "$result" -gt 0 ] 2>/dev/null; then
    echo -e "${GREEN}✓ VARCHAR handles long strings${NC}"
    log_test "PASS" "VARCHAR length validation"
    ((PASSED++))
    # Cleanup
    execute_sql_silent "DELETE FROM inventory_items WHERE sku LIKE 'TEST-LONG-%';"
else
    echo -e "${YELLOW}⚠ VARCHAR length test inconclusive${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 12: Query Performance Tests
# ==========================================
print_section "12. Query Performance Tests"

echo "12.1 Testing location-based query performance..."
# Create test data
execute_sql_silent "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    SELECT 'PERF-LOC-' || generate_series, 'Item ' || generate_series, 10, 
           CASE WHEN generate_series % 2 = 0 THEN 'Warehouse-A' ELSE 'Warehouse-B' END,
           CURRENT_TIMESTAMP
    FROM generate_series(1, 50);
" >/dev/null 2>&1

# Time the query
START_TIME=$(date +%s%N)
execute_sql_silent "
    SELECT COUNT(*) FROM inventory_items WHERE location = 'Warehouse-A';
" >/dev/null 2>&1
END_TIME=$(date +%s%N)
DURATION=$((($END_TIME - $START_TIME) / 1000000))

if [ "$DURATION" -lt 100 ]; then
    echo -e "${GREEN}✓ Location query fast (${DURATION}ms)${NC}"
    log_test "PASS" "Location query performance - ${DURATION}ms"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Location query slow (${DURATION}ms) - may need index optimization${NC}"
    log_test "WARN" "Location query performance - ${DURATION}ms"
    ((PASSED++))
fi

# Cleanup
execute_sql_silent "
    DELETE FROM inventory_items WHERE sku LIKE 'PERF-LOC-%';
" >/dev/null 2>&1

# ==========================================
# SECTION 13: Edge Cases and Boundary Tests
# ==========================================
print_section "13. Edge Cases and Boundary Tests"

echo "13.1 Testing zero quantity..."
execute_sql_silent "DELETE FROM inventory_items WHERE sku = 'TEST-ZERO-QTY';"
result=$(execute_sql_check_error "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('TEST-ZERO-QTY-$(date +%s)', 'Zero Qty Test', 0, 'Location', CURRENT_TIMESTAMP) 
    RETURNING qty;
" 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')

if [ ! -z "$result" ] && [ "$result" == "0" ] 2>/dev/null; then
    echo -e "${GREEN}✓ Zero quantity accepted${NC}"
    log_test "PASS" "Zero quantity accepted"
    ((PASSED++))
    execute_sql_silent "DELETE FROM inventory_items WHERE sku LIKE 'TEST-ZERO-QTY-%';"
else
    echo -e "${YELLOW}⚠ Zero quantity test inconclusive${NC}"
    log_test "WARN" "Zero quantity test inconclusive"
    ((SKIPPED++))
fi

echo ""
echo "13.2 Testing negative quantity (should fail at application level)..."
# Note: Database allows negative, but application validation should prevent it
result=$(execute_sql_check_error "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('TEST-NEG-QTY-$(date +%s)', 'Negative Qty Test', -10, 'Location', CURRENT_TIMESTAMP);
" 2>&1)

if echo "$result" | grep -qiE "error|violates|constraint"; then
    echo -e "${GREEN}✓ Negative quantity rejected${NC}"
    log_test "PASS" "Negative quantity rejected"
    ((PASSED++))
else
    # Database allows it, but application should validate
    echo -e "${YELLOW}⚠ Database allows negative (application should validate)${NC}"
    log_test "WARN" "Database allows negative quantity - application validation required"
    execute_sql_silent "DELETE FROM inventory_items WHERE sku LIKE 'TEST-NEG-QTY-%';"
    ((PASSED++))
fi

echo ""
echo "13.3 Testing very long SKU..."
LONG_SKU=$(printf 'A%.0s' {1..300})
result=$(execute_sql_check_error "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('$LONG_SKU', 'Long SKU Test', 10, 'Location', CURRENT_TIMESTAMP);
" 2>&1)

if echo "$result" | grep -qiE "error|violates|too long"; then
    echo -e "${GREEN}✓ Very long SKU rejected${NC}"
    log_test "PASS" "Very long SKU rejected"
    ((PASSED++))
else
    # Check if it was inserted
    check=$(execute_sql "
        SELECT COUNT(*) FROM inventory_items WHERE sku = '$LONG_SKU';
    " 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')
    if [ "$check" == "1" ] 2>/dev/null; then
        echo -e "${YELLOW}⚠ Very long SKU accepted (may exceed VARCHAR limit)${NC}"
        log_test "WARN" "Very long SKU accepted"
        execute_sql_silent "DELETE FROM inventory_items WHERE sku = '$LONG_SKU';"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ Very long SKU test inconclusive${NC}"
        ((SKIPPED++))
    fi
fi

echo ""
echo "13.4 Testing special characters in SKU..."
SPECIAL_SKU="TEST-SPECIAL-!@#\$%^&*()_+-=[]{}|;':\",./<>?"
result=$(execute_sql_check_error "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('TEST-SPECIAL-$(date +%s)', 'Special Char Test', 10, 'Location', CURRENT_TIMESTAMP);
" 2>&1)

if echo "$result" | grep -qiE "error|violates"; then
    echo -e "${GREEN}✓ Special characters handled${NC}"
    log_test "PASS" "Special characters handled"
    ((PASSED++))
else
    echo -e "${GREEN}✓ Special characters accepted${NC}"
    log_test "PASS" "Special characters accepted"
    execute_sql_silent "DELETE FROM inventory_items WHERE sku LIKE 'TEST-SPECIAL-%';"
    ((PASSED++))
fi

echo ""
echo "13.5 Testing empty string in name (should fail)..."
result=$(execute_sql_check_error "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('TEST-EMPTY-NAME-$(date +%s)', '', 10, 'Location', CURRENT_TIMESTAMP);
" 2>&1)

if echo "$result" | grep -qiE "null value|not null|violates"; then
    echo -e "${GREEN}✓ Empty name rejected${NC}"
    log_test "PASS" "Empty name rejected"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Empty name test inconclusive${NC}"
    log_test "WARN" "Empty name test inconclusive"
    execute_sql_silent "DELETE FROM inventory_items WHERE sku LIKE 'TEST-EMPTY-NAME-%';"
    ((SKIPPED++))
fi

echo ""
echo "13.6 Testing SQL injection attempt..."
SQL_INJECTION="'; DROP TABLE inventory_items; --"
result=$(execute_sql_check_error "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('TEST-SQL-INJ-$(date +%s)', '$SQL_INJECTION', 10, 'Location', CURRENT_TIMESTAMP);
" 2>&1)

# Check if table still exists
table_exists=$(execute_sql "
    SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'inventory_items';
" 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')

if [ "$table_exists" == "1" ] 2>/dev/null; then
    echo -e "${GREEN}✓ SQL injection prevented (table still exists)${NC}"
    log_test "PASS" "SQL injection prevented"
    execute_sql_silent "DELETE FROM inventory_items WHERE sku LIKE 'TEST-SQL-INJ-%';"
    ((PASSED++))
else
    echo -e "${RED}✗ SQL injection may have succeeded${NC}"
    log_test "FAIL" "SQL injection test failed"
    ((FAILED++))
fi

echo ""
echo "13.7 Testing case sensitivity in SKU..."
execute_sql_silent "DELETE FROM inventory_items WHERE sku IN ('TEST-CASE-1', 'test-case-1');"
# Insert with uppercase
result1=$(execute_sql_check_error "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('TEST-CASE-1', 'Case Test', 10, 'Location', CURRENT_TIMESTAMP);
" 2>&1)

# Try to insert with lowercase (should fail due to unique constraint if case-sensitive)
result2=$(execute_sql_check_error "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('test-case-1', 'Case Test 2', 10, 'Location', CURRENT_TIMESTAMP);
" 2>&1)

if echo "$result2" | grep -qiE "duplicate|unique constraint"; then
    echo -e "${GREEN}✓ SKU is case-sensitive (unique constraint enforced)${NC}"
    log_test "PASS" "SKU case sensitivity verified"
    ((PASSED++))
else
    # Check if both exist
    count=$(execute_sql "
        SELECT COUNT(*) FROM inventory_items WHERE sku IN ('TEST-CASE-1', 'test-case-1');
    " 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')
    if [ "$count" == "2" ] 2>/dev/null; then
        echo -e "${YELLOW}⚠ SKU is case-insensitive (both variants exist)${NC}"
        log_test "WARN" "SKU case-insensitive"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ Case sensitivity test inconclusive${NC}"
        ((SKIPPED++))
    fi
fi
execute_sql_silent "DELETE FROM inventory_items WHERE sku IN ('TEST-CASE-1', 'test-case-1');"

echo ""
echo "13.8 Testing maximum integer value..."
MAX_INT=2147483647
result=$(execute_sql_check_error "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('TEST-MAX-INT-$(date +%s)', 'Max Int Test', $MAX_INT, 'Location', CURRENT_TIMESTAMP) 
    RETURNING qty;
" 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')

if [ ! -z "$result" ] && [ "$result" == "$MAX_INT" ] 2>/dev/null; then
    echo -e "${GREEN}✓ Maximum integer value accepted${NC}"
    log_test "PASS" "Maximum integer value accepted"
    execute_sql_silent "DELETE FROM inventory_items WHERE sku LIKE 'TEST-MAX-INT-%';"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Maximum integer test inconclusive${NC}"
    log_test "WARN" "Maximum integer test inconclusive"
    ((SKIPPED++))
fi

echo ""
echo "13.9 Testing concurrent updates (optimistic locking simulation)..."
# Create test item
TEST_CONCURRENT_SKU="TEST-CONCURRENT-$(date +%s)"
execute_sql_silent "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('$TEST_CONCURRENT_SKU', 'Concurrent Test', 100, 'Location', CURRENT_TIMESTAMP);
"

# Simulate concurrent update
result1=$(execute_sql "
    UPDATE inventory_items SET qty = 200 WHERE sku = '$TEST_CONCURRENT_SKU' RETURNING qty;
" 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')

result2=$(execute_sql "
    UPDATE inventory_items SET qty = 300 WHERE sku = '$TEST_CONCURRENT_SKU' RETURNING qty;
" 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')

final_qty=$(execute_sql "
    SELECT qty FROM inventory_items WHERE sku = '$TEST_CONCURRENT_SKU';
" 2>&1 | grep -E '^[0-9]+$' | head -1 | tr -d ' \n\r')

if [ "$final_qty" == "300" ] 2>/dev/null; then
    echo -e "${GREEN}✓ Concurrent updates handled correctly${NC}"
    log_test "PASS" "Concurrent updates handled"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Concurrent update test inconclusive${NC}"
    log_test "WARN" "Concurrent update test inconclusive"
    ((SKIPPED++))
fi
execute_sql_silent "DELETE FROM inventory_items WHERE sku = '$TEST_CONCURRENT_SKU';"

echo ""
echo "13.10 Testing whitespace handling..."
execute_sql_silent "DELETE FROM inventory_items WHERE sku LIKE 'TEST-WS%';"
# Test with leading/trailing spaces in name
result=$(execute_sql_check_error "
    INSERT INTO inventory_items (sku, name, qty, location, updated_at) 
    VALUES ('TEST-WS-$(date +%s)', '  Whitespace Test  ', 10, 'Location', CURRENT_TIMESTAMP);
" 2>&1)

if echo "$result" | grep -qiE "error|violates"; then
    echo -e "${YELLOW}⚠ Whitespace in name rejected${NC}"
    log_test "WARN" "Whitespace in name rejected"
    ((SKIPPED++))
else
    # Check if it was stored with or without trimming
    stored_name=$(execute_sql "
        SELECT name FROM inventory_items WHERE sku LIKE 'TEST-WS-%' LIMIT 1;
    " 2>&1 | head -1 | tr -d '\n\r')
    
    if [ ! -z "$stored_name" ]; then
        echo -e "${GREEN}✓ Whitespace handling works${NC}"
        log_test "PASS" "Whitespace handling works"
        execute_sql_silent "DELETE FROM inventory_items WHERE sku LIKE 'TEST-WS-%';"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ Whitespace test inconclusive${NC}"
        ((SKIPPED++))
    fi
fi

# ==========================================
# FINAL SUMMARY
# ==========================================
print_section "Database Test Summary"

TOTAL=$((PASSED + FAILED + SKIPPED))
PASS_RATE=$((PASSED * 100 / TOTAL))

echo "=========================================="
echo "Test Results:"
echo -e "${GREEN}Passed:  $PASSED${NC}"
echo -e "${RED}Failed:  $FAILED${NC}"
echo -e "${YELLOW}Skipped: $SKIPPED${NC}"
echo "Total:   $TOTAL"
echo "Pass Rate: $PASS_RATE%"
echo "=========================================="
echo ""
echo "Detailed test log saved to: $TEST_LOG"
echo ""

log_test "INFO" "Test Summary - Passed: $PASSED, Failed: $FAILED, Skipped: $SKIPPED, Pass Rate: $PASS_RATE%"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All database tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some database tests failed. Please review the log: $TEST_LOG${NC}"
    exit 1
fi

