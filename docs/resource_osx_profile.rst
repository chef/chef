=====================================================
osx_profile
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_osx_profile.rst>`__

.. tag resource_osx_profile_summary

Use the **osx_profile** resource to manage configuration profiles (``.mobileconfig`` files) on the macOS platform. The **osx_profile** resource installs profiles by using the ``uuidgen`` library to generate a unique ``ProfileUUID``, and then using the ``profiles`` command to install the profile on the system.

.. end_tag

*New in Chef Client 12.7.*

Syntax
=====================================================
.. tag resource_osx_profile_syntax

A **osx_profile** resource block manages configuration profiles on the macOS platform:

.. code-block:: ruby

   osx_profile 'Install screensaver profile' do
     profile 'com.company.screensaver.mobileconfig'
   end

The full syntax for all of the properties that are available to the **osx_profile** resource is:

.. code-block:: ruby

   osx_profile 'name' do
     path                       # set automatically
     profile                    String, Hash
     profile_name               String # defaults to 'name' if not specified
     identifier                 String
     action                     Symbol # defaults to :install if not specified
   end

where

* ``osx_profile`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``profile``, ``profile_name``, and ``identifier`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
=====================================================
.. tag resource_osx_profile_actions

This resource has the following actions:

``:install``
   Default. Install the specified configuration profile.

``:nothing``
   Default. .. tag resources_common_actions_nothing

            Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

            .. end_tag

``:remove``
   Remove the specified configuration profile.

.. end_tag

Properties
=====================================================
.. tag resource_osx_profile_attributes

This resource has the following properties:

``identifier``
   **Ruby Type:** String

   Use to specify the identifier for the profile, such as ``com.company.screensaver``.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

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

``profile``
   **Ruby Types:** String, Hash

   Use to specify a profile. This may be the name of a profile contained in a cookbook or a Hash that contains the contents of the profile.

``profile_name``
   **Ruby Type:** String

   Use to specify the name of the profile, if different from the name of the resource block.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider.

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

**One liner to install profile from cookbook file**

.. tag resource_osx_profile_install_file_oneline

The ``profiles`` command will be used to install the specified configuration profile.

.. code-block:: ruby

   osx_profile 'com.company.screensaver.mobileconfig'

.. end_tag

**Install profile from cookbook file**

.. tag resource_osx_profile_install_file

The ``profiles`` command will be used to install the specified configuration profile. It can be in sub-directory within a cookbook.

.. code-block:: ruby

   osx_profile 'Install screensaver profile' do
     profile 'screensaver/com.company.screensaver.mobileconfig'
   end

.. end_tag

**Install profile from a hash**

.. tag resource_osx_profile_install_hash

The ``profiles`` command will be used to install the configuration profile, which is provided as a hash.

.. code-block:: ruby

   profile_hash = {
     'PayloadIdentifier' => 'com.company.screensaver',
     'PayloadRemovalDisallowed' => false,
     'PayloadScope' => 'System',
     'PayloadType' => 'Configuration',
     'PayloadUUID' => '1781fbec-3325-565f-9022-8aa28135c3cc',
     'PayloadOrganization' => 'Chef',
     'PayloadVersion' => 1,
     'PayloadDisplayName' => 'Screensaver Settings',
     'PayloadContent'=> [
       {
         'PayloadType' => 'com.apple.ManagedClient.preferences',
         'PayloadVersion' => 1,
         'PayloadIdentifier' => 'com.company.screensaver',
         'PayloadUUID' => '73fc30e0-1e57-0131-c32d-000c2944c108',
         'PayloadEnabled' => true,
         'PayloadDisplayName' => 'com.apple.screensaver',
         'PayloadContent' => {
           'com.apple.screensaver' => {
             'Forced' => [
               {
                 'mcx_preference_settings' => {
                   'idleTime' => 0,
                 }
               }
             ]
           }
         }
       }
     ]
   }

   osx_profile 'Install screensaver profile' do
     profile profile_hash
   end

.. end_tag

**Remove profile using identifier in resource name**

.. tag resource_osx_profile_remove_by_name

The ``profiles`` command will be used to remove the configuration profile specified by the provided ``identifier`` property.

.. code-block:: ruby

   osx_profile 'com.company.screensaver' do
     action :remove
   end

.. end_tag

**Remove profile by identifier and user friendly resource name**

.. tag resource_osx_profile_remove_by_identifier

The ``profiles`` command will be used to remove the configuration profile specified by the provided ``identifier`` property.

.. code-block:: ruby

   osx_profile 'Remove screensaver profile' do
     identifier 'com.company.screensaver'
     action :remove
   end

.. end_tag
