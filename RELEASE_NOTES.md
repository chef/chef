*This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team.
Please see `https://docs.chef.io/release/<major>-<minor>/release_notes.html` for the official Chef release notes.*

# Chef Client Release Notes 12.14:

## Highlighted enhancements for this release:

* Upgraded Ruby version from 2.1.9 to 2.3.1 which adds several performance and functionality enhancements.
* Added a small patch to Ruby 2.3.1 and improvements to the Ohai Network plugin in order to support chef client runs on Windows Nano Server.

## Highlighted bug fixes for this release:

Fixed `chef_gem` for local gems with remote dependencies. A recent chef release introduced a breaking change which added the `--local` argument to `gem installs` for local gems prohibiting remote dependencies from being installed. Users who want to ensure that gem installs remain completely local should add `--local` to the `options` property:

```
chef_gem 'my-gem' do
  source '/tmp/gems/my-gem.gem'
  options '--local'
  action :install
end
```
