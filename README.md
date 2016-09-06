Tests for duperemove.

This is all pretty basic, mostly we can automatically test for program
failure. Ultimately we'll want to parse program output too so we can
check very specific conditions.

To run:

0) make
1) cp tests/config.sample tests/config
2) edit tests/config to match your environment
3) run the .sh files in tests/ (or at least run smoke_test.sh)
