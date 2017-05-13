=====================================================
About Attributes
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/attributes.rst>`__

.. tag node_attribute

An attribute is a specific detail about a node. Attributes are used by the chef-client to understand:

* The current state of the node
* What the state of the node was at the end of the previous chef-client run
* What the state of the node should be at the end of the current chef-client run

Attributes are defined by:

* The state of the node itself
* Cookbooks (in attribute files and/or recipes)
* Roles
* Environments

During every chef-client run, the chef-client builds the attribute list using:

* Data about the node collected by Ohai
* The node object that was saved to the Chef server at the end of the previous chef-client run
* The rebuilt node object from the current chef-client run, after it is updated for changes to cookbooks (attribute files and/or recipes), roles, and/or environments, and updated for any changes to the state of the node itself

After the node object is rebuilt, all of the attributes are compared, and then the node is updated based on attribute precedence. At the end of every chef-client run, the node object that defines the current state of the node is uploaded to the Chef server so that it can be indexed for search.

.. end_tag

So how does the chef-client determine which value should be applied? Keep reading to learn more about how attributes work, including more about the types of attributes, where attributes are saved, and how the chef-client chooses which attribute to apply.

Attribute Persistence
=====================================================
.. tag node_attribute_persistence

At the beginning of a chef-client run, all attributes are reset. The chef-client rebuilds them using automatic attributes collected by Ohai at the beginning of the chef-client run and then using default and override attributes that are specified in cookbooks or by roles and environments. Normal attributes are never reset. All attributes are then merged and applied to the node according to attribute precedence. At the conclusion of the chef-client run, the attributes that were applied to the node are saved to the Chef server as part of the node object.

.. end_tag

Attribute Types
=====================================================
.. tag node_attribute_type

The chef-client uses six types of attributes to determine the value that is applied to a node during the chef-client run. In addition, the chef-client sources attribute values from up to five locations. The combination of attribute types and sources allows for up to 15 different competing values to be available to the chef-client during the chef-client run:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Attribute Type
     - Description
   * - ``default``
     - .. tag node_attribute_type_default

       A ``default`` attribute is automatically reset at the start of every chef-client run and has the lowest attribute precedence. Use ``default`` attributes as often as possible in cookbooks.

       .. end_tag

   * - ``force_default``
     - Use the ``force_default`` attribute to ensure that an attribute defined in a cookbook (by an attribute file or by a recipe) takes precedence over a ``default`` attribute set by a role or an environment.
   * - ``normal``
     - .. tag node_attribute_type_normal

       A ``normal`` attribute is a setting that persists in the node object. A ``normal`` attribute has a higher attribute precedence than a ``default`` attribute.

       .. end_tag

   * - ``override``
     - .. tag node_attribute_type_override

       An ``override`` attribute is automatically reset at the start of every chef-client run and has a higher attribute precedence than ``default``, ``force_default``, and ``normal`` attributes. An ``override`` attribute is most often specified in a recipe, but can be specified in an attribute file, for a role, and/or for an environment. A cookbook should be authored so that it uses ``override`` attributes only when required.

       .. end_tag

   * - ``force_override``
     - Use the ``force_override`` attribute to ensure that an attribute defined in a cookbook (by an attribute file or by a recipe) takes precedence over an ``override`` attribute set by a role or an environment.
   * - ``automatic``
     - .. tag node_attribute_type_automatic

       An ``automatic`` attribute contains data that is identified by Ohai at the beginning of every chef-client run. An ``automatic`` attribute cannot be modified and always has the highest attribute precedence.

       .. end_tag

.. end_tag

Attribute Sources
=====================================================
Attributes are provided to the chef-client from the following locations:

* Nodes (collected by Ohai at the start of each chef-client run)
* Attribute files (in cookbooks)
* Recipes (in cookbooks)
* Environments
* Roles

Notes:

* Many attributes are maintained in the chef-repo for environments, roles, and cookbooks (attribute files and recipes)
* Many attributes are collected by Ohai on each individual node at the start of every chef-client run
* The attributes that are maintained in the chef-repo are uploaded to the Chef server from the workstation, periodically
* The chef-client will pull down the node object from the Chef server (which contains the attribute data from the previous chef-client run), after which all attributes (except ``normal`` are reset)
* The chef-client will update the cookbooks on the node (if required), which updates the attributes contained in attribute files and recipes
* The chef-client will update the role and environment data (if required)
* The chef-client will rebuild the attribute list and apply attribute precedence while configuring the node
* The chef-client pushes the node object to the Chef server at the end of the chef-client run; the updated node object on the Chef server is then indexed for search and is stored until the next chef-client run

Automatic (Ohai)
-----------------------------------------------------
.. tag ohai_automatic_attribute

An automatic attribute is a specific detail about a node, such as an IP address, a host name, a list of loaded kernel modules, and so on. Automatic attributes are detected by Ohai and are then used by the chef-client to ensure that they are handled properly during every chef-client run. The most commonly accessed automatic attributes are:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Attribute
     - Description
   * - ``node['platform']``
     - The platform on which a node is running. This attribute helps determine which providers will be used.
   * - ``node['platform_version']``
     - The version of the platform. This attribute helps determine which providers will be used.
   * - ``node['ipaddress']``
     - The IP address for a node. If the node has a default route, this is the IPV4 address for the interface. If the node does not have a default route, the value for this attribute should be ``nil``. The IP address for default route is the recommended default value.
   * - ``node['macaddress']``
     - The MAC address for a node, determined by the same interface that detects the ``node['ipaddress']``.
   * - ``node['fqdn']``
     - The fully qualified domain name for a node. This is used as the name of a node unless otherwise set.
   * - ``node['hostname']``
     - The host name for the node.
   * - ``node['domain']``
     - The domain for the node.
   * - ``node['recipes']``
     - A list of recipes associated with a node (and part of that node's run-list).
   * - ``node['roles']``
     - A list of roles associated with a node (and part of that node's run-list).
   * - ``node['ohai_time']``
     - The time at which Ohai was last run. This attribute is not commonly used in recipes, but it is saved to the Chef server and can be accessed using the ``knife status`` subcommand.

.. end_tag

.. tag ohai_attribute_list

The list of automatic attributes that are collected by Ohai at the start of each chef-client run vary from organization to organization, and will often vary between the various server types being configured and the platforms on which those servers are run. All attributes collected by Ohai are unmodifiable by the chef-client. To see which automatic attributes are collected by Ohai for a particular node, run the following command:

.. code-block:: bash

   ohai$ grep -R "provides" -h lib/ohai/plugins|sed 's/^\s*//g'|sed "s/\\\"/\'/g"|sort|uniq|grep ^provides

.. end_tag

Attribute Files
-----------------------------------------------------
An attribute file is located in the ``attributes/`` sub-directory for a cookbook. When a cookbook is run against a node, the attributes contained in all attribute files are evaluated in the context of the node object. Node methods (when present) are used to set attribute values on a node. For example, the ``apache2`` cookbook contains an attribute file called ``default.rb``, which contains the following attributes:

.. code-block:: ruby

   default['apache']['dir']          = '/etc/apache2'
   default['apache']['listen_ports'] = [ '80','443' ]

The use of the node object (``node``) is implicit in the previous example; the following example defines the node object itself as part of the attribute:

.. code-block:: ruby

   node.default['apache']['dir']          = '/etc/apache2'
   node.default['apache']['listen_ports'] = [ '80','443' ]

Attribute Evaluation Order
-----------------------------------------------------
.. tag node_attribute_evaluation_order

The chef-client evaluates attributes in the order defined by the run-list, including any attributes that are in the run-list because of cookbook dependencies.

.. end_tag

Use Attribute Files
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag node_attribute_when_to_use

An attribute is a specific detail about a node, such as an IP address, a host name, a list of loaded kernel modules, the version(s) of available programming languages that are available, and so on. An attribute may be unique to a specific node or it can be identical across every node in the organization. Attributes are most commonly set from a cookbook, by using knife, or are retrieved by Ohai from each node prior to every chef-client run. All attributes are indexed for search on the Chef server. Good candidates for attributes include:

* any cross-platform abstraction for an application, such as the path to a configuration file
* default values for tunable settings, such as the amount of memory assigned to a process or the number of workers to spawn
* anything that may need to be persisted in node data between chef-client runs

In general, attribute precedence is set to enable cookbooks and roles to define attribute defaults, for normal attributes to define the values that should be specific for a node, and for override attributes to force a certain value, even when a node already has that value specified.

One approach is to set attributes at the same precedence level by setting attributes in a cookbook's attribute files, and then also setting the same default attributes (but with different values) using a role. The attributes set in the role will be deep merged on top of the attributes from the attribute file, and the attributes set by the role will take precedence over the attributes specified in the cookbook's attribute files.

.. end_tag

.. tag node_attribute_when_to_use_unless_variants

Another (much less common) approach is to set a value only if an attribute has no value. This can be done by using the ``_unless`` variants of the attribute priority methods:

* ``default_unless``
* ``set_unless`` (``normal_unless`` is an alias of ``set_unless``; use either alias to set an attribute with a normal attribute precedence.)

    .. note:: This method was deprecated in Chef client 12.12 and will be removed in Chef 14. Please use ``default_unless`` or ``override_unless`` instead.

* ``override_unless``

.. note:: Use the ``_unless`` variants carefully (and only when necessary) because when they are used, attributes applied to nodes may become out of sync with the values in the cookbooks as these cookbooks are updated. This approach can create situations where two otherwise identical nodes end up having slightly different configurations and can also be a challenge to debug.

.. end_tag

.. note:: .. tag notes_see_attributes_overview

          Attributes can be configured in cookbooks (attribute files and recipes), roles, and environments. In addition, Ohai collects attribute data about each node at the start of the chef-client run. See |url docs_attributes| for more information about how all of these attributes fit together.

          .. end_tag

File Methods
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag cookbooks_attribute_file_methods

Use the following methods within the attributes file for a cookbook or within a recipe. These methods correspond to the attribute type of the same name:

* ``override``
* ``default``
* ``normal`` (or ``set``, where ``set`` is an alias for ``normal``)

    .. note: The ``set`` alias was deprecated in Chef client 12.12.

* ``_unless``
* ``attribute?``

.. end_tag

**attribute?**

A useful method that is related to attributes is the ``attribute?`` method. This method will check for the existence of an attribute, so that processing can be done in an attributes file or recipe, but only if a specific attribute exists.

Using ``attribute?()`` in an attributes file:

.. code-block:: ruby

   if attribute?('ec2')
     # ... set stuff related to EC2
   end

Using ``attribute?()`` in a recipe:

.. code-block:: ruby

   if node.attribute?('ec2')
     # ... do stuff on EC2 nodes
   end

Recipes
-----------------------------------------------------
.. tag cookbooks_recipe

A recipe is the most fundamental configuration element within the organization. A recipe:

* Is authored using Ruby, which is a programming language designed to read and behave in a predictable manner
* Is mostly a collection of resources, defined using patterns (resource names, attribute-value pairs, and actions); helper code is added around this using Ruby, when needed
* Must define everything that is required to configure part of a system
* Must be stored in a cookbook
* May be included in a recipe
* May use the results of a search query and read the contents of a data bag (including an encrypted data bag)
* May have a dependency on one (or more) recipes
* May tag a node to facilitate the creation of arbitrary groupings
* Must be added to a run-list before it can be used by the chef-client
* Is always executed in the same order as listed in a run-list

.. end_tag

.. tag cookbooks_attribute

An attribute can be defined in a cookbook (or a recipe) and then used to override the default settings on a node. When a cookbook is loaded during a chef-client run, these attributes are compared to the attributes that are already present on the node. Attributes that are defined in attribute files are first loaded according to cookbook order. For each cookbook, attributes in the ``default.rb`` file are loaded first, and then additional attribute files (if present) are loaded in lexical sort order. When the cookbook attributes take precedence over the default attributes, the chef-client will apply those new settings and values during the chef-client run on the node.

.. end_tag

Roles
-----------------------------------------------------
.. tag role

A role is a way to define certain patterns and processes that exist across nodes in an organization as belonging to a single job function. Each role consists of zero (or more) attributes and a run-list. Each node can have zero (or more) roles assigned to it. When a role is run against a node, the configuration details of that node are compared against the attributes of the role, and then the contents of that role's run-list are applied to the node's configuration details. When a chef-client runs, it merges its own attributes and run-lists with those contained within each assigned role.

.. end_tag

.. tag role_attribute

An attribute can be defined in a role and then used to override the default settings on a node. When a role is applied during a chef-client run, these attributes are compared to the attributes that are already present on the node. When the role attributes take precedence over the default attributes, the chef-client will apply those new settings and values during the chef-client run on the node.

A role attribute can only be set to be a default attribute or an override attribute. A role attribute cannot be set to be a normal attribute. Use the ``default_attribute`` and ``override_attribute`` methods in the Ruby DSL file or the ``default_attributes`` and ``override_attributes`` hashes in a JSON data file.

.. end_tag

Environments
-----------------------------------------------------
.. tag environment

An environment is a way to map an organization's real-life workflow to what can be configured and managed when using Chef server. Every organization begins with a single environment called the ``_default`` environment, which cannot be modified (or deleted). Additional environments can be created to reflect each organization's patterns and workflow. For example, creating ``production``, ``staging``, ``testing``, and ``development`` environments. Generally, an environment is also associated with one (or more) cookbook versions.

.. end_tag

.. tag environment_attribute

An attribute can be defined in an environment and then used to override the default settings on a node. When an environment is applied during a chef-client run, these attributes are compared to the attributes that are already present on the node. When the environment attributes take precedence over the default attributes, the chef-client will apply those new settings and values during the chef-client run on the node.

An environment attribute can only be set to be a default attribute or an override attribute. An environment attribute cannot be set to be a ``normal`` attribute. Use the ``default_attribute`` and ``override_attribute`` methods in the Ruby DSL file or the ``default_attributes`` and ``override_attributes`` hashes in a JSON data file.

.. end_tag

.. _attribute-precedence:

Attribute Precedence
=====================================================
Changed in Chef Client 12.0, so that attributes may be modified for named precedence levels, all precedence levels, and be fully assigned.

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


Blacklist Attributes
-----------------------------------------------------
New in Chef Client 13.0

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
-----------------------------------------------------
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

Examples
-----------------------------------------------------
The following examples are listed from low to high precedence.

**Default attribute in /attributes/default.rb**

.. code-block:: ruby

   default['apache']['dir'] = '/etc/apache2'

**Default attribute in node object in recipe**

.. code-block:: ruby

   node.default['apache']['dir'] = '/etc/apache2'

**Default attribute in /environments/environment_name.rb**

.. code-block:: ruby

   default_attributes({ 'apache' => {'dir' => '/etc/apache2'}})

**Default attribute in /roles/role_name.rb**

.. code-block:: ruby

   default_attributes({ 'apache' => {'dir' => '/etc/apache2'}})

**Normal attribute set as a cookbook attribute**

.. code-block:: ruby

   set['apache']['dir'] = '/etc/apache2'
   normal['apache']['dir'] = '/etc/apache2'  #set is an alias of normal.

**Normal attribute set in a recipe**

.. code-block:: ruby

   node.set['apache']['dir'] = '/etc/apache2'

   node.normal['apache']['dir'] = '/etc/apache2' # Same as above
   node['apache']['dir'] = '/etc/apache2'       # Same as above

**Override attribute in /attributes/default.rb**

.. code-block:: ruby

   override['apache']['dir'] = '/etc/apache2'

**Override attribute in /roles/role_name.rb**

.. code-block:: ruby

   override_attributes({ 'apache' => {'dir' => '/etc/apache2'}})

**Override attribute in /environments/environment_name.rb**

.. code-block:: ruby

   override_attributes({ 'apache' => {'dir' => '/etc/apache2'}})

**Override attribute in a node object (from a recipe)**

.. code-block:: ruby

   node.override['apache']['dir'] = '/etc/apache2'

**Ensure that a default attribute has precedence over other attributes**

When a default attribute is set like this:

.. code-block:: ruby

   default['attribute'] = 'value'

any value set by a role or an environment will replace it. To prevent this value from being replaced, use the ``force_default`` attribute precedence:

.. code-block:: ruby

   force_default['attribute'] = 'I will crush you, role or environment attribute'

or:

.. code-block:: ruby

   default!['attribute'] = "The '!' means I win!"

**Ensure that an override attribute has precedence over other attributes**

When an override attribute is set like this:

.. code-block:: ruby

   override['attribute'] = 'value'

any value set by a role or an environment will replace it. To prevent this value from being replaced, use the ``force_override`` attribute precedence:

.. code-block:: ruby

   force_override['attribute'] = 'I will crush you, role or environment attribute'

or:

.. code-block:: ruby

   override!['attribute'] = "The '!' means I win!"

Change Attributes
=====================================================
.. tag node_attribute_change

Starting with chef-client 12.0, attribute precedence levels may be

* Removed for a specific, named attribute precedence level
* Removed for all attribute precedence levels
* Fully assigned attributes

.. end_tag

Remove Precedence Level
-----------------------------------------------------
.. tag node_attribute_change_remove_level

A specific attribute precedence level for default, normal, and override attributes may be removed by using one of the following syntax patterns.

For default attributes:

* ``node.rm_default('foo', 'bar')``

For normal attributes:

* ``node.rm_normal('foo', 'bar')``

For override attributes:

* ``node.rm_override('foo', 'bar')``

These patterns return the computed value of the key being deleted for the specified precedence level.

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag node_attribute_change_remove_level_examples

The following examples show how to remove a specific, named attribute precedence level.

**Delete a default value when only default values exist**

Given the following code structure under ``'foo'``:

.. code-block:: ruby

   node.default['foo'] = {
     'bar' => {
       'baz' => 52,
       'thing' => 'stuff',
     },
     'bat' => {
       'things' => [5, 6],
     },
   }

And some role attributes:

.. code-block:: ruby

   # Please don't ever do this in real code :)
   node.role_default['foo']['bar']['thing'] = 'otherstuff'

And a force attribute:

.. code-block:: ruby

   node.force_default['foo']['bar']['thing'] = 'allthestuff'

When the default attribute precedence ``node['foo']['bar']`` is removed:

.. code-block:: ruby

   node.rm_default('foo', 'bar') #=> {'baz' => 52, 'thing' => 'allthestuff'}

What is left under ``'foo'`` is only ``'bat'``:

.. code-block:: ruby

   node.attributes.combined_default['foo'] #=> {'bat' => { 'things' => [5,6] } }

**Delete default without touching higher precedence attributes**

Given the following code structure:

.. code-block:: ruby

   node.default['foo'] = {
     'bar' => {
       'baz' => 52,
       'thing' => 'stuff',
     },
     'bat' => {
       'things' => [5, 6],
     },
   }

And some role attributes:

.. code-block:: ruby

   # Please don't ever do this in real code :)
   node.role_default['foo']['bar']['thing'] = 'otherstuff'

And a force attribute:

.. code-block:: ruby

   node.force_default['foo']['bar']['thing'] = 'allthestuff'

And also some override attributes:

.. code-block:: ruby

   node.override['foo']['bar']['baz'] = 99

Same delete as before:

.. code-block:: ruby

   node.rm_default('foo', 'bar') #=> { 'baz' => 52, 'thing' => 'allthestuff' }

The other attribute precedence levels are unaffected:

.. code-block:: ruby

   node.attributes.combined_override['foo'] #=> { 'bar' => {'baz' => 99} }
   node['foo'] #=> { 'bar' => {'baz' => 99}, 'bat' => { 'things' => [5,6] }

**Delete override without touching lower precedence attributes**

Given the following code structure, which has an override attribute:

.. code-block:: ruby

   node.override['foo'] = {
     'bar' => {
       'baz' => 52,
       'thing' => 'stuff',
     },
     'bat' => {
       'things' => [5, 6],
     },
   }

with a single default value:

.. code-block:: ruby

   node.default['foo']['bar']['baz'] = 11

and a force at each attribute precedence:

.. code-block:: ruby

   node.force_default['foo']['bar']['baz'] = 55
   node.force_override['foo']['bar']['baz'] = 99

Delete the override:

.. code-block:: ruby

   node.rm_override('foo', 'bar') #=> { 'baz' => 99, 'thing' => 'stuff' }

The other attribute precedence levels are unaffected:

.. code-block:: ruby

   node.attributes.combined_default['foo'] #=> { 'bar' => {'baz' => 55} }

**Non-existent key deletes return nil**

.. code-block:: ruby

   node.rm_default("no", "such", "thing") #=> nil

.. end_tag

Remove All Levels
-----------------------------------------------------
.. tag node_attribute_change_remove_all

All attribute precedence levels may be removed by using the following syntax pattern:

* ``node.rm('foo', 'bar')``

.. note:: Using ``node['foo'].delete('bar')`` will throw an exception that points to the new API.

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag node_attribute_change_remove_all_examples

The following examples show how to remove all attribute precedence levels.

**Delete all attribute precedence levels**

Given the following code structure:

.. code-block:: ruby

   node.default['foo'] = {
     'bar' => {
       'baz' => 52,
       'thing' => 'stuff',
     },
     'bat' => {
       'things' => [5, 6],
     },
   }

With override attributes:

.. code-block:: ruby

   node.override['foo']['bar']['baz'] = 999

Removing the ``'bar'`` key returns the computed value:

.. code-block:: ruby

   node.rm('foo', 'bar') #=> {'baz' => 999, 'thing' => 'stuff'}

Looking at ``'foo'``, all that's left is the ``'bat'`` entry:

.. code-block:: ruby

   node['foo'] #=> {'bat' => { 'things' => [5,6] } }

**Non-existent key deletes return nil**

.. code-block:: ruby

   node.rm_default("no", "such", "thing") #=> nil

.. end_tag

Full Assignment
-----------------------------------------------------
.. tag node_attribute_change_full_assignment

Use ``!`` to clear out the key for the named attribute precedence level, and then complete the write by using one of the following syntax patterns:

* ``node.default!['foo']['bar'] = {...}``
* ``node.force_default!['foo']['bar'] = {...}``
* ``node.normal!['foo']['bar'] = {...}``
* ``node.override!['foo']['bar'] = {...}``
* ``node.force_override!['foo']['bar'] = {...}``

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag node_attribute_change_full_assignment_examples

The following examples show how to remove all attribute precedence levels.

**Just one component**

Given the following code structure:

.. code-block:: ruby

   node.default['foo']['bar'] = {'a' => 'b'}
   node.default!['foo']['bar'] = {'c' => 'd'}

The ``'!'`` caused the entire 'bar' key to be overwritten:
.. code-block:: ruby

   node['foo'] #=> {'bar' => {'c' => 'd'}

**Multiple components; one "after"**

Given the following code structure:

.. code-block:: ruby

   node.default['foo']['bar'] = {'a' => 'b'}
   # Please don't ever do this in real code :)
   node.role_default['foo']['bar'] = {'c' => 'd'}
   node.default!['foo']['bar'] = {'d' => 'e'}

The ``'!'`` write overwrote the "cookbook-default" value of ``'bar'``, but since role data is later in the resolution list, it was unaffected:

.. code-block:: ruby

   node['foo'] #=> {'bar' => {'c' => 'd', 'd' => 'e'}

**Multiple components; all "before"**

Given the following code structure:

.. code-block:: ruby

   node.default['foo']['bar'] = {'a' => 'b'}
   # Please don't ever do this in real code :)
   node.role_default['foo']['bar'] = {'c' => 'd'}
   node.force_default!['foo']['bar'] = {'d' => 'e'}

With ``force_default!`` there is no other data under ``'bar'``:

.. code-block:: ruby

   node['foo'] #=> {'bar' => {'d' => 'e'}

**Multiple precedence levels**

Given the following code structure:

.. code-block:: ruby

   node.default['foo'] = {
     'bar' => {
       'baz' => 52,
       'thing' => 'stuff',
     },
     'bat' => {
      'things' => [5, 6],
     },
   }

And some attributes:

.. code-block:: ruby

   # Please don't ever do this in real code :)
   node.role_default['foo']['bar']['baz'] = 55
   node.force_default['foo']['bar']['baz'] = 66

And other precedence levels:

.. code-block:: ruby

   node.normal['foo']['bar']['baz'] = 88
   node.override['foo']['bar']['baz'] = 99

With a full assignment:

.. code-block:: ruby

   node.default!['foo']['bar'] = {}

Role default and force default are left in default, plus other precedence levels:

.. code-block:: ruby

   node.attributes.combined_default['foo'] #=> {'bar' => {'baz' => 66}, 'bat'=>{'things'=>[5, 6]}}
   node.attributes.normal['foo'] #=> {'bar' => {'baz' => 88}}
   node.attributes.combined_override['foo'] #=> {'bar' => {'baz' => 99}}
   node['foo']['bar'] #=> {'baz' => 99}

If ``force_default!`` is written:

.. code-block:: ruby

   node.force_default!['foo']['bar'] = {}

the difference is:

.. code-block:: ruby

   node.attributes.combined_default['foo'] #=> {'bat'=>{'things'=>[5, 6]}, 'bar' => {}}
   node.attributes.normal['foo'] #=> {'bar' => {'baz' => 88}}
   node.attributes.combined_override['foo'] #=> {'bar' => {'baz' => 99}}
   node['foo']['bar'] #=> {'baz' => 99}

.. end_tag

About Deep Merge
=====================================================
Attributes are typically defined in cookbooks, recipes, roles, and environments. These attributes are rolled-up to the node level during a chef-client run. A recipe can store attribute values using a multi-level hash or array.

For example, a group of attributes for web servers might be:

.. code-block:: ruby

   override_attributes(
     :apache => {
       :listen_ports => [ 80 ],
       :prefork => {
         :startservers => 20,
         :minspareservers => 20,
         :maxspareservers => 40
       }
     }
   )

But what if all of the web servers are not the same? What if some of the web servers required a single attribute to have a different value? You could store these settings in two locations, once just like the preceding example and once just like the following:

.. code-block:: ruby

   override_attributes(
     :apache => {
       :listen_ports => [ 80 ],
       :prefork => {
         :startservers => 30,
         :minspareservers => 20,
         :maxspareservers => 40
       }
     }
   )

But that is not very efficient, especially because most of them are identical. The deep merge capabilities of the chef-client allows attributes to be layered across cookbooks, recipes, roles, and environments. This allows an attribute to be reused across nodes, making use of default attributes set at the cookbook level, but also providing a way for certain attributes (with a higher attribute precedence) to be applied only when they are supposed to be.

For example, a role named ``baseline.rb``:

.. code-block:: ruby

   name "baseline"
   description "The most basic role for all configurations"
   run_list "recipe[baseline]"

   override_attributes(
     :apache => {
       :listen_ports => [ 80 ],
       :prefork => {
         :startservers => 20,
         :minspareservers => 20,
         :maxspareservers => 40
       }
     }
   )

and then a role named ``web.rb``:

.. code-block:: ruby

   name 'web'
   description 'Web server config'
   run_list 'role[baseline]'

   override_attributes(
     :apache => {
       :prefork => {
         :startservers => 30
       }
     }
   )

Both of these files are similar because they share the same structure. When an attribute value is a hash, that data is merged. When an attribute value is an array, if the attribute precedence levels are the same, then that data is merged.  If the attribute value precedence levels in an array are different, then that data is replaced.  For all other value types (such as strings, integers, etc.), that data is replaced.

For example, the ``web.rb`` references the ``baseline.rb`` role. The ``web.rb`` file only provides a value for one attribute: ``:startservers``. When the chef-client compares these attributes, the deep merge feature will ensure that ``:startservers`` (and its value of ``30``) will be applied to any node for which the ``web.rb`` attribute structure should be applied.

This approach will allow a recipe like this:

.. code-block:: ruby

   include_recipe 'apache2'
   Chef::Log.info(node['apache']['prefork'].to_hash)

and a ``run_list`` like this:

.. code-block:: ruby

   run_list/web.json
   {
     "run_list": [ "role[web]" ]
   }

to produce results like this:

.. code-block:: ruby

   [Tue, 16 Aug 2011 14:44:26 -0700] INFO:
            {
              "startservers"=>30,
              "minspareservers"=>20,
              "maxspareservers"=>40,
              "serverlimit"=>400,
              "maxclients"=>400,
              "maxrequestsperchild"=>10000
            }

Even though the ``web.rb`` file does not contain attributes and values for ``minspareservers``, ``maxspareservers``, ``serverlimit``, ``maxclients``, and ``maxrequestsperchild``, the deep merge capabilities pulled them in.

The following sections show how the logic works for using deep merge to perform substitutions and additions of attributes.

Substitution
-----------------------------------------------------
The following examples show how the logic works for substituting an existing string using a hash::

   role_or_environment 1 { :x => '1', :y => '2' }
   +
   role_or_environment 2 { :y => '3' }
   =
   { :x => '1', :y => '3' }

For substituting an existing boolean using a hash::

   role_or_environment 1 { :x => true, :y => false }
   +
   role_or_environment 2 { :y => true }
   =
   { :x => true, :y => true }

For substituting an array with a hash::

   role_or_environment 1 [ '1', '2', '3' ]
   +
   role_or_environment 2 { :x => '1' , :y => '2' }
   =
   { :x => '1', :y => '2' }

When items cannot be merged through substitution, the original data is overwritten.

Addition
-----------------------------------------------------
The following examples show how the logic works for adding a string using a hash::

   role_or_environment 1 { :x => '1', :y => '2' }
   +
   role_or_environment 2 { :z => '3' }
   =
   { :x => '1', :y => '2', :z => '3' }

For adding a string using an array::

   role_or_environment 1 [ '1', '2' ]
   +
   role_or_environment 2 [ '3' ]
   =
   [ '1', '2', '3' ]

For adding a string using a multi-level hash::

   role_or_environment 1 { :x => { :y => '2' } }
   +
   role_or_environment 2 { :x => { :z => '3' } }
   =
   { :x => { :y => '2', :z => '3' } }

For adding a string using a multi-level array::

   role_or_environment 1 [ [ 1, 2 ] ]
   +
   role_or_environment 2 [ [ 3 ] ]
   =
   [ [ 1, 2 ], [ 3 ] ]
