=====================================================
knife delete
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_delete.rst>`__

.. tag knife_delete_summary

Use the ``knife delete`` subcommand to delete an object from a Chef server. This subcommand works similar to ``knife cookbook delete``, ``knife data bag delete``, ``knife environment delete``, ``knife node delete``, and ``knife role delete``, but with a single verb (and a single action).

.. end_tag

Syntax
=====================================================
This subcommand has the following syntax:

.. code-block:: bash

   $ knife delete [PATTERN...] (options)

Options
=====================================================
.. note:: .. tag knife_common_see_common_options_link

          Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

          .. end_tag

This subcommand has the following options:

``--both``
   Delete both local and remote copies of an object. Default: ``false``.

``--chef-repo-path PATH``
   The path to the chef-repo. This setting will override the default path to the chef-repo. Default: same value as specified by ``chef_repo_path`` in client.rb.

``--concurrency``
   The number of allowed concurrent connections. Default: ``10``.

``--local``
   Delete only the local copy of an object. A remote copy will not be deleted. Default: ``false``.

``-r``, ``--[no-]recurse``
   Use ``--recurse`` to delete directories recursively. Default: ``--no-recurse``.

``--repo-mode MODE``
   The layout of the local chef-repo. Possible values: ``static``, ``everything``, or ``hosted_everything``. Use ``static`` for just roles, environments, cookbooks, and data bags. By default, ``everything`` and ``hosted_everything`` are dynamically selected depending on the server type. Default: ``everything`` / ``hosted_everything``.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
=====================================================
None.
