=====================================================
knife windows
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/plugin_knife_windows.rst>`__

.. tag plugin_knife_windows_summary

The ``knife windows`` subcommand is used to configure and interact with nodes that exist on server and/or desktop machines that are running Microsoft Windows. Nodes are configured using WinRM, which allows native objects---batch scripts, Windows PowerShell scripts, or scripting library variables---to be called by external applications. The ``knife windows`` subcommand supports NTLM and Kerberos methods of authentication.

.. end_tag

.. note:: Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

Install this plugin
=====================================================
.. tag plugin_knife_windows_install_rubygem

To install the ``knife windows`` plugin using RubyGems, run the following command:

.. code-block:: bash

   $ /opt/chef/embedded/bin/gem install knife-windows

where ``/opt/chef/embedded/bin/`` is the path to the location where the chef-client expects knife plugins to be located. If the chef-client was installed using RubyGems, omit the path in the previous example.

.. end_tag

Requirements
=====================================================
.. tag plugin_knife_windows_winrm_requirements

This subcommand requires WinRM to be installed, and then configured correctly, including ensuring the correct ports are open. For more information, see: http://msdn.microsoft.com/en-us/library/aa384372(v=vs.85).aspx and/or http://support.microsoft.com/kb/968930. Use the quick configuration option in WinRM to allow outside connections and the entire network path from knife (and the workstation):

.. code-block:: bash

   $ winrm quickconfig -q

The following WinRM configuration settings should be updated:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Setting
     - Description
   * - ``MaxMemoryPerShellMB``
     - The chef-client and Ohai typically require more memory than the default setting allows. Increase this value to ``300MB``. Only required on Windows Server 2008 R2 Standard and older. The default in Windows Server 2012 was increased to ``1024MB``.
   * - ``MaxTimeoutms``
     - A bootstrap command can take longer than allowed by the default setting. Increase this value to ``1800000`` (30 minutes).
   * - ``AllowUnencrypted``
     - Set this value to ``true`` for development and testing purposes.
   * - ``Basic``
     - Set this value to ``true`` for development and testing purposes. The ``knife windows`` subcommand supports Kerberos and Basic authentication schemes.

To update these settings, run the following commands:

.. code-block:: bash

   $ winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="300"}'

and:

.. code-block:: bash

   $ winrm set winrm/config '@{MaxTimeoutms="1800000"}'

and:

.. code-block:: bash

   $ winrm set winrm/config/service '@{AllowUnencrypted="true"}'

and then:

.. code-block:: bash

   $ winrm set winrm/config/service/auth '@{Basic="true"}'

Ensure that the Windows Firewall is configured to allow WinRM connections between the workstation and the Chef server. For example:

.. code-block:: bash

   $ netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" profile=public protocol=tcp localport=5985 remoteip=localsubnet new remoteip=any

.. end_tag

Negotiate, NTLM
-----------------------------------------------------
.. tag plugin_knife_windows_winrm_requirements_nltm

When knife is executed from a Microsoft Windows system, it is no longer necessary to make additional configuration of the WinRM listener on the target node to enable successful authentication from the workstation. It is sufficient to have a WinRM listener on the remote node configured to use the default configuration for ``winrm quickconfig``. This is because ``knife windows`` supports the Microsoft Windows negotiate protocol, including NTLM authentication, which matches the authentication requirements for the default configuration of the WinRM listener.

.. note:: To use Negotiate or NTLM to authenticate as the user specified by the ``--winrm-user`` option, include the user's Microsoft Windows domain, using the format ``domain\user``, where the backslash (``\``) separates the domain from the user.

For example:

.. code-block:: bash

   $ knife bootstrap windows winrm web1.cloudapp.net -r 'server::web' -x 'proddomain\webuser' -P 'password'

and:

.. code-block:: bash

   $ knife bootstrap windows winrm db1.cloudapp.net -r 'server::db' -x '.\localadmin' -P 'password'

.. end_tag

Domain Authentication
=====================================================
.. tag plugin_knife_windows_winrm_domain_authentication

The ``knife windows`` plugin supports Microsoft Windows domain authentication. This requires:

* An SSL certificate on the target node
* The certificate details can be viewed and its `thumbprint hex values copied <http://msdn.microsoft.com/en-us/library/ms788967.aspx>`_

To create the listener over HTTPS, run the following command:

.. code-block:: bash

   $ winrm create winrm/config/Listener?Address=IP:<ip_address>+Transport=HTTPS @{Hostname="<fqdn>";CertificateThumbprint="<hexidecimal_thumbprint_value>"}

where the ``CertificateThumbprint`` is the thumbprint hex value copied from the certificate details. (The hex value may require that spaces be removed before passing them to the node using the ``knife windows`` plugin.) WinRM 2.0 uses port ``5985`` for HTTP and port ``5986`` for HTTPS traffic, by default.

To bootstrap the target node using the ``knife bootstrap`` subcommand, first use the ``winrm`` argument in the ``knife windows`` plugin to verify communication with the node:

.. code-block:: bash

   $ knife winrm 'node1.domain.com' 'dir' -m -x domain\\administrator -P 'super_secret_password' –p 5986

and then run a command similar to the following:

.. code-block:: bash

   $ knife bootstrap windows winrm 'node1.domain.com' -r 'role[webserver]' -x domain\\administrator -P 'password' -p 5986

.. end_tag

bootstrap windows ssh
=====================================================
.. tag plugin_knife_windows_bootstrap_windows_ssh

Use the ``bootstrap windows ssh`` argument to bootstrap chef-client installations in a Microsoft Windows environment, using a command shell that is native to Microsoft Windows.

.. end_tag

Syntax
-----------------------------------------------------
.. tag plugin_knife_windows_bootstrap_windows_ssh_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife bootstrap windows ssh (options)

.. end_tag

.. warning:: .. tag knife_common_windows_ampersand

             When running knife in Microsoft Windows, an ampersand (``&``) is a special character and must be protected by quotes when it appears in a command. The number of quotes to use depends on the shell from which the command is being run.

             When running knife from the command prompt, an ampersand should be surrounded by quotes (``"&"``). For example:

             .. code-block:: bash

                $ knife bootstrap windows winrm -P "&s0meth1ng"

             When running knife from Windows PowerShell, an ampersand should be surrounded by triple quotes (``"""&"""``). For example:

             .. code-block:: bash

                $ knife bootstrap windows winrm -P """&s0meth1ng"""

             .. end_tag

Options
-----------------------------------------------------
.. tag plugin_knife_windows_bootstrap_windows_ssh_options

This argument has the following options:

``--auth-timeout MINUTES``,
   The amount of time (in minutes) to wait for authentication to succeed. Default: ``2``.

``--bootstrap-no-proxy NO_PROXY_URL_or_IP``
   A URL or IP address that specifies a location that should not be proxied.

``--bootstrap-proxy PROXY_URL``
   The proxy server for the node that is the target of a bootstrap operation.

``--bootstrap-version VERSION``
   The version of the chef-client to install.

``-d DISTRO``, ``--distro DISTRO``
   .. tag knife_bootstrap_distro

   The template file to be used during a bootstrap operation. The following distributions are supported:

   * ``chef-full`` (the default bootstrap)
   * ``centos5-gems``
   * ``fedora13-gems``
   * ``ubuntu10.04-gems``
   * ``ubuntu10.04-apt``
   * ``ubuntu12.04-gems``
   * The name of a custom bootstrap template file.

   When this option is used, knife searches for the template file in the following order:

   #. The ``bootstrap/`` folder in the current working directory
   #. The ``bootstrap/`` folder in the chef-repo
   #. The ``bootstrap/`` folder in the ``~/.chef/`` directory
   #. A default bootstrap file.

   Do not use the ``--template-file`` option when ``--distro`` is specified.

   .. end_tag

   Deprecated in Chef Client 12.0.

``-G GATEWAY``, ``--ssh-gateway GATEWAY``
   The SSH tunnel or gateway that is used to run a bootstrap action on a machine that is not accessible from the workstation.

``-i IDENTITY_FILE``, ``--identity-file IDENTITY_FILE``
   The SSH identity file used for authentication. Key-based authentication is recommended.

``-j JSON_ATTRIBS``, ``--json-attributes JSON_ATTRIBS``
   A JSON string that is added to the first run of a chef-client.

``-N NAME``, ``--node-name NAME``
   The name of the node.

``--[no-]host-key-verify``
   Use ``--no-host-key-verify`` to disable host key verification. Default setting: ``--host-key-verify``.

``-p PORT``, ``--ssh-port PORT``
   The SSH port.

``-P PASSWORD``, ``--ssh-password PASSWORD``
   The SSH password. This can be used to pass the password directly on the command line. If this option is not specified (and a password is required) knife prompts for the password.

``--prerelease``
   Install pre-release gems.

``-r RUN_LIST``, ``--run-list RUN_LIST``
   A comma-separated list of roles and/or recipes to be applied.

``-s SECRET``, ``--secret``
   The encryption key that is used for values contained within a data bag item.

``--secret-file SECRET_FILE``
   The path to the file that contains the encryption key.

``--template-file TEMPLATE``
   The path to a template file to be used during a bootstrap operation.

   Deprecated in Chef Client 12.0.

``-x USER_NAME``, ``--ssh-user USER_NAME``
   The SSH user name.

.. end_tag

bootstrap windows winrm
=====================================================
Use the ``bootstrap windows winrm`` argument to bootstrap chef-client installations in a Microsoft Windows environment, using WinRM and the WS-Management protocol for communication. This argument requires the FQDN of the host machine to be specified. The Microsoft Installer Package (MSI) run silently during the bootstrap operation (using the ``/qn`` option).

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife bootstrap windows winrm FQDN

.. warning:: .. tag knife_common_windows_ampersand

             When running knife in Microsoft Windows, an ampersand (``&``) is a special character and must be protected by quotes when it appears in a command. The number of quotes to use depends on the shell from which the command is being run.

             When running knife from the command prompt, an ampersand should be surrounded by quotes (``"&"``). For example:

             .. code-block:: bash

                $ knife bootstrap windows winrm -P "&s0meth1ng"

             When running knife from Windows PowerShell, an ampersand should be surrounded by triple quotes (``"""&"""``). For example:

             .. code-block:: bash

                $ knife bootstrap windows winrm -P """&s0meth1ng"""

             .. end_tag

Options
-----------------------------------------------------
This argument has the following options:

``--auth-timeout MINUTES``,
   The amount of time (in minutes) to wait for authentication to succeed. Default: ``2``.

``--bootstrap-no-proxy NO_PROXY_URL_or_IP``
   A URL or IP address that specifies a location that should not be proxied.

``--bootstrap-proxy PROXY_URL``
   The proxy server for the node that is the target of a bootstrap operation.

``--bootstrap-version VERSION``
   The version of the chef-client to install.

``-d DISTRO``, ``--distro DISTRO``
   .. tag knife_bootstrap_distro

   The template file to be used during a bootstrap operation. The following distributions are supported:

   * ``chef-full`` (the default bootstrap)
   * ``centos5-gems``
   * ``fedora13-gems``
   * ``ubuntu10.04-gems``
   * ``ubuntu10.04-apt``
   * ``ubuntu12.04-gems``
   * The name of a custom bootstrap template file.

   When this option is used, knife searches for the template file in the following order:

   #. The ``bootstrap/`` folder in the current working directory
   #. The ``bootstrap/`` folder in the chef-repo
   #. The ``bootstrap/`` folder in the ``~/.chef/`` directory
   #. A default bootstrap file.

   Do not use the ``--template-file`` option when ``--distro`` is specified.

   .. end_tag

   Deprecated in Chef Client 12.0

``--install-as-service``
   Indicates the client should be installed as a Windows Service.

``-j JSON_ATTRIBS``, ``--json-attributes JSON_ATTRIBS``
   A JSON string that is added to the first run of a chef-client.

``-N NAME``, ``--node-name NAME``
   The name of the node.

``--prerelease``
   Install pre-release gems.

``-r RUN_LIST``, ``--run-list RUN_LIST``
   A comma-separated list of roles and/or recipes to be applied.

``-s SECRET``, ``--secret``
   The encryption key that is used for values contained within a data bag item.

``--secret-file SECRET_FILE``
   The path to the file that contains the encryption key.

``--template-file TEMPLATE``
   The path to a template file to be used during a bootstrap operation.

cert generate
=====================================================
Use the ``cert generate`` argument to generate certificates for use with WinRM SSL listeners. This argument also generates a related public key file (in .pem format) to validate communication between listeners that are configured to use the generated certificate.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife windows cert generate FILE_PATH (options)

Options
-----------------------------------------------------
This argument has the following options:

``-cp PASSWORD``, ``--cert-passphrase PASSWORD``
   The password for the SSL certificate.

``-cv MONTHS``, ``--cert-validity MONTHS``
   The number of months for which a certificate is valid. Default value: ``24``.

``-h HOST_NAME``, ``--hostname HOST_NAME``
   The hostname for the listener. For example, ``--hostname something.mydomain.com`` or ``*.mydomain.com``. Default value: ``*``.

``-k LENGTH``, ``--key-length LENGTH``
   The length of the key. Default value: ``2048``.

``-o PATH``, ``--output-file PATH``
   The location in which the ``winrmcert.b64``, ``winrmcert.pem``, and ``winrmcert.pfx`` files are generated. For example: ``--output-file /home/.winrm/server_cert`` will create ``server_cert.b64``, ``server_cert.pem``, and ``server_cert.pfx`` in the ``server_cert`` directory. Default location: ``current_directory/winrmcert``.

cert install
=====================================================
Use the ``cert install`` argument to install a certificate (such as one generated by the ``cert generate`` argument) into the Microsoft Windows certificate store so that it may be used as the SSL certificate by a WinRM listener.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife windows cert install CERT [CERT] (options)

Options
-----------------------------------------------------
This argument has the following options:

``-cp PASSWORD``, ``--cert-passphrase PASSWORD``
   The password for the SSL certificate.

listener create
=====================================================
Use the ``listener create`` argument to create a WinRM listener on the Microsoft Windows platform.

.. note:: This command may only be used on the Microsoft Windows platform.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife windows listener create (options)

Options
-----------------------------------------------------
This argument has the following options:

``-c CERT_PATH``, ``--cert-install CERT_PATH``
   Add the specified certificate to the store before creating the listener.

``-cp PASSWORD``, ``--cert-passphrase PASSWORD``
   The password for the SSL certificate.

``-h HOST_NAME``, ``--hostname HOST_NAME``
   The hostname for the listener. For example, ``--hostname something.mydomain.com`` or ``*.mydomain.com``. Default value: ``*``.

``-p PORT``, ``--port PORT``
   The WinRM port. Default value: ``5986``.

``-t THUMBPRINT``, ``--cert-thumbprint THUMBPRINT``
   The thumbprint of the SSL certificate. Required when the ``--cert-install`` option is not part of a command.

winrm
=====================================================
.. tag plugin_knife_windows_winrm

Use the ``winrm`` argument to create a connection to one or more remote machines. As each connection is created, a password must be provided. This argument uses the same syntax as the ``search`` subcommand.

.. end_tag

.. tag plugin_knife_windows_winrm_ports

WinRM requires that a target node be accessible via the ports configured to support access via HTTP or HTTPS.

.. end_tag

Syntax
-----------------------------------------------------
.. tag plugin_knife_windows_winrm_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife winrm SEARCH_QUERY SSH_COMMAND (options)

.. end_tag

Options
-----------------------------------------------------
.. tag plugin_knife_windows_winrm_options

This argument has the following options:

``-a ATTR``, ``--attribute ATTR``
   The attribute used when opening an SSH connection. The default attribute is the FQDN of the host. Other possible values include a public IP address, a private IP address, or a hostname.

``-f CA_TRUST_FILE``, ``--ca-trust-file CA_TRUST_FILE``
   Optional. The certificate authority (CA) trust file used for SSL transport.

``-C NUM``, ``--concurrency NUM``
   Changed in knife-windows 1.9.0.
   The number of allowed concurrent connections. Defaults to 1.

``-i IDENTITY_FILE``, ``--identity-file IDENTITY_FILE``
   The keytab file that contains the encryption key required by Kerberos-based authentication.

``--keytab-file KEYTAB_FILE``
   The keytab file that contains the encryption key required by Kerberos-based authentication.

``-m``, ``--manual-list``
   Define a search query as a space-separated list of servers.

``-p PORT``, ``--winrm-port PORT``
   The WinRM port. The TCP port on the remote system to which ``knife windows`` commands that are made using WinRM are sent. Default: ``5986`` when ``--winrm-transport`` is set to ``ssl``, otherwise ``5985``.

``-P PASSWORD``, ``--winrm-password PASSWORD``
   The WinRM password.

``-R KERBEROS_REALM``, ``--kerberos-realm KERBEROS_REALM``
   Optional. The administrative domain to which a user belongs.

``--returns CODES``
   A comma-delimited list of return codes that indicate the success or failure of the command that was run remotely.

``-S KERBEROS_SERVICE``, ``--kerberos-service KERBEROS_SERVICE``
   Optional. The service principal used during Kerberos-based authentication.

``SEARCH_QUERY``
   The search query used to return a list of servers to be accessed using SSH and the specified ``SSH_COMMAND``. This option uses the same syntax as the search subcommand.

``SSH_COMMAND``
   The command to be run against the results of a search query.

``--session-timeout MINUTES``
   The amount of time (in minutes) for the maximum length of a WinRM session.

``-t TRANSPORT``, ``--winrm-transport TRANSPORT``
   The WinRM transport type. Possible values: ``ssl`` or ``plaintext``.

``--winrm-authentication-protocol PROTOCOL``
   The authentication protocol to be used during WinRM communication. Possible values: ``basic``, ``kerberos`` or ``negotiate``. Default value: ``negotiate``.

``--winrm-ssl-verify-mode MODE``
   The peer verification mode that is used during WinRM communication. Possible values: ``verify_none`` or ``verify_peer``. Default value: ``verify_peer``.

``-x USERNAME``, ``--winrm-user USERNAME``
   The WinRM user name.

.. end_tag

Examples
=====================================================

**Find Uptime for Web Servers**

.. tag plugin_knife_windows_winrm_find_uptime

To find the uptime of all web servers, enter:

.. code-block:: bash

   $ knife winrm "role:web" "net stats srv" -x Administrator -P password

.. end_tag

**Force a chef-client run**

.. tag plugin_knife_windows_winrm_force_chef_run

To force a chef-client run:

.. code-block:: bash

   knife winrm 'ec2-50-xx-xx-124.amazonaws.com' 'chef-client -c c:/chef/client.rb' -m -x admin -P 'password'
   ec2-50-xx-xx-124.amazonaws.com [date] INFO: Starting Chef Run (Version 0.9.12)
   ec2-50-xx-xx-124.amazonaws.com [date] WARN: Node ip-0A502FFB has an empty run list.
   ec2-50-xx-xx-124.amazonaws.com [date] INFO: Chef Run complete in 4.383966 seconds
   ec2-50-xx-xx-124.amazonaws.com [date] INFO: cleaning the checksum cache
   ec2-50-xx-xx-124.amazonaws.com [date] INFO: Running report handlers
   ec2-50-xx-xx-124.amazonaws.com [date] INFO: Report handlers complete

Where in the examples above, ``[date]`` represents the date and time the long entry was created. For example: ``[Fri, 04 Mar 2011 22:00:53 +0000]``.

.. end_tag

**Bootstrap a Windows machine using SSH**

.. tag plugin_knife_windows_bootstrap_ssh

To bootstrap a Microsoft Windows machine using SSH:

.. code-block:: bash

   $ knife bootstrap windows ssh ec2-50-xx-xx-124.compute-1.amazonaws.com -r 'role[webserver],role[production]' -x Administrator -i ~/.ssh/id_rsa

.. end_tag

**Bootstrap a Windows machine using Windows Remote Management**

.. tag plugin_knife_windows_bootstrap_winrm

To bootstrap a Microsoft Windows machine using WinRM:

.. code-block:: bash

   $ knife bootstrap windows winrm ec2-50-xx-xx-124.compute-1.amazonaws.com -r 'role[webserver],role[production]' -x Administrator -P 'super_secret_password'

.. end_tag

**Generate an SSL certificate, and then create a listener**

Use the ``listener create``, ``cert generate``, and ``cert install`` arguments to create a new listener and assign it a newly-generated SSL certificate. First, make sure that WinRM is enabled on the machine:

.. code-block:: bash

   $ winrm quickconfig

Create the SSL certificate

.. code-block:: bash

   $ knife windows cert generate --domain myorg.org --output-file $env:userprofile/winrmcerts/winrm-ssl

This command may be run on any machine and will output three file types: ``.b64``, ``.pem``, and ``.pfx``.

Next, create the SSL listener:

.. code-block:: bash

   $ knife windows listener create --hostname *.myorg.org --cert-install $env:userprofile/winrmcerts/winrm-ssl.pfx

This will use the same ``.pfx`` file that was output by the ``cert generate`` argument. If the command is run on a different machine from that which generated the certificates, the required certificate files must first be transferred securely to the system on which the listener will be created. (Use the ``cert install`` argument to install a certificate on a machine.)

The SSL listener is created and should be listening on TCP port ``5986``, which is the default WinRM SSL port.
