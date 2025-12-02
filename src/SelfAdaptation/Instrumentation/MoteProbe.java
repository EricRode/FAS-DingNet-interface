package SelfAdaptation.Instrumentation;

import IotDomain.Gateway;
import IotDomain.LoraTransmission;
import IotDomain.Mote;
import IotDomain.NetworkEntity;
import SelfAdaptation.FeedbackLoop.GenericFeedbackLoop;

import java.util.LinkedList;
import java.util.Map;

/**
 * A class representing methods for probing.
 */
public class MoteProbe {
    /**
     * A list with feedBackLoops using the probe.
     */
    private GenericFeedbackLoop genericFeedbackLoop;

    /**
     * Constructs a MoteProbe with no FeedBackLoops using it.
     */
    public MoteProbe(){

    }

    /**
     * Returns a list of GenericFeedbackLoops using the probe.
     * @return  A list of GenericFeedbackLoops using the probe.
     */
    public GenericFeedbackLoop getGenericFeedbackLoop() {
        return genericFeedbackLoop;
    }

    /**
     * Sets a GenericFeedbackLoop using the probe.
     * @param genericFeedbackLoop The FeedbackLoop to set.
     */
    public void setGenericFeedbackLoop(GenericFeedbackLoop genericFeedbackLoop){
        this.genericFeedbackLoop =genericFeedbackLoop;
    }

    /**
     * Returns the highest received signal by any of the gateways for a given mote .
     * @param mote The mote to generate the graph of.
     * @return The highest received signal
     * Returns {@code null} if there have not been any transmissions and thus the signal cannot be calculated.
     */
    public Double getHighestReceivedSignal(Mote mote) {
        if (mote == null || mote.getEnvironment() == null) {
            return null;
        }

        Integer numberOfRuns = mote.getEnvironment().getNumberOfRuns();
        if (numberOfRuns == null || numberOfRuns <= 0) {
            return null;
        }

        Integer runIndex = numberOfRuns - 1;
        if (mote.getSentTransmissions(runIndex).isEmpty()) {
            return null;
        }

        Double highestSignal = null;
        for (Gateway gateway : mote.getEnvironment().getGateways()) {
            if (gateway.getAllReceivedTransmissions(runIndex) == null) {
                continue;
            }

            for (Map.Entry<LoraTransmission, Boolean> receivedEntry : gateway.getAllReceivedTransmissions(runIndex).entrySet()) {
                LoraTransmission transmission = receivedEntry.getKey();
                if (transmission != null && transmission.getSender() == mote) {
                    if (highestSignal == null || transmission.getTransmissionPower() > highestSignal) {
                        highestSignal = transmission.getTransmissionPower();
                    }
                }
            }
        }

        return highestSignal;
    }

    /**
     * Returns the spreading factor of a given mote.
     * @param mote The mote to generate the graph of.
     * @return the spreading factor of the mote
     */
    public Integer getSpreadingFactor(NetworkEntity mote) {
        return mote.getSF();
    }

    /**
     * Returns The distance to the nearest Gateway.
     * @param mote The given mote to find the shortest distance.
     * @return The distance to the nearest Gateway.
     * Returns {@code null} if there have not been any transmissions and thus the distance cannot be calculated.
     */
    public Double getShortestDistanceToGateway(Mote mote) {
        if (mote.getSentTransmissions(mote.getEnvironment().getNumberOfRuns() - 1).isEmpty()) {
            return null;
        }

        LinkedList<LoraTransmission> lastTransmissions = new LinkedList<>();
        for(Gateway gateway : mote.getEnvironment().getGateways()){
            for(int i = gateway.getReceivedTransmissions(mote.getEnvironment().getNumberOfRuns()-1).size()-1; i>=0; i--) {
                if(gateway.getReceivedTransmissions(mote.getEnvironment().getNumberOfRuns()-1).get(i).getSender() == mote) {
                    lastTransmissions.add(gateway.getReceivedTransmissions(mote.getEnvironment().getNumberOfRuns()-1).get(i));
                    break;
                }
            }
        }

        // No transmissions, shortest distance to gateway cannot be calculated
        if (lastTransmissions.isEmpty()) {
            return null;
        }

        LoraTransmission bestTransmission = lastTransmissions.getFirst();
        for (LoraTransmission transmission : lastTransmissions){
            if(Math.sqrt(Math.pow(transmission.getReceiver().getYPos()-transmission.getYPos(),2)+
                    Math.pow(transmission.getReceiver().getXPos()-transmission.getXPos(),2))
                    < Math.sqrt(Math.pow(bestTransmission.getReceiver().getYPos()-bestTransmission.getYPos(),2)+
                    Math.pow(bestTransmission.getReceiver().getXPos()-bestTransmission.getXPos(),2)))
                bestTransmission = transmission;
        }

        return Math.sqrt(Math.pow(bestTransmission.getReceiver().getYPos()-bestTransmission.getYPos(),2)+
                Math.pow(bestTransmission.getReceiver().getXPos()-bestTransmission.getXPos(),2));
    }

    /**
     * Returns the power setting of a specific mote.
     * @param mote The mote to get the power setting of.
     * @return The power setting of the mote.
     */
    public Integer getPowerSetting(NetworkEntity mote) {

        return mote.getTransmissionPower();

    }

    /**
     * Triggers the feedback loop.
     * @param gateway
     * @param devEUI
     */
    public void trigger(Gateway gateway, Long devEUI){
        Boolean found = false;
        Mote sender = null;
        for (Mote mote :gateway.getEnvironment().getMotes()){
            if(mote.getEUI() == devEUI){
                sender = mote;
                found = true;
            }
        }
        if(found) {
            if(getGenericFeedbackLoop().isActive()) {
                getGenericFeedbackLoop().adapt(sender, gateway);
            }
        }
    }

}
