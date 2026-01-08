package mappers;

import IotDomain.Mote;
import SelfAdaptation.Instrumentation.MoteProbe;
import models.MoteState;

import java.util.LinkedList;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

public class MoteStateMapper {
    private static final MoteProbe moteProbe = new MoteProbe();
    /**
     * Number of most recent transmissions to consider when calculating recent packet loss.
     * Roughly corresponds to 5 minutes of simulated time for regularly reporting motes.
     */
    private static final int RECENT_PACKET_WINDOW_SIZE = 30;

    public static List<MoteState> mapMoteListToMoteStateList(LinkedList<Mote> motes) {
        return IntStream.range(0, motes.size())
                .mapToObj(index -> mapMoteToMoteState(motes.get(index), index))
                .collect(Collectors.toList());
    }

    private static MoteState mapMoteToMoteState(Mote mote, int id) {
        Double shortestDistanceToGateway = mote.getShortestDistanceToGateway();
        if (shortestDistanceToGateway == null) {
            shortestDistanceToGateway = moteProbe.getShortestDistanceToGateway(mote);
        }

        Double highestReceivedSignal = moteProbe.getHighestReceivedSignal(mote);
        mote.setHighestReceivedSignal(highestReceivedSignal);

        Double packetLoss = mote.getPacketLoss();
        Double recentPacketLoss = null;

        Integer runIndex = null;
        if (mote.getEnvironment() != null) {
            Integer numberOfRuns = mote.getEnvironment().getNumberOfRuns();
            if (numberOfRuns != null && numberOfRuns > 0) {
                runIndex = numberOfRuns - 1;
            }
        }

        if (runIndex != null) {
            if (packetLoss == null) {
                packetLoss = mote.calculatePacketLoss(runIndex);
            }
            recentPacketLoss = mote.calculateRecentPacketLoss(runIndex, RECENT_PACKET_WINDOW_SIZE);
        }

        return MoteState.builder()
                .EUI(mote.getEUI())
                .id(id)
                .transmissionPower(mote.getTransmissionPower())
                .shortestDistanceToGateway(shortestDistanceToGateway)
                .highestReceivedSignal(highestReceivedSignal)
                .SF(mote.getSF())
                .XPos(mote.getXPos())
                .YPos(mote.getYPos())
                .energyLevel(mote.getEnergyLevel())
                .totalEnergyConsumed(calculateTotalEnergyConsumption(mote))
                .movementSpeed(mote.getMovementSpeed())
                .samplingRate(mote.getSamplingRate())
                .sensors(mote.getSensors())
                .startOffSet(mote.getStartOffset())
                .packetLoss(packetLoss)
                .recentPacketLoss(recentPacketLoss)
                .packetsSent(mote.getNumberOfSentPackets())
                .packetsLost(mote.getNumberOfLostPackets())
                .build();
    }

    private static Double calculateTotalEnergyConsumption(Mote mote) {
        if (mote == null || mote.getEnvironment() == null) {
            return 0.0;
        }

        Integer numberOfRuns = mote.getEnvironment().getNumberOfRuns();
        if (numberOfRuns == null || numberOfRuns <= 0) {
            return 0.0;
        }

        int currentRunIndex = numberOfRuns - 1;
        return mote.getTotalUsedEnergy(currentRunIndex);
    }
}
