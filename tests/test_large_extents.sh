#!/bin/bash
#
# Regression test for issue issue#275
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
FILSIZE=$((5*1024*1024*1024))
BC=$(($FILSIZE/$BS))

_run_dd if=/dev/zero of=$FILE count=$BC bs=$BS

# This should terminate
_run_duperemove --hashfile=$DB $FILE

extent_size=$($SQLITEBIN $DB "select len from extents")

[ $extent_size -eq $FILSIZE ] || echo "ERROR: Expected positive extent len: $FILSIZE  actual: $extent_size"; exit 1;

exit 0
