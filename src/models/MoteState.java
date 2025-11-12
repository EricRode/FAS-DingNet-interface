package models;

import IotDomain.MoteSensor;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Data;
import org.jxmapviewer.viewer.GeoPosition;

import java.util.LinkedList;

/**
 * This class is a container class for the state of a mote in a DingNet run.
 * Only non-null values are included when an instance of this class is mapped to JSON.
 * @version 1.0
 */
@Data
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class MoteState {
    /**
     * The device's unique identifier.
     * @since 1.0
     */
    private Long EUI;

    /**
     * The index of the mote in the current environment configuration.
     * @since 1.0
     */
    private Integer id;

    /**
     * The x-coordinate of the mote.
     * @since 1.0
     */
    private Integer XPos;

    /**
     * The y-coordinate of the mote.
     * @since 1.0
     */
    private Integer YPos;

    /**
     * The spreading factor of the mote.
     * @since 1.0
     */
    private Integer SF;

    /**
     * The transmission power of the mote.
     * @since 1.0
     */
    private Integer transmissionPower;

    /**
     * A list of sensors on the mote.
     * @since 1.0
     */
    private LinkedList<MoteSensor> sensors;

    /**
     * The energy level of the mote.
     * @since 1.0
     */
    private Integer energyLevel;

    /**
     * The total amount of energy the mote has consumed in the current run.
     * @since 1.0
     */
    private Double totalEnergyConsumed;

    /**
     * The sampling rate of the mote.
     * @since 1.0
     */
    private Integer samplingRate;

    /**
     * The movement speed of the mote.
     * @since 1.0
     */
    private Double movementSpeed;

    /**
     * The offset the mote has at the start.
     * @since 1.0
     */
    private Integer startOffSet;

    /**
     * The distance to the nearest gateway.
     * @since 1.0
     */
    private Double shortestDistanceToGateway;

    /**
     * The highest received signal by any of the gateways.
     * @since 1.0
     */
    private Double highestReceivedSignal;

    /**
     * The packet loss of the mote.
     * @since 1.0
     */
    private Double packetLoss;

    /**
     * The number of packets sent by the mote.
     * @since 1.0
     */
    private Integer packetsSent;

    /**
     * The number of packets sent by the mote that were lost in transit.
     * @since 1.0
     */
    private Integer packetsLost;
}
