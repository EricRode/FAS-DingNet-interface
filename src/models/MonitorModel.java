package models;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

/**
 * The Class responsible for storing the state of the simulation in DingNet.
 * Only non-null values are included when an instance of this class is mapped to JSON.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class MonitorModel {
    /**
     * A Boolean that keeps track of whether the simulation is running or not.
     */
    private Boolean isRunning;

    /**
     * A list of MoteStates.
     */
    @Builder.Default
    private List<MoteState> moteStates = new ArrayList<>();

    /**
     * A list of GatewayStates
     */
    @Builder.Default
    private List<GatewayState> gatewayStates = new ArrayList<>();
}
