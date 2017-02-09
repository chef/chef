_This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team. Please see <https://docs.chef.io/release_notes.html> for the official Chef release notes._

# Chef Client Release Notes 12.18:

## Highlighted enhancements for this release:

- You can now specify the acceptable return codes from the chocolatey_package resource using the returns property.
- You can now enable chef-client to run as a scheduled task directly from the client MSI on Windows hosts.
- The package provider now supports DNF packages for Fedora and upcoming RHEL releases
- Added support for windows alternate user identity in execute resources.

### Windows alternate user identity execute support

The `execute` resource and simliar resources such as `script`, `batch`, and `powershell_script`now support the specification of credentials on Windows so that the resulting process is created with the security identity that corresponds to those credentials.

**Note**: For this feature the user that Chef runs as needs the 'SE_ASSIGNPRIMARYTOKEN_NAME' or 'SeAssignPrimaryTokenPrivilege' user right, when running as a service. By default the user has only LocalSystem and NetworkService rights.

This is how the right can be added for a user in the recipe:
```ruby
# Add 'SeAssignPrimaryTokenPrivilege' for the user
Chef::ReservedNames::Win32::Security.add_account_right('<user>', 'SeAssignPrimaryTokenPrivilege')

# Check if the user has 'SeAssignPrimaryTokenPrivilege' rights
Chef::ReservedNames::Win32::Security.get_account_right('<user>').include?('SeAssignPrimaryTokenPrivilege')
```

#### Properties

The following properties are new or updated for the `execute`, `script`, `batch`, and `powershell_script` resources and any resources derived from them:

  *   `user`</br>
      **Ruby types:** String</br>
      The user name of the user identity with which to launch the new process.
      Default value: `nil`. The user name may optionally be specifed
      with a domain, i.e. `domain\user` or `user@my.dns.domain.com` via Universal Principal Name (UPN)
      format. It can also be specified without a domain simply as `user` if the domain is
      instead specified using the `domain` attribute. On Windows only, if this property is specified, the `password`
      property **must** be specified.

  *   `password`</br>
      **Ruby types** String</br>
      *Windows only:* The password of the user specified by the `user` property.
      Default value: `nil`. This property is mandatory if `user` is specified on Windows and may only
      be specified if `user` is specified. The `sensitive` property for this resource will
      automatically be set to `true` if `password` is specified.

  *   `domain`</br>
      **Ruby types** String</br>
      *Windows only:* The domain of the user user specified by the `user` property.
      Default value: `nil`. If not specified, the user name and password specified
      by the `user` and `password` properties will be used to resolve
      that user against the domain in which the system running Chef client
      is joined, or if that system is not joined to a domain it will resolve the user
      as a local account on that system. An alternative way to specify the domain is to leave
      this property unspecified and specify the domain as part of the `user` property.

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

- Fixed exposure of sensitive data of resources marked as sensitive inside Reporting. Before you were able to see the sensitive data on the Run History tab in the Chef Manage Console. Now we are sending a new blank resource if the resource is marked as sensitive, this way we will not compromise any sensitive data.

  _Note: Old data that was already sent to Reporting marked as sensitive will continue to be displayed. Apologies._

## New deprecations introduced in this release:

### Chef::Platform Helper Methods

- **Deprecation ID**: 13
- **Remediation Docs**: <https://docs.chef.io/deprecations_chef_platform_methods.html>
- **Expected Removal**: Chef 13 (April 2017)

### run_command Helper Method

- **Deprecation ID**: 14
- **Remediation Docs**: <https://docs.chef.io/deprecations_run_command.html>
- **Expected Removal**: Chef 13 (April 2017)
