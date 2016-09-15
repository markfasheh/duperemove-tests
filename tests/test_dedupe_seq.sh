#!/bin/bash
#
# This test is designed to ensure that the dedupe sequence tracking
# done in duperemove is working correctly. Dedupe sequence is a global
# counter in our hashfile that gets bumped each time a dedupe pass is
# run. We use it to tell when a file has already been deduped.
#

. `dirname $0`/../config || exit 1
. `dirname $0`/common || exit 1

DEST=$TESTDIR/dedupe_seq
BS=$((128*1024))

#define MAX_DEDUPES_PER_IOCTL	120

rm -f $DEST/*
mkdir -p $DEST

for i in `seq -w 1 15`; do
    _run_dd if=/dev/zero of=$DEST/$i bs=$BS count=1
done

btrfs fi sync $DEST

# dedupe_seq will be zero, filerec seq for 1-5 will be 1
_run_duperemove -v --hashfile=$DEST/test.hash $DEST/01 $DEST/02 $DEST/03 $DEST/04 $DEST/05
# After dedupe, dedupe_seq == 1
_run_duperemove -dv --hashfile=$DEST/test.hash

# add some more files. files 1-5 retain seq 1. New files 6-10 should have seq 2
_run_duperemove -v --hashfile=$DEST/test.hash $DEST/06 $DEST/07 $DEST/08 $DEST/09 $DEST/10
# dedupe_seq == 2 after this
_run_duperemove -dv --hashfile=$DEST/test.hash

#exit 0
filefrag -e $DEST/11

# force rescan of 1 and 2, this should set their seq to 3
# files 11-15 will also have seq == 3
touch $DEST/01 $DEST/02
_run_duperemove -v --hashfile=$DEST/test.hash $DEST/11 $DEST/12 $DEST/13 $DEST/14 $DEST/15
# dedupe_seq == 3 after this
_run_duperemove -dv --debug --hashfile=$DEST/test.hash

filefrag -e $DEST/11
