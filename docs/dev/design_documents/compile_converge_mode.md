---
title: Data Collector
---

# Compile Converge Mode

##



## Special Considerations:  `chef_gem`, `hostname` and chef-sugar

The `chef_gem` and `hostname` resources take a `compile_time` property which can be used to force the resource
to run at compile time.  Presently this API is limited to those two resources.

Historically the `chef_gem` was forced to run at compile time always.  This was eventually realized to be a poor
design since native gems being installed at compile time would force the installation of compilers at compile
time and created a large race to push more and more resources to compile time.  This default was eventually
flipped so that it ran at converge time, but it was necessary to introduce the `compile_time` property to deal
with that transition.  It is generally recommended to not set this property to true.

The `hostname` resource copies that implementation.  Since the `hostname` resource changes the hostname on the box
and then re-runs `ohai` and loads new state into the node object it is forced to run at compile time, before any
resources are converged, and before later resources are parsed at compile time.  This avoids having to lazy every
`node[:fqdn]` (or `node[:machinename]` which is a better attribute to use) reference in every subsequent resource.
The same `compile_time` flag is introduced there in order to override this.  It is not recommended to set this
property to false.

The `chef-sugar` gem adds the syntax to force any resource to compile time via the `at_compile_time` helper method:

```ruby
at_compile_time do
  package "apache2"
end
```



