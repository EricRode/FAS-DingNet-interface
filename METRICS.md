# DingNet Metrics Documentation

This document describes the key metrics used in the DingNet simulator for evaluating network performance and adaptation algorithms.

## Network Performance Metrics

### Packet Loss
The ratio of packets lost to total packets sent.
- **Formula**: `(Total Sent - Total Received) / Total Sent`
- **Significance**: High packet loss indicates network congestion, interference, or poor signal quality.

### Signal Strength (RSSI)
Received Signal Strength Indicator, measured in dBm.
- **Range**: Typically -120 dBm (weak) to -30 dBm (strong).
- **Significance**: Higher RSSI generally leads to better packet reception rates.

### Signal-to-Noise Ratio (SNR)
The ratio of signal power to noise power, measured in dB.
- **Significance**: Higher SNR allows for successful demodulation at lower signal strengths or higher data rates.

### Energy Consumption
The amount of energy consumed by motes for transmission and other operations.
- **Unit**: mJ (milliJoules) or Joules.
- **Significance**: Critical for battery-powered IoT devices. Lower consumption extends device lifespan.

### Latency
The time taken for a packet to travel from the sender to the receiver.
- **Unit**: ms (milliseconds).
- **Significance**: Important for time-sensitive applications.

## Adaptation Metrics

### Spreading Factor (SF)
A parameter of the LoRa modulation that trades data rate for range.
- **Values**: 7 to 12.
- **Trade-off**: Higher SF increases range and sensitivity but decreases data rate and increases energy consumption (longer time-on-air).

### Transmission Power
The power level used for transmitting packets.
- **Range**: -3 dBm to 14 dBm.
- **Trade-off**: Higher power increases range and reliability but consumes more energy.

## Simulation Statistics

### Number of Runs
The number of simulation runs executed.
- **Significance**: Multiple runs are often used to average results and account for stochastic variations.

### Simulation Time
The duration of the simulation.
- **Unit**: Virtual time steps or milliseconds.
