=====================================================
chef_user
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_chef_user.rst>`__

.. warning:: .. tag notes_provisioning

             This functionality is available with Chef provisioning and is packaged in the Chef development kit. Chef provisioning is a framework that allows clusters to be managed by the chef-client and the Chef server in the same way nodes are managed: with recipes. Use Chef provisioning to describe, version, deploy, and manage clusters of any size and complexity using a common set of tools.

             .. end_tag

Use the **chef_user** resource to manage users.

Syntax
=====================================================
The syntax for using the **chef_user** resource in a recipe is as follows:

.. code-block:: ruby

   chef_user 'value' # see properties section below
     ...
     action :action # see actions section below
   end

where

* ``chef_user`` tells the chef-client to use the ``Chef::Provider::ChefUser`` provider during the chef-client run
* ``name`` is the name of the resource block; when the ``name`` property is not specified as part of a recipe, ``name`` is also the name of the user
* ``attribute`` is zero (or more) of the properties that are available for this resource
* ``action`` identifies which steps the chef-client will take to bring the node into the desired state

Actions
=====================================================
This resource has the following actions:

``:create``
   Default. Use to create a user.

``:delete``
   Use to delete a user.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

Properties
=====================================================
This resource has the following properties:

``admin``
   Create a client as an admin client. This is required for any user to access Open Source Chef as an administrator.

``chef_server``
   The URL for the Chef server.

``complete``
   Use to specify if this resource defines a user completely. When ``true``, any property not specified by this resource will be reset to default property values.

``email``
   The email address for the user.

``external_authentication_uid``
   ...

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``name``
   The name of the user.

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

``output_key_format``
   Use to specify the format of a public key. Possible values: ``pem``, ``der``, or ``openssh``. Default value: ``openssh``.

``output_key_path``
   Use to specify the path to the location in which a public key will be written.

``raw_json``
   The user as JSON data. For example:

   .. code-block:: javascript

      {
        "name": "Robert Forster"
      }

``recovery_authentication_enabled``
   ...

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``source_key``
   Use to copy a public or private key, but apply a different ``format`` and ``password``. Use in conjunction with ``source_key_pass_phrase``` and ``source_key_path``.

``source_key_pass_phrase``
   The pass phrase for the public key. Use in conjunction with ``source_key``` and ``source_key_path``.

``source_key_path``
   The path to the public key. Use in conjunction with ``source_key``` and ``source_key_pass_phrase``.

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
