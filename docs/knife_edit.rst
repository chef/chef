=====================================================
knife edit
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_edit.rst>`__

.. tag knife_edit_summary

Use the ``knife edit`` subcommand to edit objects on the Chef server. This subcommand works similar to ``knife cookbook edit``, ``knife data bag edit``, ``knife environment edit``, ``knife node edit``, and ``knife role edit``, but with a single verb (and a single action).

.. end_tag

Syntax
=====================================================
This subcommand has the following syntax:

.. code-block:: bash

   $ knife edit (options)

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

``--local``
   Show files in the local chef-repo instead of a remote location. Default: ``false``.

``--repo-mode MODE``
   The layout of the local chef-repo. Possible values: ``static``, ``everything``, or ``hosted_everything``. Use ``static`` for just roles, environments, cookbooks, and data bags. By default, ``everything`` and ``hosted_everything`` are dynamically selected depending on the server type. Default: ``everything`` / ``hosted_everything``.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
=====================================================
The following examples show how to use this knife subcommand:

**Remove a user from /groups/admins.json**

.. tag knife_edit_admin_users

A user who belongs to the ``admins`` group must be removed from the group before they may be removed from an organization. To remove a user from the ``admins`` group, run the following:

.. code-block:: bash

   $ EDITOR=vi knife edit /groups/admins.json

make the required changes, and then save the file.

.. end_tag

