=====================================================
reboot
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_reboot.rst>`__

.. tag resource_service_reboot

Use the **reboot** resource to reboot a node, a necessary step with some installations on certain platforms. This resource is supported for use on the Microsoft Windows, macOS, and Linux platforms.  New in Chef Client 12.0.

.. end_tag

New in Chef Client 12.0

Syntax
=====================================================
.. tag resource_service_reboot_syntax

A **reboot** resource block reboots a node:

.. code-block:: ruby

   reboot 'app_requires_reboot' do
     action :request_reboot
     reason 'Need to reboot when the run completes successfully.'
     delay_mins 5
   end

The full syntax for all of the properties that are available to the **reboot** resource is:

.. code-block:: ruby

   reboot 'name' do
     delay_mins                 Fixnum
     notifies                   # see description
     reason                     String
     subscribes                 # see description
     action                     Symbol
   end

where

* ``reboot`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``delay_mins`` and ``reason`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
=====================================================
.. tag resource_service_reboot_actions

This resource has the following actions:

``:cancel``
   Cancel a reboot request.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:reboot_now``
   Reboot a node so that the chef-client may continue the installation process.

``:request_reboot``
   Reboot a node at the end of a chef-client run.

.. end_tag

Properties
=====================================================
This resource has the following properties:

``delay_mins``
   **Ruby Type:** Fixnum

   The amount of time (in minutes) to delay a reboot request.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag resources_common_notification_timers_reboot

   A timer specifies the point during the chef-client run at which a notification is run. The following timer is available:

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

``reason``
   **Ruby Type:** String

   A string that describes the reboot action.

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

   .. tag resources_common_notification_timers_reboot

   A timer specifies the point during the chef-client run at which a notification is run. The following timer is available:

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Reboot a node immediately**

.. tag resource_service_reboot_immediately

.. To reboot immediately:

.. code-block:: ruby

   reboot 'now' do
     action :nothing
     reason 'Cannot continue Chef run without a reboot.'
     delay_mins 2
   end

   execute 'foo' do
     command '...'
     notifies :reboot_now, 'reboot[now]', :immediately
   end

.. end_tag

**Reboot a node at the end of a chef-client run**

.. tag resource_service_reboot_request

.. To reboot a node at the end of the chef-client run:

.. code-block:: ruby

   reboot 'app_requires_reboot' do
     action :request_reboot
     reason 'Need to reboot when the run completes successfully.'
     delay_mins 5
   end

.. end_tag

**Cancel a reboot**

.. tag resource_service_reboot_cancel

.. To cancel a reboot request:

.. code-block:: ruby

   reboot 'cancel_reboot_request' do
     action :cancel
     reason 'Cancel a previous end-of-run reboot request.'
   end

.. end_tag

**Rename computer, join domain, reboot**

.. tag resource_powershell_rename_join_reboot

The following example shows how to rename a computer, join a domain, and then reboot the computer:

.. code-block:: ruby

   reboot 'Restart Computer' do
     action :nothing
   end

   powershell_script 'Rename and Join Domain' do
     code <<-EOH
       ...your rename and domain join logic here...
     EOH
     not_if <<-EOH
       $ComputerSystem = gwmi win32_computersystem
       ($ComputerSystem.Name -like '#{node['some_attribute_that_has_the_new_name']}') -and
         $ComputerSystem.partofdomain)
     EOH
     notifies :reboot_now, 'reboot[Restart Computer]', :immediately
   end

where:

* The **powershell_script** resource block renames a computer, and then joins a domain
* The **reboot** resource restarts the computer
* The ``not_if`` guard prevents the Windows PowerShell script from running when the settings in the ``not_if`` guard match the desired state
* The ``notifies`` statement tells the **reboot** resource block to run if the **powershell_script** block was executed during the chef-client run

.. end_tag
