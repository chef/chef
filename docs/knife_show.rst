=====================================================
knife show
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_show.rst>`__

.. tag knife_show_summary

Use the ``knife show`` subcommand to view the details of one (or more) objects on the Chef server. This subcommand works similar to ``knife cookbook show``, ``knife data bag show``, ``knife environment show``, ``knife node show``, and ``knife role show``, but with a single verb (and a single action).

.. end_tag

Syntax
=====================================================
This subcommand has the following syntax:

.. code-block:: bash

   $ knife show [PATTERN...] (options)

Options
=====================================================
.. note:: .. tag knife_common_see_common_options_link

          Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

          .. end_tag

This subcommand has the following options:

``-a ATTR``, ``--attribute ATTR``
   The attribute (or attributes) to show.

``--chef-repo-path PATH``
   The path to the chef-repo. This setting will override the default path to the chef-repo. Default: same value as specified by ``chef_repo_path`` in client.rb.

``--concurrency``
   The number of allowed concurrent connections. Default: ``10``.

``--local``
   Show local files instead of remote files.

``--repo-mode MODE``
   The layout of the local chef-repo. Possible values: ``static``, ``everything``, or ``hosted_everything``. Use ``static`` for just roles, environments, cookbooks, and data bags. By default, ``everything`` and ``hosted_everything`` are dynamically selected depending on the server type. Default: ``everything`` / ``hosted_everything``.
   
``-S SEPARATOR``, ``--field-separator SEPARATOR``
   Character separator used to delineate nesting in --attribute filters. For example, to use a colon as the delimiter, specify ``-S:`` in your ``knife node show`` subcommand. Default is ``.``

   New in Chef Client 12.16.

Examples
=====================================================
The following examples show how to use this knife subcommand:

**Show all cookbooks**

To show all cookbooks in the ``cookbooks/`` directory:

.. code-block:: bash

   $ knife show cookbooks/

or, (if already in the ``cookbooks/`` directory in the local chef-repo):

.. code-block:: bash

   $ knife show

**Show roles and environments**

.. To show roles and environments:

.. code-block:: bash

   $ knife show roles/ environments/
