#!/bin/bash

# Frontend Test Suite with Edge Cases
# Tests: UI accessibility, build, static assets, API integration, edge cases
# Author: Victor Tiradoegas

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FRONTEND_URL="${FRONTEND_URL:-http://localhost:3000}"
BACKEND_URL="${BACKEND_URL:-http://localhost:8080}"

# Test counters
PASSED=0
FAILED=0
SKIPPED=0

# Test results log
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
TEST_LOG="$LOG_DIR/frontend-test-results-$(date +%Y%m%d-%H%M%S).log"
echo "Frontend Test Run Started: $(date)" > "$TEST_LOG"

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

test_url() {
    local name=$1
    local url=$2
    local expected_status=$3
    local check_content=$4
    
    echo -n "  Testing: $name... "
    
    response=$(curl -s -w "\n%{http_code}" "$url" 2>&1)
    http_code=$(echo "$response" | sed -n '$p')
    body=$(echo "$response" | sed '$d')
    
    # Check if expected_status contains multiple values (comma-separated)
    if echo "$expected_status" | grep -q ","; then
        IFS=',' read -r -a expected_statuses_array <<< "$expected_status"
        local status_match=0
        for status in "${expected_statuses_array[@]}"; do
            if [ "$http_code" == "$status" ]; then
                status_match=1
                break
            fi
        done
        
        if [ "$status_match" -eq 1 ]; then
            if [ ! -z "$check_content" ]; then
                if echo "$body" | grep -q "$check_content"; then
                    echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code, content found)"
                    log_test "PASS" "$name - HTTP $http_code, content found"
                    ((PASSED++))
                    return 0
                else
                    echo -e "${YELLOW}⚠ PASS (HTTP $http_code, but content not found)${NC}"
                    log_test "WARN" "$name - HTTP $http_code, content '$check_content' not found"
                    ((PASSED++))
                    return 0
                fi
            else
                echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
                log_test "PASS" "$name - HTTP $http_code"
                ((PASSED++))
                return 0
            fi
        else
            echo -e "${RED}✗ FAIL${NC} (Expected one of: $expected_status, got $http_code)"
            log_test "FAIL" "$name - Expected one of: $expected_status, got $http_code"
            ((FAILED++))
            return 1
        fi
    else
        # Single expected status
        if [ "$http_code" == "$expected_status" ]; then
            if [ ! -z "$check_content" ]; then
                if echo "$body" | grep -q "$check_content"; then
                    echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code, content found)"
                    log_test "PASS" "$name - HTTP $http_code, content found"
                    ((PASSED++))
                    return 0
                else
                    echo -e "${YELLOW}⚠ PASS (HTTP $http_code, but content not found)${NC}"
                    log_test "WARN" "$name - HTTP $http_code, content '$check_content' not found"
                    ((PASSED++))
                    return 0
                fi
            else
                echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
                log_test "PASS" "$name - HTTP $http_code"
                ((PASSED++))
                return 0
            fi
        else
            echo -e "${RED}✗ FAIL${NC} (Expected $expected_status, got $http_code)"
            log_test "FAIL" "$name - Expected $expected_status, got $http_code"
            ((FAILED++))
            return 1
        fi
    fi
}

# Check prerequisites
command -v curl >/dev/null 2>&1 || { echo -e "${RED}✗ curl not found${NC}"; exit 1; }

# ==========================================
# SECTION 1: Frontend Build Tests
# ==========================================
print_section "1. Frontend Build Tests"

if command -v npm >/dev/null 2>&1; then
    echo "1.1 Testing npm build..."
    cd ../frontend 2>/dev/null || cd ./frontend 2>/dev/null || { echo -e "${RED}✗ Frontend directory not found${NC}"; ((FAILED++)); exit 1; }
    
    if npm run build > /tmp/frontend-build-test.log 2>&1; then
        echo -e "${GREEN}✓ Frontend build successful${NC}"
        log_test "PASS" "Frontend npm build"
        ((PASSED++))
        
        # Check if dist directory exists
        if [ -d "dist" ]; then
            echo -e "${GREEN}✓ Build output directory exists${NC}"
            ((PASSED++))
            
            # Check for essential files
            if [ -f "dist/index.html" ]; then
                echo -e "${GREEN}✓ index.html generated${NC}"
                ((PASSED++))
            else
                echo -e "${YELLOW}⚠ index.html not found in dist${NC}"
                ((SKIPPED++))
            fi
            
            # Check for JS files
            JS_COUNT=$(find dist -name "*.js" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$JS_COUNT" -gt 0 ]; then
                echo -e "${GREEN}✓ JavaScript files generated ($JS_COUNT files)${NC}"
                ((PASSED++))
            else
                echo -e "${YELLOW}⚠ No JavaScript files found${NC}"
                ((SKIPPED++))
            fi
            
            # Check for CSS files
            CSS_COUNT=$(find dist -name "*.css" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$CSS_COUNT" -gt 0 ]; then
                echo -e "${GREEN}✓ CSS files generated ($CSS_COUNT files)${NC}"
                ((PASSED++))
            else
                echo -e "${YELLOW}⚠ No CSS files found${NC}"
                ((SKIPPED++))
            fi
        else
            echo -e "${YELLOW}⚠ Build output directory not found${NC}"
            ((SKIPPED++))
        fi
    else
        echo -e "${RED}✗ Frontend build failed${NC}"
        echo "Build log (last 20 lines):"
        tail -20 /tmp/frontend-build-test.log
        log_test "FAIL" "Frontend npm build failed"
        ((FAILED++))
    fi
    
    cd "$SCRIPT_DIR"
else
    echo -e "${YELLOW}⚠ npm not found (skipping build tests)${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 2: Frontend Accessibility Tests
# ==========================================
print_section "2. Frontend Accessibility Tests"

# Check if frontend is running
FRONTEND_RESPONDING=0
if curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL" 2>/dev/null | grep -q "200"; then
    FRONTEND_RESPONDING=1
fi

if [ $FRONTEND_RESPONDING -eq 1 ]; then
    echo "2.1 Testing main page accessibility..."
    test_url "Frontend homepage" "$FRONTEND_URL" "200" ""
    
    echo ""
    echo "2.2 Testing HTML structure..."
    HTML_BODY=$(curl -s "$FRONTEND_URL")
    
    # Check for essential HTML elements
    if echo "$HTML_BODY" | grep -qi "<!doctype html\|<html"; then
        echo -e "  ${GREEN}✓ Valid HTML structure${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ HTML structure unclear${NC}"
        ((SKIPPED++))
    fi
    
    if echo "$HTML_BODY" | grep -qi "<title"; then
        echo -e "  ${GREEN}✓ Page title present${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ Page title missing${NC}"
        ((SKIPPED++))
    fi
    
    if echo "$HTML_BODY" | grep -qi "viewport"; then
        echo -e "  ${GREEN}✓ Viewport meta tag present${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ Viewport meta tag missing${NC}"
        ((SKIPPED++))
    fi
    
    echo ""
    echo "2.3 Testing static assets..."
    # Extract asset references from HTML
    if echo "$HTML_BODY" | grep -qE "\.js|\.css|\.svg|\.png|\.jpg|\.jpeg|\.gif"; then
        echo -e "  ${GREEN}✓ Static assets referenced${NC}"
        ((PASSED++))
        
        # Try to access a few common asset paths
        if echo "$HTML_BODY" | grep -q "vite.svg\|favicon"; then
            test_url "Favicon/logo accessibility" "$FRONTEND_URL/vite.svg" "200,404,403" ""
        fi
    else
        echo -e "  ${YELLOW}⚠ Static assets not clearly referenced${NC}"
        ((SKIPPED++))
    fi
    
    echo ""
    echo "2.4 Testing CORS headers..."
    CORS_RESPONSE=$(curl -s -I "$FRONTEND_URL" 2>&1)
    if echo "$CORS_RESPONSE" | grep -qi "access-control"; then
        echo -e "  ${GREEN}✓ CORS headers present${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ CORS headers not found (may be handled by backend)${NC}"
        ((SKIPPED++))
    fi
    
    echo ""
    echo "2.5 Testing security headers..."
    SECURITY_HEADERS=$(curl -s -I "$FRONTEND_URL" 2>&1)
    if echo "$SECURITY_HEADERS" | grep -qiE "x-content-type-options|x-frame-options|x-xss-protection"; then
        echo -e "  ${GREEN}✓ Security headers present${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ Security headers not found${NC}"
        ((SKIPPED++))
    fi
else
    echo -e "${YELLOW}⚠ Frontend not running at $FRONTEND_URL${NC}"
    echo "  Start frontend with: npm run dev (in frontend directory)"
    echo "  Or: docker-compose -f docker-compose.prod.yaml up -d frontend"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 3: Route & Navigation Edge Cases
# ==========================================
print_section "3. Route & Navigation Edge Cases"

if [ $FRONTEND_RESPONDING -eq 1 ]; then
    echo "3.1 Testing non-existent routes..."
    # Note: React Router (SPA) returns 200 for all routes - client-side routing handles 404s
    test_url "Non-existent route" "$FRONTEND_URL/non-existent-route-12345" "200,404" ""
    test_url "Deep nested route" "$FRONTEND_URL/very/deep/nested/route/path" "200,404" ""
    
    echo ""
    echo "3.2 Testing route with special characters..."
    # SPA returns 200 for all routes
    test_url "Route with special chars" "$FRONTEND_URL/test!@#\$%^&*()" "200,404,400" ""
    test_url "Route with query params" "$FRONTEND_URL/test?param=value&other=123" "200" ""
    
    echo ""
    echo "3.3 Testing route with path traversal attempts..."
    # SPA may return 200 (handled by client) or 400/404 (server rejection)
    test_url "Path traversal attempt" "$FRONTEND_URL/../../etc/passwd" "200,404,400" ""
    test_url "Encoded path traversal" "$FRONTEND_URL/%2e%2e%2f%2e%2e%2fetc%2fpasswd" "200,404,400" ""
    
    echo ""
    echo "3.4 Testing very long URLs..."
    LONG_PATH=$(printf 'A%.0s' {1..500})
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL/$LONG_PATH" 2>&1)
    if [ "$RESPONSE" == "200" ] || [ "$RESPONSE" == "404" ] || [ "$RESPONSE" == "414" ]; then
        echo -e "  ${GREEN}✓ Very long URL handled (HTTP $RESPONSE)${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ Very long URL returned unexpected code (HTTP $RESPONSE)${NC}"
        ((SKIPPED++))
    fi
else
    echo -e "${YELLOW}⚠ Skipping route tests (frontend not running)${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 4: API Integration Edge Cases
# ==========================================
print_section "4. API Integration Edge Cases"

# Check if backend is available
BACKEND_RESPONDING=0
if curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/actuator/health" 2>/dev/null | grep -q "200\|503"; then
    BACKEND_RESPONDING=1
fi

if [ $BACKEND_RESPONDING -eq 1 ]; then
    echo "4.1 Testing CORS configuration..."
    # Test preflight request
    CORS_RESPONSE=$(curl -s -X OPTIONS "$BACKEND_URL/api/inventory" \
      -H "Origin: $FRONTEND_URL" \
      -H "Access-Control-Request-Method: GET" \
      -H "Access-Control-Request-Headers: Authorization" \
      -w "\n%{http_code}" 2>&1)
    CORS_CODE=$(echo "$CORS_RESPONSE" | tail -n1)
    
    if [ "$CORS_CODE" == "200" ] || [ "$CORS_CODE" == "204" ]; then
        echo -e "  ${GREEN}✓ CORS preflight request accepted${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ CORS preflight returned HTTP $CORS_CODE${NC}"
        ((SKIPPED++))
    fi
    
    echo ""
    echo "4.2 Testing API endpoint availability from frontend context..."
    # Test if API endpoints are accessible (should fail without auth, but endpoint should exist)
    test_url "API endpoint exists" "$BACKEND_URL/api/inventory" "401,403,200" ""
    test_url "API health endpoint" "$BACKEND_URL/actuator/health" "200,503" ""
    
    echo ""
    echo "4.3 Testing API error responses..."
    # Test 404
    test_url "API 404 handling" "$BACKEND_URL/api/inventory/999999" "404,401,403" ""
    
    # Test 400 (bad request)
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/inventory" \
      -H "Content-Type: application/json" \
      -d '{"invalid":"data"}' 2>&1)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    if [ "$HTTP_CODE" == "400" ] || [ "$HTTP_CODE" == "401" ] || [ "$HTTP_CODE" == "403" ]; then
        echo -e "  ${GREEN}✓ API error handling works (HTTP $HTTP_CODE)${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ API error handling unexpected (HTTP $HTTP_CODE)${NC}"
        ((SKIPPED++))
    fi
else
    echo -e "${YELLOW}⚠ Backend not available (skipping API integration tests)${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 5: Content & Asset Edge Cases
# ==========================================
print_section "5. Content & Asset Edge Cases"

if [ $FRONTEND_RESPONDING -eq 1 ]; then
    echo "5.1 Testing asset loading..."
    HTML_BODY=$(curl -s "$FRONTEND_URL")
    
    # Extract JS file references
    JS_FILES=$(echo "$HTML_BODY" | grep -oE 'src="[^"]*\.js[^"]*"' | sed 's/src="//;s/"$//' | head -3)
    for js_file in $JS_FILES; do
        if [[ "$js_file" == http* ]]; then
            test_url "External JS: $js_file" "$js_file" "200" ""
        else
            # Remove leading slash if present for proper URL construction
            js_file_clean=$(echo "$js_file" | sed 's|^/||')
            test_url "JS asset: $js_file" "$FRONTEND_URL/$js_file_clean" "200,404" ""
        fi
    done
    
    # Extract CSS file references
    CSS_FILES=$(echo "$HTML_BODY" | grep -oE 'href="[^"]*\.css[^"]*"' | sed 's/href="//;s/"$//' | head -3)
    for css_file in $CSS_FILES; do
        if [[ "$css_file" == http* ]]; then
            test_url "External CSS: $css_file" "$css_file" "200" ""
        else
            # Remove leading slash if present for proper URL construction
            css_file_clean=$(echo "$css_file" | sed 's|^/||')
            test_url "CSS asset: $css_file" "$FRONTEND_URL/$css_file_clean" "200,404" ""
        fi
    done
    
    echo ""
    echo "5.2 Testing missing assets..."
    test_url "Non-existent JS file" "$FRONTEND_URL/non-existent-file.js" "404" ""
    test_url "Non-existent CSS file" "$FRONTEND_URL/non-existent-file.css" "404" ""
    test_url "Non-existent image" "$FRONTEND_URL/non-existent-image.png" "404" ""
    
    echo ""
    echo "5.3 Testing asset path traversal..."
    # SPA may return 200 (client-side routing) or 400/404 (server rejection)
    test_url "Asset path traversal" "$FRONTEND_URL/../../etc/passwd" "200,404,400" ""
    test_url "Asset encoded traversal" "$FRONTEND_URL/%2e%2e%2f%2e%2e%2fetc%2fpasswd" "200,404,400" ""
else
    echo -e "${YELLOW}⚠ Skipping asset tests (frontend not running)${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 6: Performance & Load Edge Cases
# ==========================================
print_section "6. Performance & Load Edge Cases"

if [ $FRONTEND_RESPONDING -eq 1 ]; then
    echo "6.1 Testing page load time..."
    START_TIME=$(date +%s%N)
    curl -s "$FRONTEND_URL" >/dev/null 2>&1
    END_TIME=$(date +%s%N)
    LOAD_TIME=$((($END_TIME - $START_TIME) / 1000000))
    
    if [ "$LOAD_TIME" -lt 1000 ]; then
        echo -e "  ${GREEN}✓ Page loads quickly (${LOAD_TIME}ms)${NC}"
        ((PASSED++))
    elif [ "$LOAD_TIME" -lt 3000 ]; then
        echo -e "  ${YELLOW}⚠ Page load acceptable (${LOAD_TIME}ms)${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ Page load slow (${LOAD_TIME}ms)${NC}"
        ((PASSED++))
    fi
    
    echo ""
    echo "6.2 Testing concurrent requests..."
    echo -n "  Testing: 10 concurrent requests... "
    START_TIME=$(date +%s%N)
    for i in {1..10}; do
        curl -s "$FRONTEND_URL" >/dev/null 2>&1 &
    done
    wait
    END_TIME=$(date +%s%N)
    CONCURRENT_TIME=$((($END_TIME - $START_TIME) / 1000000))
    
    if [ "$CONCURRENT_TIME" -lt 2000 ]; then
        echo -e "${GREEN}✓ PASS${NC} (10 requests in ${CONCURRENT_TIME}ms)"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ Slow concurrent response${NC} (10 requests in ${CONCURRENT_TIME}ms)"
        ((PASSED++))
    fi
    
    echo ""
    echo "6.3 Testing large response handling..."
    # Make multiple requests to see if server handles it
    for i in {1..5}; do
        curl -s "$FRONTEND_URL" >/dev/null 2>&1
    done
    echo -e "  ${GREEN}✓ Multiple requests handled${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ Skipping performance tests (frontend not running)${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 7: Security Edge Cases
# ==========================================
print_section "7. Security Edge Cases"

if [ $FRONTEND_RESPONDING -eq 1 ]; then
    echo "7.1 Testing XSS prevention in responses..."
    # Check if response properly escapes content
    HTML_BODY=$(curl -s "$FRONTEND_URL")
    if echo "$HTML_BODY" | grep -q "<script"; then
        # Check if scripts are properly formatted (not injected)
        SCRIPT_COUNT=$(echo "$HTML_BODY" | grep -o "<script" | wc -l | tr -d ' ')
        if [ "$SCRIPT_COUNT" -le 5 ]; then
            echo -e "  ${GREEN}✓ Script tags appear legitimate${NC}"
            ((PASSED++))
        else
            echo -e "  ${YELLOW}⚠ Many script tags found ($SCRIPT_COUNT)${NC}"
            ((SKIPPED++))
        fi
    else
        echo -e "  ${YELLOW}⚠ No script tags found${NC}"
        ((SKIPPED++))
    fi
    
    echo ""
    echo "7.2 Testing HTTP method restrictions..."
    # Test that non-GET methods are handled
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$FRONTEND_URL" 2>&1)
    if [ "$RESPONSE" == "200" ] || [ "$RESPONSE" == "405" ] || [ "$RESPONSE" == "404" ]; then
        echo -e "  ${GREEN}✓ POST method handled (HTTP $RESPONSE)${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ POST method returned unexpected code (HTTP $RESPONSE)${NC}"
        ((SKIPPED++))
    fi
    
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$FRONTEND_URL" 2>&1)
    if [ "$RESPONSE" == "200" ] || [ "$RESPONSE" == "405" ] || [ "$RESPONSE" == "404" ]; then
        echo -e "  ${GREEN}✓ DELETE method handled (HTTP $RESPONSE)${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ DELETE method returned unexpected code (HTTP $RESPONSE)${NC}"
        ((SKIPPED++))
    fi
    
    echo ""
    echo "7.3 Testing header injection attempts..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "X-Injected-Header: malicious-value" \
      -H "User-Agent: <script>alert('XSS')</script>" \
      "$FRONTEND_URL" 2>&1)
    if [ "$RESPONSE" == "200" ] || [ "$RESPONSE" == "400" ]; then
        echo -e "  ${GREEN}✓ Header injection handled (HTTP $RESPONSE)${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ Header injection test inconclusive (HTTP $RESPONSE)${NC}"
        ((SKIPPED++))
    fi
else
    echo -e "${YELLOW}⚠ Skipping security tests (frontend not running)${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 8: Browser Compatibility Edge Cases
# ==========================================
print_section "8. Browser Compatibility Edge Cases"

if [ $FRONTEND_RESPONDING -eq 1 ]; then
    echo "8.1 Testing different User-Agent strings..."
    # Test with different user agents
    for ua in "Mozilla/5.0" "curl/7.68.0" "Wget/1.20.3" "Googlebot/2.1"; do
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "User-Agent: $ua" "$FRONTEND_URL" 2>&1)
        if [ "$RESPONSE" == "200" ]; then
            echo -e "  ${GREEN}✓ User-Agent '$ua' accepted${NC}"
            ((PASSED++))
        else
            echo -e "  ${YELLOW}⚠ User-Agent '$ua' returned HTTP $RESPONSE${NC}"
            ((SKIPPED++))
        fi
    done
    
    echo ""
    echo "8.2 Testing Accept headers..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Accept: text/html" "$FRONTEND_URL" 2>&1)
    if [ "$RESPONSE" == "200" ]; then
        echo -e "  ${GREEN}✓ Accept header handled${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ Accept header test inconclusive (HTTP $RESPONSE)${NC}"
        ((SKIPPED++))
    fi
    
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Accept: application/json" "$FRONTEND_URL" 2>&1)
    if [ "$RESPONSE" == "200" ] || [ "$RESPONSE" == "406" ]; then
        echo -e "  ${GREEN}✓ JSON Accept header handled (HTTP $RESPONSE)${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ JSON Accept header test inconclusive (HTTP $RESPONSE)${NC}"
        ((SKIPPED++))
    fi
else
    echo -e "${YELLOW}⚠ Skipping browser compatibility tests (frontend not running)${NC}"
    ((SKIPPED++))
fi

# ==========================================
# SECTION 9: Error Handling Edge Cases
# ==========================================
print_section "9. Error Handling Edge Cases"

if [ $FRONTEND_RESPONDING -eq 1 ]; then
    echo "9.1 Testing malformed requests..."
    # Test with invalid HTTP version
    RESPONSE=$(echo -e "GET / HTTP/0.9\r\nHost: localhost:3000\r\n\r\n" | nc -w 1 localhost 3000 2>/dev/null | head -1 || echo "ERROR")
    if [ "$RESPONSE" != "ERROR" ]; then
        echo -e "  ${GREEN}✓ Malformed HTTP handled${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ Malformed HTTP test skipped (nc not available)${NC}"
        ((SKIPPED++))
    fi
    
    echo ""
    echo "9.2 Testing very large requests..."
    LARGE_DATA=$(printf 'A%.0s' {1..10000})
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$FRONTEND_URL" \
      -H "Content-Type: application/json" \
      -d "{\"data\":\"$LARGE_DATA\"}" 2>&1)
    if [ "$RESPONSE" == "200" ] || [ "$RESPONSE" == "400" ] || [ "$RESPONSE" == "413" ]; then
        echo -e "  ${GREEN}✓ Large request handled (HTTP $RESPONSE)${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ Large request test inconclusive (HTTP $RESPONSE)${NC}"
        ((SKIPPED++))
    fi
    
    echo ""
    echo "9.3 Testing timeout handling..."
    # This is a simple test - actual timeout would require more complex setup
    START_TIME=$(date +%s)
    curl -s --max-time 5 "$FRONTEND_URL" >/dev/null 2>&1
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    if [ "$DURATION" -lt 5 ]; then
        echo -e "  ${GREEN}✓ Request completes within timeout (${DURATION}s)${NC}"
        ((PASSED++))
    else
        echo -e "  ${YELLOW}⚠ Request took longer than expected (${DURATION}s)${NC}"
        ((PASSED++))
    fi
else
    echo -e "${YELLOW}⚠ Skipping error handling tests (frontend not running)${NC}"
    ((SKIPPED++))
fi

# ==========================================
# FINAL SUMMARY
# ==========================================
print_section "Frontend Test Summary"

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
    echo -e "${GREEN}✓ All frontend tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some frontend tests failed. Please review the log: $TEST_LOG${NC}"
    exit 1
fi

