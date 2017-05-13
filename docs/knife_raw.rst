=====================================================
knife raw
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_raw.rst>`__

.. tag knife_raw_summary

Use the ``knife raw`` subcommand to send a REST request to an endpoint in the Chef server API.

.. end_tag

Syntax
=====================================================
This subcommand has the following syntax:

.. code-block:: bash

   $ knife raw REQUEST_PATH (options)

Options
=====================================================
.. note:: .. tag knife_common_see_common_options_link

          Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

          .. end_tag

This subcommand has the following options:

``-i FILE``, ``--input FILE``
   The name of a file to be used with the ``PUT`` or a ``POST`` request.

``--[no-]pretty``
   Use ``--no-pretty`` to disable pretty-print output for JSON. Default: ``--pretty``.

``-m METHOD``, ``--method METHOD``
   The request method: ``DELETE``, ``GET``, ``POST``, or ``PUT``. Default value: ``GET``.

``--proxy-auth``
   Enable proxy authentication to the Chef server web user interface. Default value: ``false``.

   New in Chef Client 12.1

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
=====================================================
The following examples show how to use this knife subcommand:

**View a client**

To view information about a client:

.. code-block:: bash

   knife raw /clients/<client_name>

**View a node**

To view information about a node:

.. code-block:: bash

   knife raw /nodes/<node_name>

**Delete a data bag**

To delete a data bag, enter a command similar to:

.. code-block:: bash

   $ knife raw -m DELETE /data/foo

to return something similar to:

.. code-block:: bash

   {
     "name":"foo",
     "json_class":"Chef::DataBag",
     "chef_type":"data_bag"
   }

**Delete a role**

To delete a role, enter a command similar to:

.. code-block:: bash

   $ knife raw -m DELETE /roles/role-foo.json

to return something similar to:

.. code-block:: bash

   {
     "name":"role-foo",
     "json_class":"Chef::Role",
     "chef_type":"role"
   }
