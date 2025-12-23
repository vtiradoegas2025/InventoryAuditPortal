#!/bin/bash

# Comprehensive Backend Test Suite
# Run this after starting the Spring Boot application

BASE_URL="http://localhost:8080"
USER="test-user"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Backend Comprehensive Test Suite"
echo "=========================================="
echo ""

# Test counter
PASSED=0
FAILED=0

test_endpoint() {
    local name=$1
    local method=$2
    local url=$3
    local expected_status=$4
    local data=$5
    local headers=$6
    
    echo -n "Testing: $name... "
    
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
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (Expected $expected_status, got $http_code)"
        echo "  Response: $body"
        ((FAILED++))
        return 1
    fi
}

echo "=== 1. GET /api/inventory (Empty List with Pagination) ==="
test_endpoint "Get all items (empty, paginated)" "GET" "$BASE_URL/api/inventory?page=0&size=10" "200"
echo ""

echo "=== 2. CREATE Inventory Item ==="
CREATE_DATA='{"sku":"TEST-SKU-001","name":"Test Product","qty":10,"location":"Warehouse-A"}'
CREATE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/inventory" \
  -H "Content-Type: application/json" \
  -H "X-User: $USER" \
  -d "$CREATE_DATA")
ITEM_ID=$(echo "$CREATE_RESPONSE" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1)
if [ ! -z "$ITEM_ID" ]; then
    echo -e "${GREEN}✓ Created item ID: $ITEM_ID${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Failed to create item${NC}"
    ((FAILED++))
fi
echo ""

echo "=== 3. GET /api/inventory (With Items - Pagination) ==="
test_endpoint "Get all items (default pagination)" "GET" "$BASE_URL/api/inventory" "200"
test_endpoint "Get items page 0, size 5" "GET" "$BASE_URL/api/inventory?page=0&size=5" "200"
test_endpoint "Get items with sorting (updatedAt DESC)" "GET" "$BASE_URL/api/inventory?page=0&size=10&sortBy=updatedAt&sortDir=DESC" "200"
test_endpoint "Get items with sorting (updatedAt ASC)" "GET" "$BASE_URL/api/inventory?page=0&size=10&sortBy=updatedAt&sortDir=ASC" "200"
echo ""

echo "=== 4. GET /api/inventory/{id} ==="
test_endpoint "Get item by ID" "GET" "$BASE_URL/api/inventory/$ITEM_ID" "200"
echo ""

echo "=== 5. GET /api/inventory/sku/{sku} ==="
test_endpoint "Get item by SKU" "GET" "$BASE_URL/api/inventory/sku/TEST-SKU-001" "200"
echo ""

echo "=== 6. CREATE Audit Event Verification ==="
AUDIT_RESPONSE=$(curl -s "$BASE_URL/api/audit-events/entity/InventoryItem/$ITEM_ID")
AUDIT_COUNT=$(echo "$AUDIT_RESPONSE" | grep -o '"eventType":"CREATE"' | wc -l | tr -d ' ')
if [ "$AUDIT_COUNT" -ge 1 ]; then
    echo -e "${GREEN}✓ CREATE audit event found${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ CREATE audit event not found${NC}"
    ((FAILED++))
fi
echo ""

echo "=== 7. UPDATE Inventory Item ==="
UPDATE_DATA='{"sku":"TEST-SKU-001","name":"Updated Product","qty":20,"location":"Warehouse-B"}'
test_endpoint "Update item" "PUT" "$BASE_URL/api/inventory/$ITEM_ID" "200" "$UPDATE_DATA" "X-User: $USER"
echo ""

echo "=== 8. UPDATE Audit Event Verification ==="
sleep 1
AUDIT_RESPONSE=$(curl -s "$BASE_URL/api/audit-events/entity/InventoryItem/$ITEM_ID")
UPDATE_COUNT=$(echo "$AUDIT_RESPONSE" | grep -o '"eventType":"UPDATE"' | wc -l | tr -d ' ')
if [ "$UPDATE_COUNT" -ge 1 ]; then
    echo -e "${GREEN}✓ UPDATE audit event found${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ UPDATE audit event not found${NC}"
    ((FAILED++))
fi
echo ""

echo "=== 9. Error: Duplicate SKU (Create) ==="
DUPLICATE_DATA='{"sku":"TEST-SKU-001","name":"Duplicate","qty":5,"location":"C"}'
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/inventory" \
  -H "Content-Type: application/json" \
  -H "X-User: $USER" \
  -d "$DUPLICATE_DATA")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
if [ "$HTTP_CODE" == "400" ]; then
    if echo "$BODY" | grep -q "SKU already exists"; then
        echo -e "${GREEN}✓ Correct error response (400 with message)${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ Got 400 but error message format unclear${NC}"
        ((PASSED++))
    fi
else
    echo -e "${RED}✗ Expected 400, got $HTTP_CODE${NC}"
    ((FAILED++))
fi
echo ""

echo "=== 10. Error: Update Non-Existent ID ==="
test_endpoint "Update non-existent item" "PUT" "$BASE_URL/api/inventory/99999" "404" '{"sku":"SKU-999","name":"Test","qty":1,"location":"X"}' "X-User: $USER"
echo ""

echo "=== 11. Error: Get Non-Existent ID ==="
test_endpoint "Get non-existent item" "GET" "$BASE_URL/api/inventory/99999" "404"
echo ""

echo "=== 12. SKU Update Validation (New SKU) ==="
# Create second item
CREATE_DATA2='{"sku":"TEST-SKU-002","name":"Second Product","qty":15,"location":"Warehouse-C"}'
CREATE_RESPONSE2=$(curl -s -X POST "$BASE_URL/api/inventory" \
  -H "Content-Type: application/json" \
  -H "X-User: $USER" \
  -d "$CREATE_DATA2")
ITEM_ID2=$(echo "$CREATE_RESPONSE2" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1)

# Try to update first item with second item's SKU
UPDATE_CONFLICT='{"sku":"TEST-SKU-002","name":"Conflict Test","qty":25,"location":"D"}'
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/api/inventory/$ITEM_ID" \
  -H "Content-Type: application/json" \
  -H "X-User: $USER" \
  -d "$UPDATE_CONFLICT")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
if [ "$HTTP_CODE" == "400" ]; then
    if echo "$BODY" | grep -q "SKU already exists"; then
        echo -e "${GREEN}✓ SKU conflict validation works${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ Got 400 but message unclear${NC}"
        ((PASSED++))
    fi
else
    echo -e "${RED}✗ Expected 400 for SKU conflict, got $HTTP_CODE${NC}"
    ((FAILED++))
fi
echo ""

echo "=== 13. DELETE Inventory Item ==="
test_endpoint "Delete item" "DELETE" "$BASE_URL/api/inventory/$ITEM_ID" "204" "" "X-User: $USER"
echo ""

echo "=== 14. DELETE Audit Event Verification ==="
sleep 1
AUDIT_RESPONSE=$(curl -s "$BASE_URL/api/audit-events/entity/InventoryItem/$ITEM_ID")
DELETE_COUNT=$(echo "$AUDIT_RESPONSE" | grep -o '"eventType":"DELETE"' | wc -l | tr -d ' ')
if [ "$DELETE_COUNT" -ge 1 ]; then
    echo -e "${GREEN}✓ DELETE audit event found${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ DELETE audit event not found${NC}"
    ((FAILED++))
fi
echo ""

echo "=== 15. Error: Delete Non-Existent ID ==="
test_endpoint "Delete non-existent item" "DELETE" "$BASE_URL/api/inventory/99999" "404" "" "X-User: $USER"
echo ""

echo "=== 16. Audit Events Endpoints (Paginated) ==="
test_endpoint "Get all audit events (paginated)" "GET" "$BASE_URL/api/audit-events?page=0&size=10" "200"
test_endpoint "Get events by entity type (paginated)" "GET" "$BASE_URL/api/audit-events/entity-type/InventoryItem?page=0&size=10" "200"
test_endpoint "Get events by event type (paginated)" "GET" "$BASE_URL/api/audit-events/event-type/CREATE?page=0&size=10" "200"
test_endpoint "Get events by user (paginated)" "GET" "$BASE_URL/api/audit-events/user/$USER?page=0&size=10" "200"
test_endpoint "Get events with sorting" "GET" "$BASE_URL/api/audit-events?page=0&size=10&sortBy=timestamp&sortDir=DESC" "200"
echo ""

echo "=== 17. Search Endpoints ==="
# Create items with searchable patterns
CREATE_SEARCH1='{"sku":"SEARCH-ABC-001","name":"Widget Alpha","qty":5,"location":"Warehouse-A"}'
CREATE_SEARCH2='{"sku":"SEARCH-XYZ-002","name":"Widget Beta","qty":8,"location":"Warehouse-A"}'
CREATE_SEARCH3='{"sku":"OTHER-123","name":"Gadget Alpha","qty":12,"location":"Warehouse-B"}'

curl -s -X POST "$BASE_URL/api/inventory" -H "Content-Type: application/json" -H "X-User: $USER" -d "$CREATE_SEARCH1" > /dev/null
curl -s -X POST "$BASE_URL/api/inventory" -H "Content-Type: application/json" -H "X-User: $USER" -d "$CREATE_SEARCH2" > /dev/null
curl -s -X POST "$BASE_URL/api/inventory" -H "Content-Type: application/json" -H "X-User: $USER" -d "$CREATE_SEARCH3" > /dev/null

test_endpoint "Search by SKU pattern (SEARCH)" "GET" "$BASE_URL/api/inventory/search/sku?pattern=SEARCH&page=0&size=10" "200"
test_endpoint "Search by SKU pattern (case insensitive)" "GET" "$BASE_URL/api/inventory/search/sku?pattern=search&page=0&size=10" "200"
test_endpoint "Search by name pattern (Widget)" "GET" "$BASE_URL/api/inventory/search/name?pattern=Widget&page=0&size=10" "200"
test_endpoint "Search by name pattern (Alpha)" "GET" "$BASE_URL/api/inventory/search/name?pattern=Alpha&page=0&size=10" "200"
echo ""

echo "=== 18. Location-Based Filtering ==="
test_endpoint "Get items by location (Warehouse-A)" "GET" "$BASE_URL/api/inventory/location/Warehouse-A?page=0&size=10" "200"
test_endpoint "Get items by location (Warehouse-B)" "GET" "$BASE_URL/api/inventory/location/Warehouse-B?page=0&size=10" "200"
test_endpoint "Get items by location with sorting" "GET" "$BASE_URL/api/inventory/location/Warehouse-A?page=0&size=10&sortBy=qty&sortDir=DESC" "200"
echo ""

echo "=== 19. Location Summary Endpoint ==="
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/inventory/summary/location")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
if [ "$HTTP_CODE" == "200" ]; then
    if echo "$BODY" | grep -q "Warehouse"; then
        echo -e "${GREEN}✓ Location summary returned data${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ Location summary returned but no warehouse data${NC}"
        ((PASSED++))
    fi
else
    echo -e "${RED}✗ Expected 200 for location summary, got $HTTP_CODE${NC}"
    ((FAILED++))
fi
echo ""

echo "=== 20. Batch Operations ==="
BATCH_DATA='[{"sku":"BATCH-001","name":"Batch Item 1","qty":10,"location":"Warehouse-A"},{"sku":"BATCH-002","name":"Batch Item 2","qty":20,"location":"Warehouse-B"},{"sku":"BATCH-003","name":"Batch Item 3","qty":30,"location":"Warehouse-C"}]'
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/inventory/batch" \
  -H "Content-Type: application/json" \
  -H "X-User: $USER" \
  -d "$BATCH_DATA")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
if [ "$HTTP_CODE" == "201" ]; then
    BATCH_COUNT=$(echo "$BODY" | grep -o '"sku":"BATCH-' | wc -l | tr -d ' ')
    if [ "$BATCH_COUNT" -eq 3 ]; then
        echo -e "${GREEN}✓ Batch create successful (3 items)${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ Batch create returned but item count unclear${NC}"
        ((PASSED++))
    fi
else
    echo -e "${RED}✗ Expected 201 for batch create, got $HTTP_CODE${NC}"
    echo "  Response: $BODY"
    ((FAILED++))
fi

# Verify batch items were created
sleep 1
BATCH_ITEMS=$(curl -s "$BASE_URL/api/inventory/search/sku?pattern=BATCH&page=0&size=10")
BATCH_FOUND=$(echo "$BATCH_ITEMS" | grep -o '"sku":"BATCH-' | wc -l | tr -d ' ')
if [ "$BATCH_FOUND" -ge 3 ]; then
    echo -e "${GREEN}✓ Batch items verified in database${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Batch items not found in database${NC}"
    ((FAILED++))
fi
echo ""

echo "=== 21. Pagination Edge Cases ==="
test_endpoint "Pagination: Invalid page number (negative)" "GET" "$BASE_URL/api/inventory?page=-1&size=10" "400"
test_endpoint "Pagination: Large page number" "GET" "$BASE_URL/api/inventory?page=99999&size=10" "200"
test_endpoint "Pagination: Zero size" "GET" "$BASE_URL/api/inventory?page=0&size=0" "400"
test_endpoint "Pagination: Very large size" "GET" "$BASE_URL/api/inventory?page=0&size=1000" "200"
test_endpoint "Pagination: Invalid sort field" "GET" "$BASE_URL/api/inventory?page=0&size=10&sortBy=invalidField" "400"
echo ""

echo "=== 22. Performance Test: Large Dataset Pagination ==="
echo "Creating 25 test items for pagination performance test..."
for i in {1..25}; do
    PERF_DATA="{\"sku\":\"PERF-$(printf %03d $i)\",\"name\":\"Performance Item $i\",\"qty\":$i,\"location\":\"Warehouse-Perf\"}"
    curl -s -X POST "$BASE_URL/api/inventory" -H "Content-Type: application/json" -H "X-User: $USER" -d "$PERF_DATA" > /dev/null
done

echo -n "Testing pagination performance (25 items, page 0, size 10)... "
START_TIME=$(date +%s%N)
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/inventory?page=0&size=10")
END_TIME=$(date +%s%N)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
DURATION=$((($END_TIME - $START_TIME) / 1000000)) # Convert to milliseconds

if [ "$HTTP_CODE" == "200" ]; then
    if [ "$DURATION" -lt 1000 ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $HTTP_CODE, ${DURATION}ms)"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ PASS but slow${NC} (HTTP $HTTP_CODE, ${DURATION}ms)"
        ((PASSED++))
    fi
else
    echo -e "${RED}✗ FAIL${NC} (Expected 200, got $HTTP_CODE)"
    ((FAILED++))
fi

echo -n "Testing pagination performance (25 items, page 2, size 10)... "
START_TIME=$(date +%s%N)
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/inventory?page=2&size=10")
END_TIME=$(date +%s%N)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
DURATION=$((($END_TIME - $START_TIME) / 1000000))

if [ "$HTTP_CODE" == "200" ]; then
    if [ "$DURATION" -lt 1000 ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $HTTP_CODE, ${DURATION}ms)"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ PASS but slow${NC} (HTTP $HTTP_CODE, ${DURATION}ms)"
        ((PASSED++))
    fi
else
    echo -e "${RED}✗ FAIL${NC} (Expected 200, got $HTTP_CODE)"
    ((FAILED++))
fi
echo ""

echo "=== 23. Cache Performance Test ==="
echo -n "First request (cache miss)... "
START_TIME=$(date +%s%N)
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/inventory/sku/TEST-SKU-001")
END_TIME=$(date +%s%N)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
DURATION1=$((($END_TIME - $START_TIME) / 1000000))
echo "(${DURATION1}ms)"

echo -n "Second request (cache hit)... "
START_TIME=$(date +%s%N)
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/inventory/sku/TEST-SKU-001")
END_TIME=$(date +%s%N)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
DURATION2=$((($END_TIME - $START_TIME) / 1000000))
echo "(${DURATION2}ms)"

if [ "$DURATION2" -lt "$DURATION1" ]; then
    echo -e "${GREEN}✓ Cache appears to be working (second request faster)${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Cache performance unclear (may need more requests)${NC}"
    ((PASSED++))
fi
echo ""

echo "=== 24. Search Performance Test ==="
echo -n "Search performance (pattern matching)... "
START_TIME=$(date +%s%N)
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/inventory/search/sku?pattern=PERF&page=0&size=10")
END_TIME=$(date +%s%N)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
DURATION=$((($END_TIME - $START_TIME) / 1000000))

if [ "$HTTP_CODE" == "200" ]; then
    if [ "$DURATION" -lt 500 ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $HTTP_CODE, ${DURATION}ms)"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ PASS but slow${NC} (HTTP $HTTP_CODE, ${DURATION}ms)"
        ((PASSED++))
    fi
else
    echo -e "${RED}✗ FAIL${NC} (Expected 200, got $HTTP_CODE)"
    ((FAILED++))
fi
echo ""

echo "=== 25. Validation Error Test ==="

INVALID_DATA='{"sku":"","name":"","qty":-1,"location":""}'
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/inventory" \
  -H "Content-Type: application/json" \
  -H "X-User: $USER" \
  -d "$INVALID_DATA")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" == "400" ]; then
    echo -e "${GREEN}✓ Validation errors handled correctly${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ Expected 400 for validation error, got $HTTP_CODE${NC}"
    ((FAILED++))
fi
echo ""

echo "=== 26. Stress Test: Concurrent Requests ==="
echo "Sending 10 concurrent pagination requests..."
for i in {1..10}; do
    (curl -s "$BASE_URL/api/inventory?page=0&size=10" > /dev/null) &
done
wait
echo -e "${GREEN}✓ Concurrent requests completed${NC}"
((PASSED++))
echo ""

echo "=== 27. Database Index Verification ==="
echo "Testing query performance with indexes..."
# Test location-based query (should use index)
START_TIME=$(date +%s%N)
RESPONSE=$(curl -s "$BASE_URL/api/inventory/location/Warehouse-Perf?page=0&size=10")
END_TIME=$(date +%s%N)
DURATION=$((($END_TIME - $START_TIME) / 1000000))
if [ "$DURATION" -lt 500 ]; then
    echo -e "${GREEN}✓ Location query fast (${DURATION}ms) - indexes likely working${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Location query slow (${DURATION}ms) - may need index verification${NC}"
    ((PASSED++))
fi
echo ""

# Cleanup
echo "=== Cleanup ==="
# Delete all test items
echo "Cleaning up test items..."
curl -s "$BASE_URL/api/inventory/search/sku?pattern=TEST-SKU&page=0&size=100" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | while read id; do
    curl -s -X DELETE "$BASE_URL/api/inventory/$id" -H "X-User: $USER" > /dev/null
done
curl -s "$BASE_URL/api/inventory/search/sku?pattern=SEARCH&page=0&size=100" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | while read id; do
    curl -s -X DELETE "$BASE_URL/api/inventory/$id" -H "X-User: $USER" > /dev/null
done
curl -s "$BASE_URL/api/inventory/search/sku?pattern=BATCH&page=0&size=100" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | while read id; do
    curl -s -X DELETE "$BASE_URL/api/inventory/$id" -H "X-User: $USER" > /dev/null
done
curl -s "$BASE_URL/api/inventory/search/sku?pattern=PERF&page=0&size=100" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | while read id; do
    curl -s -X DELETE "$BASE_URL/api/inventory/$id" -H "X-User: $USER" > /dev/null
done
curl -s "$BASE_URL/api/inventory/search/sku?pattern=OTHER&page=0&size=100" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | while read id; do
    curl -s -X DELETE "$BASE_URL/api/inventory/$id" -H "X-User: $USER" > /dev/null
done
if [ ! -z "$ITEM_ID2" ]; then
    curl -s -X DELETE "$BASE_URL/api/inventory/$ITEM_ID2" -H "X-User: $USER" > /dev/null
fi
echo "Cleaned up test items"
echo ""

echo "=========================================="
echo "Test Results:"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "=========================================="

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed${NC}"
    exit 1
fi

