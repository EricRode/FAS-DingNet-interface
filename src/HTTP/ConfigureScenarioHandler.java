package HTTP;

import Simulation.ScenarioFactory;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import models.ScenarioConfig;
import models.SimulationState;

import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;

public class ConfigureScenarioHandler implements HttpHandler {
    private final SimulationState simulationState;
    private final ObjectMapper objectMapper;

    public ConfigureScenarioHandler(SimulationState simulationState) {
        this.simulationState = simulationState;
        this.objectMapper = new ObjectMapper();
        this.objectMapper.configure(com.fasterxml.jackson.databind.DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES,
                false);
    }

    @Override
    public void handle(HttpExchange exchange) throws IOException {
        if ("POST".equals(exchange.getRequestMethod())) {
            try {
                InputStream requestBody = exchange.getRequestBody();
                ScenarioConfig config = objectMapper.readValue(requestBody, ScenarioConfig.class);
                System.out.println("[ConfigureScenario] Received configuration. Mode: " + config.getMode());
                System.out.println("[ConfigureScenario] numMotes: " + config.getNumMotes());
                System.out.println("[ConfigureScenario] numGateways: " + config.getNumGateways());

                // Create environment based on config
                IotDomain.Environment environment = ScenarioFactory.createEnvironment(config);
                this.simulationState.setEnvironment(environment);

                String response = "Scenario configured successfully.";
                exchange.sendResponseHeaders(HttpURLConnection.HTTP_OK, response.length());
                exchange.getResponseBody().write(response.getBytes());
                exchange.getResponseBody().close();

            } catch (Exception e) {
                e.printStackTrace();
                String response = "Error configuring scenario: " + e.getMessage();
                exchange.sendResponseHeaders(HttpURLConnection.HTTP_BAD_REQUEST, response.length());
                exchange.getResponseBody().write(response.getBytes());
                exchange.getResponseBody().close();
            }
        } else {
            exchange.sendResponseHeaders(HttpURLConnection.HTTP_BAD_METHOD, 0);
            exchange.getResponseBody().close();
        }
    }
}
