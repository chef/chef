=====================================================
knife.rb Optional Settings
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/config_rb_knife_optional_settings.rst>`__

.. tag knife_using_knife_rb

In addition to the default settings in a knife.rb file, there are other subcommand-specific settings that can be added. When a subcommand is run, knife will use:

#. A value passed via the command-line
#. A value contained in the knife.rb file
#. The default value

A value passed via the command line will override a value in the knife.rb file; a value in a knife.rb file will override a default value.

.. end_tag

.. warning:: Many optional settings should not be added to the knife.rb file. The reasons for not adding them can vary. For example, using ``--yes`` as a default in the knife.rb file will cause knife to always assume that "Y" is the response to any prompt, which may lead to undesirable outcomes. Other settings, such as ``--hide-healthy`` (used only with the ``knife status`` subcommand) or ``--bare-directories`` (used only with the ``knife list`` subcommand) probably aren't used often enough (and in the same exact way) to justify adding them to the knife.rb file. In general, if the optional settings are not listed on :doc:`the main knife.rb topic </config_rb_knife>`, then add settings only after careful consideration. Do not use optional settings in a production environment until after the setting's performance has been validated in a safe testing environment.

The following list describes all of the optional settings that can be added to the configuration file:

``knife[:admin]``
   Create a client as an admin client. This is required for any user to access Open Source Chef as an administrator.

``knife[:admin_client_key]``

``knife[:admin_client_name]``

``knife[:after]``
   Add a run-list item after the specified run-list item.

``knife[:all]``
   Indicates that all environments, cookbooks, cookbook versions, metadata, and/or data bags will be uploaded, deleted, generated, or tested. The context depends on which knife subcommand and argument is used.

``knife[:all_versions]``
   Return all available versions for every cookbook.

``knife[:attribute]``
   The attribute (or attributes) to show.

``knife[:attribute_from_cli]``

``knife[:authentication_protocol_version]``

``knife[:bare_directories]``
   Prevent a directory's children from showing when a directory matches a pattern.

``knife[:before]``

``knife[:bootstrap_curl_options]``
   Arbitrary options to be added to the bootstrap command when using cURL. This option may not be used in the same command with ``--bootstrap-install-command``.

``knife[:bootstrap_install_command]``
   Execute a custom installation command sequence for the chef-client. This option may not be used in the same command with ``--bootstrap-curl-options``, ``--bootstrap-install-sh``, or ``--bootstrap-wget-options``.

``knife[:bootstrap_no_proxy]``
   A URL or IP address that specifies a location that should not be proxied.

``knife[:bootstrap_proxy]``
   The proxy server for the node that is the target of a bootstrap operation.

``knife[:bootstrap_template]``
   The path to a template file to be used during a bootstrap operation.

``knife[:bootstrap_vault_file]``
   The path to a JSON file that contains a list of vaults and items to be updated.

``knife[:bootstrap_vault_item]``
   A single vault and item to update as ``vault:item``.

``knife[:bootstrap_vault_json]``
   A JSON string that contains a list of vaults and items to be updated.

   .. tag knife_bootstrap_vault_json

   For example:

   .. code-block:: none

      --bootstrap-vault-json '{ "vault1": ["item1", "item2"], "vault2": "item2" }'

   .. end_tag

``knife[:bootstrap_version]``
   The version of the chef-client to install.

``knife[:bootstrap_wget_options]``
   Arbitrary options to be added to the bootstrap command when using GNU Wget. This option may not be used in the same command with ``--bootstrap-install-command``.

``knife[:both]``
   Delete both local and remote copies of an object.

``knife[:chef_node_name]``

``knife[:chef_repo_path]``
   The path to the chef-repo.

``knife[:chef_server_url]``

``knife[:chef_zero_host]``
   Override the host on which chef-zero listens.

``knife[:chef_zero_post]``
   The port on which chef-zero listens.

``knife[:client_key]``

``knife[:color]``

``knife[:concurrency]``
   The number of allowed concurrent connections.

``knife[:config_file]``
   The configuration file to use.

``knife[:cookbook_copyright]``

``knife[:cookbook_email]``

``knife[:cookbook_license]``

``knife[:cookbook_path]``

``knife[:delete_validators]``

``knife[:depends]``
   Ensure that when a cookbook has a dependency on one (or more) cookbooks, those cookbooks are also uploaded.

``knife[:description]``
   The description for an environment and/or a role.

``knife[:diff]``

``knife[:diff_filter]``
   Select only files that have been added (``A``), deleted (``D``), modified (``M``), and/or have had their type changed (``T``). Any combination of filter characters may be used, including no filter characters. Use ``*`` to select all paths if a file matches other criteria in the comparison.

``knife[:disable_editing]``
   Prevent the $EDITOR from being opened and accept data as-is.

``knife[:distro]``

``knife[:download_directory]``
   The directory in which cookbooks are located.

``knife[:dry_run]``
   Take no action and only print out results.

``knife[:editor]``
   The $EDITOR that is used for all interactive commands.

``knife[:encrypt]``

``knife[:env_run_list]``

``knife[:environment]``
   The name of the environment.

``knife[:exec]``
   A string of code that to be executed.

``knife[:file]``
   Save a private key to the specified file name.

``knife[:filter_result]``

``knife[:first_boot_attributes]``

``knife[:flat]``
   Show a list of file names. Set to ``false`` to view ``ls``-like output.

``knife[:force]``
   Overwrite an existing directory.

``knife[:format]``

``knife[:forward_agent]``
   Enable SSH agent forwarding.

``knife[:fqdn]``
   FQDN

``knife[:freeze]``
   Require changes to a cookbook be included as a new version. Only the ``--force`` option can override this setting.

``knife[:help]``

``knife[:hide_healthy]``
   Hide nodes on which a chef-client run has occurred within the previous hour.

``knife[:hints]``
   An Ohai hint to be set on the target node.

``knife[:host_key_verify]``
   Use ``--no-host-key-verify`` to disable host key verification.

``knife[:id_only]``

``knife[:identity_file]``
   The SSH identity file used for authentication. Key-based authentication is recommended.

``knife[:initial]``
   Create a API client, typically an administrator client on a freshly-installed Chef server.

``knife[:input]``
   The name of a file to be used with the ``PUT`` or a ``POST`` request.

``knife[:latest]``
   Download the most recent version of a cookbook.

``knife[:local]``
   Return only the contents of the local directory.

``knife[:local_mode]``

``knife[:log_level]``

``knife[:log_location]``

``knife[:manual]``
   Define a search query as a space-separated list of servers.

``knife[:max_arguments_per_command]``

``knife[:max_command_line]``

``knife[:method]``
   The request method: ``DELETE``, ``GET``, ``POST``, or ``PUT``.

``knife[:mismatch]``

``knife[:name_only]``
   Show only the names of modified files.

``knife[:name_status]``
   Show only the names of files with a status of ``Added``, ``Deleted``, ``Modified``, or ``Type Changed``.

``knife[:no_deps]``
   Ensure that all cookbooks to which the installed cookbook has a dependency are not installed.

``knife[:node_name]``
   The name of the node. This may be a username with permission to authenticate to the Chef server or it may be the name of the machine from which knife is run. For example:

   .. code-block:: ruby

      node_name 'user_name'

   or:

   .. code-block:: ruby

      node_name 'machine_name'

``knife[:null_separator]``

``knife[:on_error]``

``knife[:one_column]``
   Show only one column of results.

``knife[:patterns]``

``knife[:platform]``
   The platform for which a cookbook is designed.

``knife[:platform_version]``
   The version of the platform.

``knife[:pretty]``
   Use ``--no-pretty`` to disable pretty-print output for JSON.

``knife[:print_after]``
   Show data after a destructive operation.

``knife[:proxy_auth]``
   Enable proxy authentication to the Chef server web user interface.

``knife[:purge]``
   Entirely remove a cookbook (or cookbook version) from the Chef server. Use this action carefully because only one copy of any single file is stored on the Chef server. Consequently, purging a cookbook disables any other cookbook that references one or more files from the cookbook that has been purged.

``knife[:query]``

``knife[:readme_format]``
   The document format of the readme file: ``md`` (markdown) and ``rdoc`` (Ruby docs).

``knife[:recurse]``
   Use ``--recurse`` to delete directories recursively.

``knife[:recursive]``

``knife[:remote]``

``knife[:replace_all]``

``knife[:replace_first]``

``knife[:repo_mode]``
   The layout of the local chef-repo. Possible values: ``static``, ``everything``, or ``hosted_everything``. Use ``static`` for just roles, environments, cookbooks, and data bags. By default, ``everything`` and ``hosted_everything`` are dynamically selected depending on the server type.

``knife[:repository]``
   The path to the chef-repo.

``knife[:rows]``

``knife[:run_list]``
   A comma-separated list of roles and/or recipes to be applied.

``knife[:script_path]``
   A colon-separated path at which Ruby scripts are located.

``knife[:secret]``
   The encryption key that is used for values contained within a data bag item.

``knife[:secret_file]``
   The path to the file that contains the encryption key.

``knife[:server_name]``
   Same as node_name. Recommended configuration is to allow Ohai to collect this value during each chef-client run.

``knife[:sort]``

``knife[:sort_reverse]``
   Sort a list by last run time, descending.

``knife[:ssh_attribute]``
   The attribute used when opening an SSH connection.

``knife[:ssh_gateway]``
   The SSH tunnel or gateway that is used to run a bootstrap action on a machine that is not accessible from the workstation.

``knife[:ssh_password]``
   The SSH password. This can be used to pass the password directly on the command line. If this option is not specified (and a password is required) knife prompts for the password.

``knife[:ssh_password_ng]``

``knife[:ssh_port]``
   The SSH port.

``knife[:ssh_user]``
   The SSH user name.

``knife[:start]``

``knife[:supermarket_site]``
   The URL at which the Chef Supermarket is located. Default value: https://supermarket.chef.io.

``knife[:template_file]``

``knife[:trailing_slashes]``

``knife[:tree]``
   Show dependencies in a visual tree structure (including duplicates, if they exist).

``knife[:use current_branch]``
   Ensure that the current branch is used.

``knife[:use_sudo]``
   Execute a bootstrap operation with sudo.

``knife[:use_sudo_password]``

``knife[:user]`` and/or ``knife[:user_home]``
   The user name used by knife to sign requests made by the API client to the Chef server. Authentication fails if the user name does not match the private key.

``knife[:user_key]``
   Save a public key to the specified file name.

``knife[:user_password]``
   The user password.

``knife[:validation_client_name]``

``knife[:validation_key]``

``knife[:validator]``

``knife[:verbose_commands]``

``knife[:verbosity]``

``knife[:with_uri]``

``knife[:yes]``
   Respond to all confirmation prompts with "Yes".

By Subcommand
=====================================================
The following sections show the optional settings for the knife.rb file, sorted by subcommand.

bootstrap
-----------------------------------------------------
The following ``knife bootstrap`` settings can be added to the knife.rb file:

``knife[:bootstrap_curl_options]``
   Adds the ``--bootstrap-curl-options`` option.

``knife[:bootstrap_install_command]``
   Adds the ``--bootstrap-install-command`` option.

``knife[:bootstrap_no_proxy]``
   Adds the ``--bootstrap-no-proxy`` option.

``knife[:bootstrap_proxy]``
   Adds the ``--bootstrap-proxy`` option.

``knife[:bootstrap_template]``
   Adds the the ``--bootstrap-template`` option.

``knife[:bootstrap_url]``
   Adds the the ``--bootstrap-url`` option.

``knife[:bootstrap_vault_item]``
   Adds the the ``--bootstrap-vault-item`` option.

``knife[:bootstrap_version]``
   Adds the the ``--bootstrap-version`` option.

``knife[:bootstrap_wget_options]``
   Adds the the ``--bootstrap-wget-options`` option.

``knife[:run_list]``
   Adds the the ``--run-list`` option.

``knife[:template_file]``
   Adds the the ``--bootstrap-template`` option.

``knife[:use_sudo]``
   Adds the the ``--sudo`` option.

.. note:: The ``knife bootstrap`` subcommand relies on a number of SSH-related settings that are handled by the ``knife ssh`` subcommand.

client create
-----------------------------------------------------
The following ``knife client create`` settings can be added to the knife.rb file:

``knife[:admin]``
   Adds the the ``--admin`` option.

``knife[:file]``
   Adds the the ``--file`` option.

client reregister
-----------------------------------------------------
The following ``knife client reregister`` settings can be added to the knife.rb file:

``knife[:file]``
   Adds the the ``--file`` option.

configure
-----------------------------------------------------
The following ``knife configure`` settings can be added to the knife.rb file:

``knife[:admin_client_name]``
   The name of the admin client that is passed as part of a the command itself.

``knife[:config_file]``
   Adds the the ``--config`` option.

``knife[:disable_editing]``
   Adds the the ``--disable-editing`` option.

``knife[:file]``
   Adds the the ``--file`` option.

``knife[:initial]``
   Adds the the ``--initial`` option.

``knife[:repository]``
   Adds the the ``--repository`` option.

``knife[:user_home]``
   Adds the the ``--user`` option.

``knife[:user_password]``
   Adds the the ``--password`` option.

``knife[:yes]``
   Adds the the ``--yes`` option.

cookbook bulk delete
-----------------------------------------------------
The following ``knife cookbook bulk delete`` settings can be added to the knife.rb file:

``knife[:purge]``
   Adds the the ``--purge`` option.

``knife[:yes]``
   Adds the the ``--yes`` option.

cookbook create
-----------------------------------------------------
The following ``knife cookbook create`` settings can be added to the knife.rb file:

``knife[:readme_format]``
   Adds the the ``--readme-format`` option.

cookbook delete
-----------------------------------------------------
The following ``knife cookbook delete`` settings can be added to the knife.rb file:

``knife[:all]``
   Adds the the ``--all`` option.

``knife[:print_after]``
   Adds the the ``--print-after`` option.

``knife[:purge]``
   Adds the the ``--purge`` option.

cookbook download
-----------------------------------------------------
The following ``knife cookbook download`` settings can be added to the knife.rb file:

``knife[:download_directory]``
   Adds the the ``--dir`` option.

``knife[:force]``
   Adds the the ``--force`` option.

``knife[:latest]``
   Adds the the ``--latest`` option.

cookbook list
-----------------------------------------------------
The following ``knife cookbook list`` settings can be added to the knife.rb file:

``knife[:all]``
   Adds the the ``--all`` option.

``knife[:environment]``
   Adds the the ``--environment`` option.

cookbook metadata
-----------------------------------------------------
The following ``knife cookbook metadata`` settings can be added to the knife.rb file:

``knife[:all]``
   Adds the the ``--all`` option.

cookbook show
-----------------------------------------------------
The following ``knife cookbook show`` settings can be added to the knife.rb file:

``knife[:fqdn]``
   Adds the the ``--fqdn`` option.

``knife[:platform]``
   Adds the the ``--platform`` option.

``knife[:platform_version]``
   Adds the the ``--platform-version`` option.

cookbook test
-----------------------------------------------------
The following ``knife cookbook test`` settings can be added to the knife.rb file:

``knife[:all]``
   Adds the the ``--all`` option.

cookbook upload
-----------------------------------------------------
The following ``knife cookbook upload`` settings can be added to the knife.rb file:

``knife[:all]``
   Adds the the ``--all`` option.

``knife[:depends]``
   Adds the the ``--include-dependencies`` option.

``knife[:environment]``
   Adds the the ``--environment`` option.

``knife[:force]``
   Adds the the ``--force`` option.

``knife[:freeze]``
   Adds the the ``--freeze`` option.

cookbook site download
-----------------------------------------------------
The following ``knife cookbook site download`` settings can be added to the knife.rb file:

``knife[:file]``
   Adds the the ``--file`` option.

``knife[:force]``
   Adds the the ``--force`` option.

``knife[:supermarket_site]``
   The URL at which the Chef Supermarket is located. Default value: https://supermarket.chef.io.

cookbook site install
-----------------------------------------------------
The following ``knife cookbook site install`` settings can be added to the knife.rb file:

``knife[:cookbook_path]``
   Adds the the ``--cookbook-path`` option.

``knife[:file]``
   Adds the the ``--file`` option.

``knife[:no_deps]``
   Adds the the ``--skip-dependencies`` option.

``knife[:use_current_branch]``
   Adds the the ``--use-current-branch`` option.

``knife[:supermarket_site]``
   The URL at which the Chef Supermarket is located. Default value: https://supermarket.chef.io.

cookbook site share
-----------------------------------------------------
The following ``knife cookbook site share`` settings can be added to the knife.rb file:

``knife[:cookbook_path]``
   Adds the the ``--cookbook-path`` option.

``knife[:supermarket_site]``
   The URL at which the Chef Supermarket is located. Default value: https://supermarket.chef.io.

data bag create
-----------------------------------------------------
The following ``knife data bag create`` settings can be added to the knife.rb file:

``knife[:secret]``
   Adds the the ``--secret`` option.

``knife[:secret_file]``
   Adds the the ``--secret-file`` option.

data bag edit
-----------------------------------------------------
The following ``knife data bag edit`` settings can be added to the knife.rb file:

``knife[:print_after]``
   Adds the the ``--print-after`` option.

``knife[:secret]``
   Adds the the ``--secret`` option.

``knife[:secret_file]``
   Adds the the ``--secret-file`` option.

data bag from file
-----------------------------------------------------
The following ``knife data bag from file`` settings can be added to the knife.rb file:

``knife[:all]``
   Adds the the ``--all`` option.

``knife[:secret]``
   Adds the the ``--secret`` option.

``knife[:secret_file]``
   Adds the the ``--secret-file`` option.

data bag show
-----------------------------------------------------
The following ``knife data bag show`` settings can be added to the knife.rb file:

``knife[:secret]``
   Adds the the ``--secret`` option.

``knife[:secret_file]``
   Adds the the ``--secret-file`` option.

delete
-----------------------------------------------------
The following ``knife delete`` settings can be added to the knife.rb file:

``knife[:chef_repo_path]``
   Adds the the ``--chef-repo-path`` option.

``knife[:concurrency]``
   Adds the the ``--concurrency`` option.

``knife[:recurse]``
   Adds the the ``--recurse`` option.

``knife[:repo_mode]``
   Adds the the ``--repo-mode`` option.

deps
-----------------------------------------------------
The following ``knife deps`` settings can be added to the knife.rb file:

``knife[:chef_repo_path]``
   Adds the the ``--chef-repo-path`` option.

``knife[:concurrency]``
   Adds the the ``--concurrency`` option.

``knife[:recurse]``
   Adds the the ``--recurse`` option.

``knife[:remote]``
   Adds the the ``--remote`` option.

``knife[:repo_mode]``
   Adds the the ``--repo-mode`` option.

``knife[:tree]``
   Adds the the ``--tree`` option.

diff
-----------------------------------------------------
The following ``knife diff`` settings can be added to the knife.rb file:

``knife[:chef_repo_path]``
   Adds the the ``--chef-repo-path`` option.

``knife[:concurrency]``
   Adds the the ``--concurrency`` option.

``knife[:name_only]``
   Adds the the ``--name-only`` option.

``knife[:name_status]``
   Adds the the ``--name-status`` option.

``knife[:recurse]``
   Adds the the ``--recurse`` option.

``knife[:repo_mode]``
   Adds the the ``--repo-mode`` option.

download
-----------------------------------------------------
The following ``knife download`` settings can be added to the knife.rb file:

``knife[:chef_repo_path]``
   Adds the the ``--chef-repo-path`` option.

``knife[:concurrency]``
   Adds the the ``--concurrency`` option.

``knife[:recurse]``
   Adds the the ``--recurse`` option.

``knife[:repo_mode]``
   Adds the the ``--repo-mode`` option.

edit
-----------------------------------------------------
The following ``knife edit`` settings can be added to the knife.rb file:

``knife[:chef_repo_path]``
   Adds the the ``--chef-repo-path`` option.

``knife[:concurrency]``
   Adds the the ``--concurrency`` option.

``knife[:disable_editing]``
   Adds the the ``--disable-editing`` option.

``knife[:editor]``
   Adds the the ``--editor`` option.

``knife[:local]``
   Adds the the ``--local`` option.

``knife[:repo_mode]``
   Adds the the ``--repo-mode`` option.

environment create
-----------------------------------------------------
The following ``knife environment create`` settings can be added to the knife.rb file:

``knife[:description]``
   Adds the the ``--description`` option.

environment from file
-----------------------------------------------------
The following ``knife environment from file`` settings can be added to the knife.rb file:

``knife[:all]``
   Adds the the ``--all`` option.

``knife[:print_after]``
   Adds the the ``--print-after`` option.

exec
-----------------------------------------------------
The following ``knife exec`` settings can be added to the knife.rb file:

``knife[:exec]``
   Adds the the ``--exec`` option.

``knife[:script_path]``
   Adds the the ``--script-path`` option.

list
-----------------------------------------------------
The following ``knife list`` settings can be added to the knife.rb file:

``knife[:bare_directories]``
   Adds the the ``-d`` option.

``knife[:chef_repo_path]``
   Adds the the ``--chef-repo-path`` option.

``knife[:concurrency]``
   Adds the the ``--concurrency`` option.

``knife[:recursive]``
   Adds the the ``-R`` option.

``knife[:repo_mode]``
   Adds the the ``--repo-mode`` option.

node from file
-----------------------------------------------------
The following ``knife node from file`` settings can be added to the knife.rb file:

``knife[:print_after]``
   Adds the the ``--print-after`` option.

node list
-----------------------------------------------------
The following ``knife node list`` settings can be added to the knife.rb file:

``knife[:environment]``
   Adds the the ``--environment`` option.

node run list add
-----------------------------------------------------
The following ``knife node run list add`` settings can be added to the knife.rb file:

``knife[:after]``
   Adds the the ``--after`` option.

``knife[:run_list]``
   The run-list that is passed as part of the command itself.

node run list remove
-----------------------------------------------------
The following ``knife node run list remove`` settings can be added to the knife.rb file:

``knife[:run_list]``
   The run-list that is passed as part of the command itself.

raw
-----------------------------------------------------
The following ``knife raw`` settings can be added to the knife.rb file:

``knife[:chef_repo_path]``
   Adds the the ``--chef-repo-path`` option.

``knife[:concurrency]``
   Adds the the ``--concurrency`` option.

``knife[:input]``
   Adds the the ``--input`` option.

``knife[:method]``
   Adds the the ``--method`` option.

``knife[:pretty]``
   Adds the the ``--[no-]pretty`` option.

``knife[:repo_mode]``
   Adds the the ``--repo-mode`` option.

role create
-----------------------------------------------------
The following ``knife role create`` settings can be added to the knife.rb file:

``knife[:description]``
   Adds the the ``--description`` option.

role from file
-----------------------------------------------------
The following ``knife role from file`` settings can be added to the knife.rb file:

``knife[:print_after]``
   Adds the the ``--print-after`` option.

role show
-----------------------------------------------------
The following ``knife role show`` settings can be added to the knife.rb file:

``knife[:environment]``
   Adds the the ``--environment`` option.

ssh
-----------------------------------------------------
The following ``knife ssh`` settings can be added to the knife.rb file:

``knife[:concurrency]``
   Adds the the ``--concurrency`` option.

``knife[:identity_file]``
   Adds the the ``--identity-file`` option.

``knife[:host_key_verify]``
   Adds the the ``--[no-]host-key-verify`` option.

``knife[:manual]``
   Adds the the ``--manual-list`` option.

``knife[:ssh_attribute]``
   Adds the the ``--attribute`` option.

``knife[:ssh_gateway]``
   Adds the the ``--ssh-gateway`` option.

``knife[:ssh_password]``
   Adds the the ``--ssh-password`` option.

``knife[:ssh_port]``
   Adds the the ``--ssh-port`` option.

``knife[:ssh_user]``
   Adds the the ``--ssh-user`` option.

status
-----------------------------------------------------
The following ``knife status`` settings can be added to the knife.rb file:

``knife[:hide_healthy]``
   Adds the the ``--hide-healthy`` option.

``knife[:run_list]``
   Adds the the ``--run-list`` option.

``knife[:sort_reverse]``
   Adds the the ``--sort-reverse`` option.

upload
-----------------------------------------------------
The following ``knife upload`` settings can be added to the knife.rb file:

``knife[:chef_repo_path]``
   Adds the the ``--chef-repo-path`` option.

``knife[:concurrency]``
   Adds the the ``--concurrency`` option.

``knife[:recurse]``
   Adds the the ``--recurse`` option.

``knife[:repo_mode]``
   Adds the the ``--repo-mode`` option.

user create
-----------------------------------------------------
The following ``knife user create`` settings can be added to the knife.rb file:

``knife[:admin]``
   Adds the the ``--admin`` option.

``knife[:file]``
   Adds the the ``--file`` option.

``knife[:user_key]``
   Adds the the ``--user-key`` option.

``knife[:user_password]``
   Adds the the ``--password`` option.

user reregister
-----------------------------------------------------
The following ``knife user reregister`` settings can be added to the knife.rb file:

``knife[:file]``
   Adds the the ``--file`` option.

xargs
-----------------------------------------------------
The following ``knife delete`` settings can be added to the knife.rb file:

``knife[:chef_repo_path]``
   Adds the the ``--chef-repo-path`` option.

``knife[:concurrency]``
   Adds the the ``--concurrency`` option.

``knife[:diff]``
   Adds the the ``--diff`` option.

``knife[:dry_run]``
   Adds the the ``--dry-run`` option.

   New in Chef Client 12.0.

``knife[:force]``
   Adds the the ``--force`` option.

``knife[:local]``
   Adds the the ``--local`` option.

``knife[:max_arguments_per_command]``
   Adds the the ``--max-args`` option.

``knife[:max_command_line]``
   Adds the the ``--max-chars`` option.

``knife[:null_separator]``
   Adds the the ``-0`` option.

``knife[:patterns]``
   Adds the the ``--pattern`` option.

``knife[:replace_all]``
   Adds the the ``--replace`` option.

``knife[:replace_first]``
   Adds the the ``--replace-first`` option.

``knife[:repo_mode]``
   Adds the the ``--repo-mode`` option.

``knife[:verbose_commands]``
   Adds the the ``-t`` option.
