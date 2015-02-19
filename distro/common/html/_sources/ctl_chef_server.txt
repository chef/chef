=====================================================
|chef server ctl| (executable)
=====================================================

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server.rst

backup-recover
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_backup_recover.rst

cleanse
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_cleanse.rst

gather-logs
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_gather_logs.rst

ha-status
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_ha_status.rst

help
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_help.rst

install
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_install.rst

**Syntax**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_install_syntax.rst

**Options**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_install_options.rst

Use Downloads
-----------------------------------------------------
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_install_features_download.rst

Use Local Packages
-----------------------------------------------------
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_install_features_manual.rst

master-recover
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_master_recover.rst

org-create
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_org_create.rst

**Syntax**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_org_create_syntax.rst

**Options**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_org_create_options.rst

**Examples**

.. code-block:: bash

   $ chef-server-ctl org-create prod Production


.. code-block:: bash

   $ chef-server-ctl org-create staging Staging -a chef-admin


.. code-block:: bash

   $ chef-server-ctl org-create dev Development -f /tmp/id-dev.key

org-delete
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_org_delete.rst

**Syntax**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_org_delete_syntax.rst

**Examples**

.. code-block:: bash

   $ chef-server-ctl org-delete infra-testing-20140909


.. code-block:: bash
      
   $ chef-server-ctl org-delete pedant-testing-org

org-list
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_org_list.rst

**Syntax**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_org_list_syntax.rst

**Options**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_org_list_options.rst

org-show
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_org_show.rst

**Syntax**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_org_show_syntax.rst

org-user-add
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_org_user_add.rst

**Syntax**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_org_user_add_syntax.rst

**Options**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_org_user_add_options.rst

**Examples**

.. code-block:: bash

   $ chef-server-ctl org-user-add prod john_smith

.. code-block:: bash

   $ chef-server-ctl org-user-add preprod testmaster

.. code-block:: bash

   $ chef-server-ctl org-user-add dev grantmc --admin


org-user-remove
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_org_user_remove.rst

**Syntax**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_org_user_remove_syntax.rst

**Examples**

.. code-block:: bash

   $ chef-server-ctl org-user-remove prod john_smith

.. code-block:: bash

   $ chef-server-ctl org-user-remove prod testmaster


password
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_password.rst

reconfigure
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_reconfigure.rst

show-config
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_show_config.rst

uninstall
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_uninstall.rst

upgrade
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_upgrade.rst

**Syntax**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_upgrade_syntax.rst

**Options**

.. note:: Options for the ``upgrade`` subcommand may only be used when upgrading from |chef server osc| 11 to |chef server| 12.

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_upgrade_options.rst

user-create
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_user_create.rst

**Syntax**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_user_create_syntax.rst

**Options**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_user_create_options.rst

**Examples**

.. code-block:: bash

   $ chef-server-ctl user-create john_smith John Smith john_smith@example.com insecure-passord


.. code-block:: bash

   $ chef-server-ctl user-create jane_doe Jane Doe jane_doe@example.com PaSSword -f /tmp/jane_doe.key


.. code-block:: bash

   $ chef-server-ctl user-create waldendude Henry David Thoreau waldendude@example.com excursions


user-delete
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_user_delete.rst

**Syntax**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_user_delete_syntax.rst

**Examples**

.. code-block:: bash

   $ chef-server-ctl user-delete john_smith


.. code-block:: bash

   $ chef-server-ctl user-delete jane_doe

user-edit
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_user_edit.rst

**Syntax**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_user_edit_syntax.rst

**Examples**

.. code-block:: bash

   $ chef-server-ctl user-edit john_smith


.. code-block:: bash

   $ chef-server-ctl user-edit jane_doe


user-list
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_user_list.rst

**Syntax**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_user_list_syntax.rst

**Options**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_user_list_options.rst

user-show
=====================================================
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_user_show.rst

**Syntax**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_user_show_syntax.rst

**Options**

.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_user_show_options.rst

Service Subcommands
=====================================================
The |chef server| has a built in process supervisor, which ensures that all of the required services are in the appropriate state at any given time. The supervisor starts two processes per service.

hup
-----------------------------------------------------
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_hup.rst

int
-----------------------------------------------------
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_int.rst

kill
-----------------------------------------------------
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_kill.rst

once
-----------------------------------------------------
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_once.rst

restart
-----------------------------------------------------
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_restart.rst

service-list
-----------------------------------------------------
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_service_list.rst

start
-----------------------------------------------------
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_start.rst

status
-----------------------------------------------------
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_status.rst

High Availability
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_status_ha.rst

Log Files
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_status_logs.rst

stop
-----------------------------------------------------
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_stop.rst

tail
-----------------------------------------------------
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_tail.rst

term
-----------------------------------------------------
.. include:: ../../includes_ctl_chef_server/includes_ctl_chef_server_term.rst

