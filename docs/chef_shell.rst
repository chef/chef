=====================================================
chef-shell
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/chef_shell.rst>`__

.. tag chef_shell_summary

chef-shell is a recipe debugging tool that allows the use of breakpoints within recipes. chef-shell runs as an Interactive Ruby (IRb) session. chef-shell supports both recipe and attribute file syntax, as well as interactive debugging features.

.. end_tag

Modes
=====================================================
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
=====================================================
.. tag chef_shell_config

chef-shell determines which configuration file to load based on the following:

#. If a configuration file is specified using the ``-c`` option, chef-shell will use the specified configuration file
#. When chef-shell is started using a named configuration as an argument, chef-shell will search for a chef-shell.rb file in that directory under ``~/.chef``. For example, if chef-shell is started using ``production`` as the named configuration, the chef-shell will load a configuration file from ``~/.chef/production/chef_shell.rb``
#. If a named configuration is not provided, chef-shell will attempt to load the chef-shell.rb file from the ``.chef`` directory. For example: ``~/.chef/chef_shell.rb``
#. If a chef-shell.rb file is not found, chef-shell will attempt to load the client.rb file
#. If a chef-shell.rb file is not found, chef-shell will attempt to load the solo.rb file

.. end_tag

chef-shell.rb
-----------------------------------------------------
.. tag chef_shell_config_rb

The chef-shell.rb file can be used to configure chef-shell in the same way as the client.rb file is used to configure the chef-client. For example, to configure chef-shell to authenticate to the Chef server, copy the ``node_name``, ``client_key``, and ``chef_server_url`` settings from the knife.rb file:

.. code-block:: ruby

   node_name                'your-knife-clientname'
   client_key               File.expand_path('~/.chef/my-client.pem')
   chef_server_url          'https://api.opscode.com/organizations/myorg'

and then add them to the chef-shell.rb file. Other configuration possibilities include disabling Ohai plugins (which will speed up the chef-shell boot process) or including arbitrary Ruby code in the chef-shell.rb file.

.. end_tag

Run as a chef-client
-----------------------------------------------------
.. tag chef_shell_run_as_chef_client

By default, chef-shell loads in standalone mode and does not connect to the Chef server. The chef-shell can be run as a chef-client to verify functionality that is only available when the chef-client connects to the Chef server, such as search functionality or accessing data stored in data bags.

chef-shell can use the same credentials as knife when connecting to a Chef server. Make sure that the settings in chef-shell.rb are the same as those in knife.rb, and then use the ``-z`` option as part of the command. For example:

.. code-block:: bash

   $ chef-shell -z

.. end_tag

Manage
=====================================================
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

Use Breakpoints
=====================================================
.. tag chef_shell_breakpoints

chef-shell allows the current position in a run-list to be manipulated during a chef-client run. Add breakpoints to a recipe to take advantage of this functionality.

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

Examples
=====================================================
The following examples show how to use chef-shell.

"Hello World"
-----------------------------------------------------
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

Get Specific Nodes
-----------------------------------------------------
.. tag chef_shell_example_get_specific_nodes

To get a list of nodes using a recipe named ``postfix`` use ``search(:node,"recipe:postfix")``. To get a list of nodes using a sub-recipe named ``delivery``, use chef-shell. For example:

.. code-block:: ruby

   search(:node, 'recipes:postfix\:\:delivery')

.. note:: Single (' ') vs. double (" ") is important. This is because a backslash (\) needs to be included in the string, instead of having Ruby interpret it as an escape.

.. end_tag
