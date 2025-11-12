package models;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

/**
 * DTO representing the energy consumption history for a mote.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class MoteEnergyUsageModel {
    private Long EUI;
    private Integer run;

    @Builder.Default
    private List<Double> transmissionEnergy = new ArrayList<>();

    private Double totalEnergy;
}
