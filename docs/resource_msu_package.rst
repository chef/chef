==========================================
msu_package
==========================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_msu_package.rst>`__

Use the **msu_package** resource to install Microsoft Update(MSU) packages on Microsoft Windows machines.

*New in Chef Client 12.17.*

Syntax
==========================================
A **msu_package** resource installs or removes Microsoft Update packages.

.. code-block:: ruby

   msu_package 'name' do
     source                     String
     action                     Symbol
   end

where

* ``msu_package`` is the resource
* ``'name'`` is the name of the resource block
* ``source`` is the local path or URL for the MSU package.

The full syntax for all of the properties that are available to the **msu_package** resource is:

.. code-block:: ruby

   msu_package 'name' do
      source                    String
      checksum                  String
      action                    Symbol
   end

Actions
=====================================================
This resource has the following actions:

:install
   Installs the MSU package from either a local file path or URL.

:remove
   Uninstalls the MSU package from its location on disk.

Properties
=====================================================
This resource has the following properties:

source
   **Ruby Type:** String

   The local file path or URL for the MSU package.

checksum
   **Ruby Type:** String

   SHA-256 digest used to verify the checksum of the downloaded MSU package.

Providers
=====================================================
.. tag resources_common_provider

Where a resource represents a piece of the system (and its desired state), a provider defines the steps that are needed to bring that piece of the system from its current state into the desired state.

.. end_tag

.. tag resources_common_provider_attributes

The chef-client will determine the correct provider based on configuration data collected by Ohai at the start of the chef-client run. This configuration data is then mapped to a platform and an associated list of providers.

Generally, it's best to let the chef-client choose the provider, and this is (by far) the most common approach. However, in some cases, specifying a provider may be desirable. There are two approaches:

* Use a more specific short name---``yum_package "foo" do`` instead of ``package "foo" do``, ``script "foo" do`` instead of ``bash "foo" do``, and so on---when available
* Use the ``provider`` property within the resource block to specify the long name of the provider as a property of a resource. For example: ``provider Chef::Provider::Long::Name``

.. end_tag

This resource has the following providers:

``Chef::Provider::Package::Msu``, ``msu_package``
   The provider for the Microsoft Windows platform.

Examples
=====================================================

.. tag msu_package_examples

**Using local path in source**

.. code-block:: ruby

   msu_package 'Install Windows 2012R2 Update KB2959977' do
     source 'C:\Users\xyz\AppData\Local\Temp\Windows8.1-KB2959977-x64.msu'
     action :install
   end

.. code-block:: ruby

   msu_package 'Remove Windows 2012R2 Update KB2959977' do
     source 'C:\Users\xyz\AppData\Local\Temp\Windows8.1-KB2959977-x64.msu'
     action :remove
   end

**Using URL in source**

.. code-block:: ruby

   msu_package 'Install Windows 2012R2 Update KB2959977' do
     source 'https://s3.amazonaws.com/my_bucket/Windows8.1-KB2959977-x64.msu'
     action :install
   end

.. code-block:: ruby

   msu_package 'Remove Windows 2012R2 Update KB2959977' do
     source 'https://s3.amazonaws.com/my_bucket/Windows8.1-KB2959977-x64.msu'
     action :remove
   end

.. end_tag
