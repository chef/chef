*This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team.
Please see [https://docs.chef.io/release_notes.html](https://docs.chef.io/release_notes.html) for the official Chef release notes.*

# Chef Client Release Notes 12.16:

## Highlighted enhancements for this release:

* Added `attribute_changed` event hook:

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

## Highlighted bug fixes for this release:

