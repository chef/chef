=====================================================
chef_acl
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_chef_acl.rst>`__

.. warning:: .. tag notes_provisioning

             This functionality is available with Chef provisioning and is packaged in the Chef development kit. Chef provisioning is a framework that allows clusters to be managed by the chef-client and the Chef server in the same way nodes are managed: with recipes. Use Chef provisioning to describe, version, deploy, and manage clusters of any size and complexity using a common set of tools.

             .. end_tag

.. tag chef_client_summary

A chef-client is an agent that runs locally on every node that is under management by Chef. When a chef-client is run, it will perform all of the steps that are required to bring the node into the expected state, including:

* Registering and authenticating the node with the Chef server
* Building the node object
* Synchronizing cookbooks
* Compiling the resource collection by loading each of the required cookbooks, including recipes, attributes, and all other dependencies
* Taking the appropriate and required actions to configure the node
* Looking for exceptions and notifications, handling each as required

.. end_tag

Use the **chef_acl** resource to interact with access control lists (ACLs) that exist on the Chef server.

Syntax
=====================================================
The syntax for using the **chef_acl** resource in a recipe is as follows:

.. code-block:: ruby

   chef_acl 'name' do
     attribute 'value' # see properties section below
     ...
     action :action # see actions section below
   end

where

* ``chef_acl`` tells the chef-client to use the ``Chef::Provider::ChefAcl`` provider during the chef-client run
* ``name`` is the name of the resource block; when the ``path`` property is not specified as part of a recipe, ``name`` is also the name of the chef-client
* ``attribute`` is zero (or more) of the properties that are available for this resource
* ``action`` identifies which steps the chef-client will take to bring the node into the desired state

Actions
=====================================================
This resource has the following actions:

``:create``
   Default.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

Properties
=====================================================
This resource has the following properties:

``chef_server``
   The URL for the Chef server.

``complete``
   Use to specify if this resource defines a chef-client completely. When ``true``, any property not specified by this resource will be reset to default property values.

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

``path``
   A path to a directory in the chef-repo against which the ACL is applied. For example: ``nodes``, ``nodes/*``, ``nodes/my_node``, ``*/*``, ``**``, ``roles/base``, ``data/secrets``, ``cookbooks/apache2``, ``/users/*``, and so on.

``raw_json``
   The chef-client as JSON data. For example:

   .. code-block:: javascript

      {
        "clientname": "client_name",
        "orgname": "org_name",
        "validator": false,
        "certificate": "-----BEGIN CERTIFICATE-----\n
                        ...
                        1234567890abcdefghijklmnopq\n
                        ...
                        -----END CERTIFICATE-----\n",
        "name": "node_name"
      }

``recursive``
   Use to apply changes to child objects. Use ``:on_change`` to apply changes to child objects only if the parent object changes. Set to ``true`` to apply changes even if the parent object does not change. Set to ``false`` to prevent any changes. Default value: ``:on_change``.

``remove_rights``
   Use to remove rights. For example:

   .. code-block:: ruby

      remove_rights :read, :users => 'jkeiser', :groups => [ 'admins', 'users' ]

   or:

   .. code-block:: ruby

      remove_rights [ :create, :read ], :users => [ 'jkeiser', 'adam' ]

   or:

   .. code-block:: ruby

      remove_rights :all, :users => [ 'jkeiser', 'adam' ]

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``rights``
   Use to add rights. Syntax: ``:right, :right => 'user', :groups => [ 'group', 'group']``. For example:

   .. code-block:: ruby

      rights :read, :users => 'jkeiser', :groups => [ 'admins', 'users' ]

   or:

   .. code-block:: ruby

      rights [ :create, :read ], :users => [ 'jkeiser', 'adam' ]

   or:

   .. code-block:: ruby

      rights :all, :users => 'jkeiser'

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
None.
