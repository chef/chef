=======================================================
Deprecation: Resource Property Name Collision (CHEF-11)
=======================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_property_name_collision.rst>`__

.. tag deprecation_property_name_collision

A resource property, defined with the ``property`` method, conflicts with an already-existing property or method. This could indicate an error that could lead to unintended behavior.

.. end_tag

All Ruby objects have a number of methods that are expected to always be available. When a resource property is created, Ruby methods for setting and getting the property value are created for you. If a resource creates a property which is named the same as an existing method, the original method will be overwritten.

For example, every Ruby object has a ``hash`` method which is expected to return a number. If a resource creates a property named ``hash`` and stores a string instead, it could cause errors in your Chef run.

A deprecation warning is logged when this occurs. In Chef 13, this will raise an exception and your Chef run will fail.

Remediation
=============

Modify the resource and choose a different name for the property that does not conflict with an already-existing method name.
