=====================================================
private_key
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_private_key.rst>`__

.. warning:: .. tag notes_provisioning

             This functionality is available with Chef provisioning and is packaged in the Chef development kit. Chef provisioning is a framework that allows clusters to be managed by the chef-client and the Chef server in the same way nodes are managed: with recipes. Use Chef provisioning to describe, version, deploy, and manage clusters of any size and complexity using a common set of tools.

             .. end_tag

Use the **private_key** resource to create, delete, and regenerate private keys, including RSA, DSA, and .pem file keys.

Syntax
=====================================================
The syntax for using the **private_key** resource in a recipe is as follows:

.. code-block:: ruby

   private_key 'name' do
     attribute 'value' # see properties section below
     ...
     action :action # see actions section below
   end

where

* ``private_key`` tells the chef-client to use the ``Chef::Provider::PrivateKey`` provider during the chef-client run
* ``name`` is the name of the resource block; when the ``path`` property is not specified as part of a recipe, ``name`` is also the name of the private key
* ``attribute`` is zero (or more) of the properties that are available for this resource
* ``action`` identifies which steps the chef-client will take to bring the node into the desired state

Actions
=====================================================
This resource has the following actions:

``:create``
   Default. Use to create an RSA private key.

``:delete``
   Use to delete an RSA private key.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:regenerate``
   Use to regenerate an RSA private key.

Properties
=====================================================
This resource has the following properties:

``cipher``
   Use to specify the cipher for a .pem file. Default value: ``DES-EDE3-CBC``.

``exponent``
   Use to specify the exponent for an RSA private key. This is always an odd integer value, often a prime Fermat number, and typically ``5``, ``17``, ``257``, or ``65537``.

``format``
   Use to specify the format of a private key. Possible values: ``pem`` and ``der``. Default value: ``pem``.

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

``pass_phrase``
   Use to specify the pass phrase for a .pem file.

``path``
   Use to specify the path to a private key. Set to ``none`` to create a private key in-memory and not on-disk. Default value: the ``name`` of the resource block. See "Syntax" section above for more information.

``public_key_format``
   Use to specify the format of a public key. Possible values: ``der``, ``openssh``, and ``pem``. Default value: ``openssh``.

``public_key_path``
   The path to a public key.

``regenerate_if_different``
   Use to regenerate a private key if it does not have the desired size, type, and so on. Default value: ``false``.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``size``
   Use to specify the size of an RSA or DSA private key. Default value: ``2048``.

``source_key``
   Use to copy a private key, but apply a different ``format`` and ``password``. Use in conjunction with ``source_key_pass_phrase``` and ``source_key_path``.

``source_key_pass_phrase``
   The pass phrase for the private key. Use in conjunction with ``source_key``` and ``source_key_path``.

``source_key_path``
   The path to the private key. Use in conjunction with ``source_key``` and ``source_key_pass_phrase``.

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

``type``
   Use to specify the type of private key. Possible values: ``dsa`` and ``rsa``. Default value: ``rsa``.

Examples
=====================================================
None.
