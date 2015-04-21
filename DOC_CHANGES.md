<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

### Chef Client and Knife `--no-listen` Flag and `listen` Config Option

Chef Client and Knife have a `--no-listen` CLI option. It is only
relevant when using local mode (`-z`). When this flag is given, Chef
Zero does not bind to a port on localhost. The same behavior can be
activated by setting `listen false` in the relevant config file.

### Chef Client, Solo, and Apply `--minimal-ohai` Flag

Chef Client, Solo, and Apply all implement a `--minimal-ohai` flag. When
set, Chef only runs the bare minimum necessary ohai plugins required for
internal functionality. This reduces the run time of ohai and might
improve Chef performance by reducing the amount of data kept in memory.
Most users should NOT use this mode, however, because cookbooks that
rely on data collected by other ohai plugins will definitely be broken
when Chef is run in this mode. It may be possible for advanced users to
work around that by using the ohai resource to collect the "missing"
data during the compile phase.
