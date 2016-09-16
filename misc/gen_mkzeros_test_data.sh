#!/bin/bash
#
# Generate a sizable amount of test data using mkzeros.
#
# There are a couple 'profiles' below for different tests
#

# By default, make 500MB of data in 10 files.
SIZE=$((50*1024*1024))
FILECOUNT=10
NUMCOPIES=0

# A larger test, 200G of data in 25 files. This is better than above
# for performance timing.
#SIZE=$((8*1024*1024*1024))
#FILECOUNT=25
#NUMCOPIES=0

# 1TB of data for a generic 'torture' test of the find_dupes code.
#SIZE=$((8*1024*1024))
#FILECOUNT=131072
#NUMCOPIES=0

# Master branch before "0c2e801: Improve coverage of dedupe results"
# used to have problems with this, giving less than half dedupe
# coverage on each file. This script can be used to generate files
# which create the right situtaions which we were having problems with
# before.
#
# We make a set of FILECOUNT large (8G) files then copy them
# NUMCOPIES times each
#SIZE=$((8*1024*1024*1024))
#FILECOUNT=18
#NUMCOPIES=5
#
#200 gig version of above, runs in less than half the time
#SIZE=$((8*1024*1024*1024))
#FILECOUNT=5
#NUMCOPIES=5
#
# This is fast and enough to expose the problem for rapid testing
#SIZE=$((10*1024*1024))
#FILECOUNT=10
#NUMCOPIES=5


. `dirname $0`/../config || exit 1

make_files() {
    local filelist="$*"

    if [ -z "$filelist" ]; then
	return ;
    fi

    $MKZEROS -s $SIZE -r 40 $filelist

    if [ $NUMCOPIES -gt 0 ];
    then
	iter=0;
	for file in $filelist;
	do
	    for j in `seq 1 $(($NUMCOPIES-1))`;
	    do
		dd if=$file of=$DEST/testfile.$j.$iter bs=1M
		# cat $file > $DEST/testfile.$j.$iter
	    done
	    iter=$(($iter+1))
	done
    fi
}

DEST=$TESTDIR/mkzeros_test_data/

mkdir -p $DEST
rm -fr $DEST/*

FILELIST=""
i=0
while [ $i -lt $FILECOUNT ]; do
    FILELIST="$FILELIST $DEST/testfile.0.$i"
    i=$(($i+1));

    # Don't let filelist get too long
    mod=$(($i % 100));
    if [ $mod -eq 0 ]; then
	make_files $FILELIST
	FILELIST=""
    fi
done

make_files $FILELIST
