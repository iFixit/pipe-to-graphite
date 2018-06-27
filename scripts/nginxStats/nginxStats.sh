#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOSTNAME=$( hostname | cut -d"." -f 1 )

STATS=$( curl -s http://127.0.0.1/nginx_status )

# The current number of active client connections including Waiting connections.
# The current number of active (accepted) connections from clients, which includes all connections with the status Idle / Waiting, Reading, and Writing.
ACTIVE_CONNECTIONS=$( echo $STATS | cut -d" " -f 3 )

# The current number of (accepted) connections from clients where nginx is reading the request (at the time the status module was queried.)
READING_CONNECTIONS=$( echo $STATS | cut -d" " -f 12 )

# The current number of connections from clients where nginx is writing a response back to the client.
WRITING_CONNECTIONS=$( echo $STATS | cut -d" " -f 14 )

# The current number of connections from clients that are in the Idle / Waiting state (waiting for a request.)
WAITING_CONNECTIONS=$( echo $STATS | cut -d" " -f 16 )

# The total number of accepted client connections since server start
# The total number of accepted connections from clients since the nginx master process started. 
# Note that reloading configuration or restarting worker processes does not reset this metric, but terminating and restarting the master process does.
ACCEPTS=$( echo $STATS | cut -d" " -f 8 )

# The total number of handled connections from clients since the nginx master process started. 
# This will be lower than accepts only in cases where a connection is dropped before it is handled.
HANDLED=$( echo $STATS | cut -d" " -f 9 )

# The total number of requests from clients since the nginx master process started. A request is an application-level (HTTP, SPDY, etc.) 
# event and is defined as a client requesting a resource via the application protocol. A single connection can (and often does) 
# make multiple requests, so this number will generally be larger than the number of accepted/handled connections.
REQUESTS=$( echo $STATS | cut -d" " -f 10 )


# The total number of requests that were dropped before they could be handled. Dropped requests are generally due to resource limits being reached (For example the worker connections limit).
DROPPED=$(( $ACCEPTS - $HANDLED ))

# Create the files that keep track of the totals that we have already recorded stats for. If any one of them is missing. lets go ahead and reset them all.
if [ ! -f "$CURRENT_DIR/acceptsAccountedFor.tmp" -o ! -f "$CURRENT_DIR/handledAccountedFor.tmp" -o ! -f "$CURRENT_DIR/requestsAccountedFor.tmp" -o ! -f "$CURRENT_DIR/droppedAccountedFor.tmp" ]
        then
        echo $ACCEPTS > $CURRENT_DIR/acceptsAccountedFor.tmp
        echo $HANDLED > $CURRENT_DIR/handledAccountedFor.tmp
        echo $REQUESTS > $CURRENT_DIR/requestsAccountedFor.tmp
        echo $DROPPED > $CURRENT_DIR/droppedAccountedFor.tmp
	
	#To avoid sending an incorect value of 0 to graphite for these stats, we're going to exit out of this iteration and continue sending correct metrics on the next when the tmp files exist.
	exit
fi

#Grab the values from the tmp files before we overwrite them with the new values. 
ACCEPTS_ACCOUNTED_FOR=$( cat $CURRENT_DIR/acceptsAccountedFor.tmp )
HANDLED_ACCOUNTED_FOR=$( cat $CURRENT_DIR/handledAccountedFor.tmp )
REQUESTS_ACCOUNTED_FOR=$( cat $CURRENT_DIR/requestsAccountedFor.tmp )
DROPPED_ACCOUNTED_FOR=$( cat $CURRENT_DIR/droppedAccountedFor.tmp )

#Update the tmp files with the new values
echo $ACCEPTS > $CURRENT_DIR/acceptsAccountedFor.tmp
echo $HANDLED > $CURRENT_DIR/handledAccountedFor.tmp
echo $REQUESTS > $CURRENT_DIR/requestsAccountedFor.tmp
echo $DROPPED > $CURRENT_DIR/droppedAccountedFor.tmp

ACCEPTS_PER_MIN=$(( $ACCEPTS - $ACCEPTS_ACCOUNTED_FOR ))
REQUESTS_PER_MIN=$(( $REQUESTS - $REQUESTS_ACCOUNTED_FOR ))
DROPPED_PER_MIN=$(( $DROPPED - $DROPPED_ACCOUNTED_FOR ))

ACCEPTS_PER_SECOND=$(( $ACCEPTS_PER_MIN / 60 ))
REQUESTS_PER_SECOND=$(( $REQUESTS_PER_MIN / 60 ))
DROPPED_PER_SECOND=$(( $DROPPED_PER_MIN / 60 ))


echo "servers.$HOSTNAME.nginx.currentActiveConn $ACTIVE_CONNECTIONS"
echo "servers.$HOSTNAME.nginx.currentConnReading $READING_CONNECTIONS"
echo "servers.$HOSTNAME.nginx.currentConnWriting $WRITING_CONNECTIONS"
echo "servers.$HOSTNAME.nginx.currentConnWaiting $WAITING_CONNECTIONS"


echo "servers.$HOSTNAME.nginx.acceptedConnPerMin $ACCEPTS_PER_MIN"
echo "servers.$HOSTNAME.nginx.requestsPerMin $REQUESTS_PER_MIN"
echo "servers.$HOSTNAME.nginx.droppedConnPerMin $DROPPED_PER_MIN"

echo "servers.$HOSTNAME.nginx.acceptedConnPerSec $ACCEPTS_PER_SECOND"
echo "servers.$HOSTNAME.nginx.requestsPerSec $REQUESTS_PER_SECOND"
echo "servers.$HOSTNAME.nginx.droppedConnPerSec $DROPPED_PER_SECOND"
