package Simulation;

import IotDomain.Environment;
import IotDomain.Gateway;
import IotDomain.Mote;
import models.*;
import org.jxmapviewer.viewer.GeoPosition;

import java.util.*;

public class ScenarioFactory {

    public static Environment createEnvironment(ScenarioConfig config) {
        String mode = determineMode(config);

        switch (mode) {
            case "personalized":
                return createPersonalizedEnvironment(config);
            case "bulk":
                return createBulkEnvironment(config);
            case "default":
            default:
                return createDefaultEnvironment();
        }
    }

    private static String determineMode(ScenarioConfig cfg) {
        if (cfg.getMode() != null)
            return cfg.getMode();
        if (cfg.getMotes() != null || cfg.getGateways() != null)
            return "personalized";
        if (cfg.getNumMotes() != null || cfg.getNumGateways() != null)
            return "bulk";
        return "default";
    }

    private static Environment createDefaultEnvironment() {
        return MainSimulation.createEnvironment();
    }

    private static Environment createBulkEnvironment(ScenarioConfig config) {
        // Basic bulk implementation
        GeoPosition mapzero = new GeoPosition(50.853718, 4.673155);
        Integer mapsize = 1000;
        if (config.getAreaWidthMeters() != null)
            mapsize = config.getAreaWidthMeters();

        IotDomain.Characteristic[][] map = new IotDomain.Characteristic[mapsize][mapsize];
        for (int i = 0; i < mapsize; i++) {
            for (int j = 0; j < mapsize / 3; j++) {
                map[j][i] = IotDomain.Characteristic.Forest;
            }
            for (int j = mapsize / 3; j < 2 * mapsize / 3; j++) {
                map[j][i] = IotDomain.Characteristic.Plain;
            }
            for (int j = 2 * mapsize / 3; j < mapsize; j++) {
                map[j][i] = IotDomain.Characteristic.City;
            }
        }

        Environment environment = new Environment(map, mapzero, new LinkedHashSet<>());

        Random random = new Random();

        // Create Gateways
        int numGateways = config.getNumGateways() != null ? config.getNumGateways() : 1;
        for (int i = 0; i < numGateways; i++) {
            new Gateway((long) (i + 100), random.nextInt(mapsize), random.nextInt(mapsize), environment, 14, 12);
        }

        // Create Motes
        int numMotes = config.getNumMotes() != null ? config.getNumMotes() : 3;
        for (int i = 0; i < numMotes; i++) {
            int x = random.nextInt(mapsize);
            int y = random.nextInt(mapsize);
            List<GeoPosition> path = new LinkedList<>();
            path.add(toGeoPosition(x, y, mapzero));

            new Mote((long) (i + 1), x, y, environment,
                    config.getDefaultTransmissionPower() != null ? config.getDefaultTransmissionPower() : 14,
                    config.getDefaultSpreadingFactor() != null ? config.getDefaultSpreadingFactor() : 12,
                    new LinkedList<>(), // moteSensors
                    config.getDefaultEnergyLevel() != null ? config.getDefaultEnergyLevel() : 100, // energyLevel
                    new LinkedList<>(path), // path
                    config.getDefaultSamplingRate() != null ? config.getDefaultSamplingRate() : 10,
                    config.getDefaultMovementSpeed() != null ? config.getDefaultMovementSpeed() : 1.0,
                    config.getDefaultStartOffset() != null ? config.getDefaultStartOffset() : 0); // startOffset
        }

        return environment;
    }

    private static Environment createPersonalizedEnvironment(ScenarioConfig config) {
        // 1. Create Map (using default size or config if available)
        // Assuming default map logic for now as it's complex to parameterize map size
        // exactly without more context
        // But we can use the mapzero from MainSimulation
        GeoPosition mapzero = new GeoPosition(50.853718, 4.673155);
        Integer mapsize = 1000; // Default or calculated

        // Logic to create map characteristics...
        // For simplicity, reusing the map creation logic from MainSimulation would be
        // ideal,
        // but we need to extract it or copy it.

        // Let's copy the map creation part from MainSimulation for now
        IotDomain.Characteristic[][] map = new IotDomain.Characteristic[mapsize][mapsize];
        for (int i = 0; i < mapsize; i++) {
            for (int j = 0; j < mapsize / 3; j++) {
                map[j][i] = IotDomain.Characteristic.Forest;
            }
            for (int j = mapsize / 3; j < 2 * mapsize / 3; j++) {
                map[j][i] = IotDomain.Characteristic.Plain;
            }
            for (int j = 2 * mapsize / 3; j < mapsize; j++) {
                map[j][i] = IotDomain.Characteristic.City;
            }
        }

        Environment environment = new Environment(map, mapzero, new LinkedHashSet<>());

        // 2. Create Gateways
        if (config.getGateways() != null) {
            for (GatewayConfig gwCfg : config.getGateways()) {
                new Gateway(gwCfg.getEui(), gwCfg.getXPos(), gwCfg.getYPos(), environment,
                        gwCfg.getTransmissionPower() != null ? gwCfg.getTransmissionPower() : 14,
                        gwCfg.getSpreadingFactor() != null ? gwCfg.getSpreadingFactor() : 12);
            }
        }

        // 3. Create Motes
        if (config.getMotes() != null) {
            for (MoteConfig moteCfg : config.getMotes()) {
                List<GeoPosition> path = generatePath(moteCfg, mapzero);
                int startOffset = moteCfg.getStartOffset() != null ? moteCfg.getStartOffset() : 0;
                int period = moteCfg.getSamplingRate() != null ? moteCfg.getSamplingRate() : 10; // Default 10s

                new Mote(moteCfg.getEui(), moteCfg.getXPos(), moteCfg.getYPos(), environment,
                        moteCfg.getTransmissionPower() != null ? moteCfg.getTransmissionPower() : 14,
                        moteCfg.getSpreadingFactor() != null ? moteCfg.getSpreadingFactor() : 12,
                        new LinkedList<>(), // moteSensors
                        moteCfg.getEnergyLevel() != null ? moteCfg.getEnergyLevel() : 100, // energyLevel
                        new LinkedList<>(path), // path
                        period,
                        moteCfg.getMovementSpeed() != null ? moteCfg.getMovementSpeed() : 1.0,
                        startOffset);
            }
        }

        return environment;
    }

    private static List<GeoPosition> generatePath(MoteConfig cfg, GeoPosition mapzero) {
        List<GeoPosition> path = new LinkedList<>();
        if ("specific_path".equals(cfg.getMovementType()) && cfg.getWaypoints() != null) {
            for (WaypointConfig wp : cfg.getWaypoints()) {
                path.add(toGeoPosition(wp.getX(), wp.getY(), mapzero));
            }
        }
        return path;
    }

    private static GeoPosition toGeoPosition(Integer x, Integer y, GeoPosition mapzero) {
        // 1 km = 1000 units
        // distance in km = units / 1000
        // 1 degree latitude ~= 111 km
        // 1 degree longitude ~= 111 km * cos(latitude)

        double distLat = y / 1000.0; // km
        double distLon = x / 1000.0; // km

        double lat = mapzero.getLatitude() + (distLat / 111.32);
        double lon = mapzero.getLongitude() + (distLon / (111.32 * Math.cos(Math.toRadians(mapzero.getLatitude()))));

        return new GeoPosition(lat, lon);
    }
}
