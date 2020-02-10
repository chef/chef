This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team. Please see <https://docs.chef.io/release_notes.html> for the official Chef release notes.

# Chef Infra Client 15.8

## New notify_group functionality

Chef Infra Client now includes a new `notify_group` feature that can be used to extract multiple common notifies out of individual resources to reduce duplicate code in your cookbooks and custom resources. Previously cookbook authors would often use a `log` resource to achieve a similar outcome, but using the log resource results in unnecessary Chef Infra Client log output. The `notify_group` method produces no additional logging, but fires all defined notifications when the `:run` action is set.

Example notify_group that stops, sleeps, and then starts service when a service config is updated:

```ruby
  service "crude" do
    action [ :enable, :start ]
  end

  chef_sleep "60" do
    action :nothing
  end

  notify_group "crude_stop_and_start" do
    notifies :stop, "service[crude]", :immediately
    notifies :sleep, "chef_sleep[60]", :immediately
    notifies :start, "service[crude]", :immediately
  end

  template "/etc/crude/crude.conf" do
    source "crude.conf.erb"
    variables node["crude"]
    notifies :run, "notify_group[crude_stop_and_start]", :immediately
  end
```

## Chef InSpec 4.18.85

Chef InSpec has been updated from 4.18.39 to 4.18.85. This release includes a large number of bug fixes in addition to some great resource enhancements:

* The service resource features new support for yocto-based linux distributions. Thank you to [@michaellihs](https://github.com/michaellihs) for this addition!
* The package resource now includes support for FreeBSD. Thank you to [@fzipi](https://github.com/fzipi) for this work!
* We standardized the platform for the etc_hosts, virtualization, ini, and xml resources.
* The oracledb_session resource works again due to a missing quote fix.
* The groups resource on macOS no longer reports duplicates anymore.
command.exist? now conforms to POSIX standards. Thanks to [@PiQuer](https://github.com/PiQuer)!
* Changed the postfix_conf resource's supported platform to the broader unix. Thank you to [@fzipi](https://github.com/fzipi) for this fix!

## New Cookbook Helpers

New helpers have been added to make writing cookbooks easier.

### Platform Version Helpers

New helpers for checking platform versions have been added. These helpers return parsed version strings so there's no need to convert the returned values to Integers or Floats before comparing them. Additionally, comparisons with version objects properly understand the order of versions so `5.11` will compare as larger than `5.9`, whereas converting those values to Floats would result in `5.9` being larger than `5.11`.

* `windows_nt_version` returns the NT kernel version which often differs from Microsoft's marketing versions. This helper offers a good way to find desktop and server releases that are based on the same codebase. For example, NT 6.3 is both Windows 8.1 and Windows 2012 R2.
* `powershell_version` returns the version of PowerShell installed on the system.
* `platform_version` returns the value of node['platform_version'].

Example comparison using windows_nt_version:

```ruby
if windows_nt_version >= 10
  some_modern_windows_things
end
```

### Cloud Helpers

The cloud helpers from chef-sugar have been ported to Chef Infra Client:

* `cloud?` - if the node is running in any cloud, including internal clouds
* `ec2?` - if the node is running in ec2
* `gce?` - if the node is running in gce
* `rackspace?` - if the node is running in rackspace
* `eucalyptus?` - if the node is running under eucalyptus
* `linode?` - if the node is running in linode
* `openstack?` - if the node is running under openstack
* `azure?` - if the node is running in azure
* `digital_ocean?` - if the node is running in digital ocean
* `softlayer?` - if the node is running in softlayer

### Virtualization Helpers

The virtualization helpers from chef-sugar have been ported to Chef Infra Client and extended with helpers to detect hypervisor hosts, physical, and guest systems.

* `kvm?` - if the node is a kvm guest
* `kvm_host?` - if the node is a kvm host
* `lxc?` - if the node is an lxc guest
* `lxc_host?` - if the node is an lxc host
* `parallels?`- if the node is a parallels guest
* `parallels_host?`- if the node is a parallels host
* `vbox?` - if the node is a virtualbox guest
* `vbox_host?` - if the node is a virtualbox host
* `vmware?` - if the node is a vmware guest
* `vmware_host?` - if the node is a vmware host
* `openvz?` - if the node is an openvz guest
* `openvz_host?` - if the node is an openvz host
* `guest?` - if the node is detected as any kind of guest
* `hypervisor?` - if the node is detected as being any kind of hypervisor
* `physical?` - the node is not running as a guest (may be a hypervisor or may be bare-metal)
* `vagrant?` - attempts to identify the node as a vagrant guest (this check may be error-prone)

### include_recipe? helper

chef-sugar's `include_recipe?` has been added to Chef Infra Client providing a simple way to see if a recipe has been included on a node already.

Example usage in a not_if conditional:

```ruby
execute 'install my_app'
  command '/tmp/my_app_install.sh'
  not_if { include_recipe?('my_app::install') }
end
```

## Updated Resources

### ifconfig

The `ifconfig` resource now supports the newer `ifconfig` release that ships in Debian 10.

### mac_user

The `mac_user` resource, used when creating a user on Mac systems, has been improved to work better with macOS Catalina (10.15). The resource now properly looks up the numeric GID when creating a user, once again supports the `system` property, and includes a new `hidden` property which prevents the user from showing on the login screen. Thanks [@chilcote](https://github.com/chilcote) for these fixes and improvements.

### sysctl

The `sysctl` resource has been updated to allow the inclusion of descriptive comments. Comments may be passed as an array or as a string. Any comments provided are prefixed with '#' signs and precede the `sysctl` setting in generated files.

An example:

```ruby
sysctl 'vm.swappiness' do
  value 10
  comment [
     "define how aggressively the kernel will swap memory pages.",
     "Higher values will increase aggressiveness",
     "lower values decrease the amount of swap.",
     "A value of 0 instructs the kernel not to initiate swap",
     "until the amount of free and file-backed pages is less",
     "than the high water mark in a zone.",
     "The default value is 60."
    ]
end
```

which results in `/etc/sysctl.d/99-chef-vm.swappiness.conf` as follows:

```
# define how aggressively the kernel will swap memory pages.
# Higher values will increase aggressiveness
# lower values decrease the amount of swap.
# A value of 0 instructs the kernel not to initiate swap
# until the amount of free and file-backed pages is less
# than the high water mark in a zone.
# The default value is 60.
vm.swappiness = 10
```

## Platform Support

* Chef Infra Clients packages are now validated for Debian 10.

# Chef Infra Client 15.7

## Updated Resources

### archive_file

The `archive_file` resource will now only change ownership on files and directories that were part of the archive itself. This prevents changing permissions on important high level directories such as /etc or /bin when you extract a file into those directories. Thanks for this fix, [@bobchaos](https://github.com/bobchaos/).

### cron and cron_d

The `cron` and `cron_d` resources now include a `timeout` property, which allows you to configure actions to perform when a job times out. This property accepts a hash of timeout configuration options:

* `preserve-status`: `true`/`false` with a default of `false`
* `foreground`: `true`/`false` with a default of `false`
* `kill-after`: `Integer` for the timeout in seconds
* `signal`: `String` or `Integer` to send to the process such as `HUP`

### launchd

The `launchd` resource has been updated to properly capitalize `HardResourceLimits`. Thanks for this fix, [@rb2k](https://github.com/rb2k/).

### sudo

The `sudo` resource no longer fails on the second Chef Infra Client run when using a `Cmnd_Alias`. Thanks for reporting this issue, [@Rudikza](https://github.com/Rudikza).

### user

The `user` resource on AIX no longer forces the user to change the password after Chef Infra Client modifies the password. Thanks for this fix, [@Triodes](https://github.com/Triodes).

The `user` resource on macOS 10.15 has received several important fixes to improve logging and prevent failures.

### windows_task

The `windows_task` resource is now idempotent when a system is joined to a domain and the job runs under a local user account.

### x509_certificate

The `x509_certificate` resource now includes a new `renew_before_expiry` property that allows you to auto renew certificates a specified number of days before they expire. Thanks [@julienhuon](https://github.com/julienhuon/) for this improvement.

## Additional Recipe Helpers

We have added new helpers for identifying Windows releases that can be used in any part of your cookbooks.

### windows_workstation?

Returns `true` if the system is a Windows Workstation edition.

### windows_server?

Returns `true` if the system is a Windows Server edition.

### windows_server_core?

Returns `true` if the system is a Windows Server Core edition.

## Notable Changes and Fixes

* `knife upload` and `knife cookbook upload` will now generate a metadata.json file from metadata.rb when uploading a cookbook to the Chef Infra Server.
* A bug in `knife bootstrap` behavior that caused failures when bootstrapping Windows hosts from non-Windows hosts and vice versa has been resolved.
* The existing system path is now preserved when bootstrapping Windows nodes. Thanks for this fix, [@Xorima](https://github.com/Xorima/).
* Ohai now properly returns the drive name on Windows and includes new drive_type fields to allow you to determine the type of attached disk. Thanks for this improvement [@sshock](https://github.com/sshock/).
* Ohai has been updated to properly return DMI data to Chef Infra Client. Thanks for troubleshooting this, [@zmscwx](https://github.com/zmscwx) and [@Sliim](https://github.com/Sliim).

## Platform Support

* Chef Infra Clients packages are no longer produced for Windows 2008 R2 as this release reached its end of life on Jan 14th, 2020.
* Chef Infra Client packages are no longer produced for RHEL 6 on the s390x platform. Builds will continue to be published for RHEL 7 on the s390x platform.

## Security Updates

### OpenSSL

OpenSSL has been updated to 1.0.2u to resolve [CVE-2019-1551](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-1551)

# Chef Infra Client 15.6

## Updated Resources

## apt_repository

The `apt_repository` resource now properly escapes repository URIs instead of quoting them. This prevents failures when using the `apt-file` command, which was unable to parse the quoted URIs. Thanks for reporting this [@Seb-Solon](https://github.com/Seb-Solon)

## file

The `file` resource now shows the output of any failures when running commands specified in the `verify` property. This means you can more easily validate config files before potentially writing an incorrect file to disk. Chef Infra Client will shellout to any specified command and will show the results of failures for further troubleshooting.

## user

The `user` resource on Linux systems now continues successfully when `usermod` returns an exit code of 12. Exit code 12 occurs when a user's home directory is changed and the underlying directory already exists. Thanks [@skippyj](https://github.com/skippyj) for this fix.

## yum_repository

The `yum_repository` now properly formats the repository configuration when multiple `baseurl` values are present. Thanks [@bugok](https://github.com/bugok) for this fix.

## Performance Improvements

This release of Chef Infra Client ships with several optimizations to our Ruby installation to improve the performance of loading the chef-client and knife commands. These improvements are particularly noticeable on non-SSD hosts and on Windows.

## Smaller Install Footprint

We've further optimized our install footprint and reduced the size of `/opt/chef` by ~7% by removing unnecessary test files and libraries that shipped in previous releases.

## filesystem2 Ohai Data on Windows

Ohai 15.6 includes new `node['filesystem2']` data on Windows hosts. Fileystem2 presents filesystem data by both mountpoint and by device name. This data structure matches that of the filesystem plugin on Linux and other *nix operating systems. Thanks [@jaymzh](https://github.com/jaymzh) for this new data structure.

# Chef Infra Client 15.5.15

The Chef Infra Client 15.5.15 release includes fixes for two regressions. A regression in the `build_essential` resource caused failures on `rhel` platforms and a second regression caused Chef Infra Client to fail when starting with `enforce_path_sanity` enabled. As part of this fix we've added a new property, `raise_if_unsupported`, to the `build-essential` resource. Instead of silently continuing, this property will fail a Chef Infra Client run if an unknown platform is encountered.

We've also updated the `windows_package` resource. The resource will now provide better error messages if invalid options are passed to the `installer_type` property and the `checksum` property will now accept uppercase SHA256 checksums.

# Chef Infra Client 15.5.9

## New Cookbook Helpers

Chef Infra Client now includes a new `chef-utils` gem, which ships with a large number of helpers to make writing cookbooks easier. Many of these helpers existed previously in the `chef-sugar` gem. We have renamed many of the named helpers for consistency, while providing backwards compatibility with existing `chef-sugar` names. Existing cookbooks written with `chef-sugar` should work unmodified with any of these new helpers. Expect a Cookstyle rule in the near future to help you update existing `chef-sugar` code to use the newer built-in helpers.

For more information all of the new helpers available, see the [chef-utils readme](https://github.com/chef/chef/blob/master/chef-utils/README.md)

## Chefignore Improvements

We've reworked how chefignore files are handled in `knife`, which has allowed us to close out a large number of long outstanding bugs. `knife` will now traverse all the way up the directory structure looking for a chefignore file. This means you can place a chefignore file in each cookbook or any parent directory in your repository structure. Additionally, we have made fixes that ensure that commands like `knife diff` and `knife cookbook upload` always honor your chefignore files.

## Windows Habitat Plan

Official Habitat packages of Chef Infra Client are now available for Windows. It has all the executables of the traditional omnibus packages, but in Habitat form. You can find it in the Habitat Builder under [chef/chef-infra-client](https://bldr.habitat.sh/#/pkgs/chef/chef-infra-client/latest/windows).

## Performance Improvements

This release of Chef Infra Client ships with several optimizations to our Ruby installation that improve the performance of the chef-client and knife commands, especially on Windows systems. Expect to see more here in future releases.

## Chef InSpec 4.18.39

Chef InSpec has been updated from 4.17.17 to 4.18.38. This release includes a large number of bug fixes in addition to some great resource enhancements:

* Inputs can now be used within a `describe.one` block
* The `service` resource now includes a `startname` property for Windows and systemd services
* The `interface` resource now includes a `name` property
* The `user` resource now better supports Windows with the addition of `passwordage`, `maxbadpasswords`, and `badpasswordattempts` properties
* The `nginx` resource now includes parsing support for wildcard, dot prefix, and regex
* The `iis_app_pool` resource now handles empty app pools
* The `filesystem` resource now supports devices with very long names
* The `apt` better handles URIs and supports repos with an `arch`
* The `oracledb_session` has received multiple fixes to make it work better
* The `npm` resource now works under sudo on Unix and on Windows with a custom PATH

## New Resources

### chef_sleep

The `chef_sleep` resource can be used to sleep for a specified number of seconds during a Chef Infra Client run. This may be helpful to use with other commands that return a completed status before they are actually ready. In general, do not use this resource unless you truly need it.

Using with a Windows service that starts, but is not immediately ready:

```ruby
service 'Service that is slow to start and reports as started' do
  service_name 'my_database'
  action :start
  notifies :sleep, chef_sleep['wait for service start']
end

chef_sleep 'wait for service start' do
  seconds 30
  action :nothing
end
```

## Updated Resources

## systemd_unit / service

The `systemd_unit` and `service` resources (when on systemd) have been updated to not re-enable services with an indirect status. Thanks [@jaymzh](https://github.com/jaymzh) for this fix.

## windows_firewall

The `windows_firewall` resource has been updated to support passing in an array of profiles in the `profile` property. Thanks [@Happycoil](https://github.com/Happycoil) for this improvement.

## Security Updates

### libxslt

libxslt has been updated to 1.1.34 to resolve [CVE-2019-13118](https://nvd.nist.gov/vuln/detail/CVE-2019-13118).

# Chef Infra Client 15.4

## converge_if_changed Improvements

Chef Infra Client will now take into account any `default` values specified in custom resources when making converge determinations with the `converge_if_changed` helper. Previously, default values would be ignored, which caused necessary changes to be skipped. Note: This change may cause behavior changes for some users, but we believe this original behavior is an impacting bug for enough users to make it outside of a major release. Thanks [@ jakauppila](https://github.com/jakauppila) for reporting this.

## Bootstrap Improvements

Several improvements have been made to the `knife bootstrap` command to make it more reliable and secure:

* File creation is now wrapped in a umask to avoid potential race conditions
* `NameError` and `RuntimeError` failures during bootstrap have been resolved
* `Undefined method 'empty?' for nil:NilClass` during bootstrap have been resolved
* Single quotes in attributes during bootstrap no longer result in bootstrap failures
* The bootstrap command no longer appears in PS on the host while bootstrapping is running

## knife supermarket list Improvements

The `knife supermarket list` command now includes two new options:

* `--sort-by [recently_updated recently_added most_downloaded most_followed]`: Sort cookbooks returned from the Supermarket API
* `--owned_by`: Limit returned cookbooks to a particular owner

## Updated Resources

### chocolatey_package

The `chocolatey_package` resource no longer fails when passing options with the `options` property. Thanks for reporting this issue [@kenmacleod](https://github.com/kenmacleod).

### kernel_module

The `kernel_module` resource includes a new `options` property, which allows users to set module specific parameters and settings. Thanks [@ramereth](https://github.com/ramereth) for this new feature.

Example of a kernel_module resource using the new options property:

```ruby
  kernel_module 'loop' do
  options [ 'max_loop=4', 'max_part=8' ]
  end
```

### remote_file

The `remote_file` resource has been updated to better display progress when using the `show_progress` resource. Thanks for reporting this issue [@isuftin](https://github.com/isuftin).

### sudo

The `sudo` resource now runs sudo config validation against all of the sudo configuration files on the system instead of only the file being written. This allows us to detect configuration errors that occur when configs conflict with each other. Thanks for reporting this issue [@drzewiec](https://github.com/drzewiec).

### windows_ad_join

The `windows_ad_join` has a new `:leave` action for leaving an Active Directory domain and rejoining a workgroup. This new action also has a new `workgroup_name` property for specifying the workgroup to join upon leaving the domain. Thanks [@jasonwbarnett](https://github.com/jasonwbarnett) for adding this new action.

Example of leaving a domain

```ruby
windows_ad_join 'Leave the domain' do
  workgroup_name 'local'
  action :leave
end
```

### windows_package

The `windows_package` resource no longer updates environmental variables before installing the package. This prevents potential modifications that may cause a package installation to fail. Thanks [@jeremyhage](https://github.com/jeremyhage) for this fix.

### windows_service

The `windows_service` resource no longer updates the service and triggers notifications if the case of the `run_as_user` property does not match the user set on the service. Thanks [@jasonwbarnett](https://github.com/jasonwbarnett) for this fix.

### windows_share

The `windows_share` resource is now fully idempotent by better validating the provided `path` property from the user. Thanks [@Happycoil](https://github.com/Happycoil) for this fix.

## Security Updates

### Ruby

Ruby has been updated from 2.6.4 to 2.6.5 in order to resolve the following CVEs:

* [CVE-2019-16255](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-16255): A code injection vulnerability of Shell#[] and Shell#test
* [CVE-2019-16254](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-16254): HTTP response splitting in WEBrick (Additional fix)
* [CVE-2019-15845](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-15845): A NUL injection vulnerability of File.fnmatch and File.fnmatch?
* [CVE-2019-16201](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-16201): Regular Expression Denial of Service vulnerability of WEBrick’s Digest access authentication

# Chef Infra Client 15.3

## Custom Resource Unified Mode

Chef Infra Client 15.3 introduces an exciting new way to easily write custom resources that mix built-in Chef Infra resources with Ruby code. Previously custom resources would use Chef Infra's standard compile and converge phases, which meant that Ruby would be evaluated first and then the resources would be converged. This often results in confusing and undesirable behavior when you are trying to mix resources with Ruby logic. Many custom resource authors would attempt to get around this by forcing resources to run at compile time so that all the code in their resource would execute during the compile phase.

An example of forcing a resource to run at compile time:

```ruby
resource_name 'foo' do
  action :nothing
end.run_action(:some_action)
```

With unified mode, you opt in to a single phase per resource where all Ruby and Chef Infra resources are executed at once. This makes it far easier to determine how your code will be evaluated and run. Additionally, you no longer need to force any resources to run at compile time, as all code is run in the compile phase. To enable this new mode just add `unified_mode true` to your resources like this:

```ruby
property :Some_property, String

unified_mode true

action :create do
  # some code
end
```

## Interval Mode Now Fails on Windows

Chef Infra Client 15.3 will now raise an error if you attempt to keep the chef-client process running long-term by enabling interval runs. Interval runs have already raised failures on non-Windows platforms and we've suggested that users move away from them on Windows for many years. The long-running chef-client process on Windows will load and reload cookbooks over each other in memory. This could produce a running state which is not a representation of the cookbook code that the authors wrote or tested, and behavior that may be wildly different depending on how long the chef-client process has been running and on the sequence that the cookbooks were uploaded.

## Updated Resources

### ifconfig

The `ifconfig` resource has been updated to properly support interfaces with a hyphen in their name. This is most commonly encountered with bridge interfaces that are named `br-1234`.

### archive_file

The `archive_file` resource now supports archives in the RAR 5.0 format as well as zip files compressed using xz, lzma, ppmd8 and bzip2 compression.

### user

#### macOS 10.14 / 10.15 support

The `user` resource now supports the creation of users on macOS 10.14 and 10.15 systems. The updated resource now complies with macOS TCC policies by using a user with admin privileges to create and modify users. The following new properties have been added for macOS user creation:

* `admin` sets a user to be an admin.

* `admin_username` and `admin_password` define the admin user credentials required for toggling SecureToken for a user. The value of 'admin_username' must correspond to a system user that is part of the 'admin' with SecureToken enabled in order to toggle SecureToken.

* `secure_token` is a boolean property that sets the desired state for SecureToken. FileVault requires a SecureToken for full disk encryption.

* `secure_token_password` is the plaintext password required to enable or disable `secure_token` for a user. If no salt is specified we assume the 'password' property corresponds to a plaintext password and will attempt to use it in place of secure_token_password if it is not set.

#### Password property is now sensitive

The `password` property is now set to sensitive to prevent the password from being shown in debug or failure logs.

#### gid property can now be a string

The `gid` property now allows specifying the user's gid as a string. For example:

```ruby
user 'tim' do
  gid '123'
end
```

## Platform Support Updates

### macOS 10.15 Support

Chef Infra Client is now validated against macOS 10.15 (Catalina) with packages now available at [downloads.chef.io](https://downloads.chef.io/) and via the [Omnitruck API](https://docs.chef.io/api_omnitruck.html). Additionally, Chef Infra Client will no longer be validated against macOS 10.12.

### AIX 7.2

Chef Infra Client is now validated against AIX 7.2 with packages now available at [downloads.chef.io](https://downloads.chef.io/) and via the [Omnitruck API](https://docs.chef.io/api_omnitruck.html).

## Chef InSpec 4.16

Chef InSpec has been updated from 4.10.4 to 4.16.0 with the following changes:

* A new `postfix_conf` has been added for inspecting Postfix configuration files.
* A new `plugins` section has been added to the InSpec configuration file which can be used to pass secrets or other configurations into Chef InSpec plugins.
* The `service` resource now includes a new `startname` property for determining which user is starting the Windows services.
* The `groups` resource now properly gathers membership information on macOS hosts.

## Security Updates

### Ruby

Ruby has been updated from 2.6.3 to 2.6.4 in order to resolve [CVE-2012-6708](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-6708) and [CVE-2015-9251](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-9251).

### openssl

openssl has been updated from 1.0.2s to 1.0.2t in order to resolve [CVE-2019-1563](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-1563) and [CVE-2019-1547](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-1547).

### nokogiri

nokogori has been updated from 1.10.2 to 1.10.4 in order to resolve [CVE-2019-5477](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-5477)

# Chef Infra Client 15.2

## Updated Resources

### dnf_package

The `dnf_package` resource has been updated to fully support RHEL 8.

### kernel_module

The `kernel_module` now supports a `:disable` action. Thanks [@tomdoherty](https://github.com/tomdoherty).

### rhsm_repo

The `rhsm_repo` resource has been updated to support passing a repo name of `*` in the `:disable` action. Thanks for reporting this issue [@erinn](https://github.com/erinn).

### windows_task

The `windows_task` resource has been updated to allow the `day` property to accept an `Integer` value.

### zypper_package

The `zypper_package` package has been updated to properly upgrade packages if necessary based on the version specified in the resource block. Thanks [@foobarbam](https://github.com/foobarbam) for this fix.

## Platform Support Updates

### RHEL 8 Support Added

Chef Infra Client 15.2 now includes native packages for RHEL 8 with all builds now validated on RHEL 8 hosts.

### SLES 11 EOL

Packages will no longer be built for SUSE Linux Enterprise Server (SLES) 11 as SLES 11 exited the 'General Support' phase on March 31, 2019. See Chef's [Platform End-of-Life Policy](https://docs.chef.io/platforms.html#platform-end-of-life-policy) for more information on when Chef ends support for an OS release.

### Ubuntu 14.04 EOL

Packages will no longer be built for Ubuntu 14.04 as Canonical ended maintenance updates on April 30, 2019. See Chef's [Platform End-of-Life Policy](https://docs.chef.io/platforms.html#platform-end-of-life-policy) for more information on when Chef ends support for an OS release.

## Ohai 15.2

Ohai has been updated to 15.2 with the following changes:
  - Improved detection of Openstack including proper detection of Windows nodes running on Openstack when fetching metadata. Thanks [@jjustice6](https://github.com/jjustice6).
  - A new `other_versions` field has been added to the Packages plugin when the node is using RPM. This allows you to see all installed versions of packages, not just the latest version. Thanks [@jjustice6](https://github.com/jjustice6).
  - The Linux Network plugin has been improved to not mark interfaces down if `stp_state` is marked as down. Thanks [@josephmilla](https://github.com/josephmilla).
  - Arch running on ARM processors is now detected as the `arm` platform. Thanks [@BackSlasher](https://github.com/BackSlasher).

## Chef InSpec 4.10.4

Chef InSpec has been updated from 4.6.4 to 4.10.4 with the following changes:

* Fix handling multiple triggers in the `windows_task` resource
* Fix exceptions when resources are used with incompatible transports
* Un-deprecate the `be_running` matcher on the `service` resource
* Add resource `sys_info.manufacturer` and `sys_info.model`
* Add `ip6tables` resource

## Security Updates

### bzip2

bzip2 has been updated from 1.0.6 to 1.0.8 to resolve [CVE-2016-3189](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-3189) and [CVE-2019-12900](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-12900).

# Chef Infra Client 15.1

## New Resources

### chocolatey_feature

The `chocolatey_feature` resource allows you to enable and disable Chocolatey features. See the [chocolatey_feature documentation](https://docs.chef.io/resource_chocolatey_feauture.html) for full usage information. Thanks [@gep13](https://github.com/gep13) for this new resource.

## Updated Resources

### chocolatey_source

The `chocolatey_source` resource has been updated with new `enable` and `disable` actions, as well as `admin_only` and `allow_self_service` properties. Thanks [@gep13](https://github.com/gep13) for this enhancement.

### launchd

The `launchd` resource has been updated with a new `launch_events` property, which allows you to specify higher-level event types to be used as launch-on-demand event sources. Thanks [@chilcote](https://github.com/chilcote) for this enhancement.

### yum_package

The `yum_package` resource's helper for interacting with the yum subsystem has been updated to always close out the rpmdb lock, even during failures. This may prevent the rpmdb becoming locked in some rare conditions. Thanks for reporting this issue, [@lytao](https://github.com/lytao).

### template

The `template` resource now provides additional information on failures, which is especially useful in ChefSpec tests. Thanks [@brodock](https://github.com/brodock) for this enhancement.

## Target Mode Improvements

Our experimental Target Mode received a large number of updates in Chef Infra Client 15.1. Target Mode now reuses the connection to the remote system, which greatly speeds up the remote Chef Infra run. There is also now support for Target Mode in the `systemd_unit`, `log`, `ruby_block`, and `breakpoint` resources. Keep in mind that when using `ruby_block` with Target Mode that the Ruby code in the block will execute locally as there is not necessarily a Ruby runtime on the remote host.

## Ohai 15.1

Ohai has been updated to 15.1 with the following changes:

  - The `Shard` plugin properly uses the machine's `machinename`, `serial`, and `uuid` attributes to generate the shard value. The plugin also no longer throws an exception on macOS hosts. Thanks [@michel-slm](https://github.com/michel-slm) for these fixes.
  - The `Virtualbox` plugin has been enhanced to gather information on running guests, storage, and networks when VirtualBox is installed on a node. Thanks [@freakinhippie](https://github.com/freakinhippie) for this new capability.
  - Ohai no longer fails to gather interface information on Solaris in some rare conditions. Thanks [@devoptimist](https://github.com/devoptimist) for this fix.

## Chef InSpec 4.6.4

Chef InSpec has been updated from 4.3.2 to 4.6.4 with the following changes:

  - InSpec `Attributes` have now been renamed to `Inputs` to avoid confusion with Chef Infra attributes.
  - A new InSpec plugin type of `Input` has been added for defining new input types. See the [InSpec Plugins documentation](https://github.com/inspec/inspec/blob/master/docs/dev/plugins.md#implementing-input-plugins) for more information on writing these plugins.
  - InSpec no longer prints errors to the stdout when passing `--format json`.
  - When fetching profiles from GitHub, the URL can now include periods.
  - The performance of InSpec startup has been improved.

# Chef Infra Client 15.0.300

This release includes critical bugfixes for the 15.0 release:
  - Fix `knife bootstrap` over SSH when `requiretty` is configured on the host.
  - Added the `--chef-license` CLI flag to `chef-apply` and `chef-solo` commands.

# Chef Infra Client 15.0.298

This release includes critical bugfixes for the 15.0 release:
  - Allow accepting the license on non-interactive Windows sessions
  - Resolve license acceptance failures on Windows 2012 R2
  - Improve some `knife` and `chef-client` help text
  - Properly handle session_timeout default value in `knife bootstrap`
  - Avoid failures due to Train::Transports::SSHFailed class not being loaded in `knife bootstrap`
  - Resolve failures using the ca_trust_file option with `knife bootstrap`

# Chef Infra Client 15.0.293

## Chef Client is now Chef Infra Client

Chef Client has a new name, but don't worry, it's the same Chef Client you've grown used to. You'll notice new branding throughout the application, help, and documentation but the command line name of `chef-client` remains the same.

## Chef EULA

Chef Infra Client requires an EULA to be accepted by users before it can run. Users can accept the EULA in a variety of ways:

* `chef-client --chef-license accept`
* `chef-client --chef-license accept-no-persist`
* `CHEF_LICENSE="accept" chef-client`
* `CHEF_LICENSE="accept-no-persist" chef-client`

Finally, if users run `chef-client` without any of these options, they will receive an interactive prompt asking for license acceptance. If the license is accepted, a marker file will be written to the filesystem unless `accept-no-persist` is specified. Once this marker file is persisted, users no longer need to set any of these flags.

See our [Frequently Asked Questions document](https://www.chef.io/bmc-faq/) for more information on the EULA and license acceptance.

## New Features / Functionality

### Target Mode Prototype

Chef Infra Client 15 adds a prototype for a new method of executing resources called Target Mode. Target Mode allows a Chef Infra Client run to manage a remote system over SSH or another protocol supported by the Train library. This support includes platforms that we currently support like Ubuntu Linux, but also allows for configuring other architectures and platforms, such as switches that do not have native builds of Chef Infra Client. Target Mode maintains a separate node object for each target and allows you to manage that node using existing patterns that you currently use.

As of this release, only the `execute` resource and guards are supported, but modifying existing resources or writing new resources to support Target Mode is relatively easy. Using Target Mode is as easy as running `chef-client --target hostname`. The authentication credentials should be stored in your local `~/.chef/credentials` file with the hostname of the target node as the profile name. Each key/value pair is passed to Train for authentication.

### Data Collection Ground-Up Refactor

Chef Infra Client's Data Collection subsystem is used to report node changes during client runs to Chef Automate or other reporting systems. For Chef Infra Client 15, we performed a ground-up rewrite of this subsystem, which greatly improves the data reported to Chef Automate and ensures data is delivered even in the toughest of failure conditions.

### copy_properties_from in Custom Resources

A new `copy_properties_from` method for custom resources allows you copy properties from your custom resource into other resources you are calling, so you can avoid unnecessarily repeating code.

To inherit all the properties of another resource:
```ruby
resource_name :my_resource

property :mode, String, default: '777'
property :owner, String, default: 'app_user'
property :group, String, default: 'admins'

directory '/etc/myapp' do
  copy_properties_from new_resource
  recursive true
end
```

To selectively inherit certain properties from a resource:
```ruby
resource_name :my_resource

property :mode, String, default: '777'
property :owner, String, default: 'app_user'
property :group, String, default: 'admins'

directory '/etc/myapp' do
  copy_properties_from(new_resource, :owner, :group, :mode)
  mode '755'
  recursive true
end
```

### ed25519 SSH key support

Our underlying SSH implementation has been updated to support the new ed25519 SSH key format. This means you will be able to use `knife bootstrap` and `knife ssh` on hosts that only support this new key format.

### Allow Using --delete-entire-chef-repo in Chef Local Mode

Chef Solo's `--delete-entire-chef-repo` option has been extended to work in Local Mode as well. Be warned that this flag does exactly what it states, and when used incorrectly, can result in loss of work.

## New Resources

### archive_file resource

Use the `archive_file` resource to decompress multiple archive formats without the need for compression tools on the host.

See the [archive_file](https://docs.chef.io/resource_archive_file.html) documentation for more information.

### windows_uac resource

Use the `windows_uac` resource to configure UAC settings on Windows hosts.

See the [windows_uac](https://docs.chef.io/resource_windows_uac.html) documentation for more information.

### windows_dfs_folder resource

Use the `windows_dfs_folder` resource to create and delete Windows DFS folders.

See the [windows_dfs_folder](https://docs.chef.io/resource_windows_dfs_folder.html) documentation for more information.

### windows_dfs_namespace resources

Use the `windows_dfs_namespace` resource to create and delete Windows DFS namespaces.

See the [windows_dfs_namespace](https://docs.chef.io/resource_windows_dfs_namespace.html) documentation for more information.

### windows_dfs_server resources

Use the `windows_dfs_server` resource to configure Windows DFS server settings.

See the [windows_dfs_server](https://docs.chef.io/resource_windows_dfs_server.html) documentation for more information.

### windows_dns_record resource

Use the `windows_dns_record` resource to create or delete DNS records.

See the [windows_dns_record](https://docs.chef.io/resource_windows_dns_record.html) documentation for more information.

### windows_dns_zone resource

Use the `windows_dns_zone` resource to create or delete DNS zones.

See the [windows_dns_zone](https://docs.chef.io/resource_windows_dns_zone.html) documentation for more information.

### snap_package resource

Use the `snap_package` resource to install snap packages on Ubuntu hosts.

See the [snap_package](https://docs.chef.io/resource_snap_package.html) documentation for more information.

## Resource Improvements

### windows_task

The `windows_task` resource now supports the Start When Available option with a new `start_when_available` property.

### locale

The `locale` resource now allows setting all possible LC_* environmental variables.

### directory

The `directory` resource now property supports passing `deny_rights :write` on Windows nodes.

### windows_service

The `windows_service` resource has been improved to prevent accidentally reverting a service back to default settings in a subsequent definition.

This example will no longer result in the MyApp service reverting to default RunAsUser:
```ruby
windows_service 'MyApp' do
  run_as_user 'MyAppsUser'
  run_as_password 'MyAppsUserPassword'
  startup_type :automatic
  delayed_start true
  action [:configure, :start]
end

...

windows_service 'MyApp' do
  startup_type :automatic
  action [:configure, :start]
end
```

### Ruby 2.6.3

Chef now ships with Ruby 2.6.3. This new version of Ruby improves performance and includes many new features to make more advanced Chef usage easier. See <https://www.rubyguides.com/2018/11/ruby-2-6-new-features/> for a list of some of the new functionality.

## Ohai Improvements

### Improved Linux Platform / Platform Family Detection

`Platform` and `platform_family` detection on Linux has been rewritten to utilize the latest config files on modern Linux distributions before falling back to slower and fragile legacy detection methods. Ohai will now begin by parsing the contents of `/etc/os-release` for OS information if available. This feature improves the reliability of detection on modern distros and allows detection of new distros as they are released.

With this change, we now detect `sles_sap` as a member of the `suse` `platform_family`. Additionally, this change corrects our detection of the `platform_version` on Cisco Nexus switches where previously the build number was incorrectly appended to the version string.

### Improved Virtualization Detection

Hypervisor detection on multiple platforms has been updated to use DMI data and a single set of hypervisors. This greatly improves the detection of hypervisors on Windows, BSD and Solaris platforms. It also means that as new hypervisor detection is added in the future, we will automatically support the majority of platforms.

### Fix Windows 2016 FQDN Detection

Ohai 14 incorrectly detected a Windows 2016 node's `fqdn` as the node's `hostname`. Ohai 15 now correctly reports the FQDN value.

### Improved Memory Usage

Ohai now uses less memory due to internal optimization of how we track plugin information.

### FIPS Detection Improvements

The FIPS plugin now uses the built-in FIPS detection in Ruby for improved detection.

## New Deprecations

### knife cookbook site deprecated in favor of knife supermarket

The `knife cookbook site` command has been deprecated in favor of the `knife supermarket` command. `knife cookbook site` will now produce a warning message. In Chef Infra Client 16, we will remove the `knife cookbook site` command entirely.

### locale LC_ALL property

The `LC_ALL` property in the `locale` resource has been deprecated as the usage of this environmental variable is not recommended by distribution maintainers.

## Breaking Changes

### Knife Bootstrap

Knife bootstrap has been entirely rewritten. Native support for Windows bootstrapping is now a part of the main `knife bootstrap` command. This marks the deprecation of the `knife-windows` plugin's `bootstrap` behavior. This change also addresses [CVE-2015-8559](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-8559): *The `knife bootstrap` command in chef leaks the validator.pem private RSA key to /var/log/messages*.

**Important**: `knife bootstrap` can bootstrap all supported versions of Chef Infra Client. Older versions may continue to work as far back as 12.20.

In order to accommodate a combined bootstrap that supports both SSH and WinRM, some CLI flags have been added, removed, or changed. Using the changed options will result in deprecation warnings, but `knife bootstrap` will accept those options unless otherwise noted. Using removed options will cause the command to fail.

#### New Flags

| Flag | Description |
|-----:|:------------|
| --max-wait SECONDS | Maximum time to wait for initial connection to be established. |
| --winrm-basic-auth-only | Perform only Basic Authentication to the target WinRM node. |
| --connection-protocol PROTOCOL| Connection protocol to use. Valid values are 'winrm' and 'ssh'. Default is 'ssh'. |
| --connection-user | User to authenticate as, regardless of protocol. |
| --connection-password| Password to authenticate as, regardless of protocol. |
| --connection-port | Port to connect to, regardless of protocol. |
| --ssh-verify-host-key VALUE | Verify host key. Default is 'always'. Valid values are 'accept', 'accept\_new', 'accept\_new\_or\_local\_tunnel', and 'never'. |

#### Changed Flags

| Flag | New Option | Notes |
|-----:|:-----------|:------|
| --[no-]host-key-verify |--ssh-verify-host-key VALUE | See above for valid values. |
| --forward-agent | --ssh-forward-agent| |
| --session-timeout MINUTES | --session-timeout SECONDS|New for ssh, existing for winrm. The unit has changed from MINUTES to SECONDS for consistency with other timeouts. |
| --ssh-password | --connection-password | |
| --ssh-port | --connection-port | `knife[:ssh_port]` config setting remains available.
| --ssh-user | --connection-user | `knife[:ssh_user]` config setting remains available.
| --ssl-peer-fingerprint | --winrm-ssl-peer-fingerprint | |
| --prerelease |--channel CHANNEL | This now allows you to specify the channel that Chef Infra Client gets installed from. Valid values are _stable_, _current_, and _unstable_. 'current' has the same effect as using the old --prerelease. |
| --winrm-authentication-protocol=PROTO | --winrm-auth-method=AUTH-METHOD | Valid values: _plaintext_, _kerberos_, _ssl_, _negotiate_ |
| --winrm-password| --connection-password | |
| --winrm-port| --connection-port | `knife[:winrm_port]` config setting remains available.|
| --winrm-ssl-verify-mode MODE | --winrm-no-verify-cert | Mode is not accepted. When flag is present, SSL cert will not be verified. Same as original mode of 'verify\_none'. [1] |
| --winrm-transport TRANSPORT | --winrm-ssl | Use this flag if the target host is accepts WinRM connections over SSL. [1] |
| --winrm-user | --connection-user | `knife[:winrm_user]` config setting remains available.|
| --winrm-session-timeout | --session-timeout | Now available for bootstrapping over SSH as well |

[1] These flags do not have an automatic mapping of old flag -> new flag. The new flag must be used.

#### Removed Flags

| Flag | Notes |
|-----:|:------|
|--kerberos-keytab-file| This option existed but was not implemented. |
|--winrm-codepage| This was used under `knife-windows` because bootstrapping was performed over a `cmd` shell. It is now invoked from `powershell`, so this option is no longer used. |
|--winrm-shell| This option was ignored for bootstrap. |
|--install-as-service| Installing Chef Client as a service is not supported. |

#### Usage Changes

Instead of specifying protocol with `-o`, it is also possible to prefix the target hostname with the protocol in URL format. For example:

```
  knife bootstrap example.com -o ssh
  knife bootstrap ssh://example.com
  knife bootstrap example.com -o winrm
  knife bootstrap winrm://example.com
```

### Chef Infra Client packages remove /opt/chef before installation

Upon upgrading Chef Infra Client packages, the `/opt/chef` directory is removed. This ensures any `chef_gem` installed gem versions and other modifications to `/opt/chef` will removed to prevent upgrade issues. Due to technical details with rpm script execution order, the implementation involves a a pre-installation script that wipes `/opt/chef` before every install, and is done consistently this way on every package manager.

Users who are properly managing customizations to `/opt/chef` through Chef recipes would not be affected, because their customizations will still be installed by the new package.

You will see a warning that the `/opt/chef` directory will be removed during the package installation process.

### powershell_script now allows overriding the default flags

We now append `powershell_script` user flags to the default flags rather than the other way around, which made user flags override the defaults. This is the correct behavior, but it may cause scripts to execute differently than in previous Chef Client releases.

### Package provider allow_downgrade is now true by default

We reversed the default behavior to `allow_downgrade true` for our package providers. To override this setting to prevent downgrades, use the `allow_downgrade false` flag. This behavior change will mostly affect users of the rpm and zypper package providers.

In this example, the code below should now read as asserting that the package `foo` must be version `1.2.3` after that resource is run.:

```
package "foo" do
  version "1.2.3"
end
```

The code below is now what is necessary to specify that `foo` must be version `1.2.3` or higher. Note that the yum provider supports syntax like `package "foo > 1.2.3"`, which should be used and is preferred over using allow_downgrade.

```
package "foo" do
  allow_downgrade false
  version "1.2.3"
end
```

### Node Attributes deep merge nil values

Writing a `nil` to a precedence level in the node object now acts like any other value and can be used to override values back to `nil`.

For example:

```
chef (15.0.53)> node.default["foo"] = "bar"
 => "bar"
chef (15.0.53)> node.override["foo"] = nil
 => nil
chef (15.0.53)> node["foo"]
 => nil
```

In prior versions of `chef-client`, the `nil` set in the override level would be completely ignored and the value of `node["foo"]` would have been "bar".

### http_disable_auth_on_redirect now enabled

The Chef config ``http_disable_auth_on_redirect`` has been changed from `false` to `true`. In Chef Infra Client 16, this config option will be removed altogether and Chef Infra Client will always disable auth on redirect.

### knife cookbook test removal

The `knife cookbook test` command has been removed. This command would often report non-functional cookbooks as functional, and has been superseded by functionality in other testing tools such as `cookstyle`, `foodcritic`, and `chefspec`.

### ohai resource's ohai_name property removal

The `ohai` resource contained a non-functional `ohai_name` property, which has been removed.

### knife status --hide-healthy flag removal

The `knife status --hide-healthy` flag has been removed. Users should run `knife status --hide-by-mins MINS` instead.

### Cookbook shadowing in Chef Solo Legacy Mode Removed

Previously, if a user provided multiple cookbook paths to Chef Solo that contained cookbooks with the same name, Chef Solo would combine these into a single cookbook. This merging of two cookbooks often caused unexpected outcomes and has been removed.

### Removal of unused route resource properties

The `route` resource contained multiple unused properties that have been removed. If you previously set `networking`, `networking_ipv6`, `hostname`, `domainname`, or `domain`, they would be ignored. In Chef Infra Client 15, setting these properties will throw an error.

### FreeBSD pkg provider removal

Support for the FreeBSD `pkg` package system in the `freebsd_package` resource has been removed. FreeBSD 10 replaced the `pkg` system with `pkg-ng` system, so this removal only impacts users of EOL FreeBSD releases.

### require_recipe removal

The legacy `require_recipe` method in recipes has been removed. This method was replaced with `include_recipe` in Chef Client 10, and a FoodCritic rule has been warning to update cookbooks for multiple years.

### Legacy shell_out methods removed

In Chef Client 14, many of the more obscure `shell_out` methods used in LWRPs and custom resources were combined into the standard `shell_out` and `shell_out!` methods. The legacy methods were infrequently used and Chef Client 14/Foodcritic both contained deprecation warnings for these methods. The following methods will now throw an error: `shell_out_compact`, `shell_out_compact!`, `shell_out_compact_timeout`, `shell_out_compact_timeout!`, `shell_out_with_systems_locale`, and `shell_out_with_systems_locale!`.

### knife bootstrap --identity_file removal

The `knife bootstrap --identity_file` flag has been removed. This flag was deprecated in Chef Client 12, and users should now use the `--ssh-identity-file` flag instead.

### knife user support for Chef Infra Server < 12 removed

The `knife user` command no longer supports the open source Chef Infra Server version prior to 12.

### attributes in metadata.rb

Chef Infra Client no longer processes attributes in the `metadata.rb` file. Attributes could be defined in the `metadata.rb` file as a form of documentation, which would be shown when running `knife cookbook show COOKBOOK_NAME`. Often, these attribute definitions would become out of sync with the attributes in the actual attributes files. Chef Infra Client 15 will no longer show these attributes when running `knife cookbook show COOKBOOK_NAME` and will instead throw a warning message upon upload. Foodcritic has warned against the use of attributes in the `metadata.rb` file since April 2017.

### Node attributes array bugfix

Chef Infra Client 15 includes a bugfix for incorrect node attribute behavior involving a rare usage of arrays, which may impact users who depend on the incorrect behavior.

Previously, you could set an attribute like this:

```
node.default["foo"] = []
node.default["foo"] << { "bar" => "baz }
```

This would result in a Hash, instead of a VividMash, inserted into the AttrArray, so that:

```
node.default["foo"][0]["bar"] # gives the correct result
node.default["foo"][0][:bar]  # does not work due to the sub-Hash not
                              # converting keys
```

The new behavior uses a Mash so that the attributes will work as expected.

### Ohai's system_profile plugin for macOS removed

We removed the `system_profile` plugin because it incorrectly returned data on modern macOS systems. If you relied on this plugin, you'll want to update recipes to use `node['hardware']` instead, which correctly returns the same data, but in a more easily consumed format. Removing this plugin speeds up Ohai and Chef Infra Client by ~3 seconds, and dramatically reduces the size of the node object on the Chef Infra Server.

### Ohai's Ohai::Util::Win32::GroupHelper class has been removed

We removed the `Ohai::Util::Win32::GroupHelper` helper class from Ohai. This class was intended for use internally in several Windows plugins, but it was never marked private in the codebase. If any of your Ohai plugins rely on this helper class, you will need to update your plugins for Ohai 15.

### Audit Mode

Chef Client's Audit mode was introduced in 2015 as a beta that needed to be enabled via `client.rb`. Its functionality has been superseded by Chef InSpec and has been removed.

### Ohai system_profiler plugin removal

The `system_profiler` plugin, which ran on macOS systems, has been removed. This plugin took longer to run than all other plugins on macOS combined, and no longer produced usable information on modern macOS releases. If you're looking for similar information, it can now be found in the `hardware` plugin.

### Ohai::Util::Win32::GroupHelper helper removal

The deprecated `Ohai::Util::Win32::GroupHelper` helper has been removed from Ohai. Any custom Ohai plugins using this helper will need to be updated.

### Ohai::System.refresh_plugins method removal

The `refresh_plugins` method in the `Ohai::System` class has been removed as it has been unused for multiple major Ohai releases. If you are programatically using Ohai in your own Ruby application, you will need to update your code to use the `load_plugins` method instead.

### Ohai Microsoft VirtualPC / VirtualServer detection removal

The `Virtualization` plugin will no longer detect systems running on the circa ~2005 VirtualPC or VirtualServer hypervisors. These hypervisors were long ago deprecated by Microsoft and support can no longer be tested.

# Chef Infra Client Release Notes 14.13:

## Updated Resources

### directory

The `directory` has been updated to properly set the `deny_rights` permission on Windows. Thanks [@merlinjim](https://github.com/merlinjim) for reporting this issue.

### service

The `service` resource is now idempotent on SLES 11 systems. Thanks [@gsingla294](https://github.com/gsingla294) for reporting this issue.

### cron

The `cron` resource has been updated to advise users to use the specify properties rather than passing values in as part of the `environment` property. This avoids a situation where a user could pass the differing values in both locations and receive unexpected results.

### link

The `link` resource includes improved logging upon failure to help you debug what has failed. Thanks [@jaymzh](https://github.com/jaymzh) for this improvement.

### template

The `template` resource now includes additional information when templating failures, which is particularly useful in ChefSpec. Thanks [@brodock](https://github.com/brodock) for this improvement.

## delete_resource Fix

The `delete_resource` helper now works properly when the resource you are attempting to delete has multiple providers. Thanks [@artem-sidorenko](https://github.com/artem-sidorenko) for this fix.

## Helpers Help Everywhere

Various helpers have been moved into Chef Infra Client's `universal` class, which makes them available anywhere in your cookbook, not just recipes. If you've ever been confused why something like `search`, `powershell_out`, or `data_bag_item` didn't work somewhere in your code, that should be resolved now.

## Deprecations

The `CHEF-25` deprecation for resource collisions between cookbooks and resources in Chef Infra Client has been removed. Instead you will see a log warning that a collision has occurred, which advises you to update your run_list or cookbooks.

## Updated Components

* openssl 1.0.2r -> 1.0.2s (bugfix only release)
* cacerts 2019-01-23 -> 2019-05-15

# Chef Infra Client Release Notes 14.12:

## Updated Resources

### windows_service

The windows_service resource no longer resets credentials on a service when using the :start action without the :configure action. Thanks [@jasonwbarnett](https://github.com/jasonwbarnett) for fixing this.

### windows_certificate

The windows_certificate resource now imports nested certificates while importing P7B certs.

## Updated Components

* nokogiri 1.10.1 -> 1.10.2
* ruby 2.5.3 -> 2.5.5
* InSpec 3.7.1 -> 3.9.0
* The unused windows-api gem is no longer bundled with Chef on Windows hosts

# Chef Infra Client Release Notes 14.11:

## Updated Resources

### chocolatey_package

The chocolatey_package resource now uses the provided options to fetch information on available packages, which allows installation packages from private sources. Thanks [@astoltz](https://github.com/astoltz) for reporting this issue.

### openssl_dhparam

The openssl_dhparam resource now supports updating the dhparam file's mode on subsequent chef-client runs. Thanks [@anewb](https://github.com/anewb) for the initial work on this fix.

### mount

The mount resource now properly adds a blank line between entries in fstab to prevent mount failures on AIX.

### windows_certificate

The windows_certificate resource now supports importing Base64 encoded CER certificates and nested P7B certificates. Additionally, private keys in PFX certificates are now imported along with the certificate.

### windows_share

The windows_share resource has improved logic to compare the desired share path vs. the current path, which prevents the resource from incorrectly converging during each Chef run. Thanks [@Xorima](https://github.com/xorima) for this fix.

### windows_task

The windows_task resource now properly clears out arguments that are no longer present when updating a task. Thanks [@nmcspadden](https://github.com/nmcspadden) for reporting this.

## InSpec 3.7.1

InSpec has been updated from 3.4.1 to 3.7.1. This new release contains improvements to the plugin system, a new config file system, and improvements to multiple resources. Additionally, profile attributes have also been renamed to inputs to prevent confusion with Chef attributes, which weren't actually related in any way.

## Updated Components

* bundler 1.16.1 -> 1.17.3
* libxml2 2.9.7 -> 2.9.9
* ca-certs updated to 2019-01-22 for new roots

## Security Updates

### OpenSSL

OpenSSL has been updated to 1.0.2r in order to resolve [CVE-2019-1559](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-1559)

### RubyGems

RubyGems has been updated to 2.7.9 in order to resolve the following CVEs:
  - [CVE-2019-8320](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-8320): Delete directory using symlink when decompressing tar
  - [CVE-2019-8321](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-8321): Escape sequence injection vulnerability in verbose
  - [CVE-2019-8322](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-8322): Escape sequence injection vulnerability in gem owner
  - [CVE-2019-8323](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-8323): Escape sequence injection vulnerability in API response handling
  - [CVE-2019-8324](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-8324): Installing a malicious gem may lead to arbitrary code execution
  - [CVE-2019-8325](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-8325): Escape sequence injection vulnerability in errors



# Chef Client Release Notes 14.10:

## Updated Resources

### windows_certificate

The windows_certificate resource is now fully idempotent and properly imports private keys. Thanks [@Xorima](https://github.com/Xorima) for reporting these issues.

### apt_repository

The apt_repository resource no longer creates .gpg directory in the user's home directory owned by root when installing repository keys. Thanks [@omry](http://github.com/omry) for reporting this issue.

### git

The git resource no longer displays the URL of the repository if the `sensitive` property is set.

## InSpec 3.4.1

InSpec has been updated from 3.2.6 to 3.4.1. This new release adds new `aws_billing_report` / `aws_billing_reports` resources, resolves multiple bugs, and includes tons of under the hood improvements.

## New Deprecations

### knife cookbook site

Since Chef 13, `knife cookbook site` has actually called the `knife supermarket` command under the hood. In Chef 16 (April 2020), we will remove the `knife cookbook site` command in favor of `knife supermarket`.

### Audit Mode

Chef's Audit mode was introduced in 2015 as a beta that needed to be enabled via client.rb. Its functionality has been superceded by InSpec and we will be removing this beta feature in Chef Infra Client 15 (April 2019).

### Cookbook Shadowing

Cookbook shadowing was deprecated in 0.10 and will be removed in Chef Infra Client 15 (April 2019). Cookbook shadowing allowed combining cookbooks within a mono-repo, so long as the cookbooks in question had the same name and were present in both the cookbooks directory and the site-cookbooks directory.

# Chef Client Release Notes 14.9:

## Updated Resources

### group

On Windows hosts, the group resource now supports setting the comment field via a new `comment` property.

### homebrew_cask

Two issues, which caused homebrew_cask to converge on each Chef run, have been resolved. Thanks [@jeroenj](https://github.com/jeroenj) for this fix. Additionally, the resource will no longer fail if the `cask_name` property is specified.

### homebrew_tap

The homebrew_tap resource no longer fails if the `tap_name` property is specified.

### openssl_x509_request

The openssl_x509_request resource now properly writes out the CSR file if the `path` property is specified. Thank you [@cpjones](https://github.com/cpjones) for reporting this issue.

### powershell_package_source

powershell_package_source now suppresses warnings, which prevented properly loading the resource state, and resolves idempotency issues when both the `name` and `source_name` properties were specified. Thanks [@Happycoil](https://github.com/Happycoil) for this fix.

### sysctl

The sysctl resource now allows slashes in the key or block name. This allows keys such as `net/ipv4/conf/ens256.401/rp_filter` to be used with this resource.

### windows_ad_join

Errors joining the domain are now properly suppressed from the console and logs if the `sensitive` property is set to true. Thanks [@Happycoil](https://github.com/Happycoil) for this improvement.

### windows_certificate

The delete action now longer fails if a certificate does not exist on the system. Additionally, certificates with special characters in their passwords will no longer fail. Thank you for reporting this [@chadmccune](https://github.com/chadmccune).

### windows_printer

The windows_printer resource no longer fails when creating or deleting a printer if the `device_id` property is specified.

### windows_task

Non-system users can now run tasks without a password being specified.

## Minimal Ohai Improvements

The ohai `init_package` plugin is now included as part of the `minimal_ohai` plugins set, which allows resources such as timezone to continue to function if Chef is running with the minimal number of ohai plugins.

## Ruby 2.6 Support

Chef 14.9 now supports Ruby 2.6.

## InSpec 3.2.6

InSpec has been updated from 3.0.64 to 3.2.6 with improved resources for auditing. See the [InSpec changelog](https://github.com/inspec/inspec/blob/master/CHANGELOG.md#v326-2018-12-20) for additional details on this new version.

## powershell_exec Runtimes Bundled

The necessary VC++ runtimes for the powershell_exec helper are now bundled with Chef to prevent failures on hosts that lacked the runtimes.

# Chef Client Release Notes 14.8:

## Updated Resources

### apt_package

The apt_package resource now supports using the `allow_downgrade` property to enable downgrading of packages on a node in order to meet a specified version. Thank you [@whiteley](https://github.com/whiteley) for requesting this enhancement.

### apt_repository

An issue was resolved in the apt_repository resource that caused the resource to fail when importing GPG keys on newer Debian releases. Thank you [@EugenMayer](https://github.com/EugenMayer) for this fix.

### dnf_package / yum_package

Initial support has been added for Red Hat Enterprise Linux 8. Thank you [@pixdrift](https://github.com/pixdrift) for this fix.

### gem_package

gem_package now supports installing gems into Ruby 2.6 or later installations.

### windows_ad_join

windows_ad_join now uses the UPN format for usernames, which prevents some failures authenticating to the domain.

### windows_certificate

An issue was resolved in the :acl_add action of the windows_certificate resource, which caused the resource to fail. Thank you [@shoekstra](htts://github.com/shoekstra) for reporting this issue.

### windows_feature

The windows_feature resource now allows for the installation of DISM features that have been fully removed from a system. Thank you [@zanecodes](https://github.com/zanecodes) for requesting this enhancement.

### windows_share

Multiple issues were resolved in windows_share, which caused the resource to either fail or update the share state on every Chef Client run. Thank you [@chadmccune](https://github.com/chadmccune) for reporting several of these issues and [@derekgroh](https://github.com/derekgroh) for one of the fixes.

### windows_task

A regression was resolved that prevented ChefSpec from testing the windows_task resource in Chef Client 14.7. Thank you [@jjustice6](https://github.com/jjustice6) for reporting this issue.

## Ohai 14.8

### Improved Virtualization Detection

#### Hyper-V Hypervisor Detection

Detection of Linux guests running on Hyper-V has been improved. In addition, Linux guests on Hyper-V hypervisors will also now detect their hypervisor's hostname. Thank you [@safematix](https://github.com/safematix) for contributing this enhancement.

Example `node['virtualization']` data:
```json
{
  "systems": {
    "hyperv": "guest"
  },
  "system": "hyperv",
  "role": "guest",
  "hypervisor_host": "hyper_v.example.com"
}
```

#### LXC / LXD Detection

On Linux systems running lxc or lxd containers, the lxc/lxd virtualization system will now properly populate the `node['virtualization']['systems']` attribute.

#### BSD Hypervisor Detection

BSD-based systems can now detect guests running on KVM and Amazon's hypervisor without the need for the dmidecode package.

### New Platform Support

* Ohai now properly detects the openSUSE 15.X platform. Thank you [@megamorf](https://github.com/megamorf) for reporting this issue.
* SUSE Linux Enterprise Desktop now identified as platform_family 'suse'
* XCP-NG is now identified as platform 'xcp' and platform_family 'rhel'. Thank you [@heyjodom](http://github.com/heyjodom) for submitting this enhancement.
* Mangeia Linux is now identified as platform 'mangeia' and platform_family 'mandriva'
* Antergos Linux now identified as platform_family 'arch'
* Manjaro Linux now identified as platform_family 'arch'

## Security Updates

### OpenSSL

OpenSSL has been updated to 1.0.2q in order to resolve:
* Microarchitecture timing vulnerability in ECC scalar multiplication ([CVE-2018-5407](https://nvd.nist.gov/vuln/detail/CVE-2018-5407))
* Timing vulnerability in DSA signature generation ([CVE-2018-0734](https://nvd.nist.gov/vuln/detail/CVE-2018-0734))

# Chef Client Release Notes 14.7:

## New Resources

### windows_firewall_rule

Use the `windows_firewall_rule` resource create or delete Windows Firewall rules.

See the [windows_firewall_rule](https://docs.chef.io/resource_windows_firewall_rule.html) documentation for more information.

Thank you [Schuberg Philis](https://schubergphilis.com/) for transferring us the [windows_firewall cookbook](https://supermarket.chef.io/cookbooks/windows_firewall) and to [@Happycoil](https://github.com/Happycoil) for porting it to chef-client with a significant refactoring.

### windows_share

Use the `windows_share` resource create or delete Windows file shares.

See the [windows_share](https://docs.chef.io/resource_windows_share.html) documentation for more information.

### windows_certificate

Use the `windows_certificate` resource add, remove, or verify certificates in the system or user certificate stores.

See the [windows_certificate](https://docs.chef.io/resource_windows_certificate.html) documentation for more information.

## Updated Resources

### dmg_package

The dmg_package resource has been refactored to improve idempotency and properly support accepting a DMG's EULA with the `accept_eula` property.

### kernel_module

Kernel_module now only runs the `initramfs` update once per Chef run to greatly speed up chef-client runs when multiple kernel_module resources are used. Thank you [@tomdoherty](https://github.com/tomdoherty) for this improvement.

### mount

The `supports` property once again allows passing supports data as an array. This matches the behavior present in Chef 12.

### timezone

macOS support has been added to the timezone resource.

### windows_task

A regression in Chef 14.6’s windows_task resource which resulted in tasks being created with the "Run only when user is logged on" option being set when created with a specific user other than SYSTEM, has been resolved.

# Chef Client Release Notes 14.6:

## Smaller Package and Install Size

Both Chef packages and on disk installations have been greatly reduced in size by trimming unnecessary installation files. This has reduced our package size on macOS/Linux by ~50% and Windows by ~12%. With this change Chef 14 is now smaller than a legacy Chef 10 package.

## New Resources

### Timezone

Chef now includes the `timezone` resource from [@dragonsmith](http://github.com/dragonsmith)'s `timezone_lwrp` cookbook. This resource supports setting a Linux node's timezone. Thank you [@dragonsmith](http://github.com/dragonsmith) for allowing us to include this out of the box in Chef.

Example:

```ruby
timezone 'UTC'
```

## Updated Resources

### windows_task

The `windows_task` resource has been updated to support localized system users and groups on non-English nodes. Thanks [@jugatsu](http://github.com/jugatsu) for making this possible.

### user

The `user` resource now includes a new `full_name` property for Windows hosts, which allows specifying a user's full name.

Example:

```ruby
  user 'jdoe' do
    full_name 'John Doe'
  end
```

### zypper_package

The `zypper_package` resource now includes a new `global_options` property. This property can be used to specify one or more options for the zypper command line that are global in context.

Example:

```ruby
package 'sssd' do
   global_options '-D /tmp/repos.d/'
end
```

## InSpec 3.0

Inspec has been updated to version 3.0 with addition resources, exception handling, and a new plugin system. See https://blog.chef.io/2018/10/16/announcing-inspec-3-0/ for details.

## macOS Mojave (10.14)

Chef is now tested against macOS Mojave, and packages are now available at downloads.chef.io.

## Important Bugfixes

* Multiple bugfixes in Chef Vault have been resolved by updating chef-vault to 3.4.2
* Invalid yum package names now gracefully fail
* `windows_ad_join` now properly executes. Thank you [@cpjones01](https://github.com/cpjones01) for reporting this.
* `rhsm_errata_level` now properly executes. Thank you [@freakinhippie](https://github.com/freakinhippie) for this fix.
* `registry_key` now properly writes out the correct value when `sensitive` is specified. Thank you [@josh-barker](https://github.com/josh-barker) for this fix.
* `locale` now properly executes on RHEL 6 and Amazon Linux 201X.

## Ohai 14.6

### Filesystem Plugin on AIX and Solaris

AIX and Solaris now ship with a filesystem2 plugin that updates the filesystem data to match that of Linux, macOS, and BSD hosts. This new data structure makes accessing filesystem data in recipes easier and especially improves the layout and depth of data on ZFS filesystems. In Chef Infra Client 15 (April 2019) we will begin writing this same format of data to the existing `node['filesystem']` namespace. In Chef 16 (April 2020) we will remove the `node['filesystem2']` namespace, completing the transition to the new format. Thank you [@jaymzh](https://github.com/jaymzh) for continuing the updates to our filesystem plugins with this change.

### macOS Improvements

The system_profile plugin has been improved to skip over unnecessary data, which reduces macOS node sizes on the Chef Server. Additionally the CPU plugin has been updated to limit what sysctl values it polls, which prevents hanging on some system configurations.

### SLES 15 Detection

SLES 15 is now correctly detected as the platform "suse" instead of "sles". This matches the behavior of SLES 11 and 12 hosts.

## New Deprecations

### system_profile Ohai plugin removal

The system_profile plugin will be removed from Chef/Ohai 15 in April 2019. This plugin does not correctly return data on modern Mac systems. Additionally the same data is provided by the hardware plugin, which has a format that is simpler to consume. Removing this plugin will reduce Ohai return by ~3 seconds and greatly reduce the size of the node object on the Chef server.

## Security Updates

### Ruby 2.5.3

Ruby has been updated to from 2.5.1 to 2.5.3 to resolve multiple CVEs and bugs:
* [CVE-2018-16396](https://www.ruby-lang.org/en/news/2018/10/17/not-propagated-taint-flag-in-some-formats-of-pack-cve-2018-16396/)
* [CVE-2018-16395](https://www.ruby-lang.org/en/news/2018/10/17/openssl-x509-name-equality-check-does-not-work-correctly-cve-2018-16395/)

# Chef Client Release Notes 14.5.33:

This release resolves a regression that caused the ``windows_ad_join`` resource to fail to run. It also makes the following additional fixes:
  - The ``ohai`` resource's unused ``ohai_name`` property has been deprecated. This will be removed in Chef Infra Client 15.0.
  - Error messages in the ``windows_feature`` resources have been improved.
  - The ``windows_service`` resource will no longer log potentially sensitive information if the ``sensitive`` property is used.

Thanks to @cpjones01, @kitforbes, and @dgreeninger for their help with this release.

# Chef Client Release Notes 14.5.27:

## New Resources

We've added new resources to Chef 14.5. Cookbooks using these resources will continue to take precedent until the Chef Infra Client 15.0 release

### windows_workgroup

Use the `windows_workgroup` resource to join or change a Windows host workgroup.

See the [windows_workgroup](https://docs.chef.io/resource_windows_workgroup.html) documentation for more information.

Thanks [@derekgroh](https://github.com/derekgroh) for contributing this new resource.

### locale

Use the `locale` resource to set the system's locale.

See the [locale](https://docs.chef.io/resource_locale.html) documentation for more information.

Thanks [@vincentaubert](https://github.com/vincentaubert) for contributing this new resource.

## Updated Resources

### windows_ad_join

`windows_ad_join` now includes a `new_hostname` property for setting the hostname for the node upon joining the domain.

Thanks [@derekgroh](https://github.com/derekgroh) for contributing this new property.

## InSpec 2.2.102

InSpec has been updated from 2.2.70 to 2.2.102. This new version includes the following improvements:
  - Support for using ERB templating within the .yml files
  - HTTP basic auth support for fetching dependent profiles
  - A new global attributes concept
  - Better error handling with Automate reporting
  - Vendor command now vendors profiles when using path://

## Ohai 14.5

### Windows Improvements

Detection for the `root_group` attribute on Windows has been simplified and improved to properly support non-English systems. With this change, we've also deprecated the `Ohai::Util::Win32::GroupHelper` helper, which is no longer necessary. Thanks to [@jugatsu](https://github.com/jugatsu) for putting this together.

We've also added a new `encryption_status` attribute to volumes on Windows. Thanks to [@kmf](https://github.com/kmf) for suggesting this new feature.

### Configuration Improvements

The timeout period for communicating with OpenStack metadata servers can now be configured with the `openstack_metadata_timeout` config option. Thanks to [@sawanoboly](https://github.com/sawanoboly) for this improvement.

Ohai now properly handles relative paths to config files when running on the command line. This means commands like `ohai -c ../client.rb` will now properly use your config values.

## Security updates

### Rubyzip

The rubyzip gem has been updated to 1.2.2 to resolve [CVE-2018-1000544](https://www.cvedetails.com/cve/CVE-2018-1000544/)

# Chef Client Release Notes 14.4:

## Knife configuration profile management commands

Several new commands have been added under `knife config` to help manage multiple
profiles in your `credentials` file.

`knife config get-profile` displays the active profile.

`knife config use-profile PROFILE` sets the workstation-level default
profile. You can still override this setting with the `--profile` command line
option or the `$CHEF_PROFILE` environment variable.

`knife config list-profiles` displays all your available profiles along with
summary information on each.

```bash
$ knife config get-profile
staging
$ knife config use-profile prod
Set default profile to prod
$ knife config list-profiles
 Profile  Client  Key               Server
-----------------------------------------------------------------------------
 staging  myuser  ~/.chef/user.pem  https://example.com/organizations/staging
*prod     myuser  ~/.chef/user.pem  https://example.com/organizations/prod
```

Thank you [@coderanger](https://github.com/coderanger) for this contribution.

## New Resources

The following new previous resources were added to Chef 14.4. Cookbooks with the same resources will continue to take precedent until the Chef Infra Client 15.0 release

### Cron_d

Use the [cron_d](https://docs.chef.io/resource_cron_d.html) resource to manage cron definitions in /etc/cron.d. This is similar to the `cron` resource, but it does not use the monolithic `/etc/crontab`. file.

### Cron_access

Use the [cron_access](https://docs.chef.io/resource_cron_access.html) resource to manage the `/etc/cron.allow` and `/etc/cron.deny` files. This resource previously shipped in the `cron` community cookbook and has fully backwards compatibility with the previous `cron_manage` definition in that cookbook.

### openssl_x509_certificate

Use the [openssl_x509_certificate](https://docs.chef.io/resource_openssl_x509_certificate.html) resource to generate signed or self-signed, PEM-formatted x509 certificates. If no existing key is specified, the resource automatically generates a passwordless key with the certificate. If a CA private key and certificate are provided, the certificate will be signed with them. This resource previously shipped in the `openssl` cookbook as `openssl_x509` and is fully backwards compatible with the legacy resource name.

Thank you [@juju482](https://github.com/juju482) for updating this resource!

### openssl_x509_request

Use the [openssl_x509_request](https://docs.chef.io/resource_openssl_x509_request.html) resource to generate PEM-formatted x509 certificates requests. If no existing key is specified, the resource automatically generates a passwordless key with the certificate.

Thank you [@juju482](https://github.com/juju482) for contributing this resource.

### openssl_x509_crl

Use the [openssl_x509_crl](https://docs.chef.io/resource_openssl_x509_crl.html)l resource to generate PEM-formatted x509 certificate revocation list (CRL) files.

Thank you [@juju482](https://github.com/juju482) for contributing this resource.

### openssl_ec_private_key

Use the [openssl_ec_private_key](https://docs.chef.io/resource_openssl_ec_private_key.html) resource to generate ec private key files. If a valid ec key file can be opened at the specified location, no new file will be created.

Thank you [@juju482](https://github.com/juju482) for contributing this resource.

### openssl_ec_public_key

Use the [openssl_ec_public_key](https://docs.chef.io/resource_openssl_ec_public_key.html) resource to generate ec public key files given a private key.

Thank you [@juju482](https://github.com/juju482) for contributing this resource.

## Resource improvements

### windows_package

The windows_package resource now supports setting the `sensitive` property to avoid showing errors if a package install fails.

### sysctl

The sysctl resource will now update the on-disk `systctl.d` file even if the current sysctl value matches the desired value.

### windows_task

The windows_task resource now supports setting the task priority of the scheduled task with a new `priority` property. Additionally windows_task now supports managing the behavior of task execution when a system is on battery using new `disallow_start_if_on_batteries` and `stop_if_going_on_batteries` properties.

### ifconfig

The ifconfig resource now supports setting the interface's VLAN via a new `vlan` property on RHEL `platform_family` and setting the interface's gateway via a new `gateway` property on RHEL/Debian `platform_family`.

Thank you [@tomdoherty](https://github.com/tomdoherty) for this contribution.

### route

The route resource now supports additional RHEL platform_family systems as well as Amazon Linux.

### systemd_unit

The [systemd_unit](https://docs.chef.io/resource_systemd_unit.html) resource now supports specifying options multiple times in the content hash. Instead of setting the value to a string you can now set it to an array of strings.

Thank you [@dbresson](https://github.com/dbresson) for this contribution.

## Security Updates

### OpenSSL

OpenSSL updated to 1.0.2p to resolve:
* Client DoS due to large DH parameter ([CVE-2018-0732](https://nvd.nist.gov/vuln/detail/CVE-2018-0732))
* Cache timing vulnerability in RSA Key Generation ([CVE-2018-0737](https://nvd.nist.gov/vuln/detail/CVE-2018-0737))

# Chef Client Release Notes 14.3:

## New Preview Resources Concept

This release of Chef introduces the concept of Preview Resources. Preview resources behave the same as a standard resource built into Chef, except Chef will load a resource with the same name from a cookbook instead of the built-in preview resource.

What does this mean for you? It means we can introduce new resources in Chef without breaking existing behavior in your infrastructure. For instance if you have a cookbook with a resource named `manage_everything` and a future version of Chef introduced a preview resource named `manage_everything` you will continue to receive the resource from your cookbook. That way outside of a major release your won't experience a potentially breaking behavior change from the newly included resource.

Then when we perform our yearly major release we'll remove the preview designation from all resources, and the built in resources will take precedence over resources with the same names in cookbooks.

## New Resources

### chocolatey_config

Use the chocolatey_config resource to add or remove Chocolatey configuration keys."

#### Actions

* `set` - Sets a Chocolatey config value.
* `unset` - Unsets a Chocolatey config value.

#### Properties

* `config_key` - The name of the config. We'll use the resource's name if this isn't provided.
* `value` - The value to set.

### chocolatey_source

Use the chocolatey_source resource to add or remove Chocolatey sources.

#### Actions

* `add` - Adds a Chocolatey source.
* `remove` - Removes a Chocolatey source.

#### Properties

* `source_name` - The name of the source to add. We'll use the resource's name if this isn't provided.
* `source` - The source URL.
* `bypass_proxy` - Whether or not to bypass the system's proxy settings to access the source.
* `priority` - The priority level of the source.

### powershell_package_source

Use the `powershell_package_source` resource to register a PowerShell package repository.

### Actions

* `register` - Registers and updates the PowerShell package source.
* `unregister` - Unregisters the PowerShell package source.

#### Properties

* `source_name` - The name of the package source.
* `url` - The url to the package source.
* `trusted` - Whether or not to trust packages from this source.
* `provider_name` - The package management provider for the source. It supports the following providers: 'Programs', 'msi', 'NuGet', 'msu', 'PowerShellGet', 'psl' and 'chocolatey'.
* `publish_location` - The url where modules will be published to for this source. Only valid if the provider is 'PowerShellGet'.
* `script_source_location` - The url where scripts are located for this source. Only valid if the provider is 'PowerShellGet'.
* `script_publish_location` - The location where scripts will be published to for this source. Only valid if the provider is 'PowerShellGet'.

### kernel_module

Use the kernel_module resource to manage kernel modules on Linux systems. This resource can load, unload, blacklist, install, and uninstall modules.

#### Actions

* `install` - Load kernel module, and ensure it loads on reboot.
* `uninstall` - Unload a kernel module and remove module config, so it doesn't load on reboot.
* `blacklist` - Blacklist a kernel module.
* `load` - Load a kernel module.
* `unload` - Unload kernel module

#### Properties

* `modname` - The name of the kernel module.
* `load_dir` - The directory to load modules from.
* `unload_dir` - The modprobe.d directory.

### ssh_known_hosts_entry

Use the ssh_known_hosts_entry resource to add an entry for the specified host in /etc/ssh/ssh_known_hosts or a user's known hosts file if specified.

#### Actions

* `create` - Create an entry in the ssh_known_hosts file.
* `flush` - Immediately flush the entries to the config file. Without this the actual writing of the file is delayed in the Chef run so all entries can be accumulated before writing the file out.

#### Properties

* `host` - The host to add to the known hosts file.
* `key` - An optional key for the host. If not provided this will be automatically determined.
* `key_type` - The type of key to store.
* `port` - The server port that the ssh-keyscan command will use to gather the public key.
* `timeout` - The timeout in seconds for ssh-keyscan.
* `mode` - The file mode for the ssh_known_hosts file.
* `owner`- The file owner for the ssh_known_hosts file.
* `group` - The file group for the ssh_known_hosts file.
* `hash_entries` - Hash the hostname and addresses in the ssh_known_hosts file for privacy.
* `file_location` - The location of the ssh known hosts file. Change this to set a known host file for a particular user.

## New `knife config get` command

The `knife config get` command has been added to help with debugging configuration issues with `knife` and other tools that use the `knife.rb` file.

With no arguments, it will display all options you've set:

```bash
$ knife config get
Loading from configuration file /Users/.../.chef/knife.rb
chef_server_url: https://...
client_key:      /Users/.../.chef/user.pem
config_file:     /Users/.../.chef/knife.rb
log_level:       warn
log_location:    STDERR
node_name:       ...
validation_key:
```

You can also pass specific keys to only display those `knife config get node_name client_key`, or use `--all` to display everything (including options that are using the default value).

## Simplification of `shell_out` APIs

The following helper methods have been deprecated in favor of the single shell_out helper:

* `shell_out_with_systems_locale`
* `shell_out_with_timeout`
* `shell_out_compact`
* `shell_out_compact_timeout`
* `shell_out_with_systems_locale!`
* `shell_out_with_timeout!`
* `shell_out_compact!`
* `shell_out_compact_timeout!`

The functionality of `shell_out_with_systems_locale` has been implemented using the `default_env: false` option that removes the PATH and locale mangling that has been the default behavior of `shell_out`.

The functionality of `shell_out_compact` has been folded into `shell_out`. The `shell_out` API when called with varargs has its arguments flatted, compacted and coerced to strings. This style of calling is encouraged over using strings and building up commands using `join(" ")` since it avoids shell interpolation and edge conditions in the construction of spaces between arguments. The varargs form is still not supported on Windows.

The functionality of `shell_out*timeout` has also been folded into `shell_out`. Users writing Custom Resources should be explicit for Chef-14: `shell_out!("whatever", timeout: new_resource.timeout)` which will become automatic in Chef-15.

## Silencing deprecation warnings

While deprecation warnings have been great for the Chef community to ensure cookbooks are kept up-to-date and to prepare for major version upgrades, sometimes you just can't fix a deprecation right now. This is often compounded by the recommendation to enable `treat_deprecation_warnings_as_errors` mode in your Test Kitchen integration tests, which doesn't understand the difference between deprecations from community cookbooks and those from your own code.

Two new options are provided for silencing deprecation warnings: `silence_deprecation_warnings` and inline `chef:silence_deprecation` comments.

The `silence_deprecation_warnings` configuration value can be set in your `client.rb` or `solo.rb` config file, either to `true` to silence all deprecation warnings or to an array of deprecations to silence. You can specify which to silence either by the deprecation key name (e.g. `"internal_api"`), the numeric deprecation ID (e.g. `25` or `"CHEF-25"`), or by specifying the filename and line number where the deprecation is being raised from (e.g. `"default.rb:67"`).

An example of setting the `silence_deprecation_warnings` option in your `client.rb` or `solo.rb`:

```ruby
silence_deprecation_warnings %w{deploy_resource chef-23 recipes/install.rb:22}
```

or in your `kitchen.yml`:

```yaml
provisioner:
  name: chef_solo
  solo_rb:
    treat_deprecation_warnings_as_errors: true
    silence_deprecation_warnings:
    - deploy_resource
    - chef-23
    - recipes/install.rb:22
```

You can also silence deprecations using a comment on the line that is raising the warning:

```ruby
erl_call 'something' do # chef:silence_deprecation
```

We advise caution in the use of this feature, as excessive or prolonged silencing can lead to difficulty upgrading when the next major release of Chef comes out.

## Misc Windows improvements

* A new `skip_publisher_check` property has been added to the `powershell_package` resource
* `windows_feature_powershell` now supports Windows 2008 R2
* The `mount` resource now supports the `mount_point` property on Windows
* `windows_feature_dism` no longer errors when specifying the source
* Resolved idempotency issues in the `windows_task` resource and prevented setting up a task with bad credentials
* `windows_service` no longer throws Ruby deprecation warnings

## Newly Introduced Deprecations

### CHEF-26: Deprecation of old shell_out APIs

As noted above, this release of Chef unifies our shell_out helpers into just shell_out and shell_out!. Previous helpers are now deprecated and will be removed in Chef Infra Client 15.

See [CHEF-26 Deprecation Page](https://docs.chef.io/deprecations_shell_out.html) for details.

### Legacy FreeBSD pkg provider

Chef Infra Client 15 will remove support for the legacy FreeBSD pkg format. We will continue to support the pkgng format introduced in FreeBSD 10.

# Chef Client Release Notes 14.2:

## `ssh-agent` support for user keys

You can now use `ssh-agent` to hold your user key when using knife. This allows storing your user key in an encrypted form as well as using `ssh -A` agent forwarding for running knife commands from remote devices.

You can enable this by adding `ssh_agent_signing true` to your `knife.rb` or `ssh_agent_signing = true` in your `credentials` file.

To encrypt your existing user key, you can use OpenSSL:

```
( openssl rsa -in user.pem -pubout && openssl rsa -in user.pem -aes256 ) > user_enc.pem
chmod 600 user_enc.pem
```

This will prompt you for a passphrase for to use to encrypt the key. You can then load the key into your `ssh-agent` by running `ssh-add user_enc.pem`. Make sure you add the `ssh_agent_signing` to your configuration, and update your `client_key` to point at the new, encrypted key (and once you've verified things are working, remember to delete your unencrypted key file).

## default_env Property in Execute Resource

The shell_out helper has been extended with a new option `default_env` to allow disabling Chef from modifying PATH and LOCALE environmental variables as it shells out. This new option defaults to true (modify the env), preserving the previous behavior of the helper.

The execute resource has also been updated with a new property `default_env` that allows utilizing this the ENV sanity functionality in shell_out. The new property defaults to false, but it can be set to true in order to ensure a sane PATH and LOCALE when shelling out. If you find that binaries cannot be found when using the execute resource, `default_env` set to true may resolve those issues.

## Small Size on Disk

Chef now bundles the inspec-core and train-core gems, which omit many cloud dependencies not needed within the Chef client. This change reduces the install size of a typical system by ~22% and the number of files within that installation by ~20% compared to Chef 14.1\. Enjoy the extra disk space.

## Virtualization detection on AWS

Ohai now detects the virtualization hypervisor `amazonec2` when running on Amazon's new C5/M5 instances.

# Chef Client Release Notes 14.1.12:

This release resolves a number of regressions in 14.1:

* `git` resource: don't use `--prune-tags` as it's really new.
* `rhsm_repo` resource: now works
* `apt_repository` resource: use the `repo_name` property to name files
* `windows_task` resource: properly handle commands with arguments
* `windows_task` resource: handle creating tasks as the SYSTEM user
* `remote_directory` resource: restore the default for the `overwrite` property

## Ohai 14.1.3

* Properly detect FIPS environments
* `shard` plugin: work in FIPS compliant environments
* `filesystem` plugin: Handle BSD platforms

# Chef Client Release Notes 14.1.1:

## Platform Additions

Enable Ubuntu-18.04 and Debian-9 tested chef-client packages.

# Chef Client Release Notes 14.1:

## Windows Task

The `windows_task` resource has been entirely rewritten. This resolves a large number of bugs, including being able to correctly set the start time of tasks, proper creation and deletion of tasks, and improves Chef's validation of tasks. The rewrite will also solve the idempotency problems that users have reported.

## build_essential

The `build_essential` resource no longer requires a name, similar to the `apt_update` resource.

## Ignore Failure

The `ignore_failure` property takes a new argument, `:quiet`, to suppress the error output when the resource does in fact fail.

## This release of Chef Client 14 resolves a number of regressions in 14.0

* On Windows, the installer now correctly re-extracts files during repair mode
* Fix a number of issues relating to use with Red Hat Satellite
* Git fetch now prunes remotes before running
* Fix locking and unlocking packages with apt and zypper
* Ensure we don't request every remote file when running with lazy loading enabled
* The sysctl resource correctly handles missing keys when used with `ignore_error`
* --recipe-url apparently never worked on Windows. Now it does.

## Security Updates

### ffi Gem

* CVE-2018-1000201: DLL loading issue which can be hijacked on Windows OS

# Ohai Release Notes 14.1:

## Configurable DMI Whitelist

The whitelist of DMI IDs is now user configurable using the `additional_dmi_ids` configuration setting, which takes an Array.

## Shard plugin

The Shard plugin has been returned to a default plugin rather than an optional one. To ensure we work in FIPS environments, the plugin will use SHA256 rather than MD5 in those environments.

## SCSI plugin

A new plugin to enumerate SCSI devices has been added. This plugin is optional.

# Chef Client Release Notes 14.0.202:

This release of Chef 14 resolves several regressions in the Chef 14.0 release.

* Resources contained in cookbooks would be used instead of built-in Chef client resources causing older resources to run
* Resources failed due to a missing `property_is_set?` and `resources` methods
* `yum_package` changed the order of `disablerepo` and `enablerepo` options
* Depsolving large numbers of cookbooks with chef zero/local took a very long time

# Chef Client Release Notes 14.0:

## New Resources

Chef 14 includes a large number of resources ported from community cookbooks. These resources have been tested, improved, and had their functionality expanded. With these new resources in the Chef Client itself, the need for external cookbook dependencies and dependency management has been greatly reduced.

### build_essential

Use the build_essential resource to install packages required for compiling C software from source. This resource was ported from the `build-essential` community cookbook.

`Note`: This resource no longer configures msys2 on Windows systems.

### chef_handler

Use the chef_handler resource to install or uninstall Chef reporting/exception handlers. This resource was ported from the `chef_handler` community cookbook.

### dmg_package

Use the dmg_package resource to install a dmg 'package'. The resource will retrieve the dmg file from a remote URL, mount it using hdiutil, copy the application (.app directory) to the specified destination (/Applications), and detach the image using hdiutil. The dmg file will be stored in the Chef::Config[:file_cache_path]. This resource was ported from the `dmg` community cookbook.

### homebrew_cask

Use the homebrew_cask resource to install binaries distributed via the Homebrew package manager. This resource was ported from the `homebrew` community cookbook.

### homebrew_tap

Use the homebrew_tap resource to add additional formula repositories to the Homebrew package manager. This resource was ported from the `homebrew` community cookbook.

### hostname

Use the hostname resource to set the system's hostname, configure hostname and hosts config file, and re-run the Ohai hostname plugin so the hostname will be available in subsequent cookbooks. This resource was ported from the `chef_hostname` community cookbook.

### macos_userdefaults

Use the macos_userdefaults resource to manage the macOS user defaults system. The properties of this resource are passed to the defaults command, and the parameters follow the convention of that command. See the defaults(1) man page for details on how the tool works. This resource was ported from the `mac_os_x` community cookbook.

### ohai_hint

Use the ohai_hint resource to pass hint data to Ohai to aid in configuration detection. This resource was ported from the `ohai` community cookbook.

### openssl_dhparam

Use the openssl_dhparam resource to generate dhparam.pem files. If a valid dhparam.pem file is found at the specified location, no new file will be created. If a file is found at the specified location but it is not a valid dhparam file, it will be overwritten. This resource was ported from the `openssl` community cookbook.

### openssl_rsa_private_key

Use the openssl_rsa_private_key resource to generate RSA private key files. If a valid RSA key file can be opened at the specified location, no new file will be created. If the RSA key file cannot be opened, either because it does not exist or because the password to the RSA key file does not match the password in the recipe, it will be overwritten. This resource was ported from the `openssl` community cookbook.

### openssl_rsa_public_key

Use the openssl_rsa_public_key resource to generate RSA public key files given a RSA private key. This resource was ported from the `openssl` community cookbook.

### rhsm_errata

Use the rhsm_errata resource to install packages associated with a given Red Hat Subscription Manager Errata ID. This is helpful if packages to mitigate a single vulnerability must be installed on your hosts. This resource was ported from the `redhat_subscription_manager` community cookbook.

### rhsm_errata_level

Use the rhsm_errata_level resource to install all packages of a specified errata level from the Red Hat Subscription Manager. For example, you can ensure that all packages associated with errata marked at a 'Critical' security level are installed. This resource was ported from the `redhat_subscription_manager` community cookbook.

### rhsm_register

Use the rhsm_register resource to register a node with the Red Hat Subscription Manager or a local Red Hat Satellite server. This resource was ported from the `redhat_subscription_manager` community cookbook.

### rhsm_repo

Use the rhsm_repo resource to enable or disable Red Hat Subscription Manager repositories that are made available via attached subscriptions. This resource was ported from the `redhat_subscription_manager` community cookbook.

### rhsm_subscription

Use the rhsm_subscription resource to add or remove Red Hat Subscription Manager subscriptions for your host. This can be used when a host's activation_key does not attach all necessary subscriptions to your host. This resource was ported from the `redhat_subscription_manager` community cookbook.

### sudo

Use the sudo resource to add or remove individual sudo entries using `sudoers.d` files. Sudo version 1.7.2 or newer is required to use the sudo resource, as it relies on the `#includedir` directive introduced in version 1.7.2\. This resource does not enforce installation of the required sudo version. Supported releases of Ubuntu, Debian, SuSE, and RHEL (6+) all support this feature. This resource was ported from the `sudo` community cookbook.

### swap_file

Use the swap_file resource to create or delete swap files on Linux systems, and optionally to manage the swappiness configuration for a host. This resource was ported from the `swap` community cookbook.

### sysctl

Use the sysctl resource to set or remove kernel parameters using the sysctl command line tool and configuration files in the system's `sysctl.d` directory. Configuration files managed by this resource are named 99-chef-KEYNAME.conf. If an existing value was already set for the value it will be backed up to the node and restored if the :remove action is used later. This resource was ported from the `sysctl` community cookbook.

`Note`: This resource no longer backs up existing key values to the node when changing values as we have done in the sysctl cookbook previously. The resource has also been renamed from `sysctl_param` to `sysctl` with backwards compatibility for the previous name.

### windows_ad_join

Use the windows_ad_join resource to join a Windows Active Directory domain and reboot the node. This resource is based on the `win_ad_client` resource in the `win_ad` community cookbook, but is not backwards compatible with that resource.

### windows_auto_run

Use the windows_auto_run resource to set applications to run at logon. This resource was ported from the `windows` community cookbook.

### windows_feature

Use the windows_feature resource to add, remove or delete Windows features and roles. This resource calls the `windows_feature_dism` or `windows_feature_powershell` resources depending on the specified installation method and defaults to dism, which is available on both Workstation and Server editions of Windows. This resource was ported from the `windows` community cookbook.

`Note`: These resources received significant refactoring in the 4.0 version of the windows cookbook (March 2018). windows_feature resources now fail if the installation of invalid features is requested and support for installation via server `servermanagercmd.exe` has been removed. If you are using a windows cookbook version less than 4.0 you may need to update cookbooks for Chef 14.

### windows_font

Use the windows_font resource to install or remove font files on Windows. By default, the font is sourced from the cookbook using the resource, but a URI source can be specified as well. This resource was ported from the `windows` community cookbook.

### windows_printer

Use the windows_printer resource to setup Windows printers. Note that this doesn't currently install a printer driver. You must already have the driver installed on the system. This resource was ported from the `windows` community cookbook.

### windows_printer_port

Use the windows_printer_port resource to create and delete TCP/IPv4 printer ports on Windows. This resource was ported from the `windows` community cookbook.

### windows_shortcut

Use the windows_shortcut resource to create shortcut files on Windows. This resource was ported from the `windows` community cookbook.

### windows_workgroup

Use the windows_workgroup resource to join a Windows Workgroup and reboot the node. This resource is based on the `windows_ad_join` resource.

## Custom Resource Improvements

We've expanded the DSL for custom resources with new functionality to better document your resources and help users with errors and upgrades. Many resources in Chef itself are now using this new functionality, and you'll see more updated to take advantage of this it in the future.

### Deprecations in Cookbook Resources

Chef 14 provides new primitives that allow you to deprecate resources or properties with the same functionality used for deprecations in Chef Client resources. This allows you make breaking changes to enterprise or community cookbooks with friendly notifications to downstream cookbook consumers directly in the Chef run.

Deprecate the foo_bar resource in a cookbook:

```ruby
deprecated "The foo_bar resource has been deprecated and will be removed in the next major release of this cookbook scheduled for 12/25/2018!"

property :thing, String, name_property: true

action :create do
 # you'd probably have some actual chef code here
end
```

Deprecate the thing2 property in a resource

```ruby
property :thing2, String, deprecated: 'The thing2 property has been deprecated and will be removed in the next major release of this cookbook scheduled for 12/25/2018!'
```

Rename a property with a deprecation warning for users of the old property name

```ruby
deprecated_property_alias 'thing2', 'the_second_thing', 'The thing2 property was renamed the_second_thing in the 2.0 release of this cookbook. Please update your cookbooks to use the new property name.'
```

### Platform Deprecations

chef-client no longer is built or tested on OS X 10.10 in accordance with Chef's EOL policy.

### validation_message

Validation messages allow you give the user a friendly error message when any validation on a property fails.

Provide a friendly message when a regex fails:

```ruby
property :repo_name, String, regex: [/^[^\/]+$/], validation_message: "The repo_name property cannot contain a forward slash '/'",
```

### Resource Documentation

You can now include documentation that describes how a resource is to be used. Expect this data to be consumed by Chef and other tooling in future releases.

A resource which includes description and introduced values in the resource, actions, and properties:

```ruby
description 'The apparmor_policy resource is used to add or remove policy files from a cookbook file'
introduced '14.1'

property :source_cookbook, String,
         description: 'The cookbook to source the policy file from'
property :source_filename, String,
         description: 'The name of the source file if it differs from the apparmor.d file being created'

action :add do
  description 'Adds an apparmor policy'

  # you'd probably have some actual chef code here
end
```

## Improved Resources

Many existing resources now include new actions and properties that expand their functionality.

### apt_package

`apt_package` includes a new `overwrite_config_files` property. Setting this new property to true is equivalent to passing `-o Dpkg::Options::="--force-confnew"` to apt, and allows you to install packages that prompt the user to overwrite config files. Thanks @ccope for this new property.

### env

The `env` resource has been renamed to `windows_env` as it only supports the Windows platform. Existing cookbooks using `env` will continue to function, but should be updated to use the new name.

### ifconfig

`ifconfig` includes a new `family` property for setting the network family on Debian systems. Thanks @martinisoft for this new property.

### registry_key

The `sensitive` property can now be used in `registry_key` to suppress the output of the key's data from logs and error messages. Thanks @shoekstra for implementing this.

### powershell_package

`powershell_package` includes a new `source` property to allow specifying the source of the package. Thanks @Happycoil for this new property.

### systemd_unit

`systemd_unit` includes the following new actions:

* `preset` - Restore the preset enable/disable configuration for a unit
* `revert` - Revert to a vendor's version of a unit file
* `reenable` - Reenable a unit file

Thanks @nathwill for these new actions.

### windows_service

`windows_service` now includes actions for fully managing services on Windows, in addition to the previous actions for starting/stopping/enabling services.

* `create` - Create a new service
* `delete` - Delete an existing service
* `configure` - Reconfigure an existing service

Thanks @jasonwbarnett for these new actions

### route

`route` includes a new `comment` property.

Thanks Thomas Doherty for adding this new property.

## Expanded Configuration Detection

Ohai has been expanded to collect more information than ever. This should make writing cross-platform and cross cloud cookbooks simpler.

### Windows Kernel information

The kernel plugin now reports the following information on Windows:

* `node['kernel']['product_type']` - Workstation vs. Server editions of Windows
* `node['kernel']['system_type']` - What kind of hardware are we installed on (Desktop, Mobile, Workstation, Enterprise Server, etc.)
* `node['kernel']['server_core']` - Are we on Windows Server Core edition?

### Cloud Detection

Ohai now detects the Scaleway cloud and provides additional configuration information for systems running on Azure.

### Virtualization / Container Detection

In addition to detecting if a system is a Docker host, we now provide a large amount of Docker configuration information available at `node['docker']`. This includes the release of Docker, installed plugins, network config, and the number of running containers.

Ohai also now properly detects LXD containers and macOS guests running on VirtualBox / VMware. This data is available in `node['virtualization']['systems']`.

### Optional Ohai Plugins

Ohai now includes the ability to mark plugins as optional, which skips those plugins by default. This allows us to ship additional plugins, which some users may find useful, but not all users want that data collected in the node object on a Chef server. The change introduces two new configuration options; `run_all_plugins` which runs everything including optional plugins, and `optional_plugins` which allows you to run plugins marked as optional.

By default we will now be marking the `lspci`, `sessions` `shard` and `passwd` plugins as optional. Passwd has been particularly problematic for nodes attached to LDAP or AD where it attempts to write the entire directory's contents to the node. If you previously disabled this plugin via Ohai config, you no longer need to. Hurray!

## Other Changes

### Ruby 2.5

Ruby has been updated to version 2.5 bringing a 10% performance improvement and improved functionality.

### InSpec 2.0

InSpec has been updated to the 2.0 release. InSpec 2.0 brings compliance automation to the cloud, with new resource types specifically built for AWS and Azure clouds. Along with these changes are major speed improvements and quality of life updates. Please visit <https://www.inspec.io/> for more information.

### Policyfile Hoisting

Many users of Policyfiles rely on "hoisting" to provide group specific attributes. This approach was formalized in the poise-hoist extension, and is now included in Chef 14.

To hoist an attribute, the user provides a default attribute structure in their Policyfile similar to:

```ruby
default['staging']['myapp']['title'] = "My Staging App" default['production']['myapp']['title'] = "My App"
```

and then accesses the node attribute in their cookbook as:

```ruby
node['myapp']['title']
```

The correct attribute is then provided based on the policy_group of the node, so with a policy_group of staging the attribute would contain "My Staging App".

### yum_package rewrite

yum_package received a ground up rewrite that greatly improves both the performance and functionality while also resolving a dozen existing issues. It introduces a new caching method that runs for the duration of the chef-client process. This caching method speeds up each package install and takes 1/2 the memory of the previous `yum-dump.py` process.

yum_package should now take any argument that `yum install` does and operate the same way, including version constraints "foo < 1.2.3" and globs "foo-1.2*" along with arches "foo.i386" and in combinations

Package with a version constraint:

```ruby
yum_package "foo < 1.2.3"
```

Installing a package via what it provides:

```ruby
yum_package "perl(Git)"
```

### powershell_exec Mixin

Since our supported Windows platforms can all run .NET Framework 4.0 and PowerShell 4.0 we have taken time to add a new helper that will allow for faster and safer interactions with the system PowerShell. You will be able to use the powershell_exec mixin in most places where you would have previously used powershell_out. For comparison, a basic benchmark test to return the $PSVersionTable 100 times completed 7.3X faster compared to the powershell_out method. The majority of the time difference is because of less time spent in invocation. So we believe it has big future potential where multiple calls to PowerShell are required inside (for example) a custom resource. Many core Chef resources will be updated to use this new mixin in future releases.

### Logging Improvements

Chef now includes a new log level of `:trace` in addition to the existing `:info`, `:warn`, and `:debug` levels. With the introduction of `trace` level logging we've moved a large amount of logging that is more useful for Chef developers from `debug` to `trace`. This makes it easier for Chef Cookbook developers to use `debug` level to get useful information.

## Security Updates

### OpenSSL

OpenSSL has been updated to 1.0.2o to resolve [CVE-2018-0739](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-0739)

### Ruby

Ruby has been updated to 2.5.1 to resolve the following vulnerabilities:

* [cve-2017-17742](https://www.ruby-lang.org/en/news/2018/03/28/http-response-splitting-in-webrick-cve-2017-17742/)
* [cve-2018-6914](https://www.ruby-lang.org/en/news/2018/03/28/unintentional-file-and-directory-creation-with-directory-traversal-cve-2018-6914/)
* [cve-2018-8777](https://www.ruby-lang.org/en/news/2018/03/28/large-request-dos-in-webrick-cve-2018-8777/)
* [cve-2018-8778](https://www.ruby-lang.org/en/news/2018/03/28/buffer-under-read-unpack-cve-2018-8778/)
* [cve-2018-8779](https://www.ruby-lang.org/en/news/2018/03/28/poisoned-nul-byte-unixsocket-cve-2018-8779/)
* [cve-2018-8780](https://www.ruby-lang.org/en/news/2018/03/28/poisoned-nul-byte-dir-cve-2018-8780/)
* [Multiple vulnerabilities in rubygems](https://www.ruby-lang.org/en/news/2018/02/17/multiple-vulnerabilities-in-rubygems/)

## Breaking Changes

This release completes the deprecation process for many of the deprecations that were warnings throughout the Chef 12 and Chef 13 releases.

### erl_call Resource

The erl_call resource was deprecated in Chef 13.7 and has been removed.

### deploy Resource

The deploy resource was deprecated in Chef 13.6 and been removed. If you still require this resource, it is available in the new `deploy_resource` cookbook at <https://supermarket.chef.io/cookbooks/deploy_resource>

### Windows 2003 Support

Support for Windows 2003 has been removed from both Chef and Ohai, improving the performance of Chef on Windows hosts.

### knife deprecations

* `knife bootstrap` options `--distro` and `--template_file` flags were deprecated in Chef 12 and have now been removed.
* `knife help` functionality that read legacy Chef manpages has been removed as the manpages had not been updated and were often quite wrong. Running knife help will now simply show the help menu.
* `knife index rebuild` has been removed as reindexing Chef Server was only necessary on releases prior to Chef Server 11.
* The `knife ssh --identity-file` flag was deprecated and has been removed. Users should use the `--ssh_identity_file` flag instead.
* `knife ssh csshx` was deprecated in Chef 10 and has been removed. Users should use `knife ssh cssh` instead.

### Chef Solo `-r` flag

The Chef Solor `-r` flag has been removed as it was deprecated and replaced with the `--recipe-url` flag in Chef 12.

### node.set and node.set_unless attribute levels removal

`node.set` and `node.set_unless` were deprecated in Chef 12 and have been removed in Chef 14\. To replicate this same functionality users should use `node.normal` and `node.normal_unless`, although we highly recommend reading our [attribute documentation](https://docs.chef.io/attributes.html) to make sure `normal` is in fact the your desired attribute level.

### chocolatey_package :uninstall Action

The chocolatey_package resource in the chocolatey cookbook supported an `:uninstall` action. When this resource was moved into the Chef Client we allowed this action with a deprecation warning. This action is now removed.

### Property names not using new_resource.NAME

Previously if a user wrote a custom resource with a property named `foo` they could reference it throughout the resource using the name `foo`. This caused multiple edge cases where the property name could conflict with resources or methods in Chef. Properties now must be referenced as `new_resource.foo`. This was already the case when writing LWRPs.

### epic_fail

The original name for the `ignore_failure` property in resource was `epic_fail`. The legacy name has been removed.

### Legacy Mixins

Several legacy mixins mostly used in older HWRPs have been removed. Usage of these mixins has resulted in deprecation warnings for several years and they are rarely used in cookbooks available on the Supermarket.

* Chef::Mixin::LanguageIncludeAttribute
* Chef::Mixin::RecipeDefinitionDSLCore
* Chef::Mixin::LanguageIncludeRecipe
* Chef::Mixin::Language
* Chef::DSL::Recipe::FullDSL

### cloud_v2 and filesystem2 Ohai Plugins

In Chef 13 the `cloud_v2` plugin replaced data at `node['cloud']` and `filesystem2` replaced data at `node['filesystem']`. For compatibility with cookbooks that were previously using the "v2" data we continued to write data to both locations (ie: both node['filesystem'] and node['filesystem2']). We now no longer write data to the "v2" locations which greatly reduces the amount of data we need to store on the Chef server.

### Ipscopes Ohai Plugin Removed

The ipscopes plugin has been removed as it duplicated data already present in the network plugins and required the user to install an additional gem into the Chef installation.

### Ohai libvirt attributes moved

The libvirt Ohai plugin now writes data to `node['libvirt']` instead of writing to various locations in `node['virtualization']`. This plugin required installing an additional gem into the Chef installation and thus was infrequently used.

### Ohai Plugin V6 Support Removed

In 2014 we introduced Ohai v7 with a greatly improved plugin format. With Chef 14 we no longer support loading of the legacy "v6" plugin format.

### Newly-disabled Ohai Plugins

As mentioned above we now support an `optional` flag for Ohai plugins and have marked the `sessions`, `lspci`, and `passwd` plugins as optional, which disables them by default. If you need one of these plugins you can include them using `optional_plugins`.

optional_plugins in the client.rb file:

```ruby
optional_plugins [ "lspci", "passwd" ]
```

# Chef Client Release Notes 13.12.14

## Bugfixes

* The mount provider now properly adds blank lines between fstab entries on AIX
* Ohai now reports itself as Ohai well communicating with GCE metadata endpoints
* Property deprecations in custom resources no longer result in an error. Thanks for reporting this [martinisoft](https://github.com/martinisoft)
* mixlib-archive has been updated to prevent corruption of archives on Windows systems

## Updated Components

* libxml2 2.9.7 -> 2.9.9
* ca-certs updated to 2019-01-22 for new roots
* nokogiri 1.8.5 -> 1.10.1

## Security Updates

### OpenSSL

OpenSSL has been updated to 1.0.2r in order to resolve [CVE-2019-1559](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-1559) and [CVE-2018-5407](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-5407)

### RubyGems

RubyGems has been updated to 2.7.9 in order to resolve the following CVEs:
  - [CVE-2019-8320](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-8320): Delete directory using symlink when decompressing tar
  - [CVE-2019-8321](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-8321): Escape sequence injection vulnerability in verbose
  - [CVE-2019-8322](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-8322): Escape sequence injection vulnerability in gem owner
  - [CVE-2019-8323](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-8323): Escape sequence injection vulnerability in API response handling
  - [CVE-2019-8324](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-8324): Installing a malicious gem may lead to arbitrary code execution
  - [CVE-2019-8325](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-8325): Escape sequence injection vulnerability in errors

# Chef Client Release Notes 13.12.3

## Smaller Package and Install Size

We trimmed unnecessary installation files, greatly reducing the sizes of both Chef packages and on disk installations. MacOS/Linux/FreeBSD packages are ~50% smaller and Windows are ~12% smaller. Chef 13 is now smaller than a legacy Chef 10 package.

## macOS Mojave (10.14)

Chef is now tested against macOS Mojave and packages are now available at downloads.chef.io.

## SUSE Linux Enterprise Server 15

* Ohai now properly detects SLES 15
* The Chef package will no longer remove symlinks to chef-client and ohai when upgrading on SLES 15

## Updated Chef-Vault

Updating chef-vault to 3.4.2 resolved multiple bugs.

## Faster Windows Installations

Improved Windows installation speed by skipping unnecessary steps when Windows Installer 5.0 or later is available.

## Ohai Release Notes 13.12

### macOS Improvements

* sysctl commands have been modified to gather only the bare minimum required data, which prevents sysctl hanging in some scenarios
* Extra data has been removed from the system_profile plugin, reducing the amount of data stored on the chef-server for each node

## New Deprecations

### system_profile Ohai plugin removal

The system_profile plugin will be removed from Chef/Ohai 15 in April, 2019. This plugin incorrectly returns data on modern Mac systems. Further, the hardware plugin returns the same data in a more readily consumable format. Removing this plugin reduces the speed of the Ohai return by ~3 seconds and also greatly reduces the node object size on the Chef server

### ohai_name property in ohai resource

The ``ohai`` resource's unused ``ohai_name`` property has been deprecated. This will be removed in Chef Infra Client 15.0.

## Security Updates

### Ruby 2.4.5

Ruby has been updated to from 2.4.4 to 2.4.5 to resolve multiple CVEs as well as bugs:
* [CVE-2018-16396](https://www.ruby-lang.org/en/news/2018/10/17/not-propagated-taint-flag-in-some-formats-of-pack-cve-2018-16396/)
* [CVE-2018-16395](https://www.ruby-lang.org/en/news/2018/10/17/openssl-x509-name-equality-check-does-not-work-correctly-cve-2018-16395/)

# Chef Client Release Notes 13.11

### Sensitive Properties on Windows

* `windows_service` no longer logs potentially sensitive information when a service is setup
* `windows_package` now respects the `sensitive` property to avoid logging sensitive data in the event of a package installation failure

### Other Fixes

* `remote_directory` now properly loads files in the root of a cookbook's `files` directory
* `osx_profile` now uses the full path the profiles CLI tool to avoid running other binaries of the same name in a users path
* `package` resources that don't support the `allow_downgrade` property will no longer fail
* `knife bootstrap windows` error messages have been improved

## Security Updates

### OpenSSL

* OpenSSL has been updated to 1.0.2p to resolve [CVE-2018-0732](https://nvd.nist.gov/vuln/detail/CVE-2018-0732) and [CVE-2018-0737](https://nvd.nist.gov/vuln/detail/CVE-2018-0737)

### Rubyzip

* Updated Rubyzip to 1.2.2 to resolve [CVE-2018-1000544](https://nvd.nist.gov/vuln/detail/CVE-2018-1000544)

# Chef Client Release Notes 13.10

## Bugfixes

* Resolves a duplicate logging getting created when redirecting stdout
* Using --recipe-url with a local file on Windows no longer fails
* Service resource no longer throws Ruby deprecation warnings on Windows

## Ohai 13.10 Improvements

* Correctly identify the platform_version on the final release of Amazon Linux 2.0
* Detect nodes with the DMI data of "OpenStack Compute" as being OpenStack nodes

## Security Updates

### ffi Gem

* CVE-2018-1000201: DLL loading issue which can be hijacked on Windows OS

# Chef Client Release Notes 13.9.X:

## Security Updates

Ruby has been updated to 2.4.4

* CVE-2017-17742: HTTP response splitting in WEBrick
* CVE-2018-6914: Unintentional file and directory creation with directory traversal in tempfile and tmpdir
* CVE-2018-8777: DoS by large request in WEBrick
* CVE-2018-8778: Buffer under-read in String#unpack
* CVE-2018-8779: Unintentional socket creation by poisoned NUL byte in UNIXServer and UNIXSocket
* CVE-2018-8780: Unintentional directory traversal by poisoned NUL byte in Dir
* Multiple vulnerabilities in RubyGems

Nokogiri has been updated to 1.8.2

* [MRI] Behavior in libxml2 has been reverted which caused CVE-2018-8048 (loofah gem), CVE-2018-3740 (sanitize gem), and CVE-2018-3741 (rails-html-sanitizer gem).

OpenSSL has been updated to 1.0.2o

* CVE-2018-0739: Constructed ASN.1 types with a recursive definition could exceed the stack.

## Platform Updates

As Debian 7 is now end of life we will no longer produce Debian 7 chef-client packages.

## Ifconfig on Ubuntu 18.04

Incompatibilities with Ubuntu 18.04 in the ifconfig resource have been resolved.

## Ohai Updated to 13.9.2

### Virtualization detection on AWS

Ohai now detects the virtualization hypervisor `amazonec2` when running on Amazon's new C5/M5 instances.

### Configurable DMI Whitelist

The whitelist of DMI IDs is now user configurable using the `additional_dmi_ids` configuration setting, which takes an Array.

### Filesystem2 on BSD

The Filesystem2 functionality has been backported to BSD systems to provide a consistent filesystem format.

# Chef Client Release Notes 13.9.1:

## Platform Additions

Enable Ubuntu-18.04 and Debian-9 tested chef-client packages.

# Chef Client Release Notes 13.9:

* On Windows, the installer now correctly re-extracts files during repair mode
* The mount resource will now not create duplicate entries when the device type differs
* Ensure we don't request every remote file when running with lazy loading enabled
* Don't crash when getting the access rights for Windows system accounts

## Custom Resource Improvements

We've expanded the DSL for custom resources with new functionality to better document your resources and help users with errors and upgrades. Many resources in Chef itself are now using this new functionality, and you'll see more updated to take advantage of this it in the future.

### Deprecations in Cookbook Resources

Chef 13 provides new primitives that allow you to deprecate resources or properties with the same functionality used for deprecations in Chef Client resources. This allows you make breaking changes to enterprise or community cookbooks with friendly notifications to downstream cookbook consumers directly in the Chef run.

Deprecate the foo_bar resource in a cookbook:

```ruby
deprecated "The foo_bar resource has been deprecated and will be removed in the next major release of this cookbook scheduled for 12/25/2018!"

property :thing, String, name_property: true

action :create do
 # you'd probably have some actual chef code here
end
```

Deprecate the thing2 property in a resource

```ruby
property :thing2, String, deprecated: 'The thing2 property has been deprecated and will be removed in the next major release of this cookbook scheduled for 12/25/2018!'
```

Rename a property with a deprecation warning for users of the old property name

```ruby
deprecated_property_alias 'thing2', 'the_second_thing', 'The thing2 property was renamed the_second_thing in the 2.0 release of this cookbook. Please update your cookbooks to use the new property name.'
```

### validation_message

Validation messages allow you give the user a friendly error message when any validation on a property fails.

Provide a friendly message when a regex fails:

```ruby
property :repo_name, String, regex: [/^[^\/]+$/], validation_message: "The repo_name property cannot contain a forward slash '/'",
```

### Resource Documentation

You can now include documentation that describes how a resource is to be used. Expect this data to be consumed by Chef and other tooling in future releases.

A resource which includes description and introduced values in the resource, actions, and properties:

```ruby
description 'The apparmor_policy resource is used to add or remove policy files from a cookbook file'
introduced '14.1'

property :source_cookbook, String,
         description: 'The cookbook to source the policy file from'
property :source_filename, String,
         description: 'The name of the source file if it differs from the apparmor.d file being created'

action :add do
  description 'Adds an apparmor policy'

  # you'd probably have some actual chef code here
end
```

# Ohai Release Notes 13.9:

* Fix uptime parsing on AIX
* Fix Softlayer cloud detection
* Use the current Azure metadata endpoint
* Correctly detect macOS guests on VMware and VirtualBox

# Chef Client Release Notes 13.8:

## Revert attributes changes from 13.7

Per <https://discourse.chef.io/t/regression-in-chef-client-13-7-16/12518/1> , there was a regression in how arrays and hashes were handled in 13.7\. In 13.8, we've reverted to the same code as 13.6.

## Continuing work on `windows_task`

13.8 has better validation for the `idle_time` property, when using the `on_idle` frequency.

## Security Updates

* Updated libxml2 to 2.9.7; fixes: CVE-2017-15412

# Chef Client Release Notes 13.7:

## The `windows_task` Resource should be better behaved

We've spent a considerable amount of time testing and fixing the `windows_task` resource to ensure that it is properly idempotent and correct in more situations.

## Credentials handling

Previously, chef on the workstation used `knife.rb` or `config.rb` to handle credentials. This didn't do a great job when interacting with multiple Chef servers, leading to the need for tools like `knife_block`. We've added support for a credentials file that can contain configuration for many Chef servers (or organizations), and we've made it easy to indicate which account you mean to use.

## New deprecations

### `erl_call` Resource

We introduced `erl_call` to help us to manage CouchDB servers back in the olden times of Chef. Since then, we've noticed that no-one uses it, and so `erl_call` will be removed in Chef 14\. Foodcritic rule FC105 has been introduced to detect usage of erl_call.

### epic_fail

The original name for the ignore_failure property in resources was epic_fail. Our documentation hasn't referred to epic_fail for years and out of the 3500 cookbooks on the Supermarket only one uses epic_fail. In Chef 14 we will remove the epic_fail property entirely. Foodcritic rule FC107 has been introduced to detect usage of epic_fail.

### Legacy Mixins

In Chef 14 several legacy legacy mixins will be removed. Usage of these mixins has resulted in deprecation warnings for several years. They were traditionally used in some HWRPs, but are rarely found in code available on the Supermarket. Foodcritic rules FC097, FC098, FC099, FC100, and FC102 have been introduced to detect these mixins.

* Chef::Mixin::LanguageIncludeAttribute
* Chef::Mixin::RecipeDefinitionDSLCore
* Chef::Mixin::LanguageIncludeRecipe
* Chef::Mixin::Language
* Chef::DSL::Recipe::FullDSL

### :uninstall action in chocolatey_package

The chocolatey cookbook's chocolatey_package resource originally contained an :uninstall action. When chocolatey_package was moved into core Chef we made :uninstall an alias for :remove. In Chef 14 :uninstall will no longer be a valid action. Foodcritic rule FC103 has been introduced to detect the usage of the :uninstall action.

## Bugfixes

* Resolved a bug where knife commands that prompted on Windows would never display the prompt
* Fixed hiding of sensitive resources when converge_if_changed was used
* Fixed scenarios where services would fail to start on Solaris

## Security Updates

* OpenSSL has been upgraded to 1.0.2n to resolve CVE-2017-3738, CVE-2017-3737, CVE-2017-3736, and CVE-2017-3735.
* Ruby has been upgraded to 2.4.3 to resolve CVE-2017-17405

## Ohai 13.7 Release Notes:

### Network Tunnel Information

The Network plugin on Linux hosts now gathers additional information on tunnels

### LsPci Plugin

The new LsPci plugin provides a `node[:pci]` hash with information about the PCI bus based on `lspci`. Only runs on Linux.

### EC2 C5 Detection

The EC2 plugin has been updated to properly detect the new AWS hypervisor used in the C5 instance types

### mdadm

The mdadm plugin has been updated to properly handle arrays with more than 10 disks and to properly handle journal and spare drives in the disk counts

# Chef Client Release Notes 13.6.4:

## Bugfixes

* Resolved a regression in 13.6.0 that prevented upgrading packages on Debian/Ubuntu when the package name contained a tilde.

## Security Updates

* OpenSSL has been upgraded to 1.0.2m to resolve CVE-2017-3735 and CVE-2017-3736
* RubyGems has been upgraded to 2.6.14 to resolve CVE-2017-0903

# Chef Client Release Notes 13.6:

## `deploy` Resource Is Deprecated

The `deploy` resource (and its alter ego `deploy_revision`) have been deprecated, to be removed in Chef 14\. This is being done because this resource is considered overcomplicated and error-prone in the modern Chef ecosystem. A compatibility cookbook will be available to help users migrate during the Chef 14 release cycle. See [the deprecation documentation](https://docs.chef.io/deprecations_deploy_resource.html) for more information.

## zypper_package supports package downgrades

`zypper_package` now supports downgrading installed packages with the `allow_downgrade` property.

## InSpec updated to 1.42.3

## Reserve certain Data Bag names

It's no longer possible to create data bags named `node`, `role`, `client`, or `environment`. Existing data bags will continue to work as before.

## Properly use yum on RHEL 7

If both dnf and yum were installed, in some circumstances the yum provider might choose to run dnf, which is not what we intended it to do. It now properly runs yum, all the time.

## Ohai 13.6 Release Notes:

### Critical Plugins

Users can now specify a list of plugins which are `critical`. Critical plugins will cause Ohai to fail if they do not run successfully (and thus cause a Chef run using Ohai to fail). The syntax for this is:

```
ohai.critical_plugins << :Filesystem
```

### Filesystem now has a `allow_partial_data` configuration option

The Filesystem plugin now has a `allow_partial_data` configuration option. If set, the filesystem will return whatever data it can even if some commands it ran failed.

### Rackspace detection on Windows

Windows nodes running on Rackspace will now properly detect themselves as running on Rackspace without a hint file.

### Package data on Amazon Linux

The Packages plugin now supports gathering packages data on Amazon Linux

### Deprecation updates

In Ohai 13 we replaced the filesystem and cloud plugins with the filesystem2 and cloud_v2 plugins. To maintain compatibility with users of the previous V2 plugins we write data to both locations. We had originally planned to continue writing data to both locations until Chef Infra Client 15. Instead due to the large amount of duplicate node data this introduces we are updating OHAI-11 and OHAI-12 deprecations to remove node['cloud_v2'] and node['filesystem2'] with the release of Chef 14 in April 2018.

# Chef Client Release Notes 13.5:

## Mount's password property is now marked as sensitive

This means that passwords passed to mount won't show up in logs.

## The `windows_task` resource now correctly handles `start_day`

Previously, the resource would accept any date that was formatted correctly in the local locale, unlike the Windows cookbook and Windows itself. We now only support the `MM/DD/YYYY` format, in common with the Windows cookbook.

## InSpec updated to 1.39.1

## Ohai 13.5 Release Notes:

### Correctly detect IPv6 routes ending in ::

Previously we would ignore routes that ended `::`, and now we properly detect them.

### Plugin run time is now measured

Debug logs will show the length of time each plugin takes to run, making debugging of long ohai runs easier.

# Chef Client Release Notes 13.4:

## Security release of Ruby

Chef Client 13.4 includes Ruby 2.4.2 to fix the following CVEs:

* CVE-2017-0898
* CVE-2017-10784
* CVE-2017-14033
* CVE-2017-14064

## Security release of RubyGems

Chef Client 13.4 includes RubyGems 2.6.13 to fix the following CVEs:

* CVE-2017-0899
* CVE-2017-0900
* CVE-2017-0901
* CVE-2017-0902

## Ifconfig provider on Red Hat now supports additional properties

It is now possible to set `ETHTOOL_OPTS`, `BONDING_OPTS`, `MASTER` and `SLAVE` properties on interfaces on Red Hat compatible systems. See <https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/s1-networkscripts-interfaces.html> for further information

### Properties

* `ethtool_opts`<br>
  **Ruby types:** String<br>
  **Platforms:** Fedora, RHEL, Amazon Linux A string containing arguments to ethtool. The string will be wrapped in double quotes, so ensure that any needed quotes in the property are surrounded by single quotes

* `bonding_opts`<br>
  **Ruby types:** String<br>
  **Platforms:** Fedora, RHEL, Amazon Linux A string containing configuration parameters for the bonding device.

* `master`<br>
  **Ruby types:** String<br>
  **Platforms:** Fedora, RHEL, Amazon Linux The channel bonding interface that this interface is linked to.

* `slave`<br>
  **Ruby types:** String<br>
  **Platforms:** Fedora, RHEL, Amazon Linux Whether the interface is controlled by the channel bonding interface defined by `master`, above.

## Chef Vault is now included

Chef Client 13.4 now includes the `chef-vault` gem, making it easier for users of chef-vault to use their encrypted items.

## Windows `remote_file` resource with alternate credentials

The `remote_file` resource now supports the use of credentials on Windows when accessing a remote UNC path on Windows such as `\\myserver\myshare\mydirectory\myfile.txt`. This allows access to the file at that path location even if the Chef client process identity does not have permission to access the file. The new properties `remote_user`, `remote_domain`, and `remote_password` may be used to specify credentials with access to the remote file so that it may be read.

**Note**: This feature is mainly used for accessing files between two nodes in different domains and having different user accounts. In case the two nodes are in same domain, `remote_file` resource does not need `remote_user` and `remote_password` specified because the user has the same access on both systems through the domain.

### Properties

The following properties are new for the `remote_file` resource:

* `remote_user`<br>
  **Ruby types:** String<br>
  _Windows only:_ The user name of a user with access to the remote file specified by the `source` property. Default value: `nil`. The user name may optionally be specifed with a domain, i.e. `domain\user` or `user@my.dns.domain.com` via Universal Principal Name (UPN) format. It can also be specified without a domain simply as `user` if the domain is instead specified using the `remote_domain` attribute. Note that this property is ignored if `source` is not a UNC path. If this property is specified, the `remote_password` property **must** be specified.

* `remote_password`<br>
  **Ruby types** String<br>
  _Windows only:_ The password of the user specified by the `remote_user` property. Default value: `nil`. This property is mandatory if `remote_user` is specified and may only be specified if `remote_user` is specified. The `sensitive` property for this resource will automatically be set to `true` if `remote_password` is specified.

* `remote_domain`<br>
  **Ruby types** String<br>
  _Windows only:_ The domain of the user user specified by the `remote_user` property. Default value: `nil`. If not specified, the user and password properties specified by the `remote_user` and `remote_password` properties will be used to authenticate that user against the domain in which the system hosting the UNC path specified via `source` is joined, or if that system is not joined to a domain it will authenticate the user as a local account on that system. An alternative way to specify the domain is to leave this property unspecified and specify the domain as part of the `remote_user` property.

### Examples

Accessing file from a (different) domain account

```ruby
remote_file "E://domain_test.txt"  do
  source  "\\\\myserver\\myshare\\mydirectory\\myfile.txt"
  remote_domain "domain"
  remote_user "username"
  remote_password "password"
end
```

OR

```ruby
remote_file "E://domain_test.txt"  do
  source  "\\\\myserver\\myshare\\mydirectory\\myfile.txt"
  remote_user "domain\\username"
  remote_password "password"
end
```

Accessing file using a local account on the remote machine

```ruby
remote_file "E://domain_test.txt"  do
  source  "\\\\myserver\\myshare\\mydirectory\\myfile.txt"
  remote_domain "."
  remote_user "username"
  remote_password "password"
end
```

OR

```ruby
remote_file "E://domain_test.txt"  do
  source  "\\\\myserver\\myshare\\mydirectory\\myfile.txt"
  remote_user ".\\username"
  remote_password "password"
end
```

## windows_path resource

`windows_path` resource has been moved to core chef from windows cookbook. Use the `windows_path` resource to manage the path environment variable on Microsoft Windows.

### Actions

* `:add` - Add an item to the system path
* `:remove` - Remove an item from the system path

### Properties

* `path` - Name attribute. The name of the value to add to the system path

### Examples

Add Sysinternals to the system path

```ruby
windows_path 'C:\Sysinternals' do
  action :add
end
```

Remove 7-Zip from the system path

```ruby
windows_path 'C:\7-Zip' do
  action :remove
end
```

## Ohai Release Notes 13.4

### Windows EC2 Detection

Detection of nodes running in EC2 has been greatly improved and should now detect nodes 100% of the time including nodes that have been migrated to EC2 or were built with custom AMIs.

### Azure Metadata Endpoint Detection

Ohai now polls the new Azure metadata endpoint, giving us additional configuration details on nodes running in Azure

Sample data now available under azure:

```javascript
{
  "metadata": {
    "compute": {
      "location": "westus",
      "name": "timtest",
      "offer": "UbuntuServer",
      "osType": "Linux",
      "platformFaultDomain": "0",
      "platformUpdateDomain": "0",
      "publisher": "Canonical",
      "sku": "17.04",
      "version": "17.04.201706191",
      "vmId": "8d523242-71cf-4dff-94c3-1bf660878743",
      "vmSize": "Standard_DS1_v2"
    },
    "network": {
      "interfaces": {
        "000D3A33AF03": {
          "mac": "000D3A33AF03",
          "public_ipv6": [

          ],
          "public_ipv4": [
            "52.160.95.99",
            "23.99.10.211"
          ],
          "local_ipv6": [

          ],
          "local_ipv4": [
            "10.0.1.5",
            "10.0.1.4",
            "10.0.1.7"
          ]
        }
      },
      "public_ipv4": [
        "52.160.95.99",
        "23.99.10.211"
      ],
      "local_ipv4": [
        "10.0.1.5",
        "10.0.1.4",
        "10.0.1.7"
      ],
      "public_ipv6": [

      ],
      "local_ipv6": [

      ]
    }
  }
}
```

### Package Plugin Supports Arch Linux

The Package plugin has been updated to include package information on Arch Linux systems.

# Chef Client Release Notes 13.3:

## Unprivileged Symlink Creation on Windows

Chef can now create symlinks without privilege escalation, which allows for the creation of symlinks on Windows 10 Creator Update.

## nokogiri Gem

The nokogiri gem is once again bundled with the omnibus install of Chef

## zypper_package Options

It is now possible to pass additional options to the zypper in the zypper_package resource. This can be used to pass any zypper CLI option

### Example:

```ruby
zypper_package 'foo' do
  options '--user-provided'
end
```

## windows_task Improvements

The `windows_task` resource now properly allows updating the configuration of a scheduled task when using the `:create` action. Additionally the previous `:change` action from the windows cookbook has been aliased to `:create` to provide backwards compatibility.

## apt_preference Resource

The apt_preference resource has been ported from the apt cookbook. This resource allows for the creation of APT preference files controlling which packages take priority during installation.

Further information regarding apt-pinning is available via <https://wiki.debian.org/AptPreferences> and <https://manpages.debian.org/stretch/apt/apt_preferences.5.en.html>

### Actions

* `:add`: creates a preferences file under /etc/apt/preferences.d
* `:remove`: Removes the file, therefore unpin the package

### Properties

* `package_name`: name attribute. The name of the package
* `glob`: Pin by glob() expression or regexp surrounded by /.
* `pin`: The package version/repository to pin
* `pin_priority`: The pinning priority aka "the highest package version wins"

### Examples

Pin libmysqlclient16 to version 5.1.49-3:

```ruby
apt_preference 'libmysqlclient16' do
  pin          'version 5.1.49-3'
  pin_priority '700'
end
```

Unpin libmysqlclient16:

```ruby
apt_preference 'libmysqlclient16' do
  action :remove
end
```

Pin all packages from dotdeb.org:

```ruby
apt_preference 'dotdeb' do
  glob         '*'
  pin          'origin packages.dotdeb.org'
  pin_priority '700'
end
```

## zypper_repository Resource

The zypper_repository resource allows for the creation of Zypper package repositories on SUSE Enterprise Linux and openSUSE systems. This resource maintains full compatibility with the resource in the existing [zypper](https://supermarket.chef.io/cookbooks/zypper) cookbooks

### Actions

* `:add` - adds a repo
* `:delete` - removes a repo

### Properties

* `repo_name` - repository name if different from the resource name (name property)
* `type` - the repository type. default: 'NONE'
* `description` - the description of the repo that will be shown in `zypper repos`
* `baseurl` - the base url of the repo
* `path` - the relative path from the `baseurl`
* `mirrorlist` - the url to the mirrorlist to use
* `gpgcheck` - should we gpg check the repo (true/false). default: true
* `gpgkey` - location of repo key to import
* `priority` - priority of the repo. default: 99
* `autorefresh` - should the repository be automatically refreshed (true/false). default: true
* `keeppackages` - should packages be saved (true/false). default: false
* `refresh_cache` - should package cache be refreshed (true/false). default: true
* `enabled` - should this repository be enabled (true/false). default: true
* `mode` - the file mode of the repository file. default: "0644"

### Examples

Add the Apache repository for openSUSE Leap 42.2

```ruby
zypper_repository 'apache' do
  baseurl 'http://download.opensuse.org/repositories/Apache'
  path '/openSUSE_Leap_42.2'
  type 'rpm-md'
  priority '100'
end
```

## Ohai Release Notes 13.3:

### Additional Platform Support

Ohai now properly detects the [F5 Big-IP](https://www.f5.com/) platform and platform_version.

* platform: bigip
* platform_family: rhel

# Chef Client Release Notes 13.2:

## Properly send policyfile data

When sending events back to the Chef Server, we now correctly expand the run_list for nodes that use Policyfiles. This allows Automate to correctly report the node.

## Reconfigure between runs when daemonized

When Chef performs a reconfigure, it re-reads the configuration files. It also re-opens its log files, which facilitates log file rotation.

Chef normally will reconfigure when sent a HUP signal. As of this release if you send a HUP signal while it is converging, the reconfigure happens at the end of the run. This is avoids potential Ruby issues when the configuration file contains additional Ruby code that is executed. While the daemon is sleeping between runs, sending a SIGHUP will still cause an immediate reconfigure.

Additionally, Chef now always performs a reconfigure after every run when daemonized.

## New Deprecations

### Explicit property methods

<https://docs.chef.io/deprecations_namespace_collisions.html>

In Chef 14, custom resources will no longer assume property methods are being called on `new_resource`, and instead require the resource author to be explicit.

# Ohai Release Notes 13.2:

Ohai 13.2 has been a fantastic release in terms of community involvement with new plugins, platform support, and critical bug fixes coming from community members. A huge thank you to msgarbossa, albertomurillo, jaymzh, and davide125 for their work.

## New Features

### Systemd Paths Plugin

A new plugin has been added to expose system and user paths from systemd-path (see <https://www.freedesktop.org/software/systemd/man/systemd-path.html> for details).

### Linux Network, Filesystem, and Mdadm Plugin Resilience

The Network, Filesystem, and Mdadm plugins have been improved to greatly reduce failures to collect data. The Network plugin now better finds the binaries it requires for shelling out, filesystem plugin utilizes data from multiple sources, and mdadm handles arrays in bad states.

### Zpool Plugin Platform Expansion

The Zpool plugin has been updated to support BSD and Linux in addition to Solaris.

### RPM version parsing on AIX

The packages plugin now correctly parses RPM package name / version information on AIX systems.

### Additional Platform Support

Ohai now properly detects the [Clear](https://clearlinux.org/) and [ClearOS](https://www.clearos.com/) Linux distributions.

#### Clear Linux

* platform: clearlinux
* platform_family: clearlinux

#### ClearOS

* platform: clearos
* platform_family: rhel

## New Deprecations

### Removal of IpScopes plugin. (OHAI-13)

<https://docs.chef.io/deprecations_ohai_ipscopes.html>

In Chef/Ohai 14 (April 2018) we will remove the IpScopes plugin. The data returned by this plugin is nearly identical to information already returned by individual network plugins and this plugin required the installation of an additional gem into the Chef installation. We believe that few users were installing the gem and users would be better served by the data returned from the network plugins.

# 13.1

## Socketless local mode by default

For security reasons we are switching Local Mode to use socketless connections by default. This prevents potential attacks where an unprivileged user or process connects to the internal Zero server for the converge and changes data.

If you use Chef Provisioning with Local Mode, you may need to pass `--listen` to `chef-client`.

## New Deprecations

### Removal of support for Ohai version 6 plugins (OHAI-10)

<https://docs.chef.io/deprecations_ohai_v6_plugins.html>

In Chef/Ohai 14 (April 2018) we will remove support for loading Ohai v6 plugins, which we deprecated in Ohai 7/Chef 11.12.

# 13.0

## Rubygems provider sources behavior changed.

The behavior of `gem_package` and `chef_gem` is now to always apply the `Chef::Config[:rubygems_url]` sources, which may be a String uri or an Array of Strings. If additional sources are put on the resource with the `source` property those are added to the configured `:rubygems_url` sources.

This should enable easier setup of rubygems mirrors particularly in "airgapped" environments through the use of the global config variable. It also means that an admin may force all rubygems.org traffic to an internal mirror, while still being able to consume external cookbooks which have resources which add other mirrors unchanged (in a non-airgapped environment).

In the case where a resource must force the use of only the specified source(s), then the `include_default_source` property has been added -- setting it to false will remove the `Chef::Config[:rubygems_url]` setting from the list of sources for that resource.

The behavior of the `clear_sources` property is now to only add `--clear-sources` and has no magic side effects on the source options.

## Ruby version upgraded to 2.4.1

We've upgraded to the latest stable release of the Ruby programming language. See the Ruby [2.4.0 Release Notes](https://www.ruby-lang.org/en/news/2016/12/25/ruby-2-4-0-released/) for an overview of what's new in the language.

## Resource can now declare a default name

The core `apt_update` resource can now be declared without any name argument, no need for `apt_update "this string doesn't matter but why do i have to type it?"`.

This can be used by any other resource by just overriding the name property and supplying a default:

```ruby
  property :name, String, default: ""
```

Notifications to resources with empty strings as their name is also supported via either the bare resource name (`apt_update` -- matches what the user types in the DSL) or with empty brackets (`apt_update[]` -- matches the resource notification pattern).

## The knife ssh command applies the same fuzzifier as knife search node

A bare name to knife search node will search for the name in `tags`, `roles`, `fqdn`, `addresses`, `policy_name` or `policy_group` fields and will match when given partial strings (available since Chef 11). The `knife ssh` search term has been similarly extended so that the search API matches in both cases. The node search fuzzifier has also been extracted out to a `fuzz` option to Chef::Search::Query for re-use elsewhere.

## Cookbook root aliases

Rather than `attributes/default.rb`, cookbooks can now use `attributes.rb` in the root of the cookbook. Similarly for a single default recipe, cookbooks can use `recipe.rb` in the root of the cookbook.

## knife ssh can now connect to gateways with ssh key authentication

The new `gateway_identity_file` option allows the operator to specify the key to access ssh gateways with.

## Windows Task resource added

The `windows_task` resource has been ported from the windows cookbook, and many bugs have been fixed.

## Solaris SMF services can now been started recursively

It is now possible to load Solaris services recursively, by ensuring the new `options` property of the `service` resource contains `-r`.

## It's now possible to blacklist node attributes

This is the inverse of the pre-existing whitelisting functionality.

## The guard interpreter for `powershell_script` is PowerShell, again

When writing `not_if` or `only_if` statements, by default we now run those statements using powershell, rather than forcing the user to set `guard_interpreter` each time.

## Zypper GPG checks by default

Zypper now defaults to performing gpg checks of packages.

## The InSpec gem is now shipped by default

The `inspec` and `train` gems are shipped by default in the chef omnibus package, making it easier for users in airgapped environments to use InSpec.

## Properly support managing Sys-V services on Debian systemd hosts

Chef now properly supports managing sys-v services on hosts running systemd. Previously Chef would incorrectly attempt to fallback to Upstart even if upstart was not installed.

## Backwards Compatibility Breaks

### Resource Cloning has been removed

When Chef compiles resources, it will no longer attempt to merge the properties of previously compiled resources with the same name and type in to the new resource. See [the deprecation page](https://docs.chef.io/deprecations_resource_cloning.html) for further information.

### It is an error to specify both `default` and `name_property` on a property

Chef 12 made this work by picking the first option it found, but it was always an error and has now been disallowed.

### The path property of the execute resource has been removed

It was never implemented in the provider, so it was always a no-op to use it, the remediation is to simply delete it.

### Using the command property on any script resource (including bash, etc) is now a hard error

This was always a usage mistake. The command property was used internally by the script resource and was not intended to be exposed to users. Users should use the code property instead (or use the command property on an execute resource to execute a single command).

### Omitting the code property on any script resource (including bash, etc) is now a hard error

It is possible that this was being used as a no-op resource, but the log resource is a better choice for that until we get a null resource added. Omitting the code property or mixing up the code property with the command property are also common usage mistakes that we need to catch and error on.

### The chef_gem resource defaults to not run at compile time

The `compile_time true` flag may still be used to force compile time.

### The Chef::Config[:chef_gem_compile_time] config option has been removed

In order to for community cookbooks to behave consistently across all users this optional flag has been removed.

### The `supports[:manage_home]` and `supports[:non_unique]` API has been removed from all user providers

The remediation is to set the manage_home and non_unique properties directly.

### Using relative paths in the `creates` property of an execute resource with specifying a `cwd` is now a hard error

Without a declared cwd the relative path was (most likely?) relative to wherever chef-client happened to be invoked which is not deterministic or easy to intuit behavior.

### Chef::PolicyBuilder::ExpandNodeObject#load_node has been removed

This change is most likely to only affect internals of tooling like chefspec if it affects anything at all.

### PolicyFile failback to create non-policyfile nodes on Chef Server < 12.3 has been removed

PolicyFile users on Chef-13 should be using Chef Server 12.3 or higher.

### Cookbooks with self dependencies are no longer allowed

The remediation is removing the self-dependency `depends` line in the metadata.

### Removed `supports` API from Chef::Resource

Retained only for the service resource (where it makes some sense) and for the mount resource.

### Removed retrying of non-StandardError exceptions for Chef::Resource

Exceptions not decending from StandardError (e.g. LoadError, SecurityError, SystemExit) will no longer trigger a retry if they are raised during the executiong of a resources with a non-zero retries setting.

### Removed deprecated `method_missing` access from the Chef::Node object

Previously, the syntax `node.foo.bar` could be used to mean `node["foo"]["bar"]`, but this API had sharp edges where methods collided with the core ruby Object class (e.g. `node.class`) and where it collided with our own ability to extend the `Chef::Node` API. This method access has been deprecated for some time, and has been removed in Chef-13.

### Changed `declare_resource` API

Dropped the `create_if_missing` parameter that was immediately supplanted by the `edit_resource` API (most likely nobody ever used this) and converted the `created_at` parameter from an optional positional parameter to a named parameter. These changes are unlikely to affect any cookbook code.

### Node deep-duping fixes

The `node.to_hash`/`node.to_h` and `node.dup` APIs have been fixed so that they correctly deep-dup the node data structure including every string value. This results in a mutable copy of the immutable merged node structure. This is correct behavior, but is now more expensive and may break some poor code (which would have been buggy and difficult to follow code with odd side effects before).

For example:

```
node.default["foo"] = "fizz"
n = node.to_hash   # or node.dup
n["foo"] << "buzz"
```

before this would have mutated the original string in-place so that `node["foo"]` and `node.default["foo"]` would have changed to "fizzbuzz" while now they remain "fizz" and only the mutable `n["foo"]` copy is changed to "fizzbuzz".

### Freezing immutable merged attributes

Since Chef 11 merged node attributes have been intended to be immutable but the merged strings have not been frozen. In Chef 13, in the process of merging the node attributes strings and other simple objects are dup'd and frozen. In order to get a mutable copy, you can now correctly use the `node.dup` or `node.to_hash` methods, or you should mutate the object correctly through its precedence level like `node.default["some_string"] << "appending_this"`.

### The Chef::REST API has been removed

It has been fully replaced with `Chef::ServerAPI` in chef-client code.

### Properties overriding methods now raise an error

Defining a property that overrides methods defined on the base ruby `Object` or on `Chef::Resource` itself can cause large amounts of confusion. A simple example is `property :hash` which overrides the Object#hash method which will confuse ruby when the Custom Resource is placed into the Chef::ResourceCollection which uses a Hash internally which expects to call Object#hash to get a unique id for the object. Attempting to create `property :action` would also override the Chef::Resource#action method which is unlikely to end well for the user. Overriding inherited properties is still supported.

### `chef-shell` now supports solo and legacy solo modes

Running `chef-shell -s` or `chef-shell --solo` will give you an experience consistent with `chef-solo`. `chef-shell --solo-legacy-mode` will give you an experience consistent with `chef-solo --legacy-mode`.

### Chef::Platform.set and related methods have been removed

The deprecated code has been removed. All providers and resources should now be using Chef >= 12.0 `provides` syntax.

### Remove `sort` option for the Search API

This option has been unimplemented on the server side for years, so any use of it has been pointless.

### Remove Chef::ShellOut

This was deprecated and replaced a long time ago with mixlib-shellout and the shell_out mixin.

### Remove `method_missing` from the Recipe DSL

The core of chef hasn't used this to implement the Recipe DSL since 12.5.1 and its unlikely that any external code depended upon it.

### Simplify Recipe DSL wiring

Support for actions with spaces and hyphens in the action name has been dropped. Resources and property names with spaces and hyphens most likely never worked in Chef-12\. UTF-8 characters have always been supported and still are.

### `easy_install` resource has been removed

The Python `easy_install` package installer has been deprecated for many years, so we have removed support for it. No specific replacement for `pip` is being included with Chef at this time, but a `pip`-based `python_package` resource is available in the [`poise-python`](https://github.com/poise/poise-python) cookbooks.

### Removal of run_command and popen4 APIs

All the APIs in chef/mixlib/command have been removed. They were deprecated by mixlib-shellout and the shell_out mixin API.

### Iconv has been removed from the ruby libraries and chef omnibus build

The ruby Iconv library was replaced by the Encoding library in ruby 1.9.x and since the deprecation of ruby 1.8.7 there has been no need for the Iconv library but we have carried it forwards as a dependency since removing it might break some chef code out there which used this library. It has now been removed from the ruby build. This also removes LGPLv3 code from the omnibus build and reduces build headaches from porting iconv to every platform we ship chef-client on.

This will also affect nokogiri, but that gem natively supports UTF-8, UTF-16LE/BE, ISO-8851-1(Latin-1), ASCII and "HTML" encodings. Users who really need to write something like Shift-JIS inside of XML will need to either maintain their own nokogiri installs or will need to convert to using UTF-8.

### Deprecated cookbook metadata has been removed

The `recommends`, `suggests`, `conflicts`, `replaces` and `grouping` metadata fields are no longer supported, and have been removed, since they were never used. Chef will ignore them in existing `metadata.rb` files, but we recommend that you remove them. This was proposed in RFC 85.

### All unignored cookbook files will now be uploaded.

We now treat every file under a cookbook directory as belonging to a cookbook, unless that file is ignored with a `chefignore` file. This is a change from the previous behaviour where only files in certain directories, such as `recipes` or `templates`, were treated as special. This change allows chef to support new classes of files, such as Ohai plugins or Inspec tests, without having to make changes to the cookbook format to support them.

### DSL-based custom resources and providers no longer get module constants

Up until now, creating a `mycook/resources/thing.rb` would create a `Chef::Resources::MycookThing` name to access the resource class object. This const is no longer created for resources and providers. You can access resource classes through the resolver API like:

```ruby
Chef::Resource.resource_for_node(:mycook_thing, node)
```

Accessing a provider class is a bit more complex, as you need a resource against which to run a resolution like so:

```ruby
Chef::ProviderResolver.new(node, find_resource!("mycook_thing[name]"), :nothing).resolve
```

### Default values for resource properties are frozen

A resource declaring something like:

```ruby
property :x, default: {}
```

will now see the default value set to be immutable. This prevents cases of modifying the default in one resource affecting others. If you want a per-resource mutable default value, define it inside a `lazy{}` helper like:

```ruby
property :x, default: lazy { {} }
```

### Resources which later modify their name during creation will have their name changed on the ResourceCollection and notifications

```ruby
some_resource "name_one" do
  name "name_two"
end
```

The fix for sending notifications to multipackage resources involved changing the API which inserts resources into the resource collection slightly so that it no longer directly takes the string which is typed into the DSL but reads the (possibly coerced) name off of the resource after it is built. The end result is that the above resource will be named `some_resource[name_two]` instead of `some_resource[name_one]`. Note that setting the name (_not_ the `name_property`, but actually renaming the resource) is very uncommon. The fix is to simply name the resource correctly in the first place (`some_resource "name_two" do ...`)

### `use_inline_resources` is always enabled

The `use_inline_resources` provider mode is always enabled when using the `action :name do ... end` syntax. You can remove the `use_inline_resources` line.

### `knife cookbook site vendor` has been removed

Please use `knife cookbook site install` instead.

### `knife cookbook create` has been removed

Please use `chef generate cookbook` from the ChefDK instead.

### Verify commands no longer support "%{file}"

Chef has always recommended `%{path}`, and `%{file}` has now been removed.

### The `partial_search` recipe method has been removed

The `partial_search` method has been fully replaced by the `filter_result` argument to `search`, and has now been removed.

### The logger and formatter settings are more predictable

The default now is the formatter. There is no more automatic switching to the logger when logging or when output is sent to a pipe. The logger needs to be specifically requested with `--force-logger` or it will not show up.

The `--force-formatter` option does still exist, although it will probably be deprecated in the future.

If your logfiles switch to the formatter, you need to include `--force-logger` for your daemonized runs.

Redirecting output to a file with `chef-client > /tmp/chef.out` now captures the same output as invoking it directly on the command line with no redirection.

### Path Sanity disabled by default and modified

The chef client itself no long modifies its `ENV['PATH']` variable directly. When using the `shell_out` API now, in addition to setting up LANG/LANGUAGE/LC_ALL variables that API will also inject certain system paths and the ruby bindir and gemdirs into the PATH (or Path on Windows). The `shell_out_with_systems_locale` API still does not mangle any environment variables. During the Chef-13 lifecycle changes will be made to prep Chef-14 to switch so that `shell_out` by default behaves like `shell_out_with_systems_locale`. A new flag will get introduced to call `shell_out(..., internal: [true|false])` to either get the forced locale and path settings ("internal") or not. When that is introduced in Chef 13.x the default will be `true` (backwards-compat with 13.0) and that default will change in 14.0 to 'false'.

The PATH changes have also been tweaked so that the ruby bindir and gemdir PATHS are prepended instead of appended to the PATH. Some system directories are still appended.

Some examples of changes:

* `which ruby` in 12.x will return any system ruby and fall back to the embedded ruby if using omnibus
* `which ruby` in 13.x will return any system ruby and will not find the embedded ruby if using omnibus
* `shell_out_with_systems_locale("which ruby")` behaves the same as `which ruby` above
* `shell_out("which ruby")` in 12.x will return any system ruby and fall back to the embedded ruby if using omnibus
* `shell_out("which ruby")` in 13.x will always return the omnibus ruby first (but will find the system ruby if not using omnibus)

The PATH in `shell_out` can also be overridden:

* `shell_out("which ruby", env: { "PATH" => nil })` - behaves like shell_out_with_systems_locale()
* `shell_out("which ruby", env: { "PATH" => [...include PATH string here...] })` - set it arbitrarily however you need

Since most providers which launch custom user commands use `shell_out_with_systems_locale` (service, execute, script, etc) the behavior will be that those commands that used to be having embedded omnibus paths injected into them no longer will. Generally this will fix more problems than it solves, but may causes issues for some use cases.

### Default guard clauses (`not_if`/`only_if`) do not change the PATH or other env vars

The implementation switched to `shell_out_with_systems_locale` to match `execute` resource, etc.

### Chef Client will now exit using the RFC062 defined exit codes

Chef Client will only exit with exit codes defined in RFC 062\. This allows other tooling to respond to how a Chef run completes. Attempting to exit Chef Client with an unsupported exit code (either via `Chef::Application.fatal!` or `Chef::Application.exit!`) will result in an exit code of 1 (GENERIC_FAILURE) and a warning in the event log.

When Chef Client is running as a forked process on unix systems, the standardized exit codes are used by the child process. To actually have Chef Client return the standard exit code, `client_fork false` will need to be set in Chef Client's configuration file.

# Chef Client Release Notes 12.22:

## Security Updates

### Ruby

Ruby has been updated to 2.3.6 to resolve CVE-2017-17405

### LibXML2

Libxml2 has been updated to 2.9.7 to resolve CVE-2017-15412

## Ohai 8.26.1

### EC2 detection on C5/M5

Ohai now provides EC2 metadata configuration information on the new C5/M5 instance types running on Amazon's new hypervisor.

### LsPci Plugin

The new LsPci plugin provides a node[:pci] hash with information about the PCI bus based on lspci. Only runs on Linux.

### Docker Detection

The virtualization plugin has been updated to properly detect when running on Docker CE

# Chef Client Release Notes 12.21:

## Security Fixes

This release of Chef Client contains Ruby 2.3.5, fixing 4 CVEs:

  * CVE-2017-0898
  * CVE-2017-10784
  * CVE-2017-14033
  * CVE-2017-14064

It also contains a new version of Rubygems, fixing 4 CVEs:

  * CVE-2017-0899
  * CVE-2017-0900
  * CVE-2017-0901
  * CVE-2017-0902

This release also contains a new version of zlib, fixing 4
CVEs:

 *  [CVE-2016-9840](https://www.cvedetails.com/cve/CVE-2016-9840/)
 *  [CVE-2016-9841](https://www.cvedetails.com/cve/CVE-2016-9841/)
 *  [CVE-2016-9842](https://www.cvedetails.com/cve/CVE-2016-9842/)
 *  [CVE-2016-9843](https://www.cvedetails.com/cve/CVE-2016-9843/)

## On Debian based systems, correctly prefer Systemd to Upstart

On Debian systems, packages that support systemd will often ship both an
old style init script and a systemd unit file. When this happened, Chef
would incorrectly choose Upstart rather than Systemd as the service
provider. We now pick Systemd.

## Handle the supports pseudo-property more gracefully

Chef 13 removed the `supports` property from core resources. However,
many cookbooks also have a property named support, and Chef 12 was
incorrectly giving a deprecation notice in that case, preventing users
from properly testing their cookbooks for upgrades.

## Don't crash when we downgrade from Chef 13 to Chef 12

On systems where Chef 13 had been run, Chef 12 would crash as the
on disk cookbook format has changed. Chef 12 now correctly ignores the
unexpected files.

## Provide better system information when Chef crashes

When Chef crashes, the output now includes details about the platform
and version of Chef that was running, so that a bug report has more
detail from the off.

# Chef Client Release Notes 12.19:

## Highlighted enhancements for this release:

* Systemd unit files are now verified before being installed.
* Added support for windows alternate user identity in execute resources.
* Added ed25519 key support for for ssh connections.

### Windows alternate user identity execute support

The `execute` resource and similar resources such as `script`, `batch`, and `powershell_script` now support the specification of credentials on Windows so that the resulting process is created with the security identity that corresponds to those credentials.

**Note**: When Chef is running as a service, this feature requires that the user that Chef runs as has 'SeAssignPrimaryTokenPrivilege' (aka 'SE_ASSIGNPRIMARYTOKEN_NAME') user right. By default only LocalSystem and NetworkService have this right when running as a service. This is necessary even if the user is an Administrator.

This right bacn be added and checked in a recipe using this example:

```ruby
# Add 'SeAssignPrimaryTokenPrivilege' for the user
Chef::ReservedNames::Win32::Security.add_account_right('<user>', 'SeAssignPrimaryTokenPrivilege')

# Check if the user has 'SeAssignPrimaryTokenPrivilege' rights
Chef::ReservedNames::Win32::Security.get_account_right('<user>').include?('SeAssignPrimaryTokenPrivilege')
```

#### Properties

The following properties are new or updated for the `execute`, `script`, `batch`, and `powershell_script` resources and any resources derived from them:

* `user`<br>
  **Ruby types:** String<br>
  The user name of the user identity with which to launch the new process. Default value: `nil`. The user name may optionally be specified with a domain, i.e. `domain\user` or `user@my.dns.domain.com` via Universal Principal Name (UPN) format. It can also be specified without a domain simply as `user` if the domain is instead specified using the `domain` attribute. On Windows only, if this property is specified, the `password` property **must** be specified.

* `password`<br>
  **Ruby types** String<br>
  _Windows only:_ The password of the user specified by the `user` property. Default value: `nil`. This property is mandatory if `user` is specified on Windows and may only be specified if `user` is specified. The `sensitive` property for this resource will automatically be set to `true` if `password` is specified.

* `domain`<br>
  **Ruby types** String<br>
  _Windows only:_ The domain of the user user specified by the `user` property. Default value: `nil`. If not specified, the user name and password specified by the `user` and `password` properties will be used to resolve that user against the domain in which the system running Chef client is joined, or if that system is not joined to a domain it will resolve the user as a local account on that system. An alternative way to specify the domain is to leave this property unspecified and specify the domain as part of the `user` property.

#### Usage

The following examples explain how alternate user identity properties can be used in the execute resources:

```ruby
powershell_script 'create powershell-test file' do
  code <<-EOH
  $stream = [System.IO.StreamWriter] "#{Chef::Config[:file_cache_path]}/powershell-test.txt"
  $stream.WriteLine("In #{Chef::Config[:file_cache_path]}...word.")
  $stream.close()
  EOH
  user 'username'
  password 'password'
end

execute 'mkdir test_dir' do
  cwd Chef::Config[:file_cache_path]
  domain "domain-name"
  user "user"
  password "password"
end

script 'create test_dir' do
  interpreter "bash"
  code  "mkdir test_dir"
  cwd Chef::Config[:file_cache_path]
  user "domain-name\\username"
  password "password"
end

batch 'create test_dir' do
  code "mkdir test_dir"
  cwd Chef::Config[:file_cache_path]
  user "username@domain-name"
  password "password"
end
```

## Highlighted bug fixes for this release:

* Ensure that the Windows Administrator group can access the chef-solo nodes directory
* When loading a cookbook in Chef Solo, use `metadata.json` in preference to `metadata.rb`

## Deprecation Notice

* As of version 12.19, chef client will no longer be build or tested on the Cisco NX-OS and IOS XR platforms.

# Ohai Release Notes 8.23:

## Cumulus Linux Platform

Cumulus Linux will now be detected as platform `cumulus` instead of `debian` and the `platform_version` will be properly set to the Cumulus Linux release.

## Virtualization Detection

Windows / Linux / BSD guests running on the Veertu hypervisors will now be detected

Windows guests running on Xen and Hyper-V hypervisors will now be detected

## New Sysconf Plugin

A new plugin parses the output of the sysconf command to provide information on the underlying system.

## AWS Account ID

The EC2 plugin now fetches the AWS Account ID in addition to previous instance metadata

## GCC Detection

GCC detection has been improved to collect additional information, and to not prompt for the installation of Xcode on macOS systems

## New deprecations introduced in this release:

### Ohai::Config removed

* **Deprecation ID**: OHAI-1
* **Remediation Docs**: <https://docs.chef.io/deprecations_ohai_legacy_config.html>
* **Expected Removal**: Ohai 13 (April 2017)

### sigar gem based plugins removed

* **Deprecation ID**: OHAI-2
* **Remediation Docs**: <https://docs.chef.io/deprecations_ohai_sigar_plugins.html>
* **Expected Removal**: Ohai 13 (April 2017)

### run_command and popen4 helper methods removed

* **Deprecation ID**: OHAI-3
* **Remediation Docs**: <https://docs.chef.io/deprecations_ohai_run_command_helpers.html>
* **Expected Removal**: Ohai 13 (April 2017)

### libvirt plugin attributes moved

* **Deprecation ID**: OHAI-4
* **Remediation Docs**: <https://docs.chef.io/deprecations_ohai_libvirt_plugin.html>
* **Expected Removal**: Ohai 13 (April 2017)

### Windows CPU plugin attribute changes

* **Deprecation ID**: OHAI-5
* **Remediation Docs**: <https://docs.chef.io/deprecations_ohai_windows_cpu.html>
* **Expected Removal**: Ohai 13 (April 2017)

### DigitalOcean plugin attribute changes

* **Deprecation ID**: OHAI-6
* **Remediation Docs**: <https://docs.chef.io/deprecations_ohai_digitalocean.html>
* **Expected Removal**: Ohai 13 (April 2017)
