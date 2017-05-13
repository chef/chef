=====================================================
knife bootstrap
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_bootstrap.rst>`__

.. tag chef_client_bootstrap_node

A node is any physical, virtual, or cloud machine that is configured to be maintained by a chef-client. In order to bootstrap a node, you will first need a working installation of the :doc:`Chef software package </packages>`. A bootstrap is a process that installs the chef-client on a target system so that it can run as a chef-client and communicate with a Chef server. There are two ways to do this:

* Use the ``knife bootstrap`` subcommand to :doc:`bootstrap a node using the omnibus installer </install_bootstrap>`
* Use an unattended install to bootstrap a node from itself, without using SSH or WinRM

.. end_tag

.. tag knife_bootstrap_summary

Use the ``knife bootstrap`` subcommand to run a bootstrap operation that installs the chef-client on the target system. The bootstrap operation must specify the IP address or FQDN of the target system.

.. end_tag

.. note:: Starting with chef-client 12.0, use the :doc:`knife ssl_fetch </knife_ssl_fetch>` command to pull down the SSL certificates from the on-premises Chef server and add them to the ``/trusted_certs_dir`` on the workstation. These certificates are used during a ``knife bootstrap`` operation.

.. note:: To bootstrap the chef-client on Microsoft Windows machines, the :doc:`knife-windows </plugin_knife_windows>` plugins is required, which includes the necessary bootstrap scripts that are used to do the actual installation.

New in 12.6, ``-i IDENTITY_FILE``, ``--json-attribute-file FILE``, ``--sudo-preserve-home``.  Changed in 12.4, validatorless bootstrap requires ``-N node_name``. Changed in 12.1, ``knife-bootstrap`` has the options --bootstrap-vault-file, --bootstrap-vault-item, and --bootstrap-vault-json options to specifiy item stored in chef-vault. New in 12.0, ``--[no-]node-verify-api-cert``, ``--node-ssl-verify-mode PEER_OR_NONE``, ``-t TEMPLATE``, 

Syntax
=====================================================
.. tag knife_bootstrap_syntax

This subcommand has the following syntax:

.. code-block:: bash

   $ knife bootstrap FQDN_or_IP_ADDRESS (options)

.. end_tag

Options
=====================================================
.. note:: .. tag knife_common_see_common_options_link

          Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

          .. end_tag

.. tag knife_bootstrap_options

This subcommand has the following options:

``-A``, ``--forward-agent``
   Enable SSH agent forwarding.

``--bootstrap-curl-options OPTIONS``
   Arbitrary options to be added to the bootstrap command when using cURL. This option may not be used in the same command with ``--bootstrap-install-command``.

``--bootstrap-install-command COMMAND``
   Execute a custom installation command sequence for the chef-client. This option may not be used in the same command with ``--bootstrap-curl-options``, ``--bootstrap-install-sh``, or ``--bootstrap-wget-options``.

``--bootstrap-install-sh URL``
   Fetch and execute an installation script at the specified URL. This option may not be used in the same command with ``--bootstrap-install-command``.

``--bootstrap-no-proxy NO_PROXY_URL_or_IP``
   A URL or IP address that specifies a location that should not be proxied.

   .. note:: This option is used internally by Chef to help verify bootstrap operations during testing and should never be used during an actual bootstrap operation.

``--bootstrap-proxy PROXY_URL``
   The proxy server for the node that is the target of a bootstrap operation.

``--bootstrap-vault-file VAULT_FILE``
   The path to a JSON file that contains a list of vaults and items to be updated.

``--bootstrap-vault-item VAULT_ITEM``
   A single vault and item to update as ``vault:item``.

``--bootstrap-vault-json VAULT_JSON``
   A JSON string that contains a list of vaults and items to be updated.

   .. tag knife_bootstrap_vault_json

   For example:

   .. code-block:: none

      --bootstrap-vault-json '{ "vault1": ["item1", "item2"], "vault2": "item2" }'

   .. end_tag

``--bootstrap-version VERSION``
   The version of the chef-client to install.

``--bootstrap-wget-options OPTIONS``
   Arbitrary options to be added to the bootstrap command when using GNU Wget. This option may not be used in the same command with ``--bootstrap-install-command``.

``-E ENVIRONMENT``, ``--environment ENVIRONMENT``
   The name of the environment. When this option is added to a command, the command will run only against the named environment.

``-G GATEWAY``, ``--ssh-gateway GATEWAY``
   The SSH tunnel or gateway that is used to run a bootstrap action on a machine that is not accessible from the workstation.

``--hint HINT_NAME[=HINT_FILE]``
   An Ohai hint to be set on the target node.

   .. tag ohai_hints

   Ohai hints are used to tell Ohai something about the system that it is running on that it would not be able to discover itself. An Ohai hint exists if a JSON file exists in the hint directory with the same name as the hint. For example, calling ``hint?('antarctica')`` in an Ohai plugin would return an empty hash if the file ``antarctica.json`` existed in the hints directory, and return nil if the file does not exist.

   .. end_tag

   .. tag ohai_hints_json

   If the hint file contains JSON content, it will be returned as a hash from the call to ``hint?``.

   .. code-block:: javascript

      {
        "snow": true,
        "penguins": "many"
      }

   .. code-block:: ruby

      antarctica_hint = hint?('antarctica')
      if antarctica_hint['snow']
        "There are #{antarctica_hint['penguins']} penguins here."
      else
        'There is no snow here, and penguins like snow.'
      end

   The default directory in which hint files are located is ``/etc/chef/ohai/hints/``. Use the ``Ohai::Config[:hints_path]`` setting in the client.rb file to customize this location.

   .. end_tag

   ``HINT_FILE`` is the name of the JSON file. ``HINT_NAME`` is the name of a hint in a JSON file. Use multiple ``--hint`` options to specify multiple hints.

``-i IDENTITY_FILE``, ``--ssh-identity-file IDENTITY_FILE``
   The SSH identity file used for authentication. Key-based authentication is recommended.

   New in Chef Client 12.6.

``-j JSON_ATTRIBS``, ``--json-attributes JSON_ATTRIBS``
   A JSON string that is added to the first run of a chef-client.

``--json-attribute-file FILE``
   A JSON file to be added to the first run of chef-client.

   New in Chef Client 12.6.

``-N NAME``, ``--node-name NAME``
   The name of the node.

   .. note:: This option is required for a validatorless bootstrap (Changed in Chef Client 12.4).

``--[no-]fips``
  Allows OpenSSL to enforce FIPS-validated security during the chef-client run.

``--[no-]host-key-verify``
   Use ``--no-host-key-verify`` to disable host key verification. Default setting: ``--host-key-verify``.

``--[no-]node-verify-api-cert``
   Verify the SSL certificate on the Chef server. When ``true``, the chef-client always verifies the SSL certificate. When ``false``, the chef-client uses the value of ``ssl_verify_mode`` to determine if the SSL certificate requires verification. If this option is not specified, the setting for ``verify_api_cert`` in the configuration file is applied.

   New in Chef Client 12.0.

``--node-ssl-verify-mode PEER_OR_NONE``
   Set the verify mode for HTTPS requests.

   Use ``none`` to do no validation of SSL certificates.

   Use ``peer`` to do validation of all SSL certificates, including the Chef server connections, S3 connections, and any HTTPS **remote_file** resource URLs used in the chef-client run. This is the recommended setting.

   New in Chef Client 12.0.

``-p PORT``, ``--ssh-port PORT``
   The SSH port.

``-P PASSWORD``, ``--ssh-password PASSWORD``
   The SSH password. This can be used to pass the password directly on the command line. If this option is not specified (and a password is required) knife prompts for the password.

``--prerelease``
   Install pre-release gems.

``-r RUN_LIST``, ``--run-list RUN_LIST``
   A comma-separated list of roles and/or recipes to be applied.

``--secret SECRET``
   The encryption key that is used for values contained within a data bag item.

``--secret-file FILE``
   The path to the file that contains the encryption key.

``--sudo``
   Execute a bootstrap operation with sudo.

``--sudo-preserve-home``
   Use to preserve the non-root user's ``HOME`` environment.

   New in Chef Client 12.6.

``-t TEMPLATE``, ``--bootstrap-template TEMPLATE``
   The bootstrap template to use. This may be the name of a bootstrap template---``chef-full``, for example---or it may be the full path to an Embedded Ruby (ERB) template that defines a custom bootstrap. Default value: ``chef-full``, which installs the chef-client using the omnibus installer on all supported platforms.

   New in Chef Client 12.0.

``--use-sudo-password``
   Perform a bootstrap operation with sudo; specify the password with the ``-P`` (or ``--ssh-password``) option.

``-V -V``
   Run the initial chef-client run at the ``debug`` log-level (e.g. ``chef-client -l debug``).

``-x USERNAME``, ``--ssh-user USERNAME``
   The SSH user name.

.. end_tag

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Validatorless Bootstrap
-----------------------------------------------------
.. tag knife_bootstrap_no_validator

The ORGANIZATION-validator.pem is typically added to the .chef directory on the workstation. When a node is bootstrapped from that workstation, the ORGANIZATION-validator.pem is used to authenticate the newly-created node to the Chef server during the initial chef-client run. Starting with Chef client 12.1, it is possible to bootstrap a node using the USER.pem file instead of the ORGANIZATION-validator.pem file. This is known as a "validatorless bootstrap".

To create a node via the USER.pem file, simply delete the ORGANIZATION-validator.pem file on the workstation. For example:

.. code-block:: bash

   $ rm -f /home/lamont/.chef/myorg-validator.pem

and then make the following changes in the knife.rb file:

* Remove the ``validation_client_name`` setting
* Edit the ``validation_key`` setting to be something that isn't a path to an existent ORGANIZATION-validator.pem file. For example: ``/nonexist``.

As long as a USER.pem is also present on the workstation from which the validatorless bootstrap operation will be initiated, the bootstrap operation will run and will use the USER.pem file instead of the ORGANIZATION-validator.pem file.

When running a validatorless ``knife bootstrap`` operation, the output is similar to:

.. code-block:: bash

   desktop% knife bootstrap 10.1.1.1 -N foo01.acme.org \
     -E dev -r 'role[base]' -j '{ "foo": "bar" }' \
     --ssh-user vagrant --sudo
   Node foo01.acme.org exists, overwrite it? (Y/N)
   Client foo01.acme.org exists, overwrite it? (Y/N)
   Creating new client for foo01.acme.org
   Creating new node for foo01.acme.org
   Connecting to 10.1.1.1
   10.1.1.1 Starting first Chef Client run...
   [....etc...]

.. end_tag

New in Chef Client 12.1.

``knife bootstrap`` Options
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag chef_vault_knife_bootstrap_options

Use the following options with a validatorless bootstrap to specify items that are stored in chef-vault:

``--bootstrap-vault-file VAULT_FILE``
   The path to a JSON file that contains a list of vaults and items to be updated.

``--bootstrap-vault-item VAULT_ITEM``
   A single vault and item to update as ``vault:item``.

``--bootstrap-vault-json VAULT_JSON``
   A JSON string that contains a list of vaults and items to be updated.

   .. tag knife_bootstrap_vault_json

   For example:

   .. code-block:: none

      --bootstrap-vault-json '{ "vault1": ["item1", "item2"], "vault2": "item2" }'

   .. end_tag

.. end_tag

.. note:: The ``--node-name`` option is required for a validatorless bootstrap (Changed in Chef Client 12.4).

FIPS Mode
-----------------------------------------------------
.. tag fips_intro_client

Federal Information Processing Standards (FIPS) is a United States government computer security standard that specifies security requirements for cryptography. The current version of the standard is FIPS 140-2. The chef-client can be configured to allow OpenSSL to enforce FIPS-validated security during a chef-client run. This will disable cryptography that is explicitly disallowed in FIPS-validated software, including certain ciphers and hashing algorithms. Any attempt to use any disallowed cryptography will cause the chef-client to throw an exception during a chef-client run.

.. note:: Chef uses MD5 hashes to uniquely identify files that are stored on the Chef server. MD5 is used only to generate a unique hash identifier and is not used for any cryptographic purpose.

Notes about FIPS:

* May be enabled for nodes running on Microsoft Windows and Enterprise Linux platforms
* Should only be enabled for environments that require FIPS 140-2 compliance
* May not be enabled for any version of the chef-client earlier than 12.8

Changed in Chef server 12.13 to expose FIPS runtime flag on RHEL. New in Chef Client 12.8, support for OpenSSL validation of FIPS.

.. end_tag

**Bootstrap a node using FIPS**

.. tag knife_bootstrap_node_fips

.. To bootstrap a node:

.. code-block:: bash

   $ knife bootstrap 12.34.56.789 -P vanilla -x root -r 'recipe[apt],recipe[xfs],recipe[vim]' --fips

which shows something similar to:

.. code-block:: none

   OpenSSL FIPS 140 mode enabled
   ...
   12.34.56.789 Chef Client finished, 12/12 resources updated in 78.942455583 seconds

.. end_tag

Custom Templates
=====================================================
.. tag knife_bootstrap_template

The ``chef-full`` distribution uses the omnibus installer. For most bootstrap operations, regardless of the platform on which the target node is running, using the ``chef-full`` distribution is the best approach for installing the chef-client on a target node. In some situations, using another supported distribution is necessary. And in some situations, a custom template may be required.

For example, the default bootstrap operation relies on an Internet connection to get the distribution to the target node. If a target node cannot access the Internet, then a custom template can be used to define a specific location for the distribution so that the target node may access it during the bootstrap operation.

For example, a bootstrap template file named "sea_power":

.. code-block:: bash

   $ knife bootstrap 123.456.7.8 -x username -P password --sudo --bootstrap-template "sea_power"

The following examples show how a bootstrap template file can be customized for various platforms.

.. end_tag

Template Locations
-----------------------------------------------------
A custom bootstrap template file must be located in a ``bootstrap/`` directory, which is typically located within the ``~/.chef/`` directory on the local workstation.

Use the ``--bootstrap-template`` option with the ``knife bootstrap`` subcommand to specify the name of the bootstrap template file. This location is configurable when the following setting is added to the knife.rb file:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Setting
     - Description
   * - ``knife[:bootstrap_template]``
     - The path to a template file to be used during a bootstrap operation.

Ubuntu 14.04
-----------------------------------------------------
The following example shows how to modify the default script for Ubuntu 14.04. First, copy the bootstrap template from the default location. If the chef-client is installed from a RubyGems, the full path can be found in the gem contents. For example:

.. code-block:: bash

   $ gem contents chef | grep ubuntu14.04-gems
   /Users/grantmc/.rvm/gems/ruby-2.0/gems/chef-12.0.2/lib/chef/knife/bootstrap/ubuntu14.04-gems.erb

Copy the template to the chef-repo in the ``.chef/bootstrap`` directory:

.. code-block:: bash

   $ cp /Users/grantmc/.rvm/gems/ruby-2.0/gems/chef-12.0.2/
      lib/chef/knife/bootstrap/ubuntu14.04-gems.erb ~/chef-repo/.chef/
      bootstrap/ubuntu14.04-gems-mine.erb

Modify the template with any editor, then specify it using the ``--bootstrap-template`` option as part of the the ``knife bootstrap`` operation, or with any of the knife plug-ins that support cloud computing.

.. code-block:: bash

   $ knife bootstrap 192.168.1.100 -r 'role[webserver]' -bootstrap-template ubuntu14.04-gems-mine

Alternatively, an example bootstrap template can be found in the git source for the chef-repo: https://github.com/chef/chef/tree/master/lib/chef/knife/bootstrap. Copy the template to ``~/.chef-repo/.chef/bootstrap/ubuntu14.04-apt.erb`` and modify the template appropriately.

Debian and Apt
-----------------------------------------------------
The following example shows how to use the ``knife bootstrap`` subcommand to create a client configuration file (/etc/chef/client.rb) that uses Hosted Chef as the Chef server. The configuration file will look something like:

.. code-block:: ruby

   log_level        :info
   log_location     STDOUT
   chef_server_url  'https://api.opscode.com/organizations/NAME'
   validation_client_name 'ORGNAME-validator'

The ``knife bootstrap`` subcommand will look in three locations for the template that is used during the bootstrap operation. The locations are:

#. A bootstrap directory in the installed knife library; the actual location may vary, depending how the chef-client is installed
#. A bootstrap directory in the ``$PWD/.chef``, e.g. in ``~/chef-repo/.chef``
#. A bootstrap directory in the users ``$HOME/.chef``

If, in the example above, the second location was used, then create the ``.chef/bootstrap/`` directory in the chef-repo, and then create the Embedded Ruby (ERB) template file by running commands similar to the following:

.. code-block:: bash

   mkdir ~/.chef/bootstrap
   vi ~/.chef/bootstrap/debian6.0-apt.erb

When finished creating the directory and the Embedded Ruby (ERB) template file, edit the template to run the SSH commands. Then set up the validation certificate and the client configuration file.

Finally, run the chef-client on the node using a ``knife bootstrap`` command that specifies a run-list (the ``-r`` option). The bootstrap template can be called using a command similar to the following:

.. code-block:: bash

   $ knife bootstrap mynode.example.com -r 'role[webserver]','role[production]' --bootstrap-template debian6.0-apt

Microsoft Windows
-----------------------------------------------------
.. tag knife_bootstrap_example_windows

The following example shows how to modify the default script for Microsoft Windows and Windows PowerShell:

..   # Moved this license/header info out of the code sample; keeping it in the topic just because
..   @rem
..   @rem Author:: Seth Chisamore (<schisamo@opscode.com>)
..   @rem Author:: Michael Goetz (<mpgoetz@opscode.com>)
..   @rem Author:: Julian Dunn (<jdunn@opscode.com>)
..   @rem Copyright:: Copyright (c) 2011-2013 Opscode, Inc.
..   @rem License:: Apache License, Version 2.0
..   @rem
..   @rem Licensed under the Apache License, Version 2.0 (the "License");
..   @rem you may not use this file except in compliance with the License.
..   @rem You may obtain a copy of the License at
..   @rem
..   @rem     http://www.apache.org/licenses/LICENSE-2.0
..   @rem
..   @rem Unless required by applicable law or agreed to in writing, software
..   @rem distributed under the License is distributed on an "AS IS" BASIS,
..   @rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
..   @rem See the License for the specific language governing permissions and
..   @rem limitations under the License.
..   @rem

.. code-block:: bash

   @setlocal

   <%= "SETX HTTP_PROXY \"#{knife_config[:bootstrap_proxy]}\"" if knife_config[:bootstrap_proxy] %>
   @mkdir <%= bootstrap_directory %>

   > <%= bootstrap_directory %>\wget.ps1 (
    <%= win_wget_ps %>
   )

   :install
   @rem Install Chef using chef-client MSI installer

   <% url="http://reposerver.example.com/chef-client-12.0.2.windows.msi" -%>
   @set "REMOTE_SOURCE_MSI_URL=<%= url %>"
   @set "LOCAL_DESTINATION_MSI_PATH=<%= local_download_path %>"

   @powershell -ExecutionPolicy Unrestricted -NoProfile -NonInteractive "& '<%= bootstrap_directory %>\wget.ps1' '%REMOTE_SOURCE_MSI_URL%' '%LOCAL_DESTINATION_MSI_PATH%'"

   @REM Replace install_chef from knife-windows Gem with one that has extra flags to turn on Chef service feature -- only available in Chef >= 12.0.x
   @REM <%= install_chef %>
   @echo Installing Chef Client 12.0.2 with msiexec
   @msiexec /q /i "%LOCAL_DESTINATION_MSI_PATH%" ADDLOCAL="ChefClientFeature,ChefServiceFeature"
   @endlocal

   @echo Writing validation key...

   > <%= bootstrap_directory %>\validation.pem (
    <%= validation_key %>
   )

   @echo Validation key written.

   <% if @config[:encrypted_data_bag_secret] -%>
   > <%= bootstrap_directory %>\encrypted_data_bag_secret (
    <%= encrypted_data_bag_secret %>
   )
   <% end -%>

   > <%= bootstrap_directory %>\client.rb (
    <%= config_content %>
   )

   > <%= bootstrap_directory %>\first-boot.json (
    <%= run_list %>
   )

   <%= start_chef %>

.. end_tag

Examples
=====================================================
The following examples show how to use this knife subcommand:

**Bootstrap a node**

.. To bootstrap a node:

.. code-block:: bash

   $ knife bootstrap 12.34.56.789 -P vanilla -x root -r 'recipe[apt],recipe[xfs],recipe[vim]'

which shows something similar to:

.. code-block:: none

   ...
   12.34.56.789 Chef Client finished, 12/12 resources updated in 78.942455583 seconds

Use ``knife node show`` to verify:

.. code-block:: bash

   $ knife node show debian-wheezy.int.domain.org

which returns something similar to:

.. code-block:: none

   Node Name:   debian-wheezy.int.domain.org
   Environment: _default
   FQDN:        debian-wheezy.int.domain.org
   IP:          12.34.56.789
   Run List:    recipe[apt], recipe[xfs], recipe[vim]
   Roles:
   Recipes:     apt, xfs, vim, apt::default, xfs::default, vim::default
   Platform:    debian 7.4
   Tags:

**Use an SSH password**

.. To pass an SSH password as part of the command:

.. code-block:: bash

   $ knife bootstrap 192.168.1.1 -x username -P PASSWORD --sudo

**Use a file that contains a private key**

.. To use a file that contains a private key:

.. code-block:: bash

   $ knife bootstrap 192.168.1.1 -x username -i ~/.ssh/id_rsa --sudo

**Fetch and execute an installation script from a URL**

.. To fetch and execute an installation script from a URL:

.. code-block:: bash

   $ knife bootstrap --bootstrap-install-sh http://mycustomserver.com/custom_install_chef_script.sh

**Specify options when using cURL**

.. To specify options when using cURL:

.. code-block:: bash

   $ knife bootstrap --bootstrap-curl-options "--proxy http://myproxy.com:8080"

**Specify options when using GNU Wget**

.. To specify options when using GNU Wget:

.. code-block:: bash

   $ knife bootstrap --bootstrap-wget-options "-e use_proxy=yes -e http://myproxy.com:8080"

**Specify a custom installation command sequence**

.. To specify a custom installation command sequence:

.. code-block:: bash

   $ knife bootstrap --bootstrap-install-command "curl -l http://mycustomserver.com/custom_install_chef_script.sh | sudo bash -s --"
