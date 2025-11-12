import HTTP.*;
import com.sun.net.httpserver.HttpServer;
import models.SimulationState;

import java.io.IOException;
import java.net.InetSocketAddress;

/**
 * The class that implements the HTTP server.
 */
public class HTTPServer {
    /**
     * The default port used for the HTTP server.
     */
    static final private int DEFAULT_PORT = 8080;

    /**
     * Returns the port number of the HTTP server as a string.
     * @return Port number.
     */
    private static int getPort() {
        String portString = System.getenv("PORT");

        return portString != null ? Integer.parseInt(portString) : DEFAULT_PORT;
    }

    /**
     * Creates an HTTP server and returns it.
     * @return HTTPServer.
     */
    private static HttpServer createServer()  {
        try {
            return HttpServer.create(new InetSocketAddress(getPort()), 1024);
        } catch (IOException e) {
            throw new RuntimeException(e.getMessage());
        }
    }

    /**
     * Creates the necessary HTTPContext for all the endpoints in DingNet and starts the HTTP server.
     * @param args contains command line arguments.
     */
    public static void main(String[] args)  {
        HttpServer server = createServer();
        SimulationState simulationState = new SimulationState();

        System.out.println("Server running on port " + getPort());

        server.createContext("/", new BaseHandler());

        server.createContext("/monitor", new MonitorHandler(simulationState));
        server.createContext("/monitor_schema", new MonitorSchemaHandler());

        server.createContext("/execute", new ExecuteHandler(simulationState));
        server.createContext("/execute_schema", new ExecuteSchemaHandler());

        server.createContext("/adaptation_options", new AdaptationOptionsHandler());
        server.createContext("/adaptation_options_schema", new AdaptationOptionsSchemaHandler());

        server.createContext("/start_run", new StartRunHandler(simulationState));
        server.createContext("/stop_run", new StopRunHandler(simulationState));

        server.createContext("/mote_energy_usage", new MoteEnergyUsageHandler(simulationState));

        server.start();
    }
}
