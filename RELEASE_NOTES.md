*This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team.
Please see `https://docs.chef.io/release/<major>-<minor>/release_notes.html` for the official Chef release notes.*

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

Starting in 12.5 the `use_inline_resources` directive was mixed into Chef::Provider directly and had the
side effect of mixing in the DSL.  After 12.5 it would have worked to write code like this:

```ruby
class MyProvider < Chef::Provider
  use_inline_resources

  action :stuff do
    file "/tmp/whatever.txt"
  end
end
```

But that code would be broken (with a hard syntax error on `use_inline_resources` on prior versions of
chef-client).  After 12.9 that code will now be broken again on the use of the Recipe DSL which has been removed
from Chef::Provider when mixing `use_inline_resources` into classes that only inherit from the core
class.  If any code has been written like this, it should be modified to correctly inherit from
Chef::Provider::LWRPBase instead (which will have the side effect of fixing it so that it correctly works
on Chef 11.0-12.5 as well).

## Shorthand options for `log_location`

The `log_location` setting now accepts shorthand `:syslog` and
`:win_evt` options. `:syslog` is shorthand for `Chef::Log::Syslog.new`
and `:win_evt` is shorthand for `Chef::Log::WinEvt.new`. All previously
valid options are still valid, including Logger or Logger-like
instances, e.g. `Chef::Log::Syslog.new` with other args than the
defaults.

## chef-client `--daemonize` option now takes an optional integer argument

Optional integer argument (.e.g `chef-client --daemonize 5`) is the
number of seconds to wait before the first daemonized run. See
[#3305] for background.

[#3305]: https://github.com/chef/chef/issues/3305
