=====================================================
Debug Recipes, chef-client Runs
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/debug.rst>`__

Elements of good approaches to building cookbooks and recipes that are reliable include:

* A consistent syntax pattern when constructing recipes
* Using the same patterns in Ruby
* Using platform resources before creating custom ones
* Using community-authored lightweight resources before creating custom ones

Ideally, the best way to debug a recipe is to not have to debug it in the first place. That said, the following sections discuss various approaches to debugging recipes and failed chef-client runs.

Basic
=====================================================
Some simple ways to quickly identify common issues that can trigger recipe and/or chef-client run failures include:

* Using an empty run-list
* Using verbose logging with knife
* Using logging with the chef-client
* Using the **log** resource in a recipe to define custom logging

Empty Run-lists
-----------------------------------------------------
.. tag node_run_list_empty

Use an empty run-list to determine if a failed chef-client run has anything to do with the recipes that are defined within that run-list. This is a quick way to discover if the underlying cause of a chef-client run failure is a configuration issue. If a failure persists even if the run-list is empty, check the following:

* Configuration settings in the knife.rb file
* Permissions for the user to both the Chef server and to the node on which the chef-client run is to take place

.. end_tag

Knife
-----------------------------------------------------
Use the verbose logging that is built into knife:

``-V``, ``--verbose``
  Set for more verbose outputs. Use ``-VV`` for maximum verbosity.

.. note:: Plugins do not always support verbose logging.

chef-client
-----------------------------------------------------
Use the verbose logging that is built into the chef-client:

``-l LEVEL``, ``--log_level LEVEL``
   The level of logging to be stored in a log file.

``-L LOGLOCATION``, ``--logfile c``
   The location of the log file. This is recommended when starting any executable as a daemon. Default value: ``STDOUT``.

log Resource
-----------------------------------------------------
.. tag resource_log_summary

Use the **log** resource to create log entries. The **log** resource behaves like any other resource: built into the resource collection during the compile phase, and then run during the execution phase. (To create a log entry that is not built into the resource collection, use ``Chef::Log`` instead of the **log** resource.)

.. note:: By default, every log resource that executes will count as an updated resource in the updated resource count at the end of a Chef run. You can disable this behavior by adding ``count_log_resource_updates false`` to your Chef ``client.rb`` configuration file.

.. end_tag

New in 12.0, ``-o RUN_LIST_ITEM``. Changed in 12.0 ``-f`` no longer allows unforked intervals, ``-i SECONDS`` is applied before the chef-client run.

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_log_syntax

A **log** resource block adds messages to the log file based on events that occur during the chef-client run:

.. code-block:: ruby

   log 'message' do
     message 'A message add to the log.'
     level :info
   end

The full syntax for all of the properties that are available to the **log** resource is:

.. code-block:: ruby

   log 'name' do
     level                      Symbol
     message                    String # defaults to 'name' if not specified
     notifies                   # see description
     provider                   Chef::Provider::ChefLog
     subscribes                 # see description
     action                     Symbol # defaults to :write if not specified
   end

where

* ``log`` is the resource
* ``name`` is the name of the resource block
* ``message`` is the log message to write
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``level``, ``message``, and ``provider`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_log_actions

This resource has the following actions:

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:write``
   Default. Write to log.

.. end_tag

Attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_log_attributes

This resource has the following properties:

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``level``
   **Ruby Type:** Symbol

   The level of logging that is to be displayed by the chef-client. The chef-client uses the ``mixlib-log`` (https://github.com/chef/mixlib-log) to handle logging behavior. Options (in order of priority): ``:debug``, ``:info``, ``:warn``, ``:error``, and ``:fatal``. Default value: ``:info``.

``message``
   **Ruby Type:** String

   The message to be added to a log file. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_notifies_syntax

   The syntax for ``notifies`` is:

   .. code-block:: ruby

      notifies :action, 'resource[name]', :timer

   .. end_tag

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_subscribes_syntax

   The syntax for ``subscribes`` is:

   .. code-block:: ruby

      subscribes :action, 'resource[name]', :timer

   .. end_tag

.. end_tag

Providers
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This resource has the following providers:

``Chef::Provider::Log::ChefLog``, ``log``
   The default provider for all platforms.

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Specify a log entry**

.. tag resource_log_set_info

.. To set the info (default) logging level:

.. code-block:: ruby

   log 'a string to log'

.. end_tag

**Set debug logging level**

.. tag resource_log_set_debug

.. To set the debug logging level:

.. code-block:: ruby

   log 'a debug string' do
     level :debug
   end

.. end_tag

**Create log entry when the contents of a data bag are used**

.. tag resource_log_set_debug

.. To set the debug logging level:

.. code-block:: ruby

   log 'a debug string' do
     level :debug
   end

.. end_tag

**Add a message to a log file**

.. tag resource_log_add_message

.. To add a message to a log file:

.. code-block:: ruby

   log 'message' do
     message 'This is the message that will be added to the log.'
     level :info
   end

.. end_tag

Advanced
=====================================================
Some more complex ways to debug issues with a chef-client run include:

* Using the **chef_handler** cookbook
* Using the chef-shell and the **breakpoint** resource to add breakpoints to recipes, and to then step through the recipes using the breakpoints
* Using the ``debug_value`` method from chef-shell to indentify the location(s) from which attribute values are being set
* Using the ``ignore_failure`` method in a recipe to force the chef-client to move past an error to see what else is going on in the recipe, outside of a known failure
* Using chef-solo to run targeted chef-client runs for specific scenarios

chef_handler
-----------------------------------------------------
.. tag handler

Use a handler to identify situations that arise during a chef-client run, and then tell the chef-client how to handle these situations when they occur.

.. end_tag

.. tag handler_types

There are three types of handlers:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Handler
     - Description
   * - exception
     - An exception handler is used to identify situations that have caused a chef-client run to fail. An exception handler can be loaded at the start of a chef-client run by adding a recipe that contains the **chef_handler** resource to a node's run-list. An exception handler runs when the ``failed?`` property for the ``run_status`` object returns ``true``.
   * - report
     - A report handler is used when a chef-client run succeeds and reports back on certain details about that chef-client run. A report handler can be loaded at the start of a chef-client run by adding a recipe that contains the **chef_handler** resource to a node's run-list. A report handler runs when the ``success?`` property for the ``run_status`` object returns ``true``.
   * - start
     - A start handler is used to run events at the beginning of the chef-client run. A start handler can be loaded at the start of a chef-client run by adding the start handler to the ``start_handlers`` setting in the client.rb file or by installing the gem that contains the start handler by using the **chef_gem** resource in a recipe in the **chef-client** cookbook. (A start handler may not be loaded using the ``chef_handler`` resource.)

.. end_tag

Read more :doc:`about exception, report, and start handlers </handlers>`.

chef-shell
-----------------------------------------------------
.. tag chef_shell_summary

chef-shell is a recipe debugging tool that allows the use of breakpoints within recipes. chef-shell runs as an Interactive Ruby (IRb) session. chef-shell supports both recipe and attribute file syntax, as well as interactive debugging features.

.. end_tag

.. tag chef_shell_modes

chef-shell is tool that is run using an Interactive Ruby (IRb) session. chef-shell currently supports recipe and attribute file syntax, as well as interactive debugging features. chef-shell has three run modes:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Mode
     - Description
   * - Standalone
     - Default. No cookbooks are loaded, and the run-list is empty.
   * - Solo
     - chef-shell acts as a chef-solo client. It attempts to load the chef-solo configuration file and JSON attributes. If the JSON attributes set a run-list, it will be honored. Cookbooks will be loaded in the same way that chef-solo loads them. chef-solo mode is activated with the ``-s`` or ``--solo`` command line option, and JSON attributes are specified in the same way as for chef-solo, with ``-j /path/to/chef-solo.json``.
   * - Client
     - chef-shell acts as a chef-client. During startup, it reads the chef-client configuration file and contacts the Chef server to get attributes and cookbooks. The run-list will be set in the same way as normal chef-client runs. chef-client mode is activated with the ``-z`` or ``--client`` options. You can also specify the configuration file with ``-c CONFIG`` and the server URL with ``-S SERVER_URL``.

.. end_tag

Configure
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag chef_shell_config

chef-shell determines which configuration file to load based on the following:

#. If a configuration file is specified using the ``-c`` option, chef-shell will use the specified configuration file
#. When chef-shell is started using a named configuration as an argument, chef-shell will search for a chef-shell.rb file in that directory under ``~/.chef``. For example, if chef-shell is started using ``production`` as the named configuration, the chef-shell will load a configuration file from ``~/.chef/production/chef_shell.rb``
#. If a named configuration is not provided, chef-shell will attempt to load the chef-shell.rb file from the ``.chef`` directory. For example: ``~/.chef/chef_shell.rb``
#. If a chef-shell.rb file is not found, chef-shell will attempt to load the client.rb file
#. If a chef-shell.rb file is not found, chef-shell will attempt to load the solo.rb file

.. end_tag

chef-shell.rb
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag chef_shell_config_rb

The chef-shell.rb file can be used to configure chef-shell in the same way as the client.rb file is used to configure the chef-client. For example, to configure chef-shell to authenticate to the Chef server, copy the ``node_name``, ``client_key``, and ``chef_server_url`` settings from the knife.rb file:

.. code-block:: ruby

   node_name                'your-knife-clientname'
   client_key               File.expand_path('~/.chef/my-client.pem')
   chef_server_url          'https://api.opscode.com/organizations/myorg'

and then add them to the chef-shell.rb file. Other configuration possibilities include disabling Ohai plugins (which will speed up the chef-shell boot process) or including arbitrary Ruby code in the chef-shell.rb file.

.. end_tag

Run as a chef-client
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag chef_shell_run_as_chef_client

By default, chef-shell loads in standalone mode and does not connect to the Chef server. The chef-shell can be run as a chef-client to verify functionality that is only available when the chef-client connects to the Chef server, such as search functionality or accessing data stored in data bags.

chef-shell can use the same credentials as knife when connecting to a Chef server. Make sure that the settings in chef-shell.rb are the same as those in knife.rb, and then use the ``-z`` option as part of the command. For example:

.. code-block:: bash

   $ chef-shell -z

.. end_tag

Manage
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag chef_shell_manage

When chef-shell is configured to access a Chef server, chef-shell can list, show, search for and edit cookbooks, clients, nodes, roles, environments, and data bags.

The syntax for managing objects on the Chef server is as follows:

.. code-block:: bash

   $ chef-shell -z named_configuration

where:

* ``named_configuration`` is an existing configuration file in ``~/.chef/named_configuration/chef_shell.rb``, such as ``production``, ``staging``, or ``test``

Once in chef-shell, commands can be run against objects as follows:

.. code-block:: bash

   $ chef (preprod) > items.command

* ``items`` is the type of item to search for: ``cookbooks``, ``clients``, ``nodes``, ``roles``, ``environments`` or a data bag
* ``command`` is the command: ``list``, ``show``, ``find``, or ``edit``

For example, to list all of the nodes in a configuration named "preprod":

.. code-block:: bash

   $ chef (preprod) > nodes.list

to return something similar to:

.. code-block:: bash

   => [node[i-f09a939b], node[i-049a936f], node[i-eaaaa581], node[i-9154b1fb],
       node[i-6a213101], node[i-c2687aa9], node[i-7abeaa11], node[i-4eb8ac25],
       node[i-9a2030f1], node[i-a06875cb], node[i-145f457f], node[i-e032398b],
       node[i-dc8c98b7], node[i-6afdf401], node[i-f49b119c], node[i-5abfab31],
       node[i-78b8ac13], node[i-d99678b3], node[i-02322269], node[i-feb4a695],
       node[i-9e2232f5], node[i-6e213105], node[i-cdde3ba7], node[i-e8bfb083],
       node[i-743c2c1f], node[i-2eaca345], node[i-aa7f74c1], node[i-72fdf419],
       node[i-140e1e7f], node[i-f9d43193], node[i-bd2dc8d7], node[i-8e7f70e5],
       node[i-78f2e213], node[i-962232fd], node[i-4c322227], node[i-922232f9],
       node[i-c02728ab], node[i-f06c7b9b]]

The ``list`` command can take a code block, which will applied (but not saved) to each object that is returned from the server. For example:

.. code-block:: bash

   $ chef (preprod) > nodes.list {|n| puts "#{n.name}: #{n.run_list}" }

to return something similar to:

.. code-block:: bash

   => i-f09a939b: role[lb], role[preprod], recipe[aws]
      i-049a936f: role[lb], role[preprod], recipe[aws]
      i-9154b1fb: recipe[erlang], role[base], role[couchdb], role[preprod],
      i-6a213101: role[chef], role[preprod]
      # more...

The ``show`` command can be used to display a specific node. For example:

.. code-block:: bash

   $ chef (preprod) > load_balancer = nodes.show('i-f09a939b')

to return something similar to:

.. code-block:: bash

   => node[i-f09a939b]

or:

.. code-block:: bash

   $ chef (preprod) > load_balancer.ec2.public_hostname

to return something similar to:

.. code-block:: bash

   => "ec2-111-22-333-44.compute-1.amazonaws.com"

The ``find`` command can be used to search the Chef server from the chef-shell. For example:

.. code-block:: bash

   $ chef (preprod) > pp nodes.find(:ec2_public_hostname => 'ec2*')

A code block can be used to format the results. For example:

.. code-block:: bash

   $ chef (preprod) > pp nodes.find(:ec2_public_hostname => 'ec2*') {|n| n.ec2.ami_id } and nil

to return something similar to:

.. code-block:: bash

   => ["ami-f8927a91",
       "ami-f8927a91",
       "ami-a89870c1",
       "ami-a89870c1",
       "ami-a89870c1",
       "ami-a89870c1",
       "ami-a89870c1"
       # and more...

Or:

.. code-block:: bash

   $ chef (preprod) > amis = nodes.find(:ec2_public_hostname => 'ec2*') {|n| n.ec2.ami_id }
   $ chef (preprod) > puts amis.uniq.sort

to return something similar to:

.. code-block:: bash

   => ami-4b4ba522
      ami-a89870c1
      ami-eef61587
      ami-f8927a91

.. end_tag

breakpoint Resource
-----------------------------------------------------
.. tag chef_shell_breakpoints

chef-shell allows the current position in a run-list to be manipulated during a chef-client run. Add breakpoints to a recipe to take advantage of this functionality.

.. end_tag

.. tag resource_breakpoint_summary

Use the **breakpoint** resource to add breakpoints to recipes. Run the chef-shell in chef-client mode, and then use those breakpoints to debug recipes. Breakpoints are ignored by the chef-client during an actual chef-client run. That said, breakpoints are typically used to debug recipes only when running them in a non-production environment, after which they are removed from those recipes before the parent cookbook is uploaded to the Chef server.

.. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_breakpoint_syntax

A **breakpoint** resource block creates a breakpoint in a recipe:

.. code-block:: ruby

   breakpoint 'name' do
     action :break
   end

where

* ``:break`` will tell the chef-client to stop running a recipe; can only be used when the chef-client is being run in chef-shell mode

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_breakpoint_actions

This resource has the following actions:

``:break``
   Use to add a breakpoint to a recipe.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

.. end_tag

Attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_breakpoint_attributes

This resource does not have any properties.

.. end_tag

Providers
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This resource has the following providers:

``Chef::Provider::Breakpoint``, ``breakpoint``
   The default provider for all recipes.

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**A recipe without a breakpoint**

.. tag resource_breakpoint_no

.. A resource without breakpoints:

.. code-block:: ruby

   yum_key node['yum']['elrepo']['key'] do
     url  node['yum']['elrepo']['key_url']
     action :add
   end

   yum_repository 'elrepo' do
     description 'ELRepo.org Community Enterprise Linux Extras Repository'
     key node['yum']['elrepo']['key']
     mirrorlist node['yum']['elrepo']['url']
     includepkgs node['yum']['elrepo']['includepkgs']
     exclude node['yum']['elrepo']['exclude']
     action :create
   end

.. end_tag

**The same recipe with breakpoints**

.. tag resource_breakpoint_yes

.. code-block:: ruby

   breakpoint "before yum_key node['yum']['repo_name']['key']" do
     action :break
   end

   yum_key node['yum']['repo_name']['key'] do
     url  node['yum']['repo_name']['key_url']
     action :add
   end

   breakpoint "after yum_key node['yum']['repo_name']['key']" do
     action :break
   end

   breakpoint "before yum_repository 'repo_name'" do
     action :break
   end

   yum_repository 'repo_name' do
     description 'description'
     key node['yum']['repo_name']['key']
     mirrorlist node['yum']['repo_name']['url']
     includepkgs node['yum']['repo_name']['includepkgs']
     exclude node['yum']['repo_name']['exclude']
     action :create
   end

   breakpoint "after yum_repository 'repo_name'" do
     action :break
   end

where the name of each breakpoint is an arbitrary string. In the previous examples, the names are used to indicate if the breakpoint is before or after a resource, and then also to specify which resource.

.. end_tag

Step Through Run-list
-----------------------------------------------------
.. tag chef_shell_step_through_run_list

To explore how using the **breakpoint** to manually step through a chef-client run, create a simple recipe in chef-shell:

.. code-block:: bash

   $ chef > recipe_mode
     chef:recipe > echo off
     chef:recipe > file "/tmp/before-breakpoint"
     chef:recipe > breakpoint "foo"
     chef:recipe > file "/tmp/after-breakpoint"

and then run the chef-client:

.. code-block:: bash

   $ chef:recipe > run_chef
     [Fri, 15 Jan 2010 14:17:49 -0800] DEBUG: Processing file[/tmp/before-breakpoint]
     [Fri, 15 Jan 2010 14:17:49 -0800] DEBUG: file[/tmp/before-breakpoint] using Chef::Provider::File
     [Fri, 15 Jan 2010 14:17:49 -0800] INFO: Creating file[/tmp/before-breakpoint] at /tmp/before-breakpoint
     [Fri, 15 Jan 2010 14:17:49 -0800] DEBUG: Processing [./bin/../lib/chef/mixin/recipe_definition_dsl_core.rb:56:in 'new']
     [Fri, 15 Jan 2010 14:17:49 -0800] DEBUG: [./bin/../lib/chef/mixin/recipe_definition_dsl_core.rb:56:in 'new'] using Chef::Provider::Breakpoint

The chef-client ran the first resource before the breakpoint (``file[/tmp/before-breakpoint]``), but then stopped after execution. The chef-client attempted to name the breakpoint after its position in the source file, but the chef-client was confused because the resource was entered interactively. From here, chef-shell can resume the chef-client run:

.. code-block:: bash

   $ chef:recipe > chef_run.resume
     [Fri, 15 Jan 2010 14:27:08 -0800] INFO: Creating file[/tmp/after-breakpoint] at /tmp/after-breakpoint

A quick view of the ``/tmp`` directory shows that the following files were created:

.. code-block:: bash

   after-breakpoint
   before-breakpoint

The chef-client run can also be rewound, and then stepped through.

.. code-block:: bash

   $ chef:recipe > Chef::Log.level = :debug # debug logging won't turn on automatically in this case
       => :debug
     chef:recipe > chef_run.rewind
       => 0
     chef:recipe > chef_run.step
     [Fri, 15 Jan 2010 14:40:52 -0800] DEBUG: Processing file[/tmp/before-breakpoint]
     [Fri, 15 Jan 2010 14:40:52 -0800] DEBUG: file[/tmp/before-breakpoint] using Chef::Provider::File
       => 1
     chef:recipe > chef_run.step
     [Fri, 15 Jan 2010 14:40:54 -0800] DEBUG: Processing [./bin/../lib/chef/mixin/recipe_definition_dsl_core.rb:56:in 'new']
     [Fri, 15 Jan 2010 14:40:54 -0800] DEBUG: [./bin/../lib/chef/mixin/recipe_definition_dsl_core.rb:56:in 'new'] using Chef::Provider::Breakpoint
       => 2
     chef:recipe > chef_run.step
     [Fri, 15 Jan 2010 14:40:56 -0800] DEBUG: Processing file[/tmp/after-breakpoint]
     [Fri, 15 Jan 2010 14:40:56 -0800] DEBUG: file[/tmp/after-breakpoint] using Chef::Provider::File
       => 3

From the output, the rewound run-list is shown, but when the resources are executed again, they will repeat their checks for the existence of files. If they exist, the chef-client will skip creating them. If the files are deleted, then:

.. code-block:: bash

   $ chef:recipe > ls("/tmp").grep(/breakpoint/).each {|f| rm "/tmp/#{f}" }
       => ["after-breakpoint", "before-breakpoint"]

Rewind, and then resume the chef-client run to get the expected results:

.. code-block:: bash

   $ chef:recipe > chef_run.rewind
     chef:recipe > chef_run.resume
     [Fri, 15 Jan 2010 14:48:56 -0800] DEBUG: Processing file[/tmp/before-breakpoint]
     [Fri, 15 Jan 2010 14:48:56 -0800] DEBUG: file[/tmp/before-breakpoint] using Chef::Provider::File
     [Fri, 15 Jan 2010 14:48:56 -0800] INFO: Creating file[/tmp/before-breakpoint] at /tmp/before-breakpoint
     [Fri, 15 Jan 2010 14:48:56 -0800] DEBUG: Processing [./bin/../lib/chef/mixin/recipe_definition_dsl_core.rb:56:in 'new']
     [Fri, 15 Jan 2010 14:48:56 -0800] DEBUG: [./bin/../lib/chef/mixin/recipe_definition_dsl_core.rb:56:in 'new'] using Chef::Provider::Breakpoint
     chef:recipe > chef_run.resume
     [Fri, 15 Jan 2010 14:49:20 -0800] DEBUG: Processing file[/tmp/after-breakpoint]
     [Fri, 15 Jan 2010 14:49:20 -0800] DEBUG: file[/tmp/after-breakpoint] using Chef::Provider::File
     [Fri, 15 Jan 2010 14:49:20 -0800] INFO: Creating file[/tmp/after-breakpoint] at /tmp/after-breakpoint

.. end_tag

Debug Existing Recipe
-----------------------------------------------------
.. tag chef_shell_debug_existing_recipe

chef-shell can be used to debug existing recipes. The recipe first needs to be added to a run-list for the node, so that it is cached when starting chef-shell and then used for debugging. chef-shell will report which recipes are being cached when it is started:

.. code-block:: bash

    loading configuration: none (standalone session)
    Session type: standalone
    Loading..............done.

    This is the chef-shell.
     Chef Version: 12.17.44
     https://www.chef.io/
     /

    run `help' for help, `exit' or ^D to quit.

    Ohai2u YOURNAME@!
    chef (12.17.44)>

To just load one recipe from the run-list, go into the recipe and use the ``include_recipe`` command. For example:

.. code-block:: bash

   $ chef > recipe_mode
     chef:recipe > include_recipe "getting-started"
       => [#<Chef::Recipe:0x10256f9e8 @cookbook_name="getting-started",
     ... output truncated ...

To load all of the recipes from a run-list, use code similar to the following:

.. code-block:: ruby

   node.run_list.expand(node.chef_environment).recipes.each do |r|
     include_recipe r
   end

After the recipes that are to be debugged have been loaded, use the ``run_chef`` command to run them.

.. end_tag

Advanced Debugging
-----------------------------------------------------
.. tag chef_shell_advanced_debug

In chef-shell, it is possible to get extremely verbose debugging using the tracing feature in Interactive Ruby (IRb). chef-shell provides a shortcut for turning tracing on and off. For example:

.. code-block:: bash

   $ chef > tracing on
     /Users/danielsdeleo/.rvm/ree-1.8.7-2009.10/lib/ruby/1.8/tracer.rb:150: warning: tried to create Proc object without a block
     /Users/danielsdeleo/.rvm/ree-1.8.7-2009.10/lib/ruby/1.8/tracer.rb:146: warning: tried to create Proc object without a block
     tracing is on
       => nil

and:

.. code-block:: bash

   $ chef > tracing off
     #0:(irb):3:Object:-: tracing off
     #0:/opt/chef/embedded/lib/ruby/gems/1.9.3/gems/chef-11.4.4/lib/chef/shell/ext.rb:108:Shell::Extensions::ObjectCoreExtensions:>:       def off
     #0:/opt/chef/embedded/lib/ruby/gems/1.9.3/gems/chef-11.4.4/lib/chef/shell/ext.rb:109:Shell::Extensions::ObjectCoreExtensions:-:         :off
     #0:/opt/chef/embedded/lib/ruby/gems/1.9.3/gems/chef-11.4.4/lib/chef/shell/ext.rb:110:Shell::Extensions::ObjectCoreExtensions:<:       end
     #0:/opt/chef/embedded/lib/ruby/gems/1.9.3/gems/chef-11.4.4/lib/chef/shell/ext.rb:273:main:>:       def tracing(on_or_off)
     #0:/opt/chef/embedded/lib/ruby/gems/1.9.3/gems/chef-11.4.4/lib/chef/shell/ext.rb:274:main:-:         conf.use_tracer = on_or_off.on_off_to_bool
     #0:/opt/chef/embedded/lib/ruby/gems/1.9.3/gems/chef-11.4.4/lib/chef/shell/ext.rb:161:Shell::Extensions::Symbol:>:       def on_off_to_bool
     #0:/opt/chef/embedded/lib/ruby/gems/1.9.3/gems/chef-11.4.4/lib/chef/shell/ext.rb:162:Shell::Extensions::Symbol:-:         self.to_s.on_off_to_bool
     #0:/opt/chef/embedded/lib/ruby/gems/1.9.3/gems/chef-11.4.4/lib/chef/shell/ext.rb:148:Shell::Extensions::String:>:       def on_off_to_bool
     #0:/opt/chef/embedded/lib/ruby/gems/1.9.3/gems/chef-11.4.4/lib/chef/shell/ext.rb:149:Shell::Extensions::String:-:         case self
     #0:/opt/chef/embedded/lib/ruby/gems/1.9.3/gems/chef-11.4.4/lib/chef/shell/ext.rb:153:Shell::Extensions::String:-:           false
     #0:/opt/chef/embedded/lib/ruby/gems/1.9.3/gems/chef-11.4.4/lib/chef/shell/ext.rb:157:Shell::Extensions::String:<:       end
     #0:/opt/chef/embedded/lib/ruby/gems/1.9.3/gems/chef-11.4.4/lib/chef/shell/ext.rb:163:Shell::Extensions::Symbol:<:       end
     tracing is off
      => nil
     chef >

.. end_tag

debug_value
-----------------------------------------------------
Use the ``debug_value`` method to discover the location within the attribute precedence hierarchy from which a particular attribute (or sub-attribute) is set. This method is available when running chef-shell in chef-client mode:

.. code-block:: bash

   $ chef-shell -z

For example, the following attributes exist in a cookbook. Some are defined in a role file:

.. code-block:: ruby

   default_attributes 'test' => {'source' => 'role default'}
   override_attributes 'test' => {'source' => 'role override'}

And others are defined in an attributes file:

.. code-block:: ruby

   default[:test][:source]  = 'attributes default'
   set[:test][:source]      = 'attributes normal'
   override[:test][:source] = 'attributes override'

To debug the location in which the value of ``node[:test][:source]`` is set, use chef-shell and run a command similar to:

.. code-block:: none

   $ pp node.debug_value('test', 'source')

This will pretty-print return all of the attributes and sub-attributes as an array of arrays; ``:not_present`` is returned for any attribute without a value:

.. code-block:: bash

   [['set_unless_enabled?', false],
    ['default', 'attributes default'],
    ['env_default', :not_present],
    ['role_default', 'role default'],
    ['force_default', :not_present],
    ['normal', 'attributes normal'],
    ['override', 'attributes override'],
    ['role_override', 'role override'],
    ['env_override', :not_present],
    ['force_override', :not_present],
    ['automatic', :not_present]]

where

* ``set_unless_enabled`` indicates if the attribute collection is in ``set_unless`` mode; this typically returns ``false``
* Each attribute type is listed in order of precedence
* Each attribute value shown is the value that is set for that precedence level
* ``:not_present`` is shown for any attribute precedence level that has no attributes

A `blog post by Joshua Timberman <http://jtimberman.housepub.org/blog/2014/09/02/chef-node-dot-debug-value/>`_ provides another example of using this method.

ignore_failure Method
-----------------------------------------------------
All resources share a set of common actions, attributes, and so on. Use the following attribute in a resource to help identify where an issue within a recipe may be located:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Attribute
     - Description
   * - ``ignore_failure``
     - Continue running a recipe if a resource fails for any reason. Default value: ``false``.

chef-solo
-----------------------------------------------------
.. tag chef_solo_summary

chef-solo is a command that executes chef-client in a way that does not require the Chef server in order to converge cookbooks. chef-solo uses chef-client's `Chef local mode </ctl_chef_client.html#run-in-local-mode>`_, and **does not support** the following functionality present in chef-client / server configurations:

* Centralized distribution of cookbooks
* A centralized API that interacts with and integrates infrastructure components
* Authentication or authorization

.. note:: chef-solo can be run as a daemon.

.. end_tag

.. tag ctl_chef_solo_summary

The chef-solo executable is run as a command-line tool.

.. end_tag

Options
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This command has the following syntax:

.. code-block:: bash

   chef-solo OPTION VALUE OPTION VALUE ...

This command has the following options:

``-c CONFIG``, ``--config CONFIG``
   The configuration file to use.

``-d``, ``--daemonize``
   Run the executable as a daemon.

   This option is only available on machines that run in UNIX or Linux environments. For machines that are running Microsoft Windows that require similar functionality, use the ``chef-client::service`` recipe in the ``chef-client`` cookbook: https://supermarket.chef.io/cookbooks/chef-client. This will install a chef-client service under Microsoft Windows using the Windows Service Wrapper.

``-E ENVIRONMENT_NAME``, ``--environment ENVIRONMENT_NAME``
   The name of the environment.

``-f``, ``--[no-]fork``
   Contain the chef-client run in a secondary process with dedicated RAM. When the chef-client run is complete, the RAM is returned to the master process. This option helps ensure that a chef-client uses a steady amount of RAM over time because the master process does not run recipes. This option also helps prevent memory leaks such as those that can be introduced by the code contained within a poorly designed cookbook. Use ``--no-fork`` to disable running the chef-client in fork node. Default value: ``--fork``.

   Changed in Chef Client 12.0, unforked interval runs are no longer allowed.

``-F FORMAT``, ``--format FORMAT``
   .. tag ctl_chef_client_options_format

   The output format: ``doc`` (default) or ``min``.

   * Use ``doc`` to print the progress of the chef-client run using full strings that display a summary of updates as they occur.
   * Use ``min`` to print the progress of the chef-client run using single characters.

   A summary of updates is printed at the end of the chef-client run. A dot (``.``) is printed for events that do not have meaningful status information, such as loading a file or synchronizing a cookbook. For resources, a dot (``.``) is printed when the resource is up to date, an ``S`` is printed when the resource is skipped by ``not_if`` or ``only_if``, and a ``U`` is printed when the resource is updated.

   Other formatting options are available when those formatters are configured in the client.rb file using the ``add_formatter`` option.

   .. end_tag

``--force-formatter``
   Show formatter output instead of logger output.

``--force-logger``
   Show logger output instead of formatter output.

``-g GROUP``, ``--group GROUP``
   The name of the group that owns a process. This is required when starting any executable as a daemon.

``-h``, ``--help``
   Show help for the command.

``-i SECONDS``, ``--interval SECONDS``
   The frequency (in seconds) at which the chef-client runs. When the chef-client is run at intervals, ``--splay`` values are applied first, then the chef-client run occurs, and then ``--interval`` values are applied.

``-j PATH``, ``--json-attributes PATH``
   The path to a file that contains JSON data.

   .. tag node_ctl_run_list

   Use this option to define a ``run_list`` object. For example, a JSON file similar to:

   .. code-block:: javascript

      "run_list": [
        "recipe[base]",
        "recipe[foo]",
        "recipe[bar]",
        "role[webserver]"
      ],

   may be used by running ``chef-client -j path/to/file.json``.

   In certain situations this option may be used to update ``normal`` attributes.

   .. end_tag

   .. warning:: .. tag node_ctl_attribute

                Any other attribute type that is contained in this JSON file will be treated as a ``normal`` attribute. Setting attributes at other precedence levels is not possible. For example, attempting to update ``override`` attributes using the ``-j`` option:

                .. code-block:: javascript

                   {
                     "name": "dev-99",
                     "description": "Install some stuff",
                     "override_attributes": {
                       "apptastic": {
                         "enable_apptastic": "false",
                         "apptastic_tier_name": "dev-99.bomb.com"
                       }
                     }
                   }

                will result in a node object similar to:

                .. code-block:: javascript

                   {
                     "name": "maybe-dev-99",
                     "normal": {
                       "name": "dev-99",
                       "description": "Install some stuff",
                       "override_attributes": {
                         "apptastic": {
                           "enable_apptastic": "false",
                           "apptastic_tier_name": "dev-99.bomb.com"
                         }
                       }
                     }
                   }

                .. end_tag

``-l LEVEL``, ``--log_level LEVEL``
   The level of logging to be stored in a log file.

``-L LOGLOCATION``, ``--logfile c``
   The location of the log file. This is recommended when starting any executable as a daemon.

``--[no-]color``
   View colored output. Default setting: ``--color``.

``-N NODE_NAME``, ``--node-name NODE_NAME``
   The name of the node.

``-o RUN_LIST_ITEM``, ``--override-runlist RUN_LIST_ITEM``
   Replace the current run-list with the specified items.

   New in Chef Client 12.0.

``-r RECIPE_URL``, ``--recipe-url RECIPE_URL``
   The URL location from which a remote cookbook tar.gz is to be downloaded.

``-s SECONDS``, ``--splay SECONDS``
   A random number between zero and ``splay`` that is added to ``interval``. Use splay to help balance the load on the Chef server by ensuring that many chef-client runs are not occuring at the same interval. When the chef-client is run at intervals, ``--splay`` values are applied first, then the chef-client run occurs, and then ``--interval`` values are applied.

   Changed in Chef Client 12.0 to be applied before the chef-client run.

``-u USER``, ``--user USER``
   The user that owns a process. This is required when starting any executable as a daemon.

``-v``, ``--version``
   The version of the chef-client.

``-W``, ``--why-run``
   Run the executable in why-run mode, which is a type of chef-client run that does everything except modify the system. Use why-run mode to understand why the chef-client makes the decisions that it makes and to learn more about the current and proposed state of the system.

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**Use a URL**

.. tag ctl_chef_solo_use_url

.. To use a URL:

.. code-block:: bash

   $ chef-solo -c ~/solo.rb -j ~/node.json -r http://www.example.com/chef-solo.tar.gz

The tar.gz is archived into the ``file_cache_path``, and then extracted to ``cookbooks_path``.

.. end_tag

**Use a directory**

.. tag ctl_chef_solo_use_directory

.. To use a directory:

.. code-block:: bash

   $ chef-solo -c ~/solo.rb -j ~/node.json

chef-solo will look in the solo.rb file to determine the directory in which cookbooks are located.

.. end_tag

**Use a URL for cookbook and JSON data**

.. tag ctl_chef_solo_url_for_cookbook_and_json

.. To use a URL for cookbook and JSON data:

.. code-block:: bash

   $ chef-solo -c ~/solo.rb -j http://www.example.com/node.json -r http://www.example.com/chef-solo.tar.gz

where ``-r`` corresponds to ``recipe_url`` and ``-j`` corresponds to ``json_attribs``, both of which are configuration options in solo.rb.

.. end_tag

**"Hello World"**

.. tag chef_shell_example_hello_world

This example shows how to run chef-shell in standalone mode. (For chef-solo or chef-client modes, you would need to run chef-shell using the ``-s`` or ``-z`` command line options, and then take into consideration the necessary configuration settings.)

When the chef-client is installed using RubyGems or a package manager, chef-shell should already be installed. When the chef-client is run from a git clone, it will be located in ``chef/bin/chef shell``. To start chef-shell, just run it without any options. You'll see the loading message, then the banner, and then the chef-shell prompt:

.. code-block:: bash

   $ bin/chef-shell
     loading configuration: none (standalone session)
     Session type: standalone
     Loading..............done.

     This is the chef-shell.
      Chef Version: 12.17.44
      https://www.chef.io/
      /

     run `help' for help, `exit' or ^D to quit.

     Ohai2u YOURNAME@!
     chef (12.17.44)>

(Use the help command to print a list of supported commands.) Use the recipe_mode command to switch to recipe context:

.. code-block:: bash

   $ chef > recipe_mode
     chef:recipe_mode >

Typing is evaluated in the same context as recipes. Create a file resource:

.. code-block:: bash

   $ chef:recipe_mode > file "/tmp/ohai2u_shef"
       => #<Chef::Resource::File:0x1b691ac
          @enclosing_provider=nil,
          @resource_name=:file,
          @before=nil,
          @supports={},
          @backup=5,
          @allowed_actions=[:nothing, :create, :delete, :touch, :create_if_missing],
          @only_if=nil,
          @noop=nil,
          @collection=#<Chef::ResourceCollection:0x1b9926c
          @insert_after_idx=nil,
          @resources_by_name={"file[/tmp/ohai2u_shef]"=>0},
          @resources=[#<Chef::Resource::File:0x1b691ac ...>]>,
          @updated=false,
          @provider=nil,
          @node=<Chef::Node:0xdeeaae
          @name="eigenstate.local">,
          @recipe_name=nil,
          @not_if=nil,
          @name="/tmp/ohai2u_shef",
          @action="create",
          @path="/tmp/ohai2u_shef",
          @source_line="/Users/danielsdeleo/ruby/chef/chef/(irb#1) line 1",
          @params={},
          @actions={},
          @cookbook_name=nil,
          @ignore_failure=false>

(The previous example was formatted for presentation.) At this point, chef-shell has created the resource and put it in the run-list, but not yet created the file. To initiate the chef-client run, use the ``run_chef`` command:

.. code-block:: bash

   $ chef:recipe_mode > run_chef
     [Fri, 15 Jan 2010 10:42:47 -0800] DEBUG: Processing file[/tmp/ohai2u_shef]
     [Fri, 15 Jan 2010 10:42:47 -0800] DEBUG: file[/tmp/ohai2u_shef] using Chef::Provider::File
     [Fri, 15 Jan 2010 10:42:47 -0800] INFO: Creating file[/tmp/ohai2u_shef] at /tmp/ohai2u_shef
       => true

chef-shell can also switch to the same context as attribute files. Set an attribute with the following syntax:

.. code-block:: bash

   $ chef:recipe_mode > attributes_mode
     chef:attributes > set[:hello] = "ohai2u-again"
       => "ohai2u-again"
     chef:attributes >

Switch back to recipe_mode context and use the attributes:

.. code-block:: bash

   $ chef:attributes > recipe_mode
       => :attributes
     chef:recipe_mode > file "/tmp/#{node.hello}"

Now, run the chef-client again:

.. code-block:: bash

   $ chef:recipe_mode > run_chef
     [Fri, 15 Jan 2010 10:53:22 -0800] DEBUG: Processing file[/tmp/ohai2u_shef]
     [Fri, 15 Jan 2010 10:53:22 -0800] DEBUG: file[/tmp/ohai2u_shef] using Chef::Provider::File
     [Fri, 15 Jan 2010 10:53:22 -0800] DEBUG: Processing file[/tmp/ohai2u-again]
     [Fri, 15 Jan 2010 10:53:22 -0800] DEBUG: file[/tmp/ohai2u-again] using Chef::Provider::File
     [Fri, 15 Jan 2010 10:53:22 -0800] INFO: Creating file[/tmp/ohai2u-again] at /tmp/ohai2u-again
       => true
     chef:recipe_mode >

Because the first resource (``file[/tmp/ohai2u_shef]``) is still in the run-list, it gets executed again. And because that file already exists, the chef-client doesn't attempt to re-create it. Finally, the files were created using the ``ls`` method:

.. code-block:: bash

   $ chef:recipe_mode > ls("/tmp").grep(/ohai/)
       => ["ohai2u-again", "ohai2u_shef"]
	 Shell Tutorial

.. end_tag

**Get Specific Nodes**

.. tag chef_shell_example_get_specific_nodes

To get a list of nodes using a recipe named ``postfix`` use ``search(:node,"recipe:postfix")``. To get a list of nodes using a sub-recipe named ``delivery``, use chef-shell. For example:

.. code-block:: ruby

   search(:node, 'recipes:postfix\:\:delivery')

.. note:: Single (' ') vs. double (" ") is important. This is because a backslash (\) needs to be included in the string, instead of having Ruby interpret it as an escape.

.. end_tag
