#!/bin/sh

SRC=`hostname`
PREFIX="${PREFIX:-ping}.${SRC/./_}.${DEST/./_}"
# Set the DEST variable to the destination address
output=`ping -q -c 10 -i 0.5 $DEST | tail -2`
percent_loss=`echo $output | grep -oP "[0-9]+%"`
avg_time=`echo $output | grep -oP "/[.0-9]+/"`
echo "$PREFIX.percent_loss ${percent_loss%\%}"
echo "$PREFIX.time ${avg_time//\/}"

