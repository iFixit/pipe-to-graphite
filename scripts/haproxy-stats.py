#!/usr/bin/env python2
'''
Pull statistics out of HAProxy.

HAProxy must be configured to serve stats over a Unix domain socket.  This is
done using the `stats socket` global config option, e.g.

   stats socket /tmp/haproxy-stats mode 666

Ensure the path matches SOCKET_LOCATION below and the user running
pipe-to-graphite has permissions to read the socket.  In HAProxy 1.4 and above,
it is recommended to use the `mode` option to restrict access to only read-only
operations.

For more information, consult the manual:

   https://cbonte.github.io/haproxy-dconv/configuration-1.4.html#stats

Metrics are reported for every entry in each proxy, as well as the proxy's
aggregate statistics.  Thus, a backend 'app' with two servers, 'app0' and
'app1', will have three different metrics for downtime:

   app.app0.downtime
   app.app1.downtime
   app.BACKEND.downtime

Be aware that multiple servers in the same proxy with the same name are allowed
by HAProxy, but will overwrite each other's stats in this script.

The manual describes the meaning of each metric:

   https://cbonte.github.io/haproxy-dconv/configuration-1.4.html#9.1
'''

import socket
from csv import DictReader
from StringIO import StringIO

SOCKET_LOCATION = '/tmp/haproxy-stats'

s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(SOCKET_LOCATION)
s.sendall("show stat\n")
# The docs recommend a power of two for the buffer size.  Since it's much
# easier to slurp the entire thing at once, this seems large enough to get
# everything in most setups.
data = s.recv(2**13)
s.close()

# We DictReader requires a file object as input.  I couldn't find a better way
# of going from the socket bytestream to a file object than via a string.
data = DictReader(StringIO(data))
for line in data:
   # Pull out the section (proxy name) and name (server/frontend/backend),
   # because we want those appended to every metric (and they aren't metrics
   # themselves).
   section = line['# pxname']
   del(line['# pxname'])
   name = line['svname']
   del(line['svname'])

   for (metric, value) in line.items():
      if metric == '':
         continue

      if metric == 'status':
         if value == 'UP':
            value = 1
         else:
            # Down, no check, maintenance, etc.
            value = 0

      try:
         # All values come in as strings, even if they're ints at heart.
         value = int(value)
      except (TypeError, ValueError):
         # We can't convert None or '' to 0 directly, so convert to booleans
         # first.
         value = int(bool(value))
      print('%s.%s.%s %d' % (section, name, metric, value))

