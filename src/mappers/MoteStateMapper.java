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

    public static List<MoteState> mapMoteListToMoteStateList(LinkedList<Mote> motes) {
        return IntStream.range(0, motes.size())
                .mapToObj(index -> mapMoteToMoteState(motes.get(index), index))
                .collect(Collectors.toList());
    }

    private static MoteState mapMoteToMoteState(Mote mote, int simpleId) {
        Double shortestDistanceToGateway = mote.getShortestDistanceToGateway();
        if (shortestDistanceToGateway == null) {
            shortestDistanceToGateway = moteProbe.getShortestDistanceToGateway(mote);
        }

        Double highestReceivedSignal = mote.getHighestReceivedSignal();
        if (highestReceivedSignal == null) {
            highestReceivedSignal = moteProbe.getHighestReceivedSignal(mote);
        }

        Double packetLoss = mote.getPacketLoss();
        if (packetLoss == null) {
            packetLoss = mote.calculatePacketLoss(mote.getEnvironment().getNumberOfRuns() - 1);
        }

        return MoteState.builder()
                .EUI(mote.getEUI())
                .simpleId(simpleId)
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
