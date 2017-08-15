=====================================================
ohai
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_ohai.rst>`__

.. tag resource_ohai_summary

Use the **ohai** resource to reload the Ohai configuration on a node. This allows recipes that change system attributes (like a recipe that adds a user) to refer to those attributes later on during the chef-client run.

.. end_tag

Syntax
=====================================================
.. tag resource_ohai_syntax

A **ohai** resource block reloads the Ohai configuration on a node:

.. code-block:: ruby

   ohai 'reload' do
     action :reload
   end

The full syntax for all of the properties that are available to the **ohai** resource is:

.. code-block:: ruby

   ohai 'name' do
     name                       String
     notifies                   # see description
     plugin                     String
     provider                   Chef::Provider::Ohai
     subscribes                 # see description
     action                     Symbol # defaults to :reload if not specified
   end

where

* ``ohai`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``name``, ``plugin``,  and ``provider`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
=====================================================
.. tag resource_ohai_actions

This resource has the following actions:

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:reload``
   Default. Reload the Ohai configuration on a node.

.. end_tag

Properties
=====================================================
.. tag resource_ohai_attributes

This resource has the following properties:

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``name``
   **Ruby Type:** String

   Always the same value as the ``name`` of the resource block. See "Syntax" section above for more information.

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

``plugin``
   **Ruby Type:** String

   Optional. The name of an Ohai plugin to be reloaded. If this property is not specified, the chef-client will reload all plugins.

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

**Reload Ohai**

.. tag resource_ohai_reload

.. To reload Ohai:

.. code-block:: ruby

   ohai 'reload' do
     action :reload
   end

.. end_tag

**Reload Ohai after a new user is created**

.. tag resource_ohai_reload_after_create_user

.. To reload Ohai configuration after a new user is created:

.. code-block:: ruby

   ohai 'reload_passwd' do
     action :nothing
     plugin 'etc'
   end

   user 'daemonuser' do
     home '/dev/null'
     shell '/sbin/nologin'
     system true
     notifies :reload, 'ohai[reload_passwd]', :immediately
   end

   ruby_block 'just an example' do
     block do
       # These variables will now have the new values
       puts node['etc']['passwd']['daemonuser']['uid']
       puts node['etc']['passwd']['daemonuser']['gid']
     end
   end

.. end_tag

