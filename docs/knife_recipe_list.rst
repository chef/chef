=====================================================
knife recipe list
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_recipe_list.rst>`__

.. tag knife_recipe_list_summary

Use the ``knife recipe list`` subcommand to view all of the recipes that are on a Chef server. A regular expression can be used to limit the results to recipes that match a specific pattern. The regular expression must be within quotes and not be surrounded by forward slashes (/).

.. end_tag

Syntax
=====================================================
This subcommand has the following syntax:

.. code-block:: bash

   $ knife recipe list REGEX

Options
=====================================================
.. note:: .. tag knife_common_see_common_options_link

          Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

          .. end_tag

This command does not have any specific options.

Examples
=====================================================
The following examples show how to use this knife subcommand:

**View a list of recipes**

To view a list of recipes:

.. code-block:: bash

   $ knife recipe list 'couchdb::*'

to return:

.. code-block:: bash

   couchdb::main_monitors
   couchdb::master
   couchdb::default
   couchdb::org_cleanu
