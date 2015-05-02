<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

### Resources must now use `provides` to declare recipe DSL

Resources declared in `Chef::Resource` namespace will no longer get recipe DSL
automatically.  Instead, explicit `provides` is required in order to have DSL:

```ruby
module MyModule
  class MyResource < Chef::Resource
    provides :my_resource
  end
end
```

Users are encouraged to declare resources in their own namespaces instead of putting them in the special `Chef::Resource` namespace.

The `Chef::Resource` namespace will no longer get automatic DSL in a future Chef, and will emit a deprecation warning in Chef 12.

### LWRPs are no longer placed in the `Chef::Resource` namespace

Additionally, resources declared as LWRPs are no longer placed in the
`Chef::Resource` namespace.  This means that if your cookbook includes the LWRP
`mycookbook/resources/myresource.rb`, you will no longer be able to extend or
reference `Chef::Resource::MycookbookMyresource` in Ruby code.  LWRP recipe DSL
does not change: the LWRP will still be available to recipes as
`mycookbook_myresource`.

You can still get the LWRP class by calling `Chef::Resource.resource_matching_short_name(:mycookbook_myresource)`.

The primary aim here is clearing out the `Chef::Resource` namespace.

References to these classes is deprecated (and will emit a warning) in Chef 12, and will be removed in Chef 13.
