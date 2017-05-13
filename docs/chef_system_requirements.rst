=====================================================
System Requirements
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/chef_system_requirements.rst>`__

Before installing Chef:

* Ensure that each machine that will be a node is running a :doc:`platform </platforms>`
* Ensure that the machine that will run the Chef server is sufficiently powerful
* Ensure that any network and firewall settings are configured correctly

Install and configure the Chef server, then install and configure a workstation, and then run the bootstrap command from the workstation to install the chef-client on each node.

chef-client
=====================================================
In addition:

* The recommended amount of RAM available to the chef-client during a chef-client run is 512MB
* The chef-client binaries are stored in the ``/opt/chef`` directory, which requires a minimum of 200MB of disk space
* The chef-client caches to ``/var/chef/cache`` during the chef-client run. This is the location in which downloaded cookbooks, packages required by those cookbooks, and other large files are stored. This directory requires enough space to save all of this data and should be generously sized. 5GB is a safe number, as a starting point, but tune the size of ``/var/chef/cache`` as necessary
* Ruby 2.2.2 (or higher). In general, using the version of Ruby that is installed by the omnibus installer is recommended. Changed in Chef Client 12.14 to recommend Ruby 2.3.1; Chef client 12.13 updated to Ruby 2.1.9.
* The hosted Chef server is compatible with chef-client version 0.10.0 and greater; older clients must be upgraded before they can connect to Hosted Chef

The Chef Server
=====================================================
The following sections describe the various requirements for the Chef server.

Hosted Chef Server
-----------------------------------------------------
The hosted Chef server has the following requirements:

* **Browser** --- Firefox, Google Chrome, Safari, or Internet Explorer (versions 9 or better)
* Every node that will be configured by the chef-client and every workstation that will upload data to the Chef server must be able to communicate with the hosted Chef server

Chef Server, On-premises or in cloud environment
-----------------------------------------------------

.. tag system_requirements_server_hardware

All machines in a Chef server deployment have the following hardware requirements. Disk space for standalone and backend servers should scale up with the number of nodes that the servers are managing. A good rule to follow is to allocate 2 MB per node. The disk values listed below should be a good default value that you will want to modify later if/when your node count grows. Fast, redundant storage (SSD/RAID-based solution either on-prem or in a cloud environment) is preferred.

For all deployments:

* 64-bit architecture

For a standalone deployment:

* 4 total cores (physical or virtual)
* 8 GB of RAM or more
* 5 GB of free disk space in ``/opt``
* 5 GB of free disk space in ``/var``

.. note:: The RAM requirement can be lowered down to a minimum of 4 GB of RAM if the number of Chef client runs (CCRs) per minute are low (i.e. less than 33 CCRs/min). See `Capacity Planning </server_components.html#capacity-planning>`_ for more information on how this metric affects scalability.

For a high availability deployment:

General requirements

* Three backend servers; as many frontend servers as required
* 1 x GigE NIC interface (if on premises)

.. tag system_requirements_ha

Frontend requirements

* 4 cores (physical or virtual)
* 4GB RAM
* 20 GB of free disk space (SSD if on premises, Premium Storage in Microsoft Azure, EBS-Optimized GP2 in AWS)

Backend requirements

* 2 cores (physical or virtual)
* 8GB RAM
* 50 GB/backend server (SSD if on premises, Premium Storage in Microsoft Azure, EBS-Optimized GP2 in AWS)

.. warning:: The Chef server MUST NOT use a network file system of any type---virtual or physical---for backend storage. The Chef server database operates quickly. The behavior of operations, such as the writing of log files, will be unpredictable when run over a network file system.

.. end_tag

.. end_tag
.. tag system_requirements_server_software

Before installing the Chef server, ensure that each machine has the following installed and configured properly:

* **Hostnames** --- Ensure that all systems have properly configured hostnames. The hostname for the Chef server must be a FQDN, including the domain suffix, and must be resolvable. See `Hostnames, FQDNs </install_server_pre.html#hostnames>`_ for more information
* **FQDNs** --- Ensure that all systems have a resolvable FQDN
* **NTP** --- Ensure that every server is connected to NTP; the Chef server is sensitive to clock drift
* **Mail Relay** --- The Chef server uses email to send notifications for various events; a local mail transfer agent should be installed and available to the Chef server
* **cron** --- Periodic maintenance tasks are performed using cron
* **git** --- git must be installed so that various internal services can confirm revisions
* **libfreetype and libpng** --- These libraries are required
* **Apache Qpid** --- This daemon must be disabled on CentOS and Red Hat systems
* **Required users** --- If the environment in which the Chef server will run has restrictions on the creation of local user and group accounts, ensure that the correct users and groups exist before reconfiguring
* **Firewalls and ports** --- If host-based firewalls (iptables, ufw, etc.) are being used, ensure that ports 80 and 443 are open. These ports are used by the **nginx** service
* **Hostname** --- The hostname for the Chef server must be a FQDN, including the domain suffix, and must be resolvable. See `Hostnames, FQDNs </install_server_pre.html#hostnames>`_ for more information

In addition:

* **Browser** --- Firefox, Google Chrome, Safari, or Internet Explorer (versions 9 or better)
* **chef-client communication with the Chef server** Every node that will be configured by the chef-client and every workstation that will upload data to the Chef server must be able to communicate with the Chef server

.. end_tag

Chef DK
=====================================================
The Chef development kit has the same requirements as the chef-client.
