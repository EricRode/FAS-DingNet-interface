package HTTP;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import models.SimulationState;
import models.StatusModel;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.io.OutputStream;

public class StatusHandler implements HttpHandler {

    private SimulationState simulationState;
    private ObjectMapper objectMapper;
    private long startTime;

    public StatusHandler(SimulationState simulationState) {
        this.simulationState = simulationState;
        this.objectMapper = new ObjectMapper();
        this.startTime = System.currentTimeMillis();
    }

    @Override
    public void handle(HttpExchange exchange) throws IOException {
        if ("GET".equals(exchange.getRequestMethod())) {
            boolean isRunning = simulationState.getIsRunning();
            Integer currentRun = 0;
            Integer moteCount = 0;
            Integer gatewayCount = 0;

            if (simulationState.getEnvironment() != null) {
                currentRun = simulationState.getEnvironment().getNumberOfRuns();
                moteCount = simulationState.getEnvironment().getMotes().size();
                gatewayCount = simulationState.getEnvironment().getGateways().size();
            }

            StatusModel status = new StatusModel(
                    isRunning,
                    currentRun,
                    moteCount,
                    gatewayCount,
                    System.currentTimeMillis() - startTime);

            String response = objectMapper.writeValueAsString(status);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length());
            OutputStream os = exchange.getResponseBody();
            os.write(response.getBytes());
            os.close();
        } else {
            exchange.sendResponseHeaders(405, -1); // Method Not Allowed
        }
    }
}
