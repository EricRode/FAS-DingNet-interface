# DingNet Configuration Quick Reference

## Mode Selection

```json
{}                       // Empty = default mode (hardcoded configuration)
{"mode": "default"}      // Explicit default mode
{"mode": "bulk"}         // Random generation with counts
{"mode": "personalized"} // Explicit per-entity configuration
```

Or let the system auto-detect based on fields provided (if `motes`/`gateways` present → personalized, if `numMotes`/`numGateways` present → bulk).

**Default Value Reporting**: The configuration endpoint automatically reports which default values were applied for any unspecified parameters in bulk mode.

## Bulk Mode (Random Generation)

```json
{
  "numMotes": 10,
  "numGateways": 3,
  "seed": 42,
  "areaWidthMeters": 1000,
  "areaHeightMeters": 1000,
  "placementType": "random_uniform",
  "movementType": "random_walk",
  "defaultPower": 14,
  "defaultSpreadingFactor": 7,
  "defaultEnergyLevel": 1200,
  "defaultSamplingRate": 5000,
  "defaultMovementSpeed": 1.0,
  "defaultStartOffset": 0
}
```

**Note**: All `default*` fields apply to ALL entities uniformly.

## Personalized Mode Examples

### Static Network
```json
{
  "mode": "personalized",
  "areaWidthMeters": 1000,
  "areaHeightMeters": 1000,
  "motes": [
    {"eui": 1001, "xPos": 100, "yPos": 100, "movementType": "static"},
    {"eui": 1002, "xPos": 900, "yPos": 900, "movementType": "static"}
  ],
  "gateways": [
    {"eui": 2001, "xPos": 500, "yPos": 500}
  ]
}
```

### Patrol Route
```json
{
  "mode": "personalized",
  "motes": [{
    "eui": 3001,
    "xPos": 100, "yPos": 100,
    "movementSpeed": 5.0,
    "movementType": "specific_path",
    "waypoints": [
      {"x": 100, "y": 100},
      {"x": 500, "y": 100},
      {"x": 500, "y": 500},
      {"x": 100, "y": 500}
    ]
  }],
  "gateways": [{"eui": 2001, "xPos": 300, "yPos": 300}]
}
```

### Constrained Exploration
```json
{
  "mode": "personalized",
  "motes": [{
    "eui": 4001,
    "xPos": 500, "yPos": 500,
    "movementSpeed": 10.0,
    "movementType": "random_walk",
    "waypointRadius": 150.0,
    "waypointCount": 8
  }],
  "gateways": [{"eui": 2001, "xPos": 500, "yPos": 500}]
}
```

### Mixed Configuration
```json
{
  "mode": "personalized",
  "motes": [
    {
      "eui": 5001,
      "xPos": 100, "yPos": 100,
      "movementType": "static",
      "transmissionPower": 14,
      "spreadingFactor": 7
    },
    {
      "eui": 5002,
      "xPos": 500, "yPos": 500,
      "movementSpeed": 5.0,
      "movementType": "random_walk",
      "transmissionPower": 10,
      "spreadingFactor": 12
    }
  ],
  "gateways": [
    {"eui": 2001, "xPos": 250, "yPos": 250},
    {"eui": 2002, "xPos": 750, "yPos": 750}
  ]
}
```

## Movement Types

| Type | Description | Required Fields | Optional Fields |
|------|-------------|----------------|-----------------|
| `static` | No movement | - | - |
| `random_walk` | Random waypoints anywhere | - | `waypointCount` |
| `random_walk` (radius) | Random within radius | `waypointRadius` | `waypointCount` |
| `specific_path` | Follow exact path | `waypoints` | - |

## Parameter Ranges

| Parameter | Type | Range | Default |
|-----------|------|-------|---------|
| `xPos`, `yPos` | Integer | 0 - areaSize | - |
| `transmissionPower` | Integer | 2 - 14 dBm | 14 |
| `spreadingFactor` | Integer | 7 - 12 | 7 |
| `samplingRate` | Integer | > 0 ms | 10000 |
| `movementSpeed` | Double | >= 0.0 | 0.5 |
| `energyLevel` | Integer | >= 0 (0=infinite, >0=limited battery) | 0 |
| `waypointCount` | Integer | > 0 | 6 |
| `waypointRadius` | Double | > 0.0 | - |

**Energy Level Notes:**
- `0` = Infinite energy (battery tracking disabled, mote never depletes)
- `>0` = Limited battery (depletes per transmission, stops at 0)
- Mode is permanent once set at creation
- Energy cost formula: `10 × ((power+3)/10) × (SF/7)` units/packet
- Typical values: 500-5000 for realistic scenarios

## API Endpoints

```bash
# Configure scenario
curl -X POST http://localhost:3000/configure_scenario \
  -H "Content-Type: application/json" \
  -d @scenario.json

# Start simulation
curl -X POST http://localhost:3000/start_run

# Monitor state
curl http://localhost:3000/monitor

# Stop simulation
curl -X POST http://localhost:3000/stop_run
```

## Common Patterns

### Distance Testing
Create motes at known distances from gateway to test RSSI/packet loss:
```json
{
  "motes": [
    {"eui": 1, "xPos": 500, "yPos": 500},  // 0m from gateway
    {"eui": 2, "xPos": 700, "yPos": 500},  // 200m
    {"eui": 3, "xPos": 1000, "yPos": 500}  // 500m
  ],
  "gateways": [{"eui": 2001, "xPos": 500, "yPos": 500}]
}
```

### Handoff Testing
Mote moves between two gateways:
```json
{
  "motes": [{
    "eui": 1,
    "xPos": 100, "yPos": 500,
    "movementType": "specific_path",
    "waypoints": [
      {"x": 100, "y": 500},
      {"x": 900, "y": 500}
    ]
  }],
  "gateways": [
    {"eui": 2001, "xPos": 200, "yPos": 500},
    {"eui": 2002, "xPos": 800, "yPos": 500}
  ]
}
```

### Parameter Comparison
Test same scenario with different SF:
```json
{
  "motes": [
    {"eui": 1, "xPos": 100, "yPos": 100, "spreadingFactor": 7},
    {"eui": 2, "xPos": 200, "yPos": 100, "spreadingFactor": 10},
    {"eui": 3, "xPos": 300, "yPos": 100, "spreadingFactor": 12}
  ],
  "gateways": [{"eui": 2001, "xPos": 500, "yPos": 500}]
}
```

### Energy Depletion Testing
Test battery lifetime with different power settings:
```json
{
  "motes": [
    {"eui": 1, "xPos": 100, "yPos": 100, "transmissionPower": 14, "spreadingFactor": 12, "energyLevel": 600},
    {"eui": 2, "xPos": 200, "yPos": 100, "transmissionPower": 0, "spreadingFactor": 7, "energyLevel": 600},
    {"eui": 3, "xPos": 300, "yPos": 100, "transmissionPower": 14, "spreadingFactor": 12, "energyLevel": 0}
  ],
  "gateways": [{"eui": 2001, "xPos": 500, "yPos": 500}]
}
```
**Expected behavior:**
- Mote 1: ~20 packets (600 / 30 = 20 at 14dBm + SF12), then stops
- Mote 2: ~200 packets (600 / 3 = 200 at 0dBm + SF7), then stops
- Mote 3: Unlimited packets (infinite energy mode)

## Tips

1. **Reproducibility**: Use explicit EUIs and positions for repeatable experiments
2. **Debugging**: Start with static motes, then add movement
3. **Performance**: Fewer motes with specific paths = faster simulation
4. **Energy Testing**: Use `energyLevel=0` for initial testing, then add realistic battery constraints
5. **Monitoring Energy**: Check `energyLevel` in `/monitor` to track battery depletion over time
4. **Validation**: Check monitor output to verify configurations applied correctly
5. **Testing**: Run simulations for 5-10 seconds minimum to see stable behavior

## See Also

- `CONFIGURATION_GUIDE.md` - Detailed documentation with explanations
- `REFACTOR_SUMMARY.md` - Technical details of the implementation
- `test_integration.sh` - Automated test examples
