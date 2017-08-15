=======================================================
Deprecation: Easy Install Resource (CHEF-6)
=======================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_easy_install.rst>`__

.. tag deprecation_easy_install

The Python community recommends that users prefer ``pip`` rather than ``easy_install`` to install python packages.

.. end_tag

The ``easy_install`` resource was deprecated in 12.10, and will be removed in Chef 13.

Remediation
===============

There is no built in replacement for ``easy_install`` in Chef. The `poise-python <https://supermarket.chef.io/cookbooks/poise-python>`__ cookbook provides a set of resources for managing Python installations.
