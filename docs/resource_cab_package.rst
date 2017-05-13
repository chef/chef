==========================================
cab_package
==========================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_cab_package.rst>`__

Use the **cab_package** resource to install or remove Microsoft Windows cabinet (.cab) packages.

*New in Chef Client 12.15.*

Syntax
==========================================
A **cab_package** resource installs or removes a cabinet package from the specified file path.

.. code-block:: ruby

   cab_package 'name' do
     source                  String
   end

where

* ``cab_package`` is the resource
* ``name`` is the name of the resource block
* ``source`` is the local path or URL for the cabinet package

Actions
=====================================================
This resource has the following actions:

:install
   Installs the cabinet package.

:remove
   Removes the cabinet package.

Properties
=====================================================
This resource has the following properties:

source
   **Ruby Type:** String

   The local file path or URL for the CAB package.

   Changed in Chef Client 12.19 to allow URLs as valid source values.

Providers
=====================================================
This resource has the following provider:

``Chef::Provider::Package::Cab``, ``cab_package``
   The provider for the Microsoft Windows platform.

Examples
=====================================================

**Using local path in source**

.. code-block:: ruby

   cab_package 'Install .NET 3.5 sp1 via KB958488' do
     source 'C:\Users\xyz\AppData\Local\Temp\Windows6.1-KB958488-x64.cab'
     action :install
   end

.. code-block:: ruby

   cab_package 'Remove .NET 3.5 sp1 via KB958488' do
     source 'C:\Users\xyz\AppData\Local\Temp\Windows6.1-KB958488-x64.cab'
     action :remove
   end

**Using URL in source**

.. code-block:: ruby

   cab_package 'Install .NET 3.5 sp1 via KB958488' do
     source 'https://s3.amazonaws.com/my_bucket/Windows6.1-KB958488-x64.cab'
     action :install
   end

.. code-block:: ruby

   cab_package 'Remove .NET 3.5 sp1 via KB958488' do
     source 'https://s3.amazonaws.com/my_bucket/Temp\Windows6.1-KB958488-x64.cab'
     action :remove
   end

