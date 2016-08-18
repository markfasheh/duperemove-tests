#!/bin/bash
#
# Test that duperemove does the correct thing when a file shrinks in
# between scans. We had a bug (issue#139) where duperemove was
# aborting with ENOMEM when this would happen.
#

. `dirname $0`/config

DEST=$TESTDIR/issue139
HASHFILE=$DEST/test.hash
BS=$((128*1024))

rm -fr $DEST
mkdir -p $DEST

for i in `seq 0 7`
do
    dd if=/dev/zero of=$DEST/testfile_$i count=2 bs=$BS
done

# create initial hashfile
$DUPEREMOVE -rdh --hashfile=$HASHFILE $DEST/testfile*

# truncate one of the files so it will be skipped in our next file scan
> $DEST/testfile_0

# update mtime on another one so we can be sure that new dedupes go
# through as well.
touch $DEST/testfile_1

$DUPEREMOVE -rdh --hashfile=$HASHFILE $DEST/testfile*
if [ $? -ne 0 ]; then
    echo "FAILURE: Bad return code from duperemove"
    exit 1
fi
