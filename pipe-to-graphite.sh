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

# Defaults can be specified via the existing shell command-line
# or via the graphite.conf. The config file has precedence.
GRAPHITE_SERVER=${GRAPHITE_SERVER:=localhost}
GRAPHITE_PORT=${GRAPHITE_PORT:=2003}
GRAPHITE_INTERVAL=${GRAPHITE_INTERVAL:=10} # in seconds

if [ -f graphite.conf ]; then
   source graphite.conf
fi

# '-' indicates we should read from stdin
if [ "$1" = "-" ]; then
   # Get a timestamp for sending to graphite
   ts=`date +%s`

   # Pipe the output through sed, using a regex to
   # append a $ts timestamp to the end of each line,
   # and then to the correct server and port using netcat
   sed -e '/ [0-9]\+$/!d' -e "s/\$/ $ts/" |
   nc -w 1 $GRAPHITE_SERVER $GRAPHITE_PORT

# Normal usage just passes the command as the only parameter
# This checks if we're on a recursive call.
elif [ "$1" != "report-to-graphite" ]; then
   command="$1"

	 # No point in attempting to run an empty command
	 if [ ! -z "$command" ]; then
		 echo -n "Running '$command' as a test.. " >&2
		 test_output=$($command 2>&1)
		 test_return=$?
		 if [ $test_return -ne 0 ]; then
		     echo "FAILED" >&2
	   fi
	 fi

   if [ -z "$test_output" ] || [ $test_return -ne 0 ]; then
			# Use a bash here document. The <<- allows the preceding tabs
			# to not actually be displayed when the here doc is printed out
      cat <<-EOF >&2
				Usage:
				  $(basename $0) '/command/to/run' >> /var/log/some-stats.log
				Or (for use from cron or other automated invocations):
				  /command/to/run | $(basename $0) -

				/command/to/run must:
				 * echo 'name number' pairs separated by newlines
				 * have an exit code of 0

				Edit ./graphite.conf and export the following shell variables:
				GRAPHITE_SERVER
				GRAPHITE_PORT
				GRAPHITE_INTERVAL
				EOF
      exit 1

   else
      echo "SUCCESS" >&2
      echo
   fi

   script="$0"
   # If we are connected to a terminal redirect stdout to /dev/null
   # so it doesn't end up outputting to our terminal
   if [ -t 1 ] ; then
			cat <<-EOF >&2
				Redirecting stdout to /dev/null so it doesn't mess up your
				terminal.  Redirect it somewhere else if you wan't to save it.
				EOF
      $script 'report-to-graphite' "$command" >/dev/null &
   else
      $script 'report-to-graphite' "$command" &
   fi
   pid=$!
   # Completely disown the most recently launched backgrounded job so it's not
   # in our process-tree. This prevents *wait* and friends from blocking on
   # the background job.
   disown

	 cat <<-EOF >&2
		Command: $command
		is being piped to graphite every $GRAPHITE_INTERVAL seconds
		Background PID: $pid
		EOF

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
         if [ $exit_status -ne 0 ]; then
            err="FAILED: exit code = $exit_status, not reported to graphite"
            output="$err
$output"
         else
            # Pipe the output through sed, using a regex to
            # append a $ts timestamp to the end of each line,
            # and then to the correct server and port using netcat
            echo "$output" |
             sed "s/\$/ $ts/" |
             nc -w 1 $GRAPHITE_SERVER $GRAPHITE_PORT
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
