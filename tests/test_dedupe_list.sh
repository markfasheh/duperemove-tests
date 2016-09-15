#!/bin/bash

. `dirname $0`/../config || exit 1
. `dirname $0`/common || exit 1

# These tests are designed to stress the code in dedupe_extent_list()
# and make it crash due to leaked contexts/fds.

DEST=$TESTDIR/
BS=$((128*1024))

#define MAX_DEDUPES_PER_IOCTL	120

rm -fr $DEST/exactly/
mkdir -p $DEST/exactly
for i in `seq -w 1 120`; do
    _run_dd if=/dev/zero of=$DEST/exactly/exactly_$i bs=$BS count=1
done

rm -fr $DEST/oneover/
mkdir -p $DEST/oneover/
for i in `seq -w 1 121`; do
    _run_dd if=/dev/zero of=$DEST/oneover/over_$i bs=$BS count=1
done

rm -fr $DEST/justunder
mkdir -p $DEST/justunder/
for i in `seq -w 1 119`; do
    _run_dd if=/dev/zero of=$DEST/justunder/under_$i bs=$BS count=1
done

rm -fr $DEST/manyloops/
mkdir -p $DEST/manyloops/
for i in `seq -w 1 360`; do
    _run_dd if=/dev/zero of=$DEST/manyloops/loop_$i bs=$BS count=1
done

btrfs fi sy $DEST

_run_duperemove -vrd $DEST/exactly/
_run_duperemove -vrd $DEST/oneover/
_run_duperemove -vrd $DEST/justunder/
_run_duperemove -vrd $DEST/manyloops/

#test for issue#132, issue#134
#Do the same thing twice, but switching which file is 'bad' so we
#catch every path through dedupe_extent_list().
rm -f $DEST/1 $DEST/2
_run_dd if=/dev/zero of=$DEST/1 bs=$BS count=1
_run_dd if=/dev/zero of=$DEST/2 bs=$BS count=1
chown $TMPUSER $DEST/2
sudo -u $TMPUSER $DUPEREMOVE -vd $DEST/1 $DEST/2
if [ $? -ne 0 ]; then
    test_failure $?
fi

rm -f $DEST/1 $DEST/2
_run_dd if=/dev/zero of=$DEST/1 bs=$BS count=1
_run_dd if=/dev/zero of=$DEST/2 bs=$BS count=1
chown $TMPUSER $DEST/1
sudo -u $TMPUSER $DUPEREMOVE -vd $DEST/1 $DEST/2
if [ $? -ne 0 ]; then
    test_failure $?
fi
