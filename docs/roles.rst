=====================================================
About Roles
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/roles.rst>`__

.. tag role

A role is a way to define certain patterns and processes that exist across nodes in an organization as belonging to a single job function. Each role consists of zero (or more) attributes and a run-list. Each node can have zero (or more) roles assigned to it. When a role is run against a node, the configuration details of that node are compared against the attributes of the role, and then the contents of that role's run-list are applied to the node's configuration details. When a chef-client runs, it merges its own attributes and run-lists with those contained within each assigned role.

.. end_tag

Role Attributes
=====================================================
.. tag role_attribute

An attribute can be defined in a role and then used to override the default settings on a node. When a role is applied during a chef-client run, these attributes are compared to the attributes that are already present on the node. When the role attributes take precedence over the default attributes, the chef-client will apply those new settings and values during the chef-client run on the node.

A role attribute can only be set to be a default attribute or an override attribute. A role attribute cannot be set to be a normal attribute. Use the ``default_attribute`` and ``override_attribute`` methods in the Ruby DSL file or the ``default_attributes`` and ``override_attributes`` hashes in a JSON data file.

.. end_tag

.. note:: .. tag notes_see_attributes_overview

          Attributes can be configured in cookbooks (attribute files and recipes), roles, and environments. In addition, Ohai collects attribute data about each node at the start of the chef-client run. See |url docs_attributes| for more information about how all of these attributes fit together.

          .. end_tag

Attribute Types
-----------------------------------------------------
There are two types of attributes that can be used with roles:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Attribute Type
     - Description
   * - ``default``
     - .. tag node_attribute_type_default

       A ``default`` attribute is automatically reset at the start of every chef-client run and has the lowest attribute precedence. Use ``default`` attributes as often as possible in cookbooks.

       .. end_tag

   * - ``override``
     - .. tag node_attribute_type_override

       An ``override`` attribute is automatically reset at the start of every chef-client run and has a higher attribute precedence than ``default``, ``force_default``, and ``normal`` attributes. An ``override`` attribute is most often specified in a recipe, but can be specified in an attribute file, for a role, and/or for an environment. A cookbook should be authored so that it uses ``override`` attributes only when required.

       .. end_tag

Attribute Persistence
-----------------------------------------------------
.. tag node_attribute_persistence

At the beginning of a chef-client run, all attributes are reset. The chef-client rebuilds them using automatic attributes collected by Ohai at the beginning of the chef-client run and then using default and override attributes that are specified in cookbooks or by roles and environments. Normal attributes are never reset. All attributes are then merged and applied to the node according to attribute precedence. At the conclusion of the chef-client run, the attributes that were applied to the node are saved to the Chef server as part of the node object.

.. end_tag

Attribute Precedence
-----------------------------------------------------
.. tag node_attribute_precedence

Attributes are always applied by the chef-client in the following order:

#. A ``default`` attribute located in a cookbook attribute file
#. A ``default`` attribute located in a recipe
#. A ``default`` attribute located in an environment
#. A ``default`` attribute located in a role
#. A ``force_default`` attribute located in a cookbook attribute file
#. A ``force_default`` attribute located in a recipe
#. A ``normal`` attribute located in a cookbook attribute file
#. A ``normal`` attribute located in a recipe
#. An ``override`` attribute located in a cookbook attribute file
#. An ``override`` attribute located in a recipe
#. An ``override`` attribute located in a role
#. An ``override`` attribute located in an environment
#. A ``force_override`` attribute located in a cookbook attribute file
#. A ``force_override`` attribute located in a recipe
#. An ``automatic`` attribute identified by Ohai at the start of the chef-client run

where the last attribute in the list is the one that is applied to the node.

.. note:: The attribute precedence order for roles and environments is reversed for ``default`` and ``override`` attributes. The precedence order for ``default`` attributes is environment, then role. The precedence order for ``override`` attributes is role, then environment. Applying environment ``override`` attributes after role ``override`` attributes allows the same role to be used across multiple environments, yet ensuring that values can be set that are specific to each environment (when required). For example, the role for an application server may exist in all environments, yet one environment may use a database server that is different from other environments.

Attribute precedence, viewed from the same perspective as the overview diagram, where the numbers in the diagram match the order of attribute precedence:

.. image:: ../../images/overview_chef_attributes_precedence.png

Attribute precedence, when viewed as a table:

.. image:: ../../images/overview_chef_attributes_table.png

.. end_tag

Changed in Chef Client 12.0, so that attributes may be modified for named precedence levels, all precedence levels, and be fully assigned.

Blacklist Attributes
-----------------------------------------------------
.. tag node_attribute_blacklist

.. warning:: When attribute blacklist settings are used, any attribute defined in a blacklist will not be saved and any attribute that is not defined in a blacklist will be saved. Each attribute type is blacklisted independently of the other attribute types. For example, if ``automatic_attribute_blacklist`` defines attributes that will not be saved, but ``normal_attribute_blacklist``, ``default_attribute_blacklist``, and ``override_attribute_blacklist`` are not defined, then all normal attributes, default attributes, and override attributes will be saved, as well as the automatic attributes that were not specifically excluded through blacklisting.

Attributes that should not be saved by a node may be blacklisted in the client.rb file. The blacklist is a Hash of keys that specify each attribute to be filtered out.

Attributes are blacklisted by attribute type, with each attribute type being blacklisted independently. Each attribute type---``automatic``, ``default``, ``normal``, and ``override``---may define blacklists by using the following settings in the client.rb file:

.. list-table::
   :widths: 200 300
   :header-rows: 1


   * - Setting
     - Description
   * - ``automatic_attribute_blacklist``
     - A hash that blacklists ``automatic`` attributes, preventing blacklisted attributes from being saved. For example: ``['network/interfaces/eth0']``. Default value: ``nil``, all attributes are saved. If the array is empty, all attributes are saved.
   * - ``default_attribute_blacklist``
     - A hash that blacklists ``default`` attributes, preventing blacklisted attributes from being saved. For example: ``['filesystem/dev/disk0s2/size']``. Default value: ``nil``, all attributes are saved. If the array is empty, all attributes are saved.
   * - ``normal_attribute_blacklist``
     - A hash that blacklists ``normal`` attributes, preventing blacklisted attributes from being saved. For example: ``['filesystem/dev/disk0s2/size']``. Default value: ``nil``, all attributes are saved. If the array is empty, all attributes are saved.
   * - ``override_attribute_blacklist``
     - A hash that blacklists ``override`` attributes, preventing blacklisted attributes from being saved. For example: ``['map - autohome/size']``. Default value: ``nil``, all attributes are saved. If the array is empty, all attributes are saved.

.. warning:: The recommended practice is to use only ``automatic_attribute_blacklist`` for blacklisting attributes. This is primarily because automatic attributes generate the most data, but also that normal, default, and override attributes are typically much more important attributes and are more likely to cause issues if they are blacklisted incorrectly.

For example, normal attribute data similar to:

.. code-block:: javascript

   {
     "filesystem" => {
       "/dev/disk0s2" => {
         "size" => "10mb"
       },
       "map - autohome" => {
         "size" => "10mb"
       }
     },
     "network" => {
       "interfaces" => {
         "eth0" => {...},
         "eth1" => {...},
       }
     }
   }

To blacklist the ``filesystem`` attributes and allow the other attributes to be saved, update the client.rb file:

.. code-block:: ruby

   normal_attribute_blacklist ['filesystem']

When a blacklist is defined, any attribute of that type that is not specified in that attribute blacklist **will** be saved. So based on the previous blacklist for normal attributes, the ``filesystem`` and ``map - autohome`` attributes will not be saved, but the ``network`` attributes will.

For attributes that contain slashes (``/``) within the attribute value, such as the ``filesystem`` attribute ``'/dev/diskos2'``, use an array. For example:

.. code-block:: ruby

   automatic_attribute_blacklist [['filesystem','/dev/diskos2']]

.. end_tag

Whitelist Attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag node_attribute_whitelist

.. warning:: When attribute whitelist settings are used, only the attributes defined in a whitelist will be saved and any attribute that is not defined in a whitelist will not be saved. Each attribute type is whitelisted independently of the other attribute types. For example, if ``automatic_attribute_whitelist`` defines attributes to be saved, but ``normal_attribute_whitelist``, ``default_attribute_whitelist``, and ``override_attribute_whitelist`` are not defined, then all normal attributes, default attributes, and override attributes are saved, as well as the automatic attributes that were specifically included through whitelisting.

Attributes that should be saved by a node may be whitelisted in the client.rb file. The whitelist is a hash of keys that specifies each attribute to be saved.

Attributes are whitelisted by attribute type, with each attribute type being whitelisted independently. Each attribute type---``automatic``, ``default``, ``normal``, and ``override``---may define whitelists by using the following settings in the client.rb file:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Setting
     - Description
   * - ``automatic_attribute_whitelist``
     - A hash that whitelists ``automatic`` attributes, preventing non-whitelisted attributes from being saved. For example: ``['network/interfaces/eth0']``. Default value: ``nil``, all attributes are saved. If the hash is empty, no attributes are saved.
   * - ``default_attribute_whitelist``
     - A hash that whitelists ``default`` attributes, preventing non-whitelisted attributes from being saved. For example: ``['filesystem/dev/disk0s2/size']``. Default value: ``nil``, all attributes are saved. If the hash is empty, no attributes are saved.
   * - ``normal_attribute_whitelist``
     - A hash that whitelists ``normal`` attributes, preventing non-whitelisted attributes from being saved. For example: ``['filesystem/dev/disk0s2/size']``. Default value: ``nil``, all attributes are saved. If the hash is empty, no attributes are saved.
   * - ``override_attribute_whitelist``
     - A hash that whitelists ``override`` attributes, preventing non-whitelisted attributes from being saved. For example: ``['map - autohome/size']``. Default value: ``nil``, all attributes are saved. If the hash is empty, no attributes are saved.

.. warning:: The recommended practice is to only use ``automatic_attribute_whitelist`` to whitelist attributes. This is primarily because automatic attributes generate the most data, but also that normal, default, and override attributes are typically much more important attributes and are more likely to cause issues if they are whitelisted incorrectly.

For example, normal attribute data similar to:

.. code-block:: javascript

   {
     "filesystem" => {
       "/dev/disk0s2" => {
         "size" => "10mb"
       },
       "map - autohome" => {
         "size" => "10mb"
       }
     },
     "network" => {
       "interfaces" => {
         "eth0" => {...},
         "eth1" => {...},
       }
     }
   }

To whitelist the ``network`` attributes and prevent the other attributes from being saved, update the client.rb file:

.. code-block:: ruby

   normal_attribute_whitelist ['network/interfaces/']

When a whitelist is defined, any attribute of that type that is not specified in that attribute whitelist **will not** be saved. So based on the previous whitelist for normal attributes, the ``filesystem`` and ``map - autohome`` attributes will not be saved, but the ``network`` attributes will.

Leave the value empty to prevent all attributes of that attribute type from being saved:

.. code-block:: ruby

   normal_attribute_whitelist []

For attributes that contain slashes (``/``) within the attribute value, such as the ``filesystem`` attribute ``'/dev/diskos2'``, use an array. For example:

.. code-block:: ruby

   automatic_attribute_whitelist [['filesystem','/dev/diskos2']]

.. end_tag

Role Formats
=====================================================
Role data is stored in two formats: as a Ruby file that contains domain-specific language and as JSON data.

Ruby DSL
-----------------------------------------------------
.. tag ruby_summary

Ruby is a simple programming language:

* Chef uses Ruby as its reference language to define the patterns that are found in resources, recipes, and cookbooks
* Use these patterns to configure, deploy, and manage nodes across the network

Ruby is also a powerful and complete programming language:

* Use the Ruby programming language to make decisions about what should happen to specific resources and recipes
* Extend Chef in any manner that your organization requires

.. end_tag

Domain-specific Ruby attributes:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Setting
     - Description
   * - ``default_attributes``
     - Optional. A set of attributes to be applied to all nodes, assuming the node does not already have a value for the attribute. This is useful for setting global defaults that can then be overridden for specific nodes. If more than one role attempts to set a default value for the same attribute, the last role applied is the role to set the attribute value. When nested attributes are present, they are preserved. For example, to specify that a node that has the attribute ``apache2`` should listen on ports 80 and 443 (unless ports are already specified):

       .. code-block:: ruby

          default_attributes 'apache2' => {
            'listen_ports' => [ '80', '443' ]
          }
   * - ``description``
     - A description of the functionality that is covered. For example:

       .. code-block:: ruby

          description 'The base role for systems that serve HTTP traffic'
   * - ``env_run_lists``
     - Optional. A list of environments, each specifying a recipe or a role to be applied to that environment. This setting must specify the ``_default`` environment. If the ``_default`` environment is set to ``[]`` or ``nil``, then the run-list is empty. For example:

       .. code-block:: ruby

          env_run_lists 'prod' => ['recipe[apache2]'],
                        'staging' => ['recipe[apache2::staging]'

       .. warning:: Using ``env_run_lists`` with roles is discouraged as it can be difficult to maintain over time. Instead, consider using multiple roles to define the required behavior.
   * - ``name``
     - A unique name within the organization. Each name must be made up of letters (upper- and lower-case), numbers, underscores, and hyphens: [A-Z][a-z][0-9] and [_-]. Spaces are not allowed. For example:

       .. code-block:: ruby

          name 'dev01-24'
   * - ``override_attributes``
     - Optional. A set of attributes to be applied to all nodes, even if the node already has a value for an attribute. This is useful for ensuring that certain attributes always have specific values. If more than one role attempts to set an override value for the same attribute, the last role applied wins. When nested attributes are present, they are preserved. For example:

       .. code-block:: ruby

          override_attributes 'apache2' => {
            'max_children' => '50'
          }

       The parameters in a Ruby file are Ruby method calls, so parentheses can be used to provide clarity when specifying numerous or deeply-nested attributes. For example:

       .. code-block:: ruby

          override_attributes(
            :apache2 => {
              :prefork => { :min_spareservers => '5' }
            }
          )

       Or:

       .. code-block:: ruby

          override_attributes(
            :apache2 => {
              :prefork => { :min_spareservers => '5' }
            },
            :tomcat => {
              :worker_threads => '100'
            }
          )
   * - ``run_list``
     - A list of recipes and/or roles to be applied and the order in which they are to be applied. For example, the following run-list:

       .. code-block:: ruby

          run_list 'recipe[apache2]',
                   'recipe[apache2::mod_ssl]',
                   'role[monitor]'

       would apply the ``apache2`` recipe first, then the ``apache2::mod_ssl`` recipe, and then the ``role[monitor]`` recipe.

A Ruby DSL file for each role must exist in the ``roles/`` subdirectory of the chef-repo. (If the repository does not have this subdirectory, then create it using knife.) Each Ruby file should have the .rb suffix. The complete roles Ruby DSL has the following syntax:

.. code-block:: javascript

   name "role_name"
   description "role_description"
   run_list "recipe[name]", "recipe[name::attribute]", "recipe[name::attribute]"
   env_run_lists "name" => ["recipe[name]"], "environment_name" => ["recipe[name::attribute]"]
   default_attributes "node" => { "attribute" => [ "value", "value", "etc." ] }
   override_attributes "node" => { "attribute" => [ "value", "value", "etc." ] }

where both default and override attributes are optional and at least one run-list (with at least one run-list item) is specified. For example, a role named ``webserver`` that has a run-list that defines actions for three different roles, and for certain roles takes extra steps (such as the ``apache2`` role listening on ports 80 and 443):

.. code-block:: javascript

   name "webserver"
   description "The base role for systems that serve HTTP traffic"
   run_list "recipe[apache2]", "recipe[apache2::mod_ssl]", "role[monitor]"
   env_run_lists "prod" => ["recipe[apache2]"], "staging" => ["recipe[apache2::staging]"], "_default" => []
   default_attributes "apache2" => { "listen_ports" => [ "80", "443" ] }
   override_attributes "apache2" => { "max_children" => "50" }

JSON
-----------------------------------------------------
The JSON format for roles maps directly to the domain-specific Ruby format: same settings, attributes, and values, and a similar structure and organization. For example:

.. code-block:: javascript

   {
     "name": "webserver",
     "chef_type": "role",
     "json_class": "Chef::Role",
     "default_attributes": {
       "apache2": {
         "listen_ports": [
           "80",
           "443"
         ]
       }
     },
     "description": "The base role for systems that serve HTTP traffic",
     "run_list": [
       "recipe[apache2]",
       "recipe[apache2::mod_ssl]",
       "role[monitor]"
     ],
     "env_run_lists" : {
       "production" : [],
       "preprod" : [],
       "dev": [
         "role[base]",
         "recipe[apache]",
         "recipe[apache::copy_dev_configs]",
       ],
       "test": [
         "role[base]",
         "recipe[apache]"
       ]
     },
     "override_attributes": {
       "apache2": {
         "max_children": "50"
       }
     }
   }

The JSON format has two additional settings:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Setting
     - Description
   * - ``chef_type``
     - Always set this to ``role``. Use this setting for any custom process that consumes role objects outside of Ruby.
   * - ``json_class``
     - Always set this to ``Chef::Role``. The chef-client uses this setting to auto-inflate a role object. If objects are being rebuilt outside of Ruby, ignore it.

Manage Roles
=====================================================
There are several ways to manage roles:

* knife can be used to create, edit, view, list, tag, and delete roles.
* The Chef management console add-on can be used to create, edit, view, list, tag, and delete roles. In addition, role attributes can be modified and roles can be moved between environments.
* The chef-client can be used to manage role data using the command line and JSON files (that contain a hash, the elements of which are added as role attributes). In addition, the ``run_list`` setting allows roles and/or recipes to be added to the role.
* The open source Chef server can be used to manage role data using the command line and JSON files (that contain a hash, the elements of which are added as role attributes). In addition, the ``run_list`` setting allows roles and/or recipes to be added to the role.
* The Chef server API can be used to create and manage roles directly, although using knife and/or the Chef management console is the most common way to manage roles.
* The command line can also be used with JSON files and third-party services, such as Amazon EC2, where the JSON files can contain per-instance metadata stored in a file on-disk and then read by chef-solo or chef-client as required.

By creating and editing files using the Ruby DSL or JSON, role data can be dynamically generated with the Ruby DSL. Roles created and edited using files are compatible with all versions of Chef, including chef-solo. Roles created and edited using files can be kept in version source control, which also keeps a history of what changed when. When roles are created and edited using files, they should not be managed using knife or the Chef management console, as changes will be overwritten.

A run-list that is associated with a role can be edited using the Chef management console add-on. The canonical source of a role's data is stored on the Chef server, which means that keeping role data in version source control can be challenging.

When files are uploaded to a Chef server from a file and then edited using the Chef management console, if the file is edited and uploaded again, the changes made using the Chef management console user interface will be lost. The same is true with knife, in that if roles are created and managed using knife and then arbitrarily updated uploaded JSON data, that action will overwrite what has been done previously using knife. It is strongly recommended to keep to one process and not switch back and forth.

Set Per-environment Run-lists
------------------------------------------------------
A per-environment run-list is a run-list that is associated with a role and a specific environment. More than one environment can be specified in a role, but each specific environment may be associated with only one run-list. If a run-list is not specified, the default run-list will be used. For example:

.. code-block:: javascript

   {
     "name": "webserver",
     "default_attributes": {
     },
     "json_class": "Chef::Role",
     "env_run_lists": {
       "production": [],
       "preprod": [],
       "test": [ "role[base]", "recipe[apache]", "recipe[apache::copy_test_configs]" ],
       "dev": [ "role[base]", "recipe[apache]", "recipe[apache::copy_dev_configs]" ]
       },
     "run_list": [ "role[base]", "recipe[apache]" ],
     "description": "The webserver role",
     "chef_type": "role",
     "override_attributes": {
     }
   }

where:

* ``webserver`` is the name of the role
* ``env_run_lists`` is a hash of per-environment run-lists for ``production``, ``preprod``, ``test``, and ``dev``
* ``production`` and ``preprod`` use the default run-list because they do not have a per-environment run-list
* ``run_list`` defines the default run-list

Delete from Run-list
-----------------------------------------------------
When an environment is deleted, it will remain within a run-list for a role until it is removed from that run-list. If a new environment is created that has an identical name to an environment that was deleted, a run-list that contains an old environment name will use the new one.
