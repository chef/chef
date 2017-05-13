=======================================================
Deprecation: Resource Cloning (CHEF-3694)
=======================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_resource_cloning.rst>`__

.. tag deprecations_resource_cloning

Chef allows resources to be created with duplicate names, rather than treating that as an error. This means that several cookbooks can request the same package be installed, without needing to carefully create unique names.
This is problematic because having multiple resources named the same makes it impossible to safely deliver notifications to the right resource.

.. end_tag

The behaviour in Chef 12 and earlier, which is now deprecated, is that we will try to clone the existing resource, and then apply any properties from the new resource. For example:

.. code-block:: ruby

  file "/etc/my_file" do
    owner "ken"
  end

  file "/etc/my_file" do
    mode "0755"
  end

will result in the second instance having the following properties:

.. code-block:: ruby

  file "/etc/my_file" do
    owner "ken"
    mode "0755"
  end

Resource cloning was deprecated in Chef 10.18.0 and will be removed in Chef 13.

.. note:: Chef will only emit a deprecation warning in the situation that a cloned resource is significantly different from the existing one.


Remediation
=============

Ensure that resources that are intended to be notified are named uniquely. 
