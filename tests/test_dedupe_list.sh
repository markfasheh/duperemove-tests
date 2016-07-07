#!/bin/bash

DEST=/btrfs/
DUPEREMOVE=/build/mfasheh/duperemove.git/duperemove

BS=$((128*1024))

#define MAX_DEDUPES_PER_IOCTL	120

rm -fr $DEST/justunder
mkdir -p $DEST/justunder/
for i in `seq -w 0 118`; do
    dd if=/dev/zero of=$DEST/justunder/under_$i bs=$BS count=2
done

rm -fr $DEST/oneover/
mkdir -p $DEST/oneover/
for i in `seq -w 0 120`; do
    dd if=/dev/zero of=$DEST/oneover/over_$i bs=$BS count=2
done

rm -fr $DEST/manyloops/
mkdir -p $DEST/manyloops/
for i in `seq -w 0 240`; do
    dd if=/dev/zero of=$DEST/manyloops/loop_$i bs=$BS count=2
done

btrfs fi sy $DEST

$DUPEREMOVE -rdh $DEST/justunder/

$DUPEREMOVE -rdh $DEST/oneover/

$DUPEREMOVE -rdh $DEST/manyloops/
