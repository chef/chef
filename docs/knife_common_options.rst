=====================================================
Common Options
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_common_options.rst>`__

The following options can be run with all knife subcommands and plug-ins:

``-c CONFIG_FILE``, ``--config CONFIG_FILE``
   The configuration file to use. For example, when knife is run from a node that is configured to be managed by the Chef server, this option is used to allow knife to use the same credentials as the chef-client when communicating with the Chef server.

``--chef-zero-port PORT``
   The port on which chef-zero listens.

   Changed in Chef Client 12.0 to support specifying a range of ports.

``-d``, ``--disable-editing``
   Prevent the $EDITOR from being opened and accept data as-is.

``--defaults``
   Cause knife to use the default value instead of asking a user to provide one.

``-e EDITOR``, ``--editor EDITOR``
   The $EDITOR that is used for all interactive commands.

``-E ENVIRONMENT``, ``--environment ENVIRONMENT``
   The name of the environment. When this option is added to a command, the command will run only against the named environment. This option is ignored during search queries made using the ``knife search`` subcommand.

``-F FORMAT``, ``--format FORMAT``
   The output format: ``summary`` (default), ``text``, ``json``, ``yaml``, and ``pp``.

``-h``, ``--help``
   Show help for the command.

``-k KEY``, ``--key KEY``
   The USER.pem file that knife uses to sign requests made by the API client to the Chef server.

``--[no-]color``
   View colored output.

``--[no-]fips``
  Allows OpenSSL to enforce FIPS-validated security during the chef-client run.

``--print-after``
   Show data after a destructive operation.

``-s URL``, ``--server-url URL``
   The URL for the Chef server.

``-u USER``, ``--user USER``
   The user name used by knife to sign requests made by the API client to the Chef server. Authentication fails if the user name does not match the private key.

``-v``, ``--version``
   The version of the chef-client.

``-V``, ``--verbose``
   Set for more verbose outputs. Use ``-VV`` for maximum verbosity.

``-y``, ``--yes``
   Respond to all confirmation prompts with "Yes".

``-z``, ``--local-mode``
   Run the chef-client in local mode. This allows all commands that work against the Chef server to also work against the local chef-repo.
