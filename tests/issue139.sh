#!/bin/bash
#
# Test that duperemove does the correct thing when a file shrinks in
# between scans. We had a bug (issue#139) where duperemove was
# aborting with ENOMEM when this would happen.
#
# We also check for a rename bug which wound up giving us duplicate
# inode/subvol pairs in the file table.
#

. `dirname $0`/config || exit 1
. `dirname $0`/common || exit 1

BASEDIR=$TESTDIR/issue139
DEST=$BASEDIR/files
HASHFILE=$BASEDIR/test.hash
BS=$((128*1024))

rm -fr $BASEDIR
mkdir -p $DEST

make_files() {
    local dir=$1

    for i in `seq 0 7`
    do
	dd if=/dev/zero of=$dir/testfile_$i count=2 bs=$BS
    done
}

make_files $DEST
make_files $BASEDIR

# create initial hashfile
_run_duperemove -rdh --hashfile=$HASHFILE $DEST

# truncate one of the files so it will be skipped in our next file scan
> $DEST/testfile_0

# update mtime on another one so we can be sure that new dedupes go
# through as well.
touch $DEST/testfile_1

_run_duperemove -rdh --hashfile=$HASHFILE $DEST

# Move a completely new file over an old one
mv $BASEDIR/testfile_0 $DEST/testfile_2
_run_duperemove -vrdh --hashfile=$HASHFILE $DEST

# Changes both files
mv $DEST/testfile_3 $DEST/testfile_4
_run_duperemove -vrdh --hashfile=$HASHFILE $DEST

# Check that the previous run didn't give us duplicate ino/subvol pairs
inos=`echo "select filename, ino, subvol from files group by ino having count(*) > 1;" | sqlite3 $HASHFILE`
if [ -n "$inos" ]
then
    echo "TEST FAILURE: duplicated inodes found: $inos"
    exit 1
fi

exit 0
