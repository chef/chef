=====================================================
group
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_group.rst>`__

.. tag resource_group_summary

Use the **group** resource to manage a local group.

.. end_tag

Syntax
=====================================================
A **group** resource block manages groups on a node:

.. code-block:: ruby

   group 'www-data' do
     action :modify
     members 'maintenance'
     append true
   end

The full syntax for all of the properties that are available to the **group** resource is:

.. code-block:: ruby

   group 'name' do
     append                     TrueClass, FalseClass
     excluded_members           Array
     gid                        String, Integer
     group_name                 String # defaults to 'name' if not specified
     members                    Array
     non_unique                 TrueClass, FalseClass
     notifies                   # see description
     provider                   Chef::Provider::Group
     subscribes                 # see description
     system                     TrueClass, FalseClass
     action                     Symbol # defaults to :create if not specified
   end

where

* ``group`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``append``, ``excluded_members``, ``gid``, ``group_name``, ``members``, ``non_unique``, ``provider``, and ``system`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

``:create``
   Default. Create a group. If a group already exists (but does not match), update that group to match.

``:manage``
   Manage an existing group. This action does nothing if the group does not exist.

``:modify``
   Modify an existing group. This action raises an exception if the group does not exist.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:remove``
   Remove a group.

Properties
=====================================================
This resource has the following properties:

``append``
   **Ruby Types:** TrueClass, FalseClass

   How members should be appended and/or removed from a group. When ``true``, ``members`` are appended and ``excluded_members`` are removed. When ``false``, group members are reset to the value of the ``members`` property. Default value: ``false``.

``excluded_members``
   **Ruby Type:** Array

   Remove users from a group. May only be used when ``append`` is set to ``true``.

``gid``
   **Ruby Types:** String, Integer

   The identifier for the group.

``group_name``
   **Ruby Type:** String

   The name of the group. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``members``
   **Ruby Type:** Array

   Which users should be set or appended to a group. When more than one group member is identified, the list of members should be an array: ``members ['user1', 'user2']``.

``non_unique``
   **Ruby Types:** TrueClass, FalseClass

   Allow ``gid`` duplication. May only be used with the ``Groupadd`` provider. Default value: ``false``.

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

``system``
   **Ruby Types:** TrueClass, FalseClass

   Show if a group belongs to a system group. Set to ``true`` if the group belongs to a system group.

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

``Chef::Provider::Group``, ``group``
   When this short name is used, the chef-client will determine the correct provider during the chef-client run.

``Chef::Provider::Group::Aix``, ``group``
   The provider for the AIX platform.

``Chef::Provider::Group::Dscl``, ``group``
   The provider for the macOS platform.

``Chef::Provider::Group::Gpasswd``, ``group``
   The provider for the gpasswd command.

``Chef::Provider::Group::Groupadd``, ``group``
   The provider for the groupadd command.

``Chef::Provider::Group::Groupmod``, ``group``
   The provider for the groupmod command.

``Chef::Provider::Group::Pw``, ``group``
   The provider for the FreeBSD platform.

``Chef::Provider::Group::Suse``, ``group``
   The provider for the openSUSE platform.

``Chef::Provider::Group::Usermod``, ``group``
   The provider for the Solaris platform.

``Chef::Provider::Group::Windows``, ``group``
   The provider for the Microsoft Windows platform.

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Append users to groups**

.. tag resource_group_append_user

.. To append a user to an existing group:

.. code-block:: ruby

   group 'www-data' do
     action :modify
     members 'maintenance'
     append true
   end

.. end_tag

**Add a user to group on the Windows platform**

.. tag resource_group_add_user_on_windows

.. To add a group on the Windows platform:

.. code-block:: ruby

   group 'Administrators' do
     members ['domain\foo']
     append true
     action :modify
   end

.. end_tag

