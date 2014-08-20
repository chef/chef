# Chef Client Release Notes 12.0.0:

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

In order to avoid redownloading the file_cache for all the cookbooks and files that are skipped when an
override run list is used, when an override run list is set the file cache is not cleaned at all.

## Dropped Support For Ruby 1.8.7/1.9.1/1.9.2

Ruby 1.8.7, 1.9.1 and 1.9.2 are no longer supported.

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

## 'group' provider on OSX properly uses 'dscl' to determine existing groups

On OSX, the 'group' provider would use 'etc' to determine existing groups,
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
