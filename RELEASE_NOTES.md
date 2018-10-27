This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team. Please see <https://docs.chef.io/release_notes.html> for the official Chef release notes.

# UNRELEASED (Chef 15)

Chef 15 release notes will be added here as development progresses.

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

- Multiple bugfixes in Chef Vault have been resolved by updating chef-vault to 3.4.2
- Invalid yum package names now gracefully fail
- `windows_ad_join` now properly executes. Thank you [@cpjones01](https://github.com/cpjones01) for reporting this.
- `rhsm_errata_level` now properly executes. Thank you [@freakinhippie](https://github.com/freakinhippie) for this fix.
- `registry_key` now properly writes out the correct value when `sensitive` is specified. Thank you [@josh-barker](https://github.com/josh-barker) for this fix.
- `locale` now properly executes on RHEL 6 and Amazon Linux 201X.

## Ohai 14.6

### Filesystem Plugin on AIX and Solaris

AIX and Solaris now ship with a filesystem2 plugin that updates the filesystem data to match that of Linux, macOS, amd BSD hosts. This new data structure makes accessing filesystem data in recipes easier and especially improves the layout and depth of data on ZFS filesystems. In Chef 15 (April 2019) we will begin wrting this same format of data to the existing `node['filesystem']` namespace. In Chef 16 (April 2020) we will remove the `node['filesystem2']` namspace, completing the transition to the new format. Thank you [@jaymzh](https://github.com/jaymzh) for continuing the updates to our filesystem plugins with this change.

### macOS Improvements

The system_profile plugin has been improved to skip over uncessary data, which reduces macOS node sizes on the Chef Server. Additionally the CPU plugin has been updated to limit what sysctl values it polls, which prevents hanging on some system configurations.

### SLES 15 Detection

SLES 15 is now correctly detected as the platform "suse" instead of "sles". This matches the behavior of SLES 11 and 12 hosts.

## New Deprecations

### system_profile Ohai plugin removal

The system_profile plugin will be removed from Chef/Ohai 15 in April 2019. This plugin does not correctly return data on modern Mac systems. Additionally the same data is provided by the hardware plugin, which has a format that is simpler to consume. Removing this plugin will reduce Ohai return by ~3 seconds and greatly reduce the size of the node object on the Chef server.

## Security Updates

### Ruby 2.5.3

Ruby has been updated to from 2.5.1 to 2.5.3 to resolve multiple CVEs and bugs:
- [CVE-2018-16396](https://www.ruby-lang.org/en/news/2018/10/17/not-propagated-taint-flag-in-some-formats-of-pack-cve-2018-16396/)
- [CVE-2018-16395](https://www.ruby-lang.org/en/news/2018/10/17/openssl-x509-name-equality-check-does-not-work-correctly-cve-2018-16395/)

# Chef Client Release Notes 14.5.33:

This release resolves a regression that caused the ``windows_ad_join`` resource to fail to run. It also makes the following additional fixes:
  - The ``ohai`` resource's unused ``ohai_name`` property has been deprecated. This will be removed in Chef 15.0.
  - Error messages in the ``windows_feature`` resources have been improved.
  - The ``windows_service`` resource will no longer log potentially sensitive information if the ``sensitive`` property is used.

Thanks to @cpjones01, @kitforbes, and @dgreeninger for their help with this release.

# Chef Client Release Notes 14.5.27:

## New Resources

We've added new resources to Chef 14.5. Cookbooks using these resources will continue to take precedent until the Chef 15.0 release

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

The following new previous resources were added to Chef 14.4. Cookbooks with the same resources will continue to take precedent until the Chef 15.0 release

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
- Client DoS due to large DH parameter ([CVE-2018-0732](https://nvd.nist.gov/vuln/detail/CVE-2018-0732))
- Cache timing vulnerability in RSA Key Generation ([CVE-2018-0737](https://nvd.nist.gov/vuln/detail/CVE-2018-0737))

# Chef Client Release Notes 14.3:

## New Preview Resources Concept

This release of Chef introduces the concept of Preview Resources. Preview resources behave the same as a standard resource built into Chef, except Chef will load a resource with the same name from a cookbook instead of the built-in preview resource.

What does this mean for you? It means we can introduce new resources in Chef without breaking existing behavior in your infrastructure. For instance if you have a cookbook with a resource named `manage_everything` and a future version of Chef introduced a preview resource named `manage_everything` you will continue to receive the resource from your cookbook. That way outside of a major release your won't experience a potentially breaking behavior change from the newly included resource.

Then when we perform our yearly major release we'll remove the preview designation from all resources, and the built in resources will take precedence over resources with the same names in cookbooks.

## New Resources

### chocolatey_config

Use the chocolatey_config resource to add or remove Chocolatey configuration keys."

#### Actions

- `set` - Sets a Chocolatey config value.
- `unset` - Unsets a Chocolatey config value.

#### Properties

- `config_key` - The name of the config. We'll use the resource's name if this isn't provided.
- `value` - The value to set.

### chocolatey_source

Use the chocolatey_source resource to add or remove Chocolatey sources.

#### Actions

- `add` - Adds a Chocolatey source.
- `remove` - Removes a Chocolatey source.

#### Properties

- `source_name` - The name of the source to add. We'll use the resource's name if this isn't provided.
- `source` - The source URL.
- `bypass_proxy` - Whether or not to bypass the system's proxy settings to access the source.
- `priority` - The priority level of the source.

### powershell_package_source

Use the `powershell_package_source` resource to register a powershell package repository.

### Actions

- `register` - Registers and updates the powershell package source.
- `unregister` - Unregisters the powershell package source.

#### Properties

- `source_name` - The name of the package source.
- `url` - The url to the package source.
- `trusted` - Whether or not to trust packages from this source.
- `provider_name` - The package management provider for the source. It supports the following providers: 'Programs', 'msi', 'NuGet', 'msu', 'PowerShellGet', 'psl' and 'chocolatey'.
- `publish_location` - The url where modules will be published to for this source. Only valid if the provider is 'PowerShellGet'.
- `script_source_location` - The url where scripts are located for this source. Only valid if the provider is 'PowerShellGet'.
- `script_publish_location` - The location where scripts will be published to for this source. Only valid if the provider is 'PowerShellGet'.

### kernel_module

Use the kernel_module resource to manage kernel modules on Linux systems. This resource can load, unload, blacklist, install, and uninstall modules.

#### Actions

- `install` - Load kernel module, and ensure it loads on reboot.
- `uninstall` - Unload a kernel module and remove module config, so it doesn't load on reboot.
- `blacklist` - Blacklist a kernel module.
- `load` - Load a kernel module.
- `unload` - Unload kernel module

#### Properties

- `modname` - The name of the kernel module.
- `load_dir` - The directory to load modules from.
- `unload_dir` - The modprobe.d directory.

### ssh_known_hosts_entry

Use the ssh_known_hosts_entry resource to add an entry for the specified host in /etc/ssh/ssh_known_hosts or a user's known hosts file if specified.

#### Actions

- `create` - Create an entry in the ssh_known_hosts file.
- `flush` - Immediately flush the entries to the config file. Without this the actual writing of the file is delayed in the Chef run so all entries can be accumulated before writing the file out.

#### Properties

- `host` - The host to add to the known hosts file.
- `key` - An optional key for the host. If not provided this will be automatically determined.
- `key_type` - The type of key to store.
- `port` - The server port that the ssh-keyscan command will use to gather the public key.
- `timeout` - The timeout in seconds for ssh-keyscan.
- `mode` - The file mode for the ssh_known_hosts file.
- `owner`- The file owner for the ssh_known_hosts file.
- `group` - The file group for the ssh_known_hosts file.
- `hash_entries` - Hash the hostname and addresses in the ssh_known_hosts file for privacy.
- `file_location` - The location of the ssh known hosts file. Change this to set a known host file for a particular user.

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

- `shell_out_with_systems_locale`
- `shell_out_with_timeout`
- `shell_out_compact`
- `shell_out_compact_timeout`
- `shell_out_with_systems_locale!`
- `shell_out_with_timeout!`
- `shell_out_compact!`
- `shell_out_compact_timeout!`

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

- A new `skip_publisher_check` property has been added to the `powershell_package` resource
- `windows_feature_powershell` now supports Windows 2008 R2
- The `mount` resource now supports the `mount_point` property on Windows
- `windows_feature_dism` no longer errors when specifying the source
- Resolved idempotency issues in the `windows_task` resource and prevented setting up a task with bad credentials
- `windows_service` no longer throws Ruby deprecation warnings

## Newly Introduced Deprecations

### CHEF-26: Deprecation of old shell_out APIs

As noted above, this release of Chef unifies our shell_out helpers into just shell_out and shell_out!. Previous helpers are now deprecated and will be removed in Chef 15.

See [CHEF-26 Deprecation Page](https://docs.chef.io/deprecations_shell_out.html) for details.

### Legacy FreeBSD pkg provider

Chef 15 will remove support for the legacy FreeBSD pkg format. We will continue to support the pkgng format introduced in FreeBSD 10.

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

- `git` resource: don't use `--prune-tags` as it's really new.
- `rhsm_repo` resource: now works
- `apt_repository` resource: use the `repo_name` property to name files
- `windows_task` resource: properly handle commands with arguments
- `windows_task` resource: handle creating tasks as the SYSTEM user
- `remote_directory` resource: restore the default for the `overwrite` property

## Ohai 14.1.3

- Properly detect FIPS environments
- `shard` plugin: work in FIPS compliant environments
- `filesystem` plugin: Handle BSD platforms

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

- On Windows, the installer now correctly re-extracts files during repair mode
- Fix a number of issues relating to use with Red Hat Satellite
- Git fetch now prunes remotes before running
- Fix locking and unlocking packages with apt and zypper
- Ensure we don't request every remote file when running with lazy loading enabled
- The sysctl resource correctly handles missing keys when used with `ignore_error`
- --recipe-url apparently never worked on Windows. Now it does.

## Security Updates

### ffi Gem

- CVE-2018-1000201: DLL loading issue which can be hijacked on Windows OS

# Ohai Release Notes 14.1:

## Configurable DMI Whitelist

The whitelist of DMI IDs is now user configurable using the `additional_dmi_ids` configuration setting, which takes an Array.

## Shard plugin

The Shard plugin has been returned to a default plugin rather than an optional one. To ensure we work in FIPS environments, the plugin will use SHA256 rather than MD5 in those environments.

## SCSI plugin

A new plugin to enumerate SCSI devices has been added. This plugin is optional.

# Chef Client Release Notes 14.0.202:

This release of Chef 14 resolves several regressions in the Chef 14.0 release.

- Resources contained in cookbooks would be used instead of built-in Chef client resources causing older resources to run
- Resources failed due to a missing `property_is_set?` and `resources` methods
- `yum_package` changed the order of `disablerepo` and `enablerepo` options
- Depsolving large numbers of cookbooks with chef zero/local took a very long time

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

Use the sysctl resource to set kernel parameters using the sysctl command line tool and configuration files in the system's `sysctl.d` directory. Configuration files managed by this resource are named 99-chef-KEYNAME.conf. If an existing value was already set for the value it will be backed up to the node and restored if the :remove action is used later. This resource was ported from the `sysctl` community cookbook.

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

- `preset` - Restore the preset enable/disable configuration for a unit
- `revert` - Revert to a vendor's version of a unit file
- `reenable` - Reenable a unit file

Thanks @nathwill for these new actions.

### windows_service

`windows_service` now includes actions for fully managing services on Windows, in addition to the previous actions for starting/stopping/enabling services.

- `create` - Create a new service
- `delete` - Delete an existing service
- `configure` - Reconfigure an existing service

Thanks @jasonwbarnett for these new actions

### route

`route` includes a new `comment` property.

Thanks Thomas Doherty for adding this new property.

## Expanded Configuration Detection

Ohai has been expanded to collect more information than ever. This should make writing cross-platform and cross cloud cookbooks simpler.

### Windows Kernel information

The kernel plugin now reports the following information on Windows:

- `node['kernel']['product_type']` - Workstation vs. Server editions of Windows
- `node['kernel']['system_type']` - What kind of hardware are we installed on (Desktop, Mobile, Workstation, Enterprise Server, etc.)
- `node['kernel']['server_core']` - Are we on Windows Server Core edition?

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

- [cve-2017-17742](https://www.ruby-lang.org/en/news/2018/03/28/http-response-splitting-in-webrick-cve-2017-17742/)
- [cve-2018-6914](https://www.ruby-lang.org/en/news/2018/03/28/unintentional-file-and-directory-creation-with-directory-traversal-cve-2018-6914/)
- [cve-2018-8777](https://www.ruby-lang.org/en/news/2018/03/28/large-request-dos-in-webrick-cve-2018-8777/)
- [cve-2018-8778](https://www.ruby-lang.org/en/news/2018/03/28/buffer-under-read-unpack-cve-2018-8778/)
- [cve-2018-8779](https://www.ruby-lang.org/en/news/2018/03/28/poisoned-nul-byte-unixsocket-cve-2018-8779/)
- [cve-2018-8780](https://www.ruby-lang.org/en/news/2018/03/28/poisoned-nul-byte-dir-cve-2018-8780/)
- [Multiple vulnerabilities in rubygems](https://www.ruby-lang.org/en/news/2018/02/17/multiple-vulnerabilities-in-rubygems/)

## Breaking Changes

This release completes the deprecation process for many of the deprecations that were warnings throughout the Chef 12 and Chef 13 releases.

### erl_call Resource

The erl_call resource was deprecated in Chef 13.7 and has been removed.

### deploy Resource

The deploy resource was deprecated in Chef 13.6 and been removed. If you still require this resource, it is available in the new `deploy_resource` cookbook at <https://supermarket.chef.io/cookbooks/deploy_resource>

### Windows 2003 Support

Support for Windows 2003 has been removed from both Chef and Ohai, improving the performance of Chef on Windows hosts.

### knife deprecations

- `knife bootstrap` options `--distro` and `--template_file` flags were deprecated in Chef 12 and have now been removed.
- `knife help` functionality that read legacy Chef manpages has been removed as the manpages had not been updated and were often quite wrong. Running knife help will now simply show the help menu.
- `knife index rebuild` has been removed as reindexing Chef Server was only necessary on releases prior to Chef Server 11.
- The `knife ssh --identity-file` flag was deprecated and has been removed. Users should use the `--ssh_identity_file` flag instead.
- `knife ssh csshx` was deprecated in Chef 10 and has been removed. Users should use `knife ssh cssh` instead.

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

- Chef::Mixin::LanguageIncludeAttribute
- Chef::Mixin::RecipeDefinitionDSLCore
- Chef::Mixin::LanguageIncludeRecipe
- Chef::Mixin::Language
- Chef::DSL::Recipe::FullDSL

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

# Chef Client Release Notes 13.8:

## Revert attributes changes from 13.7

Per <https://discourse.chef.io/t/regression-in-chef-client-13-7-16/12518/1> , there was a regression in how arrays and hashes were handled in 13.7\. In 13.8, we've reverted to the same code as 13.6.

## Continuing work on `windows_task`

13.8 has better validation for the `idle_time` property, when using the `on_idle` frequency.

## Security Updates

- Updated libxml2 to 2.9.7; fixes: CVE-2017-15412

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

- Chef::Mixin::LanguageIncludeAttribute
- Chef::Mixin::RecipeDefinitionDSLCore
- Chef::Mixin::LanguageIncludeRecipe
- Chef::Mixin::Language
- Chef::DSL::Recipe::FullDSL

### :uninstall action in chocolatey_package

The chocolatey cookbook's chocolatey_package resource originally contained an :uninstall action. When chocolatey_package was moved into core Chef we made :uninstall an alias for :remove. In Chef 14 :uninstall will no longer be a valid action. Foodcritic rule FC103 has been introduced to detect the usage of the :uninstall action.

## Bugfixes

- Resolved a bug where knife commands that prompted on Windows would never display the prompt
- Fixed hiding of sensitive resources when converge_if_changed was used
- Fixed scenarios where services would fail to start on Solaris

## Security Updates

- OpenSSL has been upgraded to 1.0.2n to resolve CVE-2017-3738, CVE-2017-3737, CVE-2017-3736, and CVE-2017-3735.
- Ruby has been upgraded to 2.4.3 to resolve CVE-2017-17405

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

- Resolved a regression in 13.6.0 that prevented upgrading packages on Debian/Ubuntu when the package name contained a tilde.

## Security Updates

- OpenSSL has been upgraded to 1.0.2m to resolve CVE-2017-3735 and CVE-2017-3736
- RubyGems has been upgraded to 2.6.14 to resolve CVE-2017-0903

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

In Ohai 13 we replaced the filesystem and cloud plugins with the filesystem2 and cloud_v2 plugins. To maintain compatibility with users of the previous V2 plugins we write data to both locations. We had originally planned to continue writing data to both locations until Chef 15\. Instead due to the large amount of duplicate node data this introduces we are updating OHAI-11 and OHAI-12 deprecations to remove node['cloud_v2'] and node['filesystem2'] with the release of Chef 14 in April 2018.

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

- CVE-2017-0898
- CVE-2017-10784
- CVE-2017-14033
- CVE-2017-14064

## Security release of RubyGems

Chef Client 13.4 includes RubyGems 2.6.13 to fix the following CVEs:

- CVE-2017-0899
- CVE-2017-0900
- CVE-2017-0901
- CVE-2017-0902

## Ifconfig provider on Red Hat now supports additional properties

It is now possible to set `ETHTOOL_OPTS`, `BONDING_OPTS`, `MASTER` and `SLAVE` properties on interfaces on Red Hat compatible systems. See <https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/s1-networkscripts-interfaces.html> for further information

### Properties

- `ethtool_opts`<br>
  **Ruby types:** String<br>
  **Platforms:** Fedora, RHEL, Amazon Linux A string containing arguments to ethtool. The string will be wrapped in double quotes, so ensure that any needed quotes in the property are surrounded by single quotes

- `bonding_opts`<br>
  **Ruby types:** String<br>
  **Platforms:** Fedora, RHEL, Amazon Linux A string containing configuration parameters for the bonding device.

- `master`<br>
  **Ruby types:** String<br>
  **Platforms:** Fedora, RHEL, Amazon Linux The channel bonding interface that this interface is linked to.

- `slave`<br>
  **Ruby types:** String<br>
  **Platforms:** Fedora, RHEL, Amazon Linux Whether the interface is controlled by the channel bonding interface defined by `master`, above.

## Chef Vault is now included

Chef Client 13.4 now includes the `chef-vault` gem, making it easier for users of chef-vault to use their encrypted items.

## Windows `remote_file` resource with alternate credentials

The `remote_file` resource now supports the use of credentials on Windows when accessing a remote UNC path on Windows such as `\\myserver\myshare\mydirectory\myfile.txt`. This allows access to the file at that path location even if the Chef client process identity does not have permission to access the file. The new properties `remote_user`, `remote_domain`, and `remote_password` may be used to specify credentials with access to the remote file so that it may be read.

**Note**: This feature is mainly used for accessing files between two nodes in different domains and having different user accounts. In case the two nodes are in same domain, `remote_file` resource does not need `remote_user` and `remote_password` specified because the user has the same access on both systems through the domain.

### Properties

The following properties are new for the `remote_file` resource:

- `remote_user`<br>
  **Ruby types:** String<br>
  _Windows only:_ The user name of a user with access to the remote file specified by the `source` property. Default value: `nil`. The user name may optionally be specifed with a domain, i.e. `domain\user` or `user@my.dns.domain.com` via Universal Principal Name (UPN) format. It can also be specified without a domain simply as `user` if the domain is instead specified using the `remote_domain` attribute. Note that this property is ignored if `source` is not a UNC path. If this property is specified, the `remote_password` property **must** be specified.

- `remote_password`<br>
  **Ruby types** String<br>
  _Windows only:_ The password of the user specified by the `remote_user` property. Default value: `nil`. This property is mandatory if `remote_user` is specified and may only be specified if `remote_user` is specified. The `sensitive` property for this resource will automatically be set to `true` if `remote_password` is specified.

- `remote_domain`<br>
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

- `:add` - Add an item to the system path
- `:remove` - Remove an item from the system path

### Properties

- `path` - Name attribute. The name of the value to add to the system path

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

- `:add`: creates a preferences file under /etc/apt/preferences.d
- `:remove`: Removes the file, therefore unpin the package

### Properties

- `package_name`: name attribute. The name of the package
- `glob`: Pin by glob() expression or regexp surrounded by /.
- `pin`: The package version/repository to pin
- `pin_priority`: The pinning priority aka "the highest package version wins"

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

- `:add` - adds a repo
- `:delete` - removes a repo

### Properties

- `repo_name` - repository name if different from the resource name (name property)
- `type` - the repository type. default: 'NONE'
- `description` - the description of the repo that will be shown in `zypper repos`
- `baseurl` - the base url of the repo
- `path` - the relative path from the `baseurl`
- `mirrorlist` - the url to the mirrorlist to use
- `gpgcheck` - should we gpg check the repo (true/false). default: true
- `gpgkey` - location of repo key to import
- `priority` - priority of the repo. default: 99
- `autorefresh` - should the repository be automatically refreshed (true/false). default: true
- `keeppackages` - should packages be saved (true/false). default: false
- `refresh_cache` - should package cache be refreshed (true/false). default: true
- `enabled` - should this repository be enabled (true/false). default: true
- `mode` - the file mode of the repository file. default: "0644"

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

- platform: bigip
- platform_family: rhel

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

- platform: clearlinux
- platform_family: clearlinux

#### ClearOS

- platform: clearos
- platform_family: rhel

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

- `which ruby` in 12.x will return any system ruby and fall back to the embedded ruby if using omnibus
- `which ruby` in 13.x will return any system ruby and will not find the embedded ruby if using omnibus
- `shell_out_with_systems_locale("which ruby")` behaves the same as `which ruby` above
- `shell_out("which ruby")` in 12.x will return any system ruby and fall back to the embedded ruby if using omnibus
- `shell_out("which ruby")` in 13.x will always return the omnibus ruby first (but will find the system ruby if not using omnibus)

The PATH in `shell_out` can also be overridden:

- `shell_out("which ruby", env: { "PATH" => nil })` - behaves like shell_out_with_systems_locale()
- `shell_out("which ruby", env: { "PATH" => [...include PATH string here...] })` - set it arbitrarily however you need

Since most providers which launch custom user commands use `shell_out_with_systems_locale` (service, execute, script, etc) the behavior will be that those commands that used to be having embedded omnibus paths injected into them no longer will. Generally this will fix more problems than it solves, but may causes issues for some use cases.

### Default guard clauses (`not_if`/`only_if`) do not change the PATH or other env vars

The implementation switched to `shell_out_with_systems_locale` to match `execute` resource, etc.

### Chef Client will now exit using the RFC062 defined exit codes

Chef Client will only exit with exit codes defined in RFC 062\. This allows other tooling to respond to how a Chef run completes. Attempting to exit Chef Client with an unsupported exit code (either via `Chef::Application.fatal!` or `Chef::Application.exit!`) will result in an exit code of 1 (GENERIC_FAILURE) and a warning in the event log.

When Chef Client is running as a forked process on unix systems, the standardized exit codes are used by the child process. To actually have Chef Client return the standard exit code, `client_fork false` will need to be set in Chef Client's configuration file.
