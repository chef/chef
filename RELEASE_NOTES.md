# Chef Client Release Notes 12.3.0:

## Socketless Chef Zero Local Mode
All requests to the Chef Zero server in local mode use Chef Zero's new
socketless request mechanism. By default, Chef Zero will still bind to a
port and accept HTTP requests on localhost; this can be disabled with
the `--no-listen` CLI flag or by adding `listen false` to the relevant
configuration file.

## Minimal Ohai Flag

Chef Client, Solo, and Apply all now support a `--minimal-ohai` flag.
When set, Chef will only run the bare minimum Ohai plugins necessary to
support node name detection and resource/provider selection. The primary
motivation for this feature is to speed up Chef's integration tests
which run `chef-client` (and solo) many times in various contexts,
however advanced users may find it useful in certain use cases. Any
cookbook that relies on other ohai data will absolutely not work in this
mode unless the user implements workarounds such as running the ohai
resource during the compile phase.
