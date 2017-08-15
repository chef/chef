=====================================================
Deprecation: Ohai::Config removal (OHAI-1)
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_ohai_legacy_config.rst>`__

Ohai 8.8.0 (Chef 12.6.0) introduced a new Ohai configuration system as defined in `RFC-053
<https://github.com/chef/chef-rfc/blob/master/rfc053-ohai-config.md>`__. This system replaced the existing usage of Ohai::Config config system, which will be removed in Chef 13.

Remediation
=============

Previously Ohai configuration values in the Chef client.rb file need to be updated for the new configuration system format. For example to configuration the plugin_path value previously you would set ``Ohai::Config.ohai[:plugin_path] = "/etc/chef/ohai/plugins.local"`` where as you would now use ``ohai.plugin_path = "/etc/chef/ohai/plugins.local"``. See the `Ohai Configuration Documentation </ohai.html#ohai-settings-in-client-rb>`__ for additional usage information.
