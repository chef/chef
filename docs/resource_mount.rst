=====================================================
mount
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_mount.rst>`__

.. tag resource_mount_summary

Use the **mount** resource to manage a mounted file system.

.. end_tag

Syntax
=====================================================
A **mount** resource block manages a mounted file system:

.. code-block:: ruby

   mount node['mysql']['ec2_path'] do
     device ebs_vol_dev
     fstype 'xfs'
     action :mount
   end

The full syntax for all of the properties that are available to the **mount** resource is:

.. code-block:: ruby

   mount 'name' do
     device                     String
     device_type                Symbol
     domain                     String
     dump                       Integer, FalseClass
     enabled                    TrueClass, FalseClass
     fsck_device                String
     fstype                     String
     mount_point                String # defaults to 'name' if not specified
     mounted                    TrueClass, FalseClass
     notifies                   # see description
     options                    Array, String
     pass                       Integer, FalseClass
     password                   String
     provider                   Chef::Provider::Mount
     subscribes                 # see description
     supports                   Hash # defaults to { :remount => false } (preferred)
                                Array # defaults to { :remount => true } (non-preferred)
     username                   String
     action                     Symbol # defaults to :mount if not specified
   end

where

* ``mount`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``device``, ``device_type``, ``domain``, ``dump``, ``enabled``, ``fsck_device``, ``fstype``, ``mount_point``, ``mounted``, ``options``, ``pass``, ``password``, ``provider``, ``supports``, and ``username`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

``:disable``
   Remove an entry from the file systems table (``fstab``).

``:enable``
   Add an entry to the file systems table (``fstab``).

``:mount``
   Default. Mount a device.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:remount``
   Remount a device.

``:umount``
   Unmount a device.

``:unmount``
   Alias for ``:umount`` action.

   New in Chef Client 12.17.

.. note:: Order matters when passing multiple actions. For example: ``action [:mount, :enable]`` ensures that the file system is mounted before it is enabled.

Properties
=====================================================
This resource has the following properties:

``device``
   **Ruby Type:** String

   Required for ``:umount`` and ``:remount`` actions (for the purpose of checking the mount command output for presence). The special block device or remote node, a label, or a uuid to be mounted.

``device_type``
   **Ruby Type:** Symbol

   The type of device: ``:device``, ``:label``, or ``:uuid``. Default value: ``:device``.

``domain``
   **Ruby Type:** String

   Microsoft Windows only. Use to specify the domain in which the ``username`` and ``password`` are located.

``dump``
   **Ruby Types:** Integer, FalseClass

   The dump frequency (in days) used while creating a file systems table (fstab) entry. Default value: ``0``.

``enabled``
   **Ruby Types:** TrueClass, FalseClass

   Use to specify if a mounted file system is enabled. Default value: ``false``.

``fsck_device``
   **Ruby Type:** String

   The fsck device on the Solaris platform. Default value: ``-``.

   New in Chef Client 12.0. 

``fstype``
   **Ruby Type:** String

   Required. The file system type (fstype) of the device.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``mount_point``
   **Ruby Type:** String

   The directory (or path) in which the device is to be mounted. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``mounted``
   **Ruby Types:** TrueClass, FalseClass

   Use to specify if a file system is already mounted. Default value: ``false``.

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
   **Ruby Types:** Array, String

   An array or string that contains mount options. If this value is a string, it is converted to an array. Default value: ``defaults``.

``pass``
   **Ruby Types:** Integer, FalseClass

   The pass number used by the file system check (``fsck``) command while creating a file systems table (``fstab``) entry. Default value: ``2``.

``password``
   **Ruby Type:** String

   Microsoft Windows only. Use to specify the password for ``username``.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider. See "Providers" section below for more information.

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

``supports``
   **Ruby Type:** Hash

   Specify a Hash of supported mount features. Default value: ``remount: false``.

``username``
   **Ruby Type:** String

   Microsoft Windows only. Use to specify the user name.

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

``Chef::Provider::Mount``, ``mount``
   The default provider for all platforms, except for Microsoft Windows.

``Chef::Provider::Mount::Windows``, ``mount``
   The default provider for the Microsoft Windows platform.

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Mount a labeled file system**

.. tag resource_mount_labeled_file_system

.. To mount a labeled file system:

.. code-block:: ruby

   mount '/mnt/volume1' do
     device 'volume1'
     device_type :label
     fstype 'xfs'
     options 'rw'
   end

.. end_tag

**Mount a local block drive**

.. tag resource_mount_local_block_device

.. To mount a local block device:

.. code-block:: ruby

   mount '/mnt/local' do
     device '/dev/sdb1'
     fstype 'ext3'
   end

.. end_tag

**Mount a non-block file system**

.. tag resource_mount_nonblock_file_system

.. To mount a non-block file system

.. code-block:: ruby

   mount '/mount/tmp' do
     pass     0
     fstype   'tmpfs'
     device   '/dev/null'
     options  'nr_inodes=999k,mode=755,size=500m'
     action   [:mount, :enable]
   end

.. end_tag

**Mount and add to the file systems table**

.. tag resource_mount_remote_file_system_add_to_fstab

.. To mount a remote file system and add it to the file systems table:

.. code-block:: ruby

   mount '/export/www' do
     device 'nas1prod:/export/web_sites'
     fstype 'nfs'
     options 'rw'
     action [:mount, :enable]
   end

.. end_tag

**Mount a remote file system**

.. tag resource_mount_remote_file_system

.. To mount a remote file system:

.. code-block:: ruby

   mount '/export/www' do
     device 'nas1prod:/export/web_sites'
     fstype 'nfs'
     options 'rw'
   end

.. end_tag

**Mount a remote folder in Microsoft Windows**

.. tag resource_mount_remote_windows_folder

.. To mount a remote Microsoft Windows folder on local drive letter T:

.. code-block:: ruby

   mount 'T:' do
     action :mount
     device '\\\\hostname.example.com\\folder'
   end

.. end_tag

**Unmount a remote folder in Microsoft Windows**

.. tag resource_mount_unmount_remote_windows_drive

.. To un-mount a remote Microsoft Windows D: drive attached as local drive letter T:

.. code-block:: ruby

   mount 'T:' do
     action :umount
     device '\\\\hostname.example.com\\D$'
   end

.. end_tag

**Stop a service, do stuff, and then restart it**

.. tag resource_service_stop_do_stuff_start

The following example shows how to use the **execute**, **service**, and **mount** resources together to ensure that a node running on Amazon EC2 is running MySQL. This example does the following:

* Checks to see if the Amazon EC2 node has MySQL
* If the node has MySQL, stops MySQL
* Installs MySQL
* Mounts the node
* Restarts MySQL

.. code-block:: ruby

   # the following code sample comes from the ``server_ec2``
   # recipe in the following cookbook:
   # https://github.com/chef-cookbooks/mysql

   if (node.attribute?('ec2') && ! FileTest.directory?(node['mysql']['ec2_path']))

     service 'mysql' do
       action :stop
     end

     execute 'install-mysql' do
       command "mv #{node['mysql']['data_dir']} #{node['mysql']['ec2_path']}"
       not_if do FileTest.directory?(node['mysql']['ec2_path']) end
     end

     [node['mysql']['ec2_path'], node['mysql']['data_dir']].each do |dir|
       directory dir do
         owner 'mysql'
         group 'mysql'
       end
     end

     mount node['mysql']['data_dir'] do
       device node['mysql']['ec2_path']
       fstype 'none'
       options 'bind,rw'
       action [:mount, :enable]
     end

     service 'mysql' do
       action :start
     end

   end

where

* the two **service** resources are used to stop, and then restart the MySQL service
* the **execute** resource is used to install MySQL
* the **mount** resource is used to mount the node and enable MySQL

.. end_tag
