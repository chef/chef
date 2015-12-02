# Chef Client Release Notes 12.6.0:


## New `chef_version` and `ohai_version` metadata keywords

Two new keywords have been introduced to the metadata of cookbooks for constraining the acceptable range
of chef-client versions that a cookbook runs on.  By default if these keywords are not present chef-client
will always run.  If either of these keywords are given and none of the given ranges match the running
Chef::VERSION or Ohai::VERSION then the chef-client will report an error that the cookbook does not support
the running client or ohai version.

There is currently little integration with this outside of the client, but work is underway to display this
information on the supermarket.  There are also plans to get depsolvers like Berkshelf able to automatically
prune invalid cookbooks out of their solution sets to avoid uploading a cookbook which will only throw
an exception.

## New --profile-ruby option to profile Ruby

The 'chef' gem now has a new optional development dependency on the 'ruby-prof' gem and when it is installed
it can be used via the --profile-ruby command line option.  This gem will also be shipped in all the omnibus
builds of `chef` and `chef-dk` going forwards so that while it will be 'optional' it will also be fairly
broadly installed (it is 'optional' mostly for people who are installing chef in their own bundles).

When invoked this option will dump a (large) profiling graph into `/var/chef/cache/graph_profile.out`.  For
users who are familiar with reading call stack graphs this will likely be very useful for profiling the
internal guts of a chef-client run.  The performance hit of this profiler will roughly double the length
of a chef-client run so it is something that can be used without causing errant timeouts and other
heisenbugs due to the profiler itself.  It is not suitable for daily use in production.  It is unlikely to
be suitable for users without a background in software development and debugging.

It was developed out of some particularly difficult profiling of performance issues in the Chef node
attributes code, which was then turned into a patch so that other people could experiment with it.  It was
not designed to be a general solution to performance issues inside of chef-client recipe code.

This debugging feature will mostly be useful to people who are already Ruby experts.


