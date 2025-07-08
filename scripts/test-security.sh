#!/bin/bash
set -e

echo "🔒 Security Isolation Test Suite"
echo "================================"
echo ""
echo "This script tests the security isolation of the sandbox."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
PASSED=0
FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"  # "fail" or "pass"
    
    echo -n "Testing: $test_name... "
    
    if [ "$expected_result" = "fail" ]; then
        # We expect this command to fail
        if ! $test_command 2>/dev/null; then
            echo -e "${GREEN}PASS${NC} (correctly failed)"
            ((PASSED++))
        else
            echo -e "${RED}FAIL${NC} (should have failed)"
            ((FAILED++))
        fi
    else
        # We expect this command to succeed
        if $test_command 2>/dev/null; then
            echo -e "${GREEN}PASS${NC}"
            ((PASSED++))
        else
            echo -e "${RED}FAIL${NC}"
            ((FAILED++))
        fi
    fi
}

# Get container name or ID
if [ -z "$1" ]; then
    echo "Usage: $0 <container-name-or-id>"
    echo ""
    echo "For DevPod: Use the workspace name"
    echo "For Docker Compose: Use 'claude-agent-sandbox'"
    exit 1
fi

CONTAINER="$1"

echo "🔍 Testing container: $CONTAINER"
echo ""

# Test 1: Check if running as non-root
echo "📋 User Privilege Tests:"
run_test "Running as non-root user" \
    "docker exec $CONTAINER sh -c 'test \$(id -u) -ne 0'" \
    "pass"

run_test "Cannot gain root privileges" \
    "docker exec $CONTAINER sh -c 'sudo echo test'" \
    "fail"

echo ""

# Test 2: Filesystem access tests
echo "📋 Filesystem Isolation Tests:"
run_test "Cannot access host root" \
    "docker exec $CONTAINER sh -c 'ls /host_root'" \
    "fail"

run_test "Cannot write to root filesystem" \
    "docker exec $CONTAINER sh -c 'touch /test_file'" \
    "fail"

run_test "Can write to workspace" \
    "docker exec $CONTAINER sh -c 'touch /workspace/test_file && rm /workspace/test_file'" \
    "pass"

echo ""

# Test 3: Process and capability tests
echo "📋 Process Isolation Tests:"
run_test "Cannot see host processes" \
    "docker exec $CONTAINER sh -c 'ps aux | grep -v grep | grep dockerd'" \
    "fail"

run_test "No dangerous capabilities" \
    "docker exec $CONTAINER sh -c 'capsh --print | grep -E \"cap_sys_admin|cap_sys_ptrace\"'" \
    "fail"

echo ""

# Test 4: Network tests
echo "📋 Network Isolation Tests:"
run_test "Cannot access Docker socket" \
    "docker exec $CONTAINER sh -c 'docker ps'" \
    "fail"

run_test "Cannot bind privileged ports" \
    "docker exec $CONTAINER sh -c 'python3 -m http.server 80'" \
    "fail"

echo ""

# Test 5: Environment variable tests
echo "📋 Environment Security Tests:"
run_test "GITHUB_TOKEN is set" \
    "docker exec $CONTAINER sh -c 'test -n \"\$GITHUB_TOKEN\"'" \
    "pass"

run_test "No HOST environment leakage" \
    "docker exec $CONTAINER sh -c 'env | grep -E \"HOST_|DOCKER_HOST\"'" \
    "fail"

echo ""

# Test 6: Resource limit tests
echo "📋 Resource Limit Tests:"
echo -e "${YELLOW}Note: Resource limits are enforced by Docker/DevPod${NC}"

# Get container stats
echo "Current resource usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" $CONTAINER

echo ""

# Summary
echo "================================"
echo "🏁 Test Summary:"
echo -e "   Passed: ${GREEN}$PASSED${NC}"
echo -e "   Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All security tests passed!${NC}"
    echo "The sandbox is properly isolated."
else
    echo -e "${RED}❌ Some security tests failed!${NC}"
    echo "Please review the failed tests above."
fi

echo ""
echo "📚 For more details, see SECURITY.md"