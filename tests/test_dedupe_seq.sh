#!/bin/bash -x

. `dirname $0`/config || exit 1

DEST=/btrfs/dedupe_seq
BS=$((128*1024))

#define MAX_DEDUPES_PER_IOCTL	120

rm -f $DEST/*
mkdir -p $DEST

for i in `seq -w 1 15`; do
    dd if=/dev/zero of=$DEST/$i bs=$BS count=1
done

btrfs fi sync $DEST

# dedupe_seq will be zero, filerec seq for 1-5 will be 1
$DUPEREMOVE -v --hashfile=$DEST/test.hash $DEST/01 $DEST/02 $DEST/03 $DEST/04 $DEST/05
# After dedupe, dedupe_seq == 1
$DUPEREMOVE -dv --hashfile=$DEST/test.hash

# add some more files. files 1-5 retain seq 1. New files 6-10 should have seq 2
$DUPEREMOVE -v --hashfile=$DEST/test.hash $DEST/06 $DEST/07 $DEST/08 $DEST/09 $DEST/10
# dedupe_seq == 2 after this
$DUPEREMOVE -dv --hashfile=$DEST/test.hash

#exit 0
filefrag -e $DEST/11

# force rescan of 1 and 2, this should set their seq to 3
# files 11-15 will also have seq == 3
touch $DEST/01 $DEST/02
$DUPEREMOVE -v --hashfile=$DEST/test.hash $DEST/11 $DEST/12 $DEST/13 $DEST/14 $DEST/15
# dedupe_seq == 3 after this
$DUPEREMOVE -dv --debug --hashfile=$DEST/test.hash

filefrag -e $DEST/11
