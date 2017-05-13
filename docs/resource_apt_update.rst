=====================================================
apt_update
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_apt_update.rst>`__

.. tag resource_apt_update_summary

Use the **apt_update** resource to manage Apt repository updates on Debian and Ubuntu platforms.

.. end_tag

*New in Chef Client 12.7.*

Syntax
=====================================================
.. tag resource_apt_update_syntax

A **apt_update** resource block defines the update frequency for Apt repositories:

.. code-block:: ruby

   apt_update 'name' do
     frequency                  Integer
     action                     Symbol # defaults to :periodic if not specified
   end

where

* ``apt_update`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``frequency`` is a property of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Nameless
=====================================================

This resource can be **nameless**. Add the resource itself to your recipe to get the default behavior:

.. code-block:: ruby

   apt_update

will behave the same as:

.. code-block:: ruby

   apt_update 'update'

Actions
=====================================================
.. tag resource_apt_update_actions

This resource has the following actions:

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:periodic``
   Update the Apt repository at the interval specified by the ``frequency`` property.

``:update``
   Update the Apt repository at the start of the chef-client run.

.. end_tag

Properties
=====================================================
.. tag resource_apt_update_attributes

This resource has the following properties:

``frequency``
   **Ruby Type:** Integer

   The frequency at which Apt repository updates are made. Use this property when the ``:periodic`` action is specified. Default value: ``86400``.

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
.. tag resources_common_examples_intro

The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

.. end_tag

**Update the Apt repository at a specified interval**

.. tag resource_apt_update_periodic

.. To update the Apt repository at a specified interval:

.. code-block:: ruby

   apt_update 'all platforms' do
     frequency 86400
     action :periodic
   end

.. end_tag

**Update the Apt repository at the start of a chef-client run**

.. tag resource_apt_update_at_start_of_client_run

.. To update the Apt repository at the start of a chef-client run:

.. code-block:: ruby

   apt_update 'update' do
     action :update
   end

.. end_tag
