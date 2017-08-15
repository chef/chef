=============================================================================
Deprecation: Filesystem plugin replaced by the Filesystem V2 plugin. (OHAI-9)
=============================================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_ohai_filesystem.rst>`__

In Ohai/Chef 13 we replaced the existing Filesystem plugin with the Filesystem2 plugin. This was done by having the Filesystem2 plugin populate both ``node['fileystem2']`` and ``node['filesystem']``. The Filesystem2 plugin includes a different data format that resolves many of the longstanding bugs in the Filesystem plugin.

Remediation
=============

If you have a cookbook that relies on data from ``node['filesystem']`` you will need to update the code to use data in the new format when migrating to Chef 13 or later. On a Chef 12 or earlier node you can view the new format by running `ohai filesystem2` or on a Chef 13+ node you can run ``ohai filesystem``.

The output of the filesystem plugin is too large to show the difference here, but as an example code that may reference ``node['/dev/xvda1']['kb_size']`` would need to be updated to reference ``node['by_device']['/dev/xvda1']['kb_size']`` as filesystem data is now displayed by both devices and mounts.
