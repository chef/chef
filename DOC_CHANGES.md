<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

### Resources may now specify `resource_name` to get DSL

When you declare a resource class, you may call `resource_name` to get recipe DSL for it.

```ruby
module MyModule
  class MyResource < Chef::Resource
    resource_name :my_resource
    # Names the resource "my_resource"
  end
end
```

When this happens, the resource can be used in a recipe:

```ruby
my_resource 'blah' do
end
```

If you have an abstract class that should *not* have DSL, you may set `resource_name` to `nil` (this is only really important for classes in `Chef::Resource` which get DSL automatically):

```ruby
class Chef
  class Resource
    # This will not have DSL
    class MyBaseResource < Chef::Resource
      resource_name nil
    end
    # This will have DSL `my_resource`
    class MyResource < MyBaseResource
    end
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

### Resource `provides` now has intuitive automatic rules

`provides` is how a Resource or Provider associates itself with the Chef recipe DSL on different OS's.  Now when multiple resources or providers say they provide the same DSL, "specificity rules" are applied to decide the priority of these rules.  For example:

```ruby
class GenericFile < Chef::Resource
  provides :file
end
class LinuxFile < Chef::Resource
  provides :file, os: 'linux'
end
class DebianFile < Chef::Resource
  provides :file, platform_family: 'debian'
end
```

This means that if I run this recipe on Ubuntu, it will pick DebianFile:

```ruby
file 'x' do
end
```

Now, no matter what order those resources are declared in, the resource lookup system will choose DebianFile on Debian-based platforms since that is the most specific rule.  If a platform is Linux but *not* Debian, like Red Hat, it will pick LinuxFile, since that is less specific.

The specificity order (from highest to lowest) is:

1. provides :x, platform_version: '12.4.0'
2. provides :x, platform: 'ubuntu'
3. provides :x, platform_family: 'debian'
4. provides :x, os: 'linux'
5. provides :x

This means that a class that specifies a platform_version will *always* be picked over any other provides line.

### Warnings when multiple classes try to provide the same resource DSL

We now warn you when you are replacing DSL provided by another resource or
provider class:

```ruby
class X < Chef::Resource
  provides :file
end
class Y < Chef::Resource
  provides :file
end
```

This will emit a warning that Y is overriding X.  To disable the warning, use `override: true`:

```ruby
class X < Chef::Resource
  provides :file
end
class Y < Chef::Resource
  provides :file, override: true
end
```

### LWRPs are no longer automatically placed in the `Chef::Resource` namespace

Starting with Chef 12.4.0, accessing an LWRP class by name from the `Chef::Resource` namespace will trigger a deprecation warning message. This means that if your cookbook includes the LWRP `mycookbook/resources/myresource.rb`, you will no longer be able to extend or reference `Chef::Resource::MycookbookMyresource` in Ruby code.  LWRP recipe DSL does not change: the LWRP will still be available to recipes as `mycookbook_myresource`.

You can still get the LWRP class by calling `Chef::ResourceResolver.resolve(:mycookbook_myresource)`.

The primary aim here is clearing out the `Chef::Resource` namespace.

References to these classes is deprecated (and will emit a warning) in Chef 12, and will be removed in Chef 13.
