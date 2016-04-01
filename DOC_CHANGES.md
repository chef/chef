<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

## Doc changes for Chef 12.9

### New timeout option added to `knife ssh`

When doing a `knife ssh` call, if a connection to a host is not able
to succeed due to host unreachable or down, the entire call can hang. In
order to prevent this from happening, a new timeout option has been added
to allow a connection timeout to be passed to the underlying SSH call
(see ConnectTimeout setting in http://linux.die.net/man/5/ssh_config)

The timeout setting can be passed in via a command line parameter
(`-t` or `--ssh-timeout`) or via a knife config
(`Chef::Config[:knife][:ssh_timeout]`).  The value of the timeout is set
in seconds.
