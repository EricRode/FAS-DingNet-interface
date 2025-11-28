package models;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
public class MoteConfig {
    private Long eui;

    @JsonProperty("xPos")
    private Integer xPos;

    @JsonProperty("yPos")
    private Integer yPos;

    private Integer transmissionPower;
    private Integer spreadingFactor;
    private Integer samplingRate;
    private Double movementSpeed;
    private Integer startOffset;

    // Movement configuration
    private String movementType; // "static", "random_walk", "specific_path"
    private Double waypointRadius;
    private List<WaypointConfig> waypoints;

    // Energy configuration
    private Integer energyLevel;
}
