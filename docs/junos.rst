=====================================================
Chef for Junos OS
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/junos.rst>`__

Juniper Networks is a leading provider of network routing, switching and security solutions for enterprises and service providers. Juniper Networks routers and switches help solve some of the most difficult problems in the data center. Junos OS is the operating system that runs on Juniper Networks routers and switches.

.. image:: ../../images/overview_junos.png

Chef for Junos OS allows hardware running Junos OS to be managed by the Chef server. The ``netdev`` cookbook is an open source cookbook (maintained by Chef) that contains a collection of resources that can be used to build recipes that extend the node management capabilities of the Chef server to include Juniper Networks network devices.

For more information about Chef for Junos OS, including information about installing and configuring the chef-client on a Junos OS device, see the Juniper Networks Chef for Junos OS documentation at http://www.juniper.net/techpubs/en_US/release-independent/junos-chef/information-products/pathway-pages/index.html.

The netdev Custom Resources
=====================================================
The ``netdev`` cookbook is used to install and configure network interfaces and Layer 2 switching.

The ``netdev`` cookbook contains the following custom resources: ``netdev_interface``, ``netdev_l2_interface``, ``netdev_lag``, and ``netdev_vlan``.

.. note:: These custom resources are part of the ``netdev`` cookbook (https://github.com/chef-cookbooks/netdev).

netdev_interface
-----------------------------------------------------
The ``netdev_interface`` custom resource is used to model the properties and to manage the configuration of a physical interface.

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++

This custom resource has the following actions:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Action
     - Description
   * - ``:create``
     - Default. Use to create a physical interface.
   * - ``:delete``
     - Use to delete a physical interface.

Properties
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This custom resource has the following properties:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Property
     - Description
   * - ``description``
     - The description of the interface.
   * - ``duplex``
     - The duplex mode for the interface. Possible values: ``auto``, ``half``, or ``full``. Default value: ``auto``.
   * - ``enable``
     - Activate the interface. Default value: ``true``.
   * - ``mtu``
     - The maximum transmission unit (MTU) for the network interface.
   * - ``name``
     - The name of the interface.
   * - ``speed``
     - The speed for the interface. Possible values: ``auto``, ``100m``, ``1g``, ``10g``, ``40g``, ``56g``, or ``100g``. Default value: ``auto``. Setting the speed attribute to the default value of ``auto`` causes the device to use the existing configuration for the speed statement and does not explicitly configure anything for the interface speed.

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. To use the ``netdev_interface`` lightweight resource:

.. code-block:: ruby

   netdev_interface "ge-0/0/0" do
     description "description"
     speed "1g"
     duplex "full"
     action :create
   end

netdev_l2_interface
-----------------------------------------------------
The ``netdev_l2_interface`` custom resource is used to model the properties and to manage the configuration of Layer 2 networking features on both physical and virtual interfaces.

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This custom resource has the following actions:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Action
     - Description
   * - ``:create``
     - Default. Use to create Layer 2 networking.
   * - ``:delete``
     - Use to delete Layer 2 networking.

Properties
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This custom resource has the following properties:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Property
     - Description
   * - ``description``
     - The description of the interface.
   * - ``name``
     - The name of the interface.
   * - ``tagged_vlans``
     - An array of VLANs that carry traffic on a trunk interface.
   * - ``untagged_vlan``
     - The native VLAN on an interface.
   * - ``vlan_tagging``
     - Specify that a port is in access or trunk mode. Default value: ``true`` (trunk mode).

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. To use the ``netdev_l2_interface`` lightweight resource:

.. code-block:: ruby

   netdev_l2_interface "ge-0/0/0" do
     description "description"
     tagged_vlans %w{ foobar }
     vlan_tagging true
     action :create
   end

netdev_lag
-----------------------------------------------------
The ``netdev_lag`` custom resource is used to to model the properties and to manage the configuration of a link aggregation group (LAG). This is referred to as an aggregated Ethernet bundle in Junos OS.

.. note:: The number of supported aggregated Ethernet interfaces on a switch must be manually configured before this resource can be used to create LAGs. Use the `aggregated-devices <http://www.juniper.net/techpubs/en_US/junos13.2/topics/reference/configuration-statement/device-count-chassis-qfx-series.html>`_ command to configure the number of supported interfaces:

   .. code-block:: bash

      $ set chassis aggregated-devices ethernet device-count <count-value>

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This custom resource has the following actions:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Action
     - Description
   * - ``:create``
     - Default. Use to create a link aggregation group (LAG).
   * - ``:delete``
     - Use to delete a link aggregation group (LAG).

Properties
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This custom resource has the following properties:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Property
     - Description
   * - ``lacp``
     - The Link Aggregation Control Protocol (LACP) mode. Possible values: ``active`` (active mode), ``disable`` (not used), or ``passive`` (passive mode). Default value: ``disable``.
   * - ``links``
     - Required. An array of interfaces to be configured as members of a link aggregation group (LAG).

       .. note:: If a ``netdev_lag`` resource is deleted, interfaces that are defined by this property are also deleted, unless they have been configured elsewhere.
   * - ``minimum_links``
     - The minimum number of physical links that are required to ensure the availability of the link aggregation group (LAG).
   * - ``name``
     - The name of the link aggregation group (LAG).

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. To use the ``netdev_lag`` lightweight resource:

.. code-block:: ruby

   netdev_lag "ae0" do
     links %w{ ge-0/0/1 ge-0/0/2 }
     minimum_links 1
     lacp "disable"
     action :create
   end

netdev_vlan
-----------------------------------------------------
The ``netdev_vlan`` custom resource is used to model the properties and to manage the configuration of VLANs.

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This custom resource has the following actions:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Action
     - Description
   * - ``:create``
     - Default. Use to create a VLAN.
   * - ``:delete``
     - Use to delete a VLAN.

Properties
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This custom resource has the following properties:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Property
     - Description
   * - ``description``
     - The description of the VLAN.
   * - ``name``
     - The name of the VLAN.
   * - ``vlan_id``
     - Required. The identifier for the VLAN.

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. To use the ``netdev_vlan`` lightweight resource:

.. code-block:: ruby

   netdev_vlan "name" do
     vlan_id 2
     description "description"
     action :create
   end
