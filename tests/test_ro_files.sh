#!/bin/bash
#
# See issue#129, this should work but doesn't right now.
#

. `dirname $0`/../config || exit 1
. `dirname $0`/common || exit 1

DEST=$TESTDIR/ro_files
BS=$((128*1024))

rm -fr $DEST
mkdir -p $DEST

FILE1=$DEST/file1
FILE2=$DEST/file2

_run_dd if=/dev/zero of=$FILE1 count=1 bs=$BS
# make a non-COW copy
cat $FILE1 > $FILE2
chmod 400 $FILE1 # make files readonly
chmod 400 $FILE2

chown $TMPUSER $FILE1 $FILE2
# can't use the helper here
sudo -u $TMPUSER $DUPEREMOVE -dA $FILE1 $FILE2 &> $DEST/log
if [ $? -ne 0 ]; then
    echo "TEST FAILURE: $RET"
    exit 1;
fi

grep -q "Invalid argument" $DEST/log
if [ $? -eq 0 ]; then
    test_failure 22
fi

exit 0
