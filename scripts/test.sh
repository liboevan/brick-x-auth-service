#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test configuration
SERVICE_URL="http://localhost:17101"
TIMEOUT=30
WAIT_INTERVAL=2

# Function to wait for service to be ready
wait_for_service() {
    print_status "Waiting for auth service to be ready..."
    local counter=0
    
    while [ $counter -lt $TIMEOUT ]; do
        if curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL/health" | grep -q "200"; then
            print_status "Service is ready!"
            return 0
        fi
        
        counter=$((counter + $WAIT_INTERVAL))
        sleep $WAIT_INTERVAL
        print_status "Waiting... ($counter/$TIMEOUT seconds)"
    done
    
    print_error "Service failed to start within timeout"
    return 1
}

# Function to test health endpoint
test_health() {
    print_status "Testing health endpoint..."
    
    local response=$(curl -s -w "%{http_code}" "$SERVICE_URL/health")
    local status_code="${response: -3}"
    local body="${response%???}"
    
    if [ "$status_code" = "200" ]; then
        echo -e "${GREEN}✓ Health check passed${NC}"
        echo "Response: $body"
    else
        echo -e "${RED}✗ Health check failed (HTTP $status_code)${NC}"
        return 1
    fi
    
    echo ""
}

# Function to test build info endpoint
test_build_info() {
    print_status "Testing build info endpoint..."
    
    local response=$(curl -s -w "%{http_code}" "$SERVICE_URL/build-info.json")
    local status_code="${response: -3}"
    local body="${response%???}"
    
    if [ "$status_code" = "200" ]; then
        echo -e "${GREEN}✓ Build info check passed${NC}"
        echo "Response: $body"
    else
        echo -e "${RED}✗ Build info check failed (HTTP $status_code)${NC}"
        return 1
    fi
    
    echo ""
}

# Function to test version endpoint
test_version() {
    print_status "Testing version endpoint..."
    
    local response=$(curl -s -w "%{http_code}" "$SERVICE_URL/VERSION")
    local status_code="${response: -3}"
    local body="${response%???}"
    
    if [ "$status_code" = "200" ]; then
        echo -e "${GREEN}✓ Version check passed${NC}"
        echo "Version: $body"
    else
        echo -e "${RED}✗ Version check failed (HTTP $status_code)${NC}"
        return 1
    fi
    
    echo ""
}

# Function to test login for x-superadmin
test_login_x_superadmin() {
    print_status "Testing login endpoint for user: x-superadmin"
    local user="x-superadmin"
    local pass="x-superadmin"
    # Test successful login
    print_status "Testing successful login..."
    local login_response=$(curl -s -w "%{http_code}" \
        -X POST "$SERVICE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"username":"'$user'","password":"'$pass'"}')
    local login_status="${login_response: -3}"
    local login_body="${login_response%???}"
    if [ "$login_status" = "200" ]; then
        echo -e "${GREEN}✓ x-superadmin login successful${NC}"
        echo "Response: $login_body"
    else
        echo -e "${RED}✗ x-superadmin login failed (HTTP $login_status)${NC}"
        echo "Response: $login_body"
        return 1
    fi
    # Test failed login
    print_status "Testing failed login..."
    local failed_response=$(curl -s -w "%{http_code}" \
        -X POST "$SERVICE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"username":"'$user'","password":"wrongpassword"}')
    local failed_status="${failed_response: -3}"
    if [ "$failed_status" = "401" ] || [ "$failed_status" = "400" ]; then
        echo -e "${GREEN}✓ x-superadmin failed login handled correctly (HTTP $failed_status)${NC}"
    else
        echo -e "${YELLOW}⚠ x-superadmin failed login returned unexpected status (HTTP $failed_status)${NC}"
    fi
    echo ""
}
# Function to test login for x-operator
test_login_x_operator() {
    print_status "Testing login endpoint for user: x-operator"
    local user="x-operator"
    local pass="x-operator"
    # Test successful login
    print_status "Testing successful login..."
    local login_response=$(curl -s -w "%{http_code}" \
        -X POST "$SERVICE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"username":"'$user'","password":"'$pass'"}')
    local login_status="${login_response: -3}"
    local login_body="${login_response%???}"
    if [ "$login_status" = "200" ]; then
        echo -e "${GREEN}✓ x-operator login successful${NC}"
        echo "Response: $login_body"
    else
        echo -e "${RED}✗ x-operator login failed (HTTP $login_status)${NC}"
        echo "Response: $login_body"
        return 1
    fi
    # Test failed login
    print_status "Testing failed login..."
    local failed_response=$(curl -s -w "%{http_code}" \
        -X POST "$SERVICE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"username":"'$user'","password":"wrongpassword"}')
    local failed_status="${failed_response: -3}"
    if [ "$failed_status" = "401" ] || [ "$failed_status" = "400" ]; then
        echo -e "${GREEN}✓ x-operator failed login handled correctly (HTTP $failed_status)${NC}"
    else
        echo -e "${YELLOW}⚠ x-operator failed login returned unexpected status (HTTP $failed_status)${NC}"
    fi
    echo ""
}

# Function to test invalid endpoints
test_invalid_endpoints() {
    print_status "Testing invalid endpoints..."
    
    local test_failed=false
    
    # Test non-existent endpoint
    local not_found_response=$(curl -s -w "%{http_code}" "$SERVICE_URL/nonexistent")
    local not_found_status="${not_found_response: -3}"
    
    if [ "$not_found_status" = "404" ]; then
        echo -e "${GREEN}✓ 404 handling correct${NC}"
    else
        echo -e "${YELLOW}⚠ 404 returned unexpected status (HTTP $not_found_status)${NC}"
        test_failed=true
    fi
    
    # Test wrong method
    local method_response=$(curl -s -w "%{http_code}" -X PUT "$SERVICE_URL/health")
    local method_status="${method_response: -3}"
    
    if [ "$method_status" = "405" ] || [ "$method_status" = "404" ]; then
        echo -e "${GREEN}✓ Wrong method handled correctly (HTTP $method_status)${NC}"
    else
        echo -e "${YELLOW}⚠ Wrong method returned unexpected status (HTTP $method_status)${NC}"
        test_failed=true
    fi
    
    echo ""
    
    if [ "$test_failed" = true ]; then
        return 1
    else
        return 0
    fi
}

# Function to run all tests
run_all_tests() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}Brick X Auth Service - API Tests${NC}"
    echo -e "${BLUE}======================================${NC}"
    if ! wait_for_service; then
        print_error "Service is not ready. Please ensure the service is running."
        exit 1
    fi
    local failed_tests=0
    echo ""
    if test_health; then
        echo -e "${GREEN}✓ Health test passed${NC}"
    else
        echo -e "${RED}✗ Health test failed${NC}"
        failed_tests=$((failed_tests + 1))
    fi
    echo ""
    if test_build_info; then
        echo -e "${GREEN}✓ Build info test passed${NC}"
    else
        echo -e "${RED}✗ Build info test failed${NC}"
        failed_tests=$((failed_tests + 1))
    fi
    echo ""
    if test_version; then
        echo -e "${GREEN}✓ Version test passed${NC}"
    else
        echo -e "${RED}✗ Version test failed${NC}"
        failed_tests=$((failed_tests + 1))
    fi
    echo ""
    if test_login_x_superadmin; then
        echo -e "${GREEN}✓ x-superadmin login test passed${NC}"
    else
        echo -e "${RED}✗ x-superadmin login test failed${NC}"
        failed_tests=$((failed_tests + 1))
    fi
    if test_login_x_operator; then
        echo -e "${GREEN}✓ x-operator login test passed${NC}"
    else
        echo -e "${RED}✗ x-operator login test failed${NC}"
        failed_tests=$((failed_tests + 1))
    fi
    echo ""
    if test_invalid_endpoints; then
        echo -e "${GREEN}✓ Invalid endpoints test passed${NC}"
    else
        echo -e "${RED}✗ Invalid endpoints test failed${NC}"
        failed_tests=$((failed_tests + 1))
    fi
    echo -e "${BLUE}======================================${NC}"
    if [ $failed_tests -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}$failed_tests test(s) failed${NC}"
        exit 1
    fi
}

# Function to show help
show_help() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}Brick X Auth Service - Test Script${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo -e ""
    echo -e "${GREEN}Usage:${NC}"
    echo -e "  $0 [command]"
    echo -e ""
    echo -e "${GREEN}Commands:${NC}"
    echo -e "  ${YELLOW}all${NC}      - Run all tests (default)"
    echo -e "  ${YELLOW}health${NC}   - Test health endpoint"
    echo -e "  ${YELLOW}build${NC}    - Test build info endpoint"
    echo -e "  ${YELLOW}version${NC}  - Test version endpoint"
    echo -e "  ${YELLOW}login${NC}    - Test login endpoint"
    echo -e "  ${YELLOW}invalid${NC}  - Test invalid endpoints"
    echo -e "  ${YELLOW}help${NC}     - Show this help"
    echo -e ""
    echo -e "${BLUE}Configuration:${NC}"
    echo -e "  Service URL: $SERVICE_URL"
    echo -e "  Timeout: ${TIMEOUT}s"
    echo -e ""
    echo -e "${BLUE}======================================${NC}"
}

# Main command handler
case "${1:-all}" in
    "all")
        run_all_tests
        ;;
    "health")
        wait_for_service && test_health
        ;;
    "build")
        wait_for_service && test_build_info
        ;;
    "version")
        wait_for_service && test_version
        ;;
    "login")
        wait_for_service && test_login_x_superadmin && test_login_x_operator
        ;;
    "invalid")
        wait_for_service && test_invalid_endpoints
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac 