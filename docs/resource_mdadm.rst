=====================================================
mdadm
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_mdadm.rst>`__

.. tag resource_mdadm_summary

Use the **mdadm** resource to manage RAID devices in a Linux environment using the mdadm utility. The **mdadm** provider will create and assemble an array, but it will not create the config file that is used to persist the array upon reboot. If the config file is required, it must be done by specifying a template with the correct array layout, and then by using the **mount** provider to create a file systems table (fstab) entry.

.. end_tag

Syntax
=====================================================
A **mdadm** resource block manages RAID devices in a Linux environment using the mdadm utility:

.. code-block:: ruby

   mdadm '/dev/md0' do
     devices [ '/dev/sda', '/dev/sdb' ]
     level 1
     action [ :create, :assemble ]
   end

The full syntax for all of the properties that are available to the **mdadm** resource is:

.. code-block:: ruby

   mdadm 'name' do
     bitmap                     String
     chunk                      Integer
     devices                    Array
     exists                     TrueClass, FalseClass
     layout                     String
     level                      Integer
     mdadm_defaults             TrueClass, FalseClass
     metadata                   String
     notifies                   # see description
     provider                   Chef::Provider::Mdadm
     raid_device                String # defaults to 'name' if not specified
     subscribes                 # see description
     action                     Symbol # defaults to :create if not specified
   end

where

* ``mdadm`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``bitmap``, ``chunk``, ``devices``, ``exists``, ``layout``, ``level``, ``mdadm_defaults``, ``metadata``, ``provider``,  and ``raid_device`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

``:assemble``
   Assemble a previously created array into an active array.

``:create``
   Default. Create an array with per-device superblocks. If an array already exists (but does not match), update that array to match.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:stop``
   Stop an active array.

Properties
=====================================================
This resource has the following properties:

``bitmap``
   **Ruby Type:** String

   The path to a file in which a write-intent bitmap is stored.

``chunk``
   **Ruby Type:** Integer

   The chunk size. This property should not be used for a RAID 1 mirrored pair (i.e. when the ``level`` property is set to ``1``). Default value: ``16``.

``devices``
   **Ruby Type:** Array

   A comma-separated list of devices to be part of a RAID array. Default value: ``[]``.

``exists``
   **Ruby Types:** TrueClass, FalseClass

   Indicates whether the RAID array exists. Default value: ``false``.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``layout``
   **Ruby Type:** String

   The RAID5 parity algorithm. Possible values: ``left-asymmetric`` (or ``la``), ``left-symmetric`` (or ``ls``), ``right-asymmetric`` (or ``ra``), or ``right-symmetric`` (or ``rs``).

   New in Chef Client 12.10

``level``
   **Ruby Type:** Integer

   The RAID level. Default value: ``1``.

``mdadm_defaults``
   **Ruby Types:** TrueClass, FalseClass

   When ``true`` this property sets the default values for ``chunk`` and ``metadata`` to ``nil`` allowing mdadm to use its own default values. Default value: ``false``.

   New in Chef Client 12.9.

``metadata``
   **Ruby Type:** String

   The superblock type for RAID metadata. Default value: ``0.90``.

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

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider.

``raid_device``
   **Ruby Type:** String

   The name of the RAID device. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

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

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Create and assemble a RAID 0 array**

.. tag resource_mdadm_raid0

The mdadm command can be used to create RAID arrays. For example, a RAID 0 array named ``/dev/md0`` with 10 devices would have a command similar to the following:

.. code-block:: bash

   $ mdadm --create /dev/md0 --level=0 --raid-devices=10 /dev/s01.../dev/s10

where ``/dev/s01 .. /dev/s10`` represents 10 devices (01, 02, 03, and so on). This same command, when expressed as a recipe using the **mdadm** resource, would be similar to:

.. code-block:: ruby

   mdadm '/dev/md0' do
     devices [ '/dev/s01', ... '/dev/s10' ]
     level 0
     action :create
   end

(again, where ``/dev/s01 .. /dev/s10`` represents devices /dev/s01, /dev/s02, /dev/s03, and so on).

.. end_tag

**Create and assemble a RAID 1 array**

.. tag resource_mdadm_raid1

.. To create and assemble a RAID 1 array from two disks with a 64k chunk size:

.. code-block:: ruby

   mdadm '/dev/md0' do
     devices [ '/dev/sda', '/dev/sdb' ]
     level 1
     action [ :create, :assemble ]
   end

.. end_tag

**Create and assemble a RAID 5 array**

.. tag resource_mdadm_raid5

The mdadm command can be used to create RAID arrays. For example, a RAID 5 array named ``/dev/sd0`` with 4, and a superblock type of ``0.90`` would be similar to:

.. code-block:: ruby

   mdadm '/dev/sd0' do
     devices [ '/dev/s1', '/dev/s2', '/dev/s3', '/dev/s4' ]
     level 5
     metadata '0.90'
     chunk 32
     action :create
   end

.. end_tag
