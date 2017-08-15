=====================================================
About Search
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/chef_search.rst>`__

.. tag search

Search indexes allow queries to be made for any type of data that is indexed by the Chef server, including data bags (and data bag items), environments, nodes, and roles. A defined query syntax is used to support search patterns like exact, wildcard, range, and fuzzy. A search is a full-text query that can be done from several locations, including from within a recipe, by using the ``search`` subcommand in knife, the ``search`` method in the Recipe DSL, the search box in the Chef management console, and by using the ``/search`` or ``/search/INDEX`` endpoints in the Chef server API. The search engine is based on Apache Solr and is run from the Chef server.

.. end_tag

Many of the examples in this section use knife, but the search indexes and search query syntax can be used in many locations, including from within recipes and when using the Chef server API.

Search Indexes
=====================================================
A search index is a full-text list of objects that are stored on the Chef server, against which search queries can be made. The following search indexes are built:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Search Index Name
     - Description
   * - ``client``
     - API client
   * - ``DATA_BAG_NAME``
     - A data bag is a global variable that is stored as JSON data and is accessible from a Chef server. The name of the search index is the name of the data bag. For example, if the name of the data bag was "admins" then a corresponding search query might look something like ``search(:admins, "*:*")``.
   * - ``environment``
     - An environment is a way to map an organization's real-life workflow to what can be configured and managed when using Chef server.
   * - ``node``
     - A node is any server or virtual server that is configured to be maintained by a chef-client.
   * - ``role``
     - A role is a way to define certain patterns and processes that exist across nodes in an organization as belonging to a single job function.

Using Knife
-----------------------------------------------------
.. tag knife_search_summary

Use the ``knife search`` subcommand to run a search query for information that is indexed on a Chef server.

.. end_tag

**Search by platform ID**

.. tag knife_search_by_platform_ids

To search for the IDs of all nodes running on the Amazon EC2 platform, enter:

.. code-block:: bash

   $ knife search node 'ec2:*' -i

to return something like:

.. code-block:: bash

   4 items found

   ip-0A7CA19F.ec2.internal

   ip-0A58CF8E.ec2.internal

   ip-0A58E134.ec2.internal

   ip-0A7CFFD5.ec2.internal

.. end_tag

**Search by instance type**

.. tag knife_search_by_platform_instance_type

To search for the instance type (flavor) of all nodes running on the Amazon EC2 platform, enter:

.. code-block:: bash

   $ knife search node 'ec2:*' -a ec2.instance_type

to return something like:

.. code-block:: bash

   4 items found

   ec2.instance_type:  m1.large
   id:                 ip-0A7CA19F.ec2.internal

   ec2.instance_type:  m1.large
   id:                 ip-0A58CF8E.ec2.internal

   ec2.instance_type:  m1.large
   id:                 ip-0A58E134.ec2.internal

   ec2.instance_type:  m1.large
   id:                 ip-0A7CFFD5.ec2.internal

.. end_tag

**Search by recipe**

.. tag knife_search_by_recipe

To search for recipes that are used by a node, use the ``recipes`` attribute to search for the recipe names, enter something like:

.. code-block:: bash

   $ knife search node 'recipes:recipe_name'

or:

.. code-block:: bash

   $ knife search node '*:*' -a recipes | grep 'recipe_name'

.. end_tag

**Search by cookbook, then recipe**

.. tag knife_search_by_cookbook

To search for cookbooks on a node, use the ``recipes`` attribute followed by the ``cookbook::recipe`` pattern, escaping both of the ``:`` characters. For example:

.. code-block:: bash

   $ knife search node 'recipes:cookbook_name\:\:recipe_name'

.. end_tag

**Search by node**

.. tag knife_search_by_node

To search for all nodes running Ubuntu, enter:

.. code-block:: bash

   $ knife search node 'platform:ubuntu'

.. end_tag

**Search by node and environment**

.. tag knife_search_by_node_and_environment

To search for all nodes running CentOS in the production environment, enter:

.. code-block:: bash

   $ knife search node 'chef_environment:production AND platform:centos'

.. end_tag

**Search for nested attributes**

.. tag knife_search_by_nested_attribute

To find a nested attribute, use a pattern similar to the following:

.. code-block:: bash

   $ knife search node <query_to_run> -a <main_attribute>.<nested_attribute>

.. end_tag

**Search for multiple attributes**

.. tag knife_search_by_query_for_many_attributes

To build a search query to use more than one attribute, use an underscore (``_``) to separate each attribute. For example, the following query will search for all nodes running a specific version of Ruby:

.. code-block:: bash

	$ knife search node "languages_ruby_version:1.9.3"

.. end_tag

**Search for nested attributes using a search query**

.. tag knife_search_by_query_for_nested_attribute

To build a search query that can find a nested attribute:

.. code-block:: bash

   $ knife search node name:<node_name> -a kernel.machine

.. end_tag

**Use a test query**

.. tag knife_search_test_query_for_ssh

To test a search query that will be used in a ``knife ssh`` subcommand:

.. code-block:: bash

   $ knife search node "role:web NOT name:web03"

where the query in the previous example will search all servers that have the ``web`` role, but not on the server named ``web03``.

.. end_tag

Query Syntax
=====================================================
.. tag search_query_syntax

A search query is comprised of two parts: the key and the search pattern. A search query has the following syntax:

.. code-block:: ruby

   key:search_pattern

where ``key`` is a field name that is found in the JSON description of an indexable object on the Chef server (a role, node, client, environment, or data bag) and ``search_pattern`` defines what will be searched for, using one of the following search patterns: exact, wildcard, range, or fuzzy matching. Both ``key`` and ``search_pattern`` are case-sensitive; ``key`` has limited support for multiple character wildcard matching using an asterisk ("*") (and as long as it is not the first character).

.. end_tag

.. note:: Search queries may not contain newlines.

Filter Search Results
=====================================================
.. tag dsl_recipe_method_search_filter_result

Use ``:filter_result`` as part of a search query to filter the search output based on the pattern specified by a Hash. Only attributes in the Hash will be returned.

.. note:: .. tag notes_filter_search_vs_partial_search

          Prior to chef-client 12.0, this functionality was available from the ``partial_search`` cookbook and was referred to as "partial search".

          .. end_tag

The syntax for the ``search`` method that uses ``:filter_result`` is as follows:

.. code-block:: ruby

   search(:index, 'query',
     :filter_result => { 'foo' => [ 'abc' ],
                         'bar' => [ '123' ],
                         'baz' => [ 'sea', 'power' ]
                       }
         ).each do |result|
     puts result['foo']
     puts result['bar']
     puts result['baz']
   end

where:

* ``:index`` is of name of the index on the Chef server against which the search query will run: ``:client``, ``:data_bag_name``, ``:environment``, ``:node``, and ``:role``
* ``'query'`` is a valid search query against an object on the Chef server
* ``:filter_result`` defines a Hash of values to be returned

For example:

.. code-block:: ruby

   search(:node, 'role:web',
     :filter_result => { 'name' => [ 'name' ],
                         'ip' => [ 'ipaddress' ],
                         'kernel_version' => [ 'kernel', 'version' ]
                       }
         ).each do |result|
     puts result['name']
     puts result['ip']
     puts result['kernel_version']
   end

.. end_tag

New in Chef Client 12.0.

Keys
=====================================================
.. tag search_key

A field name/description pair is available in the JSON object. Use the field name when searching for this information in the JSON object. Any field that exists in any JSON description for any role, node, chef-client, environment, or data bag can be searched.

.. end_tag

Nested Fields
-----------------------------------------------------
.. tag search_key_nested

A nested field appears deeper in the JSON data structure. For example, information about a network interface might be several layers deep: ``node[:network][:interfaces][:en1]``. When nested fields are present in a JSON structure, the chef-client will extract those nested fields to the top-level, flattening them into compound fields that support wildcard search patterns.

By combining wildcards with range-matching patterns and wildcard queries, it is possible to perform very powerful searches, such as using the vendor part of the MAC address to find every node that has a network card made by the specified vendor.

Consider the following snippet of JSON data:

.. code-block:: javascript

   {"network":
     [
     //snipped...
       "interfaces",
         {"en1": {
           "number": "1",
           "flags": [
             "UP",
             "BROADCAST",
             "SMART",
             "RUNNING",
             "SIMPLEX",
             "MULTICAST"
           ],
           "addresses": {
             "fe80::fa1e:dfff:fed8:63a2": {
               "scope": "Link",
               "prefixlen": "64",
               "family": "inet6"
             },
             "f8:1e:df:d8:63:a2": {
               "family": "lladdr"
             },
             "192.168.0.195": {
               "netmask": "255.255.255.0",
               "broadcast": "192.168.0.255",
               "family": "inet"
             }
           },
           "mtu": "1500",
           "media": {
             "supported": {
               "autoselect": {
                 "options": [

                 ]
               }
             },
             "selected": {
               "autoselect": {
                 "options": [

                 ]
               }
             }
           },
           "type": "en",
           "status": "active",
           "encapsulation": "Ethernet"
         },
     //snipped...

Before this data is indexed on the Chef server, the nested fields are extracted into the top level, similar to:

.. code-block:: none

   "broadcast" => "192.168.0.255",
   "flags"     => ["UP", "BROADCAST", "SMART", "RUNNING", "SIMPLEX", "MULTICAST"]
   "mtu"       => "1500"

which allows searches like the following to find data that is present in this node:

.. code-block:: ruby

   node "broadcast:192.168.0.*"

or:

.. code-block:: ruby

   node "mtu:1500"

or:

.. code-block:: ruby

   node "flags:UP"

This data is also flattened into various compound fields, which follow the same pattern as the JSON hierarchy and use underscores (``_``) to separate the levels of data, similar to:

.. code-block:: none

     # ...snip...
     "network_interfaces_en1_addresses_192.168.0.195_broadcast" => "192.168.0.255",
     "network_interfaces_en1_addresses_fe80::fa1e:tldr_family"  => "inet6",
     "network_interfaces_en1_addresses"                         => ["fe80::fa1e:tldr","f8:1e:df:tldr","192.168.0.195"]
     # ...snip...

which allows searches like the following to find data that is present in this node:

.. code-block:: ruby

   node "network_interfaces_en1_addresses:192.168.0.195"

This flattened data structure also supports using wildcard compound fields, which allow searches to omit levels within the JSON data structure that are not important to the search query. In the following example, an asterisk (``*``) is used to show where the wildcard can exist when searching for a nested field:

.. code-block:: ruby

   "network_interfaces_*_flags"     => ["UP", "BROADCAST", "SMART", "RUNNING", "SIMPLEX", "MULTICAST"]
   "network_interfaces_*_addresses" => ["fe80::fa1e:dfff:fed8:63a2", "192.168.0.195", "f8:1e:df:d8:63:a2"]
   "network_interfaces_en0_media_*" => ["autoselect", "none", "1000baseT", "10baseT/UTP", "100baseTX"]
   "network_interfaces_en1_*"       => ["1", "UP", "BROADCAST", "SMART", "RUNNING", "SIMPLEX", "MULTICAST",
                                        "fe80::fa1e:dfff:fed8:63a2", "f8:1e:df:d8:63:a2", "192.168.0.195",
                                        "1500", "supported", "selected", "en", "active", "Ethernet"]

For each of the wildcard examples above, the possible values are shown contained within the brackets. When running a search query, the query syntax for wildcards is to simply omit the name of the node (while preserving the underscores), similar to:

.. code-block:: ruby

   network_interfaces__flags

This query will search within the ``flags`` node, within the JSON structure, for each of ``UP``, ``BROADCAST``, ``SMART``, ``RUNNING``, ``SIMPLEX``, and ``MULTICAST``.

.. end_tag

Examples
-----------------------------------------------------
.. tag search_key_name

To see the available keys for a node, enter the following (for a node named ``staging``):

.. code-block:: bash

   $ knife node show staging -Fj | less

to return a full JSON description of the node and to view the available keys with which any search query can be based.

.. end_tag

.. tag search_key_wildcard_question_mark

To use a question mark (``?``) to replace a single character in a wildcard search, enter the following:

.. code-block:: bash

   $ knife search node 'platfor?:ubuntu'

.. end_tag

.. tag search_key_wildcard_asterisk

To use an asterisk (``*``) to replace zero (or more) characters in a wildcard search, enter the following:

.. code-block:: bash

   $ knife search node 'platfo*:ubuntu'

.. end_tag

.. tag search_key_nested_starting_with

To find all IP address that are on the same network, enter the following:

.. code-block:: bash

   $ knife search node 'network_interfaces__addresses:192.168*'

where ``192.168*`` is the network address for which the search will be run.

.. end_tag

.. tag search_key_nested_range

To use a range search to find IP addresses within a subnet, enter the following:

.. code-block:: bash

   $ knife search node 'network_interfaces_X_addresses:[192.168.0.* TO 192.168.127.*]'

where ``192.168.0.* TO 192.168.127.*`` defines the subnet range.

.. end_tag

Patterns
=====================================================
.. tag search_pattern

A search pattern is a way to fine-tune search results by returning anything that matches some type of incomplete search query. There are four types of search patterns that can be used when searching the search indexes on the Chef server: exact, wildcard, range, and fuzzy.

.. end_tag

Exact Matching
-----------------------------------------------------
.. tag search_pattern_exact

An exact matching search pattern is used to search for a key with a name that exactly matches a search query. If the name of the key contains spaces, quotes must be used in the search pattern to ensure the search query finds the key. The entire query must also be contained within quotes, so as to prevent it from being interpreted by Ruby or a command shell. The best way to ensure that quotes are used consistently is to quote the entire query using single quotes (' ') and a search pattern with double quotes (" ").

.. end_tag

.. tag search_pattern_exact_key_and_item

To search in a specific data bag for a specific data bag item, enter the following:

.. code-block:: bash

   $ knife search admins 'id:charlie'

where ``admins`` is the name of the data bag and ``charlie`` is the name of the data bag item. Something similar to the following will be returned:

.. code-block:: bash

   1 items found
   _rev:       1-39ff4099f2510f477b4c26bef81f75b9
   chef_type:  data_bag_item
   comment:    Charlie the Unicorn
   data_bag:   admins
   gid:        ops
   id:         charlie
   shell:      /bin/zsh
   uid:        1005

.. end_tag

.. tag search_pattern_exact_key_and_item_string

To search in a specific data bag using a string to find any matching data bag item, enter the following:

.. code-block:: bash

   $ knife search admins 'comment:"Charlie the Unicorn"'

where ``admins`` is the name of the data bag and ``Charlie the Unicorn`` is the string that will be used during the search. Something similar to the following will be returned:

.. code-block:: bash

   1 items found
   _rev:       1-39ff4099f2510f477b4c26bef81f75b9
   chef_type:  data_bag_item
   comment:    Charlie the Unicorn
   data_bag:   admins
   gid:        ops
   id:         charlie
   shell:      /bin/zsh
   uid:        1005

.. end_tag

Wildcard Matching
-----------------------------------------------------
.. tag search_pattern_wildcard

A wildcard matching search pattern is used to query for substring matches that replace zero (or more) characters in the search pattern with anything that could match the replaced character. There are two types of wildcard searches:

* A question mark (``?``) can be used to replace exactly one character (as long as that character is not the first character in the search pattern)
* An asterisk (``*``) can be used to replace any number of characters (including zero)

.. end_tag

.. tag search_pattern_wildcard_any_node

To search for any node that contains the specified key, enter the following:

.. code-block:: bash

   $ knife search node 'foo:*'

where ``foo`` is the name of the node.

.. end_tag

.. tag search_pattern_wildcard_node_contains

To search for a node using a partial name, enter one of the following:

.. code-block:: bash

   $ knife search node 'name:app*'

or:

.. code-block:: bash

   $ knife search node 'name:app1*.example.com'

or:

.. code-block:: bash

   $ knife search node 'name:app?.example.com'

or:

.. code-block:: bash

   $ knife search node 'name:app1.example.???'

to return ``app1.example.com`` (and any other node that matches any of the string searches above).

.. end_tag

Range Matching
-----------------------------------------------------
.. tag search_pattern_range

A range matching search pattern is used to query for values that are within a range defined by upper and lower boundaries. A range matching search pattern can be inclusive or exclusive of the boundaries. Use square brackets ("[ ]") to denote inclusive boundaries and curly braces ("{ }") to denote exclusive boundaries and with the following syntax:

.. code-block:: ruby

   boundary TO boundary

where ``TO`` is required (and must be capitalized).

.. end_tag

.. tag search_pattern_range_in_between

A data bag named ``sample`` contains four data bag items: ``abc``, ``bar``, ``baz``, and ``quz``. All of the items in-between ``bar`` and ``foo``, inclusive, can be searched for using an inclusive search pattern.

To search using an inclusive range, enter the following:

.. code-block:: bash

   $ knife search sample "id:[bar TO foo]"

where square brackets (``[ ]``) are used to define the range.

.. end_tag

.. tag search_pattern_range_exclusive

A data bag named ``sample`` contains four data bag items: ``abc``, ``bar``, ``baz``, and ``quz``. All of the items that are exclusive to ``bar`` and ``foo`` can be searched for using an exclusive search pattern.

To search using an exclusive range, enter the following:

.. code-block:: bash

   $ knife search sample "id:{bar TO foo}"

where curly braces (``{ }``) are used to define the range.

.. end_tag

Fuzzy Matching
-----------------------------------------------------
.. tag search_pattern_fuzzy

A fuzzy matching search pattern is used to search based on the proximity of two strings of characters. An (optional) integer may be used as part of the search query to more closely define the proximity. A fuzzy matching search pattern has the following syntax:

.. code-block:: ruby

   "search_query"~edit_distance

where ``search_query`` is the string that will be used during the search and ``edit_distance`` is the proximity. A tilde ("~") is used to separate the edit distance from the search query.

.. end_tag

.. tag search_pattern_fuzzy_summary

To use a fuzzy search pattern enter something similar to:

.. code-block:: bash

   $ knife search client "name:boo~"

where ``boo~`` defines the fuzzy search pattern. This will return something similar to:

.. code-block:: javascript

   {
     "total": 1,
     "start": 0,
     "rows": [
       {
         "public_key": "too long didn't read",
         "name": "foo",
         "_rev": "1-f11a58043906e33d39a686e9b58cd92f",
         "json_class": "Chef::ApiClient",
         "admin": false,
         "chef_type": "client"
       }
     ]
   }

.. end_tag

Operators
=====================================================
.. tag search_boolean_operators

An operator can be used to ensure that certain terms are included in the results, are excluded from the results, or are not included even when other aspects of the query match. Searches can use the following operators:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Operator
     - Description
   * - ``AND``
     - Use to find a match when both terms exist.
   * - ``OR``
     - Use to find a match if either term exists.
   * - ``NOT``
     - Use to exclude the term after ``NOT`` from the search results.

.. end_tag

.. tag search_boolean_operators_andnot

Operators must be in ALL CAPS. Parentheses can be used to group clauses and to form sub-queries.

.. warning:: Using ``AND NOT`` together may trigger an error. For example:

   .. code-block:: bash

      ERROR: knife search failed: invalid search query:
      'datacenter%3A123%20AND%20NOT%20hostname%3Adev-%20AND%20NOT%20hostanem%3Asyslog-'
      Parse error at offset: 38 Reason: Expected one of \ at line 1, column 42 (byte 42) after AND

   Use ``-`` instead of ``NOT``. For example:

   .. code-block:: bash

      $ knife search sample "id:foo AND -id:bar"

.. end_tag

AND
-----------------------------------------------------
.. tag search_boolean_and

To join queries using the ``AND`` boolean operator, enter the following:

.. code-block:: bash

   $ knife search sample "id:b* AND animal:dog"

to return something like:

.. code-block:: bash

   {
     "total": 1,
     "start": 0,
     "rows": [
       {
         "comment": "an item named baz",
         "id": "baz",
         "animal": "dog"
       }
     ]
   }

Or, to find all of the computers running on the Microsoft Windows platform that are associated with a role named ``jenkins``, enter:

.. code-block:: bash

   $ knife search node 'platform:windows AND roles:jenkins'

to return something like:

.. code-block:: bash

   2 items found

   Node Name:   windows-server-2008r2.domain.com
   Environment: _default
   FQDN:        windows-server-2008r2
   IP:          0000::0000:0000:0000:0000
   Run List:    role[jenkins-windows]
   Roles:       jenkins-windows, jenkins
   Recipes:     jenkins-client::windows, jenkins::node_windows
   Platform:    windows 6.1.7601
   Tags:

   Node Name:   123-windows-2008r2-amd64-builder
   Environment: _default
   FQDN:        ABC-1234567890AB
   IP:          123.45.6.78
   Run List:    role[123-windows-2008r2-amd64-builder]
   Roles:       123-windows-2008r2-amd64-builder, jenkins
   Recipes:     jenkins::node_windows, git_windows
   Platform:    windows 6.1.7601
   Tags:

.. end_tag

NOT
-----------------------------------------------------
.. tag search_boolean_not

To negate search results using the ``NOT`` boolean operator, enter the following:

.. code-block:: bash

   $ knife search sample "(NOT id:foo)"

to return something like:

.. code-block:: bash

   {
     "total": 4,
     "start": 0,
     "rows": [
       {
         "comment": "an item named bar",
         "id": "bar",
         "animal": "cat"
       },
       {
         "comment": "an item named baz",
         "id": "baz"
         "animal": "dog"
       },
       {
         "comment": "an item named abc",
         "id": "abc",
         "animal": "unicorn"
       },
       {
         "comment": "an item named qux",
         "id": "qux",
         "animal", "penguin"
       }
     ]
   }

.. end_tag

OR
-----------------------------------------------------
.. tag search_boolean_or

To join queries using the ``OR`` boolean operator, enter the following:

.. code-block:: bash

   $ knife search sample "id:foo OR id:abc"

to return something like:

.. code-block:: bash

   {
     "total": 2,
     "start": 0,
     "rows": [
       {
         "comment": "an item named foo",
         "id": "foo",
         "animal": "pony"
       },
       {
         "comment": "an item named abc",
         "id": "abc",
         "animal": "unicorn"
       }
     ]
   }

.. end_tag

Special Characters
=====================================================
.. tag search_special_characters

A special character can be used to fine-tune a search query and to increase the accuracy of the search results. The following characters can be included within the search query syntax, but each occurrence of a special character must be escaped with a backslash (``\``):

.. code-block:: ruby

   +  -  &&  | |  !  ( )  { }  [ ]  ^  "  ~  *  ?  :  \

For example:

.. code-block:: ruby

   \(1\+1\)\:2

.. end_tag

Targets
=====================================================
A search target is any object that has been indexed on the Chef server, including roles (and run-lists), nodes, environments, data bags, and any API client.

Roles in Run-lists
-----------------------------------------------------
A search query can be made for roles that are at the top-level of a run-list and also for a role that is part of an expanded run-list.

.. note:: The ``roles`` field is updated each time the chef-client is run; changes to a run-list will not affect ``roles`` until the next time the chef-client is run on the node.

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Role Location
     - Description
   * - Top-level
     - To find a node with a role in the top-level of its run-list, search within the ``role`` field (and escaping any special characters with the slash symbol) using the following syntax::

          role:ROLE_NAME

       where ``role`` (singlular!) indicates the top-level run-list.
   * - Expanded
     - To find a node with a role in an expanded run-list, search within the ``roles`` field (and escaping any special characters with the slash symbol) using the following syntax::

          roles:ROLE_NAME

       where ``roles`` (plural!) indicates the expanded run-list.

To search a top-level run-list for a role named ``load_balancer`` use the ``knife search`` subcommand from the command line or the ``search`` method in a recipe. For example:

.. code-block:: bash

   $ knife search node role:load_balancer

and from within a recipe:

.. code-block:: ruby

   search(:node, 'role:load_balancer')

To search an expanded run-list for all nodes with the role ``load_balancer`` use the ``knife search`` subcommand from the command line or the ``search`` method in a recipe. For example:

.. code-block:: bash

   $ knife search node roles:load_balancer

and from within a recipe:

.. code-block:: ruby

   search(:node, 'roles:load_balancer')

Nodes
-----------------------------------------------------
A node can be searched from a recipe by using the following syntax:

.. code-block:: ruby

   search(:node, "key:attribute")

A wildcard can be used to replace characters within the search query.

Expanded lists of roles (all of the roles that apply to a node, including nested roles) and recipes to the role and recipe attributes on a node are saved on the Chef server. The expanded lists of roles allows for searching within nodes that run a given recipe, even if that recipe is included by a role.

.. note:: The ``recipes`` field is updated each time the chef-client is run; changes to a run-list will not affect ``recipes`` until the next time the chef-client is run on the node.

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Node Location
     - Description
   * - In a specified recipe
     - To find a node with a specified recipe in the run-list, search within the ``run_list`` field (and escaping any special characters with the slash symbol) using the following syntax:

       .. code-block:: ruby

          search(:node, 'run_list:recipe\[foo\:\:bar\]')

       where ``recipe`` (singular!) indicates the top-level run-list. Variables can be interpolated into search strings using the Ruby alternate quoting syntax:

       .. code-block:: ruby

          search(:node, %Q{run_list:"recipe[#{the_recipe}]"} )

   * - In an expanded run-list
     - To find a node with a recipe in an expanded run-list, search within the ``recipes`` field (and escaping any special characters with the slash symbol) using the following syntax:

       .. code-block:: ruby

          recipes:RECIPE_NAME

       where ``recipes`` (plural!) indicates to search within an expanded run-list.

If you just want to use each result of the search and don't care about the aggregate result you can provide a code block to the search method. Each result is then passed to the block:

.. code-block:: ruby

   # Print every node matching the search pattern
   search(:node, "*:*").each do |matching_node|
     puts matching_node.to_s
   end

API Clients
-----------------------------------------------------
An API client is any machine that has permission to use the Chef server API to communicate with the Chef server. An API client is typically a node (on which the chef-client runs) or a workstation (on which knife runs), but can also be any other machine configured to use the Chef server API.

Sometimes when a role isn't fully defined (or implemented), it may be necessary for a machine to connect to a database, search engine, or some other service within an environment by using the settings located on another machine, such as a host name, IP address, or private IP address. The following example shows a simplified settings file:

.. code-block:: ruby

   username: "mysql"
   password: "MoveAlong"
   host:     "10.40.64.202"
   port:     "3306"

where ``host`` is the private IP address of the database server. Use the following knife query to view information about the node:

.. code-block:: bash

   knife search node "name:name_of_database_server" --long

To access these settings as part of a recipe that is run on the web server, use code similar to:

.. code-block:: ruby

   db_server = search(:node, "name:name_of_database_server")
   private_ip = "#{db_server[0][:rackspace][:private_ip]}"
   puts private_ip

where the "[0]" is the 0 (zero) index for the ``db_server`` identifier. A single document is returned because the node is being searched on its unique name. The identifier ``private_ip`` will now have the value of the private IP address of the database server (``10.40.64.202``) and can then be used in templates as a variable, among other possible uses.

Environments
-----------------------------------------------------
.. tag environment

An environment is a way to map an organization's real-life workflow to what can be configured and managed when using Chef server. Every organization begins with a single environment called the ``_default`` environment, which cannot be modified (or deleted). Additional environments can be created to reflect each organization's patterns and workflow. For example, creating ``production``, ``staging``, ``testing``, and ``development`` environments. Generally, an environment is also associated with one (or more) cookbook versions.

.. end_tag

.. tag search_environment

When searching, an environment is an attribute. This allows search results to be limited to a specified environment by using Boolean operators and extra search terms. For example, to use knife to search for all of the servers running CentOS in an environment named "QA", enter the following:

.. code-block:: bash

   knife search node "chef_environment:QA AND platform:centos"

Or, to include the same search in a recipe, use a code block similar to:

.. code-block:: ruby

   qa_nodes = search(:node,"chef_environment:QA")
   qa_nodes.each do |qa_node|
       # Do useful work specific to qa nodes only
   end

.. end_tag

Data Bags
-----------------------------------------------------
.. tag data_bag

A data bag is a global variable that is stored as JSON data and is accessible from a Chef server. A data bag is indexed for searching and can be loaded by a recipe or accessed during a search.

.. end_tag

.. tag search_data_bag

Any search for a data bag (or a data bag item) must specify the name of the data bag and then provide the search query string that will be used during the search. For example, to use knife to search within a data bag named "admin_data" across all items, except for the "admin_users" item, enter the following:

.. code-block:: bash

   $ knife search admin_data "(NOT id:admin_users)"

Or, to include the same search query in a recipe, use a code block similar to:

.. code-block:: ruby

   search(:admin_data, "NOT id:admin_users")

It may not be possible to know which data bag items will be needed. It may be necessary to load everything in a data bag (but not know what "everything" is). Using a search query is the ideal way to deal with that ambiguity, yet still ensure that all of the required data is returned. The following examples show how a recipe can use a series of search queries to search within a data bag named "admins". For example, to find every administrator:

.. code-block:: ruby

   search(:admins, "*:*")

Or to search for an administrator named "charlie":

.. code-block:: ruby

   search(:admins, "id:charlie")

Or to search for an administrator with a group identifier of "ops":

.. code-block:: ruby

   search(:admins, "gid:ops")

Or to search for an administrator whose name begins with the letter "c":

.. code-block:: ruby

   search(:admins, "id:c*")

Data bag items that are returned by a search query can be used as if they were a hash. For example:

.. code-block:: ruby

   charlie = search(:admins, "id:charlie").first
   # => variable 'charlie' is set to the charlie data bag item
   charlie["gid"]
   # => "ops"
   charlie["shell"]
   # => "/bin/zsh"

The following recipe can be used to create a user for each administrator by loading all of the items from the "admins" data bag, looping through each admin in the data bag, and then creating a user resource so that each of those admins exist:

.. code-block:: ruby

   admins = data_bag('admins')

   admins.each do |login|
     admin = data_bag_item('admins', login)
     home = "/home/#{login}"

     user(login) do
       uid       admin['uid']
       gid       admin['gid']
       shell     admin['shell']
       comment   admin['comment']
       home      home
       manage_home true
     end

   end

And then the same recipe, modified to load administrators using a search query (and using an array to store the results of the search query):

.. code-block:: ruby

   admins = []

   search(:admins, "*:*").each do |admin|
     login = admin["id"]

     admins << login

     home = "/home/#{login}"

     user(login) do
       uid       admin['uid']
       gid       admin['gid']
       shell     admin['shell']
       comment   admin['comment']

       home      home
       manage_home true
     end

   end

.. end_tag
