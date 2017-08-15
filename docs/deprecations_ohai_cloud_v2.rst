==================================================
Deprecation: Cloud_v2 attribute removal (OHAI-11)
==================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_ohai_cloud_v2.rst>`__

In Ohai/Chef 13 we replaced the existing Cloud plugin with the Cloud V2 plugin. That was done by having Ohai populate both ``node['cloud']`` and ``node['cloud_v2']`` with the data previously found at ``node['cloud_v2']``. In Chef 15 we will no longer populate ``node['cloud_v2']``.

Remediation
=============

If you have a cookbook that relies on data from ``node['cloud_v2']`` you will need to update the code to instead use ``node['cloud']`` attributes. Keep in mind that if you're attempting to support Chef < 13 this data will be different.
