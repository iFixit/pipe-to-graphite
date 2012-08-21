#!/bin/bash

##
# Use this to send the output of any command or script to graphite at regular
# intervals in the background.
#
# Run this script with no arguments to see proper usage.
#
# Author: Daniel Beardsley: daniel@ifixit.com
# Origin: git@gist.github.com:3271040.git
##

# edit these to match your graphite setup
GRAPHITE_SERVER=localhost
GRAPHITE_PORT=2003
GRAPHITE_INTERVAL=10 # in seconds

# Normal usage just passes the command as the only parameter
# This checks if we're on a recursive call.
if [ "$1" != "report-to-graphite" ]; then
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
   fi

   script="$0"
   # If we are connected to a terminal redirect stdout to /dev/null
   # so nohup doesn't complain and send it to nohup.out
   if [ -t 1 ] ; then
      echo "Redirecting stdout to /dev/null so it doesn't mess up your" >&2
      echo "terminal.  Redirect it somewhere else if you wan't to save it." >&2
      echo >&2
      nohup $script 'report-to-graphite' "$command" >/dev/null &
   else
      nohup $script 'report-to-graphite' "$command" &
   fi
   pid=$!
   (
   echo "Command: $command"
   echo "is being piped to graphite every $GRAPHITE_INTERVAL seconds"
   echo "Background PID: $pid"
   ) >&2

# Internal usage passes the action as the first parameter
# If we get here, we're running from the nohup command above
else
   # first parameter was the action, second is the command
   command="$2"

   # The actual sleep, report, sleep loop
   while true; do
      # Do it in a backgrounded subshell so we can move
      # directly on to sleeping for $GRAPHITE_INTERVAL
      (
         # Get a timestamp for sending to graphite
         ts=`date +%s`

         # Run the provided command and capture stdout
         output=$($command)
         exit_status=$?
         
         # If the command didn't succeed, prepend the output with a failure
         # message and don't send it to graphite.
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
             nc -w 1 -u $GRAPHITE_SERVER $GRAPHITE_PORT
         fi

         # Echo this data too in case we want to record
         # it to a log
         echo "DATE:" `date "+%Y-%m-%d %H:%M:%S"`
         echo "$output"
         echo
      ) &
      sleep $GRAPHITE_INTERVAL
   done;
fi 


