=====================================================
windows_package
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_windows_package.rst>`__

.. tag resource_package_windows

Use the **windows_package** resource to manage Microsoft Installer Package (MSI) packages for the Microsoft Windows platform.

.. end_tag

Changed in 12.4 to include ``checksum`` and ``remote_file_attributes`` and URL locations on the ``source`` properties. Changed in Chef Client 12.6 to support a greater variety of ``installer_type``; Changed in 12.0 for ``installer_type`` to require a symbol. 

Syntax
=====================================================
.. tag resource_package_windows_syntax

A **windows_package** resource block manages a package on a node, typically by installing it. The simplest use of the **windows_package** resource is:

.. code-block:: ruby

   windows_package 'package_name'

which will install the named package using all of the default options and the default action (``:install``).

The full syntax for all of the properties that are available to the **windows_package** resource is:

.. code-block:: ruby

   windows_package 'name' do
     checksum                   String
     installer_type             Symbol
     notifies                   # see description
     options                    String
     provider                   Chef::Provider::Package::Windows
     remote_file_attributes     Hash
     returns                    Integer, Array of integers
     source                     String # defaults to 'name' if not specified
     subscribes                 # see description
     timeout                    String, Integer
     action                     Symbol # defaults to :install if not specified
   end

where

* ``windows_package`` tells the chef-client to manage a package
* ``'name'`` is the name of the package
* ``action`` identifies which steps the chef-client will take to bring the node into the desired state
* ``checksum``, ``installer_type``, ``options``, ``package_name``, ``provider``, ``remote_file_attributes``, ``returns``, ``source``, and ``timeout`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
=====================================================
.. tag resource_package_windows_actions

This resource has the following actions:

``:install``
   Default. Install a package. If a version is specified, install the specified version of the package.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:remove``
   Remove a package.

.. end_tag

Properties
=====================================================
.. tag resource_package_windows_attributes

This resource has the following properties:

``checksum``
   **Ruby Type:** String

   The SHA-256 checksum of the file. Use to prevent a file from being re-downloaded. When the local file matches the checksum, the chef-client does not download it. Use when a URL is specified by the ``source`` property.

   New in Chef Client 12.4, changed in 12.6.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``installer_type``
   **Ruby Type:** Symbol

   A symbol that specifies the type of package. Possible values: ``:custom`` (such as installing a non-.msi file that embeds an .msi-based installer), ``:inno`` (Inno Setup), ``:installshield`` (InstallShield), ``:msi`` (Microsoft Installer Package (MSI)), ``:nsis`` (Nullsoft Scriptable Install System (NSIS)), ``:wise`` (Wise).

   Changed in Chef Client 12.6 to support diverse installer types; Changed in 12.0 to require a symbol.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_notifies_syntax

   The syntax for ``notifies`` is:

   .. code-block:: ruby

      notifies :action, 'resource[name]', :timer

   .. end_tag

``options``
   **Ruby Type:** String

   One (or more) additional options that are passed to the command.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider. See "Providers" section below for more information.

``remote_file_attributes``
   **Ruby Type:** Hash

   A package at a remote location define as a Hash of properties that modifes the properties of the **remote_file** resource.

   New in Chef Client 12.4.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``returns``
   **Ruby Types:** Integer, Array of integers

   A comma-delimited list of return codes that indicate the success or failure of the command that was run remotely. This code signals a successful ``:install`` action. Default value: ``0``.

``source``
   **Ruby Type:** String

   Optional. The path to a package in the local file system. The location of the package may be at a URL. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

   If the ``source`` property is not specified, the package name MUST be exactly the same as the display name found in **Add/Remove programs** or exacty the same as the ``DisplayName`` property in the appropriate registry key:

   .. code-block:: ruby

      HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall
      HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall
      HKEY_LOCAL_MACHINE\Software\Wow6464Node\Microsoft\Windows\CurrentVersion\Uninstall

   .. note:: If there are multiple versions of a package installed with the same display name, all of those packages will be removed unless a version is provided in the ``version`` property or unless it can be discovered in the installer file specified by the ``source`` property.

   Changed in Chef Client 12.4 to support URL locations.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_subscribes_syntax

   The syntax for ``subscribes`` is:

   .. code-block:: ruby

      subscribes :action, 'resource[name]', :timer

   .. end_tag

``timeout``
   **Ruby Types:** String, Integer

   The amount of time (in seconds) to wait before timing out. Default value: ``600`` (seconds).

.. end_tag

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

.. tag resource_package_windows_providers

This resource has the following providers:

``Chef::Provider::Package``, ``package``
   When this short name is used, the chef-client will attempt to determine the correct provider during the chef-client run.

``Chef::Provider::Package::Windows``, ``windows_package``
   The provider for the Microsoft Windows platform.

.. end_tag

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Install a package**

.. tag resource_windows_package_install

.. To install a package:

.. code-block:: ruby

   windows_package '7zip' do
     action :install
     source 'C:\7z920.msi'
   end

.. end_tag

**Specify a URL for the source attribute**

.. tag resource_package_windows_source_url

.. To install a package using a URL for the source:

.. code-block:: ruby

   windows_package '7zip' do
     source 'http://www.7-zip.org/a/7z938-x64.msi'
   end

.. end_tag

**Specify path and checksum**

.. tag resource_package_windows_source_url_checksum

.. To install a package using a URL for the source and specifying a checksum:

.. code-block:: ruby

   windows_package '7zip' do
     source 'http://www.7-zip.org/a/7z938-x64.msi'
     checksum '7c8e873991c82ad9cfc123415254ea6101e9a645e12977dcd518979e50fdedf3'
   end

.. end_tag

**Modify remote_file resource attributes**

.. tag resource_package_windows_source_remote_file_attributes

The **windows_package** resource may specify a package at a remote location using the ``remote_file_attributes`` property. This uses the **remote_file** resource to download the contents at the specified URL and passes in a Hash that modifes the properties of the :doc:`remote_file resource </resource_remote_file>`.

For example:

.. code-block:: ruby

   windows_package '7zip' do
     source 'http://www.7-zip.org/a/7z938-x64.msi'
     remote_file_attributes ({
       :path => 'C:\\7zip.msi',
       :checksum => '7c8e873991c82ad9cfc123415254ea6101e9a645e12977dcd518979e50fdedf3'
     })
   end

.. end_tag

**Download a nsis (Nullsoft) package resource**

.. tag resource_package_windows_download_nsis_package

.. To download a nsis (Nullsoft) package resource:

.. code-block:: ruby

   windows_package 'Mercurial 3.6.1 (64-bit)' do
     source 'http://mercurial.selenic.com/release/windows/Mercurial-3.6.1-x64.exe'
     checksum 'febd29578cb6736163d232708b834a2ddd119aa40abc536b2c313fc5e1b5831d'
   end

.. end_tag

**Download a custom package**

.. tag resource_package_windows_download_custom_package

.. To download a custom package:

.. code-block:: ruby

   windows_package 'Microsoft Visual C++ 2005 Redistributable' do
     source 'https://download.microsoft.com/download/6/B/B/6BB661D6-A8AE-4819-B79F-236472F6070C/vcredist_x86.exe'
     installer_type :custom
     options '/Q'
   end

.. end_tag
