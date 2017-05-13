=====================================================
systemd_unit
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_systemd_unit.rst>`__

Use the **systemd_unit** resource to create, manage, and run `systemd units <https://www.freedesktop.org/software/systemd/man/systemd.html#Concepts>`_.

New in Chef Client 12.11. Changed in 12.19 to verify systemd unit-files before installation (using the external ``systemd-analyze verify`` command).

Syntax
=====================================================
.. tag resource_systemd_unit_syntax

A **systemd_unit** resource describes the configuration behavior for systemd units. For example:

.. code-block:: ruby

   systemd_unit 'sysstat-collect.timer' do
     content <<-EOU.gsub(/^\s+/, '')
     [Unit]
     Description=Run system activity accounting tool every 10 minutes

     [Timer]
     OnCalendar=*:00/10

     [Install]
     WantedBy=sysstat.service
     EOU

     action [:create, :enable]
   end

The full syntax for all of the properties that are available to the **systemd_unit** resource is:

.. code-block:: ruby

   systemd_unit 'name.service' do
     content                String or Hash
     user                   String
     triggers_reload        Boolean
   end

where

* ``name`` is the name of the unit. Must include the type/suffix (e.g. `name.socket` or `name.service`).
* ``user`` is the user account that systemd units run under. If not specified, systemd units will run under the system account.
* ``content`` describes the behavior of the unit

.. end_tag

Actions
=====================================================
.. tag resource_systemd_unit_actions

This resource has the following actions:

``:create``
   Create a unit file, if it does not already exist.

``:delete``
   Delete a unit file, if it exists.

``:enable``
   Ensure the unit will be started after the next system boot.

``:disable``
   Ensure the unit will not be started after the next system boot.

``:nothing``
   Default. Do nothing with the unit.

``:mask``
   Ensure the unit will not start, even to satisfy dependencies.

``:unmask``
   Stop the unit from being masked and cause it to start as specified.

``:start``
   Start a unit based in its systemd unit file.

``:stop``
   Stop a running unit.

``:restart``
   Restart a unit.

``:reload``
   Reload the configuration file for a unit.

``:try_restart``
   Try to restart a unit if the unit is running.

``:reload_or_restart``
   For units that are services, this action reloads the configuration of the service without restarting, if possible; otherwise, it will restart the service so the new configuration is applied.

``:reload_or_try_restart``
   For units that are services, this action reloads the configuration of the service without restarting, if possible; otherwise, it will try to restart the service so the new configuration is applied.

.. end_tag

Properties
=====================================================
.. tag resource_systemd_unit_attributes

This resource has the following properties:

``user``
   **Ruby Type:** String

   The user account that the systemd unit process is run under. The path to the unit for that user would be something like
   ``/etc/systemd/user/sshd.service``. If no user account is specified, the systemd unit will run under a ``system`` account, with the path to the unit being something like ``/etc/systemd/system/sshd.service``.

``content``
   **Ruby Type:** String, Hash

   A string or hash that contains a systemd `unit file <https://www.freedesktop.org/software/systemd/man/systemd.unit.html>`_ definition that describes the properties of systemd-managed entities, such as services, sockets, devices, and so on.

``triggers_reload``
   **Ruby Type:** TrueClass, FalseClass

   Specifies whether to trigger a daemon reload when creating or deleting a unit. Default is true.

``verify``
   **Ruby Type:** TrueClass, FalseClass

   Specifies if the unit will be verified before installation. Systemd can be overly strict when verifying units, so in certain cases it is preferable not to verify the unit. Defaults to true.

.. end_tag

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

``Chef::Provider::SystemdUnit``, ``systemd_unit``
   The provider for systemd_unit.

..
.. Examples
.. =====================================================
..
