package models;

import com.fasterxml.jackson.annotation.JsonProperty;

public class StatusModel {
    @JsonProperty("isRunning")
    private boolean isRunning;
    private Integer currentRun;
    private Integer moteCount;
    private Integer gatewayCount;
    private Long uptimeMs;

    public StatusModel(boolean isRunning, Integer currentRun, Integer moteCount, Integer gatewayCount, Long uptimeMs) {
        this.isRunning = isRunning;
        this.currentRun = currentRun;
        this.moteCount = moteCount;
        this.gatewayCount = gatewayCount;
        this.uptimeMs = uptimeMs;
    }

    public boolean isRunning() {
        return isRunning;
    }

    public Integer getCurrentRun() {
        return currentRun;
    }

    public Integer getMoteCount() {
        return moteCount;
    }

    public Integer getGatewayCount() {
        return gatewayCount;
    }

    public Long getUptimeMs() {
        return uptimeMs;
    }
}
