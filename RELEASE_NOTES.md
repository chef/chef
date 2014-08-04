# Chef Client Release Notes:

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
