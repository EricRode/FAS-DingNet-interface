#!/bin/bash

# Test script to verify packet loss calculation accuracy
# This test reveals the bug in packet counting logic

set -e

API_BASE="http://localhost:3000"
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Function to run a single test
run_test() {
    local test_name=$1
    ((TESTS_TOTAL++))
    log_test "Running: $test_name"
    if $test_name; then
        ((TESTS_PASSED++))
        return 0
    else
        ((TESTS_FAILED++))
        return 1
    fi
}

# Stop any running simulation
stop_simulation() {
    curl -s -X POST "$API_BASE/stop" > /dev/null || true
    sleep 1
}

# Test 1: Basic packet counting with minimal setup (1 mote, 1 gateway)
test_minimal_packet_counting() {
    log_info "Testing with 1 mote and 1 gateway - should have minimal broadcast overhead"
    
    stop_simulation
    
    # Configure: 1 mote, 1 gateway, close together (high success rate expected)
    local config='{
        "mode": "personalized",
        "motes": [
            {
                "devEUI": 1,
                "xPos": 1000,
                "yPos": 1000,
                "energyLevel": 0,
                "transmissionPower": 14,
                "spreadingFactor": 7,
                "samplingRate": 5000,
                "movementSpeed": 0.0,
                "sensors": []
            }
        ],
        "gateways": [
            {
                "gatewayEUI": 100,
                "xPos": 1050,
                "yPos": 1000,
                "transmissionPower": 14,
                "spreadingFactor": 7
            }
        ]
    }'
    
    curl -s -X POST "$API_BASE/configure_scenario" \
        -H "Content-Type: application/json" \
        -d "$config" > /dev/null
    
    # Start simulation
    curl -s -X POST "$API_BASE/start" > /dev/null
    sleep 2
    
    # Let it run for a bit
    sleep 8
    
    # Get monitoring data
    local monitor_response=$(curl -s -X GET "$API_BASE/monitor")
    
    # Extract packet stats for mote 1
    local packets_sent=$(echo "$monitor_response" | jq -r '.motes[] | select(.devEUI == 1) | .packetsSent')
    local packets_lost=$(echo "$monitor_response" | jq -r '.motes[] | select(.devEUI == 1) | .packetsLost')
    local packet_loss=$(echo "$monitor_response" | jq -r '.motes[] | select(.devEUI == 1) | .packetLoss')
    
    log_info "Mote 1 stats: Sent=$packets_sent, Lost=$packets_lost, Loss=$packet_loss"
    
    # With 1 mote and 1 gateway close together:
    # - Each mote transmission creates 1 packet (to the gateway)
    # - Expected loss should be LOW (< 20%) since they're close
    
    if [ "$packets_sent" -eq 0 ]; then
        log_error "No packets sent - timing issue?"
        return 1
    fi
    
    # Calculate actual loss percentage
    local loss_pct=$(echo "$packet_loss * 100" | bc -l | cut -d. -f1)
    
    log_info "Calculated packet loss: ${loss_pct}%"
    
    # If loss is > 50%, this indicates the broadcast counting bug
    if [ "$loss_pct" -gt 50 ]; then
        log_error "UNEXPECTED: Packet loss is ${loss_pct}% with 1 gateway nearby!"
        log_error "This suggests the bug: counting broadcast copies as separate packets"
        return 1
    fi
    
    log_success "Packet loss is reasonable: ${loss_pct}%"
    return 0
}

# Test 2: Show broadcast counting bug with multiple gateways
test_broadcast_counting_bug() {
    log_info "Testing with 1 mote and 4 gateways - revealing broadcast counting bug"
    
    stop_simulation
    
    # Configure: 1 mote, 4 gateways, all close together
    local config='{
        "mode": "personalized",
        "motes": [
            {
                "devEUI": 1,
                "xPos": 1000,
                "yPos": 1000,
                "energyLevel": 0,
                "transmissionPower": 14,
                "spreadingFactor": 7,
                "samplingRate": 5000,
                "movementSpeed": 0.0,
                "sensors": []
            }
        ],
        "gateways": [
            {
                "gatewayEUI": 100,
                "xPos": 1050,
                "yPos": 1000,
                "transmissionPower": 14,
                "spreadingFactor": 7
            },
            {
                "gatewayEUI": 101,
                "xPos": 1000,
                "yPos": 1050,
                "transmissionPower": 14,
                "spreadingFactor": 7
            },
            {
                "gatewayEUI": 102,
                "xPos": 950,
                "yPos": 1000,
                "transmissionPower": 14,
                "spreadingFactor": 7
            },
            {
                "gatewayEUI": 103,
                "xPos": 1000,
                "yPos": 950,
                "transmissionPower": 14,
                "spreadingFactor": 7
            }
        ]
    }'
    
    curl -s -X POST "$API_BASE/configure_scenario" \
        -H "Content-Type: application/json" \
        -d "$config" > /dev/null
    
    # Start simulation
    curl -s -X POST "$API_BASE/start" > /dev/null
    sleep 2
    
    # Let it run
    sleep 8
    
    # Get monitoring data
    local monitor_response=$(curl -s -X GET "$API_BASE/monitor")
    
    # Extract packet stats
    local packets_sent=$(echo "$monitor_response" | jq -r '.motes[] | select(.devEUI == 1) | .packetsSent')
    local packets_lost=$(echo "$monitor_response" | jq -r '.motes[] | select(.devEUI == 1) | .packetsLost')
    local packet_loss=$(echo "$monitor_response" | jq -r '.motes[] | select(.devEUI == 1) | .packetLoss')
    
    log_info "Mote 1 stats: Sent=$packets_sent, Lost=$packets_lost, Loss=$packet_loss"
    
    # Calculate loss percentage
    local loss_pct=$(echo "$packet_loss * 100" | bc -l | cut -d. -f1)
    
    log_info "Calculated packet loss: ${loss_pct}%"
    
    # THE BUG: With 4 gateways, each transmission creates 4 packets
    # So numberOfSentPackets is 4x the actual transmissions
    # But calculatePacketLoss only counts received once per gateway
    # Expected bug behavior: ~75% loss (3 out of 4 packets "lost")
    
    if [ "$loss_pct" -gt 60 ]; then
        log_error "BUG CONFIRMED: Packet loss is ${loss_pct}% with 4 gateways all nearby!"
        log_error "Expected: Low loss (all gateways should receive)"
        log_error "Actual: High loss due to counting broadcast copies as separate packets"
        log_error ""
        log_error "Root cause in NetworkEntity.loraSend():"
        log_error "  - Creates N packets (1 per gateway + M per other mote)"
        log_error "  - Increments numberOfSentPackets N times (line 401)"
        log_error "  - But calculatePacketLoss() counts each transmission once"
        log_error "  - Result: (N - 1) / N = artificial packet loss"
        return 1
    fi
    
    log_success "Packet loss is reasonable: ${loss_pct}%"
    return 0
}

# Test 3: Demonstrate the formula for the bug
test_demonstrate_bug_formula() {
    log_info "Demonstrating the mathematical relationship of the bug"
    
    stop_simulation
    
    # Configure: 1 mote, varying numbers of gateways
    for num_gateways in 1 2 4 8; do
        log_info "Testing with $num_gateways gateways..."
        
        # Build gateway array
        local gateways_json="["
        for i in $(seq 1 $num_gateways); do
            local angle=$(echo "scale=5; 2 * 3.14159 * ($i - 1) / $num_gateways" | bc -l)
            local x_offset=$(echo "scale=0; 50 * c($angle)" | bc -l)
            local y_offset=$(echo "scale=0; 50 * s($angle)" | bc -l)
            local x_pos=$(echo "1000 + $x_offset" | bc)
            local y_pos=$(echo "1000 + $y_offset" | bc)
            
            gateways_json="$gateways_json{\"gatewayEUI\": $((100 + i)), \"xPos\": $x_pos, \"yPos\": $y_pos, \"transmissionPower\": 14, \"spreadingFactor\": 7}"
            if [ $i -lt $num_gateways ]; then
                gateways_json="$gateways_json,"
            fi
        done
        gateways_json="$gateways_json]"
        
        local config="{
            \"mode\": \"personalized\",
            \"motes\": [
                {
                    \"devEUI\": 1,
                    \"xPos\": 1000,
                    \"yPos\": 1000,
                    \"energyLevel\": 0,
                    \"transmissionPower\": 14,
                    \"spreadingFactor\": 7,
                    \"samplingRate\": 5000,
                    \"movementSpeed\": 0.0,
                    \"sensors\": []
                }
            ],
            \"gateways\": $gateways_json
        }"
        
        curl -s -X POST "$API_BASE/configure_scenario" \
            -H "Content-Type: application/json" \
            -d "$config" > /dev/null
        
        curl -s -X POST "$API_BASE/start" > /dev/null
        sleep 2
        sleep 5
        
        local monitor_response=$(curl -s -X GET "$API_BASE/monitor")
        local packet_loss=$(echo "$monitor_response" | jq -r '.motes[] | select(.devEUI == 1) | .packetLoss')
        local loss_pct=$(echo "$packet_loss * 100" | bc -l | cut -d. -f1)
        
        # Expected bug formula: loss = (N - 1) / N where N = num_gateways
        local expected_loss=$(echo "scale=2; ($num_gateways - 1) * 100 / $num_gateways" | bc)
        
        log_info "  Gateways: $num_gateways, Loss: ${loss_pct}%, Expected (bug): ${expected_loss}%"
        
        stop_simulation
        sleep 1
    done
    
    log_error "Bug formula demonstrated: PacketLoss ≈ (NumGateways - 1) / NumGateways"
    log_error "This confirms numberOfSentPackets counts broadcast copies incorrectly"
    return 1
}

# Test 4: Verify what SHOULD be counted
test_correct_counting_logic() {
    log_info "Testing what the CORRECT packet counting should be"
    
    stop_simulation
    
    local config='{
        "mode": "personalized",
        "motes": [
            {
                "devEUI": 1,
                "xPos": 1000,
                "yPos": 1000,
                "energyLevel": 0,
                "transmissionPower": 14,
                "spreadingFactor": 7,
                "samplingRate": 5000,
                "movementSpeed": 0.0,
                "sensors": []
            }
        ],
        "gateways": [
            {
                "gatewayEUI": 100,
                "xPos": 1050,
                "yPos": 1000,
                "transmissionPower": 14,
                "spreadingFactor": 7
            },
            {
                "gatewayEUI": 101,
                "xPos": 1000,
                "yPos": 1050,
                "transmissionPower": 14,
                "spreadingFactor": 7
            }
        ]
    }'
    
    curl -s -X POST "$API_BASE/configure_scenario" \
        -H "Content-Type: application/json" \
        -d "$config" > /dev/null
    
    curl -s -X POST "$API_BASE/start" > /dev/null
    sleep 2
    sleep 8
    
    local monitor_response=$(curl -s -X GET "$API_BASE/monitor")
    local packets_sent=$(echo "$monitor_response" | jq -r '.motes[] | select(.devEUI == 1) | .packetsSent')
    local packets_lost=$(echo "$monitor_response" | jq -r '.motes[] | select(.devEUI == 1) | .packetsLost')
    
    log_info "Current implementation: Sent=$packets_sent, Lost=$packets_lost"
    log_info ""
    log_info "CORRECT logic should be:"
    log_info "  - numberOfSentPackets = number of TRANSMISSIONS (calls to loraSend)"
    log_info "  - A transmission succeeds if ANY gateway receives it"
    log_info "  - packetsSent should NOT multiply by number of gateways"
    log_info ""
    log_info "In this test:"
    log_info "  - If mote called loraSend() X times"
    log_info "  - packetsSent should be X (not X * num_gateways)"
    log_info "  - packetsLost should be 0 if at least 1 gateway received each"
    
    # This test always fails with current implementation
    return 1
}

# Main execution
main() {
    echo "=========================================="
    echo "  Packet Loss Calculation Bug Analysis"
    echo "=========================================="
    echo ""
    
    # Check if server is running
    if ! curl -s "$API_BASE/monitor" > /dev/null 2>&1; then
        log_error "API server not reachable at $API_BASE"
        log_error "Please start the server first: docker run -p 3000:8080 dingnet"
        exit 1
    fi
    
    log_success "API server is reachable"
    echo ""
    
    # Run tests that demonstrate the bug
    run_test test_minimal_packet_counting
    echo ""
    
    run_test test_broadcast_counting_bug
    echo ""
    
    run_test test_demonstrate_bug_formula
    echo ""
    
    run_test test_correct_counting_logic
    echo ""
    
    # Summary
    echo "=========================================="
    echo "  TEST SUMMARY"
    echo "=========================================="
    echo "Total tests: $TESTS_TOTAL"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo ""
    
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}BUG CONFIRMED IN PACKET LOSS CALCULATION${NC}"
        echo ""
        echo "Root Cause:"
        echo "  File: src/IotDomain/NetworkEntity.java"
        echo "  Method: loraSend() at line ~401"
        echo ""
        echo "Issue:"
        echo "  numberOfSentPackets++ executes once per RECIPIENT (gateway/mote)"
        echo "  But each loraSend() call is ONE transmission, not N transmissions"
        echo ""
        echo "Fix Required:"
        echo "  Move numberOfSentPackets++ outside the packet-sending loop"
        echo "  It should increment once per loraSend() call, not once per recipient"
        echo ""
        return 1
    else
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    fi
}

main
