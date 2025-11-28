# DingNet Configuration Guide

## Overview

DingNet now supports three configuration modes for creating simulation scenarios:

1. **Default Mode**: Uses hardcoded configuration (original behavior)
2. **Bulk Mode**: Random generation with specified counts (original parameterized behavior)
3. **Personalized Mode**: Explicit per-entity configuration for reproducibility

## Configuration Modes

### 1. Default Mode

Uses hardcoded defaults from the original implementation. Can be invoked with empty JSON or explicit mode specification.

**Empty configuration (recommended for default):**
```json
{}
```

**Explicit mode specification:**
```json
{
  "mode": "default"
}
```

Both approaches produce the same result: hardcoded default scenario with 3 motes and 4 gateways.

### 2. Bulk Mode (Random Generation)

Generates random mote and gateway placements with specified counts and parameters.

```json
{
  "mode": "bulk",
  "numMotes": 5,
  "numGateways": 2,
  "seed": 12345,
  "areaWidthMeters": 1000,
  "areaHeightMeters": 1000,
  "placementType": "random_uniform",
  "movementType": "random_walk",
  "defaultPower": 12,
  "defaultSpreadingFactor": 10,
  "defaultEnergyLevel": 1000,
  "defaultSamplingRate": 5000,
  "defaultMovementSpeed": 1.0
}
```

**Note**: All `default*` parameters apply uniformly to all motes/gateways. For individual per-entity configuration, use **personalized mode**.

**Parameters:**
- `numMotes`: Number of motes to create (default: 3)
- `numGateways`: Number of gateways to create (default: 4)
- `seed`: Random seed for reproducibility (default: random)
- `areaWidthMeters`: Simulation area width (default: 2000)
- `areaHeightMeters`: Simulation area height (default: 2000)
- `placementType`: `"random_uniform"` or `"random_clustered"` (default: "random_uniform")
- `movementType`: `"static"` or `"random_walk"` (default: "static")
- `defaultPower`: Default transmission power in dBm for all entities (default: 14)
- `defaultSpreadingFactor`: Default LoRa spreading factor 7-12 for all entities (default: 12)
- `defaultEnergyLevel`: Default initial battery capacity for all motes (default: 0 = infinite energy)
- `defaultSamplingRate`: Default sensor sampling interval in ms for all motes (default: 10000)
- `defaultMovementSpeed`: Default movement speed in meters/tick for all motes (default: 0.5)
- `defaultStartOffset`: Default start time offset in ticks for all motes (default: random 0-4)

### 3. Personalized Mode (Explicit Configuration)

Allows precise control over individual mote and gateway configurations for reproducible scenarios.

```json
{
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
      "samplingRate": 60000,
      "movementSpeed": 5.0,
      "startOffset": 0,
      "energyLevel": 1000,
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
}
```

## Personalized Configuration Reference

### Mote Configuration

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `eui` | Long | Optional | Unique identifier (random if not specified) |
| `xPos` | Integer | **Required** | X position in meters |
| `yPos` | Integer | **Required** | Y position in meters |
| `transmissionPower` | Integer | Optional | Transmission power in dBm (default from scenario) |
| `spreadingFactor` | Integer | Optional | LoRa spreading factor 7-12 (default from scenario) |
| `samplingRate` | Integer | Optional | Sensor sampling interval in ms (default: 10000) |
| `movementSpeed` | Double | Optional | Movement speed in units/tick (default: 0.5) |
| `startOffset` | Integer | Optional | Start time offset in ticks (default: random 0-4) |
| `energyLevel` | Integer | Optional | **Initial battery capacity** (default: 0 = infinite energy). See Energy Management below |
| `movementType` | String | Optional | Movement behavior (see below) |
| `waypoints` | Array | Conditional | Required for `specific_path` movement |
| `waypointCount` | Integer | Optional | Number of waypoints for `random_walk` (default: 6) |
| `waypointRadius` | Double | Optional | Max distance from start for `random_walk` |

### Energy Management

The `energyLevel` parameter controls battery behavior for the mote's entire lifetime:

**Infinite Energy Mode** (`energyLevel = 0`):
- Battery tracking is **disabled permanently** at mote creation
- Mote has unlimited energy and never depletes
- Energy remains at 0 throughout simulation
- Ideal for testing scenarios without battery constraints
- **Default behavior** (backward compatible)

**Limited Battery Mode** (`energyLevel > 0`):
- Battery tracking is **enabled permanently** at mote creation
- Initial value represents battery capacity in energy units
- Energy depletes with each transmission based on physics formula:
  ```
  cost = 10 × ((transmissionPower + 3) / 10) × (spreadingFactor / 7)
  ```
- **When energy reaches 0, mote stops transmitting permanently**
- Cannot be recharged in current implementation
- Cannot switch back to infinite energy mode

**Energy Cost Examples** (validated):
- 14 dBm + SF7: ~17 units/packet
- 14 dBm + SF12: ~30 units/packet ✅ verified
- 0 dBm + SF7: ~3 units/packet
- 0 dBm + SF12: ~5 units/packet

**Recommended Energy Values**:
- **500-1000 units**: Short-lived sensors (20-60 packets at high power)
- **2000-5000 units**: Medium lifetime sensors (100-300 packets)
- **10000+ units**: Long-lived sensors (500+ packets)
- **0 units**: Infinite energy (no battery constraints)

**Example Configuration**:
```json
{
  "eui": 1001,
  "xPos": 100,
  "yPos": 200,
  "transmissionPower": 14,
  "spreadingFactor": 12,
  "energyLevel": 600,
  "movementType": "static"
}
```
This mote will send approximately 20 packets (600 / 30 = 20) before depleting its battery.

### Movement Types

#### Static Movement
Mote remains at initial position.

```json
{
  "movementType": "static"
}
```

#### Random Walk (Unrestricted)
Mote moves randomly to waypoints anywhere in the simulation area.

```json
{
  "movementType": "random_walk",
  "waypointCount": 6
}
```

#### Random Walk (Radius-Constrained)
Mote moves randomly but stays within a radius from its starting position.

```json
{
  "movementType": "random_walk",
  "waypointCount": 8,
  "waypointRadius": 150.0
}
```

**Use case**: Simulating a sensor that explores a local area but doesn't wander too far.

#### Specific Path
Mote follows an exact sequence of waypoints.

```json
{
  "movementType": "specific_path",
  "waypoints": [
    {"x": 100, "y": 100},
    {"x": 300, "y": 100},
    {"x": 300, "y": 300},
    {"x": 100, "y": 300}
  ]
}
```

**Use case**: Simulating a delivery robot following a predetermined route.

### Gateway Configuration

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `eui` | Long | Optional | Unique identifier (random if not specified) |
| `xPos` | Integer | **Required** | X position in meters |
| `yPos` | Integer | **Required** | Y position in meters |
| `transmissionPower` | Integer | Optional | Transmission power in dBm (default from scenario) |
| `spreadingFactor` | Integer | Optional | LoRa spreading factor 7-12 (default from scenario) |

## Example Scenarios

### Example 1: Reproducible Static Network

Create a network with known positions for testing packet loss at specific distances.

```json
{
  "mode": "personalized",
  "areaWidthMeters": 1000,
  "areaHeightMeters": 1000,
  "motes": [
    {
      "eui": 1001,
      "xPos": 100,
      "yPos": 500,
      "transmissionPower": 14,
      "spreadingFactor": 7,
      "movementType": "static"
    },
    {
      "eui": 1002,
      "xPos": 300,
      "yPos": 500,
      "transmissionPower": 14,
      "spreadingFactor": 7,
      "movementType": "static"
    },
    {
      "eui": 1003,
      "xPos": 600,
      "yPos": 500,
      "transmissionPower": 14,
      "spreadingFactor": 7,
      "movementType": "static"
    }
  ],
  "gateways": [
    {
      "eui": 2001,
      "xPos": 500,
      "yPos": 500
    }
  ]
}
```

**Result**: Three motes at 400m, 200m, and 100m from gateway for testing signal strength vs distance.

### Example 2: Mobile Patrol Route

Simulate a security guard following a patrol route around a building.

```json
{
  "mode": "personalized",
  "areaWidthMeters": 500,
  "areaHeightMeters": 500,
  "motes": [
    {
      "eui": 3001,
      "xPos": 50,
      "yPos": 50,
      "movementSpeed": 2.0,
      "movementType": "specific_path",
      "waypoints": [
        {"x": 50, "y": 50},
        {"x": 450, "y": 50},
        {"x": 450, "y": 450},
        {"x": 50, "y": 450},
        {"x": 50, "y": 50}
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
}
```

**Result**: Mote traces a square path around the building perimeter.

### Example 3: Constrained Exploration

Simulate sensors that move within their assigned zones.

```json
{
  "mode": "personalized",
  "areaWidthMeters": 1000,
  "areaHeightMeters": 1000,
  "motes": [
    {
      "eui": 4001,
      "xPos": 250,
      "yPos": 250,
      "movementSpeed": 5.0,
      "movementType": "random_walk",
      "waypointCount": 10,
      "waypointRadius": 100.0
    },
    {
      "eui": 4002,
      "xPos": 750,
      "yPos": 750,
      "movementSpeed": 5.0,
      "movementType": "random_walk",
      "waypointCount": 10,
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
}
```

**Result**: Two motes each exploring a 100m radius zone around their starting positions.

### Example 4: Mixed Configuration

Combine static infrastructure with mobile sensors.

```json
{
  "mode": "personalized",
  "areaWidthMeters": 1000,
  "areaHeightMeters": 1000,
  "motes": [
    {
      "eui": 5001,
      "xPos": 100,
      "yPos": 100,
      "movementType": "static",
      "spreadingFactor": 7
    },
    {
      "eui": 5002,
      "xPos": 900,
      "yPos": 900,
      "movementType": "static",
      "spreadingFactor": 7
    },
    {
      "eui": 5003,
      "xPos": 500,
      "yPos": 500,
      "movementSpeed": 10.0,
      "movementType": "random_walk",
      "waypointCount": 8,
      "spreadingFactor": 12
    }
  ],
  "gateways": [
    {
      "eui": 2001,
      "xPos": 300,
      "yPos": 300
    },
    {
      "eui": 2002,
      "xPos": 700,
      "yPos": 700
    }
  ]
}
```

**Result**: Two static corner motes with one mobile mote roaming the area, covered by two gateways.

## Auto-Detection

If you don't specify a `mode`, the system automatically detects it:

- If `motes` or `gateways` arrays are present → **personalized**
- If `numMotes` or `numGateways` are present → **bulk**
- Otherwise → **default**

## Default Value Validation

When configuring a scenario, the system automatically applies default values for any unspecified parameters and reports them in the response:

**Example - Partial configuration:**
```bash
curl -X POST http://localhost:3000/configure_scenario \
  -H 'Content-Type: application/json' \
  -d '{"mode": "bulk", "numMotes": 5, "defaultEnergyLevel": 800}'
```

**Response:**
```
Scenario configured (bulk mode). Defaults: numGateways=4, areaWidthMeters=2000, 
areaHeightMeters=2000, defaultPower=14dBm, defaultSF=12, 
defaultSamplingRate=10000ms, defaultSpeed=0.5m/tick.
```

This helps you understand exactly what configuration is being used, especially useful for debugging and ensuring consistency across experiments.

## API Usage

### Configure Endpoint

```bash
curl -X POST http://localhost:3000/configure_scenario \
  -H "Content-Type: application/json" \
  -d @scenario.json
```

### Start Simulation

```bash
curl -X POST http://localhost:3000/start_run
```

### Monitor State

```bash
curl http://localhost:3000/monitor
```

## Reproducibility

To ensure reproducible experiments:

1. **Use personalized mode** with explicit positions and EUIs
2. **For random movement**, specify `seed` in bulk mode or use `specific_path` in personalized mode
3. **Save configurations** to version control for experiment tracking
4. **Document parameters** such as `movementSpeed`, `samplingRate`, and LoRa settings

## Benefits of Personalized Mode

1. **Reproducibility**: Exact same scenario every time
2. **Debugging**: Test specific configurations that trigger issues
3. **Benchmarking**: Compare adaptations with identical initial conditions
4. **Validation**: Verify expected behavior at known positions/distances
5. **Research**: Create controlled experiments with specific network topologies
