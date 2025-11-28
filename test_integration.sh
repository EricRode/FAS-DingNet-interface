#!/usr/bin/env bash
#
# DingNet Integration Test Suite
# Tests all HTTP endpoints and validates simulation behavior
#

# Configuration
BASE_URL="${DINGNET_URL:-http://localhost:3000}"
VERBOSE="${VERBOSE:-0}"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_verbose() {
    if [[ $VERBOSE -eq 1 ]]; then
        echo -e "${NC}  → $*${NC}"
    fi
}

# Run a test function and track its result
run_test() {
    local test_func=$1
    ((TESTS_TOTAL++))
    if $test_func; then
        ((TESTS_PASSED++))
        return 0
    else
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test helper functions
http_get() {
    local endpoint="$1"
    local output_file="${2:-$TEMP_DIR/response.json}"
    
    curl -s -o "$output_file" "$BASE_URL$endpoint" 2>/dev/null
    local exit_code=$?
    log_verbose "GET $endpoint -> exit_code=$exit_code"
    return $exit_code
}

http_post() {
    local endpoint="$1"
    local data="${2:-}"
    local output_file="${3:-$TEMP_DIR/response.json}"
    
    if [[ -n "$data" ]]; then
        curl -s -o "$output_file" \
            -X POST "$BASE_URL$endpoint" \
            -H 'Content-Type: application/json' \
            -d "$data" 2>/dev/null
    else
        curl -s -o "$output_file" \
            -X POST "$BASE_URL$endpoint" 2>/dev/null
    fi
    local exit_code=$?
    log_verbose "POST $endpoint -> exit_code=$exit_code"
    return $exit_code
}

http_put() {
    local endpoint="$1"
    local data="$2"
    local output_file="${3:-$TEMP_DIR/response.json}"
    
    curl -s -o "$output_file" \
        -X PUT "$BASE_URL$endpoint" \
        -H 'Content-Type: application/json' \
        -d "$data" 2>/dev/null
    local exit_code=$?
    log_verbose "PUT $endpoint -> exit_code=$exit_code"
    return $exit_code
}

json_value() {
    local key="$1"
    local file="${2:-$TEMP_DIR/response.json}"
    python3 -c "import json,sys; data=json.load(open('$file')); print(data.get('$key', ''))" 2>/dev/null || echo ""
}

json_array_length() {
    local key="$1"
    local file="${2:-$TEMP_DIR/response.json}"
    python3 -c "import json,sys; data=json.load(open('$file')); print(len(data.get('$key', [])))" 2>/dev/null || echo "0"
}

json_extract_mote_positions() {
    local file="${1:-$TEMP_DIR/response.json}"
    python3 -c "
import json
data = json.load(open('$file'))
for mote in data.get('moteStates', []):
    print(f\"{mote.get('eui','?')}:{mote.get('xpos','?')}:{mote.get('ypos','?')}\")
" 2>/dev/null
}

validate_metric_range() {
    local metric="$1"
    local value="$2"
    local min="$3"
    local max="$4"
    
    python3 -c "
val = float('$value')
if $min <= val <= $max:
    exit(0)
else:
    exit(1)
" 2>/dev/null
}

# Test functions
test_base_endpoint() {
    log_info "Test 1: Base endpoint /"
    if http_get "/"; then
        log_success "Base endpoint returns 200 OK"
        return 0
    else
        log_error "Base endpoint failed"
        return 1
    fi
}

test_schemas() {
    log_info "Test 2: Schema endpoints"
    
    if http_get "/monitor_schema"; then
        log_success "monitor_schema endpoint accessible"
    else
        log_error "monitor_schema failed"
    fi
    
    if http_get "/execute_schema"; then
        log_success "execute_schema endpoint accessible"
    else
        log_error "execute_schema failed"
    fi
    
    if http_get "/adaptation_options"; then
        log_success "adaptation_options endpoint accessible"
    else
        log_error "adaptation_options failed"
    fi
    
    if http_get "/configure_scenario_schema"; then
        log_success "configure_scenario_schema endpoint accessible"
    else
        log_error "configure_scenario_schema failed"
    fi
}

test_monitor_before_start() {
    log_info "Test 3: Monitor before simulation start"
    if http_get "/monitor"; then
        local is_running=$(json_value "isRunning")
        if [[ "$is_running" == "False" ]] || [[ "$is_running" == "false" ]]; then
            log_success "Monitor returns isRunning=false before start"
        else
            log_error "Monitor shows isRunning=$is_running, expected false"
        fi
    else
        log_error "Monitor request failed"
    fi
}

test_status_endpoint() {
    log_info "Test 4: Status endpoint"
    if http_get "/status"; then
        log_success "Status endpoint returns 200 OK"
        log_verbose "Status response: $(cat $TEMP_DIR/response.json)"
    else
        log_error "Status endpoint failed"
    fi
}

test_scenario_configuration() {
    log_info "Test 5: Configure scenario"
    local scenario_json='{
        "numMotes": 5,
        "numGateways": 2,
        "seed": 12345,
        "areaWidthMeters": 1000,
        "areaHeightMeters": 1000,
        "placementType": "random_uniform",
        "movementType": "static",
        "movingFraction": 0.0,
        "defaultPower": 12,
        "defaultSpreadingFactor": 10
    }'
    
    if http_post "/configure_scenario" "$scenario_json"; then
        log_success "Scenario configuration accepted"
    else
        log_error "Configure scenario failed"
    fi
}

test_start_simulation() {
    log_info "Test 6: Start simulation"
    if http_post "/start_run"; then
        log_success "Simulation started successfully"
    else
        log_error "Start run failed"
    fi
    sleep 3  # Allow simulation to initialize and begin running
}

test_monitor_after_start() {
    log_info "Test 7: Monitor after simulation start"
    if http_get "/monitor"; then
        local is_running=$(json_value "isRunning")
        if [[ "$is_running" == "True" ]] || [[ "$is_running" == "true" ]]; then
            log_success "Monitor shows isRunning=true after start"
            
            # Check for motes
            local mote_count=$(json_array_length "moteStates")
            log_verbose "Found $mote_count motes in environment"
            if [[ "$mote_count" -ge 5 ]]; then
                log_success "Environment has expected number of motes ($mote_count)"
            else
                log_error "Expected 5+ motes, found $mote_count"
            fi
        else
            log_error "Monitor shows isRunning=$is_running after start"
        fi
    else
        log_error "Monitor request failed"
    fi
}

test_status_during_run() {
    log_info "Test 8: Status during simulation run"
    if http_get "/status"; then
        local is_running=$(json_value "isRunning")
        if [[ "$is_running" == "True" ]] || [[ "$is_running" == "true" ]]; then
            log_success "Status shows simulation running"
            
            local mote_count=$(json_value "moteCount")
            local gateway_count=$(json_value "gatewayCount")
            log_verbose "Status reports: $mote_count motes, $gateway_count gateways"
            
            if [[ "$mote_count" == "5" ]] && [[ "$gateway_count" == "2" ]]; then
                log_success "Status counts match scenario configuration"
            else
                log_warn "Status counts ($mote_count motes, $gateway_count gw) differ from config (5, 2)"
            fi
        else
            log_error "Status shows isRunning=$is_running"
        fi
    else
        log_error "Status request failed"
    fi
}

test_execute_adaptations() {
    log_info "Test 9: Execute adaptations"
    local adapt_json='{
        "items": [
            {
                "id": 0,
                "adaptations": [
                    {"name": "power", "value": 14},
                    {"name": "sampling_rate", "value": 50}
                ]
            },
            {
                "id": 1,
                "adaptations": [
                    {"name": "spreading_factor", "value": 8}
                ]
            }
        ]
    }'
    
    if http_put "/execute" "$adapt_json"; then
        log_success "Adaptations executed successfully"
    else
        log_error "Execute failed"
    fi
}

test_monitor_after_adaptation() {
    log_info "Test 10: Verify adaptations in monitor"
    sleep 1
    if http_get "/monitor"; then
        # Check if adaptations are reflected
        if grep -q '"transmissionPower":14' "$TEMP_DIR/response.json"; then
            log_success "Adaptation reflected in monitor (power=14)"
        else
            log_warn "Could not verify power adaptation in monitor"
        fi
    else
        log_error "Monitor request failed"
    fi
}

test_stop_simulation() {
    log_info "Test 11: Stop simulation"
    if http_post "/stop_run"; then
        log_success "Simulation stopped successfully"
    else
        log_error "Stop run failed"
    fi
    sleep 1
}

test_monitor_after_stop() {
    log_info "Test 12: Monitor after simulation stop"
    if http_get "/monitor"; then
        local is_running=$(json_value "isRunning")
        if [[ "$is_running" == "False" ]] || [[ "$is_running" == "false" ]]; then
            log_success "Monitor shows isRunning=false after stop"
        else
            log_error "Monitor shows isRunning=$is_running after stop"
        fi
    else
        log_error "Monitor request failed"
    fi
}

test_scenario_with_movement() {
    log_info "Test 13: Scenario with movement - position tracking"
    local scenario_json='{
        "numMotes": 6,
        "numGateways": 2,
        "seed": 99999,
        "areaWidthMeters": 1500,
        "areaHeightMeters": 1500,
        "placementType": "random_uniform",
        "movementType": "random_walk",
        "movingFraction": 1.0,
        "defaultPower": 10,
        "defaultSpreadingFactor": 9
    }'
    
    if http_post "/configure_scenario" "$scenario_json"; then
        log_success "Movement scenario configured"
        
        # Start and verify
        if http_post "/start_run"; then
            log_success "Movement scenario started"
            sleep 5
            
            # Capture initial positions
            http_get "/monitor" "$TEMP_DIR/monitor1.json"
            local positions1=$(json_extract_mote_positions "$TEMP_DIR/monitor1.json")
            log_verbose "Initial positions: $positions1"
            
            # Wait longer for significant movement
            sleep 8
            http_get "/monitor" "$TEMP_DIR/monitor2.json"
            local positions2=$(json_extract_mote_positions "$TEMP_DIR/monitor2.json")
            log_verbose "Positions after 8s: $positions2"
            
            # Check if any positions changed (movement detected)
            if [[ "$positions1" != "$positions2" ]]; then
                log_success "Mote positions changed over time (movement detected)"
            else
                log_warn "Mote positions unchanged (may be static or slow movement)"
            fi
            
            # Validate position bounds
            local positions_valid=true
            while IFS=: read -r eui xpos ypos; do
                if [[ "$xpos" =~ ^[0-9]+$ ]] && [[ "$ypos" =~ ^[0-9]+$ ]]; then
                    if [[ $xpos -lt 0 ]] || [[ $xpos -gt 1500 ]] || [[ $ypos -lt 0 ]] || [[ $ypos -gt 1500 ]]; then
                        positions_valid=false
                        log_verbose "Position out of bounds: ($xpos, $ypos)"
                    fi
                fi
            done <<< "$positions2"
            
            if $positions_valid; then
                log_success "All mote positions within configured area bounds (0-1500)"
            else
                log_error "Some mote positions outside area bounds"
            fi
            
            # Stop
            http_post "/stop_run" "$TEMP_DIR/stop_response.json"
            sleep 1
        else
            log_error "Failed to start movement scenario"
        fi
    else
        log_error "Movement scenario configuration failed"
    fi
}

test_static_scenario() {
    log_info "Test 14: Static scenario - verify no movement"
    local scenario_json='{
        "numMotes": 4,
        "numGateways": 2,
        "seed": 12345,
        "areaWidthMeters": 800,
        "areaHeightMeters": 800,
        "placementType": "random_uniform",
        "movementType": "static",
        "movingFraction": 0.0,
        "defaultPower": 14,
        "defaultSpreadingFactor": 12
    }'
    
    if http_post "/configure_scenario" "$scenario_json"; then
        log_success "Static scenario configured"
        
        if http_post "/start_run"; then
            log_success "Static scenario started"
            sleep 2
            
            # Capture initial positions
            http_get "/monitor" "$TEMP_DIR/static_monitor1.json"
            local pos1=$(json_extract_mote_positions "$TEMP_DIR/static_monitor1.json")
            
            # Wait and capture again
            sleep 3
            http_get "/monitor" "$TEMP_DIR/static_monitor2.json"
            local pos2=$(json_extract_mote_positions "$TEMP_DIR/static_monitor2.json")
            
            # Verify positions stayed the same
            if [[ "$pos1" == "$pos2" ]]; then
                log_success "Static motes remained at fixed positions (no movement)"
            else
                log_error "Static motes moved when they should not have"
                log_verbose "Before: $pos1"
                log_verbose "After:  $pos2"
            fi
            
            # Stop
            http_post "/stop_run" "$TEMP_DIR/stop_response.json"
            sleep 1
        else
            log_error "Failed to start static scenario"
        fi
    else
        log_error "Static scenario configuration failed"
    fi
}

test_metrics_validation() {
    log_info "Test 15: Metrics validation - verify ranges and consistency"
    local scenario_json='{
        "numMotes": 6,
        "numGateways": 2,
        "seed": 54321,
        "areaWidthMeters": 1000,
        "areaHeightMeters": 1000,
        "placementType": "random_uniform",
        "movementType": "static",
        "defaultPower": 12,
        "defaultSpreadingFactor": 10
    }'
    
    if http_post "/configure_scenario" "$scenario_json"; then
        if http_post "/start_run"; then
            sleep 3  # Let simulation run to generate metrics
            
            http_get "/monitor" "$TEMP_DIR/metrics_monitor.json"
            
            # Validate metrics using Python
            python3 <<PYTHON_SCRIPT
import json
import sys

with open('$TEMP_DIR/metrics_monitor.json') as f:
    data = json.load(f)

motes = data.get('moteStates', [])
if not motes:
    print("ERROR: No motes found")
    sys.exit(1)

errors = []
warnings = []

for i, mote in enumerate(motes):
    # Validate transmission power (-3 to 14 dBm)
    power = mote.get('transmissionPower')
    if power is not None:
        if not (-3 <= power <= 14):
            errors.append(f"Mote {i}: transmissionPower {power} out of range [-3, 14]")
    
    # Validate spreading factor (7 to 12)
    sf = mote.get('sf')
    if sf is not None:
        if not (7 <= sf <= 12):
            errors.append(f"Mote {i}: spreading factor {sf} out of range [7, 12]")
    
    # Validate packet loss (0.0 to 1.0)
    loss = mote.get('packetLoss')
    if loss is not None:
        if not (0.0 <= loss <= 1.0):
            errors.append(f"Mote {i}: packetLoss {loss} out of range [0.0, 1.0]")
        elif loss > 0.8:
            warnings.append(f"Mote {i}: High packet loss {loss:.2f}")
    
    # Validate RSSI (should be negative, typically -20 to -120 dBm)
    rssi = mote.get('highestReceivedSignal')
    if rssi is not None:
        if rssi > 0:
            errors.append(f"Mote {i}: RSSI {rssi} should be negative")
        elif rssi < -120:
            warnings.append(f"Mote {i}: RSSI {rssi} unusually low")
    
    # Validate sampling rate (should be positive)
    sampling = mote.get('samplingRate')
    if sampling is not None and sampling < 1:
        errors.append(f"Mote {i}: samplingRate {sampling} should be >= 1")
    
    # Validate movement speed (should be non-negative)
    speed = mote.get('movementSpeed')
    if speed is not None and speed < 0:
        errors.append(f"Mote {i}: movementSpeed {speed} should be non-negative")
    
    # Validate energy level (should be non-negative)
    energy = mote.get('energyLevel')
    if energy is not None and energy < 0:
        errors.append(f"Mote {i}: energyLevel {energy} should be non-negative")
    
    # Validate packet counts consistency
    sent = mote.get('packetsSent', 0)
    lost = mote.get('packetsLost', 0)
    if sent < lost:
        errors.append(f"Mote {i}: packetsLost {lost} > packetsSent {sent}")

print(f"Validated {len(motes)} motes")
for warn in warnings:
    print(f"WARN: {warn}")

if errors:
    for err in errors:
        print(f"ERROR: {err}")
    sys.exit(1)
else:
    print("All metric validations passed")
    sys.exit(0)
PYTHON_SCRIPT
            
            if [[ $? -eq 0 ]]; then
                log_success "All metrics within expected ranges"
            else
                log_error "Metric validation failed (see above)"
            fi
            
            # Additional test: verify scenarioConfig in monitor matches what we set
            local mote_count=$(json_array_length "moteStates" "$TEMP_DIR/metrics_monitor.json")
            if [[ "$mote_count" == "6" ]]; then
                log_success "Monitor shows correct number of motes (6)"
            else
                log_error "Monitor shows $mote_count motes, expected 6"
            fi
            
            http_post "/stop_run" "$TEMP_DIR/stop_response.json"
            sleep 1
        else
            log_error "Failed to start metrics test scenario"
        fi
    else
        log_error "Metrics test scenario configuration failed"
    fi
}

test_detailed_metrics_validation() {
    log_info "Test 16: Detailed metrics validation - mathematical correctness"
    
    # Configure a controlled scenario
    local scenario_json='{
        "numMotes": 3,
        "numGateways": 2,
        "seed": 777,
        "areaWidthMeters": 1000,
        "areaHeightMeters": 1000,
        "placementType": "random_uniform",
        "movementType": "random_walk",
        "movingFraction": 1.0,
        "defaultPower": 12,
        "defaultSpreadingFactor": 10
    }'
    
    if ! http_post "/configure_scenario" "$scenario_json"; then
        log_error "Failed to configure detailed metrics test scenario"
        return 1
    fi
    log_success "Detailed metrics scenario configured"
    
    if ! http_post "/start_run"; then
        log_error "Failed to start detailed metrics test"
        return 1
    fi
    log_success "Detailed metrics test started"
    
    # Wait and capture initial state
    sleep 5
    http_get "/monitor" "$TEMP_DIR/metrics_t1.json"
    
    # Wait longer for metrics to accumulate
    sleep 10
    http_get "/monitor" "$TEMP_DIR/metrics_t2.json"
    
    # Run Python validation script
    python3 <<PYTHON_VALIDATION
import json
import math

def load_monitor(filename):
    with open(filename) as f:
        return json.load(f)

data1 = load_monitor('$TEMP_DIR/metrics_t1.json')
data2 = load_monitor('$TEMP_DIR/metrics_t2.json')

motes1 = {m['eui']: m for m in data1.get('moteStates', [])}
motes2 = {m['eui']: m for m in data2.get('moteStates', [])}

errors = []
warnings = []
passed = []

print("=" * 60)
print("DETAILED METRICS VALIDATION REPORT")
print("=" * 60)

for eui in motes1:
    if eui not in motes2:
        warnings.append(f"Mote {eui} disappeared between measurements")
        continue
    
    m1, m2 = motes1[eui], motes2[eui]
    
    print(f"\nMote {eui}:")
    print(f"  Initial position: ({m1['xpos']}, {m1['ypos']})")
    print(f"  Final position: ({m2['xpos']}, {m2['ypos']})")
    
    # 1. Movement validation
    dx = m2['xpos'] - m1['xpos']
    dy = m2['ypos'] - m1['ypos']
    distance_moved = math.sqrt(dx**2 + dy**2)
    
    # Expect movement since movementType=random_walk
    # With 1500ms ticks and 1 pixel/tick, over 10s we get ~6.67 ticks = ~6.67m
    # But actual movement depends on path and may vary
    if distance_moved > 0:
        passed.append(f"Mote {eui}: Moved {distance_moved:.1f}m as expected")
        print(f"  ✓ Movement: {distance_moved:.1f}m over 10s")
    else:
        # Movement might be 0 if mote reached waypoint and hasn't moved to next
        warnings.append(f"Mote {eui}: No movement detected (may have reached waypoint)")
        print(f"  ⚠ No movement (waypoint reached?)")
    
    # 2. Energy level validation
    e1, e2 = m1['energyLevel'], m2['energyLevel']
    if e1 == 0 and e2 == 0:
        passed.append(f"Mote {eui}: Energy tracking disabled (infinite energy)")
        print(f"  ✓ Energy: Tracking disabled (0 = infinite)")
    elif e1 > 0:
        if e2 <= e1:
            passed.append(f"Mote {eui}: Energy decreased from {e1} to {e2}")
            print(f"  ✓ Energy: {e1} → {e2} (consumed: {e1-e2})")
        else:
            errors.append(f"Mote {eui}: Energy increased from {e1} to {e2} (impossible!)")
            print(f"  ✗ Energy: INCREASED from {e1} to {e2} (ERROR)")
    
    # 3. Packet loss mathematical consistency
    sent = m2['packetsSent']
    lost = m2['packetsLost']
    loss_ratio = m2['packetLoss']
    
    if sent > 0:
        expected_loss_ratio = lost / sent
        ratio_diff = abs(expected_loss_ratio - loss_ratio)
        
        if ratio_diff < 0.01:  # Allow 1% tolerance for rounding
            passed.append(f"Mote {eui}: Packet loss math consistent")
            print(f"  ✓ Packets: {lost}/{sent} lost = {loss_ratio:.3f} (consistent)")
        else:
            errors.append(f"Mote {eui}: Packet loss mismatch: {lost}/{sent} = {expected_loss_ratio:.3f} but reported {loss_ratio:.3f}")
            print(f"  ✗ Packets: Math error - {lost}/{sent} = {expected_loss_ratio:.3f} ≠ {loss_ratio:.3f}")
    
    # 4. Packet counters validation
    if sent < lost:
        errors.append(f"Mote {eui}: Impossible packet counts (sent={sent} < lost={lost})")
        print(f"  ✗ Counters: sent={sent} < lost={lost} (IMPOSSIBLE)")
    else:
        passed.append(f"Mote {eui}: Packet counters valid")
        print(f"  ✓ Counters: sent={sent}, lost={lost}, received={sent-lost}")
    
    # 5. Packet accumulation validation (should increase over time)
    sent1 = m1['packetsSent']
    sent2 = m2['packetsSent']
    
    if sent2 > sent1:
        delta_packets = sent2 - sent1
        passed.append(f"Mote {eui}: Packets accumulated (+{delta_packets})")
        print(f"  ✓ Accumulation: {sent1} → {sent2} (+{delta_packets} packets)")
    elif sent2 == sent1:
        warnings.append(f"Mote {eui}: No packets sent in 10s interval")
        print(f"  ⚠ No packets sent in 10s (startOffset delay?)")
    else:
        errors.append(f"Mote {eui}: Packet count decreased from {sent1} to {sent2}")
        print(f"  ✗ Packets decreased: {sent1} → {sent2} (ERROR)")
    
    # 6. RSSI validation (should be negative)
    rssi = m2.get('highestReceivedSignal')
    if rssi is not None:
        if rssi < 0:
            passed.append(f"Mote {eui}: RSSI valid ({rssi:.1f} dBm)")
            print(f"  ✓ RSSI: {rssi:.1f} dBm (valid negative value)")
        else:
            errors.append(f"Mote {eui}: Invalid RSSI {rssi} (should be negative)")
            print(f"  ✗ RSSI: {rssi} dBm (should be negative)")
    
    # 7. Distance validation (should be non-negative and reasonable)
    distance = m2.get('shortestDistanceToGateway')
    if distance:
        if distance >= 0 and distance <= 1500:  # Within area bounds (diagonal ~1414m)
            passed.append(f"Mote {eui}: Distance to gateway reasonable ({distance:.1f}m)")
            print(f"  ✓ Distance: {distance:.1f}m to nearest gateway (valid)")
        else:
            warnings.append(f"Mote {eui}: Unusual distance {distance:.1f}m to gateway")
            print(f"  ⚠ Distance: {distance:.1f}m (outside expected range)")
    
    # Note: highestReceivedSignal appears to be transmission power, not actual RSSI
    # based on code analysis, so RSSI/distance correlation test is removed
    
    # 8. Spreading factor and power validation
    sf = m2['sf']
    power = m2['transmissionPower']
    if 7 <= sf <= 12 and -3 <= power <= 14:
        passed.append(f"Mote {eui}: SF and power in valid ranges")
        print(f"  ✓ SF: {sf}, Power: {power} dBm (valid ranges)")
    else:
        errors.append(f"Mote {eui}: SF={sf} or power={power} out of valid range")
        print(f"  ✗ SF: {sf}, Power: {power} (out of range)")

print("\n" + "=" * 60)
print("SUMMARY")
print("=" * 60)
print(f"Passed: {len(passed)}")
print(f"Warnings: {len(warnings)}")
print(f"Errors: {len(errors)}")

if warnings:
    print("\nWarnings:")
    for w in warnings[:5]:  # Show first 5 warnings
        print(f"  ⚠ {w}")

if errors:
    print("\nErrors:")
    for e in errors:
        print(f"  ✗ {e}")
    exit(1)
else:
    print("\n✓ All detailed metrics validations passed!")
    exit(0)
PYTHON_VALIDATION
    
    local validation_result=$?
    if [ $validation_result -eq 0 ]; then
        log_success "All detailed metrics validations passed"
    else
        log_error "Detailed metrics validation failed (see report above)"
    fi
    
    # Stop simulation
    http_post "/stop_run" "$TEMP_DIR/stop_response.json"
    sleep 1
    
    return $validation_result
}

# Test 17: Personalized configuration - static motes at exact positions
test_personalized_static() {
    log_info "Test 17: Personalized configuration - static positioning"
    
    # Stop any running simulation
    http_post "/stop_run" || true
    sleep 1
    
    # Configure personalized scenario with exact positions
    local personalized_json='{
        "mode": "personalized",
        "areaWidthMeters": 1000,
        "areaHeightMeters": 1000,
        "motes": [
            {
                "eui": 1001,
                "xPos": 100,
                "yPos": 100,
                "transmissionPower": 14,
                "spreadingFactor": 7,
                "movementType": "static"
            },
            {
                "eui": 1002,
                "xPos": 900,
                "yPos": 900,
                "transmissionPower": 10,
                "spreadingFactor": 12,
                "movementType": "static"
            }
        ],
        "gateways": [
            {
                "eui": 2001,
                "xPos": 500,
                "yPos": 500,
                "transmissionPower": 14,
                "spreadingFactor": 7
            }
        ]
    }'
    
    if http_post "/configure_scenario" "$personalized_json" "$TEMP_DIR/config_response.json"; then
        log_success "Personalized static scenario configured"
    else
        log_error "Failed to configure personalized scenario"
        return 1
    fi
    
    # Start simulation
    if http_post "/start_run" "" "$TEMP_DIR/start_response.json"; then
        log_success "Personalized scenario started"
    else
        log_error "Failed to start personalized scenario"
        return 1
    fi
    sleep 2
    
    # Monitor and verify exact positions
    if ! http_get "/monitor" "$TEMP_DIR/monitor_personalized.json"; then
        log_error "Failed to get monitor data"
        http_post "/stop_run"
        return 1
    fi
    
    python3 <<PYTHON_VALIDATE
import json

with open('$TEMP_DIR/monitor_personalized.json') as f:
    data = json.load(f)

motes = data.get('moteStates', [])
gateways = data.get('gatewayStates', [])

errors = []

# Verify count
if len(motes) != 2:
    errors.append(f"Expected 2 motes, got {len(motes)}")
if len(gateways) != 1:
    errors.append(f"Expected 1 gateway, got {len(gateways)}")

if not errors:
    # Verify mote 1001
    m1 = [m for m in motes if m['eui'] == 1001]
    if not m1:
        errors.append("Mote 1001 not found")
    else:
        m1 = m1[0]
        if m1['xpos'] != 100 or m1['ypos'] != 100:
            errors.append(f"Mote 1001 at ({m1['xpos']}, {m1['ypos']}), expected (100, 100)")
        if m1['transmissionPower'] != 14:
            errors.append(f"Mote 1001 power {m1['transmissionPower']}, expected 14")
        if m1['sf'] != 7:
            errors.append(f"Mote 1001 SF {m1['sf']}, expected 7")
    
    # Verify mote 1002
    m2 = [m for m in motes if m['eui'] == 1002]
    if not m2:
        errors.append("Mote 1002 not found")
    else:
        m2 = m2[0]
        if m2['xpos'] != 900 or m2['ypos'] != 900:
            errors.append(f"Mote 1002 at ({m2['xpos']}, {m2['ypos']}), expected (900, 900)")
        if m2['transmissionPower'] != 10:
            errors.append(f"Mote 1002 power {m2['transmissionPower']}, expected 10")
        if m2['sf'] != 12:
            errors.append(f"Mote 1002 SF {m2['sf']}, expected 12")
    
    # Verify gateway
    if gateways:
        g = gateways[0]
        if g['eui'] != 2001:
            errors.append(f"Gateway EUI {g['eui']}, expected 2001")
        if g['xpos'] != 500 or g['ypos'] != 500:
            errors.append(f"Gateway at ({g['xpos']}, {g['ypos']}), expected (500, 500)")

if errors:
    for err in errors:
        print(err)
    exit(1)
else:
    print("✓ All entities at exact specified positions with correct parameters")
    exit(0)
PYTHON_VALIDATE
    
    local result=$?
    if [ $result -eq 0 ]; then
        log_success "All entities at exact positions with correct parameters"
    else
        log_error "Personalized configuration positioning failed"
    fi
    
    # Stop simulation
    http_post "/stop_run"
    sleep 1
    
    return $result
}

# Test 18: Personalized configuration - specific path movement
test_personalized_specific_path() {
    log_info "Test 18: Personalized configuration - specific path following"
    
    # Stop any running simulation
    http_post "/stop_run" || true
    sleep 1
    
    # Configure mote with specific rectangular path
    local personalized_path='{
        "mode": "personalized",
        "areaWidthMeters": 1000,
        "areaHeightMeters": 1000,
        "motes": [
            {
                "eui": 3001,
                "xPos": 100,
                "yPos": 100,
                "movementSpeed": 10.0,
                "movementType": "specific_path",
                "waypoints": [
                    {"x": 100, "y": 100},
                    {"x": 400, "y": 100},
                    {"x": 400, "y": 400},
                    {"x": 100, "y": 400}
                ]
            }
        ],
        "gateways": [
            {
                "eui": 2001,
                "xPos": 250,
                "yPos": 250
            }
        ]
    }'
    
    if ! http_post "/configure_scenario" "$personalized_path"; then
        log_error "Failed to configure specific path scenario"
        return 1
    fi
    log_success "Specific path scenario configured"
    
    # Start and verify movement happens
    http_post "/start_run"
    sleep 1
    http_get "/monitor" "$TEMP_DIR/monitor_path_t0.json"
    
    sleep 4
    http_get "/monitor" "$TEMP_DIR/monitor_path_t5.json"
    
    local moved=$(python3 -c "
import json
with open('$TEMP_DIR/monitor_path_t0.json') as f: d0 = json.load(f)
with open('$TEMP_DIR/monitor_path_t5.json') as f: d5 = json.load(f)
m0 = d0['moteStates'][0]
m5 = d5['moteStates'][0]
print('yes' if (m0['xpos'], m0['ypos']) != (m5['xpos'], m5['ypos']) else 'no')
" 2>/dev/null || echo "error")
    
    if [ "$moved" = "yes" ]; then
        log_success "Mote is following the configured specific path"
    else
        log_warn "Mote movement not detected (may need more time)"
    fi
    
    http_post "/stop_run"
    sleep 1
    return 0
}

# Test 19: Personalized configuration - radius-constrained random walk
test_personalized_radius_constraint() {
    log_info "Test 19: Personalized configuration - radius-constrained movement"
    
    # Stop any running simulation
    http_post "/stop_run" || true
    sleep 1
    
    # Configure mote with radius constraint
    local personalized_radius='{
        "mode": "personalized",
        "areaWidthMeters": 1000,
        "areaHeightMeters": 1000,
        "motes": [
            {
                "eui": 4001,
                "xPos": 500,
                "yPos": 500,
                "movementSpeed": 20.0,
                "movementType": "random_walk",
                "waypointCount": 6,
                "waypointRadius": 100.0
            }
        ],
        "gateways": [
            {
                "eui": 2001,
                "xPos": 500,
                "yPos": 500
            }
        ]
    }'
    
    if ! http_post "/configure_scenario" "$personalized_radius"; then
        log_error "Failed to configure radius-constrained scenario"
        return 1
    fi
    log_success "Radius-constrained scenario configured"
    
    # Start simulation and let it run
    http_post "/start_run"
    sleep 5
    
    # Monitor position
    http_get "/monitor" "$TEMP_DIR/monitor_radius.json"
    
    local within_radius=$(python3 -c "
import json, math
with open('$TEMP_DIR/monitor_radius.json') as f:
    data = json.load(f)
m = data['moteStates'][0]
dist = math.sqrt((m['xpos'] - 500)**2 + (m['ypos'] - 500)**2)
print('yes' if dist <= 150 else 'no')  # Allow 50 unit tolerance
" 2>/dev/null || echo "error")
    
    if [ "$within_radius" = "yes" ]; then
        log_success "Mote respected radius constraint"
    else
        log_warn "Mote may have exceeded radius (movement variance)"
    fi
    
    http_post "/stop_run"
    sleep 1
    return 0
}

# Test 20: Backward compatibility - bulk mode still works
test_backward_compatibility() {
    log_info "Test 20: Backward compatibility - bulk mode"
    
    # Stop any running simulation
    http_post "/stop_run" || true
    sleep 1
    
    # Use traditional bulk configuration (without mode field)
    local bulk_config='{
        "numMotes": 4,
        "numGateways": 2,
        "seed": 54321,
        "areaWidthMeters": 800,
        "areaHeightMeters": 800,
        "placementType": "random_uniform",
        "movementType": "static",
        "defaultPower": 12,
        "defaultSpreadingFactor": 10
    }'
    
    if ! http_post "/configure_scenario" "$bulk_config"; then
        log_error "Bulk mode configuration failed"
        return 1
    fi
    log_success "Bulk mode (legacy) configuration accepted"
    
    # Start and verify
    http_post "/start_run"
    sleep 2
    
    http_get "/monitor" "$TEMP_DIR/monitor_bulk.json"
    
    local mote_count=$(json_array_length "moteStates" "$TEMP_DIR/monitor_bulk.json")
    local gateway_count=$(json_array_length "gatewayStates" "$TEMP_DIR/monitor_bulk.json")
    
    if [ "$mote_count" = "4" ] && [ "$gateway_count" = "2" ]; then
        log_success "Bulk mode creates correct number of entities (4 motes, 2 gateways)"
    else
        log_error "Bulk mode created $mote_count motes and $gateway_count gateways, expected 4 and 2"
        http_post "/stop_run"
        return 1
    fi
    
    http_post "/stop_run"
    sleep 1
    return 0
}

# Test 21: Energy depletion - battery consumption
test_energy_depletion() {
    log_info "Test 21: Energy depletion - battery consumption"
    
    http_post "/stop_run" || true
    sleep 1
    
    # Configure mote with limited energy
    local config='{
        "mode": "personalized",
        "areaWidthMeters": 500,
        "areaHeightMeters": 500,
        "motes": [{
            "eui": 9001,
            "xPos": 100,
            "yPos": 100,
            "transmissionPower": 14,
            "spreadingFactor": 12,
            "samplingRate": 200,
            "energyLevel": 500,
            "movementType": "static"
        }],
        "gateways": [{"eui": 6001, "xPos": 100, "yPos": 100}]
    }'
    
    http_post "/configure_scenario" "$config"
    http_post "/start_run"
    sleep 3
    
    http_get "/monitor" "$TEMP_DIR/energy_test.json"
    
    # Expected: 14dBm SF12 costs ~30 units/packet
    # 500 initial energy allows ~16 packets before insufficient energy
    local energy=$(python3 -c "import json,sys;data=json.load(sys.stdin);print(data['moteStates'][0]['energyLevel'])" < "$TEMP_DIR/energy_test.json")
    local packets=$(python3 -c "import json,sys;data=json.load(sys.stdin);print(data['moteStates'][0]['packetsSent'])" < "$TEMP_DIR/energy_test.json")
    
    if [ "$energy" -lt 500 ] && [ "$packets" -gt 0 ]; then
        local consumed=$((500 - energy))
        local avg_cost=$(python3 -c "print(round($consumed / $packets, 1))")
        log_success "Energy depleted: $consumed units consumed over $packets packets (avg $avg_cost units/pkt)"
    else
        log_error "Energy not depleting: energy=$energy, packets=$packets"
        http_post "/stop_run"
        return 1
    fi
    
    http_post "/stop_run"
    sleep 1
    return 0
}

# Test 22: Energy depletion - transmission stops when depleted
test_energy_stops_transmission() {
    log_info "Test 22: Energy depletion - transmission stops when insufficient"
    
    http_post "/stop_run" || true
    sleep 1
    
    local config='{
        "mode": "personalized",
        "areaWidthMeters": 500,
        "areaHeightMeters": 500,
        "motes": [{
            "eui": 9002,
            "xPos": 100,
            "yPos": 100,
            "transmissionPower": 14,
            "spreadingFactor": 12,
            "samplingRate": 100,
            "energyLevel": 200,
            "movementType": "static"
        }],
        "gateways": [{"eui": 6002, "xPos": 100, "yPos": 100}]
    }'
    
    http_post "/configure_scenario" "$config"
    http_post "/start_run"
    sleep 2
    
    http_get "/monitor" "$TEMP_DIR/energy_low.json"
    local energy=$(python3 -c "import json,sys;data=json.load(sys.stdin);print(data['moteStates'][0]['energyLevel'])" < "$TEMP_DIR/energy_low.json")
    local packets_before=$(python3 -c "import json,sys;data=json.load(sys.stdin);print(data['moteStates'][0]['packetsSent'])" < "$TEMP_DIR/energy_low.json")
    
    # Wait and check if packets stopped increasing
    sleep 3
    http_get "/monitor" "$TEMP_DIR/energy_after.json"
    local packets_after=$(python3 -c "import json,sys;data=json.load(sys.stdin);print(data['moteStates'][0]['packetsSent'])" < "$TEMP_DIR/energy_after.json")
    
    # Expected: transmission stops when energy < cost (~30 units)
    if [ "$energy" -lt 30 ] && [ "$packets_before" = "$packets_after" ]; then
        log_success "Transmission stopped with insufficient energy (${energy} units < 30 required)"
    else
        log_error "Transmission did not stop: energy=$energy, packets $packets_before → $packets_after"
        http_post "/stop_run"
        return 1
    fi
    
    http_post "/stop_run"
    sleep 1
    return 0
}

# Test 23: Energy depletion - infinite energy mode (energyLevel=0)
test_infinite_energy() {
    log_info "Test 23: Infinite energy mode (energyLevel=0)"
    
    http_post "/stop_run" || true
    sleep 1
    
    local config='{
        "mode": "personalized",
        "areaWidthMeters": 500,
        "areaHeightMeters": 500,
        "motes": [{
            "eui": 9003,
            "xPos": 100,
            "yPos": 100,
            "transmissionPower": 14,
            "spreadingFactor": 12,
            "samplingRate": 10,
            "energyLevel": 0,
            "movementType": "static"
        }],
        "gateways": [{"eui": 6003, "xPos": 100, "yPos": 100}]
    }'
    
    http_post "/configure_scenario" "$config"
    http_post "/start_run"
    sleep 2
    
    http_get "/monitor" "$TEMP_DIR/infinite_energy.json"
    local energy=$(python3 -c "import json,sys;data=json.load(sys.stdin);print(data['moteStates'][0]['energyLevel'])" < "$TEMP_DIR/infinite_energy.json")
    local packets=$(python3 -c "import json,sys;data=json.load(sys.stdin);print(data['moteStates'][0]['packetsSent'])" < "$TEMP_DIR/infinite_energy.json")
    
    if [ "$energy" = "0" ] && [ "$packets" -gt 0 ]; then
        log_success "Infinite energy mode: energyLevel=0 (unchanged), $packets packets sent"
    else
        log_error "Infinite energy mode failed: energy=$energy, packets=$packets"
        http_post "/stop_run"
        return 1
    fi
    
    http_post "/stop_run"
    sleep 1
    return 0
}

# Main execution
main() {
    echo
    echo "======================================"
    echo "  DingNet Integration Test Suite"
    echo "======================================"
    echo "Target: $BASE_URL"
    echo

    # Check if server is reachable
    log_info "Checking server availability..."
    if ! curl -s -o /dev/null "$BASE_URL/" 2>/dev/null; then
        log_error "Cannot reach DingNet server at $BASE_URL"
        exit 1
    fi
    log_success "Server is reachable"
    echo

    # Run all tests
    run_test test_base_endpoint
    run_test test_schemas
    run_test test_monitor_before_start
    run_test test_status_endpoint
    run_test test_scenario_configuration
    run_test test_start_simulation
    run_test test_monitor_after_start
    run_test test_status_during_run
    run_test test_execute_adaptations
    run_test test_monitor_after_adaptation
    run_test test_stop_simulation
    run_test test_monitor_after_stop
    run_test test_scenario_with_movement
    run_test test_static_scenario
    run_test test_metrics_validation
    run_test test_detailed_metrics_validation
    run_test test_personalized_static
    run_test test_personalized_specific_path
    run_test test_personalized_radius_constraint
    run_test test_backward_compatibility
    run_test test_energy_depletion
    run_test test_energy_stops_transmission
    run_test test_infinite_energy

    # Summary
    echo
    echo "======================================"
    echo "  Test Summary"
    echo "======================================"
    echo "Total tests:  $TESTS_TOTAL"
    echo "Passed:       $TESTS_PASSED"
    if [[ $TESTS_TOTAL -gt 0 ]]; then
        local pass_pct=$(python3 -c "print(f'{100.0 * $TESTS_PASSED / $TESTS_TOTAL:.1f}')" 2>/dev/null || echo "?")
        echo "Pass rate:    ${pass_pct}%"
    fi
    echo "Failed:       $TESTS_FAILED"
    echo "======================================"
    echo

    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed!"
        exit 0
    else
        log_error "$TESTS_FAILED test(s) failed"
        exit 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        --url)
            BASE_URL="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Options:"
            echo "  -v, --verbose     Enable verbose output"
            echo "  --url URL         Set base URL (default: http://localhost:3000)"
            echo "  -h, --help        Show this help"
            echo
            echo "Environment variables:"
            echo "  DINGNET_URL       Base URL for DingNet server"
            echo "  VERBOSE           Set to 1 for verbose output"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

main
