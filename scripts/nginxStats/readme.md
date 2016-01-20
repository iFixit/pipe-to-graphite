# NGINX Stats Collector

Requests 127.0.0.1/nginx_status, parses the output, and pipes the following metrics to graphite:

The current number of active client connections including Waiting connections.

The current number of active (accepted) connections from clients, which includes all connections with the status Idle / Waiting, Reading, and Writing.

servers.$HOSTNAME.nginx.currentActiveConn $ACTIVE_CONNECTIONS


servers.$HOSTNAME.nginx.currentConnReading $READING_CONNECTIONS
servers.$HOSTNAME.nginx.currentConnWriting $WRITING_CONNECTIONS
servers.$HOSTNAME.nginx.currentConnWaiting $WAITING_CONNECTIONS


servers.$HOSTNAME.nginx.acceptedConnPerMin $ACCEPTS_PER_MIN
servers.$HOSTNAME.nginx.requestsPerMin $REQUESTS_PER_MIN
servers.$HOSTNAME.nginx.droppedConnPerMin $DROPPED_PER_MIN

servers.$HOSTNAME.nginx.acceptedConnPerSec $ACCEPTS_PER_SECOND
servers.$HOSTNAME.nginx.requestsPerSec $REQUESTS_PER_SECOND
servers.$HOSTNAME.nginx.droppedConnPerSec $DROPPED_PER_SECOND
