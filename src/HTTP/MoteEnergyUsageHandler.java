package HTTP;

import IotDomain.Environment;
import IotDomain.Mote;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import models.MoteEnergyUsageModel;
import models.SimulationState;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Handler that exposes the transmission energy usage history of a mote.
 */
public class MoteEnergyUsageHandler implements HttpHandler {

    private static final HTTPResponse INVALID_REQUEST = new HTTPResponse(
            HttpURLConnection.HTTP_BAD_REQUEST,
            "Invalid request.\n"
    );

    private static final HTTPResponse MOTE_NOT_FOUND = new HTTPResponse(
            HttpURLConnection.HTTP_NOT_FOUND,
            "Mote not found.\n"
    );

    private static final HTTPResponse ENVIRONMENT_UNAVAILABLE = new HTTPResponse(
            HttpURLConnection.HTTP_CONFLICT,
            "Simulation environment not initialised.\n"
    );

    private static final HTTPResponse METHOD_NOT_ALLOWED = new HTTPResponse(
            HttpURLConnection.HTTP_BAD_METHOD,
            "Method not allowed.\n"
    );

    private final SimulationState simulationState;
    private final ObjectMapper objectMapper;

    public MoteEnergyUsageHandler(SimulationState simulationState) {
        this.simulationState = simulationState;
        this.objectMapper = new ObjectMapper();
    }

    @Override
    public void handle(HttpExchange exchange) throws IOException {
        if (!"GET".equalsIgnoreCase(exchange.getRequestMethod())) {
            exchange.getResponseHeaders().add("Allow", "GET");
            METHOD_NOT_ALLOWED.send(exchange);
            return;
        }

        Environment environment = this.simulationState.getEnvironment();
        if (environment == null) {
            ENVIRONMENT_UNAVAILABLE.send(exchange);
            return;
        }

        Map<String, String> queryParameters = parseQueryParameters(exchange.getRequestURI());

        String euiParameter = queryParameters.get("eui");
        String idParameter = queryParameters.get("id");
        String runParameter = queryParameters.get("run");

        if ((euiParameter == null && idParameter == null) || (euiParameter != null && idParameter != null)) {
            INVALID_REQUEST.send(exchange);
            return;
        }

        Mote mote;
        if (idParameter != null) {
            Integer moteIndex = parseInteger(idParameter);
            if (moteIndex == null) {
                INVALID_REQUEST.send(exchange);
                return;
            }

            List<Mote> motes = environment.getMotes();
            if (moteIndex < 0 || moteIndex >= motes.size()) {
                MOTE_NOT_FOUND.send(exchange);
                return;
            }
            mote = motes.get(moteIndex);
        } else {
            Long moteEui = parseLong(euiParameter);
            if (moteEui == null) {
                INVALID_REQUEST.send(exchange);
                return;
            }

            mote = findMoteByEui(environment.getMotes(), moteEui).orElse(null);
            if (mote == null) {
                MOTE_NOT_FOUND.send(exchange);
                return;
            }
        }

        int numberOfRuns = environment.getNumberOfRuns();
        int runIndex = Math.max(0, numberOfRuns - 1);
        if (runParameter != null) {
            Integer parsedRun = parseInteger(runParameter);
            if (parsedRun == null || parsedRun < 0 || parsedRun >= numberOfRuns) {
                INVALID_REQUEST.send(exchange);
                return;
            }
            runIndex = parsedRun;
        }

        LinkedList<Double> usedEnergy = mote.getUsedEnergy(runIndex);
        double totalEnergy = usedEnergy.stream().mapToDouble(Double::doubleValue).sum();

        MoteEnergyUsageModel model = MoteEnergyUsageModel.builder()
                .EUI(mote.getEUI())
                .run(runIndex)
                .transmissionEnergy(new LinkedList<>(usedEnergy))
                .totalEnergy(totalEnergy)
                .build();

        String responseBody = this.objectMapper.writeValueAsString(model);

        exchange.getResponseHeaders().add("Content-Type", "application/json");
        new HTTPResponse(HttpURLConnection.HTTP_OK, responseBody).send(exchange);
    }

    private Map<String, String> parseQueryParameters(URI uri) {
        Map<String, String> parameters = new HashMap<>();
        if (uri == null) {
            return parameters;
        }

        String query = uri.getQuery();
        if (query == null || query.isEmpty()) {
            return parameters;
        }

        String[] pairs = query.split("&");
        for (String pair : pairs) {
            if (pair.isEmpty()) {
                continue;
            }

            int equalsIndex = pair.indexOf('=');
            String key;
            String value;
            if (equalsIndex >= 0) {
                key = URLDecoder.decode(pair.substring(0, equalsIndex), StandardCharsets.UTF_8);
                value = URLDecoder.decode(pair.substring(equalsIndex + 1), StandardCharsets.UTF_8);
            } else {
                key = URLDecoder.decode(pair, StandardCharsets.UTF_8);
                value = "";
            }
            parameters.put(key, value);
        }
        return parameters;
    }

    private Integer parseInteger(String value) {
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private Long parseLong(String value) {
        try {
            return Long.parseLong(value);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private Optional<Mote> findMoteByEui(List<Mote> motes, Long eui) {
        return motes.stream()
                .filter(mote -> mote.getEUI().equals(eui))
                .findFirst();
    }
}
