#!/bin/bash
# Echo all the useful information from the `service memcached status` command 
#
# Output wil resemble this:
#
#    memcache.pid 17576
#    memcache.uptime 1080764
#    memcache.time 1344234823
#    memcache.pointer_size 64
#    memcache.rusage_user 51.160222
#    memcache.rusage_system 157.221098
#    memcache.curr_items 181059
#    memcache.total_items 1948898
#    memcache.bytes 62620267
#    ...

# memcache gives us some decent stats in the form of 
# STAT bytes_read 4535820
service memcached status 2>/dev/null |
grep STAT |
grep -v version |
sed "s/STAT /memcache\./" 
