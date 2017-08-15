=====================================================
knife configure
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_configure.rst>`__

.. tag knife_configure_summary

Use the ``knife configure`` subcommand to create the knife.rb and client.rb files so that they can be distributed to workstations and nodes.

.. end_tag

Syntax
=====================================================
This subcommand has the following syntax when creating a knife.rb file:

.. code-block:: bash

   $ knife configure (options)

and the following syntax when creating a client.rb file:

.. code-block:: bash

   $ knife configure client DIRECTORY

Options
=====================================================
.. note:: .. tag knife_common_see_common_options_link

          Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

          .. end_tag

This subcommand has the following options for use when configuring a knife.rb file:

``--admin-client-name NAME``
   The name of the client, typically the name of the admin client.

``--admin-client-key PATH``
   The path to the private key used by the client, typically a file named ``admin.pem``.

``-i``, ``--initial``
   Create a API client, typically an administrator client on a freshly-installed Chef server.

``-r REPO``, ``--repository REPO``
   The path to the chef-repo.

``--validation-client-name NAME``
   The name of the validation client, typically a client named chef-validator.

``--validation-key PATH``
   The path to the validation key used by the client, typically a file named chef-validator.pem.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
=====================================================
The following examples show how to use this knife subcommand:

**Configure knife.rb**

.. To create a knife.rb file, enter:

.. code-block:: bash

   $ knife configure

**Configure client.rb**

.. To configure a client.rb, enter:

.. code-block:: bash

   $ knife configure client '/directory'

