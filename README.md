## pipe-to-graphite
Makes it easy to monitor and report just about anything to Graphite
from the commandline.

### Why
Created initially to report the useful numbers from `service memcached status`
to Graphite.  More examples are added as needed.

### How
Write a script that outputs some `name value` pairs tha your care about.
`pipe-to-graphite` will take care of formatting them and sending them
to graphite at regular intervals. The expected output is something like this:

```
some.thing.count 53453
SomeOtherThing 3522
```

_NOTE: Your script must finish with an exit code of 0 or the output won't be
sent to graphite (though it will be logged along with a failure message)._

### Example
Lets say you want to monitor the `glorkd` program. Let's say glorkd comes with
a script `/usr/glork/status` that spits out something like this:

```
Glorkd - v2.1.352
Running: pid 3242
Blargs: 1230
Blorks: 452
```

You only care about the Blargs and Blorks (those are counts since
program start).  All you have to do is write a script that does some grepping
and awking to get that into this:

```
Blargs 1230
Blorks 452
```

Your script (lets say `~/glork-stats.sh`) would look something like this:

```bash
/usr/glork/status | tail -n +3 | sed "s/: / /"
```

To get that regularly reported to Graphite, run this command

```bash
./pipe-to-graphite.sh ~/glork-stats.sh >> /var/log/glork-stats.log
```

Or to report it to graphite at any time, if you want to use cron or something.
The '-' argument indicates input should be read form stdin

```bash
~/glork-stats.sh | ./pipe-to-graphite.sh -
```

### Logging
Output from each run is prepended with a timestamp and echoed to stdout
Redirect that wherever you like.
