#!/bin/bash

# top in batch mode outputs life-time cpu usage on the first iteration, so we
# use -n 2 and grab the last one.
cpu_line=$(top -b -n 2 -i -H | grep ^Cpu | tail -n+2)
hostname=$(hostname)

extract() {
   local name="$1"
   local id="$2"
   echo -n "servers.${hostname//./_}.$name "
   echo "$cpu_line" | sed -r "s/^.* ([0-9.]+)%$id.*$/\1/"
}

extract user us
extract system sy
extract wait wa
extract idle id
extract steal st

