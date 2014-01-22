#!/bin/bash

cpu_line=$(top -b -n 1 | grep ^Cpu)
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
extract steal st

