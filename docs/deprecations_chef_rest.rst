=====================================================
Deprecation: Chef REST (CHEF-9)
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_chef_rest.rst>`__

.. tag deprecation_chef_rest

The ``Chef::REST`` class will be removed.

.. end_tag

``Chef::REST`` was deprecated in 12.7.2, and will be removed in Chef 13.

Remediation
=============

If writing code designed to be run internally to Chef, for example in a cookbook or a knife plugin, transition to using ``Chef::ServerAPI``. In most cases this is as simple as creating a ``Chef::ServerAPI`` instance rather than a ``Chef::REST`` one.

If writing code to interact with a Chef Server from other code, move to the `chef-api gem <https://rubygems.org/gems/chef-api>`__.

