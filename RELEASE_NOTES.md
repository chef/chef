*This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team.
Please see `https://docs.chef.io/release/<major>-<minor>/release_notes.html` for the official Chef release notes.*

# Chef Client Release Notes 12.14:

## Highlighted enhancements for this release:

* Upgraded Ruby version from 2.1.9 to 2.3.1 which adds several performance and functionality enhancements.
* Added a small patch to Ruby 2.3.1 and improvements to the Ohai Network plugin in order to support chef client runs on Windows Nano Server.
* Added the ability to mark a property of a custom resource as "sensitive." This will suppress the property's value when it's used in other outputs, such as messages used by the [Data Collector](https://github.com/chef/chef-rfc/blob/master/rfc077-mode-agnostic-data-collection.md). To use, add `sensitive: true` when definine the property. Example:

  ```ruby
  property :db_password, String, sensitive: true
  ```

* Ported the yum_repository resource from the yum cookbook to core chef. With this change you can create and remove repositories without depending on the yum cookbook. Example:

  ```ruby
  yum_repository 'OurCo' do
    description 'OurCo yum repository'
    mirrorlist 'http://artifacts.ourco.org/mirrorlist?repo=ourco-6&arch=$basearch'
    gpgkey 'http://artifacts.ourco.org/pub/yum/RPM-GPG-KEY-OURCO-6'
    action :create
  end

  yum 'Oldrepo' do
    action :delete
  end
  ```

* Support for Solaris releases before 10u11 has been removed
* Upgraded Ohai to 8.20 with new / enhanced plugins. See the [ohai changelog](https://github.com/chef-cookbooks/ohai/blob/master/CHANGELOG.md)

## Highlighted bug fixes for this release:

Fixed `chef_gem` for local gems with remote dependencies. A recent chef release introduced a breaking change which added the `--local` argument to `gem installs` for local gems prohibiting remote dependencies from being installed. Users who want to ensure that gem installs remain completely local should add `--local` to the `options` property:

```
chef_gem 'my-gem' do
  source '/tmp/gems/my-gem.gem'
  options '--local'
  action :install
end
```
