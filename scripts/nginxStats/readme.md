# NGINX Stats Collector

This collector makes a curl request to 127.0.0.1/nginx_status, parses the output, and echoes out the metrics shown below.

This script is meant to run every 60 seconds. Running at any other interval is of course possible, but you'll need to customize the script for the output to make sense.

NOTE: You have to add the following config to nginx under a ```server``` directive before you can consume information from 127.0.0.1/nginx_status:

```
    location /nginx_status {
                    stub_status on;
                    access_log   off;
                    allow all;
            }
```

####Metrics Echoed to Graphite:

```servers.$HOSTNAME.nginx.currentActiveConn $ACTIVE_CONNECTIONS```

The current number of active (accepted) connections from clients, which includes all connections with the status Idle / Waiting, Reading, and Writing.

```servers.$HOSTNAME.nginx.currentConnReading $READING_CONNECTIONS```

The current number of (accepted) connections from clients where nginx is reading the request (at the time the status module was queried.)


```servers.$HOSTNAME.nginx.currentConnWriting $WRITING_CONNECTIONS```

The current number of connections from clients where nginx is writing a response back to the client.

```servers.$HOSTNAME.nginx.currentConnWaiting $WAITING_CONNECTIONS```

The current number of connections from clients that are in the Idle / Waiting state (waiting for a request.)


```servers.$HOSTNAME.nginx.acceptedConnPerMin $ACCEPTS_PER_MIN```

The number of connections received in the last minute.

```servers.$HOSTNAME.nginx.requestsPerMin $REQUESTS_PER_MIN```

The number of requests from clients received in the last minute. A request is an application-level (HTTP, SPDY, etc.) event and is defined as a client requesting a resource via the application protocol. A single connection can (and often does) make multiple requests, so this number will generally be larger than the number of accepted/handled connections.

```servers.$HOSTNAME.nginx.droppedConnPerMin $DROPPED_PER_MIN```

The number of dropped connections in the past minute. This number is derived from subtracting the handled connections from the accepted connections. NOTE: I have not included the handled connections in the output of this script because it will always be the same as accepted connections unless there are dropped connections. That means that as long as you are paying attention to dropped connections and accepted connections, Handled connections are redundant information.

The below metrics are the same metrics as above, just divided by 60. This will output 0 if you have less than 60 requests per minute, so they'll be pretty useless unless you have a higher volume of traffic.

```servers.$HOSTNAME.nginx.acceptedConnPerSec $ACCEPTS_PER_SECOND```

```servers.$HOSTNAME.nginx.requestsPerSec $REQUESTS_PER_SECOND```

```servers.$HOSTNAME.nginx.droppedConnPerSec $DROPPED_PER_SECOND```
