=====================================================
chef_organization
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_chef_organization.rst>`__

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

Use the **chef_organization** resource to interact with organization objects that exist on the Chef server.

Syntax
=====================================================
The syntax for using the **chef_organization** resource in a recipe is as follows:

.. code-block:: ruby

   chef_organization 'name' do
     attribute 'value' # see attributes section below
     ...
     action :action # see actions section below
   end

where

* ``chef_organization`` tells the chef-client to use the ``Chef::Provider::ChefOrganization`` provider during the chef-client run
* ``name`` is the name of the resource block
* ``attribute`` is zero (or more) of the attributes that are available for this resource
* ``action`` identifies which steps the chef-client will take to bring the node into the desired state

Actions
=====================================================
This resource has the following actions:

``:create``
   Default.

``:delete``

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
   Use to specify if this resource defines an organization completely. When ``true``, any property not specified by this resource will be reset to default property values.

``full_name``
   The full name must begin with a non-white space character and must be between 1 and 1023 characters. For example: ``Chef Software, Inc.``.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``invites``
   Use to specify a list of users to be invited to the organization. An invitation is sent to any user in this list who is not already a member of the organization.

``members``
   Use to specify a list of users who MUST be members of the organization. These users will be added directly to the organization. The user who initiates this operation MUST also have permission to add users to the specified organization.

``members_specified``
   Use to discover if a user is a member of an organization. Will return ``true`` if the user is a member.

``name``
   The name must begin with a lower-case letter or digit, may only contain lower-case letters, digits, hyphens, and underscores, and must be between 1 and 255 characters. For example: ``chef``.

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
   The organization as JSON data. For example:

   .. code-block:: none

      {
        "name": "chef",
        "full_name": "Chef Software, Inc",
        "guid": "f980d1asdfda0331235s00ff36862
        ...
      }

``remove_members``
   Use to remove the specified users from an organization. Invitations that have not been accepted will be cancelled.

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
None.
