=====================================================
knife node
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_node.rst>`__

.. tag node

A node is any machine---physical, virtual, cloud, network device, etc.---that is under management by Chef.

.. end_tag

.. tag knife_node_summary

The ``knife node`` subcommand is used to manage the nodes that exist on a Chef server.

.. end_tag

.. note:: .. tag knife_common_see_common_options_link

          Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

          .. end_tag

bulk delete
=====================================================
Use the ``bulk delete`` argument to delete one or more nodes that match a pattern defined by a regular expression. The regular expression must be within quotes and not be surrounded by forward slashes (/).

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife node bulk delete REGEX

Options
-----------------------------------------------------
This command does not have any specific options.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Bulk delete nodes**

Use a regular expression to define the pattern used to bulk delete nodes:

.. code-block:: bash

   $ knife node bulk delete "^[0-9]{3}$"

Type ``Y`` to confirm a deletion.

create
=====================================================
Use the ``create`` argument to add a node to the Chef server. Node data is stored as JSON on the Chef server.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife node create NODE_NAME

Options
-----------------------------------------------------
This command does not have any specific options.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Create a node**

To add a node named ``node1``, enter:

.. code-block:: bash

   $ knife node create node1

In the $EDITOR enter the node data in JSON:

.. code-block:: javascript

   {
      "normal": {
      },
      "name": "foobar",
      "override": {
      },
      "default": {
      },
      "json_class": "Chef::Node",
      "automatic": {
      },
      "run_list": [
         "recipe[zsh]",
         "role[webserver]"
      ],
      "chef_type": "node"
   }

When finished, save it.

delete
=====================================================
Use the ``delete`` argument to delete a node from the Chef server. If using Chef client 12.17 or later, you can delete multiple nodes using this subcommand.

.. note:: Deleting a node will not delete any corresponding API clients.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife node delete NODE_NAME

Options
-----------------------------------------------------
This command does not have any specific options.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Delete a node**

To delete a node named ``node1``, enter:

.. code-block:: bash

   $ knife node delete node1

edit
=====================================================
Use the ``edit`` argument to edit the details of a node on a Chef server. Node data is stored as JSON on the Chef server.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife node edit NODE_NAME (options)

Options
-----------------------------------------------------
This argument has the following options:

``-a``, ``--all``
   Display a node in the $EDITOR. By default, attributes that are default, override, or automatic, are not shown.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Edit a node**

To edit the data for a node named ``node1``, enter:

.. code-block:: bash

   $ knife node edit node1 -a

Update the role data in JSON:

.. code-block:: javascript

   {
      "normal": {
      },
      "name": "node1",
      "override": {
      },
      "default": {
      },
      "json_class": "Chef::Node",
      "automatic": {
      },
      "run_list": [
         "recipe[devops]",
         "role[webserver]"
      ],
      "chef_type": "node"
   }

When finished, save it.

environment set
=====================================================
Use the ``environment set`` argument to set the environment for a node without editing the node object.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife node environment_set NODE_NAME ENVIRONMENT_NAME (options)

Options
-----------------------------------------------------
This command does not have any specific options.

Examples
-----------------------------------------------------
None.

from file
=====================================================
Use the ``from file`` argument to create a node using existing node data as a template.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife node from file FILE

Options
-----------------------------------------------------
This command does not have any specific options.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Create a node using a JSON file**

To add a node using data contained in a JSON file:

.. code-block:: bash

   $ knife node from file "PATH_TO_JSON_FILE"

list
=====================================================
Use the ``list`` argument to view all of the nodes that exist on a Chef server.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife node list (options)

Options
-----------------------------------------------------
This argument has the following options:

``-w``, ``--with-uri``
   Show the corresponding URIs.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**View a list of nodes**

To verify the list of nodes that are registered with the Chef server, enter:

.. code-block:: bash

   $ knife node list

to return something similar to:

.. code-block:: bash

   i-12345678
   rs-123456

run_list add
=====================================================
.. tag node_run_list

A run-list defines all of the information necessary for Chef to configure a node into the desired state. A run-list is:

* An ordered list of roles and/or recipes that are run in the exact order defined in the run-list; if a recipe appears more than once in the run-list, the chef-client will not run it twice
* Always specific to the node on which it runs; nodes may have a run-list that is identical to the run-list used by other nodes
* Stored as part of the node object on the Chef server
* Maintained using knife, and then uploaded from the workstation to the Chef server, or is maintained using the Chef management console

.. end_tag

.. tag knife_node_run_list_add

Use the ``run_list add`` argument to add run-list items (roles or recipes) to a node.

.. end_tag

.. tag node_run_list_format

A run-list must be in one of the following formats: fully qualified, cookbook, or default. Both roles and recipes must be in quotes, for example:

.. code-block:: ruby

   'role[NAME]'

or

.. code-block:: ruby

   'recipe[COOKBOOK::RECIPE]'

Use a comma to separate roles and recipes when adding more than one item the run-list:

.. code-block:: ruby

   'recipe[COOKBOOK::RECIPE],COOKBOOK::RECIPE,role[NAME]'

.. end_tag

Syntax
-----------------------------------------------------
.. tag knife_node_run_list_add_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife node run_list add NODE_NAME RUN_LIST_ITEM (options)

.. end_tag

.. warning:: .. tag knife_common_windows_quotes

             When running knife in Microsoft Windows, a string may be interpreted as a wildcard pattern when quotes are not present in the command. The number of quotes to use depends on the shell from which the command is being run.

             When running knife from the command prompt, a string should be surrounded by single quotes (``' '``). For example:

             .. code-block:: bash

                $ knife node run_list set test-node 'recipe[iptables]'

             When running knife from Windows PowerShell, a string should be surrounded by triple single quotes (``''' '''``). For example:

             .. code-block:: bash

                $ knife node run_list set test-node '''recipe[iptables]'''

             .. end_tag

.. note:: .. tag knife_common_windows_quotes_module

          The chef-client version 12.4 release adds an optional feature to the Microsoft Installer Package (MSI) for Chef. This feature enables the ability to pass quoted strings from the Windows PowerShell command line without the need for triple single quotes (``''' '''``). This feature installs a Windows PowerShell module (typically in ``C:\opscode\chef\modules``) that is also appended to the ``PSModulePath`` environment variable. This feature is not enabled by default. To activate this feature, run the following command from within Windows PowerShell:

          .. code-block:: bash

             $ Import-Module chef

          or add ``Import-Module chef`` to the profile for Windows PowerShell located at:

          .. code-block:: bash

             ~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1

          This module exports cmdlets that have the same name as the command-line tools---chef-client, knife, chef-apply---that are built into Chef.

          For example:

          .. code-block:: bash

             $ knife exec -E 'puts ARGV' """&s0meth1ng"""

          is now:

          .. code-block:: bash

             $ knife exec -E 'puts ARGV' '&s0meth1ng'

          and:

          .. code-block:: bash

             $ knife node run_list set test-node '''role[ssssssomething]'''

          is now:

          .. code-block:: bash

             $ knife node run_list set test-node 'role[ssssssomething]'

          To remove this feature, run the following command from within Windows PowerShell:

          .. code-block:: bash

             $ Remove-Module chef

          .. end_tag

Options
-----------------------------------------------------
.. tag knife_node_run_list_add_options

This argument has the following options:

``-a ITEM``, ``--after ITEM``
   Add a run-list item after the specified run-list item.

``-b ITEM``, ``--before ITEM``
   Add a run-list item before the specified run-list item.

.. end_tag

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Add a role**

.. tag knife_node_run_list_add_role

To add a role to a run-list, enter:

.. code-block:: bash

   $ knife node run_list add NODE_NAME 'role[ROLE_NAME]'

.. end_tag

**Add roles and recipes**

.. tag knife_node_run_list_add_roles_and_recipes

To add roles and recipes to a run-list, enter:

.. code-block:: bash

   $ knife node run_list add NODE_NAME 'recipe[COOKBOOK::RECIPE_NAME],recipe[COOKBOOK::RECIPE_NAME],role[ROLE_NAME]'

.. end_tag

**Add a recipe with a FQDN**

.. tag knife_node_run_list_add_recipe_with_fqdn

To add a recipe to a run-list using the fully qualified format, enter:

.. code-block:: bash

   $ knife node run_list add NODE_NAME 'recipe[COOKBOOK::RECIPE_NAME]'

.. end_tag

**Add a recipe with a cookbook**

.. tag knife_node_run_list_add_recipe_with_cookbook

To add a recipe to a run-list using the cookbook format, enter:

.. code-block:: bash

   $ knife node run_list add NODE_NAME 'COOKBOOK::RECIPE_NAME'

.. end_tag

**Add the default recipe**

.. tag knife_node_run_list_add_default_recipe

To add the default recipe of a cookbook to a run-list, enter:

.. code-block:: bash

   $ knife node run_list add NODE_NAME 'COOKBOOK'

.. end_tag

run_list remove
=====================================================
.. tag knife_node_run_list_remove

Use the ``run_list remove`` argument to remove run-list items (roles or recipes) from a node. A recipe must be in one of the following formats: fully qualified, cookbook, or default. Both roles and recipes must be in quotes, for example: ``'role[ROLE_NAME]'`` or ``'recipe[COOKBOOK::RECIPE_NAME]'``. Use a comma to separate roles and recipes when removing more than one, like this: ``'recipe[COOKBOOK::RECIPE_NAME],COOKBOOK::RECIPE_NAME,role[ROLE_NAME]'``.

.. end_tag

Syntax
-----------------------------------------------------
.. tag knife_node_run_list_remove_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife node run_list remove NODE_NAME RUN_LIST_ITEM

.. end_tag

Options
-----------------------------------------------------
This command does not have any specific options.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Remove a role**

.. tag knife_node_run_list_remove_role

To remove a role from a run-list, enter:

.. code-block:: bash

   $ knife node run_list remove NODE_NAME 'role[ROLE_NAME]'

.. end_tag

**Remove a run-list**

.. tag knife_node_run_list_remove_run_list

To remove a recipe from a run-list using the fully qualified format, enter:

.. code-block:: bash

   $ knife node run_list remove NODE_NAME 'recipe[COOKBOOK::RECIPE_NAME]'

.. end_tag

run_list set
=====================================================
.. tag knife_node_run_list_set

Use the ``run_list set`` argument to set the run-list for a node. A recipe must be in one of the following formats: fully qualified, cookbook, or default. Both roles and recipes must be in quotes, for example: ``'role[ROLE_NAME]'`` or ``'recipe[COOKBOOK::RECIPE_NAME]'``. Use a comma to separate roles and recipes when setting more than one, like this: ``'recipe[COOKBOOK::RECIPE_NAME],COOKBOOK::RECIPE_NAME,role[ROLE_NAME]'``.

.. end_tag

Syntax
-----------------------------------------------------
.. tag knife_node_run_list_set_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife node run_list set NODE_NAME RUN_LIST_ITEM

.. end_tag

.. warning:: .. tag knife_common_windows_quotes

             When running knife in Microsoft Windows, a string may be interpreted as a wildcard pattern when quotes are not present in the command. The number of quotes to use depends on the shell from which the command is being run.

             When running knife from the command prompt, a string should be surrounded by single quotes (``' '``). For example:

             .. code-block:: bash

                $ knife node run_list set test-node 'recipe[iptables]'

             When running knife from Windows PowerShell, a string should be surrounded by triple single quotes (``''' '''``). For example:

             .. code-block:: bash

                $ knife node run_list set test-node '''recipe[iptables]'''

             .. end_tag

.. note:: .. tag knife_common_windows_quotes_module

          The chef-client version 12.4 release adds an optional feature to the Microsoft Installer Package (MSI) for Chef. This feature enables the ability to pass quoted strings from the Windows PowerShell command line without the need for triple single quotes (``''' '''``). This feature installs a Windows PowerShell module (typically in ``C:\opscode\chef\modules``) that is also appended to the ``PSModulePath`` environment variable. This feature is not enabled by default. To activate this feature, run the following command from within Windows PowerShell:

          .. code-block:: bash

             $ Import-Module chef

          or add ``Import-Module chef`` to the profile for Windows PowerShell located at:

          .. code-block:: bash

             ~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1

          This module exports cmdlets that have the same name as the command-line tools---chef-client, knife, chef-apply---that are built into Chef.

          For example:

          .. code-block:: bash

             $ knife exec -E 'puts ARGV' """&s0meth1ng"""

          is now:

          .. code-block:: bash

             $ knife exec -E 'puts ARGV' '&s0meth1ng'

          and:

          .. code-block:: bash

             $ knife node run_list set test-node '''role[ssssssomething]'''

          is now:

          .. code-block:: bash

             $ knife node run_list set test-node 'role[ssssssomething]'

          To remove this feature, run the following command from within Windows PowerShell:

          .. code-block:: bash

             $ Remove-Module chef

          .. end_tag

Options
-----------------------------------------------------
This command does not have any specific options.

Examples
-----------------------------------------------------
None.

show
=====================================================
Use the ``show`` argument to display information about a node.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife node show NODE_NAME (options)

Options
-----------------------------------------------------
This argument has the following options:

``-a ATTR``, ``--attribute ATTR``
   The attribute (or attributes) to show.

``-l``, ``--long``
   Display all attributes in the output and show the output as JSON.

   New in Chef Client 12.0.

``-m``, ``--medium``
   Display normal attributes in the output and to show the output as JSON.

   New in Chef Client 12.0.

``-r``, ``--run-list``
   Show only the run-list.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Show all data about nodes**

To view all data for a node named ``build``, enter:

.. code-block:: bash

   $ knife node show build

to return:

.. code-block:: bash

   Node Name:   build
   Environment: _default
   FQDN:
   IP:
   Run List:
   Roles:
   Recipes:
   Platform:

**Show basic information about nodes**

To show basic information about a node, truncated and nicely formatted:

.. code-block:: bash

   knife node show NODE_NAME

**Show all data about nodes, truncated**

To show all information about a node, nicely formatted:

.. code-block:: bash

   knife node show -l NODE_NAME

**Show attributes**

To list a single node attribute:

.. code-block:: bash

   knife node show NODE_NAME -a ATTRIBUTE_NAME

where ``ATTRIBUTE_NAME`` is something like ``kernel`` or ``platform``.

To list a nested attribute:

.. code-block:: bash

   knife node show NODE_NAME -a ATTRIBUTE_NAME.NESTED_ATTRIBUTE_NAME

where ``ATTRIBUTE_NAME`` is something like ``kernel`` and ``NESTED_ATTRIBUTE_NAME`` is something like ``machine``.

**Show the FQDN**

To view the FQDN for a node named ``i-12345678``, enter:

.. code-block:: bash

   $ knife node show i-12345678 -a fqdn

to return:

.. code-block:: bash

   fqdn: ip-10-251-75-20.ec2.internal

**Show a run-list**

To view the run-list for a node named ``dev``, enter:

.. code-block:: bash

   $ knife node show dev -r

**Show as JSON data**

To view information in JSON format, use the ``-F`` common option; use a command like this for a node named ``devops``:

.. code-block:: bash

   $ knife node show devops -F json

Other formats available include ``text``, ``yaml``, and ``pp``.

**Show as raw JSON data**

To view node information in raw JSON, use the ``-l`` or ``--long`` option:

.. code-block:: bash

   knife node show -l -F json NODE_NAME

and/or:

.. code-block:: bash

   knife node show -l --format=json NODE_NAME
