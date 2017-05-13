=======================================================
Deprecation: "Supports" metaproperty (CHEF-8)
=======================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_supports_property.rst>`__

.. tag deprecation_supports_property

The ``user`` resource previously allowed a cookbook author to set policy for the resource in two ways. The ``supports`` metaproperty, which is now deprecated, enabled the ``manage_home`` and ``non_unique`` properties to be set.

.. end_tag

The ``supports`` metaproperty was deprecated in Chef 12.14 and will be removed in Chef 13.

Example
===========

.. code-block:: ruby

  user "betty" do
    supports({
      manage_home: true,
      non_unique: true
    })
  end

Remediation
=============

Make the ``manage_home`` and ``non_unique`` settings properties rather than parts of the ``supports`` hash.

.. code-block:: ruby

  user "betty" do
    manage_home true
    non_unique true
  end

