FROM egalberts/dingnet:latest
WORKDIR /usr/app
COPY ./DingNet.jar .
ENTRYPOINT  (sleep 10 && ( nohup java -jar DingNet.jar > out.txt & )) & exec /dockerstartup/vnc_startup.sh /dockerstartup/kasm_startup.sh