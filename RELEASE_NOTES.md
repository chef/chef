# Chef Client Release Notes 12.1.0:

# Internal API Changes in this Release

## Experimental Audit Mode Feature

This is a new feature intended to provide _infrastructure audits_.  Chef already allows you to configure your infrastructure
with code, but there are some use cases that are not covered by resource convergence.  What if you want to check that
the application Chef just installed is functioning correctly?  If it provides a status page an audit can check this
and validate that the application has database connectivity.

Audits are performed by leveraging [Serverspec](http://serverspec.org/) and [RSpec](https://relishapp.com/rspec) on the
node.  As such the syntax is very similar to a normal RSpec spec.

### Syntax

```ruby
control_group "Database Audit" do

  control "postgres package" do
    it "should not be installed" do
      expect(package("postgresql")).to_not be_installed
    end
  end

  let(:p) { port(111) }
  control p do
    it "has nothing listening" do
      expect(p).to_not be_listening
    end
  end

end
```

Using the example above I will break down the components of an Audit:

* `control_group` - This named block contains all the audits to be performed during the audit phase.  During Chef convergence
 the audits will be collected and ran in a separate phase at the end of the Chef run.  Any `control_group` block defined in
 a recipe that is ran on the node will be performed.
* `control` - This keyword describes a section of audits to perform.  The name here should either be a string describing
the system under test, or a [Serverspec resource](http://serverspec.org/resource_types.html).
* `it` - Inside this block you can use [RSpec expectations](https://relishapp.com/rspec/rspec-expectations/docs) to
write the audits.  You can use the Serverspec resources here or regular ruby code.  Any raised errors will fail the
audit.

### Output and error handling

Output from the audit run will appear in your `Chef::Config[:log_location]`.  If an audit fails then Chef will raise
an error and exit with a non-zero status.

### Further reading

More information about the audit mode can be found in its
[RFC](https://github.com/opscode/chef-rfc/blob/master/rfc035-audit-mode.md)

# End-User Changes

## OpenBSD Package provider was added

The package resource on OpenBSD is wired up to use the new OpenBSD package provider to install via pkg_add on OpenBSD systems.

## Case Insensitive URI Handling

Previously, when a URI scheme contained all uppercase letters, Chef would reject the URI as invalid. In compliance with RFC3986, Chef now treats URI schemes in a case insensitive manner.

## Drop SSL Warnings
Now that the default for SSL checking is on, no more warning is emitted when SSL
checking is off.

## Multi-package Support
The `package` provider has been extended to support multiple packages. This
support is new and and not all subproviders yet support it. Full support for
`apt` and `yum` has been implemented.

## chef_gem deprecation of installation at compile time

A `compile_time` flag has been added to the chef_gem resource to control if it is installed at compile_time or not.  The prior behavior has been that this
resource forces itself to install at compile_time which is problematic since if the gem is native it forces build_essentials and other dependent libraries
to have to be installed at compile_time in an escalating war of forcing compile time execution.  This default was engineered before it was understood that a better
approach was to lazily require gems inside of provider code which only ran at converge time and that requiring gems in recipe code was bad practice.

The default behavior has not changed, but every chef_gem resource will now emit out a warning:

```
[2015-02-06T13:13:48-08:00] WARN: chef_gem[aws-sdk] chef_gem compile_time installation is deprecated
[2015-02-06T13:13:48-08:00] WARN: chef_gem[aws-sdk] Please set `compile_time false` on the resource to use the new behavior.
[2015-02-06T13:13:48-08:00] WARN: chef_gem[aws-sdk] or set `compile_time true` on the resource if compile_time behavior is required.
```

The preferred way to fix this is to make every chef_gem resource explicit about compile_time installation (keeping in mind the best-practice to default to false
unless there is a reason):

```ruby
chef_gem 'aws-sdk' do
  compile_time false
end
```

There is also a Chef::Config[:chef_gem_compile_time] flag which has been added.  If this is set to true (not recommended) then chef will only emit a single
warning at the top of the chef-client run:

```
[2015-02-06T13:27:35-08:00] WARN: setting chef_gem_compile_time to true is deprecated
```

It will behave like Chef 10 and Chef 11 and will default chef_gem to compile_time installations and will suppress
subsequent warnings in the chef-client run.

If this setting is changed to 'false' then it will adopt Chef-13 style behavior and will default all chef_gem installs to not run at compile_time by default.  This
may break existing cookbooks.

* All existing cookbooks which require compile_time true MUST be updated to be explicit about this setting.
* To be considered high quality, cookbooks which require compile_time true MUST be rewritten to avoid this setting.
* All existing cookbooks which do not require compile_time true SHOULD be updated to be explicit about this setting.

For cookbooks that need to maintain backwards compatibility a `respond_to?` check should be used:

```
chef_gem 'aws-sdk' do
  compile_time false if respond_to?(:compile_time)
end
```

# Chef Client Release Notes 12.0.0:

# Internal API Changes in this Release

These changes do not impact any cookbook code, but may impact tools that
use the code base as a library. Authors of tools that rely on Chef
internals should review these changes carefully and update their
applications.

## Changes to CookbookUpload

`Chef::CookbookUpload.new` previously took a path as the second
argument, but due to internal changes, this parameter was not used, and
it has been removed. See: https://github.com/opscode/chef/commit/12c9bed3a5a7ab86ff78cb660d96f8b77ad6395d

## Changes to FileVendor

`Chef::Cookbook::FileVendor` was previously configured by passing a
block to the `on_create` method; it is now configured by calling either
`fetch_from_remote` or `fetch_from_disk`. See: https://github.com/opscode/chef/commit/3b2b4de8e7f0d55524f2a0ccaf3e1aa9f2d371eb

# End-User Changes

## Chef 12 Attribute Changes

The Chef 12 Attribute RFC 23 (https://github.com/opscode/chef-rfc/blob/master/rfc023-chef-12-attributes-changes.md) has been merged into
Chef.  This adds the ability to remove precedence levels (or all levels) of attributes in recipes code, or to
force setting an attribute precedence level.  The major backwards incompatible change to call out in this RFC is that
`node.force_default!` and `node.force_override!` have changed from accessors to setters, and any cookbook code that used these functions
(extremely uncommon) simply needs to drop the exclamation point off of the method in order to use the accessor.

## Knife Prefers `config.rb` to `knife.rb`.

Knife will now look for `config.rb` in preference to `knife.rb` for its
configuration file. The syntax and configuration options available in
`config.rb` are identical to `knife.rb`. Also, the search path for
configuration files is unchanged.

At this time, it is _recommended_ that users use `config.rb` instead of
`knife.rb`, but `knife.rb` is not deprecated; no warning will be emitted
when using `knife.rb`. Once third-party application developers have had
sufficient time to adapt to the change, `knife.rb` will become
deprecated and config.rb will be preferred.

## Bootstrap Changes

Chef Client 12 introduces a set of changes to `knife bootstrap`. Here is the list of changes:

* Unused / untested bootstrap templates that install Chef Client from rubygems are removed. The recommended installation path for Chef Client is to use the omnibus packages. `chef-full` template (which is the default) installs Chef Client using omnibus packages on all the supported platforms.
* `--distro` & `--template-file` options are deprecated in Chef 12 in favor of `--boostrap-template` option. This option can take a bootstrap template name (e.g. 'chef-full') or the full path to a bootstrap template.
* Chef now configures `:ssl_verify_mode` & `:verify_api_cert` config options on the node that is being bootstrapped. This setting can be controlled by `:node_ssl_verify_mode` & `:node_verify_api_cert` CLI options. If these are not specified the configured value will be inferred from knife config.

## Solaris Mount Provider

The Solaris provider now supports specifying the fsck_device attribute (which defaults to '-' for backwards compat).

## Version Constraints in value_for_platform

The `value_for_platform` helper can now take version constraints like `>=` and `~>`.  This is particularly useful for users
of RHEL 7 where the version numbers now look like `7.0.<buildnumber>`, so that they can do:

```ruby
value_for_platform(
  "redhat" => {
    "~> 7.0" => "version 7.x.y"
    ">= 8.0" => "version 8.0.0 and greater"
  }
}
```

Note that if two version constraints match it is considered ambiguous and will raise an Exception.  An exact match, however, will
always take precedence over a version constraint.

## Git SCM provider now support environment attribute

You can now pass in a hash of environment variables into the git provider:

```ruby
git "/opt/mysources/couch" do
  repository "git://git.apache.org/couchdb.git"
  revision "master"
  environment  { 'VAR' => 'whatever' }
  action :sync
end
```

The git provider already automatically sets `ENV['HOME']` and `ENV['GIT_SSH']` but those can both be overridden
by passing them into the environment hash if the defaults are not appropriate.

## DSCL user provider now supports Mac OS X 10.7 and above.

DSCL user provider in Chef has supported setting passwords only on Mac OS X 10.6. In this release, Mac OS X versions 10.7 and above are now supported. Support for Mac OS X 10.6 is dropped from the dscl provider since this version is EOLed by Apple.

In order to support configuring passwords for the users using shadow hashes two new attributes `salt` & `iterations` are added to the user resource. These attributes are required to make the new [SALTED-SHA512-PBKDF2](http://en.wikipedia.org/wiki/PBKDF2) style shadow hashes used in Mac OS X versions 10.8 and above.

User resource on Mac supports setting password both using plain-text password or using the shadow hash. You can simply set the `password` attribute to the plain text password to configure the password for the user. However this is not ideal since including plain text passwords in cookbooks (even if they are private) is not a good idea. In order to set passwords using shadow hash you can follow the instructions below based on your Mac OS X version.

## Mac OS X default package provider is now Homebrew

Per [Chef RFC 016](https://github.com/opscode/chef-rfc/blob/master/rfc016-homebrew-osx-package-provider.md), the default provider for the `package` resource on Mac OS X is now [Homebrew](http://brew.sh). The [homebrew cookbook's](https://supermarket.getchef.com/cookbooks/homebrew) default recipe, or some other method is still required for getting homebrew installed on the system. The cookbook won't be strictly required just to install packages from homebrew on OS X, though. To use this, simply use the `package` resource, or the `homebrew_package` shortcut resource:

```ruby
package 'emacs'
```

Or,

```ruby
homebrew_package 'emacs'
```

The macports provider will still be available, and can be used with the shortcut resource, or by using the `provider` attribute:

```ruby
macports_package 'emacs'
```

Or,

```ruby
package 'emacs' do
  provider Chef::Provider::Package::Macports
end
```

### Providing `homebrew_user`

Homebrew recommends being ran as a non-root user, whereas Chef recommends being ran with root privileges.  The
`homebrew_package` provider has logic to try and determine which user to install Homebrew packages as.

By default, the `homebrew_package` provider will try to execute the homebrew command as the owner of the `/usr/local/bin/brew`
executable.  If that executable does not exist, Chef will try to find it by executing `which brew`.  If that cannot be
found, Chef then errors.  The Homebrew recommendation is the default install, which will place the executable at
`/usr/local/bin/brew` owned by a non-root user.

You can circumvent this by providing the `homebrew_package` a `homebrew_user` attribute, like:

```ruby
# provided as a uid
homebrew_package 'emacs' do
  homebrew_user 1001
end

# provided as a string
homebrew_package 'vim' do
  homebrew_user 'user1'
end
```

Chef will then execute the Homebrew command as that user.  The `homebrew_user` attribute can only be provided to the
`homebrew_package` resource, not the `package` resource.

## DSCL user provider now supports Mac OS X 10.7 and above.

DSCL user provider in Chef has supported setting passwords only on Mac OS X 10.6. In this release, Mac OS X versions 10.7 and above are now supported. Support for Mac OS X 10.6 is dropped from the dscl provider since this version is EOLed by Apple.

In order to support configuring passwords for the users using shadow hashes two new attributes `salt` & `iterations` are added to the user resource. These attributes are required to make the new [SALTED-SHA512-PBKDF2](http://en.wikipedia.org/wiki/PBKDF2) style shadow hashes used in Mac OS X versions 10.8 and above.

User resource on Mac supports setting password both using plain-text password or using the shadow hash. You can simply set the `password` attribute to the plain text password to configure the password for the user. However this is not ideal since including plain text passwords in cookbooks (even if they are private) is not a good idea. In order to set passwords using shadow hash you can follow the instructions below based on your Mac OS X version.

### Mac OS X 10.7

10.7 calculates the password hash using **SALTED-SHA512**. Stored shadow hash length is 68 bytes; first 4 bytes being salt and the next 64 bytes being the shadow hash itself. You can use below code in order to calculate password hashes to be used in `password` attribute on Mac OS X 10.7:

```
password = "my_awesome_password"
salt = OpenSSL::Random.random_bytes(4)
encoded_password = OpenSSL::Digest::SHA512.hexdigest(salt + password)
shadow_hash = salt.unpack('H*').first + encoded_password

# You can use this value in your recipes as below:

user "my_awesome_user" do
  password "c9b3bd....d843"  # Length: 136
end
```
### Mac OS X 10.8 and above

10.7 calculates the password hash using **SALTED-SHA512-PBKDF2**. Stored shadow hash length is 128 bytes. In addition to the shadow hash value, `salt` (32 bytes) and `iterations` (integer) is stored on the system. You can use below code in order to calculate password hashes on Mac OS X 10.8 and above:

```
password = "my_awesome_password"
salt = OpenSSL::Random.random_bytes(32)
iterations = 25000 # Any value above 20k should be fine.

shadow_hash = OpenSSL::PKCS5::pbkdf2_hmac(
  password,
  salt,
  iterations,
  128,
  OpenSSL::Digest::SHA512.new
).unpack('H*').first
salt_value = salt.unpack('H*').first

# You can use this value in your recipes as below:

user "my_awesome_user" do
  password "cbd1a....fc843"  # Length: 256
  salt "bd1a....fc83"        # Length: 64
  iterations 25000
end
```

## `name` Attribute is Required in Metadata

Previously, the `name` attribute in metadata had no effect on the name
of an uploaded cookbook, instead the name was always inferred from the
directory basename of the cookbook. The `name` attribute is now
respected when determining the name of a cookbook. Furthermore, the
`name` attribute is required when loading/uploading cookbooks.

## http_request resource no longer appends query string

Previously the http_request GET and HEAD requests appended a hard-coded "?message=resource_name"
query parameter that could not be overridden.  That feature has been dropped.  Cookbooks that
actually relied on that should manually add the message query string to the URL they pass to
the resource.

## Added Chef::Mixin::ShellOut methods to Recipe DSL

Added the ability to use shell_out, shell_out! and shell_out_with_systems_locale in the Recipe
DSL without needing to explicitly extend/include the mixin.

## Cookbook Synchronizer Cleans Deleted Files

At the start of the Chef client run any files which are in active cookbooks, but are no longer in the
manifest for the cookbook will be deleted from the cookbook file cache.

## When given an override run list Chef does not clean the file_cache

In order to avoid re-downloading the file_cache for all the cookbooks and files that are skipped when an
override run list is used, when an override run list is set the file cache is not cleaned at all.

## Dropped Support For Ruby 1.8 and 1.9

Ruby 1.8.7, 1.9.1, 1.9.2 and 1.9.3 are no longer supported.

## Changed no_lazy_load config default to True

Previously the default behavior of chef-client was lazily synchronize cookbook files and templates as
they were actually used.  With this setting being true, all the files and templates in a cookbook will
be synchronized at the beginning of the chef-client run.  This avoids the problem where time-sensitive
URLs in the cookbook manifest may timeout before the `cookbook_file` or `template` resource is actually
converged.  Many users find the lazy behavior confusing as well and expect that the cookbook should
be fully synchronized at the start.

Some users who distribute large files via cookbooks may see performance issues with this turned on.  They
should disable the setting and go back to the old lazy behavior, or else refactor how they are doing
file distribution (using `remote_file` to download artifacts from S3 or a similar service is usually a
better approach, or individual large artifacts could be encapsulated into individual different cookbooks).

## Changed file_staging_uses_destdir config default to True

Staging into the system's tempdir (usually /tmp or /var/tmp) rather than the destination directory can
cause issues with permissions or available space.  It can also become problematic when doing cross-devices
renames which turn move operations into copy operations (using mv uses a new inode on Unix which avoids
ETXTBSY exceptions, while cp reuses the inode and can raise that error).  Staging the tempfile for the
Chef file providers into the destination directory solve these problems for users.  Windows ACLs on the
directory will also be inherited correctly.

## Removed Rest-Client dependency

- cookbooks that previously were able to use rest-client directly will now need to install it via `chef_gem "rest-client"`.
- cookbooks that were broken because of the version of rest-client that chef used will now be able to track and install whatever
  version that they depend on.

## Chef local mode port ranges

- to avoid crashes, by default, Chef will now scan a port range and take the first available port from 8889-9999.
- to change this behavior, you can pass --chef-zero-port=PORT_RANGE (for example, 10,20,30 or 10000-20000) or modify Chef::Config.chef_zero.port to be a port string, an enumerable of ports, or a single port number.

## Knife now logs to stderr

Informational messages from knife are now sent to stderr, allowing you to pipe the output of knife to other commands without having to filter these messages out.

## Enhance `data_bag_item` to interact with encrypted data bag items

The `data_bag_item` dsl method can be used to load encrypted data bag items when an additional `secret` String parameter is included.
If no `secret` is provided but the data bag item is encrypted, `Chef::Config[:encrypted_data_bag_secret]` will be checked.

## 'group' provider on OS X properly uses 'dscl' to determine existing groups

On OS X, the 'group' provider would use 'etc' to determine existing groups,
but 'dscl' to add groups, causing broken idempotency if something existed
in /etc/group. The provider now uses 'dscl' for both idempotenty checks and
modifications.

## Windows Service Startup Type

When a Windows service is running and Chef stops it, the startup type will change from automatic to manual. A bug previously existed
that prevented you from changing the startup type to disabled from manual. Using the enable and disable actions will now correctly set
the service startup type to automatic and disabled, respectively. A new `windows_service` resource has been added that allows you to
specify the startup type as manual:

```
windows_service "BITS" do
  action :configure_startup
  startup_type :manual
end
```

You must use the windows_service resource to utilize the `:configure_startup` action and `startup_type` attribute. The service resource
does not support them.

## Client-side key generation enabled by default
When creating a new client via the validation_client account, Chef 11 servers allow the client to generate a key pair locally
and send the public key to the server, enhancing scalability. This was disabled by default, since client registration would not
work properly if the remote server implemented only the Chef 10 API.

## CookbookSiteStreamingUploader now uses ssl_verify_mode config option
The CookbookSiteStreamingUploader now obeys the setting of ssl_verify_mode in the client config. Was previously ignoring the
config setting and always set to VERIFY_NONE.

## Result filtering on `search` API.
`search` can take an optional `:filter_result`, which returns search data in the form specified
by the given Hash. This works analogously to the partial_search method from the [partial_search cookbook](https://supermarket.getchef.com/cookbooks/partial_search),
with `:filter_result` replacing `:keys`. You can also filter `knife search` results by supplying the `--filter-result`
or `-f` option and a comma-separated string representation of the filter hash.

## Unforked chef-client interval runs are disabled.
We no longer allow unforked interval runs of `chef-client`. CLI arguments with flag combinations `--interval SEC --no-fork` or
`--daemonize --no-fork` will fail immediately. Configuration options `interval` and `daemonize` will also fail with
error when `client_fork false` is set.

## Interval sleep occurs before converge
When running chef-client or chef-solo at intervals, the application will perform splay and interval sleep
before converging chef. (In previous releases, splay sleep occurred first, then convergence, then interval sleep).

## `--dry-run` option for knife cookbook site share
"knife cookbook site share" command now accepts a new command line option `--dry-run`. When this option is specified, command
  will display the files that are about to be uploaded to the Supermarket.

## New cookbook metadata attributes for Supermarket
Cookbook metadata now accepts `source_url` and `issues_url` that should point to the source code of the cookbook and
  the issue tracker of the cookbook. These attributes are being used by Supermarket.

## CHEF RFC-017 - File Specificity Overhaul
RFC-017 has two great advantages:
1. It makes it easy to create cookbooks by removing the need for `default/` folder when adding templates and cookbook files.
2. It enables the configuring a custom lookup logic when Chef is attempting to find cookbook files.

You can read more about this RFC [here](https://github.com/opscode/chef-rfc/blob/master/rfc017-file-specificity.md).

## JSON output for `knife status`
`knife status` command now supports two additional output formats:

1. `--medium`: Includes normal attributes in the output and presents the output as JSON.
1. `--long`: Includes all attributes in the output and presents the output as JSON.

## AIX Service Provider Support

Chef 12 now supports managing services on AIX, using both the SRC (Subsystem Resource Controller) as well as the BSD-style init system. SRC is the default; the BSD-style provider can be selected using `Chef::Provider::Service::AixInit`.

The SRC service provider will manage services as well as service groups. However, because SRC has no standard mechanism for starting services on system boot, `action :enable` and `action :disable` are not supported for SRC services. You may use the `execute` resource to invoke `mkitab`, for example, to add lines to `/etc/inittab` with the right parameters.

## `guard_interpreter` attribute for `powershell_script` defaults to `:powershell_script`
The default `guard_interpreter` attribute for the `powershell_script` resource is `:powershell_script`. This means that the
64-bit version of the PowerShell shell will be used to evaluate strings supplied to the `not_if` or `only_if` attributes of the
resource. Prior to this release, the default value was `:default`, which used the 32-bit version of the `cmd.exe` shell to evaluate the guard.

If you are using guard expressions with the `powershell_script` resource in your recipes, you should override the
`guard_interpreter` attribute to restore the behavior of guards for this resource in Chef 11:

```ruby
# The not_if will be evaluated with 64-bit PowerShell by default,
# So override it to :default if your guard assumes 32-bit cmd.exe
powershell_script 'make_safe_backup' do
  guard_interpreter :default # Chef 11 behavior
  code 'cp ~/data/nodes.json $env:systemroot/system32/data/nodes.bak'

  # cmd.exe (batch) guard below behaves differently in 32-bit vs. 64-bit processes
  not_if 'if NOT EXIST %SYSTEMROOT%\\system32\\data\\nodes.bak exit /b 1' 
end
```

If the code in your guard expression does not rely on the `cmd.exe` interpreter, e.g. it simply executes a process that should
return an exit code such as `findstr datafile sentinelvalue`, and does not rely on being executed from a 32-bit process, then it
should function identically when executed from the PowerShell shell and it is not necessary to override the attribute
to`:default` to restore Chef 11 behavior.

Note that with this change guards for the `powershell_script` resource will also inherit some attributes like `:architecture`, `:cwd`,
`:environment`, and `:path`.

## `guard_interpreter` attribute for `batch` resource defaults to `:batch`

The default `guard_interpreter` attribute for the `batch` resource is now `:batch`. This means that the
64-bit version of the `cmd.exe` shell will be used to evaluate strings supplied to the `not_if` or `only_if` attributes of the
resource. Prior to this release, the default value was `:default`, which used the 32-bit version of the `cmd.exe` shell to evaluate the guard.

Note that with this change guards for the `batch` resource will also inherit some attributes like `:architecture`, `:cwd`,
`:environment`, and `:path`.

Unless the code you supply to guard attributes (`only_if` and `not_if`) has logic that requires that the 32-bit version of
`cmd.exe` be used to evaluate the guard or you need to avoid the inheritance behavior of guard options, that code should function identically in this release of Chef and Chef 11 releases.

If an assumption of a 32-bit process for guard evaluation exists in your code, you can obtain the equivalent of Chef 11's 32-bit
process behavior by supplying an architecture attribute to the guard as follows:

```ruby
# The not_if will be evaluated with 64-bit cmd.exe by default,
# so you can override it with the :architecture guard option to
# make it 32-bit as it is in Chef 11
batch 'make_safe_backup' do
  code 'copy %USERPROFILE%\\data\\nodes.json %SYSTEMROOT%\\system32\\data\\nodes.bak'

  # cmd.exe (batch) guard code below behaves differently in 32-bit vs. 64-bit processes
  not_if 'if NOT EXIST %SYSTEMROOT%\\system32\\data\\nodes.bak exit /b 1', :architecture => :i386
end
```

If in addition to the 32-bit process assumption you also need to avoid the inheritance behavior, you can revert completely to
the Chef 11's 32-bit process, no inheritance behavior by supplying `:default` for the `guard_interpreter` as follows:

```ruby
# The not_if will be evaluated with 64-bit cmd.exe by default,
# so override it to :default if your guard assumes 32-bit cmd.exe
batch 'make_safe_backup' do
  guard_interpreter :default # Revert to Chef 11 behavior
  code 'copy %USERPROFILE%\\data\\nodes.json %SYSTEMROOT%\\system32\\data\\nodes.bak'

  # cmd.exe (batch) guard code below behaves differently in 32-bit vs. 64-bit processes
  not_if 'if NOT EXIST %SYSTEMROOT%\\system32\\data\\nodes.bak exit /b 1'
end
```

## Chef Client logs events to Windows Event Log on Windows

Chef 12 will log a small set of events to Windows Event Log. This feature is enabled by default, and can be disabled by the new config option `disable_event_logger`.

Events by default will be logged to the "Application" event log on Windows. Chef will log event when:
* Run starts
* Run completes
* Run fails

Information about these events can be found in `Chef::EventDispatch::Base`.

## Resource and Provider Resolution changes

Resource resolution and provider resolution has been made more dynamic in Chef-12.  The `provides` syntax on the 
Chef::Resource DSL (which has existed for 4 years) has been expanded to use platform_family and os and has been applied
to most resources.  This does early switching at compile time between different resources based on the node data returned
from ohai.  The effect is that previously the package resource on a CentOS machine invoked via `package "foo"` would be
an instance of Chef::Resource::Package but would use the Chef::Provider::Package::Yum provider.  After the changes to
the resources the resource will be an instance of Chef::Resource::YumPackage and will do the correct validation for
the yum package provider.

For the service resource it uses late validation via the Chef::ProviderResolver and will dynamically select which
service provider to use at package converge time right before the service provider actions are invoked.  This means
that if Chef is used to install systemd (or alternatively to remove it) then the ProviderResolver will be invoked
and will be able to determine the proper provider to start the service.  It also allows for multiple providers to
be invoked for a resource on a case-by-case basis.  The old static one-to-one Chef::Platform provider mapping was
inflexible since it cannot handle the case where an admin installs or removes a subsystem from a distro, and cannot
handle the case where there may be multiple providers that handle different kinds of services (e.g. Upstart, SysV,
etc).  This fixes the Ubuntu 14.04 service resource problems, and can handle arbitrarily complicated future distro
and administrative preferences dynamically.

