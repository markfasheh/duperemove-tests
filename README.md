Tests for duperemove.

This is all pretty basic, mostly we can automatically test for program
failure. Ultimately we'll want to parse program output too so we can
check very specific conditions.

To run:

1. make
2. cp config.sample config
3. edit config to match your environment
4. run tests/smoke_test.sh and the other tests/test_*.sh files
