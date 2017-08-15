=====================================================
machine_image
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_machine_image.rst>`__

.. tag resource_machine_image_summary

Use the **machine_image** resource to define a machine image. This image may then be used by the **machine** resource when building machines.

.. end_tag

.. warning:: .. tag notes_provisioning

             This functionality is available with Chef provisioning and is packaged in the Chef development kit. Chef provisioning is a framework that allows clusters to be managed by the chef-client and the Chef server in the same way nodes are managed: with recipes. Use Chef provisioning to describe, version, deploy, and manage clusters of any size and complexity using a common set of tools.

             .. end_tag

Syntax
=====================================================
.. tag resource_machine_image_syntax

The syntax for using the **machine_image** resource in a recipe is as follows:

.. code-block:: ruby

   machine_image 'name' do
     attribute 'value' # see properties section below
     ...
     action :action # see actions section below
   end

where

* ``machine_image`` tells the chef-client to use the ``Chef::Provider::MachineImage`` provider during the chef-client run
* ``name`` is the name of the resource block and also the name of the machine image
* ``attribute`` is zero (or more) of the properties that are available for this resource
* ``action`` identifies which steps the chef-client will take to bring the node into the desired state

.. end_tag

Actions
=====================================================
.. tag resource_machine_image_actions

This resource has the following actions:

``:archive``
   Use to archive a machine image.

``:create``
   Default. Use to create a machine image.

``:destroy``
   Use to destroy a machine image.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

.. end_tag

Properties
=====================================================
.. tag resource_machine_image_attributes

This resource has the following properties:

``attributes``
   Use to specify a hash of attributes to be applied to the machine image.

``chef_environment``
   The name of the environment.

``complete``
   Use to specify if all of the attributes specified in ``attributes`` represent a complete specification for the machine image. When true, any attributes not specified in ``attributes`` will be reset to their default values.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``image_options``
   **Ruby Type:** Hash

   Use to specify options that are used with this machine image.

``name``
   The name of the machine image.

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

``raw_json``
   The machine image as JSON data. For example:

   .. code-block:: javascript

      {

      }

``recipe``
   Use to add a recipe to the run-list for the machine image. Each ``recipe`` adds a single recipe to the run-list. The order in which ``recipe`` defines the run-list is the order in which Chef will execute the run-list on the machine image.

``remove_recipe``
   Use to remove a recipe from the run-list for the machine image.

``remove_role``
   Use to remove a role from the run-list for the machine image.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``role``
   Use to add a role to the run-list for the machine image.

``run_list``
   Use to specify the run-list to be applied to the machine image.

   .. tag node_run_list

   A run-list defines all of the information necessary for Chef to configure a node into the desired state. A run-list is:

   * An ordered list of roles and/or recipes that are run in the exact order defined in the run-list; if a recipe appears more than once in the run-list, the chef-client will not run it twice
   * Always specific to the node on which it runs; nodes may have a run-list that is identical to the run-list used by other nodes
   * Stored as part of the node object on the Chef server
   * Maintained using knife, and then uploaded from the workstation to the Chef server, or is maintained using the Chef management console

   .. end_tag

   .. tag node_run_list_format

   A run-list must be in one of the following formats: fully qualified, cookbook, or default. Both roles and recipes must be in quotes, for example:

   .. code-block:: ruby

      'role[NAME]'

   or

   .. code-block:: ruby

      'recipe[COOKBOOK::RECIPE]'

   Use a comma to separate roles and recipes when adding more than one item the run-list:

   .. code-block:: ruby

      'recipe[COOKBOOK::RECIPE],COOKBOOK::RECIPE,role[NAME]'

   .. end_tag

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

``tags``
   Use to specify the list of tags to be applied to the machine image. Any tag not specified in this list will be removed.

.. end_tag

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Build a machine from a machine image**

.. tag resource_machine_image_add_apache_to_image

.. To add Apache to a machine image, and then build a machine:

.. code-block:: ruby

   machine_image 'web_image' do
     recipe 'apache2'
   end

   machine 'web_machine' do
    from_image 'web_image'
   end

.. end_tag

