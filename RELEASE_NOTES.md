_This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team. Please see <https://docs.chef.io/release_notes.html> for the official Chef release notes._

# Chef Client Release Notes 13.1:

## Newly Introduced Deprecations

### Removal of support for Ohai version 6 plugins (OHAI-10)

<https://docs.chef.io/deprecations_ohai_filesystem.html>

In Chef/Ohai 14 (April 2018) we will remove support for loading Ohai v6 plugins, which we deprecated in Ohai 7/Chef 11.12.

### Cloud V2 attribute removal. (OHAI-11)

<https://docs.chef.io/deprecations_ohai_cloud_v2.html>

In Chef/Ohai 15 (April 2019) we will no longer write data to node['cloud_v2']. In Chef/Ohai 13 we deprecated the existing Cloud plugin and instead used CloudV2 to write to both node['cloud'] and node['cloud_v2']. Removing the existing "v2" namespace completes this plugin migration.

### Filesystem2 attribute removal. (OHAI-12)

<https://docs.chef.io/deprecations_ohai_filesystem_v2.html>

In Chef/Ohai 15 (April 2019) we will no longer write data to node['filesystem2']. In Chef/Ohai 13 we deprecated the existing Filesystem plugin and instead used Filesystem2 to write to both node['filesystem'] and node['filesystem2']. Removing the existing "v2" namespace completes this plugin migration.
