#!/bin/sh


if [ "$1" == "--include-zeros" ]; then
   # print all lines
   awk_command='{ print }'
else
   # Remove all the lines where the value is 0
   # (~50% of the 360 values were 0 when I checked)
   awk_command='{if ($2) print}'
fi

# Produce a huge number of stats about mysql
mysql -u root -e "show global status" |
# Skip the first line (column headers "Variable_name Value")
tail -n +2 |
# command from above
awk "$awk_command" |
# lower-case everything because Capitals_with_underscores_are_annoying
tr '[A-Z]' '[a-z]' |
# Prepend 'mysql.' and turn a few instances of 'name_' into 'name.' mainly
# so they are grouped in the Graphite UI
sed -e "s/^/mysql./" -re "s/^(com|handler|innodb|key|qcache|select|sort|threads)_/\1./"

