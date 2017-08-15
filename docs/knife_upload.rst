=====================================================
knife upload
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_upload.rst>`__

.. tag knife_upload_summary

Use the ``knife upload`` subcommand to upload data to the  Chef server from the current working directory in the chef-repo. The following types of data may be uploaded with this subcommand:

* Cookbooks
* Data bags
* Roles stored as JSON data
* Environments stored as JSON data

(Roles and environments stored as Ruby data will not be uploaded.) This subcommand is often used in conjunction with ``knife diff``, which can be used to see exactly what changes will be uploaded, and then ``knife download``, which does the opposite of ``knife upload``.

.. end_tag

Syntax
=====================================================
This subcommand has the following syntax:

.. code-block:: bash

   $ knife upload [PATTERN...] (options)

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

``--[no-]diff``
   Upload only new and modified files. Set to ``false`` to upload all files. Default: ``true``.

``--[no-]force``
   Use ``--force`` to upload roles, cookbooks, etc. even if the file in the directory is identical (by default, no ``POST`` or ``PUT`` is performed unless an actual change would be made). Default: ``--no-force``.

``--[no-]freeze``
   Require changes to a cookbook be included as a new version. Only the ``--force`` option can override this setting. Default: ``false``.

``-n``, ``--dry-run``
   Take no action and only print out results. Default: ``false``.

   New in Chef Client 12.0.

``--[no-]purge``
   Use ``--purge`` to delete roles, cookbooks, etc. from the Chef server if their corresponding files do not exist in the chef-repo. By default, such objects are left alone and NOT purged. Default: ``--no-purge``.

``--[no-]recurse``
   Use ``--no-recurse`` to disable uploading a directory recursively. Default: ``--recurse``.

``--repo-mode MODE``
   The layout of the local chef-repo. Possible values: ``static``, ``everything``, or ``hosted_everything``. Use ``static`` for just roles, environments, cookbooks, and data bags. By default, ``everything`` and ``hosted_everything`` are dynamically selected depending on the server type. Default: ``everything`` / ``hosted_everything``.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
=====================================================
The following examples show how to use this knife subcommand:

**Upload the entire chef-repo**

Browse to the top level of the chef-repo and enter:

.. code-block:: bash

   $ knife upload .

or from anywhere in the chef-repo, enter:

.. code-block:: bash

   $ knife upload /

to upload all cookbooks and data bags, plus all roles and enviroments that are stored as JSON data. (Roles and environments stored as Ruby data will not be uploaded.)

**Upload the /cookbooks directory**

Browse to the top level of the chef-repo and enter:

.. code-block:: bash

   $ knife upload cookbooks

or from anywhere in the chef-repo, enter:

.. code-block:: bash

   $ knife upload /cookbooks

**Upload the /environments directory**

Browse to the top level of the chef-repo and enter:

.. code-block:: bash

   $ knife upload environments

or from anywhere in the chef-repo, enter:

.. code-block:: bash

   $ knife upload /environments

to upload all enviroments that are stored as JSON data. (Environments stored as Ruby data will not be uploaded.)

**Upload a single environment**

Browse to the top level of the chef-repo and enter:

.. code-block:: bash

   $ knife upload environments/production.json

or from the ``environments/`` directory, enter:

.. code-block:: bash

   $ knife upload production.json

**Upload the /roles directory**

Browse to the top level of the chef-repo and enter:

.. code-block:: bash

   $ knife upload roles

or from anywhere in the chef-repo, enter:

.. code-block:: bash

   $ knife upload /roles

to upload all roles that are stored as JSON data. (Roles stored as Ruby data will not be uploaded.)

**Upload cookbooks and roles**

Browse to the top level of the chef-repo and enter:

.. code-block:: bash

   $ knife upload cookbooks/apache\* roles/webserver.json

**Use output of knife deps to pass command to knife upload**

.. Use the output of ``knife deps`` to pass a command to ``knife upload``. For example:

.. code-block:: bash

   $ knife upload `knife deps nodes/*.json`
