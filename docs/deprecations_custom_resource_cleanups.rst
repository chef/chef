=======================================================
Deprecation: Custom Resource Cleanups (CHEF-5)
=======================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_custom_resource_cleanups.rst>`__

.. tag deprecations_custom_resource_cleanups

We are continuously improving and streamlining the way custom resources work in Chef, to make it easier for cookbook authors and Chef developers to build resources.

.. end_tag

This page documents many deprecations over the course of many Chef releases.

Nil Properties
==================

In current versions of Chef, ``nil`` was often used to mean that a property had no good default, and needed to be set by the user. However, it is often to useful to set a property to ``nil``, meaning that it's not set and should be ignored. In Chef 13, it is an error to set ``default: nil`` on a property if that property doesn't allow ``nil`` as a valid value.

Remediation
--------------

If it is valid for the property to be set to nil, then update the property to include that.

.. code-block:: ruby

  property :my_nillable_property, [ String, nil ], default: nil

Otherwise, remove the ``default: nil`` statement from the property.

Invalid Defaults
==================

Current versions of Chef emit a warning when a property's default value is not valid. This is often because the type of the default value doesn't match the specification of the property. For example:

.. code-block:: ruby

  property :my_property, [ String ], default: []

sets the type of the property to be a String, but then sets the default to be an Array. In Chef 13, this will be an error.

Remediation
--------------

Ensure that the default value of a property is correct.

Property Getters
=======================

When writing a resource in Chef 12, calling ``some_property nil`` behaves as a getter, returning the value of ``some_property``. In Chef 13, this will change to set ``some_property`` to ``nil``.

Remediation
--------------

Simply write ``some_property`` when retrieving the value of ``some_property``.

Specifying both "default" and "name_property" on a resource
============================================================

Current versions of Chef emit a warning if the property declaration has both ``default`` and ``name_property`` set. In Chef 13, that will become an error. For example:

.. code-block:: ruby

  property :my_property, [ String ], default: [], name_property: true

Remediation
------------

A property can either have a default, or it can be a "name" property (meaning that it will take the value of the resource's name if not otherwise specified), but not both.

Overriding provides?
==========================

Some providers override the ``provides?`` method, used to check whether they are a valid provider on the current platform. In Chef 13, this will cause an error if the provider does not also register themselves with the ``provides`` call.

Example
--------

.. code-block:: ruby

  def provides?
    true
  end

Remediation
------------

.. code-block:: ruby

  provides :my_provider

  def provides?
    true
  end

Don't use the updated method
=============================

The ``updated=(true_or_false)`` method is deprecated and will be removed from Chef 13.

Example
--------

.. code-block:: ruby

  action :foo do
    updated = true
  end

Remediation
------------

.. code-block:: ruby

  action :foo do
    updated_by_last_action true
  end

Don't use the dsl_name method
=============================

The ``dsl_name`` method is deprecated and will be removed from Chef 13. It has been replaced by ``resource_name``.

Example
--------

.. code-block:: ruby

  my_resource = MyResource.dsl_name

Remediation
------------

.. code-block:: ruby

  my_resource = MyResource.resource_name

Don't use the provider_base method
====================================

The ``Resource.provider_base`` allows the developer to specify an alternative module to load providers from, rather than ``Chef::Provider``. It is deprecated and will be removed in Chef 13. Instead, the provider should call ``provides`` to register itself, or the resource should call ``provider`` to specify the provider to use.

