=====================================================
knife tag
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_tag.rst>`__

.. tag chef_tags

A tag is a custom description that is applied to a node. A tag, once applied, can be helpful when managing nodes using knife or when building recipes by providing alternate methods of grouping similar types of information.

.. end_tag

.. tag knife_tag_summary

The ``knife tag`` subcommand is used to apply tags to nodes on a Chef server.

.. end_tag

.. note:: .. tag knife_common_see_common_options_link

          Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

          .. end_tag

create
=====================================================
Use the ``create`` argument to add one or more tags to a node.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife tag create NODE_NAME [TAG...]

Options
-----------------------------------------------------
This command does not have any specific options.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Create tags**

To create tags named ``seattle``, ``portland``, and ``vancouver``, enter:

.. code-block:: bash

   $ knife tag create node seattle portland vancouver

delete
=====================================================
Use the ``delete`` argument to delete one or more tags from a node.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife tag delete NODE_NAME [TAG...]

Options
-----------------------------------------------------
This command does not have any specific options.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Delete tags**

To delete tags named ``denver`` and ``phoenix``, enter:

.. code-block:: bash

   $ knife tag delete node denver phoenix

Type ``Y`` to confirm a deletion.

list
=====================================================
Use the ``list`` argument to list all of the tags that have been applied to a node.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife tag list [NODE_NAME...]

Options
-----------------------------------------------------
This command does not have any specific options.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**View a list of tags**

To view the tags for a node named ``devops_prod1``, enter:

.. code-block:: bash

   $ knife tag list devops_prod1

