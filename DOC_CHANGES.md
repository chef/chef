<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

### Resources now *all* get automatic DSL

When you declare a resource (no matter where) you now get automatic DSL for it, based on your class name:

```ruby
module MyModule
  class MyResource < Chef::Resource
    # Names the resource "my_resource"
  end
end
```

When this happens, the resource can be used in a recipe:

```ruby
my_resource 'blah' do
end
```

If you have an abstract class that should *not* have DSL, set `resource_name` to `nil`:

```ruby
module MyModule
  # This will not have DSL
  class MyBaseResource < Chef::Resource
    resource_name nil
  end
  # This will have DSL `my_resource`
  class MyResource < MyBaseResource
  end
end
```

When you do this, `my_base_resource` will not work in a recipe (but `my_resource` will).

You can still use `provides` to provide other DSL names:

```ruby
module MyModule
  class MyResource < Chef::Resource
    provides :super_resource
  end
end
```

Which enables this recipe:

```ruby
super_resource 'wowzers' do  
end
```

(Note that when you use provides in this manner, resource_name will be `my_resource` and declared_type will be `super_resource`. This won't affect most people, but it is worth noting as a matter of explanation.)

Users are encouraged to declare resources in their own namespaces instead of putting them in the `Chef::Resource` namespace.

### Resources may now use `allowed_actions` and `default_action`

Instead of overriding `Chef::Resource.initialize` and setting `@allowed_actions` and `@action` in the constructor, you may now use the `allowed_actions` and `default_action` DSL to declare them:

```ruby
class MyResource < Chef::Resource
  allowed_actions :create, :delete
  default_action :create
end
```

### LWRPs are no longer automatically placed in the `Chef::Resource` namespace

Starting with Chef 12.4.0, accessing an LWRP class by name from the `Chef::Resource` namespace will trigger a deprecation warning message. This means that if your cookbook includes the LWRP `mycookbook/resources/myresource.rb`, you will no longer be able to extend or reference `Chef::Resource::MycookbookMyresource` in Ruby code.  LWRP recipe DSL does not change: the LWRP will still be available to recipes as `mycookbook_myresource`.

You can still get the LWRP class by calling `Chef::ResourceResolver.resolve(:mycookbook_myresource)`.

The primary aim here is clearing out the `Chef::Resource` namespace.

References to these classes is deprecated (and will emit a warning) in Chef 12, and will be removed in Chef 13.
