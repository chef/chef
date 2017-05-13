======================================================
Deprecation: Filesystem2 attribute removal (OHAI-12)
======================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_ohai_filesystem_v2.rst>`__

In Ohai/Chef 13 we replaced the existing Filesystem plugin with the Filesystem V2 plugin. That was done by having Ohai populate both ``node['filesystem']`` and ``node['filesystem_v2']`` with the data previously found at ``node['filesystem2']``. In Chef 15 we will no longer populate ``node['filesystem2']``.

Remediation
=============

If you have a cookbook that relies on data from ``node['filesystem2']`` you will need to update the code to instead use ``node['filesystem']``. Keep in mind that if you're attempting to support Chef < 13 the data structure of node['filesystem'] will be different.
