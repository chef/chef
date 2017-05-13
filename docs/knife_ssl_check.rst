=====================================================
knife ssl check
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_ssl_check.rst>`__

.. tag knife_ssl_check_summary

Use the ``knife ssl check`` subcommand to verify the SSL configuration for the Chef server or a location specified by a URL or URI. Invalid certificates will not be used by OpenSSL.

When this command is run, the certificate files (``*.crt`` and/or ``*.pem``) that are located in the ``/.chef/trusted_certs`` directory are checked to see if they have valid X.509 certificate properties. A warning is returned when certificates do not have valid X.509 certificate properties or if the ``/.chef/trusted_certs`` directory does not contain any certificates.

.. warning:: When verification of a remote server's SSL certificate is disabled, the chef-client will issue a warning similar to "SSL validation of HTTPS requests is disabled. HTTPS connections are still encrypted, but the chef-client is not able to detect forged replies or man-in-the-middle attacks." To configure SSL for the chef-client, set ``ssl_verify_mode`` to ``:verify_peer`` (recommended) **or** ``verify_api_cert`` to ``true`` in the client.rb file.

.. end_tag

Changed in Chef Client 12.5 to support Server Name Indication (SNI).

Syntax
=====================================================
This subcommand has the following syntax:

.. code-block:: bash

   $ knife ssl check (options)

Options
=====================================================
This subcommand has the following options:

``URL_or_URI``
   The URL or URI for the location at which the SSL certificate is located. Default value: the URL for the Chef server, as defined in the knife.rb file.

Examples
=====================================================
The following examples show how to use this knife subcommand:

**SSL certificate has valid X.509 properties**

.. tag knife_ssl_check_verify_server_config

If the SSL certificate can be verified, the response to

.. code-block:: bash

   $ knife ssl check

is similar to:

.. code-block:: bash

   Connecting to host chef-server.example.com:443
   Successfully verified certificates from 'chef-server.example.com'

.. end_tag

**SSL certificate has invalid X.509 properties**

.. tag knife_ssl_check_bad_ssl_certificate

If the SSL certificate cannot be verified, the response to

.. code-block:: bash

   $ knife ssl check

is similar to:

.. code-block:: bash

   Connecting to host chef-server.example.com:443
   ERROR: The SSL certificate of chef-server.example.com could not be verified
   Certificate issuer data:
     /C=US/ST=WA/L=S/O=Corp/OU=Ops/CN=chef-server.example.com/emailAddress=you@example.com

   Configuration Info:

   OpenSSL Configuration:
   * Version: OpenSSL 1.0.1j 15 Oct 2014
   * Certificate file: /opt/chefdk/embedded/ssl/cert.pem
   * Certificate directory: /opt/chefdk/embedded/ssl/certs
   Chef SSL Configuration:
   * ssl_ca_path: nil
   * ssl_ca_file: nil
   * trusted_certs_dir: "/Users/grantmc/Downloads/chef-repo/.chef/trusted_certs"

   TO FIX THIS ERROR:

   If the server you are connecting to uses a self-signed certificate,
   you must configure chef to trust that certificate.

   By default, the certificate is stored in the following location on the
   host where your chef-server runs:

     /var/opt/opscode/nginx/ca/SERVER_HOSTNAME.crt

   Copy that file to your trusted_certs_dir (currently:

     /Users/grantmc/Downloads/chef-repo/.chef/trusted_certs)

   using SSH/SCP or some other secure method, then re-run this command to
   confirm that the certificate is now trusted.

.. end_tag

**Verify the SSL configuration for the chef-client**

The SSL certificates that are used by the chef-client may be verified by specifying the path to the client.rb file. Use the ``--config`` option (that is available to any knife command) to specify this path:

.. code-block:: bash

   $ knife ssl check --config /etc/chef/client.rb

**Verify an external server's SSL certificate**

.. code-block:: bash

   $ knife ssl check URL_or_URI

for example:

.. code-block:: bash

   $ knife ssl check https://www.chef.io
