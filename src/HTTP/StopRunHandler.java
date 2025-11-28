package HTTP;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import models.SimulationState;

import java.io.IOException;
import java.io.OutputStream;
import java.net.HttpURLConnection;

/**
 * This class implements the handler for starting a run in DingNet.
 * 
 * @version 1.0
 */
public class StopRunHandler implements HttpHandler {
    /**
     * The simulation state containing information regarding the simulation.
     * 
     * @since 1.0
     */
    private final SimulationState simulationState;

    /**
     * An HTTP Response message {@code ALREADY_RUNNING} for when DingNet is already
     * running.
     */
    static private final HTTPResponse NOT_RUNNING = new HTTPResponse(
            HttpURLConnection.HTTP_CONFLICT,
            "Simulation is not running.\n");

    /**
     * An HTTP Response message {@code SIMULATION_STARTED} for when DingNet has
     * successfully started.
     */
    static private final HTTPResponse SIMULATION_STOPPED = new HTTPResponse(
            HttpURLConnection.HTTP_OK,
            "Simulation stopped.\n");

    /**
     * Constructs an {@code StartRunHandler} object with the simulation state
     * {@code simulationState}.
     * 
     * @param simulationState The state of the simulation to be started.
     * @since 1.0
     */
    public StopRunHandler(SimulationState simulationState) {
        this.simulationState = simulationState;
    }

    /**
     * Starts the simulation of DingNet (if it wasn't running already).
     * The function also resets the SimulationState.
     * 
     * @param exchange the exchange containing the request from the
     *                 client and used to send the response
     * @exception IOException can occur in
     *                        {@link HttpExchange#sendResponseHeaders(int, long),
     *                        {@link OutputStream#write(int)},
     *                        {@link OutputStream#flush()} and
     *                        {@link OutputStream#close()}
     */
    @Override
    public void handle(HttpExchange exchange) throws IOException {
        boolean isRunning = this.simulationState.getIsRunning();
        HTTPResponse response = isRunning ? SIMULATION_STOPPED : NOT_RUNNING;

        if (isRunning) {
            System.out.println("[StopRun] Setting shouldStop=true");
            this.simulationState.setShouldStop(true);
        }

        response.send(exchange);
    }
}
