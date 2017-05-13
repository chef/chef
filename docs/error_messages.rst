=====================================================
Error Messages
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/error_messages.rst>`__

The following sections describe how to troubleshoot some common errors and problems.

.. _error_messages_external_postgresql:

External PostgreSQL
=====================================================
The following error messages may be present when configuring the Chef server to use a remote PostgreSQL server.

CSPG001 (changed setting)
-----------------------------------------------------
**Reason**

The value of ``postgresql['external']`` has been changed.

**Possible Causes**

* This setting must be set before running ``chef-server-ctl reconfigure``, and may not be changed after

.. warning:: Upgrading is not supported at this time.

**Resolution**

* Back up the data using ``knife ec backup``, create a new backend instance, and then restore the data
* Re-point front end machines at the new backend instance **or** assign the new backend instance the name/VIP of the old backend instance (including certificates, keys, and so on)

CSPG010 (cannot connect)
-----------------------------------------------------
**Reason**

Cannot connect to PostgreSQL on the remote server.

**Possible Causes**

* PostgreSQL is not running on the remote server
* The port used by PostgreSQL is blocked by a firewall on the remote server
* Network routing configuration is preventing access to the host
* When using Amazon Web Services (AWS), rules for security groups are preventing the Chef server from communicating with PostgreSQL

CSPG011 (cannot authenticate)
-----------------------------------------------------
**Reason**

Cannot authenticate to PostgreSQL on the remote server.

**Possible Causes**

* Incorrect password specified for ``db_superuser_password``
* Incorrect user name specified for ``db_superuser``

CSPG012 (incorrect rules)
-----------------------------------------------------
**Reason**

Cannot connect to PostgreSQL on the remote server because rules in ``pg_hba`` are incorrect.

**Possible Causes**

* There is no ``pg_hba.conf`` rule for the ``db_superuser`` in PostgreSQL
* A rule exists for the ``db_superuser`` in ``pg_hba.conf``, but it does not specify ``md5`` access
* A rule in ``pg_hba.conf`` specifies an incorrect originating address

**Resolution**

* Entries in the ``pg_hba.conf`` file should allow all user names that originate from any Chef server instance using ``md5`` authentication. For example, a ``pg_hba.conf`` entry for a valid username and password from the 192.168.18.0 subnet:

  .. code-block:: bash

	 host     postgres     all     192.168.18.0/24     md5

  or, specific named users with a valid password originating from the 192.168.18.0 subnet. A file named ``$PGDATA/chef_users`` with the following content must be created:

  .. code-block:: bash

	 opscode_chef
	 opscode_chef_ro
	 bifrost
	 bifrost_ro
	 oc_id
	 oc_id_ro

  where ``CHEF-SUPERUSER-NAME`` is replaced with the same user name specified by ``postgresql['db_superuser']``. The corresponding ``pg_hba.conf`` entry is similar to:

  .. code-block:: bash

     host     postgres     @chef_users     192.168.93.0/24     md5

  or, using the same ``$PGDATA/chef_users`` file (from the previous example), the following example shows a way to limit connections to specific nodes that are running components of the Chef server. This approach requires more maintanence because the ``pg_hba.conf`` file must be updated when machines are added to or removed from the Chef server configuration. For example, a high availability configuration with four nodes: ``backend-1`` (192.168.18.100), ``backend-2`` (192.168.18.101), ``frontend-1`` (192.168.18.110), and ``frontend-2`` (192.168.18.111).

  The corresponding ``pg_hba.conf`` entry is similar to:

  .. code-block:: bash

     host     postgres     @chef_users     192.168.18.100     md5
     host     postgres     @chef_users     192.168.18.101     md5
     host     postgres     @chef_users     192.168.18.110     md5
     host     postgres     @chef_users     192.168.18.111     md5

  These changes also require a configuration reload for PostgreSQL:

  .. code-block:: bash

	 pg_ctl reload

  or:

  .. code-block:: bash

	 SELECT pg_reload_conf();

* Rules in the ``pg_hba.conf`` file should allow only specific application names: ``$db_superuser`` (the configured superuser name in the chef-server.rb file), ``oc_id``, ``oc_id_ro``, ``opscode_chef``, ``opscode_chef_ro``, ``bifrost``, and ``bifrost_ro``

CSPG013 (incorrect permissions)
-----------------------------------------------------
**Reason**

The ``db_superuser`` account has incorrect permissions.

**Possible Causes**

* The ``db_superuser`` account has not been granted ``SUPERUSER`` access
* The ``db_superuser`` account has not been granted ``CREATE DATABASE`` and ``CREATE ROLE`` privileges

  .. code-block:: bash

     ALTER ROLE "$your_db_superuser_name" WITH SUPERUSER

  or:

  .. code-block:: bash

     ALTER ROLE "$your_db_superuser_name"  WITH CREATEDB CREATEROLE

CSPG014 (incorrect version)
-----------------------------------------------------
**Reason**

Bad version of PostgreSQL.

**Possible Causes**

* The remote server is not running PostgreSQL version 9.2.x

.. currently, Amazon AWS RDS instances use PostgreSQL 9.3 and 9.4.

CSPG015 (missing database)
-----------------------------------------------------
**Reason**

The database template ``template1`` does not exist.

**Possible Causes**

* The ``template1`` database template has been removed from the remote server

**Resolution**

* Run the following command (as a superuser):

  .. code-block:: bash

     CREATE DATABASE template1 TEMPLATE template0

  or:

  .. code-block:: bash

     createdb -T template0 template1

CSPG016 (database exists)
-----------------------------------------------------
**Reason**

One (or more) of the PostgreSQL databases already exists.

**Possible Causes**

* The ``opscode_chef``, ``oc_id``, and/or ``bifrost`` databases already exist on the remote machine
* The PostgreSQL database exists for another application

**Resolution**

* Verify that the ``opscode_chef``, ``oc_id``, and/or ``bifrost`` databases exist, and then verify that they are not being used by another internal application
* Back up the PostgreSQL data, remove the existing databases, and reconfigure the Chef server

CSPG017 (user exists)
-----------------------------------------------------
**Reason**

One (or more) of the PostgreSQL predefined users already exists.

**Possible Causes**

* The ``opscode_chef``, ``ospcode_chef_ro``, ``bifrost``, ``bifrost_ro``, ``oc_id``, or ``oc_id_ro`` users already exist on the remote machine
* The ``postgresql['vip']`` setting is configured to a remote host, but ``postgresql['external']`` is not set to ``true``, which causes the ``opscode_chef`` and ``ospcode_chef_ro`` users to be created before the machine is reconfigured, which will return a permissions error
* Existing, valid naming conflicts are present, where the users were created independently of the Chef server

**Resolution**

* Run the following, if it is safe to do so, to update the user name that is specified in the error message:

  .. code-block:: bash

     DROP ROLE "name-of-user";

  or change the name of the user by updating following settings in the chef-server.rb configuration file:

  .. code-block:: none

     oc_id['sql_user'] = 'alternative_username'
     oc_id['sql_ro_user'] = alternative_username_for_ro_access'
     opscode_erchef['sql_user'] = 'alternative_username'
     opscode_erchef['sql_ro_user'] = 'alternative_username_for_ro_access'
     oc_bifrost['sql_ro_user'] = 'alternative_username'
     oc_bifrost['sql_ro_user'] = 'alternative_username_for_ro_access'
