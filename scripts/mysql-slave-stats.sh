#!/bin/sh


# Produce a huge number of stats about mysql
mysql -u root -e "show slave status \G" |
# Skip the first line (column headers "Variable_name Value")
tail -n +2 |
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

