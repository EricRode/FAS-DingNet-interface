#!/bin/bash

# Comprehensive Energy Depletion Validation Test
# This test thoroughly validates:
# 1. Energy consumption is happening correctly
# 2. Energy values are reported accurately in monitor
# 3. Transmission stops when energy is insufficient
# 4. Infinite energy mode works (energyLevel=0)

set -e

BASE_URL="${DINGNET_URL:-http://localhost:3000}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================================================"
echo "  THOROUGH ENERGY DEPLETION VALIDATION"
echo "========================================================================"
echo "Target: $BASE_URL"
echo

# Helper functions
log_test() {
    echo -e "\n${BLUE}[TEST]${NC} $*"
    echo "------------------------------------------------------------------------"
}

log_pass() {
    echo -e "${GREEN}  ✓ PASS:${NC} $*"
}

log_fail() {
    echo -e "${RED}  ✗ FAIL:${NC} $*"
    exit 1
}

log_info() {
    echo -e "  ${NC}→${NC} $*"
}

# Check server
log_info "Checking server availability..."
if ! curl -s -o /dev/null "$BASE_URL/" 2>/dev/null; then
    log_fail "Cannot reach DingNet server at $BASE_URL"
fi
log_pass "Server is reachable"

# ==============================================================================
# TEST 1: Energy Consumption with Detailed Monitoring
# ==============================================================================
log_test "Test 1: Energy Consumption - Detailed Monitoring"

curl -s -X POST "$BASE_URL/stop_run" > /dev/null 2>&1 || true
sleep 1

# Configure mote with limited energy, slow sampling rate to observe depletion
CONFIG='{
    "mode": "personalized",
    "areaWidthMeters": 500,
    "areaHeightMeters": 500,
    "motes": [{
        "eui": 10001,
        "xPos": 100,
        "yPos": 100,
        "transmissionPower": 14,
        "spreadingFactor": 12,
        "samplingRate": 150,
        "energyLevel": 600,
        "movementType": "static"
    }],
    "gateways": [{"eui": 7001, "xPos": 100, "yPos": 100}]
}'

log_info "Configuring: energyLevel=600, power=14dBm, SF=12, samplingRate=150"
log_info "Expected cost per packet: ~30 units (formula: 10 * ((14+3)/10) * (12/7))"
log_info "Expected capacity: ~20 packets before depletion"

curl -s -X POST -H "Content-Type: application/json" -d "$CONFIG" "$BASE_URL/configure_scenario" > /dev/null
curl -s -X POST "$BASE_URL/start_run" > /dev/null
sleep 2

# Sample energy levels over time
log_info "Monitoring energy over 20 seconds..."
echo
printf "  %5s | %8s | %8s | %10s\n" "Time" "Energy" "Packets" "Consumed"
printf "  %s\n" "------+----------+----------+------------"

energy_samples=()
packet_samples=()

for i in {1..10}; do
    sleep 2
    MONITOR=$(curl -s "$BASE_URL/monitor")
    energy=$(echo "$MONITOR" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['moteStates'][0]['energyLevel'])")
    packets=$(echo "$MONITOR" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['moteStates'][0]['packetsSent'])")
    
    consumed=$((600 - energy))
    printf "  %4ds | %8s | %8s | %10s\n" "$((i*2))" "$energy" "$packets" "$consumed"
    
    energy_samples+=($energy)
    packet_samples+=($packets)
done

echo
curl -s -X POST "$BASE_URL/stop_run" > /dev/null

# Analyze results
initial_energy=600
final_energy=${energy_samples[-1]}
final_packets=${packet_samples[-1]}
total_consumed=$((initial_energy - final_energy))

log_info "Analysis:"
log_info "  Initial energy: $initial_energy units"
log_info "  Final energy:   $final_energy units"
log_info "  Total consumed: $total_consumed units"
log_info "  Total packets:  $final_packets"

if [ "$final_packets" -gt 0 ]; then
    avg_cost=$(python3 -c "print(round($total_consumed / $final_packets, 1))")
    log_info "  Average cost:   $avg_cost units/packet"
    
    # Verify energy was depleted
    if [ "$final_energy" -lt "$initial_energy" ]; then
        log_pass "Energy depleted: $initial_energy → $final_energy units"
    else
        log_fail "Energy did NOT deplete (stayed at $final_energy)"
    fi
    
    # Verify cost is reasonable (should be ~30 for 14dBm SF12)
    if [ $(python3 -c "print(25 <= $avg_cost <= 35)") = "True" ]; then
        log_pass "Average cost $avg_cost units/packet is reasonable (expected ~30)"
    else
        log_fail "Average cost $avg_cost units/packet is outside expected range (25-35)"
    fi
    
    # Verify energy values are changing
    unique_energies=$(printf '%s\n' "${energy_samples[@]}" | sort -u | wc -l)
    if [ "$unique_energies" -gt 1 ]; then
        log_pass "Energy values changed over time ($unique_energies unique values observed)"
    else
        log_fail "Energy values did NOT change (all samples = ${energy_samples[0]})"
    fi
else
    log_fail "No packets transmitted"
fi

sleep 2

# ==============================================================================
# TEST 2: Transmission Stops When Energy Insufficient
# ==============================================================================
log_test "Test 2: Transmission Stops When Energy Insufficient"

curl -s -X POST "$BASE_URL/stop_run" > /dev/null 2>&1 || true
sleep 1

CONFIG='{
    "mode": "personalized",
    "areaWidthMeters": 500,
    "areaHeightMeters": 500,
    "motes": [{
        "eui": 10002,
        "xPos": 100,
        "yPos": 100,
        "transmissionPower": 14,
        "spreadingFactor": 12,
        "samplingRate": 80,
        "energyLevel": 250,
        "movementType": "static"
    }],
    "gateways": [{"eui": 7002, "xPos": 100, "yPos": 100}]
}'

log_info "Configuring: energyLevel=250, cost ~30/packet"
log_info "Expected: ~8 packets, then stop with ~10 units remaining"

curl -s -X POST -H "Content-Type: application/json" -d "$CONFIG" "$BASE_URL/configure_scenario" > /dev/null
curl -s -X POST "$BASE_URL/start_run" > /dev/null

log_info "Waiting for energy to get low..."
sleep 4

# Check energy is low
MONITOR=$(curl -s "$BASE_URL/monitor")
energy=$(echo "$MONITOR" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['moteStates'][0]['energyLevel'])")
packets_at_low=$(echo "$MONITOR" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['moteStates'][0]['packetsSent'])")

log_info "Current state: energy=$energy, packets=$packets_at_low"

if [ "$energy" -lt 30 ]; then
    log_pass "Energy is low ($energy units < 30 required for transmission)"
    
    # Wait and verify packets don't increase
    log_info "Waiting 5 seconds to verify transmission stopped..."
    sleep 5
    
    MONITOR=$(curl -s "$BASE_URL/monitor")
    packets_after=$(echo "$MONITOR" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['moteStates'][0]['packetsSent'])")
    
    log_info "After wait: packets=$packets_after"
    
    if [ "$packets_after" -eq "$packets_at_low" ]; then
        log_pass "Transmission STOPPED: packets remained at $packets_at_low (no new transmissions)"
    else
        log_fail "Transmission CONTINUED: $packets_at_low → $packets_after packets (should have stopped)"
    fi
else
    log_fail "Energy is still high ($energy units), expected < 30"
fi

curl -s -X POST "$BASE_URL/stop_run" > /dev/null
sleep 2

# ==============================================================================
# TEST 3: Infinite Energy Mode (energyLevel=0)
# ==============================================================================
log_test "Test 3: Infinite Energy Mode (energyLevel=0)"

curl -s -X POST "$BASE_URL/stop_run" > /dev/null 2>&1 || true
sleep 1

CONFIG='{
    "mode": "personalized",
    "areaWidthMeters": 500,
    "areaHeightMeters": 500,
    "motes": [{
        "eui": 10003,
        "xPos": 100,
        "yPos": 100,
        "transmissionPower": 14,
        "spreadingFactor": 12,
        "samplingRate": 10,
        "energyLevel": 0,
        "movementType": "static"
    }],
    "gateways": [{"eui": 7003, "xPos": 100, "yPos": 100}]
}'

log_info "Configuring: energyLevel=0 (infinite energy mode)"
log_info "Expected: energy stays at 0, unlimited transmissions"

curl -s -X POST -H "Content-Type: application/json" -d "$CONFIG" "$BASE_URL/configure_scenario" > /dev/null
curl -s -X POST "$BASE_URL/start_run" > /dev/null
sleep 3

MONITOR=$(curl -s "$BASE_URL/monitor")
energy=$(echo "$MONITOR" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['moteStates'][0]['energyLevel'])")
packets=$(echo "$MONITOR" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['moteStates'][0]['packetsSent'])")

log_info "State: energy=$energy, packets=$packets"

if [ "$energy" -eq 0 ]; then
    log_pass "Energy stayed at 0 (infinite mode active)"
else
    log_fail "Energy changed to $energy (should stay at 0)"
fi

if [ "$packets" -gt 0 ]; then
    log_pass "Packets transmitted successfully ($packets packets with infinite energy)"
else
    log_fail "No packets transmitted"
fi

curl -s -X POST "$BASE_URL/stop_run" > /dev/null

# ==============================================================================
# TEST 4: Energy Cost Formula Validation
# ==============================================================================
log_test "Test 4: Energy Cost Formula Validation (Different Power Levels)"

curl -s -X POST "$BASE_URL/stop_run" > /dev/null 2>&1 || true
sleep 1

log_info "Testing different power levels with same SF=12"
echo

powers=(0 7 14)
expected_costs=(5 12 30)  # Approximate expected costs

for idx in ${!powers[@]}; do
    power=${powers[$idx]}
    expected=${expected_costs[$idx]}
    eui=$((11000 + idx))
    
    CONFIG="{
        \"mode\": \"personalized\",
        \"areaWidthMeters\": 500,
        \"areaHeightMeters\": 500,
        \"motes\": [{
            \"eui\": $eui,
            \"xPos\": 100,
            \"yPos\": 100,
            \"transmissionPower\": $power,
            \"spreadingFactor\": 12,
            \"samplingRate\": 100,
            \"energyLevel\": 500,
            \"movementType\": \"static\"
        }],
        \"gateways\": [{\"eui\": 8000, \"xPos\": 100, \"yPos\": 100}]
    }"
    
    curl -s -X POST -H "Content-Type: application/json" -d "$CONFIG" "$BASE_URL/configure_scenario" > /dev/null
    curl -s -X POST "$BASE_URL/start_run" > /dev/null
    sleep 3
    
    MONITOR=$(curl -s "$BASE_URL/monitor")
    energy=$(echo "$MONITOR" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['moteStates'][0]['energyLevel'])")
    packets=$(echo "$MONITOR" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['moteStates'][0]['packetsSent'])")
    
    if [ "$packets" -gt 0 ]; then
        consumed=$((500 - energy))
        actual_cost=$(python3 -c "print(round($consumed / $packets, 1))")
        log_info "Power ${power}dBm: consumed $consumed units over $packets packets = $actual_cost units/packet (expected ~${expected})"
        
        # Verify within 20% of expected
        if [ $(python3 -c "print($expected * 0.8 <= $actual_cost <= $expected * 1.2)") = "True" ]; then
            log_pass "Cost $actual_cost is within expected range (${expected} ± 20%)"
        else
            log_fail "Cost $actual_cost is outside expected range (${expected} ± 20%)"
        fi
    else
        log_fail "No packets for power ${power}dBm"
    fi
    
    curl -s -X POST "$BASE_URL/stop_run" > /dev/null
    sleep 1
done

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================
echo
echo "========================================================================"
echo "  VALIDATION SUMMARY"
echo "========================================================================"
log_pass "All energy depletion tests passed!"
log_pass "Energy consumption is working correctly"
log_pass "Transmission stops when energy insufficient"
log_pass "Infinite energy mode works as expected"
log_pass "Energy costs match formula expectations"
echo "========================================================================"
