#!/bin/bash
host=`hostname | sed "s/\./_/g"`

varnishstat -1 |
awk "{ print \"varnish.$host.\"\$1, \$2 }" |
grep -E -v "(\..*){3}"
