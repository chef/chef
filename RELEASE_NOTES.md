<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# Chef Client Release Notes:

#### CHEF-5223 OS X Service provider regression.

This commit: https://github.com/opscode/chef/commit/024b1e3e4de523d3c1ebbb42883a2bef3f9f415c
introduced a requirement that a service have a plist file for any
action, but a service that is being created will not have a plist file
yet. Chef now only requires that a service have a plist for the enable
and disable actions.

#### Signal Regression Fix

CHEF-1761 introduced a regression for signal handling when not in daemon mode
(see CHEF-5172). Chef will now, once again, exit immediately on SIGTERM if it
is not in daemon mode, otherwise it will complete it's current run before
existing.
