#!/bin/bash

GRAPHITE_SERVER=localhost
GRAPHITE_PORT=2003
GRAPHITE_INTERVAL=10

action="$1"

if [ "$action" == "report-to-graphite" ]; then
   command="$2"

   while true; do
      # Do it in a backgrounded subshell so we can move
      # directly on to sleeping for $GRAPHITE_INTERVAL
      (
         # Get a timestamp for sending to graphite
         ts=`date +%s`

         output=$($command)
         exit_status=$?
         
         if [ "$exit_status" != "0" ]; then
            err="FAILED: exit code = $exit_status, not reported to graphite"
            output="$err
$output"
         else
            # Pipe the output through sed, using a regex to
            # append a $ts timestamp to the end of each line,
            # and then to the correct server and port using netcat
            echo "$output" |
             sed "s/\$/ $ts/" |
             nc $GRAPHITE_SERVER $GRAPHITE_PORT
         fi

         # Echo this data too in case we want to record
         # it to a log
         echo "DATE:" `date "+%Y-%m-%d %H:%M:%S"`
         echo "$output"
         echo
      ) &
      sleep $GRAPHITE_INTERVAL
   done;
   exit 0
fi 

command="$1"

echo -n "Running '$command' as a test.. " >&2
test_output=$($command 2>&1)
test_return=$?

if [ "$test_output" == "" ] || [ "$test_return" != "0" ]; then
   (
   echo "FAILED"
   echo
   echo "Usage:"
   script="`basename $0`"
   echo "  $script '/command/to/run' >> /var/log/some-stats.log "
   echo 
   echo "/command/to/run must:"
   echo " * echo 'name number' pairs separated by newlines"
   echo " * have an exit code of 0"
   ) >&2
   exit 1

else
   echo "SUCCESS" >&2
   echo
   script="$0"
   # If we are connected to a terminal redirect stdout to /dev/null
   # so nohup doesn't send it to nohup.out
   if [ -t 1 ] ; then
      echo "Redirecting stdout to /dev/null so it doesn't mess up your" >&2
      echo "terminal.  Direct it somewhere else if you wan't to save it." >&2
      echo >&2
      nohup $script 'report-to-graphite' "$command" >/dev/null &
   else
      nohup $script 'report-to-graphite' "$command" &
   fi
   pid=$!
   (
   echo "Started piping output of '$command' to graphite"
   echo "Background PID: $pid"
   ) >&2
   exit 0
fi

