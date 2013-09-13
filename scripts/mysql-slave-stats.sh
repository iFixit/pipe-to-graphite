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
mysql -u root -e "show slave status \G" |
# Skip the first line (column headers "Variable_name Value")
tail -n +2 |
# command from above
awk "$awk_command" |
# lower-case everything because Capitals_with_underscores_are_annoying
tr '[A-Z]' '[a-z]' |
# 1.  Remove leading spaces (from ragged-left edge) and prepend namespace.
# 2.  Remove \G-created colons.
# 3-4 Alter 'yes' and 'no' to integers so we can record them.
# 5.  Filter out entries with non-numeric values.
sed -re "s/^\s*/mysql./" \
     -e 's/://' \
     -e 's/ yes$/ 1/' \
     -e 's/ no$/ 0/' \
     -e "/\S+\s+[0-9.-]+/!d"

