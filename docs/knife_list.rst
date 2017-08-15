=====================================================
knife list
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_list.rst>`__

.. tag knife_list_summary

Use the ``knife list`` subcommand to view a list of objects on the Chef server. This subcommand works similar to ``knife cookbook list``, ``knife data bag list``, ``knife environment list``, ``knife node list``, and ``knife role list``, but with a single verb (and a single action).

.. end_tag

Syntax
=====================================================
This subcommand has the following syntax:

.. code-block:: bash

   $ knife list [PATTERN...] (options)

Options
=====================================================
.. note:: .. tag knife_common_see_common_options_link

          Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

          .. end_tag

This subcommand has the following options:

``-1``
   Show only one column of results. Default: ``false``.

``--chef-repo-path PATH``
   The path to the chef-repo. This setting will override the default path to the chef-repo. Default: same value as specified by ``chef_repo_path`` in client.rb.

``--concurrency``
   The number of allowed concurrent connections. Default: ``10``.

``-d``
   Prevent a directory's children from showing when a directory matches a pattern. Default value: ``false``.

``-f``, ``--flat``
   Show a list of file names. Set to ``false`` to view ``ls``-like output. Default: ``false``.

``--local``
   Return only the contents of the local directory. Default: ``false``.

``-p``
   Show directories with trailing slashes (/). Default: ``false``.

``-R``
   List directories recursively. Default: ``false``.

``--repo-mode MODE``
   The layout of the local chef-repo. Possible values: ``static``, ``everything``, or ``hosted_everything``. Use ``static`` for just roles, environments, cookbooks, and data bags. By default, ``everything`` and ``hosted_everything`` are dynamically selected depending on the server type. Default: ``everything`` / ``hosted_everything``.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
=====================================================
The following examples show how to use this knife subcommand:

**List roles**

For example, to view a list of roles on the Chef server:

.. code-block:: bash

   $ knife list roles/

**List roles and environments**

To view a list of roles and environments on the Chef server:

.. code-block:: bash

   $ knife list roles/ environments/

**List everything**

To view a list of absolutely everything on the Chef server:

.. code-block:: bash

   $ knife list -R /
