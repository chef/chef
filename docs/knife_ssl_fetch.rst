=====================================================
knife ssl_fetch
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_ssl_fetch.rst>`__

.. tag knife_ssl_fetch_summary

Use the ``knife ssl fetch`` subcommand to copy SSL certificates from an HTTPS server to the ``trusted_certs_dir`` directory that is used by knife and the chef-client to store trusted SSL certificates. When these certificates match the hostname of the remote server, running ``knife ssl fetch`` is the only step required to verify a remote server that is accessed by either knife or the chef-client.

.. warning:: It is the user's responsibility to verify the authenticity of every SSL certificate before downloading it to the ``/.chef/trusted_certs`` directory. knife will use any certificate in that directory as if it is a 100% trusted and authentic SSL certificate. knife will not be able to determine if any certificate in this directory has been tampered with, is forged, malicious, or otherwise harmful. Therefore it is essential that users take the proper steps before downloading certificates into this directory.

.. end_tag

Syntax
=====================================================
This subcommand has the following syntax:

.. code-block:: bash

   $ knife ssl fetch (options)

Options
=====================================================
This subcommand has the following options:

``URL_or_URI``
   The URL or URI for the location at which the SSL certificate is located. Default value: the URL for the Chef server, as defined in the knife.rb file.

Examples
=====================================================
The following examples show how to use this knife subcommand:

**Fetch the SSL certificates used by Knife from the Chef server**

.. code-block:: bash

   $ knife ssl fetch

The response is similar to:

.. code-block:: bash

   WARNING: Certificates from <chef_server_url> will be fetched and placed in your trusted_cert
   directory (/Users/grantmc/chef-repo/.chef/trusted_certs).

   Knife has no means to verify these are the correct certificates. You should
   verify the authenticity of these certificates after downloading.

   Adding certificate for <chef_server_url> in /Users/grantmc/chef-repo/.chef/trusted_certs/grantmc.crt
   Adding certificate for DigiCert Secure Server CA in /Users/grantmc/chef-repo/.chef/trusted_certs/DigiCert_Secure_Server_CA.crt

**Fetch SSL certificates from a URL or URI**

.. code-block:: bash

   $ knife ssl fetch https://www.example.com

**Verify Checksums**

.. tag knife_ssl_fetch_verify_certificate

The SSL certificate that is downloaded to the ``/.chef/trusted_certs`` directory should be verified to ensure that it is, in fact, the same certificate as the one located on the Chef server. This can be done by comparing the SHA-256 checksums.

#. View the checksum on the Chef server:

   .. code-block:: bash

      $ ssh ubuntu@chef-server.example.com sudo sha256sum /var/opt/opscode/nginx/ca/chef-server.example.com.crt

   The response is similar to:

   .. code-block:: bash

      <ABC123checksum>  /var/opt/opscode/nginx/ca/chef-server.example.com.crt

#. View the checksum on the workstation:

   .. code-block:: bash

      $ gsha256sum .chef/trusted_certs/chef-server.example.com.crt

   The response is similar to:

   .. code-block:: bash

      <ABC123checksum>  .chef/trusted_certs/chef-server.example.com.crt

#. Verify that the checksum values are identical.

.. end_tag

