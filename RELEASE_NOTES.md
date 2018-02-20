_This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team. Please see <https://docs.chef.io/release_notes.html> for the official Chef release notes._

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

- Systemd unit files are now verified before being installed.
- Added support for windows alternate user identity in execute resources.
- Added ed25519 key support for for ssh connections.

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

- `user`<br>
  **Ruby types:** String<br>
  The user name of the user identity with which to launch the new process. Default value: `nil`. The user name may optionally be specified with a domain, i.e. `domain\user` or `user@my.dns.domain.com` via Universal Principal Name (UPN) format. It can also be specified without a domain simply as `user` if the domain is instead specified using the `domain` attribute. On Windows only, if this property is specified, the `password` property **must** be specified.

- `password`<br>
  **Ruby types** String<br>
  _Windows only:_ The password of the user specified by the `user` property. Default value: `nil`. This property is mandatory if `user` is specified on Windows and may only be specified if `user` is specified. The `sensitive` property for this resource will automatically be set to `true` if `password` is specified.

- `domain`<br>
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

- Ensure that the Windows Administrator group can access the chef-solo nodes directory
- When loading a cookbook in Chef Solo, use `metadata.json` in preference to `metadata.rb`

## Deprecation Notice

- As of version 12.19, chef client will no longer be build or tested on the Cisco NX-OS and IOS XR platforms.

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

- **Deprecation ID**: OHAI-1
- **Remediation Docs**: <https://docs.chef.io/deprecations_ohai_legacy_config.html>
- **Expected Removal**: Ohai 13 (April 2017)

### sigar gem based plugins removed

- **Deprecation ID**: OHAI-2
- **Remediation Docs**: <https://docs.chef.io/deprecations_ohai_sigar_plugins.html>
- **Expected Removal**: Ohai 13 (April 2017)

### run_command and popen4 helper methods removed

- **Deprecation ID**: OHAI-3
- **Remediation Docs**: <https://docs.chef.io/deprecations_ohai_run_command_helpers.html>
- **Expected Removal**: Ohai 13 (April 2017)

### libvirt plugin attributes moved

- **Deprecation ID**: OHAI-4
- **Remediation Docs**: <https://docs.chef.io/deprecations_ohai_libvirt_plugin.html>
- **Expected Removal**: Ohai 13 (April 2017)

### Windows CPU plugin attribute changes

- **Deprecation ID**: OHAI-5
- **Remediation Docs**: <https://docs.chef.io/deprecations_ohai_windows_cpu.html>
- **Expected Removal**: Ohai 13 (April 2017)

### DigitalOcean plugin attribute changes

- **Deprecation ID**: OHAI-6
- **Remediation Docs**: <https://docs.chef.io/deprecations_ohai_digitalocean.html>
- **Expected Removal**: Ohai 13 (April 2017)
