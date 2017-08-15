=====================================================
knife user
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_user.rst>`__

.. tag knife_user_summary

The ``knife user`` subcommand is used to manage the list of users and their associated RSA public key-pairs.

.. end_tag

.. warning:: In versions of the chef-client prior to version 12.0, this subcommand ONLY works when run against the open source Chef server; it does not run against Enterprise Chef (including hosted Enterprise Chef), or Private Chef.

             Starting with Chef server 12.0, this functionality is built into the :doc:`chef-server-ctl </ctl_chef_server>` command-line tool as part of the following arguments:

             * `user-create </ctl_chef_server.html#user-create>`_
             * `user-delete </ctl_chef_server.html#user-delete>`_
             * `user-edit </ctl_chef_server.html#user-edit>`_
             * `user-list </ctl_chef_server.html#user-list>`_
             * `user-show </ctl_chef_server.html#user-show>`_

             Starting with chef-client version 12.4.1, the ``knife user`` functionality is restored for the following arguments: ``user-edit``, ``user-list``, and ``user-show`` for Chef server version 12.0 (and higher).

             Starting with Chef server 12.4.1, `users who are members of the server-admins group </ctl_chef_server.html#server-admins>`_ may use the ``user-create``, ``user-delete``, ``user-edit``, ``user-list``, and ``user-show`` arguements to manage user accounts on the Chef server via the ``knife user`` subcommand.

.. note:: .. tag knife_common_see_common_options_link

          Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

          .. end_tag

Changed in Chef Client 12.4 to support public key management for users and clients.

create
=====================================================
Use the ``create`` argument to create a user. This process will generate an RSA key pair for the named user. The public key will be stored on the Chef server and the private key will be displayed on ``STDOUT`` or written to a named file.

* For the user, the private key should be copied to the system as ``/etc/chef/client.pem``.
* For knife, the private key is typically copied to ``~/.chef/client_name.pem`` and referenced in the knife.rb configuration file.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife user create USER_NAME (options)

Options
-----------------------------------------------------
This argument has the following options:

``-a``, ``--admin``
   Create a client as an admin client. This is required for any user to access Open Source Chef as an administrator. This option only works when used with the open source Chef server and will have no effect when used with Enterprise Chef or Chef server 12.x.

``-f FILE_NAME``, ``--file FILE_NAME``
   Save a private key to the specified file name.

``-p PASSWORD``, ``--password PASSWORD``
   The user password.

``--user-key FILE_NAME``
   The path to a file that contains the public key.  If this option is not specified, the Chef server will generate a public/private key pair.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Create a user**

.. To create a new user named "Radio Birdman" with a private key saved to "/keys/user_name", enter:

.. code-block:: bash

   $ knife user create "Radio Birdman" -f /keys/user_name

delete
=====================================================
Use the ``delete`` argument to delete a registered user.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife user delete USER_NAME

Options
-----------------------------------------------------
This command does not have any specific options.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Delete a user**

.. To delete a user named "Steve Danno", enter:

.. code-block:: bash

   $ knife user delete "Steve Danno"

edit
=====================================================
Use the ``edit`` argument to edit the details of a user. When this argument is run, knife will open $EDITOR. When finished, knife will update the Chef server with those changes.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife user edit USER_NAME

Options
-----------------------------------------------------
This command does not have any specific options.

Examples
-----------------------------------------------------
None.

key create
=====================================================
.. tag knife_user_key_create

Use the ``key create`` argument to create a public key.

.. end_tag

Syntax
-----------------------------------------------------
.. tag knife_user_key_create_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife user key create USER_NAME (options)

.. end_tag

Options
-----------------------------------------------------
.. tag knife_user_key_create_options

This argument has the following options:

``-e DATE``, ``--expiration-date DATE``
   The expiration date for the public key, specified as an ISO 8601 formatted string: ``YYYY-MM-DDTHH:MM:SSZ``. If this option is not specified, the public key will not have an expiration date. For example: ``2013-12-24T21:00:00Z``.

``-f FILE``, ``--file FILE``
   Save a private key to the specified file name.

``-k NAME``, ``--key-name NAME``
   The name of the public key.

``-p FILE_NAME``, ``--public-key FILE_NAME``
   The path to a file that contains the public key. If this option is not specified, and only if ``--key-name`` is specified, the Chef server will generate a public/private key pair.

.. end_tag

Examples
-----------------------------------------------------
None.

key delete
=====================================================
.. tag knife_user_key_delete

Use the ``key delete`` argument to delete a public key.

.. end_tag

Syntax
-----------------------------------------------------
.. tag knife_user_key_delete_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife user key delete USER_NAME KEY_NAME

.. end_tag

Examples
-----------------------------------------------------
None.

key edit
=====================================================
.. tag knife_user_key_edit

Use the ``key edit`` argument to modify or rename a public key.

.. end_tag

Syntax
-----------------------------------------------------
.. tag knife_user_key_edit_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife user key edit USER_NAME KEY_NAME (options)

.. end_tag

Options
-----------------------------------------------------
.. tag knife_user_key_edit_options

This argument has the following options:

``-c``, ``--create-key``
   Generate a new public/private key pair and replace an existing public key with the newly-generated public key. To replace the public key with an existing public key, use ``--public-key`` instead.

``-e DATE``, ``--expiration-date DATE``
   The expiration date for the public key, specified as an ISO 8601 formatted string: ``YYYY-MM-DDTHH:MM:SSZ``. If this option is not specified, the public key will not have an expiration date. For example: ``2013-12-24T21:00:00Z``.

``-f FILE``, ``--file FILE``
   Save a private key to the specified file name. If the ``--public-key`` option is not specified the Chef server will generate a private key.

``-k NAME``, ``--key-name NAME``
   The name of the public key.

``-p FILE_NAME``, ``--public-key FILE_NAME``
   The path to a file that contains the public key. If this option is not specified, and only if ``--key-name`` is specified, the Chef server will generate a public/private key pair.

.. end_tag

Examples
-----------------------------------------------------
None.

key list
=====================================================
.. tag knife_user_key_list

Use the ``key list`` argument to view a list of public keys for the named user.

.. end_tag

Syntax
-----------------------------------------------------
.. tag knife_user_key_list_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife user key list USER_NAME (options)

.. end_tag

Options
-----------------------------------------------------
.. tag knife_user_key_list_options

This argument has the following options:

``-e``, ``--only-expired``
   Show a list of public keys that have expired.

``-n``, ``--only-non-expired``
   Show a list of public keys that have not expired.

``-w``, ``--with-details``
   Show a list of public keys, including URIs and expiration status.

.. end_tag

Examples
-----------------------------------------------------
None.

key show
=====================================================
.. tag knife_user_key_show

Use the ``key show`` argument to view details for a specific public key.

.. end_tag

Syntax
-----------------------------------------------------
.. tag knife_user_key_show_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife user key show USER_NAME KEY_NAME

.. end_tag

Examples
-----------------------------------------------------
None.

list
=====================================================
Use the ``list`` argument to view a list of registered users.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife user list (options)

Options
-----------------------------------------------------
This argument has the following options:

``-w``, ``--with-uri``
   Show the corresponding URIs.

Examples
-----------------------------------------------------
None.

reregister
=====================================================
Use the ``reregister`` argument to regenerate an RSA key pair for a user. The public key will be stored on the Chef server and the private key will be displayed on ``STDOUT`` or written to a named file.

.. note:: Running this argument will invalidate the previous RSA key pair, making it unusable during authentication to the Chef server.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife user reregister USER_NAME (options)

Options
-----------------------------------------------------
This argument has the following options:

``-f FILE_NAME``, ``--file FILE_NAME``
   Save a private key to the specified file name.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Regenerate the RSA key-pair**

.. To regenerate the RSA key pair for a user named "Robert Younger", enter:

.. code-block:: bash

   $ knife user reregister "Robert Younger"

show
=====================================================
Use the ``show`` argument to show the details of a user.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife user show USER_NAME (options)

Options
-----------------------------------------------------
This argument has the following options:

``-a ATTR``, ``--attribute ATTR``
   The attribute (or attributes) to show.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Show user data**

To view a user named ``Dennis Teck``, enter:

.. code-block:: bash

   $ knife user show "Dennis Teck"

to return something like:

.. code-block:: bash

   chef_type:   user
   json_class:  Chef::User
   name:        Dennis Teck
   public_key:

**Show user data as JSON**

To view information in JSON format, use the ``-F`` common option as part of the command like this:

.. code-block:: bash

   $ knife user show "Dennis Teck" -F json

(Other formats available include ``text``, ``yaml``, and ``pp``, e.g. ``-F yaml`` for YAML.)
