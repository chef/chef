==================================================================
FIPS (Federal Information Processing Standards)
==================================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/fips.rst>`__

.. warning:: There is a known issue on the Windows platform that prevents FIPS usage. If this would affect you, please continue to use ChefDK 1.2.22 until we resolve this issue with a patch release.

What is FIPS?
==================================================================
.. tag fips_intro

Federal Information Processing Standards (FIPS) are federal standards for computer systems used by contractors of government agencies and non-military government agencies.

FIPS 140-2 is a specific federal government security standard used to approve cryptographic modules. Chef Automate uses the OpenSSL FIPS Object Module, which satisfies the requirements of software cryptographic modules under the FIPS 140-2 standard. The OpenSSL Object Module provides an API for invoking FIPS approved cryptographic functions from calling applications.

.. end_tag

Why would you want to enable it?
------------------------------------------------------------------
You may be legally required to enable FIPS if you are a United States non-military government agency, or are contracting with one. If you are not sure if you need to enable FIPS, please check with your compliance department.

Why might you not need to enable it?
------------------------------------------------------------------
You will only need to enable FIPS if you are a US non-military government agency, or contracting with one, and you are contractually obligated to meet federal government security standards.  If you are not a US non-military governmental agency, or you are not contracting with one, and you are not contractually obligated to meet federal government security standards, then do not enable FIPS.  Chef products have robust security standards even without FIPS, and FIPS prevents the use of certain hashing algorithms you might want to use, so we only recommend enabling FIPS if it is contractually necessary.

How to enable FIPS mode in the Operating System
==================================================================

FIPS kernel settings
------------------------------------------------------------------
Windows and Red Hat Enterprise Linux can both be configured for FIPS mode using a kernel-level setting. After FIPS mode is enabled at the kernel level, the operating system will only use FIPS approved algorithms and keys during operation.

All of the tools Chef produces that have FIPS support read this kernel setting and default their mode of operation to match it with the exception of the workstation, which requires designating a port in the ``fips_git_port`` setting of the ``cli.toml``.  For the other Chef tools, Chef Client, for example, if ``chef-client`` is run on an  operating system configured into FIPS mode and you run, that Chef run will automatically be in FIPS mode unless the user disables it.

To enable FIPS on your platform follow these instructions:

* `Red Hat Enterprise Linux 6 <https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Security_Guide/sect-Security_Guide-Federal_Standards_And_Regulations-Federal_Information_Processing_Standard.html>`_
* `Red Hat Enterprise Linux 7 <https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Security_Guide/chap-Federal_Standards_and_Regulations.html#sec-Enabling-FIPS-Mode>`_
* `Windows <https://technet.microsoft.com/en-us/library/cc750357.aspx>`_

How to enable FIPS mode for the Chef Server
==================================================================

Prerequisites
------------------------------------------------------------------
* Supported Systems - CentOS or Red Hat Enterprise Linux 6 or 7
* Chef Server version `12.13.0` or greater

Configuration
------------------------------------------------------------------
If you have FIPS compliance enabled at the kernel level and install or
reconfigure the Chef Server then it will default to running in FIPS mode.

To enable FIPS manually for the Chef Server, can add ``fips true`` to the
``chef-server.rb`` and reconfigure.  For more configuration information see `Chef
Server </config_rb_server_optional_settings.html>`_.

How to enable FIPS mode for the Chef client
==================================================================

Prerequisites
------------------------------------------------------------------
* Supported Systems - CentOS or Red Hat Enterprise Linux 6 or 7
* Chef Client ``12.19.36`` or greater

Configuration
------------------------------------------------------------------

If you have FIPS compliance enabled at the kernel level then chef-client will
default to running in FIPS mode. Otherwise you can add ``fips true`` to the
``/etc/chef/client.rb`` or ``C:\\chef\\client.rb``.

.. tag chef_client_fips_mode

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

.. tag delivery_cli_fips

How to enable FIPS mode for the Chef Automate server
==================================================================

Prerequisites
------------------------------------------------------------------
* Supported Systems - CentOS or Red Hat Enterprise Linux 6 or 7
* Chef Automate version ``0.7.100`` or greater

Configuration
------------------------------------------------------------------
If you have FIPS compliance enabled in the operating system at the kernel level
and install or reconfigure the Chef Automate server then it will default to
running in FIPS mode.

A Chef Automate server running in FIPS mode can only communicate with workstations that are
also running in FIPS mode.

If you do need to use FIPS mode, there are a few steps to get it up and running in Delivery CLI on your workstation.

Check if Chef Automate server has enabled FIPS mode
-----------------------------------------------------

You can see if your Chef Automate server is in FIPS mode by running ``delivery status``. It will say ``FIPS mode: enabled`` if it is enabled as well as output some instructions on how to set up
your ``cli.toml`` to enable FIPS mode locally. If ``delivery status`` reports either ``FIPS mode: disabled`` or FIPS is missing completely from the report, please see `FIPS kernel settings </fips.html#fips-kernel-settings>`_ on how to enable FIPS mode in your Chef Automate server before proceeding.

Enable FIPS mode in your cli.toml file
-----------------------------------------------------

Now that you have confirmed that the Chef Automate server is in FIPS mode, you must enable FIPS mode locally on your workstation for Delivery CLI.
This can be done by adding the following to your ``.delivery/cli.toml``:

.. code-block:: none

   fips = true
   fips_git_port = "OPEN_PORT"
   fips_custom_cert_filename = "/full/path/to/your/certificate-chain.pem" # optional

Replace ``OPEN_PORT`` with any port that is free locally on localhost.

If you are using a custom certificate authority or a self-signed certificate then you will need the third option. This file should contain to the entire certificate chain in `pem` format. See `FIPS Certificate Management </fips#certificate_management>`_ for an example on how to generate the file.

How to enable FIPS mode for workstations
==================================================================

A workstation is a computer running the Chef Development Kit (ChefDK) that is used to author cookbooks, interact with the Chef server, and interact with nodes.

Prerequisites
------------------------------------------------------------------
* Supported Systems - Windows, CentOS and Red Hat Enterprise Linux
* ChefDK version ``1.3.23`` or greater

Now that FIPS mode is enabled in your ``.delivery/cli.toml``, running any project-specific Delivery CLI command will automatically use FIPS-compliant encrypted git traffic between your
workstation and the Chef Automate server. As long as the Chef Automate server is in FIPS mode, no other action is needed on your part to operate Delivery CLI in FIPS mode.
If you ever stop using FIPS mode on the Chef Automate server, simply delete the above two lines from your ``.delivery/cli.toml`` file and Delivery CLI will stop running in FIPS mode.

.. note:: You could also pass ``--fips`` and ``--fips-git-port=OPEN_PORT`` into project specific commands if you do not wish to edit your ``.delivery/cli.toml``. See list of commands below for details..

.. end_tag

For more information on configuring the Chef Automate server, see `Delivery CLI </ctl_delivery.html>`_.

.. note:: If you set up any runners using an Chef Automate server version ``0.7.61`` or earlier, then you will need to re-run `automate-ctl install-runner </ctl_delivery_server.html#install-runner>`_ on every existing runner after upgrading your Chef Automate server. Your runners will not work with FIPS enabled without re-running the installer.



Architecture Overview
==================================================================

.. image:: ../../images/automate-fips.png
   :width: 600px
   :align: center


When Automate is running in FIPS mode, it uses stunnel to stand up encrypted tunnels between servers and clients to carry traffic generated by programs that do not support FIPS 140-2 validation, thus wrapping non-FIPS compliant traffic within a FIPS-compliant tunnel.
The stunnel is stood up  prior to a request and torn down thereafter.  Enabling FIPS in Chef Automate disables its git server and isolates it on localhost, where it listens for stunnel traffic over port 8989.

Certificate Management
==================================================================
If you are using a certificate purchased from a well-known certificate authority then no additional configuration should be required.

The well-known certificate authorities are those trusted by Mozilla and captured in a file known as cacert.pem, which can be referenced here: https://curl.haxx.se/docs/caextract.html

If you have a self-signed certificate or a customer certificate authority then you will need some additional steps to get your Automate stack configured.

.. note:: Any time this certificate changes you must re-run this process.

* Generate a pem file with your entire certificate chain of the Chef Automate instance and save it to a file. A client machine may run the above openssl command to avoid having to copy/paste the certificate chain around as well. For Example:

    .. code-block:: none

        $ echo "q" | openssl s_client -showcerts -connect yourautomateserver.com:443 </dev/null 2> /dev/null

        CONNECTED(00000003)
        ---
        Certificate chain
        0 s:/C=US/O=Acme/OU=Profit Center/CN=yourautomateserver.com
        i:/C=US/O=Acme/OU=Profit Center/CN=Root CA
        -----BEGIN CERTIFICATE-----
        (server certificate)
        -----END CERTIFICATE-----
        1 s:/C=US/O=Acme/OU=Profit Center/CN=Root CA
        i:/C=US/O=Acme/OU=Profit Center/CN=Root CA
        -----BEGIN CERTIFICATE-----
        (root certificate)
        -----END CERTIFICATE-----
        ---
        ...

    Create a new file ``yourautomateserver.com.pem`` and copy both of the certificate sections in order. In this example the file should look like:

    .. code-block:: none

        -----BEGIN CERTIFICATE-----
        (server certificate)
        -----END CERTIFICATE-----
        -----BEGIN CERTIFICATE-----
        (root certificate)
        -----END CERTIFICATE-----

* Every workstation will need a copy of this file and the cli.toml should be updated to include this configuration option.

    .. code-block:: none

        fips_custom_cert_filename = "/full/path/to/your/certificate-chain.pem"


* When configuring runners you'll need to include the file generated above as an argument to the `install-runner` command. See `Install Runner </ctl_delivery_server.html#install-runner>`_.

    .. code-block:: none

       $ automate-ctl install-runner [server fqdn] [ssh user] --fips-custom-cert-filename path/to/your/certificate-chain.pem [other options...]


Troubleshooting
==================================================================

If you experience configuration errors, check the Chef Automate configuration by running ``delivery status`` from any client machine. This command is further documented in `Check if Chef Automate has enabled FIPS mode </ctl_delivery.html#check-if-chef-automate-server-has-enabled-fips-mode>`_.

Running ``delivery status`` should return something like:

   .. code-block:: none

      Status information for Automate server automate-server.dev

      Status: up (request took 97 ms)
      Configuration Mode: standalone
      FIPS Mode: enabled
      Upstreams:
      Lsyncd:
         status: not_running
      PostgreSQL:
         status: up
      RabbitMQ:
         status: up
         node_health:
            status: up
         vhost_aliveness:
            status: up

      Your Automate Server is configured in FIPS mode.
      Please add the following to your cli.toml to enable Automate FIPS mode on your machine:

         fips = true
         fips_git_port = "OPEN_PORT"

         Replace OPEN_PORT with any port that is free on your machine.


Unable to run any delivery commands when FIPS is enabled
------------------------------------------------------------------
#. Confirm FIPS is enabled on Chef Automate with ``delivery status``. You should see ``FIPS Mode: enabled``.
#. Confirm your project's ``cli.toml`` is configured correctly. The following configuration items should be present:

    .. code-block:: none

        fips_enabled = true
        fips_git_port = "<some open port>"

        # Below is only used with self-signed certificates or custom certificate
        # authorities

        fips_custom_cert_filename = "/path/to/file/with/certificate-chain.pem"

#. On Windows you will need to kill the tunnel whenever you make a fips configuration change to ``cli.toml``. To restart the tunnel:

    .. code-block:: none

        PS C:\Users\user> tasklist /fi "imagename eq stunnel.exe"

        Image Name                     PID Session Name        Session#    Mem Usage
        ========================= ======== ================ =========== ============
        stunnel.exe                   2520 Console                    1      9,040 K

        PS C:\Users\user> taskkill 2520
        PS C:\Users\user\example-project> delivery review # will restart the tunnel on the next execution

Self-signed certificate or custom certificate authority
------------------------------------------------------------------
See the section on `Certificate Management </fips.html#certificate-management>`_.

Nothing above has helped
------------------------------------------------------------------
If you continue to have issues you should include the following logs with your support request:

#. Stunnel client log ``~/.chefdk/log/stunnel.log`` on your workstation
#. Stunnel server log ``sudo automate-ctl log stunnel``
#. Stunnel configuration file on your workstation ``C:\\opscode\\chefdk\\embedded\\stunnel.conf`` or ``~/.chefdk/etc/stunnel.conf``
