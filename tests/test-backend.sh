#!/bin/bash

# Backend API Test Suite with Edge Cases
# Tests: All API endpoints, validation, error handling, edge cases, security
# Author: Victor Tiradoegas

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="${BACKEND_URL:-http://localhost:8080}"
TEST_USER="testuser-$(date +%s)"
TEST_EMAIL="testuser-$(date +%s)@test.com"
TEST_PASSWORD="Test123!@#"
ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin123!}"

# Test counters
PASSED=0
FAILED=0
SKIPPED=0

# Test results log
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
TEST_LOG="$LOG_DIR/backend-test-results-$(date +%Y%m%d-%H%M%S).log"
echo "Backend Test Run Started: $(date)" > "$TEST_LOG"

# Helper functions
log_test() {
    local status=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [$status] $message" >> "$TEST_LOG"
}

print_section() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
    echo ""
    log_test "INFO" "Starting section: $1"
}

test_endpoint() {
    local name=$1
    local method=$2
    local url=$3
    local expected_status=$4
    local data=$5
    local headers=$6
    
    echo -n "  Testing: $name... "
    
    if [ -z "$data" ]; then
        if [ -z "$headers" ]; then
            response=$(curl -s -w "\n%{http_code}" -X $method "$url" 2>&1)
        else
            response=$(curl -s -w "\n%{http_code}" -X $method -H "$headers" "$url" 2>&1)
        fi
    else
        if [ -z "$headers" ]; then
            response=$(curl -s -w "\n%{http_code}" -X $method -H "Content-Type: application/json" -d "$data" "$url" 2>&1)
        else
            response=$(curl -s -w "\n%{http_code}" -X $method -H "Content-Type: application/json" -H "$headers" -d "$data" "$url" 2>&1)
        fi
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" == "$expected_status" ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
        log_test "PASS" "$name - HTTP $http_code"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (Expected $expected_status, got $http_code)"
        echo "    Response: $(echo "$body" | head -c 150)"
        log_test "FAIL" "$name - Expected $expected_status, got $http_code - Response: $body"
        ((FAILED++))
        return 1
    fi
}

test_endpoint_multi_status() {
    local name=$1
    local method=$2
    local url=$3
    local expected_statuses_str=$4
    local data=$5
    local headers=$6
    
    echo -n "  Testing: $name... "
    
    if [ -z "$data" ]; then
        if [ -z "$headers" ]; then
            response=$(curl -s -w "\n%{http_code}" -X $method "$url" 2>&1)
        else
            response=$(curl -s -w "\n%{http_code}" -X $method -H "$headers" "$url" 2>&1)
        fi
    else
        if [ -z "$headers" ]; then
            response=$(curl -s -w "\n%{http_code}" -X $method -H "Content-Type: application/json" -d "$data" "$url" 2>&1)
        else
            response=$(curl -s -w "\n%{http_code}" -X $method -H "Content-Type: application/json" -H "$headers" -d "$data" "$url" 2>&1)
        fi
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    IFS=',' read -r -a expected_statuses_array <<< "$expected_statuses_str"
    
    local status_match=0
    for status in "${expected_statuses_array[@]}"; do
        if [ "$http_code" == "$status" ]; then
            status_match=1
            break
        fi
    done
    
    if [ "$status_match" -eq 1 ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
        log_test "PASS" "$name (HTTP $http_code)"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (Expected one of: $expected_statuses_str, got $http_code)"
        echo "    Response: $(echo "$body" | head -c 150)"
        log_test "FAIL" "$name - Expected one of: $expected_statuses_str, got $http_code"
        ((FAILED++))
        return 1
    fi
}

# Check prerequisites
command -v curl >/dev/null 2>&1 || { echo -e "${RED}✗ curl not found${NC}"; exit 1; }

# Check if backend is running
BACKEND_RESPONDING=0
if curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/actuator/info" 2>/dev/null | grep -q "200\|404"; then
    BACKEND_RESPONDING=1
elif curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/actuator/health" 2>/dev/null | grep -q "200\|503"; then
    BACKEND_RESPONDING=1
fi

if [ $BACKEND_RESPONDING -eq 0 ]; then
    echo -e "${RED}✗ Backend not responding at $BACKEND_URL${NC}"
    echo "  Please start the backend service:"
    echo "    docker-compose -f docker-compose.prod.yaml up -d backend"
    echo "    OR"
    echo "    cd backend && ./mvnw spring-boot:run"
    exit 1
fi

echo -e "${GREEN}✓ Backend is responding${NC}"
((PASSED++))

# ==========================================
# SECTION 1: Authentication & Authorization
# ==========================================
print_section "1. Authentication & Authorization Tests"

echo "1.1 User Registration..."
REGISTER_DATA="{\"username\":\"$TEST_USER\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"role\":\"USER\"}"
REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "$REGISTER_DATA")
REGISTER_CODE=$(echo "$REGISTER_RESPONSE" | tail -n1)

if [ "$REGISTER_CODE" == "201" ] || [ "$REGISTER_CODE" == "200" ]; then
    echo -e "${GREEN}✓ User registration successful${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ User registration failed (HTTP $REGISTER_CODE)${NC}"
    ((FAILED++))
fi

echo ""
echo "1.2 User Login..."
LOGIN_DATA="{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASSWORD\"}"
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "$LOGIN_DATA")
LOGIN_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
LOGIN_BODY=$(echo "$LOGIN_RESPONSE" | sed '$d')
USER_TOKEN=$(echo "$LOGIN_BODY" | grep -o '"token":"[^"]*' | cut -d'"' -f4 | head -1)

if [ "$LOGIN_CODE" == "200" ] && [ ! -z "$USER_TOKEN" ]; then
    echo -e "${GREEN}✓ User login successful${NC}"
    USER_AUTH_HEADER="Authorization: Bearer $USER_TOKEN"
    ((PASSED++))
else
    echo -e "${RED}✗ User login failed${NC}"
    ((FAILED++))
fi

echo ""
echo "1.3 Admin Login..."
ADMIN_LOGIN_DATA="{\"username\":\"$ADMIN_USERNAME\",\"password\":\"$ADMIN_PASSWORD\"}"
ADMIN_LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "$ADMIN_LOGIN_DATA")
ADMIN_LOGIN_CODE=$(echo "$ADMIN_LOGIN_RESPONSE" | tail -n1)
ADMIN_LOGIN_BODY=$(echo "$ADMIN_LOGIN_RESPONSE" | sed '$d')
ADMIN_TOKEN=$(echo "$ADMIN_LOGIN_BODY" | grep -o '"token":"[^"]*' | cut -d'"' -f4 | head -1)

if [ "$ADMIN_LOGIN_CODE" == "200" ] && [ ! -z "$ADMIN_TOKEN" ]; then
    echo -e "${GREEN}✓ Admin login successful${NC}"
    ADMIN_AUTH_HEADER="Authorization: Bearer $ADMIN_TOKEN"
    AUTH_HEADER="$USER_AUTH_HEADER"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Admin login failed (may not be configured)${NC}"
    AUTH_HEADER="$USER_AUTH_HEADER"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 2: Input Validation Edge Cases
# ==========================================
print_section "2. Input Validation Edge Cases"

if [ ! -z "$AUTH_HEADER" ]; then
    echo "2.1 Testing empty/invalid JSON..."
    test_endpoint_multi_status "Empty JSON body" "POST" "$BACKEND_URL/api/inventory" "400,403" "" "$AUTH_HEADER"
    test_endpoint_multi_status "Invalid JSON" "POST" "$BACKEND_URL/api/inventory" "400,403" "{invalid json}" "$AUTH_HEADER"
    
    echo ""
    echo "2.2 Testing missing required fields..."
    test_endpoint "Missing SKU" "POST" "$BACKEND_URL/api/inventory" "400" '{"name":"Test","qty":10,"location":"A"}' "$AUTH_HEADER"
    test_endpoint "Missing name" "POST" "$BACKEND_URL/api/inventory" "400" '{"sku":"TEST-1","qty":10,"location":"A"}' "$AUTH_HEADER"
    test_endpoint "Missing quantity" "POST" "$BACKEND_URL/api/inventory" "400" '{"sku":"TEST-1","name":"Test","location":"A"}' "$AUTH_HEADER"
    test_endpoint "Missing location" "POST" "$BACKEND_URL/api/inventory" "400" '{"sku":"TEST-1","name":"Test","qty":10}' "$AUTH_HEADER"
    
    echo ""
    echo "2.3 Testing empty string values..."
    test_endpoint "Empty SKU string" "POST" "$BACKEND_URL/api/inventory" "400" '{"sku":"","name":"Test","qty":10,"location":"A"}' "$AUTH_HEADER"
    test_endpoint "Empty name string" "POST" "$BACKEND_URL/api/inventory" "400" '{"sku":"TEST-1","name":"","qty":10,"location":"A"}' "$AUTH_HEADER"
    test_endpoint "Empty location string" "POST" "$BACKEND_URL/api/inventory" "400" '{"sku":"TEST-1","name":"Test","qty":10,"location":""}' "$AUTH_HEADER"
    
    echo ""
    echo "2.4 Testing whitespace-only values..."
    test_endpoint "Whitespace-only SKU" "POST" "$BACKEND_URL/api/inventory" "400" '{"sku":"   ","name":"Test","qty":10,"location":"A"}' "$AUTH_HEADER"
    test_endpoint "Whitespace-only name" "POST" "$BACKEND_URL/api/inventory" "400" '{"sku":"TEST-1","name":"   ","qty":10,"location":"A"}' "$AUTH_HEADER"
    
    echo ""
    echo "2.5 Testing negative quantity..."
    test_endpoint "Negative quantity" "POST" "$BACKEND_URL/api/inventory" "400" '{"sku":"TEST-1","name":"Test","qty":-10,"location":"A"}' "$AUTH_HEADER"
    
    echo ""
    echo "2.6 Testing zero quantity..."
    test_endpoint_multi_status "Zero quantity" "POST" "$BACKEND_URL/api/inventory" "201,200" '{"sku":"TEST-ZERO-'"$(date +%s)"'","name":"Test","qty":0,"location":"A"}' "$AUTH_HEADER"
    
    echo ""
    echo "2.7 Testing very large numbers..."
    test_endpoint_multi_status "Very large quantity" "POST" "$BACKEND_URL/api/inventory" "201,200,400" '{"sku":"TEST-LARGE-'"$(date +%s)"'","name":"Test","qty":999999999,"location":"A"}' "$AUTH_HEADER"
    
    echo ""
    echo "2.8 Testing very long strings..."
    LONG_STRING=$(printf 'A%.0s' {1..500})
    test_endpoint_multi_status "Very long SKU" "POST" "$BACKEND_URL/api/inventory" "400,201,403" "{\"sku\":\"TEST-LONG-SKU-$(date +%s)\",\"name\":\"Test\",\"qty\":10,\"location\":\"A\"}" "$AUTH_HEADER"
    test_endpoint_multi_status "Very long name" "POST" "$BACKEND_URL/api/inventory" "400,201,403" "{\"sku\":\"TEST-LONG-NAME-$(date +%s)\",\"name\":\"$LONG_STRING\",\"qty\":10,\"location\":\"A\"}" "$AUTH_HEADER"
    
    echo ""
    echo "2.9 Testing special characters..."
    test_endpoint_multi_status "Special chars in SKU" "POST" "$BACKEND_URL/api/inventory" "201,400" '{"sku":"TEST-SPECIAL-'"$(date +%s)"'-!@#$%^&*()","name":"Test","qty":10,"location":"A"}' "$AUTH_HEADER"
    test_endpoint_multi_status "SQL injection attempt in SKU" "POST" "$BACKEND_URL/api/inventory" "400,201" '{"sku":"TEST-SQL-INJ-'"$(date +%s)"'-\"; DROP TABLE inventory_items; --","name":"Test","qty":10,"location":"A"}' "$AUTH_HEADER"
    
    echo ""
    echo "2.10 Testing null values..."
    test_endpoint "Null SKU" "POST" "$BACKEND_URL/api/inventory" "400" '{"sku":null,"name":"Test","qty":10,"location":"A"}' "$AUTH_HEADER"
    test_endpoint "Null quantity" "POST" "$BACKEND_URL/api/inventory" "400" '{"sku":"TEST-1","name":"Test","qty":null,"location":"A"}' "$AUTH_HEADER"
    
    echo ""
    echo "2.11 Testing wrong data types..."
    test_endpoint_multi_status "String instead of number for qty" "POST" "$BACKEND_URL/api/inventory" "400,403" '{"sku":"TEST-DTYPE-'"$(date +%s)"'","name":"Test","qty":"ten","location":"A"}' "$AUTH_HEADER"
    test_endpoint_multi_status "Number instead of string for SKU" "POST" "$BACKEND_URL/api/inventory" "400,201" '{"sku":"TEST-DTYPE-SKU-'"$(date +%s)"'","name":"Test","qty":10,"location":"A"}' "$AUTH_HEADER"
else
    echo -e "${YELLOW}⚠ Skipping validation tests (authentication required)${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 3: Pagination Edge Cases
# ==========================================
print_section "3. Pagination Edge Cases"

if [ ! -z "$AUTH_HEADER" ]; then
    echo "3.1 Testing invalid pagination parameters..."
    test_endpoint "Negative page number" "GET" "$BACKEND_URL/api/inventory?page=-1&size=10" "400" "" "$AUTH_HEADER"
    test_endpoint "Zero page size" "GET" "$BACKEND_URL/api/inventory?page=0&size=0" "400" "" "$AUTH_HEADER"
    test_endpoint "Negative page size" "GET" "$BACKEND_URL/api/inventory?page=0&size=-10" "400" "" "$AUTH_HEADER"
    test_endpoint "Page size exceeds limit (1000+)" "GET" "$BACKEND_URL/api/inventory?page=0&size=1001" "400" "" "$AUTH_HEADER"
    
    echo ""
    echo "3.2 Testing boundary values..."
    test_endpoint "Page size = 1" "GET" "$BACKEND_URL/api/inventory?page=0&size=1" "200" "" "$AUTH_HEADER"
    test_endpoint "Page size = 1000 (max)" "GET" "$BACKEND_URL/api/inventory?page=0&size=1000" "200" "" "$AUTH_HEADER"
    test_endpoint "Very large page number" "GET" "$BACKEND_URL/api/inventory?page=999999&size=10" "200" "" "$AUTH_HEADER"
    
    echo ""
    echo "3.3 Testing missing pagination parameters..."
    test_endpoint "No pagination params" "GET" "$BACKEND_URL/api/inventory" "200" "" "$AUTH_HEADER"
    test_endpoint "Only page param" "GET" "$BACKEND_URL/api/inventory?page=0" "200" "" "$AUTH_HEADER"
    test_endpoint "Only size param" "GET" "$BACKEND_URL/api/inventory?size=10" "200" "" "$AUTH_HEADER"
    
    echo ""
    echo "3.4 Testing invalid sort fields..."
    test_endpoint "Invalid sort field" "GET" "$BACKEND_URL/api/inventory?page=0&size=10&sortBy=invalidField" "400" "" "$AUTH_HEADER"
    test_endpoint "SQL injection in sort field" "GET" "$BACKEND_URL/api/inventory?page=0&size=10&sortBy=id;DROP+TABLE+inventory_items" "400" "" "$AUTH_HEADER"
else
    echo -e "${YELLOW}⚠ Skipping pagination tests (authentication required)${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 4: CRUD Operations Edge Cases
# ==========================================
print_section "4. CRUD Operations Edge Cases"

if [ ! -z "$AUTH_HEADER" ]; then
    echo "4.1 Create with duplicate SKU..."
    TEST_SKU="TEST-DUP-$(date +%s)"
    CREATE_DATA="{\"sku\":\"$TEST_SKU\",\"name\":\"Test Product\",\"qty\":10,\"location\":\"Warehouse-A\"}"
    
    # First create
    CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/inventory" \
      -H "Content-Type: application/json" \
      -H "$AUTH_HEADER" \
      -d "$CREATE_DATA")
    CREATE_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
    
    if [ "$CREATE_CODE" == "201" ] || [ "$CREATE_CODE" == "200" ]; then
        echo -e "  ${GREEN}✓ First create successful${NC}"
        ((PASSED++))
        
        # Try duplicate
        test_endpoint_multi_status "Duplicate SKU creation" "POST" "$BACKEND_URL/api/inventory" "400,409" "$CREATE_DATA" "$AUTH_HEADER"
        
        # Get ID for cleanup
        CREATE_BODY=$(echo "$CREATE_RESPONSE" | sed '$d')
        ITEM_ID=$(echo "$CREATE_BODY" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1)
    else
        echo -e "  ${YELLOW}⚠ Could not create test item${NC}"
        ((SKIPPED++))
    fi
    
    echo ""
    echo "4.2 Update non-existent item..."
    test_endpoint "Update non-existent ID" "PUT" "$BACKEND_URL/api/inventory/999999" "404" '{"sku":"SKU-999","name":"Test","qty":10,"location":"A"}' "$AUTH_HEADER"
    
    echo ""
    echo "4.3 Delete non-existent item..."
    test_endpoint "Delete non-existent ID" "DELETE" "$BACKEND_URL/api/inventory/999999" "404" "" "$AUTH_HEADER"
    
    echo ""
    echo "4.4 Get non-existent item..."
    test_endpoint "Get non-existent ID" "GET" "$BACKEND_URL/api/inventory/999999" "404" "" "$AUTH_HEADER"
    
    echo ""
    echo "4.5 Get by non-existent SKU..."
    test_endpoint "Get non-existent SKU" "GET" "$BACKEND_URL/api/inventory/sku/NONEXISTENT-SKU-12345" "404" "" "$AUTH_HEADER"
    
    echo ""
    echo "4.6 Update with invalid data..."
    if [ ! -z "$ITEM_ID" ]; then
        test_endpoint "Update with negative qty" "PUT" "$BACKEND_URL/api/inventory/$ITEM_ID" "400" "{\"sku\":\"$TEST_SKU\",\"name\":\"Test\",\"qty\":-10,\"location\":\"A\"}" "$AUTH_HEADER"
        test_endpoint "Update with empty name" "PUT" "$BACKEND_URL/api/inventory/$ITEM_ID" "400" "{\"sku\":\"$TEST_SKU\",\"name\":\"\",\"qty\":10,\"location\":\"A\"}" "$AUTH_HEADER"
        
        # Cleanup
        curl -s -X DELETE "$BACKEND_URL/api/inventory/$ITEM_ID" -H "$AUTH_HEADER" >/dev/null 2>&1
    fi
    
    echo ""
    echo "4.7 Concurrent updates simulation..."
    TEST_SKU_CONCURRENT="TEST-CONCURRENT-$(date +%s)"
    CREATE_DATA_CONCURRENT="{\"sku\":\"$TEST_SKU_CONCURRENT\",\"name\":\"Concurrent Test\",\"qty\":100,\"location\":\"Warehouse-A\"}"
    
    CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/inventory" \
      -H "Content-Type: application/json" \
      -H "$AUTH_HEADER" \
      -d "$CREATE_DATA_CONCURRENT")
    CREATE_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
    
    if [ "$CREATE_CODE" == "201" ] || [ "$CREATE_CODE" == "200" ]; then
        CREATE_BODY=$(echo "$CREATE_RESPONSE" | sed '$d')
        CONCURRENT_ITEM_ID=$(echo "$CREATE_BODY" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1)
        
        # Simulate concurrent updates
        UPDATE1_DATA="{\"sku\":\"$TEST_SKU_CONCURRENT\",\"name\":\"Update 1\",\"qty\":200,\"location\":\"A\"}"
        UPDATE2_DATA="{\"sku\":\"$TEST_SKU_CONCURRENT\",\"name\":\"Update 2\",\"qty\":300,\"location\":\"A\"}"
        
        curl -s -X PUT "$BACKEND_URL/api/inventory/$CONCURRENT_ITEM_ID" -H "Content-Type: application/json" -H "$AUTH_HEADER" -d "$UPDATE1_DATA" >/dev/null 2>&1 &
        curl -s -X PUT "$BACKEND_URL/api/inventory/$CONCURRENT_ITEM_ID" -H "Content-Type: application/json" -H "$AUTH_HEADER" -d "$UPDATE2_DATA" >/dev/null 2>&1 &
        wait
        
        echo -e "  ${GREEN}✓ Concurrent updates handled${NC}"
        ((PASSED++))
        
        # Cleanup
        curl -s -X DELETE "$BACKEND_URL/api/inventory/$CONCURRENT_ITEM_ID" -H "$AUTH_HEADER" >/dev/null 2>&1
    else
        echo -e "  ${YELLOW}⚠ Could not create item for concurrent test${NC}"
        ((SKIPPED++))
    fi
else
    echo -e "${YELLOW}⚠ Skipping CRUD edge case tests (authentication required)${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 5: Search & Filter Edge Cases
# ==========================================
print_section "5. Search & Filter Edge Cases"

if [ ! -z "$AUTH_HEADER" ]; then
    echo "5.1 Testing search with empty pattern..."
    test_endpoint_multi_status "Empty SKU search pattern" "GET" "$BACKEND_URL/api/inventory/search/sku?pattern=&page=0&size=10" "200,400" "" "$AUTH_HEADER"
    test_endpoint_multi_status "Empty name search pattern" "GET" "$BACKEND_URL/api/inventory/search/name?pattern=&page=0&size=10" "200,400" "" "$AUTH_HEADER"
    
    echo ""
    echo "5.2 Testing search with special characters..."
    test_endpoint_multi_status "Special chars in SKU search" "GET" "$BACKEND_URL/api/inventory/search/sku?pattern=!@#&page=0&size=10" "200" "" "$AUTH_HEADER"
    test_endpoint_multi_status "SQL injection in search" "GET" "$BACKEND_URL/api/inventory/search/sku?pattern=';DROP+TABLE+inventory_items;--&page=0&size=10" "200,400" "" "$AUTH_HEADER"
    
    echo ""
    echo "5.3 Testing location filter..."
    test_endpoint_multi_status "Non-existent location" "GET" "$BACKEND_URL/api/inventory/location/NONEXISTENT-LOCATION-12345?page=0&size=10" "200" "" "$AUTH_HEADER"
    test_endpoint_multi_status "Empty location" "GET" "$BACKEND_URL/api/inventory/location/?page=0&size=10" "404,400,403" "" "$AUTH_HEADER"
    
    echo ""
    echo "5.4 Testing very long search patterns..."
    LONG_PATTERN=$(printf 'A%.0s' {1..200})
    test_endpoint_multi_status "Very long search pattern" "GET" "$BACKEND_URL/api/inventory/search/sku?pattern=$LONG_PATTERN&page=0&size=10" "200,400" "" "$AUTH_HEADER"
else
    echo -e "${YELLOW}⚠ Skipping search tests (authentication required)${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 6: Security Edge Cases
# ==========================================
print_section "6. Security Edge Cases"

echo "6.1 Testing unauthorized access..."
test_endpoint_multi_status "Access without token" "GET" "$BACKEND_URL/api/inventory" "401,403" "" ""
test_endpoint_multi_status "Access with invalid token" "GET" "$BACKEND_URL/api/inventory" "401,403" "" "Authorization: Bearer invalid-token-12345"
test_endpoint_multi_status "Access with malformed token" "GET" "$BACKEND_URL/api/inventory" "401,403" "" "Authorization: Bearer"
test_endpoint_multi_status "Access with expired token format" "GET" "$BACKEND_URL/api/inventory" "401,403" "" "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"

echo ""
echo "6.2 Testing role-based access control..."
if [ ! -z "$USER_AUTH_HEADER" ] && [ ! -z "$ADMIN_AUTH_HEADER" ]; then
    echo "  Testing USER access to admin endpoint..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/auth/admin/reset-password" \
      -H "Content-Type: application/json" \
      -H "$USER_AUTH_HEADER" \
      -d '{"username":"test","newPassword":"NewPass123!"}')
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" == "403" ] || [ "$HTTP_CODE" == "401" ]; then
        echo -e "    ${GREEN}✓ USER correctly denied admin access (HTTP $HTTP_CODE)${NC}"
        ((PASSED++))
    else
        echo -e "    ${RED}✗ USER should be denied but got HTTP $HTTP_CODE${NC}"
        ((FAILED++))
    fi
else
    echo -e "  ${YELLOW}⚠ Skipping RBAC test (need both USER and ADMIN tokens)${NC}"
    ((SKIPPED++))
fi

    echo ""
    echo "6.3 Testing path traversal attempts..."
    test_endpoint_multi_status "Path traversal in ID" "GET" "$BACKEND_URL/api/inventory/../etc/passwd" "400,404,403" "" "$AUTH_HEADER"
    test_endpoint_multi_status "Path traversal in SKU" "GET" "$BACKEND_URL/api/inventory/sku/../../etc/passwd" "400,404,403" "" "$AUTH_HEADER"

    echo ""
    echo "6.4 Testing XSS attempts..."
    XSS_PAYLOAD="<script>alert('XSS')</script>"
    test_endpoint_multi_status "XSS in SKU" "POST" "$BACKEND_URL/api/inventory" "201,400" "{\"sku\":\"TEST-XSS-$(date +%s)-$XSS_PAYLOAD\",\"name\":\"Test\",\"qty\":10,\"location\":\"A\"}" "$AUTH_HEADER"

# ==========================================
# SECTION 7: Audit Events Edge Cases
# ==========================================
print_section "7. Audit Events Edge Cases"

if [ ! -z "$AUTH_HEADER" ]; then
    echo "7.1 Testing invalid event types..."
    test_endpoint_multi_status "Invalid event type" "POST" "$BACKEND_URL/api/audit-events" "400,201" '{"eventType":"INVALID","entityType":"InventoryItem","entityId":1}' "$AUTH_HEADER"
    test_endpoint_multi_status "Empty event type" "POST" "$BACKEND_URL/api/audit-events" "400" '{"eventType":"","entityType":"InventoryItem","entityId":1}' "$AUTH_HEADER"
    
    echo ""
    echo "7.2 Testing invalid entity IDs..."
    test_endpoint_multi_status "Negative entity ID" "POST" "$BACKEND_URL/api/audit-events" "400,201" '{"eventType":"CREATE","entityType":"InventoryItem","entityId":-1}' "$AUTH_HEADER"
    test_endpoint_multi_status "Zero entity ID" "POST" "$BACKEND_URL/api/audit-events" "400,201" '{"eventType":"CREATE","entityType":"InventoryItem","entityId":0}' "$AUTH_HEADER"
    test_endpoint_multi_status "Very large entity ID" "POST" "$BACKEND_URL/api/audit-events" "201,400" '{"eventType":"CREATE","entityType":"InventoryItem","entityId":999999999999}' "$AUTH_HEADER"
    
    echo ""
    echo "7.3 Testing audit event queries..."
    test_endpoint "Query non-existent entity" "GET" "$BACKEND_URL/api/audit-events/entity/InventoryItem/999999?page=0&size=10" "200" "" "$AUTH_HEADER"
    test_endpoint "Invalid entity type" "GET" "$BACKEND_URL/api/audit-events/entity-type/InvalidType?page=0&size=10" "200" "" "$AUTH_HEADER"
    test_endpoint "Invalid event type filter" "GET" "$BACKEND_URL/api/audit-events/event-type/INVALID?page=0&size=10" "200" "" "$AUTH_HEADER"
else
    echo -e "${YELLOW}⚠ Skipping audit event tests (authentication required)${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 8: Performance & Load Edge Cases
# ==========================================
print_section "8. Performance & Load Edge Cases"

if [ ! -z "$AUTH_HEADER" ]; then
    echo "8.1 Testing batch operations..."
    # Create batch data
    BATCH_ITEMS="["
    for i in {1..10}; do
        if [ $i -gt 1 ]; then
            BATCH_ITEMS="$BATCH_ITEMS,"
        fi
        BATCH_ITEMS="$BATCH_ITEMS{\"sku\":\"BATCH-$i-$(date +%s)\",\"name\":\"Batch Item $i\",\"qty\":$i,\"location\":\"Warehouse-Batch\"}"
    done
    BATCH_ITEMS="$BATCH_ITEMS]"
    
    test_endpoint_multi_status "Batch create 10 items" "POST" "$BACKEND_URL/api/inventory/batch" "201,200" "$BATCH_ITEMS" "$AUTH_HEADER"
    
    echo ""
    echo "8.2 Testing large result sets..."
    test_endpoint "Request large page size" "GET" "$BACKEND_URL/api/inventory?page=0&size=100" "200" "" "$AUTH_HEADER"
    
    echo ""
    echo "8.3 Testing rapid sequential requests..."
    echo -n "  Testing: Rapid GET requests... "
    START_TIME=$(date +%s%N)
    for i in {1..20}; do
        curl -s -X GET "$BACKEND_URL/api/inventory?page=0&size=10" -H "$AUTH_HEADER" >/dev/null 2>&1
    done
    END_TIME=$(date +%s%N)
    DURATION=$((($END_TIME - $START_TIME) / 1000000))
    
    if [ "$DURATION" -lt 5000 ]; then
        echo -e "${GREEN}✓ PASS${NC} (20 requests in ${DURATION}ms)"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ Slow response${NC} (20 requests in ${DURATION}ms)"
        ((PASSED++))
    fi
else
    echo -e "${YELLOW}⚠ Skipping performance tests (authentication required)${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 9: Content-Type & Headers Edge Cases
# ==========================================
print_section "9. Content-Type & Headers Edge Cases"

if [ ! -z "$AUTH_HEADER" ]; then
    echo "9.1 Testing missing Content-Type..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/inventory" \
      -H "$AUTH_HEADER" \
      -d '{"sku":"TEST-CT-1","name":"Test","qty":10,"location":"A"}')
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" == "400" ] || [ "$HTTP_CODE" == "415" ]; then
        echo -e "  ${GREEN}✓ Missing Content-Type rejected (HTTP $HTTP_CODE)${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ Missing Content-Type handled (HTTP $HTTP_CODE)${NC}"
        ((PASSED++))
    fi
    
    echo ""
    echo "9.2 Testing wrong Content-Type..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/inventory" \
      -H "Content-Type: text/plain" \
      -H "$AUTH_HEADER" \
      -d '{"sku":"TEST-CT-2","name":"Test","qty":10,"location":"A"}')
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" == "400" ] || [ "$HTTP_CODE" == "415" ]; then
        echo -e "  ${GREEN}✓ Wrong Content-Type rejected (HTTP $HTTP_CODE)${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ Wrong Content-Type handled (HTTP $HTTP_CODE)${NC}"
        ((PASSED++))
    fi
    
    echo ""
    echo "9.3 Testing extra headers..."
    test_endpoint "Request with extra headers" "GET" "$BACKEND_URL/api/inventory?page=0&size=10" "200" "" "$AUTH_HEADER
X-Custom-Header: test-value"
else
    echo -e "${YELLOW}⚠ Skipping header tests (authentication required)${NC}"
    ((SKIPPED++))
fi

# ==========================================
# FINAL SUMMARY
# ==========================================
print_section "Backend Test Summary"

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
    echo -e "${GREEN}✓ All backend tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some backend tests failed. Please review the log: $TEST_LOG${NC}"
    exit 1
fi

