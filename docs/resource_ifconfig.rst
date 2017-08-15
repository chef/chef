=====================================================
ifconfig
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_ifconfig.rst>`__

.. tag resource_ifconfig_summary

Use the **ifconfig** resource to manage interfaces.

.. end_tag

Syntax
=====================================================
A **ifconfig** resource block manages interfaces, such as a static IP address:

.. code-block:: ruby

   ifconfig '33.33.33.80' do
     device 'eth1'
   end

The full syntax for all of the properties that are available to the **ifconfig** resource is:

.. code-block:: ruby

   ifconfig 'name' do
     bcast                      String
     bootproto                  String
     device                     String
     hwaddr                     String
     inet_addr                  String
     mask                       String
     metric                     String
     mtu                        String
     network                    String
     notifies                   # see description
     onboot                     String
     onparent                   String
     provider                   Chef::Provider::Ifconfig
     subscribes                 # see description
     target                     String # defaults to 'name' if not specified
     action                     Symbol # defaults to :create if not specified
   end

where

* ``ifconfig`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``bcast``, ``bootproto``, ``device``, ``hwaddr``, ``inet_addr``, ``mask``, ``metric``, ``mtu``, ``network``, ``onboot``, ``onparent``, ``provider``,  and ``target`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

``:add``
   Default. Run ifconfig to configure a network interface and (on some platforms) write a configuration file for that network interface.

``:delete``
   Run ifconfig to disable a network interface and (on some platforms) delete that network interface's configuration file.

``:disable``
   Run ifconfig to disable a network interface.

``:enable``
   Run ifconfig to enable a network interface.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

Properties
=====================================================
This resource has the following properties:

``bcast``
   **Ruby Type:** String

   The broadcast address for a network interface. On some platforms this property is not set using ifconfig, but instead is added to the startup configuration file for the network interface.

``bootproto``
   **Ruby Type:** String

   The boot protocol used by a network interface.

``device``
   **Ruby Type:** String

   The network interface to be configured.

``hwaddr``
   **Ruby Type:** String

   The hardware address for the network interface.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``inet_addr``
   **Ruby Type:** String

   The Internet host address for the network interface.

``mask``
   **Ruby Type:** String

   The decimal representation of the network mask. For example: ``255.255.255.0``.

``metric``
   **Ruby Type:** String

   The routing metric for the interface.

``mtu``
   **Ruby Type:** String

   The maximum transmission unit (MTU) for the network interface.

``network``
   **Ruby Type:** String

   The address for the network interface.

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

``onboot``
   **Ruby Type:** String

   Bring up the network interface on boot.

``onparent``
   **Ruby Type:** String

   Bring up the network interface when its parent interface is brought up.

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

``target``
   **Ruby Type:** String

   The IP address that is to be assigned to the network interface. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Configure a network interface**

.. tag resource_ifconfig_boot_protocol

.. To specify a boot protocol:

.. code-block:: ruby

   ifconfig "33.33.33.80" do
     bootproto "dhcp"
     device "eth1"
   end

will create the following interface:

.. code-block:: none

   vagrant@default-ubuntu-1204:~$ cat /etc/network/interfaces.d/ifcfg-eth1
   iface eth1 inet dhcp

.. end_tag

**Specify a boot protocol**

.. tag resource_ifconfig_configure_network_interface

.. To configure a network interface:

.. code-block:: ruby

   ifconfig '192.186.0.1' do
     device 'eth0'
   end

.. end_tag

**Specify a static IP address**

.. tag resource_ifconfig_static_ip_address

.. To specify a static IP address:

.. code-block:: ruby

   ifconfig "33.33.33.80" do
     device "eth1"
   end

will create the following interface:

.. code-block:: none

   iface eth1 inet static
     address 33.33.33.80

.. end_tag

**Update a static IP address with a boot protocol**

.. tag resource_ifconfig_update_static_ip_with_boot_protocol

.. To update a static IP address with a boot protocol*:

.. code-block:: ruby

   ifconfig "33.33.33.80" do
     bootproto "dhcp"
     device "eth1"
   end

will update the interface from ``static`` to ``dhcp``:

.. code-block:: none

   iface eth1 inet dhcp
     address 33.33.33.80

.. end_tag

