=====================================================
Deprecation: Sigar gem based plugins removal (OHAI-2)
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_ohai_sigar_plugins.rst>`__

When Ohai was first released it depended on the sigar gem for discovering system configuration details. As time went on Ohai was expanded with built-in discovery methods for various platforms. The sigar gem was still required by Ohai and used primarily for the HP-UX platform. The SIGAR project is no longer active, and there is no longer an active port of Ruby to HP-UX. Due to this we've chosen to remove the sigar dependency and all sigar-based plugins from Ohai 13. There is no anticipated impact for Chef Foundation Platforms or Secondary Platforms. See the :doc:`Platforms <platforms>` page for a complete list of platforms.
