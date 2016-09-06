Tests for duperemove.

This is all pretty basic, mostly we can automatically test for program
failure. Ultimately we'll want to parse program output too so we can
check very specific conditions.

To run:

1. make
2. cp tests/config.sample tests/config
3. edit tests/config to match your environment
4. run the .sh files in tests/ (or at least run smoke_test.sh)
