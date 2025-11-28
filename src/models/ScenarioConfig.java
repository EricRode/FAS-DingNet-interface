package models;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
public class ScenarioConfig {
    private String mode; // "default", "bulk", "personalized"

    // Bulk mode parameters
    private Integer numMotes;
    private Integer numGateways;
    private Integer areaWidthMeters;
    private Integer areaHeightMeters;

    // Bulk mode defaults for entities
    private Integer defaultEnergyLevel;
    private Integer defaultSamplingRate;
    private Double defaultMovementSpeed;
    private Integer defaultStartOffset;
    private Integer defaultTransmissionPower;
    private Integer defaultSpreadingFactor;

    // Personalized mode parameters
    private List<MoteConfig> motes;
    private List<GatewayConfig> gateways;
}
