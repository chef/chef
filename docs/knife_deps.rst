=====================================================
knife deps
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_deps.rst>`__

.. tag knife_deps_summary

Use the ``knife deps`` subcommand to identify dependencies for a node, role, or cookbook.

.. end_tag

Syntax
=====================================================
This subcommand has the following syntax:

.. code-block:: bash

   $ knife deps (options)

Options
=====================================================
.. note:: .. tag knife_common_see_common_options_link

          Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

          .. end_tag

This subcommand has the following options:

``--chef-repo-path PATH``
   The path to the chef-repo. This setting will override the default path to the chef-repo. Default: same value as specified by ``chef_repo_path`` in client.rb.

``--concurrency``
   The number of allowed concurrent connections. Default: ``10``.

``--[no-]recurse``
   Use ``--recurse`` to list dependencies recursively. This option can only be used when ``--tree`` is set to ``true``. Default: ``--no-recurse``.

``--remote``
   Determine dependencies from objects located on the Chef server instead of in the local chef-repo. Default: ``false``.

``--repo-mode MODE``
   The layout of the local chef-repo. Possible values: ``static``, ``everything``, or ``hosted_everything``. Use ``static`` for just roles, environments, cookbooks, and data bags. By default, ``everything`` and ``hosted_everything`` are dynamically selected depending on the server type. Default: ``everything`` / ``hosted_everything``.

``--tree``
   Show dependencies in a visual tree structure (including duplicates, if they exist). Default: ``false``.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
=====================================================
The following examples show how to use this knife subcommand:

**Find dependencies for a node**

.. To find the dependencies for a node:

.. code-block:: bash

   $ knife deps nodes/node_name.json

**Find dependencies for a role**

.. To find the dependencies for a role:

.. code-block:: bash

   $ knife deps roles/role_name.json

**Find dependencies for a cookbook**

.. To find the dependencies for a cookbook:

.. code-block:: bash

   $ knife deps cookbooks/cookbook_name.json

**Find dependencies for an environment**

.. To find the dependencies for an environment:

.. code-block:: bash

   $ knife deps environments/environment_name.json

**Find dependencies for a combination of nodes, roles, and so on**

To find the dependencies for a combination of nodes, cookbooks, roles, and/or environments:

.. code-block:: bash

   $ knife deps cookbooks/git.json cookbooks/github.json roles/base.json environments/desert.json nodes/mynode.json

**Use a wildcard**

A wildcard can be used to return all of the child nodes. For example, all of the environments:

.. code-block:: bash

   $ knife deps environments/*.json

**Return as tree**

Use the ``--tree`` option to view the results with structure:

.. code-block::  bash

   $ knife deps roles/webserver.json

to return something like:

.. code-block:: none

   roles/webserver.json
     roles/base.json
       cookbooks/github
         cookbooks/git
       cookbooks/users
     cookbooks/apache2

**Pass knife deps output to knife upload**

The output of ``knife deps`` can be passed to ``knife upload``:

.. code-block:: bash

   $ knife upload `knife deps nodes/*.json

**Pass knife deps output to knife xargs**

The output of ``knife deps`` can be passed to ``knife xargs``:

.. code-block:: bash

   $ knife deps nodes/*.json | xargs knife upload
