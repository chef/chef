=====================================================
About Proxies
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/proxies.rst>`__

In an environment that requires proxies to reach the Internet, many Chef commands will not work until they are configured correctly. To configure Chef to work in an environment that requires proxies, set the ``http_proxy``, ``https_proxy``, ``ftp_proxy``, and/or ``no_proxy`` environment variables to specify the proxy settings using a lowercase value.

Microsoft Windows
=====================================================
.. tag proxy_windows

To determine the current proxy server on the Microsoft Windows platform:

#. Open **Internet Properties**.
#. Open **Connections**.
#. Open **LAN settings**.
#. View the **Proxy server** setting. If this setting is blank, then a proxy server may not be available.

To configure proxy settings in Microsoft Windows:

#. Open **System Properties**.
#. Open **Environment Variables**.
#. Open **System variables**.
#. Set ``http_proxy`` and ``https_proxy`` to the location of your proxy server. This value **MUST** be lowercase.

.. end_tag

Linux
=====================================================
To determine the current proxy server on the macOS and Linux platforms, check the environment variables. Run the following:

.. code-block:: bash

   env | grep -i http_proxy

If an environment variable is set, it **MUST** be lowercase. If it is not, add a lowercase version of that proxy variable to the shell (e.g. ``~/.bashrc``) using one (or more) the following commands.

For HTTP:

.. code-block:: bash

   export http_proxy=http://myproxy.com:3168

For HTTPS:

.. code-block:: bash

   export https_proxy=http://myproxy.com:3168

For FTP:

.. code-block:: bash

   export ftp_proxy=ftp://myproxy.com:3168

Proxy Settings
=====================================================
Proxy settings are defined in configuration files for the chef-client and for knife and may be specified for HTTP, HTTPS, and FTP.

HTTP
-----------------------------------------------------
Use the following settings in the client.rb or knife.rb files for environments that use an HTTP proxy:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Setting
     - Description
   * - ``http_proxy``
     - The proxy server for HTTP connections. Default value: ``nil``.
   * - ``http_proxy_pass``
     - The password for the proxy server when the proxy server is using an HTTP connection. Default value: ``nil``.
   * - ``http_proxy_user``
     - The user name for the proxy server when the proxy server is using an HTTP connection. Default value: ``nil``.

HTTPS
-----------------------------------------------------
Use the following settings in the client.rb or knife.rb files for environments that use an HTTPS proxy:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Setting
     - Description
   * - ``https_proxy``
     - The proxy server for HTTPS connections. Default value: ``nil``.
   * - ``https_proxy_pass``
     - The password for the proxy server when the proxy server is using an HTTPS connection. Default value: ``nil``.
   * - ``https_proxy_user``
     - The user name for the proxy server when the proxy server is using an HTTPS connection. Default value: ``nil``.

FTP
-----------------------------------------------------
Use the following settings in the client.rb or knife.rb files for environments that use an FTP proxy:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Setting
     - Description
   * - ``ftp_proxy``
     - The proxy server for FTP connections.
   * - ``ftp_proxy_pass``
     - The password for the proxy server when the proxy server is using an FTP connection. Default value: ``nil``.
   * - ``ftp_proxy_user``
     - The user name for the proxy server when the proxy server is using an FTP connection. Default value: ``nil``.

No Proxy
-----------------------------------------------------
The ``no_proxy`` setting is used to specify addresses for which the proxy should not be used. This can be a single address or a comma-separated list of addresses.

Example:

.. code-block:: ruby

   no_proxy 'test.example.com,test.example2.com,test.example3.com'

.. note:: Wildcard matching may be used in the ``no_proxy`` list---such as ``no_proxy '*.*.example.*'``---however, many situations require hostnames to be specified explicitly (i.e. "without wildcards").

Environment Variables
=====================================================
Consider the following for situations where environment variables are used to set the proxy:

* Proxy settings may not be honored by all applications. For example, proxy settings may be ignored by the underlying application when specifying a ``ftp`` source with a ``remote_file`` resource. Consider a workaround. For example, in this situation try doing a ``wget`` with an ``ftp`` URL instead.
* Proxy settings may be honored inconsistently by applications. For example, the behavior of the ``no_proxy`` setting may not work with certain applications when wildcards are specified. Consider specifying the hostnames without using wildcards.

ENV
-----------------------------------------------------
.. tag proxy_env

If ``http_proxy``, ``https_proxy``, ``ftp_proxy``, or ``no_proxy`` is set in the client.rb file and is not already set in the ``ENV``, the chef-client will configure the ``ENV`` variable based on these (and related) settings. For example:

.. code-block:: ruby

   http_proxy 'http://proxy.example.org:8080'
   http_proxy_user 'myself'
   http_proxy_pass 'Password1'

will be set to:

.. code-block:: ruby

   ENV['http_proxy'] = 'http://myself:Password1@proxy.example.org:8080'

.. end_tag

