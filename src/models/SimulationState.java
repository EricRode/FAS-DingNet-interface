package models;

import IotDomain.Environment;
import lombok.*;

/**
 * The Class responsible for storing the state of the simulation in DingNet.
 * Only non-null values are included when an instance of this class is mapped to
 * JSON.
 */
@Data
@NoArgsConstructor
public class SimulationState {
    /**
     * The environment of the simulation.
     */
    private Environment environment;

    /**
     * A Boolean that keeps track of whether the simulation is running or not.
     */
    private Boolean isRunning = false;

    private Boolean shouldStop = false;
}
