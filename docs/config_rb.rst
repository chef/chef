=====================================================
config.rb
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/config_rb.rst>`__

.. warning:: The config.rb file is a replacement for the knife.rb file, starting with the chef-client 12.0 release. The config.rb file has identical settings and behavior to the knife.rb file. The chef-client will first look for the presence of the config.rb file and if it is not found, will look for the knife.rb file. If you are using the chef-client 11.x versions in your infrastructure, continue using the knife.rb file.

A ``config.rb`` file is used to specify chef-repo-specific configuration details.

* This file is loaded every time this executable is run
* The default location in which the chef-client expects to find this file is ``~/.chef/config.rb``; use the ``--config`` option from the command line to change this location
* This file is not created by default
* When a config.rb file is present in this directory, the settings contained within that file will override the default configuration settings

Settings
=====================================================
This configuration file has the following settings:

``bootstrap_template``
   The path to a template file to be used during a bootstrap operation.

``chef_server_url``
   The URL for the Chef server. For example:

   .. code-block:: ruby

      chef_server_url 'https://localhost/organizations/ORG_NAME'

``chef_zero.enabled``
   Enable chef-zero. This setting requires ``local_mode`` to be set to ``true``. Default value: ``false``. For example:

   .. code-block:: ruby

      chef_zero.enabled true

``chef_zero[:port]``
   The port on which chef-zero is to listen. Default value: ``8889``. For example:

   .. code-block:: ruby

      chef_zero[:port] 8889

``client_key``
   The location of the file that contains the client key. Default value: ``/etc/chef/client.pem``. For example:

   .. code-block:: ruby

      client_key '/etc/chef/client.pem'

``cookbook_copyright``
   The name of the copyright holder. This option places a copyright notice that contains the name of the copyright holder in each of the pre-created files. If this option is not specified, a copyright name of "COMPANY_NAME" is used instead; it can easily be modified later.

``cookbook_email``
   The email address for the individual who maintains the cookbook. This option places an email address in each of the pre-created files. If not specified, an email name of "YOUR_EMAIL" is used instead; this can easily be modified later.

``cookbook_license``
   The type of license under which a cookbook is distributed: ``apachev2``, ``gplv2``, ``gplv3``, ``mit``, or ``none`` (default). This option places the appropriate license notice in the pre-created files: ``Apache v2.0`` (for ``apachev2``), ``GPL v2`` (for ``gplv2``), ``GPL v3`` (for ``gplv3``), ``MIT`` (for ``mit``), or ``license 'Proprietary - All Rights Reserved`` (for ``none``). Be aware of the licenses for files inside of a cookbook and be sure to follow any restrictions they describe.

``cookbook_path``
   The sub-directory for cookbooks on the chef-client. This value can be a string or an array of file system locations, processed in the specified order. The last cookbook is considered to override local modifications. For example:

   .. code-block:: ruby

      cookbook_path [
        '/var/chef/cookbooks',
        '/var/chef/site-cookbooks'
      ]

``data_bag_encrypt_version``
   The minimum required version of data bag encryption. Possible values: ``1`` or ``2``. When all of the machines in an organization are running chef-client version 11.6 (or higher), it is recommended that this value be set to ``2``. For example:

   .. code-block:: ruby

      data_bag_encrypt_version 2

``local_mode``
   Run the chef-client in local mode. This allows all commands that work against the Chef server to also work against the local chef-repo. For example:

   .. code-block:: ruby

      local_mode true

``node_name``
   The name of the node. This is typically also the same name as the computer from which knife is run. For example:

   .. code-block:: ruby

      node_name 'node_name'

``no_proxy``
   A comma-separated list of URLs that do not need a proxy. Default value: ``nil``. For example:

   .. code-block:: ruby

      no_proxy 'localhost, 10.0.1.35, *.example.com, *.dev.example.com'

``ssl_verify_mode``
   Set the verify mode for HTTPS requests.

   * Use ``:verify_none`` to do no validation of SSL certificates.
   * Use ``:verify_peer`` to do validation of all SSL certificates, including the Chef server connections, S3 connections, and any HTTPS **remote_file** resource URLs used in the chef-client run. This is the recommended setting.

   Depending on how OpenSSL is configured, the ``ssl_ca_path`` may need to be specified. Default value: ``:verify_peer``.

``syntax_check_cache_path``
   All files in a cookbook must contain valid Ruby syntax. Use this setting to specify the location in which knife caches information about files that have been checked for valid Ruby syntax.

``validation_client_name``
   The name of the chef-validator key that is used by the chef-client to access the Chef server during the initial chef-client run. For example:

   .. code-block:: ruby

      validation_client_name 'chef-validator'

``validation_key``
   The location of the file that contains the key used when a chef-client is registered with a Chef server. A validation key is signed using the ``validation_client_name`` for authentication. Default value: ``/etc/chef/validation.pem``. For example:

   .. code-block:: ruby

      validation_key '/etc/chef/validation.pem'

``verify_api_cert``
   Verify the SSL certificate on the Chef server. When ``true``, the chef-client always verifies the SSL certificate. When ``false``, the chef-client uses the value of ``ssl_verify_mode`` to determine if the SSL certificate requires verification. Default value: ``false``.

``versioned_cookbooks``
   Append cookbook versions to cookbooks. Set to ``false`` to hide cookbook versions: ``cookbooks/apache``. Set to ``true`` to show cookbook versions: ``cookbooks/apache-1.0.0`` and/or ``cookbooks/apache-1.0.1``. When this setting is ``true``, ``knife download`` downloads ALL cookbook versions, which can be useful if a full-fidelity backup of data on the Chef server is required. For example:

   .. code-block:: ruby

      versioned_cookbooks true

``config_log_level``
   New in Chef DK 1.2.
   Sets the default value of ``log_level`` in the client.rb file of the node being bootstrapped. Possible values are ``:debug``, ``:info``, ``:warn``, ``:error`` and ``:fatal``. For example:

   .. code-block:: ruby

      config_log_level :debug

``config_log_location``
   New in Chef DK 1.2.
   Sets the default value of ``log_location`` in the client.rb file of the node being bootstrapped. Possible values are ``/path/to/log_location``, ``STDOUT``, ``STDERR``, ``:win_evt`` and ``:syslog``. For example:

   .. code-block:: ruby

      config_log_location "/path/to/log_location"   # Please make sure that the path exists

Proxy Settings
-----------------------------------------------------
.. tag config_rb_knife_settings_proxy

In certain situations the proxy used by the Chef server requires authentication. In this situation, three settings must be added to the configuration file. Which settings to add depends on the protocol used to access the Chef server: HTTP or HTTPS.

If the Chef server is configured to use HTTP, add the following settings:

``http_proxy``
   The proxy server for HTTP connections. Default value: ``nil``. For example:

   .. code-block:: ruby

      http_proxy 'http://proxy.vmware.com:3128'

``http_proxy_user``
   The user name for the proxy server when the proxy server is using an HTTP connection. Default value: ``nil``.

``http_proxy_pass``
   The password for the proxy server when the proxy server is using an HTTP connection. Default value: ``nil``.

If the Chef server is configured to use HTTPS (such as the hosted Chef server), add the following settings:

``https_proxy``
   The proxy server for HTTPS connections. (The hosted Chef server uses an HTTPS connection.) Default value: ``nil``.

``https_proxy_user``
   The user name for the proxy server when the proxy server is using an HTTPS connection. Default value: ``nil``.

``https_proxy_pass``
   The password for the proxy server when the proxy server is using an HTTPS connection. Default value: ``nil``.

Use the following setting to specify URLs that do not need a proxy:

``no_proxy``
   A comma-separated list of URLs that do not need a proxy. Default value: ``nil``.

.. end_tag

.d Directories
=====================================================
.. tag config_rb_client_dot_d_directories

The chef-client supports reading multiple configuration files by putting them inside a ``.d`` configuration directory. For example: ``/etc/chef/client.d``. All files that end in ``.rb`` in the ``.d`` directory are loaded; other non-``.rb`` files are ignored.

``.d`` directories may exist in any location where the ``client.rb``, ``config.rb``, or ``solo.rb`` files are present, such as:

* ``/etc/chef/client.d``
* ``/etc/chef/config.d``
* ``~/chef/solo.d``

(There is no support for a ``knife.d`` directory; use ``config.d`` instead.)

For example, when using knife, the following configuration files would be loaded:

* ``~/.chef/config.rb``
* ``~/.chef/config.d/company_settings.rb``
* ``~/.chef/config.d/ec2_configuration.rb``
* ``~/.chef/config.d/old_settings.rb.bak``

The ``old_settings.rb.bak`` file is ignored because it's not a configuration file. The ``config.rb``, ``company_settings.rb``, and ``ec2_configuration`` files are merged together as if they are a single configuration file.

.. note:: If multiple configuration files exists in a ``.d`` directory, ensure that the same setting has the same value in all files.

New in Chef Client 12.8.

.. end_tag

Optional Settings
=====================================================
In addition to the default settings in a config.rb file, there are other subcommand-specific settings that can be added:

#. A value passed via the command-line
#. A value contained in the config.rb file
#. The default value

A value passed via the command line will override a value in the config.rb file; a value in a config.rb file will override a default value.
