*This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team.
Please see [https://docs.chef.io/release_notes.html](https://docs.chef.io/release_notes.html) for the official Chef release notes.*

# Chef Client Release Notes 12.16:

## Highlighted enhancements for this release:

### `attribute_changed` event hook

In a cookbook library file, you can add this in order to print out all attribute changes in cookbooks:

```ruby
Chef.event_handler do
  on :attribute_changed do |precedence, key, value|
    puts "setting attribute #{precedence}#{key.map {|n| "[\"#{n}\"]" }.join} = #{value}"
  end
end
```

If you want to setup a policy that override attributes should never be used:

```ruby
Chef.event_handler do
  on :attribute_changed do |precedence, key, value|
    raise "override policy violation" if precedence == :override
  end
end
```

There will likely be some missed attribute changes and some bugs that need fixing (hint: PRs accepted), there could be
added command line options to print out all attribute changes or filter them (hint: PRs accepted), or to add source
file and line numbers to the event (hint: PRs accepted).

### Automatic connection to Chef Automate's Data Collector with supported Chef Server

Chef Client will automatically attempt to connect to the Chef Server
authenticated data collector proxy. If you have a supported version of
Chef Server and have enabled this feature on the Chef Server, Chef
Client run data will automatically be forwarded to Automate without
additional Chef Client configuration. If you do not have Automate or the
feature is disabled on the Chef Server, Chef Client will detect this and
disable data collection.

Note that Chef Server 12.11.0+ (not yet released as of the time this was
written) is required for this feature.

## Highlighted bug fixes for this release:

