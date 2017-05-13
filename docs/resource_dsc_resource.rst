=====================================================
dsc_resource
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_dsc_resource.rst>`__

.. tag resources_common_powershell

Windows PowerShell is a task-based command-line shell and scripting language developed by Microsoft. Windows PowerShell uses a document-oriented approach for managing Microsoft Windows-based machines, similar to the approach that is used for managing UNIX- and Linux-based machines. Windows PowerShell is `a tool-agnostic platform <http://technet.microsoft.com/en-us/library/bb978526.aspx>`_ that supports using Chef for configuration management.

.. end_tag

New in Chef Client 12.2.  Changed in Chef Client 12.6.

.. tag resources_common_powershell_dsc

Desired State Configuration (DSC) is a feature of Windows PowerShell that provides `a set of language extensions, cmdlets, and resources <http://technet.microsoft.com/en-us/library/dn249912.aspx>`_ that can be used to declaratively configure software. DSC is similar to Chef, in that both tools are idempotent, take similar approaches to the concept of resources, describe the configuration of a system, and then take the steps required to do that configuration. The most important difference between Chef and DSC is that Chef uses Ruby and DSC is exposed as configuration data from within Windows PowerShell.

.. end_tag

.. tag resource_dsc_resource_summary

The **dsc_resource** resource allows any DSC resource to be used in a Chef recipe, as well as any custom resources that have been added to your Windows PowerShell environment. Microsoft `frequently adds new resources <https://github.com/powershell/DscResources>`_ to the DSC resource collection.

.. end_tag

.. warning:: .. tag resource_dsc_resource_requirements

             Using the **dsc_resource** has the following requirements:

             * Windows Management Framework (WMF) 5.0 February Preview (or higher), which includes Windows PowerShell 5.0.10018.0 (or higher).
             * The ``RefreshMode`` configuration setting in the Local Configuration Manager must be set to ``Disabled``.

               **NOTE:** Starting with the chef-client 12.6 release, this requirement applies only for versions of Windows PowerShell earlier than 5.0.10586.0. The latest version of Windows Management Framework (WMF) 5 has relaxed the limitation that prevented the chef-client from running in non-disabled refresh mode.

             * The **dsc_script** resource  may not be used in the same run-list with the **dsc_resource**. This is because the **dsc_script** resource requires that ``RefreshMode`` in the Local Configuration Manager be set to ``Push``, whereas the **dsc_resource** resource requires it to be set to ``Disabled``.

               **NOTE:** Starting with the chef-client 12.6 release, this requirement applies only for versions of Windows PowerShell earlier than 5.0.10586.0. The latest version of Windows Management Framework (WMF) 5 has relaxed the limitation that prevented the chef-client from running in non-disabled refresh mode, which allows the Local Configuration Manager to be set to ``Push``.

             * The **dsc_resource** resource can only use binary- or script-based resources. Composite DSC resources may not be used.

               This is because composite resources aren't "real" resources from the perspective of the the Local Configuration Manager (LCM). Composite resources are used by the "configuration" keyword from the ``PSDesiredStateConfiguration`` module, and then evaluated in that context. When using DSC to create the configuration document (the Managed Object Framework (MOF) file) from the configuration command, the composite resource is evaluated. Any individual resources from that composite resource are written into the Managed Object Framework (MOF) document. As far as the Local Configuration Manager (LCM) is concerned, there is no such thing as a composite resource. Unless that changes, the **dsc_resource** resource and/or ``Invoke-DscResource`` command cannot directly use them.

             .. end_tag

Syntax
=====================================================
.. tag resource_dsc_resource_syntax

A **dsc_resource** resource block allows DSC resourcs to be used in a Chef recipe. For example, the DSC ``Archive`` resource:

.. code-block:: powershell

   Archive ExampleArchive {
     Ensure = "Present"
     Path = "C:\Users\Public\Documents\example.zip"
     Destination = "C:\Users\Public\Documents\ExtractionPath"
   }

and then the same **dsc_resource** with Chef:

.. code-block:: ruby

   dsc_resource 'example' do
      resource :archive
      property :ensure, 'Present'
      property :path, "C:\Users\Public\Documents\example.zip"
      property :destination, "C:\Users\Public\Documents\ExtractionPath"
    end

The full syntax for all of the properties that are available to the **dsc_resource** resource is:

.. code-block:: ruby

   dsc_resource 'name' do
     module_name                String
     module_version             String
     notifies                   # see description
     property                   Symbol
     resource                   String
     subscribes                 # see description
   end

where

* ``dsc_resource`` is the resource
* ``name`` is the name of the resource block
* ``property`` is zero (or more) properties in the DSC resource, where each property is entered on a separate line, ``:dsc_property_name`` is the case-insensitive name of that property, and ``"property_value"`` is a Ruby value to be applied by the chef-client
* ``module_name``, ``module_version``, ``property``, and ``resource`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
=====================================================
This resource has the following actions:

``:nothing``
   Default.

   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:reboot_action``
   Use to request an immediate reboot or to queue a reboot using the ``:reboot_now`` (immediate reboot) or ``:request_reboot`` (queued reboot) actions built into the **reboot** resource.

   New in Chef Client 12.6.

Properties
=====================================================
.. tag resource_dsc_resource_attributes

This resource has the following properties:

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``module_name``
   **Ruby Type:** String

   The name of the module from which a DSC resource originates. If this property is not specified, it will be inferred.

``module_version``
   **Ruby Type:** String

   The version number of the module to use. Powershell 5.0.10018.0 (or higher) supports having multiple versions of a module installed. This should be specified along with the ``module_name``.

   New in Chef Client 12.19.

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

``property``
   **Ruby Type:** Symbol

   A property from a Desired State Configuration (DSC) resource. Use this property multiple times, one for each property in the Desired State Configuration (DSC) resource. The format for this property must follow ``property :dsc_property_name, "property_value"`` for each DSC property added to the resource block.

   The ``:dsc_property_name`` must be a symbol.

   .. tag resource_dsc_resource_ruby_types

   Use the following Ruby types to define ``property_value``:

   .. list-table::
      :widths: 250 250
      :header-rows: 1

      * - Ruby
        - Windows PowerShell
      * - ``Array``
        - ``Object[]``
      * - ``Chef::Util::Powershell:PSCredential``
        - ``PSCredential``
      * - ``FalseClass``
        - ``bool($false)``
      * - ``Fixnum``
        - ``Integer``
      * - ``Float``
        - ``Double``
      * - ``Hash``
        - ``Hashtable``
      * - ``TrueClass``
        - ``bool($true)``

   These are converted into the corresponding Windows PowerShell type during the chef-client run.

   .. end_tag

``resource``
   **Ruby Type:** String

   The name of the DSC resource. This value is case-insensitive and must be a symbol that matches the name of the DSC resource.

   .. tag resource_dsc_resource_features

   For built-in DSC resources, use the following values:

   .. list-table::
      :widths: 250 250
      :header-rows: 1

      * - Value
        - Description
      * - ``:archive``
        - Use to to `unpack archive (.zip) files <https://msdn.microsoft.com/en-us/powershell/dsc/archiveresource>`_.
      * - ``:environment``
        - Use to to `manage system environment variables <https://msdn.microsoft.com/en-us/powershell/dsc/environmentresource>`_.
      * - ``:file``
        - Use to to `manage files and directories <https://msdn.microsoft.com/en-us/powershell/dsc/fileresource>`_.
      * - ``:group``
        - Use to to `manage local groups <https://msdn.microsoft.com/en-us/powershell/dsc/groupresource>`_.
      * - ``:log``
        - Use to to `log configuration messages <https://msdn.microsoft.com/en-us/powershell/dsc/logresource>`_.
      * - ``:package``
        - Use to to `install and manage packages <https://msdn.microsoft.com/en-us/powershell/dsc/packageresource>`_.
      * - ``:registry``
        - Use to to `manage registry keys and registry key values <https://msdn.microsoft.com/en-us/powershell/dsc/registryresource>`_.
      * - ``:script``
        - Use to to `run Powershell script blocks <https://msdn.microsoft.com/en-us/powershell/dsc/scriptresource>`_.
      * - ``:service``
        - Use to to `manage services <https://msdn.microsoft.com/en-us/powershell/dsc/serviceresource>`_.
      * - ``:user``
        - Use to to `manage local user accounts <https://msdn.microsoft.com/en-us/powershell/dsc/userresource>`_.
      * - ``:windowsfeature``
        - Use to to `add or remove Windows features and roles <https://msdn.microsoft.com/en-us/powershell/dsc/windowsfeatureresource>`_.
      * - ``:windowsoptionalfeature``
        - Use to configure Microsoft Windows optional features.
      * - ``:windowsprocess``
        - Use to to `configure Windows processes <https://msdn.microsoft.com/en-us/powershell/dsc/windowsprocessresource>`_.

   Any DSC resource may be used in a Chef recipe. For example, the DSC Resource Kit contains resources for `configuring Active Directory components <http://www.powershellgallery.com/packages/xActiveDirectory/2.8.0.0>`_, such as ``xADDomain``, ``xADDomainController``, and ``xADUser``. Assuming that these resources are available to the chef-client, the corresponding values for the ``resource`` attribute would be: ``:xADDomain``, ``:xADDomainController``, and ``xADUser``.

   .. end_tag

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

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

.. end_tag

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Open a Zip file**

.. tag resource_dsc_resource_zip_file

.. To use a zip file:

.. code-block:: ruby

   dsc_resource 'example' do
      resource :archive
      property :ensure, 'Present'
      property :path, 'C:\Users\Public\Documents\example.zip'
      property :destination, 'C:\Users\Public\Documents\ExtractionPath'
    end

.. end_tag

**Manage users and groups**

.. tag resource_dsc_resource_manage_users

.. To manage users and groups

.. code-block:: ruby

   dsc_resource 'demogroupadd' do
     resource :group
     property :groupname, 'demo1'
     property :ensure, 'present'
   end

   dsc_resource 'useradd' do
     resource :user
     property :username, 'Foobar1'
     property :fullname, 'Foobar1'
     property :password, ps_credential('P@assword!')
     property :ensure, 'present'
   end

   dsc_resource 'AddFoobar1ToUsers' do
     resource :Group
     property :GroupName, 'demo1'
     property :MembersToInclude, ['Foobar1']
   end

.. end_tag

**Create and register a windows service**

.. tag resource_dsc_resource_windows_service

.. To create a windows service:

The following example creates a windows service, defines it's execution path, and prevents windows from starting the service
in case the executable is not at the defined location:

.. code-block:: ruby

  dsc_resource 'NAME' do
    resource :service
    property :name, 'NAME'
    property :startuptype, 'Disabled'
    property :path, 'D:\\Sites\\Site_name\file_to_run.exe'
    property :ensure, 'Present'
    property :state, 'Stopped'
  end

.. end_tag

New in Chef Client 12.0.

**Create a test message queue**

.. tag resource_dsc_resource_manage_msmq

.. To manage a message queue:

The following example creates a file on a node (based on one that is located in a cookbook), unpacks the ``MessageQueue.zip`` Windows PowerShell module, and then uses the **dsc_resource** to ensure that Message Queuing (MSMQ) sub-features are installed, a test queue is created, and that permissions are set on the test queue:

.. code-block:: ruby

   cookbook_file 'cMessageQueue.zip' do
     path "#{Chef::Config[:file_cache_path]}\\MessageQueue.zip"
     action :create_if_missing
   end

   windows_zipfile "#{ENV['PROGRAMW6432']}\\WindowsPowerShell\\Modules" do
     source "#{Chef::Config[:file_cache_path]}\\MessageQueue.zip"
     action :unzip
   end

   dsc_resource 'install-sub-features' do
     resource :windowsfeature
     property :ensure, 'Present'
     property :name, 'msmq'
     property :IncludeAllSubFeature, true
   end

   dsc_resource 'create-test-queue' do
     resource :cPrivateMsmqQueue
     property :ensure, 'Present'
     property :name, 'Test_Queue'
   end

   dsc_resource 'set-permissions' do
     resource :cPrivateMsmqQueuePermissions
     property :ensure, 'Present'
     property :name, 'Test_Queue_Permissions'
     property :QueueNames, 'Test_Queue'
     property :ReadUsers, node['msmq']['read_user']
   end

.. end_tag

**Example to show usage of module properties**

.. tag resource_dsc_resource_module_properties_usage

.. To show usage of module properties:

.. code-block:: ruby

   dsc_resource 'test-cluster' do
     resource :xCluster
     module_name 'xFailOverCluster'
     module_version '1.6.0.0'
     property :name, 'TestCluster'
     property :staticipaddress, '10.0.0.3'
     property :domainadministratorcredential, ps_credential('abcd')
   end

.. end_tag

