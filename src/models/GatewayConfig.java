package models;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class GatewayConfig {
    private Long eui;

    @JsonProperty("xPos")
    private Integer xPos;

    @JsonProperty("yPos")
    private Integer yPos;

    private Integer transmissionPower;
    private Integer spreadingFactor;
}
