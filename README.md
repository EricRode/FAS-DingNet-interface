# DingNet - Fundamentals of Adaptive Software

DingNet exemplar for the 2024 Fundamentals of Adaptive Software course at VU Amsterdam.

### Instructions

To build the docker image:

```shell
docker build -t dingnet .
```

To run the image:

```shell
docker run --name dingnet --rm --shm-size=512m -p 6901:6901 -p 3000:3000 -e VNC_PW=password -e PORT=3000 dingnet
```

The example above exposes the HTTP server on port 3000.
If you need a different port, replace all occurrences of 3000 with a port of your liking.

Note: If no port is specified in the environment variables (-e argument), port 8080 will be used.

### Usage
- Access the HTTP server on port 3000 (or the port you specified).
- After making a request to the `/start_run` endpoint, the simulation will start.
- You can access the GUI of the simulation by opening a web-browser and connecting to `localhost:6901`. The username is 'kasm_user' and the password is 'password'.

### HTTP API
- See [HTTP API Reference](docs/HTTP_API.md) for detailed documentation of the available endpoints, including payload schemas and error responses.
