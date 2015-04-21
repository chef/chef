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

## Dynamic Resource Resolution and Chef Class Fascade

Resolution of Resources is now dynamic and similar to Providers and handles
multiple resources having the same provides line on a given platform.  When
the user types a resource like 'package' into the DSL that is resolved via
the provides lines, and if multiple classes provide the same resource (like
Homebrew and MacPorts package resources on Mac) then which one is selected
is governed by the Chef::Platform::ResourcePriorityMap.

In order to change the priorities in both the ResourcePriorityMap and
ProviderPriorityMap a helper API has been constructed off of the Chef class:

* `Chef.get_provider_priority_array(resource_name)`
* `Chef.get_resource_priority_array(resource_name)`
* `Chef.set_provider_priority_array(resource_name, Array<Class>, *filter)`
* `Chef.set_resoruce_priority_array(resource_name, Array<Class>, *filter)`

In order to change the `package` resource globally on MacOSX to the MacPorts provider:

`Chef.set_resource_priority_array(:package, [ Chef::Resource::MacportsPackage ], os: 'darwin')`

That line can be placed into a library file in a cookbook so that it is applied before
any recipes are compiled.

