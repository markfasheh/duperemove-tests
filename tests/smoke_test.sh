#!/bin/bash

. `dirname $0`/../config || exit 1
. `dirname $0`/common || exit 1

DEST=$TESTDIR/basic
HASHFILE=$DEST/test.hash
BS=$((128*1024))
SIZE=$((4*1024*1024))

prep_dirs() {
    rm -fr $DEST
    mkdir -p $DEST

    for i in `seq -w 0 2`;
    do
	DIR="$DEST/testdir_$i"
	mkdir -p $DIR/
	_run_mkzeros -s $SIZE $DIR/0 $DIR/1 $DIR/2 $DIR/3
    done

    wait

    btrfs fi sync $DEST
}

prep_secondary_dirs() {
    #remove a dir to trigger the delete hashes code
    rm -fr $DEST/testdir_0 &
    #make a fresh directory so we can add it to the hashfile
    DIR="$DEST/testdir_extra"
    mkdir -p $DIR/
    _run_mkzeros -s $SIZE $DIR/0 $DIR/1 $DIR/2 $DIR/3
    wait
    btrfs fi sync $DEST
}

prep_dirs

# --version and --help options should not return error
_run_duperemove --version
_run_duperemove --help

echo "Test memory only operation"
#memory only, don't dedupe yet
_run_duperemove -rhv $DEST/testdir*

echo "Test fdupes mode"
DIR=$DEST/fdupes
mkdir -p $DIR
_run_dd if=/dev/zero of=$DIR/dupefileA.1 bs=$BS count=10
cp $DIR/dupefileA.1 $DIR/dupefileA.2
cp $DIR/dupefileA.1 $DIR/dupefileA.3
_run_dd if=/dev/urandom of=$DIR/dupefileB.1  bs=$BS count=10 iflag=fullblock
cp $DIR/dupefileB.1 $DIR/dupefileB.2
$FDUPES -r $DIR | _run_duperemove --fdupes -dv

echo "Test write-hashes"
_run_duperemove -rhv --write-hashes=$HASHFILE $DEST/testdir*

echo "Test read-hashes"
_run_duperemove -rhv --read-hashes=$HASHFILE

rm -f $HASHFILE

echo "Test basic hashfile"
#now store in a hashfile, do dedupe
_run_duperemove -rdhv --hashfile=$HASHFILE $DEST/testdir*

echo "Test basic hashfile update"
prep_secondary_dirs
#dedupe again we should only re-hash testdir_extra
_run_duperemove -rdhv --hashfile=$HASHFILE $DEST/testdir*

echo "Test basic hashfile (no fiemap)"
rm -f $HASHFILE
prep_dirs
prep_secondary_dirs
_run_duperemove -rdh --dedupe-options=nofiemap --hashfile=$HASHFILE \
    $DEST/testdir*

echo "Test basic hashfile (block dedupe)"
rm -f $HASHFILE
prep_dirs
prep_secondary_dirs
_run_duperemove -rdhv --dedupe-options=block --hashfile=$HASHFILE \
    $DEST/testdir*
