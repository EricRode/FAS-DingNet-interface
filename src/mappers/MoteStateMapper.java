package mappers;

import IotDomain.Mote;
import SelfAdaptation.Instrumentation.MoteProbe;
import models.MoteState;

import java.util.LinkedList;
import java.util.List;
import java.util.stream.Collectors;

public class MoteStateMapper {
    private static final MoteProbe moteProbe = new MoteProbe();

    public static List<MoteState> mapMoteListToMoteStateList(LinkedList<Mote> motes) {
        return motes.stream()
                .map(MoteStateMapper::mapMoteToMoteState)
                .collect(Collectors.toList());
    }

    public static MoteState mapMoteToMoteState(Mote mote) {
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
                .transmissionPower(mote.getTransmissionPower())
                .shortestDistanceToGateway(shortestDistanceToGateway)
                .highestReceivedSignal(highestReceivedSignal)
                .SF(mote.getSF())
                .XPos(mote.getXPos())
                .YPos(mote.getYPos())
                .energyLevel(mote.getEnergyLevel())
                .movementSpeed(mote.getMovementSpeed())
                .samplingRate(mote.getSamplingRate())
                .sensors(mote.getSensors())
                .startOffSet(mote.getStartOffset())
                .packetLoss(packetLoss)
                .packetsSent(mote.getNumberOfSentPackets())
                .packetsLost(mote.getNumberOfLostPackets())
                .build();
    }
}
