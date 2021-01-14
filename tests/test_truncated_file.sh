#!/bin/bash
#
# Regression test for issue issue#255
#

trap "_cleanup" EXIT

_cleanup()
{
	rm -f $DB
	rm -f $FILE
}
. `dirname $0`/../config || exit 1
. `dirname $0`/common || exit 1

DB=./test.db
FILE=$TESTDIR/file1
BS=$((4*1024*1024))

_run_dd if=/dev/zero of=$FILE count=1 bs=$BS

# truncate the file
truncate -s $((2*$BS)) $FILE

# This should terminate
_run_duperemove --write-hashes-v2=$DB $FILE

num_hashes=$($SQLITEBIN $DB "select count(*) from hashes")

[ $num_hashes -eq 32 ] || echo "ERROR: Expected number of hashes: 32 actual: $num_hashes"; exit 1;

exit 0
