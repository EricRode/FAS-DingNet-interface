package Simulation;

import IotDomain.*;
import SelfAdaptation.Instrumentation.MoteProbe;
import models.SimulationState;
import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.axis.NumberAxis;
import org.jfree.chart.axis.NumberTickUnit;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.chart.plot.XYPlot;
import org.jfree.data.xy.XYSeries;
import org.jfree.data.xy.XYSeriesCollection;
import org.jxmapviewer.viewer.GeoPosition;

import javax.swing.*;
import java.awt.*;
import java.util.List;
import java.util.*;

/**
 * This class provides the data and functionality of the main simulation.
 * 
 * @version 1.0
 */
public class MainSimulation extends Thread {
    private static final MoteProbe moteProbe = new MoteProbe();

    /**
     * The current environment of the simulation.
     * 
     * @since 1.0
     */
    SimulationState simulationState;

    /**
     * Constructs a {@code MainSimulation} object with the Environment
     * {@code environment}.
     * 
     * @param simulationState The environment of the {@code MainSimulation} object.
     * @since 1.0
     */
    public MainSimulation(SimulationState simulationState) {
        this.simulationState = simulationState;
    }

    public static IotDomain.Environment createEnvironment() {
        /*
         * Generate all the points
         */
        GeoPosition mapzero = new GeoPosition(50.853718, 4.673155);
        Integer mapsize = (int) Math
                .ceil(1000 * Math.max(IotDomain.Environment.distance(50.853718, 4.673155, 50.878697, 4.673155),
                        IotDomain.Environment.distance(50.853718, 4.673155, 50.853718, 4.701200)));
        GeoPosition leuven = new GeoPosition(50, 51, 46, 4, 41, 2);
        GeoPosition gw1 = new GeoPosition(50.859722, 4.681944);
        GeoPosition gw2 = new GeoPosition(50.863780, 4.677992);
        GeoPosition gw3 = new GeoPosition(50.867222, 4.678056);
        GeoPosition gw4 = new GeoPosition(50.856667, 4.676389);

        GeoPosition wp1 = new GeoPosition(50.856020, 4.675844);
        GeoPosition wp2 = new GeoPosition(50.856545, 4.676743);
        GeoPosition wp3 = new GeoPosition(50.857852, 4.679702);
        GeoPosition wp4 = new GeoPosition(50.860061, 4.683473);
        GeoPosition wp5 = new GeoPosition(50.861985, 4.680993);
        GeoPosition wp6 = new GeoPosition(50.862263, 4.680672);
        GeoPosition wp7 = new GeoPosition(50.862696, 4.680416);
        GeoPosition wp8 = new GeoPosition(50.863049, 4.680321);
        GeoPosition wp9 = new GeoPosition(50.863455, 4.680385);
        GeoPosition wp10 = new GeoPosition(50.863977, 4.680610);
        GeoPosition wp11 = new GeoPosition(50.864770, 4.680898);
        GeoPosition wp12 = new GeoPosition(50.865176, 4.680973);
        GeoPosition wp13 = new GeoPosition(50.865583, 4.680976);
        GeoPosition wp14 = new GeoPosition(50.867980, 4.680381);
        GeoPosition wp15 = new GeoPosition(50.867881, 4.678226);
        GeoPosition wp16 = new GeoPosition(50.868028, 4.678175);
        GeoPosition wp17 = new GeoPosition(50.869650, 4.676740);

        GeoPosition wp21 = new GeoPosition(50.868551, 4.698337);
        GeoPosition wp22 = new GeoPosition(50.866713, 4.695153);
        GeoPosition wp23 = new GeoPosition(50.861330, 4.685687);
        GeoPosition wp24 = new GeoPosition(50.857910, 4.679724);
        GeoPosition wp25 = new GeoPosition(50.856486, 4.676650);

        /*
         * Create tracks.
         */
        LinkedList<GeoPosition> track0 = new LinkedList<>(Arrays.asList(wp1, wp2, wp3, wp4, wp5, wp6, wp7, wp8, wp9,
                wp10, wp11, wp12, wp13, wp14, wp15, wp16, wp17));
        LinkedList<GeoPosition> track2 = new LinkedList<>(Arrays.asList(wp21, wp22, wp23, wp24, wp25, wp1));

        GeoPosition positionMote2 = new GeoPosition(50.862752, 4.688886);

        /*
         * Prepare simulation environment.
         */
        Characteristic[][] map = new Characteristic[mapsize][mapsize];
        for (int i = 0; i < mapsize; i++) {
            for (int j = 0; j < mapsize / 3; j++) {
                map[j][i] = Characteristic.Forest;
            }
            for (int j = mapsize / 3; j < 2 * mapsize / 3; j++) {
                map[j][i] = Characteristic.Plain;
            }

            for (int j = 2 * mapsize / 3; j < mapsize; j++) {
                map[j][i] = Characteristic.City;
            }
        }

        IotDomain.Environment environment = new IotDomain.Environment(map, mapzero, new LinkedHashSet<>());

        /*
         * Add motes and gateways.
         */
        Random random = new Random();
        new Gateway(random.nextLong(),
                (int) Math.round(1000 * IotDomain.Environment.distance(mapzero.getLatitude(), mapzero.getLongitude(),
                        mapzero.getLatitude(), gw1.getLongitude())),
                (int) Math.round(1000 * IotDomain.Environment.distance(mapzero.getLatitude(), mapzero.getLongitude(),
                        gw1.getLatitude(), mapzero.getLongitude())),
                environment, 14, 12);
        new Gateway(random.nextLong(),
                (int) Math.round(1000 * IotDomain.Environment.distance(mapzero.getLatitude(), mapzero.getLongitude(),
                        mapzero.getLatitude(), gw2.getLongitude())),
                (int) Math.round(1000 * IotDomain.Environment.distance(mapzero.getLatitude(), mapzero.getLongitude(),
                        gw2.getLatitude(), mapzero.getLongitude())),
                environment, 14, 12);
        new Gateway(random.nextLong(),
                (int) Math.round(1000 * IotDomain.Environment.distance(mapzero.getLatitude(), mapzero.getLongitude(),
                        mapzero.getLatitude(), gw3.getLongitude())),
                (int) Math.round(1000 * IotDomain.Environment.distance(mapzero.getLatitude(), mapzero.getLongitude(),
                        gw3.getLatitude(), mapzero.getLongitude())),
                environment, 14, 12);
        new Gateway(random.nextLong(),
                (int) Math.round(1000 * IotDomain.Environment.distance(mapzero.getLatitude(), mapzero.getLongitude(),
                        mapzero.getLatitude(), gw4.getLongitude())),
                (int) Math.round(1000 * IotDomain.Environment.distance(mapzero.getLatitude(), mapzero.getLongitude(),
                        gw4.getLatitude(), mapzero.getLongitude())),
                environment, 14, 12);

        /*
         * Mote 0
         */
        new Mote(random.nextLong(),
                (int) Math.round(1000 * IotDomain.Environment.distance(mapzero.getLatitude(), mapzero.getLongitude(),
                        mapzero.getLatitude(), wp1.getLongitude())),
                (int) Math.round(1000 * IotDomain.Environment.distance(mapzero.getLatitude(), mapzero.getLongitude(),
                        wp1.getLatitude(), mapzero.getLongitude())),
                environment, 14, 12, new LinkedList<>(), 0, track0, 10, 0.5);

        /*
         * Mote 1
         */
        new Mote(random.nextLong(), toMapXCoordinate(wp21, mapzero),
                toMapYCoordinate(wp21, mapzero),
                environment, 14, 12, new LinkedList<>(), 0, new LinkedList<>(), 10, 0.5);

        /*
         * Mote 2
         */
        new Mote(random.nextLong(),
                (int) Math.round(1000 * IotDomain.Environment.distance(mapzero.getLatitude(), mapzero.getLongitude(),
                        mapzero.getLatitude(), positionMote2.getLongitude())),
                (int) Math.round(1000 * IotDomain.Environment.distance(mapzero.getLatitude(), mapzero.getLongitude(),
                        positionMote2.getLatitude(), mapzero.getLongitude())),
                environment, 14, 12, new LinkedList<>(), 0, track2, 10, 0.5);

        return environment;
    }

    /**
     * Starts a DingNet simulation with three motes and four gateways. Two motes are
     * moved along different paths.
     * The simulation state is updated regularly.
     * 
     * @exception InterruptedException can occur in {@link Thread#sleep(long)}
     * @since 1.0
     */
    public void runSimulation(boolean visualizeResults) throws InterruptedException {
        Environment environment;
        if (this.simulationState.getEnvironment() != null) {
            System.out.println("[MainSim] Using pre-created environment from StartRunHandler");
            environment = this.simulationState.getEnvironment();
        } else {
            System.out.println("[MainSim] Creating new environment (fallback)");
            environment = ScenarioFactory.createEnvironment(new models.ScenarioConfig());
            this.simulationState.setEnvironment(environment);
        }

        // Initialize counters and path indices for all motes
        Map<Mote, Integer> samplingCounters = new HashMap<>();
        Map<Mote, Integer> pathIndices = new HashMap<>();

        for (Mote mote : environment.getMotes()) {
            // Use startOffset if defined, otherwise samplingRate
            int initialCounter = (mote.getStartOffset() != null && mote.getStartOffset() > 0)
                    ? mote.getStartOffset()
                    : mote.getSamplingRate();
            samplingCounters.put(mote, initialCounter);
            pathIndices.put(mote, 0);
        }

        GeoPosition mapzero = environment.getMapCenter();

        while (!simulationState.getShouldStop()) {
            for (Mote mote : environment.getMotes()) {
                // 1. Handle Movement
                if (mote.getPath() != null && !mote.getPath().isEmpty()) {
                    int pathIndex = pathIndices.getOrDefault(mote, 0);
                    GeoPosition target = mote.getPath().get(pathIndex % mote.getPath().size());

                    // moveMote returns true if moved, false if reached target (or didn't move)
                    if (!moveMote(target, mote, mapzero)) {
                        // Reached target, move to next waypoint
                        pathIndices.put(mote, pathIndex + 1);
                    }
                }

                // 2. Handle Transmission
                int counter = samplingCounters.getOrDefault(mote, mote.getSamplingRate());
                if (counter <= 0) {
                    mote.sendToGateWay(new Byte[0], new HashMap<>());
                    updateMoteStatistics(mote, environment);
                    samplingCounters.put(mote, mote.getSamplingRate());
                } else {
                    samplingCounters.put(mote, counter - 1);
                }
            }

            environment.tick(1500);
        }
        System.out.println("[MainSim] Simulation loop ended, setting isRunning=false");

        if (visualizeResults) {
            // showCharts(environment, indexesMote2); // Disabled legacy charts for now
        }
    }

    private void updateMoteStatistics(Mote mote, Environment environment) {
        mote.setHighestReceivedSignal(moteProbe.getHighestReceivedSignal(mote));
        mote.setShortestDistanceToGateway(moteProbe.getShortestDistanceToGateway(mote));
        mote.setPacketLoss(mote.calculatePacketLoss(environment.getNumberOfRuns() - 1));
    }

    private static void showCharts(Environment environment, List<Integer> indexesMote2) {
        /*
         * Data collection mote 0
         */
        LinkedList<LinkedList<LoraTransmission>> transmissionsMote0 = new LinkedList<>();
        int transmittedPacketsMote0 = 0;
        int lostPacketsMote0 = 0;
        for (Gateway gateway : environment.getGateways()) {
            transmissionsMote0.add(new LinkedList<>());
            for (LoraTransmission transmission : gateway
                    .getAllReceivedTransmissions(gateway.getEnvironment().getNumberOfRuns() - 1).keySet()) {
                if (transmission.getSender() == environment.getMotes().get(0)) {
                    transmittedPacketsMote0++;
                    if (!gateway.getAllReceivedTransmissions(gateway.getEnvironment().getNumberOfRuns() - 1)
                            .get(transmission))
                        transmissionsMote0.getLast().add(transmission);
                    else {
                        transmissionsMote0.getLast().add(new LoraTransmission(transmission.getSender(),
                                transmission.getReceiver(), -10, transmission.getBandwidth(),
                                transmission.getSpreadingFactor(), transmission.getContent()));
                        lostPacketsMote0++;
                    }
                }
            }
        }

        /*
         * Data collection mote 2
         */
        LinkedList<LinkedList<LoraTransmission>> transmissionsMote2 = new LinkedList<>();

        int transmittedPacketsMote2 = 0;
        int lostPacketsMote2 = 0;
        for (Gateway gateway : environment.getGateways()) {
            transmissionsMote2.add(new LinkedList<>());
            for (LoraTransmission transmission : gateway
                    .getAllReceivedTransmissions(gateway.getEnvironment().getNumberOfRuns() - 1).keySet()) {
                if (transmission.getSender() == environment.getMotes().get(2)) {
                    transmittedPacketsMote2++;
                    if (!gateway.getAllReceivedTransmissions(gateway.getEnvironment().getNumberOfRuns() - 1)
                            .get(transmission))
                        transmissionsMote2.getLast().add(transmission);
                    else {
                        lostPacketsMote2++;
                        transmissionsMote2.getLast().add(new LoraTransmission(transmission.getSender(),
                                transmission.getReceiver(), -10, transmission.getBandwidth(),
                                transmission.getSpreadingFactor(), transmission.getContent()));
                    }
                }
            }
        }

        System.out.println("Sent Packets: " + transmittedPacketsMote0);
        System.out.println("Lost Packets: " + lostPacketsMote0);
        System.out.println("Sent Packets: " + transmittedPacketsMote2);
        System.out.println("Lost Packets: " + lostPacketsMote2);

        /*
         * Creating charts
         */
        XYSeriesCollection dataMote0 = new XYSeriesCollection();
        for (LinkedList<LoraTransmission> list : transmissionsMote0) {
            XYSeries series = new XYSeries(list.get(0).getReceiver().toString());
            Integer i = 0;
            for (LoraTransmission transmission : list) {
                series.add(i, (Number) transmission.getTransmissionPower());
                i = i + 10;
            }
            dataMote0.addSeries(series);
        }

        XYSeriesCollection dataMote2 = new XYSeriesCollection();
        for (LinkedList<LoraTransmission> list : transmissionsMote2) {
            XYSeries series = new XYSeries(list.get(0).getReceiver().toString());
            int i = 0;
            for (LoraTransmission transmission : list) {
                series.add(indexesMote2.get(i), (Number) transmission.getTransmissionPower());
                i++;
            }
            dataMote2.addSeries(series);
        }

        JFreeChart receivedPowerChartMote0 = ChartFactory.createScatterPlot(
                null, // chart title
                "Distance travelled in meter", // x axis label
                "Received signal strength in dB", // y axis label
                dataMote0, // data
                PlotOrientation.VERTICAL,
                true, // include legend
                true, // tooltips
                false // urls
        );
        XYPlot xyPlotreceivedPowerMote0 = (XYPlot) receivedPowerChartMote0.getPlot();
        xyPlotreceivedPowerMote0.setDomainCrosshairVisible(true);
        xyPlotreceivedPowerMote0.setRangeCrosshairVisible(true);
        NumberAxis domainreceivedPowerMote0 = (NumberAxis) xyPlotreceivedPowerMote0.getDomainAxis();
        domainreceivedPowerMote0.setRange(0.0, 2700.0);
        domainreceivedPowerMote0.setTickUnit(new NumberTickUnit(200));
        domainreceivedPowerMote0.setVerticalTickLabels(true);
        NumberAxis rangereceivedPowerMote0 = (NumberAxis) xyPlotreceivedPowerMote0.getRangeAxis();
        rangereceivedPowerMote0.setRange(-85, 0.0);
        rangereceivedPowerMote0.setTickUnit(new NumberTickUnit(4));

        JFreeChart receivedPowerChartMote2 = ChartFactory.createScatterPlot(
                null, // chart title
                "Distance travelled in meter", // x axis label
                "Received signal strength in dB", // y axis label
                dataMote2, // data
                PlotOrientation.VERTICAL,
                true, // include legend
                true, // tooltips
                false // urls
        );
        XYPlot xyPlotreceivedPowerMote2 = (XYPlot) receivedPowerChartMote2.getPlot();
        xyPlotreceivedPowerMote2.setDomainCrosshairVisible(true);
        xyPlotreceivedPowerMote2.setRangeCrosshairVisible(true);
        NumberAxis domainreceivedPowerMote2 = (NumberAxis) xyPlotreceivedPowerMote2.getDomainAxis();
        domainreceivedPowerMote2.setRange(0.0, 2700.0);
        domainreceivedPowerMote2.setTickUnit(new NumberTickUnit(200));
        domainreceivedPowerMote2.setVerticalTickLabels(true);
        NumberAxis rangereceivedPowerMote2 = (NumberAxis) xyPlotreceivedPowerMote2.getRangeAxis();
        rangereceivedPowerMote2.setRange(-85, 0.0);
        rangereceivedPowerMote2.setTickUnit(new NumberTickUnit(4));

        JFrame frame1 = new JFrame("received signals");
        ChartPanel HighestSignalChartpanel = new ChartPanel(receivedPowerChartMote0);
        HighestSignalChartpanel.setPreferredSize(new java.awt.Dimension(1000, 500));
        frame1.getContentPane().add(HighestSignalChartpanel, BorderLayout.NORTH);
        ChartPanel powersettingChart1panel = new ChartPanel(receivedPowerChartMote2);
        powersettingChart1panel.setPreferredSize(new java.awt.Dimension(1000, 500));
        frame1.getContentPane().add(powersettingChart1panel, BorderLayout.SOUTH);
        frame1.pack();
        frame1.setVisible(true);
    }

    /**
     * Runs the simulation and sets the {@code isRunning} flag of the simulation
     * state to {@code false} again.
     * 
     * @exception RuntimeException can occur in
     *                             {@link MainSimulation#runSimulation(boolean)}
     * @since 1.0
     */
    public void run() {
        try {
            this.runSimulation(false);
            this.simulationState.setIsRunning(false);
        } catch (InterruptedException e) {
            throw new RuntimeException(e.getMessage());
        }
    }

    /*
     * The naïve adaptation for our paper
     */
    private static LinkedList<Double> algorithmBuffer = new LinkedList<>();

    private static LoraTransmission naiveAdaptionAlgorithm(Mote mote) {
        LinkedList<LoraTransmission> lastTransmissions = new LinkedList<>();
        for (Gateway gateway : mote.getEnvironment().getGateways()) {
            Boolean placed = false;
            for (int i = gateway.getReceivedTransmissions(gateway.getEnvironment().getNumberOfRuns() - 1).size()
                    - 1; i >= 0 && !placed; i--) {
                if (gateway.getReceivedTransmissions(gateway.getEnvironment().getNumberOfRuns() - 1).get(i)
                        .getSender() == mote) {
                    lastTransmissions.add(
                            gateway.getReceivedTransmissions(gateway.getEnvironment().getNumberOfRuns() - 1).get(i));
                    placed = true;
                }
            }
        }
        LoraTransmission bestTransmission = lastTransmissions.getFirst();
        for (LoraTransmission transmission : lastTransmissions) {
            if (transmission.getTransmissionPower() > bestTransmission.getTransmissionPower())
                bestTransmission = transmission;
        }
        algorithmBuffer.add(bestTransmission.getTransmissionPower());
        if (algorithmBuffer.size() == 5) {
            double average = 0;
            for (Double power : algorithmBuffer) {
                average += power;
            }
            average = average / 5;
            if (average > -42) {
                if (mote.getTransmissionPower() > -3)
                    mote.setTransmissionPower(mote.getTransmissionPower() - 1);
            }
            if (average < -48) {
                if (mote.getTransmissionPower() < 14)
                    mote.setTransmissionPower(mote.getTransmissionPower() + 1);
            }
            algorithmBuffer = new LinkedList<>();
        }
        return bestTransmission;
    }

    /**
     * A function that moves a mote to a geoposition 1 step and returns if the note
     * has moved.
     * 
     * @param position
     * @param mote
     * @param mapzero
     * @return If the node has moved
     */
    private static Boolean moveMote(GeoPosition position, Mote mote, GeoPosition mapzero) {
        Integer xPos = toMapXCoordinate(position, mapzero);
        Integer yPos = toMapYCoordinate(position, mapzero);
        if (Integer.signum(xPos - mote.getXPos()) != 0 || Integer.signum(yPos - mote.getYPos()) != 0) {
            if (Math.abs(mote.getXPos() - xPos) >= Math.abs(mote.getYPos() - yPos)) {
                mote.setXPos(mote.getXPos() + Integer.signum(xPos - mote.getXPos()));
            } else {
                mote.setYPos(mote.getYPos() + Integer.signum(yPos - mote.getYPos()));
            }
            return true;
        }
        return false;
    }

    private static Integer toMapXCoordinate(GeoPosition geoPosition, GeoPosition mapzero) {
        return (int) Math.round(1000 * IotDomain.Environment.distance(mapzero.getLatitude(), mapzero.getLongitude(),
                mapzero.getLatitude(), geoPosition.getLongitude()));
    }

    private static Integer toMapYCoordinate(GeoPosition geoPosition, GeoPosition mapzero) {
        return (int) Math.round(1000 * IotDomain.Environment.distance(mapzero.getLatitude(), mapzero.getLongitude(),
                geoPosition.getLatitude(), mapzero.getLongitude()));
    }

    public static void main(String[] args) throws InterruptedException {
        new MainSimulation(new SimulationState()).runSimulation(true);
    }
}