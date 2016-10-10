*This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team.
Please see [https://docs.chef.io/release_notes.html](https://docs.chef.io/release_notes.html) for the official Chef release notes.*

# Chef Client Release Notes 12.15:

## Highlighted enhancements for this release:

* Omnibus packages are now available for Ubuntu 16.04.

* Added cab_package resource and provider which supports the installation of CAB/cabinet packages on Windows. Example:

  ```ruby
  cab_package 'Install .NET 3.5 sp1 via KB958488' do
    source 'C:\Users\xyz\AppData\Local\Temp\Windows6.1-KB958488-x64.cab'
    action :install
  end

  cab_package 'Remove .NET 3.5 sp1 via KB958488' do
    source 'C:\Users\xyz\AppData\Local\Temp\Windows6.1-KB958488-x64.cab'
    action :remove
  end
  ```
  **NOTE:** cab_package resource does not support URLs in `source`.

* Added exit code 213 (Chef Upgrades) from [RFC062](https://github.com/chef/chef-rfc/blob/master/rfc062-exit-status.md)
  * This allows for easier testing of chef client upgrades in Test Kitchen. See [omnibus_updater](https://github.com/chef-cookbooks/omnibus_updater)

* Set `yum_repository` gpgcheck default to true.

* Allow deletion of `registry_key` without the need for users to pass data key in values hash.

* `knife ssh` will pass the -P option on the command line, if it is given, as the sudo password and will bypass prompting.

## Highlighted bug fixes for this release:

