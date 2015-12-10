# Chef Client Release Notes 12.6.0:


## Upgrade to OpenSSL 1.0.1q

This release picks up the latest distribution from the OpenSSL 1.0.1 branch (1.0.1q).
There are a number of OpenSSL security fixes that are addressed - please see the following for more info: https://www.openssl.org/news/openssl-1.0.1-notes.html

## New `chef_version` and `ohai_version` metadata keywords

Two new keywords have been introduced to the metadata of cookbooks for constraining the acceptable range
of chef-client versions that a cookbook runs on.  By default if these keywords are not present chef-client
will always run.  If either of these keywords are given and none of the given ranges match the running
Chef::VERSION or Ohai::VERSION then the chef-client will report an error that the cookbook does not support
the running client or ohai version.

There is currently little integration with this outside of the client, but work is underway to display this
information on the supermarket.  There are also plans to get depsolvers like Berkshelf able to automatically
prune invalid cookbooks out of their solution sets to avoid uploading a cookbook which will only throw
an exception.

## New --profile-ruby option to profile Ruby

The 'chef' gem now has a new optional development dependency on the 'ruby-prof' gem and when it is installed
it can be used via the --profile-ruby command line option.  This gem will also be shipped in all the omnibus
builds of `chef` and `chef-dk` going forwards so that while it will be 'optional' it will also be fairly
broadly installed (it is 'optional' mostly for people who are installing chef in their own bundles).

When invoked this option will dump a (large) profiling graph into `/var/chef/cache/graph_profile.out`.  For
users who are familiar with reading call stack graphs this will likely be very useful for profiling the
internal guts of a chef-client run.  The performance hit of this profiler will roughly double the length
of a chef-client run so it is something that can be used without causing errant timeouts and other
heisenbugs due to the profiler itself.  It is not suitable for daily use in production.  It is unlikely to
be suitable for users without a background in software development and debugging.

It was developed out of some particularly difficult profiling of performance issues in the Chef node
attributes code, which was then turned into a patch so that other people could experiment with it.  It was
not designed to be a general solution to performance issues inside of chef-client recipe code.

This debugging feature will mostly be useful to people who are already Ruby experts.

## `dpkg_package` now accepts an array of packages

Similar to the `yum_package` and `apt_package` resources, the `dpkg_package` resource now handles an Array of package names (and
also array of versions and array of sources).

Some edge conditions in the `:remove` and `:purge` actions in `dpkg_package` were also fixed and the `:purge` action will now
purge packages that were previously removed (`apt_package` still does not do this).

## New ksh resource

Korn Shell scripts can now be run using the ksh resource, or by setting the interpreter parameter of the script resource to ksh.

Please see the following for more details : https://docs.chef.io/release/12-6/resource_ksh.html

## New FastMSI omnibus installer (Windows)

This is the first release where we are rolling out a MSI package for Windows that significantly improves the installation time. In a nutshell, the new approach is to deploy and extract a zipped package rather than individually tracking every file as a MSI component. Please note that the first  upgrade (ie, an older version of Chef client is already on the machine) may not exhibit the full extent of the speed-up (as MSI is still tracking the older files). New installs, as well as future upgrades, will be sped up. Uninstalls will remove the folder that Chef client is installed to (typically, C:\Opscode\Chef).

## `windows_package` now supports non-`MSI` based Windows installers

Today you can install `MSI`s using the `windows_package` resource. However, you have had to use the windows cookbook in order to install non `MSI` based installer packages such as Nullsoft, Inno Setup, Installshield and other `EXE` based installers. We have moved and slightly improved the windows cookbook resource into the core chef client. This means you can now run most windows installer types without taking on external cookbook dependencies.

## Better handling of log_location with chef client service (Windows)

This change is for the scenario when running chef client as a Windows service. Currently, a default log_location gets used by the chef client windows service. This log_location overrides any log_location set in the client.rb. In 12.6.0, the behavior is changed to allow the Chef client running as a Windows service to prefer the log_location in client.rb instead. Now, the windows_service_manager will not explicitly pass in a log_location, and therefore the Chef service will always use what is in the client.rb or the typical default path if none is configured. This enables scenarios such as logging to the Windows event log when running chef client as a Windows service.

## Dsc_resource changes and fixes (Windows)

* A fix was made for the Nov 2015 update of Windows 10, where the dsc_resource did not properly show the command output when converging the resource.
* Dsc_resource could in some cases show the plaintext password when #inspected - this is now prevented from happening.
* Previously, Chef required the LCM Refreshmode to be set to Disabled when utilizing dsc_resource. Microsoft has relaxed this requirement in Windows Management Framework 5 (WMF5) (PowerShell 5.0.10586.0 or later). Now, we only require the RefreshMode to be disabled when running on earlier versions of PowerShell 5.
* Added a reboot_action attribute to dsc_resource. If the DSC resource indicates that it requires a reboot, reboot_action can use the reboot resource to either reboot immediately (:reboot_now) or queue a reboot (:request_reboot).  The default value of reboot_action is :nothing.

In addition to `:immediately` and `:delayed`, we have added the new notification timing `:before`. `:before` will trigger just before the
resource converges, but will only trigger if the resource is going to
actually cause an update.

For example, this will stop apache if you are about to upgrade your particularly sensitive web app (which can't run while installing for
whatever reason) and start it back up afterwards.

```
execute 'install my app' do
  only_if { i_should_install_my_app }
end

# Only stop and start apache if i_should_install_my_app
service 'httpd' do
  action :nothing
  subscribes :stop, 'template[/etc/httpd.conf]', :before
  subscribes :start, 'template[/etc/httpd.conf]'
end
```

## Other items

There are a large number of other PRs in this release. Please see the CHANGELOG for the full set of changes : https://github.com/chef/chef/blob/master/CHANGELOG.md
