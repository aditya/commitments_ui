# Overview #

This is the superforker root package for installing a commitments
server.

# Requirements #
You need `superwatcher` and `superforker` installed.

You just run `production` and you are good to go. Note that this will
make a runtime instance, which will re-clone this repository. Huh? So,
if you have this checked out into ~/commitments_server, it will be blown
away and replaced with a fresh, auto-updating clone.

So, **if you are developing**, run `dev` not `production`. This assumes
you have put the GUI in `~/commitments_ui`. If not, must make a symlink.
