# Chef Client Release Notes 12.9:

## Possible Compat Break with `use_inline_resources` and non-LWRPBase library providers

The correct pattern for LWRPBase-style library providers looks something like:

```ruby
class MyProvider < Chef::Provider::LWRPBase
  use_inline_resources

  action :stuff do
    file "/tmp/whatever.txt"
  end
end
```

Start in 12.5 the `use_inline_resources` directive was mixed into Chef::Provider directly and had the
side effect of mixin in the DSL.  After 12.5 it would have worked to write code like this:

```ruby
class MyProvider < Chef::Provider
  use_inline_resources

  action :stuff do
    file "/tmp/whatever.txt"
  end
end
```

But that code would be broken (with a hard syntax error on `use_inline_resources` on prior versions of
chef-client).  After 12.9 that code will now be broken on the use of the Recipe DSL which has been removed
from Chef::Provider when mixing use_inline_resources into classes that only inherit from the core
class.  If any code has been written like this, it should be modified to correctly inherit from
Chef::Provider::LWRPBase instead (which will have the side effect of fixing it so that it correctly works
on Chef 11.0-12.5 as well).

