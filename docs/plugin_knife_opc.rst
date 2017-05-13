=====================================================
knife opc
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/plugin_knife_opc.rst>`__

.. tag plugin_knife_opc_summary

The ``knife opc`` subcommand is used to manage organizations and users in Chef server 12.

.. note:: The ``knife-opc`` plugin has been imported into ChefDK with version 1.0. If you use an older version, please upgrade, or install ``knife-opc`` from RubyGems manually.

.. note:: Administrator permissions are required to add, remove, or edit users. To manage organizations, or change a user's assignment to an organization, the pivotal key is required. To grant a user administrator permissions, use ``chef-server-ctl grant-server-admin-permissions USER_NAME`` on the Chef server. :doc:`See chef-server-ctl for details </ctl_chef_server>`.

.. note:: Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

.. end_tag

.. _plugin_knife_opc-knife-rb-configuration:

knife.rb Configuration
=====================================================
Unlike other knife subcommands the subcommands in the knife-opc plugin make API calls against the root of your Chef server installation's API endpoint.

Typically the ``chef_server_url`` for your Chef server installation may look like this:

.. code-block:: ruby

   chef_server_url 'https://chef.yourdomain.com/organizations/ORG_NAME'

To configure knife-opc, set the ``chef_server_root`` option to the root of your Chef server installation:

.. code-block:: ruby

   chef_server_root 'https://chef.yourdomain.com/'

If your ``chef_server_url`` configuration ends with ``/organizations/ORG_NAME`` (as shown above), this setting will default to ``https://chef.yourdomain.com/``.

.. note:: On Chef server 12, the majority of the commands provided by this plugin can be accessed via ``chef-server-ctl`` wrapper commands. :doc:`See chef-server-ctl for details </ctl_chef_server>`.

.. _plugin_knife_opc-opc-user-list:

opc user list
=====================================================
Show a list of all users in your Chef server installation.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife opc user list (options)

Options
-----------------------------------------------------
This argument has the following options:

``-w``, ``--with-uri``
   Show corresponding URIs.

Example
-----------------------------------------------------
.. code-block:: bash

   $ knife opc user list
   alice
   pivotal
   $ knife opc user list -w
   alice: https://chef-server.fqdn/users/alice
   pivotal: https://chef-server.fqdn/users/pivotal

.. _plugin_knife_opc-opc-user-show:

opc user show
=====================================================
Shows the details of a user in your Chef server installation.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife opc user show USER_NAME (options)

Options
-----------------------------------------------------
This argument has the following options:

``-l``, ``--with-orgs``
   Show the organizations of which the user is a member.

Example
-----------------------------------------------------
.. code-block:: bash

   $ knife opc user show alice -l
   display_name:  Alice Schmidt
   email:         alice@chef.io
   first_name:    Alice
   last_name:     Schmidt
   middle_name:
   organizations: acme
   public_key:    -----BEGIN PUBLIC KEY-----
   [...]
   -----END PUBLIC KEY-----


   username:     alice

.. _plugin_knife_opc-opc-user-create:

opc user create
=====================================================
Creates a new user in your Chef server installation. The user's private key will be returned in response.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife opc user create USER_NAME FIRST_NAME [MIDDLE_NAME] LAST_NAME EMAIL PASSWORD (options)

Options
-----------------------------------------------------
This argument has the following options:

``-f FILENAME``, ``--filename FILENAME``
   Write private key to ``FILENAME`` rather than ``STDOUT``.

Example
-----------------------------------------------------
.. code-block:: bash

   $ knife opc user create arno arno schmidt arno@chef.io password
   -----BEGIN RSA PRIVATE KEY-----
   [...]
   -----END RSA PRIVATE KEY-----

.. _plugin_knife_opc-opc-user-delete:

opc user delete
=====================================================
Deletes the given OPC user.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife opc user delete USER_NAME [-d] [-R]

Options
-----------------------------------------------------
This argument has the following options:

``-d``, ``--no-disassociate-user``
   Don't disassociate the user first.

``-R``, ``--remove-from-admin-groups``
   If the user is a member of any org admin groups, attempt to remove from those groups. Ignored if ``--no-disassociate-user`` is set.


Example
-----------------------------------------------------
.. code-block:: bash

   $ knife opc user delete arno
   Do you want to delete the user arno? (Y/N) Y
   Checking organization memberships...
   Deleting user arno.

.. _plugin_knife_opc-opc-user-edit:

opc user edit
=====================================================
Will open ``$EDITOR`` to edit a user. When finished editing, knife will update the given Chef server user.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife opc user edit USER_NAME

.. _plugin_knife_opc-opc-user-password:

Example
-----------------------------------------------------
.. code-block:: bash

   $ EDITOR=ed knife opc user edit arno
   639
   1,%p
   {
     "username": "arno",
     "email": "arno@chef.io",
     "display_name": "arno schmidt",
     "first_name": "arno",
     "last_name": "schmidt",
     "middle_name": "",
     "public_key": "-----BEGIN PUBLIC KEY-----\n[...]\n-----END PUBLIC KEY-----\n\n"
   }
   /email/s/chef.io/opscode.com/p
   "email": "arno@opscode.com",
   wq
   643
   Saved arno.
   $ knife opc user show arno
   display_name: arno schmidt
   email:        arno@opscode.io
   first_name:   arno
   last_name:    schmidt
   middle_name:
   public_key:   -----BEGIN PUBLIC KEY-----
   [...]
   -----END PUBLIC KEY-----


   username:     arno


opc user password
=====================================================
Command for managing password and authentication for a user.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife opc user password USER_NAME [PASSWORD | --enable_external_auth]

The last argument should either be a string to use as password or ``--enable_external_auth`` instead of a password to enable external authentication for this user.


Example
-----------------------------------------------------
.. code-block:: bash

   $ knife opc user password arno newpassword
   {"username"=>"arno", "email"=>"arno@opscode.com", "display_name"=>"arno schmidt", "first_name"=>"arno", "last_name"=>"schmidt", "middle_name"=>"", "public_key"=>"-----BEGIN PUBLIC KEY-----\n[...]\n-----END PUBLIC KEY-----\n\n", "password"=>"newpassword", "recovery_authentication_enabled"=>true}
   Authentication info updated for arno.

.. _plugin_knife_opc-opc-org-list:

opc org list
=====================================================
Show a list of all organizations in your Chef server installation.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife opc org list (options)

Options
-----------------------------------------------------
This argument has the following options:

``-w``, ``--with-uri``
   Show corresponding URIs.

``-a``, ``--all-orgs``
   Display auto-generated hidden orgs.

Example
-----------------------------------------------------
.. code-block:: bash

   $ knife opc org list -w -a
   acme: https://chef-server.fqdn/organizations/acme

.. _plugin_knife_opc-opc-org-show:

opc org show
=====================================================
Shows the details of an organization in your Chef server installation.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife opc org show ORG_NAME

Example
-----------------------------------------------------
.. code-block:: bash

   $ knife opc org show acme
   full_name: Acme
   guid:      cc9f9d0d4f6e7e35272e327e22e7affc
   name:      acme

.. _plugin_knife_opc-opc-org-create:

opc org create
=====================================================
Creates a new Chef server organization. The private key for the organization's validator client is returned.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife opc org create ORG_NAME ORG_FULL_NAME (options)

Options
-----------------------------------------------------
This argument has the following options:

``-f FILENAME``, ``--filename FILENAME``
   Write private key to ``FILENAME`` rather than ``STDOUT``.

``-a USER_NAME``, ``--association_user USER_NAME``
   Associate ``USER_NAME`` with the organization after creation.

Example
-----------------------------------------------------
.. code-block:: bash

   $ knife opc org create acme2 "The Other Acme" -a arno
   -----BEGIN RSA PRIVATE KEY-----
   [...]
   -----BEGIN RSA PRIVATE KEY-----

.. _plugin_knife_opc-opc-org-delete:

opc org delete
=====================================================
Deletes the given Chef server organization.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife opc org delete ORG_NAME

Example
-----------------------------------------------------
.. code-block:: bash

   $ knife opc org delete acme2
   Do you want to delete the organization acme2? (Y/N) Y
   full_name: The Other Acme
   guid:      2adec1140cf777a15d82d9099304da71
   name:      acme2

.. _plugin_knife_opc-opc-org-user-add:

opc org user add
=====================================================
Adds a user to an organization. Requires that the named organization and user both exist.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife opc org user add ORG_NAME USER_NAME

Example
-----------------------------------------------------
.. code-block:: bash

   $ knife opc org user add acme2 alice

.. _plugin_knife_opc-opc-org-user-remove:

opc org user remove
=====================================================
Removes a user from an organization. Requires that the named organization and user both exist, and that the user is currently associated with the organization.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife opc org user remove ORG_NAME USER_NAME

Example
-----------------------------------------------------
.. code-block:: bash

   $ knife opc org user remove acme2 alice
