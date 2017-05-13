=====================================================
chef-solo (executable)
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/ctl_chef_solo.rst>`__

.. warning:: .. tag notes_chef_solo_use_local_mode

             The chef-client `includes an option called local mode </ctl_chef_client.html#run-in-local-mode>`_ (``--local-mode`` or ``-z``), which runs the chef-client against the chef-repo on the local machine as if it were running against a Chef server. Local mode was added to the chef-client in the 11.8 release. If you are running that version of the chef-client (or later), you should consider using local mode instead of using chef-solo.

             .. end_tag

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

New in Chef Client 12.3, ``--minimal-ohai``. New in 12.0, ``-o RUN_LIST_ITEM``. Changed in 12.0 ``-f`` no longer allows unforked intervals, ``-i SECONDS`` is applied before the chef-client run.

Options
=====================================================
.. tag ctl_chef_solo_options

This command has the following syntax:

.. code-block:: bash

   chef-solo OPTION VALUE OPTION VALUE ...

This command has the following options:

``-c CONFIG``, ``--config CONFIG``
   The configuration file to use.

``-d``, ``--daemonize``
   Run the executable as a daemon. This option may not be used in the same command with the ``--[no-]fork`` option.

   This option is only available on machines that run in UNIX or Linux environments. For machines that are running Microsoft Windows that require similar functionality, use the ``chef-client::service`` recipe in the ``chef-client`` cookbook: https://supermarket.chef.io/cookbooks/chef-client. This will install a chef-client service under Microsoft Windows using the Windows Service Wrapper.

``-E ENVIRONMENT_NAME``, ``--environment ENVIRONMENT_NAME``
   The name of the environment.

``-f``, ``--[no-]fork``
   Contain the chef-client run in a secondary process with dedicated RAM. When the chef-client run is complete, the RAM is returned to the master process. This option helps ensure that a chef-client uses a steady amount of RAM over time because the master process does not run recipes. This option also helps prevent memory leaks such as those that can be introduced by the code contained within a poorly designed cookbook. Use ``--no-fork`` to disable running the chef-client in fork node. Default value: ``--fork``. This option may not be used in the same command with the ``--daemonize`` and ``--interval`` options.

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
   The frequency (in seconds) at which the chef-client runs. When the chef-client is run at intervals, ``--splay`` and ``--interval`` values are applied before the chef-client run. This option may not be used in the same command with the ``--[no-]fork`` option.

   Changed in Chef Client 12.0 to be applied before the chef-client run.

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

``--legacy-mode``
   Cause the chef-client to not use chef local mode, but rather the original chef-solo mode. This is not recommended unless really required.

``--minimal-ohai``
   Run the Ohai plugins for name detection and resource/provider selection and no other Ohai plugins. Set to ``true`` during integration testing to speed up test cycles.

   New in Chef Client 12.3.

``--[no-]color``
   View colored output. Default setting: ``--color``.

``-N NODE_NAME``, ``--node-name NODE_NAME``
   The name of the node.

``-o RUN_LIST_ITEM``, ``--override-runlist RUN_LIST_ITEM``
   Replace the current run-list with the specified items.

   New in Chef Client 12.0.

``-r RECIPE_URL``, ``--recipe-url RECIPE_URL``
   The URL location from which a remote cookbook tar.gz is to be downloaded.

``--run-lock-timeout SECONDS``
   The amount of time (in seconds) to wait for a chef-client lock file to be deleted. Default value: not set (indefinite). Set to ``0`` to cause a second chef-client to exit immediately.

``-s SECONDS``, ``--splay SECONDS``
   A random number between zero and ``splay`` that is added to ``interval``. Use splay to help balance the load on the Chef server by ensuring that many chef-client runs are not occuring at the same interval. When the chef-client is run at intervals, ``--splay`` and ``--interval`` values are applied before the chef-client run.

``-u USER``, ``--user USER``
   The user that owns a process. This is required when starting any executable as a daemon.

``-v``, ``--version``
   The version of the chef-client.

``-W``, ``--why-run``
   Run the executable in why-run mode, which is a type of chef-client run that does everything except modify the system. Use why-run mode to understand why the chef-client makes the decisions that it makes and to learn more about the current and proposed state of the system.

.. end_tag

Run as Non-root User
=====================================================
chef-solo may be run as a non-root user. For example, the ``sudoers`` file can be updated similar to:

.. code-block:: ruby

   # chef-solo privilege specification
   chef ALL=(ALL) NOPASSWD: /usr/bin/chef-solo

where ``chef`` is the name of the non-root user. This would allow chef-solo to run any command on the node without requiring a password.

Examples
=====================================================

**Run chef-solo using solo.rb settings**

.. tag ctl_chef_solo_use_solo_rb

.. To use solo.rb settings:

.. code-block:: bash

   $ chef-solo -c ~/chef/solo.rb

.. end_tag

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
