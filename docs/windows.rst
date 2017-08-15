=====================================================
Chef for Microsoft Windows
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/windows.rst>`__

.. note:: This page collects information about Chef that is specific to using Chef with Microsoft Windows.

.. note:: New in Chef Client 12.9, Chef client now runs on 64-bit versions of Microsoft Windows.

The chef-client has specific components that are designed to support unique aspects of the Microsoft Windows platform, including Windows PowerShell, Internet Information Services (IIS), and SQL Server.

* The chef-client is `installed on a machine <https://downloads.chef.io/chef-client/windows/>`_ running Microsoft Windows by using a Microsoft Installer Package (MSI)
* Six resources dedicated to the Microsoft Windows platform are built into the chef-client: **batch**, **dsc_script**, **env**, **powershell_script**, **registry_key**, and **windows_package**
* Use the **dsc_resource** to use Powershell DSC resources in Chef!
* Two knife plugins dedicated to the Microsoft Windows platform are available: ``knife azure`` is used to manage virtual instances in Microsoft Azure; ``knife windows`` is used to interact with and manage physical nodes that are running Microsoft Windows, such as desktops and servers
* Many community cookbooks on Supermarket provide Windows specific support. Chef maintains cookbooks for `PowerShell <https://github.com/chef-cookbooks/powershell>`_, `IIS <https://github.com/chef-cookbooks/iis>`_, `SQL Server <https://github.com/chef-cookbooks/database>`_, and `Windows <https://github.com/chef-cookbooks/windows>`_.
* The following Microsoft Windows platform-specific helpers can be used in recipes:

  .. list-table::
     :widths: 200 300
     :header-rows: 1

     * - Helper
       - Description
     * - ``cluster?``
       - Use to test for a Cluster SKU (Windows Server 2003 and later).
     * - ``core?``
       - Use to test for a Core SKU (Windows Server 2003 and later).
     * - ``datacenter?``
       - Use to test for a Datacenter SKU.
     * - ``marketing_name``
       - Use to display the marketing name for a Microsoft Windows platform.
     * - ``windows_7?``
       - Use to test for Windows 7.
     * - ``windows_8?``
       - Use to test for Windows 8.
     * - ``windows_8_1?``
       - Use to test for Windows 8.1.
     * - ``windows_2000?``
       - Use to test for Windows 2000.
     * - ``windows_home_server?``
       - Use to test for Windows Home Server.
     * - ``windows_server_2003?``
       - Use to test for Windows Server 2003.
     * - ``windows_server_2003_r2?``
       - Use to test for Windows Server 2003 R2.
     * - ``windows_server_2008?``
       - Use to test for Windows Server 2008.
     * - ``windows_server_2008_r2?``
       - Use to test for Windows Server 2008 R2.
     * - ``windows_server_2012?``
       - Use to test for Windows Server 2012.
     * - ``windows_server_2012_r2?``
       - Use to test for Windows Server 2012 R2.
     * - ``windows_vista?``
       - Use to test for Windows Vista.
     * - ``windows_xp?``
       - Use to test for Windows XP.
* Two community provisioners for Kitchen: `kitchen-dsc <https://github.com/test-kitchen/kitchen-dsc>`_ and `kitchen-pester <https://github.com/test-kitchen/kitchen-pester>`_

The most popular core resources in the chef-client---:doc:`cookbook_file </resource_cookbook_file>`, :doc:`directory </resource_directory>`, :doc:`env </resource_env>`, :doc:`execute </resource_execute>`, :doc:`file </resource_file>`, :doc:`group </resource_group>`, :doc:`http_request </resource_http_request>`, :doc:`link </resource_link>`, :doc:`mount </resource_mount>`, :doc:`package </resource_package>`, :doc:`remote_directory </resource_remote_directory>`, :doc:`remote_file </resource_remote_file>`, :doc:`ruby_block </resource_ruby_block>`, :doc:`service </resource_service>`, :doc:`template </resource_template>`, and :doc:`user </resource_user>`---work the same way in Microsoft Windows as they do on any UNIX- or Linux-based platform.

The file-based resources---**cookbook_file**, **file**, **remote_file**, and **template**---have attributes that support unique requirements within the Microsoft Windows platform, including ``inherits`` (for file inheritence), ``mode`` (for octal modes), and ``rights`` (for access control lists, or ACLs).

.. note:: The Microsoft Windows platform does not support running as an alternate user unless full credentials (a username and password or equivalent) are specified.

The following sections are pulled in from the larger |url docs| site and represents the documentation that is specific to the Microsoft Windows platform, compiled here into a single-page reference.

Install the chef-client on Windows
=====================================================
.. tag windows_install_overview

The chef-client can be installed on machines running Microsoft Windows in the following ways:

* By using the :doc:`knife windows </plugin_knife_windows>` plugin to bootstrap the chef-client; this process requires the target node be available via SSH (port 22) or by using the HTTP or HTTPS ports that are required by WinRM
* By downloading the chef-client to the target node, and then running the Microsoft Installer Package (MSI) locally
* By using an existing process already in place for managing Microsoft Windows machines, such as System Center

To run the chef-client at periodic intervals (so that it can check in with the Chef server automatically), configure the chef-client to run as a service or as a scheduled task. (The chef-client can be configured to run as a service during the setup process.)

.. end_tag

The chef-client can be used to manage machines that run on the following versions of Microsoft Windows:

.. list-table::
   :widths: 200 200 200
   :header-rows: 1

   * - Operating System
     - Version
     - Architecture
   * - Windows
     - 2008 R2, 2012, 2012 R2
     - x86_64

(The recommended amount of RAM available to the chef-client during a chef-client run is 512MB. Each node and workstation must have access to the Chef server via HTTPS. Ruby version 1.9.1 or Ruby version 1.9.2 with SSL bindings is required.)

The Microsoft Installer Package (MSI) for Microsoft Windows is available at http://www.chef.io/chef/install/. From the drop-downs, select the operating system (``Windows``), then the version, and then the architecture.

After the chef-client is installed, it is located at ``C:\chef``. The main configuration file for the chef-client is located at ``C:\chef\client.rb``.

Set the System Ruby
-----------------------------------------------------
.. tag windows_set_system_ruby

To set the system Ruby for the Microsoft Windows platform `the steps described for all platforms are true </install_dk.html#set-system-ruby>`_, but then require the following manual edits to the ``chef shell-init bash`` output for the Microsoft Windows platform:

#. Add quotes around the variable assignment strings.
#. Convert ``C:/`` to ``/c/``.
#. Save those changes.

.. end_tag

Spaces and Directories
-----------------------------------------------------
.. tag windows_spaces_and_directories

Directories that are used by Chef on the Microsoft Windows platform cannot have spaces. For example, ``/c/Users/Steven Danno`` will not work, but ``/c/Users/StevenDanno`` will.

A different issue exists with the knife command line tool that is also related to spaces and directories. The ``knife cookbook site install`` subcommand will fail when the Microsoft Windows directory contains a space.

.. end_tag

Top-level Directory Names
-----------------------------------------------------
.. tag windows_top_level_directory_names

Paths can be longer in UNIX and Linux environments than they can be in Microsoft Windows. Microsoft Windows will throw errors when path name lengths are too long. For this reason, it's often helpful to use a very short top-level directory in Microsoft Windows, much like what is done in UNIX and Linux. For example, Chef uses ``/opt/`` to install the Chef development kit on macOS. A similar approach can be done on Microsoft Windows, by creating a top-level directory with a short name. For example: ``c:\chef``.

.. end_tag

Use knife-windows
-----------------------------------------------------
.. tag plugin_knife_windows_summary

The ``knife windows`` subcommand is used to configure and interact with nodes that exist on server and/or desktop machines that are running Microsoft Windows. Nodes are configured using WinRM, which allows native objects---batch scripts, Windows PowerShell scripts, or scripting library variables---to be called by external applications. The ``knife windows`` subcommand supports NTLM and Kerberos methods of authentication.

.. end_tag

For more information about the ``knife windows`` plugin, see :doc:`windows </plugin_knife_windows>`.

Ports
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag plugin_knife_windows_winrm_ports

WinRM requires that a target node be accessible via the ports configured to support access via HTTP or HTTPS.

.. end_tag

Msiexec.exe
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag windows_msiexec

Msiexec.exe is used to install the chef-client on a node as part of a bootstrap operation. The actual command that is run by the default bootstrap script is:

.. code-block:: bash

   $ msiexec /qn /i "%LOCAL_DESTINATION_MSI_PATH%"

where ``/qn`` is used to set the user interface level to "No UI", ``/i`` is used to define the location in which the chef-client is installed, and ``"%LOCAL_DESTINATION_MSI_PATH%"`` is a variable defined in the default `windows-chef-client-msi.erb <https://github.com/chef/knife-windows/blob/master/lib/chef/knife/bootstrap/windows-chef-client-msi.erb>`_ bootstrap template. See http://msdn.microsoft.com/en-us/library/aa367988%28v=vs.85%29.aspx for more information about the options available to Msiexec.exe.

.. end_tag

ADDLOCAL Options
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag windows_msiexec_addlocal
.. note:: ``ChefSchTaskFeature`` is New in Chef Client 12.18.

The ``ADDLOCAL`` parameter adds two setup options that are specific to the chef-client. These options can be passed along with an Msiexec.exe command:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Option
     - Description
   * - ``ChefClientFeature``
     - Use to install the chef-client.
   * - ``ChefSchTaskFeature``
     - Use to configure the chef-client as a scheduled task in Microsoft Windows.
   * - ``ChefServiceFeature``
     - Use to configure the chef-client as a service in Microsoft Windows.
   * - ``ChefPSModuleFeature``
     - Used to install the chef PowerShell module. This will enable chef command line utilities within PowerShell.

First install the chef-client, and then enable it to run as a scheduled task (recommended) or as a service. For example:

.. code-block:: bash

   $ msiexec /qn /i C:\inst\chef-client-12.4.3-1.windows.msi ADDLOCAL="ChefClientFeature,ChefSchTaskFeature,ChefPSModuleFeature"

OR

.. code-block:: bash

   $ msiexec /qn /i C:\inst\chef-client-12.4.3-1.windows.msi ADDLOCAL="ChefClientFeature,ChefServiceFeature,ChefPSModuleFeature"

.. end_tag

Use MSI Installer
-----------------------------------------------------
A Microsoft Installer Package (MSI) is available for installing the chef-client on a Microsoft Windows machine.

.. tag install_chef_client_windows

To install the chef-client on Microsoft Windows, do the following:

#. Go to https://downloads.chef.io/chef.

#. Click the **Chef Client** tab.

#. Select **Windows**, a version, and an architecture.

#. Under **Downloads**, select the version of the chef-client to download, and then click the link that appears below to download the package.

#. Ensure that the MSI is on the target node.

#. Run the MSI package and use all the default options:

   .. image:: ../../images/step_install_windows_01.png

then:

   .. image:: ../../images/step_install_windows_02.png

then:

   .. image:: ../../images/step_install_windows_03.png

   .. note:: The MSI can either configure the chef-client to run as a scheduled task or as a service for it to be able to regularly check in with the Chef server. Using a scheduled task is a recommended approach. Select the **Chef Unattended Execution Options** option to have the MSI configure the chef-client as a scheduled task or as a service.

then:

   .. image:: ../../images/step_install_windows_04.png

then:

   .. image:: ../../images/step_install_windows_05.png

then:

   .. image:: ../../images/step_install_windows_06.png

then:

   .. image:: ../../images/step_install_windows_07.png

.. end_tag

Enable as a Scheduled Task
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag install_chef_client_windows_as_scheduled_task

To run the chef-client at periodic intervals (so that it can check in with the Chef server automatically), configure the chef-client to run as a scheduled task. This can be done via the MSI, by selecting the **Chef Unattended Execution Options** --> **Chef Client Scheduled Task** option on the **Custom Setup** page or by running the following command after the chef-client is installed:

For example:

.. code-block:: bash

   $ SCHTASKS.EXE /CREATE /TN ChefClientSchTask /SC MINUTE /MO 30 /F /RU "System" /RP /RL HIGHEST /TR "cmd /c \"C:\opscode\chef\embedded\bin\ruby.exe C:\opscode\chef\bin\chef-client -L C:\chef\chef-client.log -c C:\chef\client.rb\""

Refer `Schedule a Task <https://technet.microsoft.com/en-us/library/cc748993%28v=ws.11%29.aspx>`_ for more details.

After the chef-client is configured to run as a scheduled task, the default file path is: ``c:\chef\chef-client.log``.

Using a scheduled task is a recommended approach. Refer `Should I run chef-client on Windows as a 'service' or a 'scheduled task'? <https://getchef.zendesk.com/hc/en-us/articles/205233360-Should-I-run-chef-client-on-Windows-as-a-service-or-a-scheduled-task->`_ to help you identify some reasons for why scheduled task is preferred over service.

.. end_tag

Enable as a Service
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag install_chef_client_windows_as_service

To run the chef-client at periodic intervals (so that it can check in with the Chef server automatically), configure the chef-client to run as a service. This can be done via the MSI, by selecting the **Chef Unattended Execution Options** --> **Chef Client Service** option on the **Custom Setup** page or by running the following command after the chef-client is installed:

.. code-block:: bash

   $ chef-service-manager -a install

and then start the chef-client as a service:

.. code-block:: bash

   $ chef-service-manager -a start

After the chef-client is configured to run as a service, the default file path is: ``c:\chef\chef-client.log``.

.. end_tag

Use an Existing Process
-----------------------------------------------------
.. tag windows_install_system_center

Many organizations already have processes in place for managing the applications and settings on various Microsoft Windows machines. For example, System Center. The chef-client can be installed using this method.

.. end_tag

PATH System Variable
-----------------------------------------------------
.. tag windows_environment_variable_path

On Microsoft Windows, the chef-client must have two entries added to the ``PATH`` environment variable:

* ``C:\opscode\chef\bin``
* ``C:\opscode\chef\embedded\bin``

This is typically done during the installation of the chef-client automatically. If these values (for any reason) are not in the ``PATH`` environment variable, the chef-client will not run properly.

.. image:: ../../images/includes_windows_environment_variable_path.png

This value can be set from a recipe. For example, from the ``php`` cookbook:

.. code-block:: ruby

   #  the following code sample comes from the ``package`` recipe in the ``php`` cookbook: https://github.com/chef-cookbooks/php

   if platform?('windows')

     include_recipe 'iis::mod_cgi'

     install_dir = File.expand_path(node['php']['conf_dir']).gsub('/', '\\')
     windows_package node['php']['windows']['msi_name'] do
       source node['php']['windows']['msi_source']
       installer_type :msi

       options %W[
         /quiet
         INSTALLDIR="#{install_dir}"
         ADDLOCAL=#{node['php']['packages'].join(',')}
       ].join(' ')
   end

   ...

   ENV['PATH'] += ";#{install_dir}"
   windows_path install_dir

   ...

.. end_tag

Proxy Settings
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

Microsoft Azure portal
=====================================================

.. tag cloud_azure_portal

Microsoft Azure is a cloud hosting platform from Microsoft that provides virtual machines and integrated services for you to use with your cloud and hybrid applications. And through the Azure Marketplace and Azure portal (|url azure_production|), virtual machines can be bootstrapped and ready to run Chef Automate, Chef server, Chef Compliance and Chef client.

.. end_tag

.. tag cloud_azure_portal_platforms

Through the Azure portal, you can provision a virtual machine with chef-client running as a background service. Once provisioned, these virtual machines are ready to be managed by a Chef server.

.. note:: Virtual machines running on Microsoft Azure can also be provisioned from the command-line using the ``knife azure`` plugin for knife. This approach is ideal for cases that require automation or for users who are more suited to command-line interfaces.

.. end_tag

Azure Marketplace
-----------------------------------------------------
.. tag cloud_azure_portal_server_marketplace

Chef provides a fully functional Chef server that can be launched from the Azure Marketplace. This server is preconfigured with Chef server, the Chef management console, Reporting, and Chef Analytics.

Before getting started, you will need a functioning workstation. Install the :doc:`Chef development kit </install_dk>` on that workstation.

   .. note:: The following steps assume that Chef is installed on the workstation and that the ``knife ssl fetch`` subcommand is available. The ``knife ssl fetch`` subcommand was added to Chef in the 11.16 release of the Chef Client, and then packaged as part of the Chef development kit starting with the 0.3 release.)

#. Sign in to the Azure portal (|url azure_preview|). Authenticate using your Microsoft Azure account credentials.

#. Click the **New** icon in the upper-left corner of the portal.

#. In the search box enter **Chef Server**.

#. Select the **Chef Server 12** offering that is appropriate for your size.

   .. note:: The Chef server is available on the Azure Marketplace in 25, 50, 100, 150, 200, and 250 licensed images, as well as a "Bring Your Own License" image.

#. Click **Create** and follow the steps to launch the Chef server, providing credentials, VM size, and any additional information required.

#. Once your VM has been created, create a **DNS name label** for the instance by following these instructions:  <https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-create-fqdn-on-portal/>

#. In order to use the Chef Manage UI, you will need to create an account. To do this, open an SSH connection to the host using the user name and password (or SSH key) provided when you launched the instance.

#. Configure the Chef server with the DNS Name.

   .. note:: In the following steps substitute ``<fqdn>`` for the fully qualified domain **DNS NAME** that you created.

#. Remove the Nginx configuration for the existing Chef Analytics configuration:

   .. code-block:: bash

      $ sudo rm /var/opt/opscode/nginx/etc/nginx.d/analytics.conf

#. Update the ``/etc/chef-marketplace/marketplace.rb`` file to include the ``api_fqdn`` of the machine:

   .. code-block:: none

      $ echo 'api_fqdn "<fqdn>"' | sudo tee -a /etc/chef-marketplace/marketplace.rb

#. Update the ``/etc/opscode-analytics/opscode-analytics.rb`` file to include the ``analytics_fqdn`` of the machine:

   .. code-block:: none

      $ echo 'analytics_fqdn "<fqdn>"' | sudo tee -a /etc/opscode-analytics/opscode-analytics.rb

#. Run the following command to update the hostname and reconfigure the software:

   .. code-block:: bash

      $ sudo chef-marketplace-ctl hostname <fqdn>

#. Run the following command to update reconfigure Chef Analytics:

   .. code-block:: bash

      $ sudo opscode-analytics-ctl reconfigure

#. Now proceed to the web based setup wizard ``https://<fqdn>/signup``.

   .. note:: Before you can run through the wizard you must provide the VM Name or DNS Label of the instance in order to ensure that only you are configuring the Chef server.

#. Enter credentials to sign up for a new account and download the starter kit.

#. Extract the starter kit zip file. Open a command prompt and change into the ``chef-repo`` directory extracted from the starter kit.

#. Open ``/path/to/chef-repo/.chef/knife.rb`` and replace the ``chef_server_url`` value with the following:

   .. code-block:: bash

      "https://<fqdn>/organizations/<orgname>"


   .. note:: The organization value is the one you defined during setup.

#. Run ``knife ssl fetch`` to retrieve the SSL keys for the Chef server. You should see a message informing you that a certificate for your Chef server VM was successfully added to your local ``chef-repo`` directory.

#. Run ``knife client list`` to test the connection to the Chef server. The command should return ``<orgname>-validator``, where ``<orgname>`` is the name of the organization you previously created. You are now ready to add virtual machines to your Chef server.

.. end_tag

chef-client Settings
-----------------------------------------------------
.. tag cloud_azure_portal_settings_chef_client

Before virtual machines can be created using the Azure portal, some chef-client-specific settings will need to be identified so they can be provided to the Azure portal during the virtual machine creation workflow. These settings are available from the chef-client configuration settings:

* The ``chef_server_url`` and ``validaton_client_name``. These are settings in the :doc:`client.rb file </config_rb_client>`.

* The file for the :doc:`validator key </chef_private_keys>`.

.. end_tag

Set up Virtual Machines
-----------------------------------------------------
.. tag cloud_azure_portal_virtual_machines

Once this information has been identified, launch the Azure portal, start the virtual machine creation workflow, and then bootstrap virtual machines with Chef using the following steps:

#. Sign in to the Azure portal (|url azure_production|). Authenticate using your Microsoft Azure account credentials.

#. Choose **Virtual Machines** in the left pane of the portal.

#. Click the **Add** option at the top of the blade.

#. Select either **Windows Server** or **Ubuntu Server** in the **Recommended** category.

   .. note:: The Chef extension on the Azure portal may be used on the following platforms:

      * Windows Server 2008 R2 SP1, 2012, 2012 R2, 2016
      * Ubuntu 12.04 LTS, 14.04 LTS, 16.04 LTS, 16.10
      * CentOS 6.5+
      * RHEL 6+
      * Debian 7, 8

#. In the next blade, select the sku/version of the OS that you would like to use on your VM and click **Create**.

#. Fill in the virtual machine configuration information, such as machine name, credentials, VM size, and so on.

   .. note:: It's best to use a new computer name each time through this workflow. This will help to avoid conflicts with virtual machine names that may have been previously registered on the Chef server.

#. In Step 3 on the portal UI, open the **Extensions** blade and click ``Add extension``.

#. Depending on the OS you selected earlier, select either **Windows Chef Extension** or **Linux Chef Extension** and then **Create**.

#. Using the ``chef-repo/.chef/knife.rb`` file you downloaded during your Chef server setup, enter values for the Chef server URL and the validation client name. You can also use this file to help you find the location of your validation key.

#. Browse on your local machine and find your validation key (``chef-repo/.chef/<orgname>-validator.pem``).

#. Upload it through the portal in the **Validation Key** field.

   .. note:: Because the ``.chef`` directory is considered a hidden directory, you may have to copy this file out to a non-hidden directory on disk before you can upload it through the open file dialog box.

#. For **Client Configuration File**, browse to the ``chef-repo/.chef/knife.rb`` file and upload it through your web browser.

   .. note:: Same directory issue from previous step applies here as well. Also, the ``knife.rb`` file must be correctly configured to communicate to the Chef server. Specifically, it must have valid values for the following two settings: ``chef_server_url`` and ``validaton_client_name``.

#. Optional. :doc:`Use a run-list </run_lists>` to specify what should be run when the virtual machine is provisioned, such as using the run-list to provision a virtual machine with Internet Information Services (IIS). Use the ``iis`` cookbook and the default recipe to build a run-list. For example:

   .. code-block:: ruby

      iis

   or:

   .. code-block:: ruby

      iis::default

   or:

   .. code-block:: ruby

      recipe['iis']

   A run-list can also be built using a role. For example, if a role named ``backend_server`` is defined on the Chef server, the run-list would look like:

   .. code-block:: ruby

      role['backend_server']

   Even without a run-list, the virtual machine will periodically check with the Chef server to see if the configuration requirements change. This means that the run-list can be updated later, by editing the run-list to add the desired run-list items by using the Chef server web user interface or by using the knife command line tool.

   .. note:: A run-list may only refer to roles and/or recipes that have already been uploaded to the Chef server.

#. Click **OK** to complete the page. Click **OK** in the Extensions blade and the rest of the setup blades. Provisioning will begin and the portal will the blade for your new VM.

After the process is complete, the virtual machine will be registered with the Chef server and it will have been provisioned with the configuration (applications, services, etc.) from the specified run-list. The Chef server can now be used to perform all ongoing management of the virtual machine node.

.. end_tag

Log Files
-----------------------------------------------------
.. tag cloud_azure_portal_log_files

If the Azure portal displays an error in dashboard, check the log files. The log files are created by the chef-client. The log files can be accessed from within the Azure portal or by running the chef-client on the node itself and then reproducing the issue interactively.

.. end_tag

From the Azure portal
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag cloud_azure_portal_log_files_azure_portal

Log files are available from within the Azure portal:

#. Select **Virtual Machines** in the left pane of the Azure portal.

#. Select the virtual machine that has the error status.

#. Click the **Connect** button at the bottom of the portal to launch a Windows Remote Desktop session, and then log in to the virtual machine.

#. Start up a Windows PowerShell command shell.

   .. code-block:: bash

      $ cd c:\windowsazure\logs
        ls –r chef*.log

#. This should display the log files, including the chef-client log file.

.. end_tag

From the chef-client
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag cloud_azure_portal_log_files_chef_client

The chef-client can be run interactively by using Windows Remote Desktop to connect to the virtual machine, and then running the chef-client:

#. Log into the virtual machine.

#. Start up a Windows PowerShell command shell.

#. Run the following command:

   .. code-block:: bash

      $ chef-client -l debug

#. View the logs. On a linux system, the Chef client logs are saved to ``/var/log/azure/Chef.Bootstrap.WindowsAzure.LinuxChefClient/<extension-version-number>/chef-client.log`` and can be viewed using the following command:

   .. code-block:: bash

      $ tail -f /var/log/azure/Chef.Bootstrap.WindowsAzure.LinuxChefClient/1210.12.102.1000/chef-client.log

.. end_tag

Troubleshoot Log Files
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag cloud_azure_portal_log_files_troubleshoot

After the log files have been located, open them using a text editor to view the log file. The most common problem are below:

* Connectivity errors with the Chef server caused by incorrect settings in the client.rb file. Ensure that the ``chef_server_url`` value in the client.rb file is the correct value and that it can be resolved.
* An invalid validator key has been specified. This will prevent the chef-client from authenticating to the Chef server. Ensure that the ``validaton_client_name`` value in the client.rb file is the correct value
* The name of the node is the same as an existing node. Node names must be unique. Ensure that the name of the virtual machine in Microsoft Azure has a unique name.
* An error in one the run-list. The log file will specify the details about errors related to the run-list.

.. end_tag

For more information ...
-----------------------------------------------------
For more information about Microsoft Azure and how to use it with Chef:

* `Microsoft Azure Documentation <http://www.windowsazure.com/en-us/documentation/services/virtual-machines/>`_
* `azure-cookbook <https://github.com/chef-partners/azure-cookbook>`_

Knife
=====================================================
.. tag knife_summary

knife is a command-line tool that provides an interface between a local chef-repo and the Chef server. knife helps users to manage:

* Nodes
* Cookbooks and recipes
* Roles, Environments, and Data Bags
* Resources within various cloud environments
* The installation of the chef-client onto nodes
* Searching of indexed data on the Chef server

.. end_tag

Set the Text Editor
-----------------------------------------------------
.. tag knife_common_set_editor

Some knife commands, such as ``knife data bag edit``, require that information be edited as JSON data using a text editor. For example, the following command:

.. code-block:: bash

   $ knife data bag edit admins admin_name

will open up the text editor with data similar to:

.. code-block:: javascript

   {
     "id": "admin_name"
   }

Changes to that file can then be made:

.. code-block:: javascript

   {
     "id": "Justin C."
     "description": "I am passing the time by letting time pass over me ..."
   }

The type of text editor that is used by knife can be configured by adding an entry to the knife.rb file or by setting an ``EDITOR`` environment variable. For example, to configure the text editor to always open with vim, add the following to the knife.rb file:

.. code-block:: ruby

   knife[:editor] = "/usr/bin/vim"

When a Microsoft Windows file path is enclosed in a double-quoted string (" "), the same backslash character (``\``) that is used to define the file path separator is also used in Ruby to define an escape character. The knife.rb file is a Ruby file; therefore, file path separators must be escaped. In addition, spaces in the file path must be replaced with ``~1`` so that the length of each section within the file path is not more than 8 characters. For example, if EditPad Pro is the text editor of choice and is located at the following path::

   C:\\Program Files (x86)\EditPad Pro\EditPad.exe

the setting in the knife.rb file would be similar to:

.. code-block:: ruby

   knife[:editor] = "C:\\Progra~1\\EditPa~1\\EditPad.exe"

One approach to working around the double- vs. single-quote issue is to put the single-quotes outside of the double-quotes. For example, for Notepad++:

.. code-block:: ruby

   knife[:editor] = '"C:\Program Files (x86)\Notepad++\notepad++.exe" -nosession -multiInst'

for Sublime Text:

.. code-block:: ruby

   knife[:editor] = '"C:\Program Files\Sublime Text 2\sublime_text.exe" --wait'

for TextPad:

.. code-block:: ruby

   knife[:editor] = '"C:\Program Files (x86)\TextPad 7\TextPad.exe"'

and for vim:

.. code-block:: ruby

   knife[:editor] = '"C:\Program Files (x86)\vim\vim74\gvim.exe"'

.. end_tag

Quotes, Windows
-----------------------------------------------------
.. tag knife_common_windows_quotes

When running knife in Microsoft Windows, a string may be interpreted as a wildcard pattern when quotes are not present in the command. The number of quotes to use depends on the shell from which the command is being run.

When running knife from the command prompt, a string should be surrounded by single quotes (``' '``). For example:

.. code-block:: bash

   $ knife node run_list set test-node 'recipe[iptables]'

When running knife from Windows PowerShell, a string should be surrounded by triple single quotes (``''' '''``). For example:

.. code-block:: bash

   $ knife node run_list set test-node '''recipe[iptables]'''

.. end_tag

Import-Module chef
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag knife_common_windows_quotes_module

The chef-client version 12.4 release adds an optional feature to the Microsoft Installer Package (MSI) for Chef. This feature enables the ability to pass quoted strings from the Windows PowerShell command line without the need for triple single quotes (``''' '''``). This feature installs a Windows PowerShell module (typically in ``C:\opscode\chef\modules``) that is also appended to the ``PSModulePath`` environment variable. This feature is not enabled by default. To activate this feature, run the following command from within Windows PowerShell:

.. code-block:: bash

   $ Import-Module chef

or add ``Import-Module chef`` to the profile for Windows PowerShell located at:

.. code-block:: bash

   ~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1

This module exports cmdlets that have the same name as the command-line tools---chef-client, knife, chef-apply---that are built into Chef.

For example:

.. code-block:: bash

   $ knife exec -E 'puts ARGV' """&s0meth1ng"""

is now:

.. code-block:: bash

   $ knife exec -E 'puts ARGV' '&s0meth1ng'

and:

.. code-block:: bash

   $ knife node run_list set test-node '''role[ssssssomething]'''

is now:

.. code-block:: bash

   $ knife node run_list set test-node 'role[ssssssomething]'

To remove this feature, run the following command from within Windows PowerShell:

.. code-block:: bash

   $ Remove-Module chef

.. end_tag

Ampersands, Windows
-----------------------------------------------------
.. tag knife_common_windows_ampersand

When running knife in Microsoft Windows, an ampersand (``&``) is a special character and must be protected by quotes when it appears in a command. The number of quotes to use depends on the shell from which the command is being run.

When running knife from the command prompt, an ampersand should be surrounded by quotes (``"&"``). For example:

.. code-block:: bash

   $ knife bootstrap windows winrm -P "&s0meth1ng"

When running knife from Windows PowerShell, an ampersand should be surrounded by triple quotes (``"""&"""``). For example:

.. code-block:: bash

   $ knife bootstrap windows winrm -P """&s0meth1ng"""

.. end_tag

knife bootstrap
-----------------------------------------------------
.. tag chef_client_bootstrap_node

A node is any physical, virtual, or cloud machine that is configured to be maintained by a chef-client. In order to bootstrap a node, you will first need a working installation of the :doc:`Chef software package </packages>`. A bootstrap is a process that installs the chef-client on a target system so that it can run as a chef-client and communicate with a Chef server. There are two ways to do this:

* Use the ``knife bootstrap`` subcommand to :doc:`bootstrap a node using the omnibus installer </install_bootstrap>`
* Use an unattended install to bootstrap a node from itself, without using SSH or WinRM

.. end_tag

.. tag knife_bootstrap_summary

Use the ``knife bootstrap`` subcommand to run a bootstrap operation that installs the chef-client on the target system. The bootstrap operation must specify the IP address or FQDN of the target system.

.. end_tag

.. note:: To bootstrap the chef-client on Microsoft Windows machines, the :doc:`knife-windows </plugin_knife_windows>` plugins is required, which includes the necessary bootstrap scripts that are used to do the actual installation.

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag knife_bootstrap_syntax

This subcommand has the following syntax:

.. code-block:: bash

   $ knife bootstrap FQDN_or_IP_ADDRESS (options)

.. end_tag

Options
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. note:: Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

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

Custom Templates
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag knife_bootstrap_template

The ``chef-full`` distribution uses the omnibus installer. For most bootstrap operations, regardless of the platform on which the target node is running, using the ``chef-full`` distribution is the best approach for installing the chef-client on a target node. In some situations, using another supported distribution is necessary. And in some situations, a custom template may be required.

For example, the default bootstrap operation relies on an Internet connection to get the distribution to the target node. If a target node cannot access the Internet, then a custom template can be used to define a specific location for the distribution so that the target node may access it during the bootstrap operation.

For example, a bootstrap template file named "sea_power":

.. code-block:: bash

   $ knife bootstrap 123.456.7.8 -x username -P password --sudo --bootstrap-template "sea_power"

The following examples show how a bootstrap template file can be customized for various platforms.

.. end_tag

Microsoft Windows
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
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

knife azure
-----------------------------------------------------
.. tag plugin_knife_azure

Microsoft Azure is a cloud hosting platform from Microsoft that provides virtual machines for Linux and Windows Server, cloud and database services, and more. The ``knife azure`` subcommand is used to manage API-driven cloud servers that are hosted by Microsoft Azure.

.. end_tag

.. note:: Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

Install this plugin
+++++++++++++++++++++++++++++++++++++++++++++++++++++
To install the ``knife azure`` plugin using RubyGems, run the following command:

.. code-block:: bash

   $ /opt/chef/embedded/bin/gem install knife-azure

where ``/opt/chef/embedded/bin/`` is the path to the location where the chef-client expects knife plugins to be located. If the chef-client was installed using RubyGems, omit the path in the previous example.

Generate Certificates
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The ``knife azure`` subcommand must use a management certificate for secure communication with Microsoft Azure. The management certificate is required for secure communication with the Microsoft Azure platform via the REST APIs. To generate the management certificate (.pem file):

#. Download the settings file: http://go.microsoft.com/fwlink/?LinkId=254432.
#. Extract the data from the ``ManagementCertificate`` field into a separate file named ``cert.pfx``.
#. Decode the certificate file with the following command:

   .. code-block:: bash

      $ base64 -d cert.pfx > cert_decoded.pfx
#. Convert the decoded PFX file to a PEM file with the following command:

   .. code-block:: bash

      $ openssl pkcs12 -in cert_decoded.pfx -out managementCertificate.pem -nodes

.. note:: It is possible to generate certificates, and then upload them. See the following link for more information: www.windowsazure.com/en-us/manage/linux/common-tasks/manage-certificates/.

ag create
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the ``ag create`` argument to create an affinity group.

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following syntax:

.. code-block:: bash

   $ knife azure ag create (options)

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following options:

``-a``, ``--azure-affinity-group GROUP``
   The affinity group to which the virtual machine belongs. Required when not using a service location. Required when not using ``--azure-service-location``.

``--azure-ag-desc DESCRIPTION``
   The description of the Microsoft Azure affinity group.

``--azure-publish-settings-file FILE_NAME``
   The name of the Azure Publish Settings file, including the path. For example: ``"/path/to/your.publishsettings"``.

``-H HOST_NAME``, ``--azure_host_name HOST_NAME``
   The host name for the Microsoft Azure environment.

``-m LOCATION``, ``--azure-service-location LOCATION``
   The geographic location for a virtual machine and its services. Required when not using ``--azure-affinity-group``.

``-p FILE_NAME``, ``--azure-mgmt-cert FILE_NAME``
   The name of the file that contains the SSH public key that is used when authenticating to Microsoft Azure.

``-S ID``, ``--azure-subscription-id ID``
   The subscription identifier for the Microsoft Azure portal.

``--verify-ssl-cert``
   The SSL certificate used to verify communication over HTTPS.

ag list
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the ``ag list`` argument to get a list of affinity groups.

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following syntax:

.. code-block:: bash

   $ knife azure ag list (options)

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following options:

``--azure-publish-settings-file FILE_NAME``
   The name of the Azure Publish Settings file, including the path. For example: ``"/path/to/your.publishsettings"``.

``-H HOST_NAME``, ``--azure_host_name HOST_NAME``
   The host name for the Microsoft Azure environment.

``-p FILE_NAME``, ``--azure-mgmt-cert FILE_NAME``
   The name of the file that contains the SSH public key that is used when authenticating to Microsoft Azure.

``-S ID``, ``--azure-subscription-id ID``
   The subscription identifier for the Microsoft Azure portal.

``--verify-ssl-cert``
   The SSL certificate used to verify communication over HTTPS.

image list
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the ``image list`` argument to get a list of images that exist in a Microsoft Azure environment. Any image in this list may be used for provisioning.

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following syntax:

.. code-block:: bash

   $ knife azure image list (options)

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following options:

``--azure-publish-settings-file FILE_NAME``
   The name of the Azure Publish Settings file, including the path. For example: ``"/path/to/your.publishsettings"``.

``--full``
   Show all fields for all images.

``-H HOST_NAME``, ``--azure_host_name HOST_NAME``
   The host name for the Microsoft Azure environment.

``-p FILE_NAME``, ``--azure-mgmt-cert FILE_NAME``
   The name of the file that contains the SSH public key that is used when authenticating to Microsoft Azure.

``-S ID``, ``--azure-subscription-id ID``
   The subscription identifier for the Microsoft Azure portal.

``--verify-ssl-cert``
   The SSL certificate used to verify communication over HTTPS.

server create
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the ``server create`` argument to create a new Microsoft Azure cloud instance. This will provision a new image in Microsoft Azure, perform a bootstrap (using the SSH protocol), and then install the chef-client on the target system so that it can be used to configure the node and to communicate with a Chef server.

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following syntax:

.. code-block:: bash

   $ knife azure server create (options)

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following options:

``-a``, ``--azure-affinity-group GROUP``
   The affinity group to which the virtual machine belongs. Required when not using a service location. Required when not using ``--azure-service-location``.

``--auto-update-client``
   Enable automatic updates for the chef-client in Microsoft Azure. This option may only be used when ``--bootstrap-protocol`` is set to ``cloud-api``. Default value: ``false``.

``--azure-availability-set NAME``
   The name of the availability set for the virtual machine.

``--azure-dns-name DNS_NAME``
   Required. The name of the DNS prefix that is used to access the cloud service. This name must be unique within Microsoft Azure. Use with ``--azure-connect-to-existing-dns`` to use an existing DNS prefix.

``--azure-network-name NETWORK_NAME``
   The network for the virtual machine.

``--azure-publish-settings-file FILE_NAME``
   The name of the Azure Publish Settings file, including the path. For example: ``"/path/to/your.publishsettings"``.

``--azure-storage-account STORAGE_ACCOUNT_NAME``
   The name of the storage account used with the hosted service. A storage account name may be between 3 and 24 characters (lower-case letters and numbers only) and must be unique within Microsoft Azure.

``--azure-subnet-name SUBNET_NAME``
   The subnet for the virtual machine.

``--azure-vm-name NAME``
   The name of the virtual machine. Must be unique within Microsoft Azure. Required for advanced server creation options.

``--azure-vm-ready-timeout TIMEOUT``
   A number (in minutes) to wait for a virtual machine to reach the ``provisioning`` state. Default value: ``10``.

``--azure-vm-startup-timeout TIMEOUT``
   A number (in minutes) to wait for a virtual machine to transition from the ``provisioning`` state to the ``ready`` state. Default value: ``15``.

``--bootstrap-protocol PROTOCOL``
   The protocol used to bootstrap on a machine that is running Windows Server: ``cloud-api``, ``ssh``, or ``winrm``. Default value: ``winrm``.

   Use the ``cloud-api`` option to bootstrap a machine in Microsoft Azure. The bootstrap operation will enable the guest agent to install, configure, and run the chef-client on a node, after which the chef-client is configured to run as a daemon/service. (This is a similar process to using the Azure portal.)

   Microsoft Azure maintains images of the chef-client on the guest, so connectivity between the guest and the workstation from which the bootstrap operation was initiated is not required, after a ``cloud-api`` bootstrap is started.

   During the ``cloud-api`` bootstrap operation, knife does not print the output of the chef-client run like it does when the ``winrm`` and ``ssh`` options are used. knife reports only on the status of the bootstrap process: ``provisioning``, ``installing``, ``ready``, and so on, along with reporting errors.

``--bootstrap-version VERSION``
   The version of the chef-client to install.

``-c``, ``--azure-connect-to-existing-dns``
   Add a new virtual machine to the existing deployment and/or service. Use with ``--azure-dns-name`` to ensure the correct DNS is used.

``--cert-passphrase PASSWORD``
   The password for the SSL certificate.

``--cert-path PATH``
   The path to the location of the SSL certificate.

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

   Deprecated in Chef Client 12.0,

``-H HOST_NAME``, ``--azure_host_name HOST_NAME``
   The host name for the virtual machine.

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

``--host-name HOST_NAME``
   The host name for the Microsoft Azure environment.

``-I IMAGE``, ``--azure-source-image IMAGE``
   The name of the disk image to be used to create the virtual machine.

``--identity-file IDENTITY_FILE``
   The SSH identity file used for authentication. Key-based authentication is recommended.

``--identity-file_passphrase PASSWORD``
   The passphrase for the SSH key. Use only with ``--identity-file``.

``-j JSON_ATTRIBS``, ``--json-attributes JSON_ATTRIBS``
   A JSON string that is added to the first run of a chef-client.

``-m LOCATION``, ``--azure-service-location LOCATION``
   The geographic location for a virtual machine and its services. Required when not using ``--azure-affinity-group``.

``-N NAME``, ``--node-name NAME``
   The name of the node. Node names, when used with Microsoft Azure, must be 91 characters or shorter.

``--[no-]host-key-verify``
   Use ``--no-host-key-verify`` to disable host key verification. Default setting: ``--host-key-verify``.

``-o DISK_NAME``, ``--azure-os-disk-name DISK_NAME``
   The operating system type of the Microsoft Azure OS image: ``Linux`` or ``Windows``.

``-p FILE_NAME``, ``--azure-mgmt-cert FILE_NAME``
   The name of the file that contains the SSH public key that is used when authenticating to Microsoft Azure.

``-P PASSWORD``, ``--ssh-password PASSWORD``
   The SSH password. This can be used to pass the password directly on the command line. If this option is not specified (and a password is required) knife prompts for the password.

``--prerelease``
   Install pre-release gems.

``-r RUN_LIST``, ``--run-list RUN_LIST``
   A comma-separated list of roles and/or recipes to be applied.

``-R ROLE_NAME``, ``--role-name ROLE_NAME``
   The name of the virtual machine.

``--ssh-port PORT``
   The SSH port. Default value: ``22``.

``-t PORT_LIST``, ``--tcp-endpoints PORT_LIST``
   A comma-separated list of local and public TCP ports that are to be opened. For example: ``80:80,433:5000``.

``--template-file TEMPLATE``
   The path to a template file to be used during a bootstrap operation.

   Deprecated in Chef Client 12.0.

``--thumbprint THUMBPRINT``
   The thumbprint of the SSL certificate.

``-u PORT_LIST``, ``---udp-endpoints PORT_LIST``
   A comma-separated list of local and public UDP ports that are to be opened. For example: ``80:80,433:5000``.

``--verify-ssl-cert``
   The SSL certificate used to verify communication over HTTPS.

``--windows-auth-timeout MINUTES``
   The amount of time (in minutes) to wait for authentication to succeed. Default value: ``25``.

``-x USER_NAME``, ``--ssh-user USER_NAME``
   The SSH user name.

``-z SIZE``, ``--azure-vm-size SIZE``
   The size of the virtual machine: ``ExtraSmall``, ``Small``, ``Medium``, ``Large``, or ``ExtraLarge``. Default value: ``Small``.

Examples
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
**Provision an instance using new hosted service and storage accounts**

To provision a medium-sized CentOS machine configured as a web server in the ``West US`` data center, while reusing existing hosted service and storage accounts, enter something like:

.. code-block:: bash

   $ knife azure server create -r "role[webserver]" --service-location "West US"
     --hosted-service-name webservers --storage-account webservers-storage --ssh-user foo
     --ssh--password password --role-name web-apache-0001 --host-name web-apache
     --tcp-endpoints 80:80,8080:8080 --source-image name_of_source_image --role-size Medium

**Provision an instance using new hosted service and storage accounts**

To provision a medium-sized CentOS machine configured as a web server in the ``West US`` data center, while also creating new hosted service and storage accounts, enter something like:

.. code-block:: bash

   $ knife azure server create -r "role[webserver]" --service-location "West US" --ssh-user foo
     --ssh--password password --role-name web-apache-0001 --host-name web-apache
     --tcp-endpoints 80:80,8080:8080 --source-image name_of_source_image --role-size Medium

server delete
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the ``server delete`` argument to delete one or more instances that are running in the Microsoft Azure cloud. To find a specific cloud instance, use ``knife azure server list``. Use the ``--purge`` option to delete all associated node and client objects from the Chef server or use the ``knife node delete`` and ``knife client delete`` subcommands to delete specific node and client objects.

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following syntax:

.. code-block:: bash

   $ knife azure server delete [SERVER...] (options)

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following options:

``--azure-dns-name NAME``
   The name of the DNS server (also known as the Hosted Service Name).

``--azure-publish-settings-file FILE_NAME``
   The name of the Azure Publish Settings file, including the path. For example: ``"/path/to/your.publishsettings"``.

``--delete-azure-storage-account``
   Delete any corresponding storage account. When this option is ``true``, any storage account not used by any virtual machine is deleted.

``-H HOST_NAME``, ``--azure_host_name HOST_NAME``
   The host name for the Microsoft Azure environment.

``-N NODE_NAME``, ``--node-name NODE_NAME``
   The name of the node to be deleted, if different from the server name. This must be used with the ``-p`` (purge) option.

``-p FILE_NAME``, ``--azure-mgmt-cert FILE_NAME``
   The name of the file that contains the SSH public key that is used when authenticating to Microsoft Azure.

``-P``, ``--purge``
   Destroy all corresponding nodes and clients on the Chef server, in addition to the Microsoft Azure node itself. This action (by itself) assumes that the node and client have the same name as the server; if they do not have the same names, then the ``--node-name`` option must be used to specify the name of the node.

``--preserve-azure-dns-name``
   Preserve the DNS entries for the corresponding cloud services. If this option is ``false``, any service not used by any virtual machine is deleted.

``--preserve-azure-os-disk``
   Preserve the corresponding operating system disk.

``--preserve-azure-vhd``
   Preserve the underlying virtual hard disk (VHD).

``-S ID``, ``--azure-subscription-id ID``
   The subscription identifier for the Microsoft Azure portal.

``--verify-ssl-cert``
   The SSL certificate used to verify communication over HTTPS.

``--wait``
   Pause the console until the server has finished processing the request.

Examples
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
**Delete an instance**

To delete an instance named ``devops12``, enter:

.. code-block:: bash

   $ knife azure server delete devops12

server describe
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the ``server describe`` argument to view a detailed description of one (or more) roles that exist in a Microsoft Azure cloud instance. For each specified role name, information such as status, size, hosted service name, deployment name, ports (open, local, public) and IP are displayed.

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following syntax:

.. code-block:: bash

   $ knife azure server describe [ROLE_NAME...] (options)

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following options:

``--azure-publish-settings-file FILE_NAME``
   The name of the Azure Publish Settings file, including the path. For example: ``"/path/to/your.publishsettings"``.

``-H HOST_NAME``, ``--azure_host_name HOST_NAME``
   The host name for the Microsoft Azure environment.

``-p FILE_NAME``, ``--azure-mgmt-cert FILE_NAME``
   The name of the file that contains the SSH public key that is used when authenticating to Microsoft Azure.

``-S ID``, ``--azure-subscription-id ID``
   The subscription identifier for the Microsoft Azure portal.

``--verify-ssl-cert``
   The SSL certificate used to verify communication over HTTPS.

Examples
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
**View role details**

To view the details for a role named ``admin``, enter:

.. code-block:: bash

   $ knife azure server describe admin

server list
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the ``server list`` argument to find instances that are associated with a Microsoft Azure account. The results may show instances that are not currently managed by the Chef server.

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following syntax:

.. code-block:: bash

   $ knife azure server list (options)

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following options:

``--azure-publish-settings-file FILE_NAME``
   The name of the Azure Publish Settings file, including the path. For example: ``"/path/to/your.publishsettings"``.

``-H HOST_NAME``, ``--azure_host_name HOST_NAME``
   The host name for the Microsoft Azure environment.

``-p FILE_NAME``, ``--azure-mgmt-cert FILE_NAME``
   The name of the file that contains the SSH public key that is used when authenticating to Microsoft Azure.

``-S ID``, ``--azure-subscription-id ID``
   The subscription identifier for the Microsoft Azure portal.

``--verify-ssl-cert``
   The SSL certificate used to verify communication over HTTPS.

server show
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the ``server show`` argument to show the details for the named server (or servers).

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following syntax:

.. code-block:: bash

   $ knife azure server show SERVER [SERVER...] (options)

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following options:

``--azure-publish-settings-file FILE_NAME``
   The name of the Azure Publish Settings file, including the path. For example: ``"/path/to/your.publishsettings"``.

``-H HOST_NAME``, ``--azure_host_name HOST_NAME``
   The host name for the Microsoft Azure environment.

``-p FILE_NAME``, ``--azure-mgmt-cert FILE_NAME``
   The name of the file that contains the SSH public key that is used when authenticating to Microsoft Azure.

``-S ID``, ``--azure-subscription-id ID``
   The subscription identifier for the Microsoft Azure portal.

``--verify-ssl-cert``
   The SSL certificate used to verify communication over HTTPS.

vnet create
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the ``vnet create`` argument to create a virtual network.

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following syntax:

.. code-block:: bash

   $ knife azure vnet create (options)

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following options:

``-a``, ``--azure-affinity-group GROUP``
   The affinity group to which the virtual machine belongs. Required when not using a service location.

``--azure-address-space CIDR``
   The address space of the virtual network. Use with classless inter-domain routing (CIDR) notation.

``--azure-publish-settings-file FILE_NAME``
   The name of the Azure Publish Settings file, including the path. For example: ``"/path/to/your.publishsettings"``.

``--azure-subnet-name CIDR``
   The subnet for the virtual machine. Use with classless inter-domain routing (CIDR) notation.

``-H HOST_NAME``, ``--azure_host_name HOST_NAME``
   The host name for the Microsoft Azure environment.

``-n``, ``--azure-network-name NETWORK_NAME``
   The network for the virtual machine.

``-p FILE_NAME``, ``--azure-mgmt-cert FILE_NAME``
   The name of the file that contains the SSH public key that is used when authenticating to Microsoft Azure.

``-S ID``, ``--azure-subscription-id ID``
   The subscription identifier for the Microsoft Azure portal.

``--verify-ssl-cert``
   The SSL certificate used to verify communication over HTTPS.

vnet list
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the ``vnet list`` argument to get a list of virtual networks.

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following syntax:

.. code-block:: bash

   $ knife azure vnet list (options)

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This argument has the following options:

``--azure-publish-settings-file FILE_NAME``
   The name of the Azure Publish Settings file, including the path. For example: ``"/path/to/your.publishsettings"``.

``-H HOST_NAME``, ``--azure_host_name HOST_NAME``
   The host name for the Microsoft Azure environment.

``-p FILE_NAME``, ``--azure-mgmt-cert FILE_NAME``
   The name of the file that contains the SSH public key that is used when authenticating to Microsoft Azure.

``-S ID``, ``--azure-subscription-id ID``
   The subscription identifier for the Microsoft Azure portal.

``--verify-ssl-cert``
   The SSL certificate used to verify communication over HTTPS.

knife windows
-----------------------------------------------------
.. tag plugin_knife_windows_summary

The ``knife windows`` subcommand is used to configure and interact with nodes that exist on server and/or desktop machines that are running Microsoft Windows. Nodes are configured using WinRM, which allows native objects---batch scripts, Windows PowerShell scripts, or scripting library variables---to be called by external applications. The ``knife windows`` subcommand supports NTLM and Kerberos methods of authentication.

.. end_tag

.. note:: Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

Install this plugin
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag plugin_knife_windows_install_rubygem

To install the ``knife windows`` plugin using RubyGems, run the following command:

.. code-block:: bash

   $ /opt/chef/embedded/bin/gem install knife-windows

where ``/opt/chef/embedded/bin/`` is the path to the location where the chef-client expects knife plugins to be located. If the chef-client was installed using RubyGems, omit the path in the previous example.

.. end_tag

Requirements
+++++++++++++++++++++++++++++++++++++++++++++++++++++
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
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
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
+++++++++++++++++++++++++++++++++++++++++++++++++++++
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
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag plugin_knife_windows_bootstrap_windows_ssh

Use the ``bootstrap windows ssh`` argument to bootstrap chef-client installations in a Microsoft Windows environment, using a command shell that is native to Microsoft Windows.

.. end_tag

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag plugin_knife_windows_bootstrap_windows_ssh_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife bootstrap windows ssh (options)

.. end_tag

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
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

winrm
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag plugin_knife_windows_winrm

Use the ``winrm`` argument to create a connection to one or more remote machines. As each connection is created, a password must be provided. This argument uses the same syntax as the ``search`` subcommand.

.. end_tag

.. tag plugin_knife_windows_winrm_ports

WinRM requires that a target node be accessible via the ports configured to support access via HTTP or HTTPS.

.. end_tag

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag plugin_knife_windows_winrm_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife winrm SEARCH_QUERY SSH_COMMAND (options)

.. end_tag

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
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
+++++++++++++++++++++++++++++++++++++++++++++++++++++

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

Resources
=====================================================
.. tag resources_common

A resource is a statement of configuration policy that:

* Describes the desired state for a configuration item
* Declares the steps needed to bring that item to the desired state
* Specifies a resource type---such as ``package``, ``template``, or ``service``
* Lists additional details (also known as resource properties), as necessary
* Are grouped into recipes, which describe working configurations

.. end_tag

Common Functionality
-----------------------------------------------------
The following sections describe Microsoft Windows-specific functionality that applies generally to all resources:

Relative Paths
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resources_common_relative_paths

The following relative paths can be used with any resource:

``#{ENV['HOME']}``
   Use to return the ``~`` path in Linux and macOS or the ``%HOMEPATH%`` in Microsoft Windows.

.. end_tag

Examples
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag resource_template_use_relative_paths

.. To use a relative path:

.. code-block:: ruby

   template "#{ENV['HOME']}/chef-getting-started.txt" do
     source 'chef-getting-started.txt.erb'
     mode '0755'
   end

.. end_tag

Windows File Security
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resources_common_windows_security

To support Microsoft Windows security, the **template**, **file**, **remote_file**, **cookbook_file**, **directory**, and **remote_directory** resources support the use of inheritance and access control lists (ACLs) within recipes.

.. end_tag

.. note:: Windows File Security applies to the **cookbook_file**, **directory**, **file**, **remote_directory**, **remote_file**, and **template** resources.

ACLs
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag resources_common_windows_security_acl

The ``rights`` property can be used in a recipe to manage access control lists (ACLs), which allow permissions to be given to multiple users and groups. Use the ``rights`` property can be used as many times as necessary; the chef-client will apply them to the file or directory as required. The syntax for the ``rights`` property is as follows:

.. code-block:: ruby

   rights permission, principal, option_type => value

where

``permission``
   Use to specify which rights are granted to the ``principal``. The possible values are: ``:read``, ``:write``, ``read_execute``, ``:modify``, and ``:full_control``.

   These permissions are cumulative. If ``:write`` is specified, then it includes ``:read``. If ``:full_control`` is specified, then it includes both ``:write`` and ``:read``.

   (For those who know the Microsoft Windows API: ``:read`` corresponds to ``GENERIC_READ``; ``:write`` corresponds to ``GENERIC_WRITE``; ``:read_execute`` corresponds to ``GENERIC_READ`` and ``GENERIC_EXECUTE``; ``:modify`` corresponds to ``GENERIC_WRITE``, ``GENERIC_READ``, ``GENERIC_EXECUTE``, and ``DELETE``; ``:full_control`` corresponds to ``GENERIC_ALL``, which allows a user to change the owner and other metadata about a file.)

``principal``
   Use to specify a group or user name. This is identical to what is entered in the login box for Microsoft Windows, such as ``user_name``, ``domain\user_name``, or ``user_name@fully_qualified_domain_name``. The chef-client does not need to know if a principal is a user or a group.

``option_type``
   A hash that contains advanced rights options. For example, the rights to a directory that only applies to the first level of children might look something like: ``rights :write, 'domain\group_name', :one_level_deep => true``. Possible option types:

   .. list-table::
      :widths: 60 420
      :header-rows: 1

      * - Option Type
        - Description
      * - ``:applies_to_children``
        - Specify how permissions are applied to children. Possible values: ``true`` to inherit both child directories and files;  ``false`` to not inherit any child directories or files; ``:containers_only`` to inherit only child directories (and not files); ``:objects_only`` to recursively inherit files (and not child directories).
      * - ``:applies_to_self``
        - Indicates whether a permission is applied to the parent directory. Possible values: ``true`` to apply to the parent directory or file and its children; ``false`` to not apply only to child directories and files.
      * - ``:one_level_deep``
        - Indicates the depth to which permissions will be applied. Possible values: ``true`` to apply only to the first level of children; ``false`` to apply to all children.

For example:

.. code-block:: ruby

   resource 'x.txt' do
     rights :read, 'Everyone'
     rights :write, 'domain\group'
     rights :full_control, 'group_name_or_user_name'
     rights :full_control, 'user_name', :applies_to_children => true
   end

or:

.. code-block:: ruby

    rights :read, ['Administrators','Everyone']
    rights :full_control, 'Users', :applies_to_children => true
    rights :write, 'Sally', :applies_to_children => :containers_only, :applies_to_self => false, :one_level_deep => true

Some other important things to know when using the ``rights`` attribute:

* Only inherited rights remain. All existing explicit rights on the object are removed and replaced.
* If rights are not specified, nothing will be changed. The chef-client does not clear out the rights on a file or directory if rights are not specified.
* Changing inherited rights can be expensive. Microsoft Windows will propagate rights to all children recursively due to inheritance. This is a normal aspect of Microsoft Windows, so consider the frequency with which this type of action is necessary and take steps to control this type of action if performance is the primary consideration.

Use the ``deny_rights`` property to deny specific rights to specific users. The ordering is independent of using the ``rights`` property. For example, it doesn't matter if rights are granted to everyone is placed before or after ``deny_rights :read, ['Julian', 'Lewis']``, both Julian and Lewis will be unable to read the document. For example:

.. code-block:: ruby

   resource 'x.txt' do
     rights :read, 'Everyone'
     rights :write, 'domain\group'
     rights :full_control, 'group_name_or_user_name'
     rights :full_control, 'user_name', :applies_to_children => true
     deny_rights :read, ['Julian', 'Lewis']
   end

or:

.. code-block:: ruby

   deny_rights :full_control, ['Sally']

.. end_tag

Inheritance
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag resources_common_windows_security_inherits

By default, a file or directory inherits rights from its parent directory. Most of the time this is the preferred behavior, but sometimes it may be necessary to take steps to more specifically control rights. The ``inherits`` property can be used to specifically tell the chef-client to apply (or not apply) inherited rights from its parent directory.

For example, the following example specifies the rights for a directory:

.. code-block:: ruby

   directory 'C:\mordor' do
     rights :read, 'MORDOR\Minions'
     rights :full_control, 'MORDOR\Sauron'
   end

and then the following example specifies how to use inheritance to deny access to the child directory:

.. code-block:: ruby

   directory 'C:\mordor\mount_doom' do
     rights :full_control, 'MORDOR\Sauron'
     inherits false # Sauron is the only person who should have any sort of access
   end

If the ``deny_rights`` permission were to be used instead, something could slip through unless all users and groups were denied.

Another example also shows how to specify rights for a directory:

.. code-block:: ruby

   directory 'C:\mordor' do
     rights :read, 'MORDOR\Minions'
     rights :full_control, 'MORDOR\Sauron'
     rights :write, 'SHIRE\Frodo' # Who put that there I didn't put that there
   end

but then not use the ``inherits`` property to deny those rights on a child directory:

.. code-block:: ruby

   directory 'C:\mordor\mount_doom' do
     deny_rights :read, 'MORDOR\Minions' # Oops, not specific enough
   end

Because the ``inherits`` property is not specified, the chef-client will default it to ``true``, which will ensure that security settings for existing files remain unchanged.

.. end_tag

Attributes for File-based Resources
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This resource has the following attributes:

.. list-table::
   :widths: 150 450
   :header-rows: 1

   * - Attribute
     - Description
   * - ``group``
     - A string or ID that identifies the group owner by group name, including fully qualified group names such as ``domain\group`` or ``group@domain``. If this value is not specified, existing groups remain unchanged and new group assignments use the default ``POSIX`` group (if available).
   * - ``inherits``
     - Microsoft Windows only. Whether a file inherits rights from its parent directory. Default value: ``true``.
   * - ``mode``
     - If ``mode`` is not specified and if the file already exists, the existing mode on the file is used. If ``mode`` is not specified, the file does not exist, and the ``:create`` action is specified, the chef-client assumes a mask value of ``'0777'`` and then applies the umask for the system on which the file is to be created to the ``mask`` value. For example, if the umask on a system is ``'022'``, the chef-client uses the default value of ``'0755'``.

       Microsoft Windows: A quoted 3-5 character string that defines the octal mode that is translated into rights for Microsoft Windows security. For example: ``'755'``, ``'0755'``, or ``00755``. Values up to ``'0777'`` are allowed (no sticky bits) and mean the same in Microsoft Windows as they do in UNIX, where ``4`` equals ``GENERIC_READ``, ``2`` equals ``GENERIC_WRITE``, and ``1`` equals ``GENERIC_EXECUTE``. This property cannot be used to set ``:full_control``. This property has no effect if not specified, but when it and ``rights`` are both specified, the effects are cumulative.
   * - ``owner``
     - A string or ID that identifies the group owner by user name, including fully qualified user names such as ``domain\user`` or ``user@domain``. If this value is not specified, existing owners remain unchanged and new owner assignments use the current user (when necessary).
   * - ``path``
     - The full path to the file, including the file name and its extension.

       Microsoft Windows: A path that begins with a forward slash (``/``) will point to the root of the current working directory of the chef-client process. This path can vary from system to system. Therefore, using a path that begins with a forward slash (``/``) is not recommended.
   * - ``rights``
     - Microsoft Windows only. The permissions for users and groups in a Microsoft Windows environment. For example: ``rights <permissions>, <principal>, <options>`` where ``<permissions>`` specifies the rights granted to the principal, ``<principal>`` is the group or user name, and ``<options>`` is a Hash with one (or more) advanced rights options.

.. note:: Use the ``owner`` and ``right`` attributes and avoid the ``group`` and ``mode`` attributes whenever possible. The ``group`` and ``mode`` attributes are not true Microsoft Windows concepts and are provided more for backward compatibility than for best practice.

Atomic File Updates
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resources_common_atomic_update

Atomic updates are used with **file**-based resources to help ensure that file updates can be made when updating a binary or if disk space runs out.

Atomic updates are enabled by default. They can be managed globally using the ``file_atomic_update`` setting in the client.rb file. They can be managed on a per-resource basis using the ``atomic_update`` property that is available with the **cookbook_file**, **file**, **remote_file**, and **template** resources.

.. note:: On certain platforms, and after a file has been moved into place, the chef-client may modify file permissions to support features specific to those platforms. On platforms with SELinux enabled, the chef-client will fix up the security contexts after a file has been moved into the correct location by running the ``restorecon`` command. On the Microsoft Windows platform, the chef-client will create files so that ACL inheritance works as expected.

.. end_tag

.. note:: Atomic File Updates applies to the **template** resource.

batch
-----------------------------------------------------
.. tag resource_batch_summary

Use the **batch** resource to execute a batch script using the cmd.exe interpreter. The **batch** resource creates and executes a temporary file (similar to how the **script** resource behaves), rather than running the command inline. This resource inherits actions (``:run`` and ``:nothing``) and properties (``creates``, ``cwd``, ``environment``, ``group``, ``path``, ``timeout``, and ``user``) from the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

.. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_batch_syntax

A **batch** resource block executes a batch script using the cmd.exe interpreter:

.. code-block:: ruby

   batch 'echo some env vars' do
     code <<-EOH
       echo %TEMP%
       echo %SYSTEMDRIVE%
       echo %PATH%
       echo %WINDIR%
       EOH
   end

The full syntax for all of the properties that are available to the **batch** resource is:

.. code-block:: ruby

   batch 'name' do
     architecture               Symbol
     code                       String
     command                    String, Array
     creates                    String
     cwd                        String
     flags                      String
     group                      String, Integer
     guard_interpreter          Symbol
     interpreter                String
     notifies                   # see description
     provider                   Chef::Provider::Batch
     returns                    Integer, Array
     subscribes                 # see description
     timeout                    Integer, Float
     user                       String
     password                   String
     domain                     String
     action                     Symbol # defaults to :run if not specified
   end

where

* ``batch`` is the resource
* ``name`` is the name of the resource block
* ``command`` is the command to be run and ``cwd`` is the location from which the command is run
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``architecture``, ``code``, ``command``, ``creates``, ``cwd``, ``flags``, ``group``, ``guard_interpreter``, ``interpreter``, ``provider``, ``returns``, ``timeout``, `user``, `password`` and `domain`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_batch_actions

This resource has the following actions:

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:run``
   Run a batch file.

.. end_tag

Attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_batch_attributes

This resource has the following properties:

``architecture``
   **Ruby Type:** Symbol

   The architecture of the process under which a script is executed. If a value is not provided, the chef-client defaults to the correct value for the architecture, as determined by Ohai. An exception is raised when anything other than ``:i386`` is specified for a 32-bit process. Possible values: ``:i386`` (for 32-bit processes) and ``:x86_64`` (for 64-bit processes).

``code``
   **Ruby Type:** String

   A quoted (" ") string of code to be executed.

``command``
   **Ruby Types:** String, Array

   The name of the command to be executed.

``creates``
   **Ruby Type:** String

   Prevent a command from creating a file when that file already exists.

``cwd``
   **Ruby Type:** String

   The current working directory from which a command is run.

``flags``
   **Ruby Type:** String

   One or more command line flags that are passed to the interpreter when a command is invoked.

``group``
   **Ruby Types:** String, Integer

   The group name or group ID that must be changed before running a command.

``guard_interpreter``
   **Ruby Type:** Symbol

   Default value: ``:batch``. When this property is set to ``:batch``, the 64-bit version of the cmd.exe shell will be used to evaluate strings values for the ``not_if`` and ``only_if`` properties. Set this value to ``:default`` to use the 32-bit version of the cmd.exe shell.

   Changed in Chef Client 12.0 to default to the specified property.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``interpreter``
   **Ruby Type:** String

   The script interpreter to use during code execution. Changing the default value of this property is not supported.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_notifies_syntax

   The syntax for ``notifies`` is:

   .. code-block:: ruby

      notifies :action, 'resource[name]', :timer

   .. end_tag

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``returns``
   **Ruby Types:** Integer, Array

   The return value for a command. This may be an array of accepted values. An exception is raised when the return value(s) do not match. Default value: ``0``.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_subscribes_syntax

   The syntax for ``subscribes`` is:

   .. code-block:: ruby

      subscribes :action, 'resource[name]', :timer

   .. end_tag

``timeout``
   **Ruby Types:** Integer, Float

   The amount of time (in seconds) a command is to wait before timing out. Default value: ``3600``.

``user``
   **Ruby Types:** String

   The user name of the user identity with which to launch the new process. Default value: `nil`. The user name may optionally be specifed with a domain, i.e. `domain\user` or `user@my.dns.domain.com` via Universal Principal Name (UPN)format. It can also be specified without a domain simply as user if the domain is instead specified using the `domain` attribute. On Windows only, if this property is specified, the `password` property must be specified.

``password``
   **Ruby Types:** String

   *Windows only*: The password of the user specified by the `user` property.
   Default value: `nil`. This property is mandatory if `user` is specified on Windows and may only be specified if `user` is specified. The `sensitive` property for this resource will automatically be set to true if password is specified.

``domain``
   **Ruby Types:** String

   *Windows only*: The domain of the user user specified by the `user` property.
   Default value: `nil`. If not specified, the user name and password specified by the `user` and `password` properties will be used to resolve that user against the domain in which the system running Chef client is joined, or if that system is not joined to a domain it will resolve the user as a local account on that system. An alternative way to specify the domain is to leave this property unspecified and specify the domain as part of the `user` property.

.. note:: See http://technet.microsoft.com/en-us/library/bb490880.aspx for more information about the cmd.exe interpreter.

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Unzip a file, and then move it**

.. tag resource_batch_unzip_file_and_move

To run a batch file that unzips and then moves Ruby, do something like:

.. code-block:: ruby

   batch 'unzip_and_move_ruby' do
     code <<-EOH
       7z.exe x #{Chef::Config[:file_cache_path]}/ruby-1.8.7-p352-i386-mingw32.7z
         -oC:\\source -r -y
       xcopy C:\\source\\ruby-1.8.7-p352-i386-mingw32 C:\\ruby /e /y
       EOH
   end

   batch 'echo some env vars' do
     code <<-EOH
       echo %TEMP%
       echo %SYSTEMDRIVE%
       echo %PATH%
       echo %WINDIR%
       EOH
   end

or:

.. code-block:: ruby

   batch 'unzip_and_move_ruby' do
     code <<-EOH
       7z.exe x #{Chef::Config[:file_cache_path]}/ruby-1.8.7-p352-i386-mingw32.7z
         -oC:\\source -r -y
       xcopy C:\\source\\ruby-1.8.7-p352-i386-mingw32 C:\\ruby /e /y
       EOH
   end

   batch 'echo some env vars' do
     code 'echo %TEMP%\\necho %SYSTEMDRIVE%\\necho %PATH%\\necho %WINDIR%'
   end

.. end_tag

dsc_resource
-----------------------------------------------------

.. tag resources_common_generic

A :doc:`resource </resource>` defines the desired state for a single configuration item present on a node that is under management by Chef. A resource collection---one (or more) individual resources---defines the desired state for the entire node. During a `chef-client run </chef_client.html#the-chef-client-run>`_, the current state of each resource is tested, after which the chef-client will take any steps that are necessary to repair the node and bring it back into the desired state.

.. end_tag

.. tag resources_common_powershell

Windows PowerShell is a task-based command-line shell and scripting language developed by Microsoft. Windows PowerShell uses a document-oriented approach for managing Microsoft Windows-based machines, similar to the approach that is used for managing UNIX- and Linux-based machines. Windows PowerShell is `a tool-agnostic platform <http://technet.microsoft.com/en-us/library/bb978526.aspx>`_ that supports using Chef for configuration management.

.. end_tag

.. tag resources_common_powershell_dsc

Desired State Configuration (DSC) is a feature of Windows PowerShell that provides `a set of language extensions, cmdlets, and resources <http://technet.microsoft.com/en-us/library/dn249912.aspx>`_ that can be used to declaratively configure software. DSC is similar to Chef, in that both tools are idempotent, take similar approaches to the concept of resources, describe the configuration of a system, and then take the steps required to do that configuration. The most important difference between Chef and DSC is that Chef uses Ruby and DSC is exposed as configuration data from within Windows PowerShell.

.. end_tag

.. tag resource_dsc_resource_summary

The **dsc_resource** resource allows any DSC resource to be used in a Chef recipe, as well as any custom resources that have been added to your Windows PowerShell environment. Microsoft `frequently adds new resources <https://github.com/powershell/DscResources>`_ to the DSC resource collection.

.. end_tag

.. warning:: .. tag resource_dsc_resource_requirements

             Using the **dsc_resource** has the following requirements:

             * Windows Management Framework (WMF) 5.0 February Preview (or higher), which includes Windows PowerShell 5.0.10018.0 (or higher).
             * The ``RefreshMode`` configuration setting in the Local Configuration Manager must be set to ``Disabled``.

               **NOTE:** Starting with the chef-client 12.6 release, this requirement applies only for versions of Windows PowerShell earlier than 5.0.10586.0. The latest version of Windows Management Framework (WMF) 5 has relaxed the limitation that prevented the chef-client from running in non-disabled refresh mode.

             * The **dsc_script** resource  may not be used in the same run-list with the **dsc_resource**. This is because the **dsc_script** resource requires that ``RefreshMode`` in the Local Configuration Manager be set to ``Push``, whereas the **dsc_resource** resource requires it to be set to ``Disabled``.

               **NOTE:** Starting with the chef-client 12.6 release, this requirement applies only for versions of Windows PowerShell earlier than 5.0.10586.0. The latest version of Windows Management Framework (WMF) 5 has relaxed the limitation that prevented the chef-client from running in non-disabled refresh mode, which allows the Local Configuration Manager to be set to ``Push``.

             * The **dsc_resource** resource can only use binary- or script-based resources. Composite DSC resources may not be used.

               This is because composite resources aren't "real" resources from the perspective of the the Local Configuration Manager (LCM). Composite resources are used by the "configuration" keyword from the ``PSDesiredStateConfiguration`` module, and then evaluated in that context. When using DSC to create the configuration document (the Managed Object Framework (MOF) file) from the configuration command, the composite resource is evaluated. Any individual resources from that composite resource are written into the Managed Object Framework (MOF) document. As far as the Local Configuration Manager (LCM) is concerned, there is no such thing as a composite resource. Unless that changes, the **dsc_resource** resource and/or ``Invoke-DscResource`` command cannot directly use them.

             .. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_dsc_resource_syntax

A **dsc_resource** resource block allows DSC resourcs to be used in a Chef recipe. For example, the DSC ``Archive`` resource:

.. code-block:: powershell

   Archive ExampleArchive {
     Ensure = "Present"
     Path = "C:\Users\Public\Documents\example.zip"
     Destination = "C:\Users\Public\Documents\ExtractionPath"
   }

and then the same **dsc_resource** with Chef:

.. code-block:: ruby

   dsc_resource 'example' do
      resource :archive
      property :ensure, 'Present'
      property :path, "C:\Users\Public\Documents\example.zip"
      property :destination, "C:\Users\Public\Documents\ExtractionPath"
    end

The full syntax for all of the properties that are available to the **dsc_resource** resource is:

.. code-block:: ruby

   dsc_resource 'name' do
     module_name                String
     module_version             String
     notifies                   # see description
     property                   Symbol
     resource                   String
     subscribes                 # see description
   end

where

* ``dsc_resource`` is the resource
* ``name`` is the name of the resource block
* ``property`` is zero (or more) properties in the DSC resource, where each property is entered on a separate line, ``:dsc_property_name`` is the case-insensitive name of that property, and ``"property_value"`` is a Ruby value to be applied by the chef-client
* ``module_name``, ``module_version``, ``property``, and ``resource`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_dsc_resource_attributes

This resource has the following properties:

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``module_name``
   **Ruby Type:** String

   The name of the module from which a DSC resource originates. If this property is not specified, it will be inferred.

``module_version``
   **Ruby Type:** String

   The version number of the module to use. Powershell 5.0.10018.0 (or higher) supports having multiple versions of a module installed. This should be specified along with the ``module_name``.

   New in Chef Client 12.19.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_notifies_syntax

   The syntax for ``notifies`` is:

   .. code-block:: ruby

      notifies :action, 'resource[name]', :timer

   .. end_tag

``property``
   **Ruby Type:** Symbol

   A property from a Desired State Configuration (DSC) resource. Use this property multiple times, one for each property in the Desired State Configuration (DSC) resource. The format for this property must follow ``property :dsc_property_name, "property_value"`` for each DSC property added to the resource block.

   The ``:dsc_property_name`` must be a symbol.

   .. tag resource_dsc_resource_ruby_types

   Use the following Ruby types to define ``property_value``:

   .. list-table::
      :widths: 250 250
      :header-rows: 1

      * - Ruby
        - Windows PowerShell
      * - ``Array``
        - ``Object[]``
      * - ``Chef::Util::Powershell:PSCredential``
        - ``PSCredential``
      * - ``FalseClass``
        - ``bool($false)``
      * - ``Fixnum``
        - ``Integer``
      * - ``Float``
        - ``Double``
      * - ``Hash``
        - ``Hashtable``
      * - ``TrueClass``
        - ``bool($true)``

   These are converted into the corresponding Windows PowerShell type during the chef-client run.

   .. end_tag

``resource``
   **Ruby Type:** String

   The name of the DSC resource. This value is case-insensitive and must be a symbol that matches the name of the DSC resource.

   .. tag resource_dsc_resource_features

   For built-in DSC resources, use the following values:

   .. list-table::
      :widths: 250 250
      :header-rows: 1

      * - Value
        - Description
      * - ``:archive``
        - Use to to `unpack archive (.zip) files <https://msdn.microsoft.com/en-us/powershell/dsc/archiveresource>`_.
      * - ``:environment``
        - Use to to `manage system environment variables <https://msdn.microsoft.com/en-us/powershell/dsc/environmentresource>`_.
      * - ``:file``
        - Use to to `manage files and directories <https://msdn.microsoft.com/en-us/powershell/dsc/fileresource>`_.
      * - ``:group``
        - Use to to `manage local groups <https://msdn.microsoft.com/en-us/powershell/dsc/groupresource>`_.
      * - ``:log``
        - Use to to `log configuration messages <https://msdn.microsoft.com/en-us/powershell/dsc/logresource>`_.
      * - ``:package``
        - Use to to `install and manage packages <https://msdn.microsoft.com/en-us/powershell/dsc/packageresource>`_.
      * - ``:registry``
        - Use to to `manage registry keys and registry key values <https://msdn.microsoft.com/en-us/powershell/dsc/registryresource>`_.
      * - ``:script``
        - Use to to `run Powershell script blocks <https://msdn.microsoft.com/en-us/powershell/dsc/scriptresource>`_.
      * - ``:service``
        - Use to to `manage services <https://msdn.microsoft.com/en-us/powershell/dsc/serviceresource>`_.
      * - ``:user``
        - Use to to `manage local user accounts <https://msdn.microsoft.com/en-us/powershell/dsc/userresource>`_.
      * - ``:windowsfeature``
        - Use to to `add or remove Windows features and roles <https://msdn.microsoft.com/en-us/powershell/dsc/windowsfeatureresource>`_.
      * - ``:windowsoptionalfeature``
        - Use to configure Microsoft Windows optional features.
      * - ``:windowsprocess``
        - Use to to `configure Windows processes <https://msdn.microsoft.com/en-us/powershell/dsc/windowsprocessresource>`_.

   Any DSC resource may be used in a Chef recipe. For example, the DSC Resource Kit contains resources for `configuring Active Directory components <http://www.powershellgallery.com/packages/xActiveDirectory/2.8.0.0>`_, such as ``xADDomain``, ``xADDomainController``, and ``xADUser``. Assuming that these resources are available to the chef-client, the corresponding values for the ``resource`` attribute would be: ``:xADDomain``, ``:xADDomainController``, and ``xADUser``.

   .. end_tag

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_subscribes_syntax

   The syntax for ``subscribes`` is:

   .. code-block:: ruby

      subscribes :action, 'resource[name]', :timer

   .. end_tag

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**Open a Zip file**

.. tag resource_dsc_resource_zip_file

.. To use a zip file:

.. code-block:: ruby

   dsc_resource 'example' do
      resource :archive
      property :ensure, 'Present'
      property :path, 'C:\Users\Public\Documents\example.zip'
      property :destination, 'C:\Users\Public\Documents\ExtractionPath'
    end

.. end_tag

**Manage users and groups**

.. tag resource_dsc_resource_manage_users

.. To manage users and groups

.. code-block:: ruby

   dsc_resource 'demogroupadd' do
     resource :group
     property :groupname, 'demo1'
     property :ensure, 'present'
   end

   dsc_resource 'useradd' do
     resource :user
     property :username, 'Foobar1'
     property :fullname, 'Foobar1'
     property :password, ps_credential('P@assword!')
     property :ensure, 'present'
   end

   dsc_resource 'AddFoobar1ToUsers' do
     resource :Group
     property :GroupName, 'demo1'
     property :MembersToInclude, ['Foobar1']
   end

.. end_tag

**Create a test message queue**

.. tag resource_dsc_resource_manage_msmq

.. To manage a message queue:

The following example creates a file on a node (based on one that is located in a cookbook), unpacks the ``MessageQueue.zip`` Windows PowerShell module, and then uses the **dsc_resource** to ensure that Message Queuing (MSMQ) sub-features are installed, a test queue is created, and that permissions are set on the test queue:

.. code-block:: ruby

   cookbook_file 'cMessageQueue.zip' do
     path "#{Chef::Config[:file_cache_path]}\\MessageQueue.zip"
     action :create_if_missing
   end

   windows_zipfile "#{ENV['PROGRAMW6432']}\\WindowsPowerShell\\Modules" do
     source "#{Chef::Config[:file_cache_path]}\\MessageQueue.zip"
     action :unzip
   end

   dsc_resource 'install-sub-features' do
     resource :windowsfeature
     property :ensure, 'Present'
     property :name, 'msmq'
     property :IncludeAllSubFeature, true
   end

   dsc_resource 'create-test-queue' do
     resource :cPrivateMsmqQueue
     property :ensure, 'Present'
     property :name, 'Test_Queue'
   end

   dsc_resource 'set-permissions' do
     resource :cPrivateMsmqQueuePermissions
     property :ensure, 'Present'
     property :name, 'Test_Queue_Permissions'
     property :QueueNames, 'Test_Queue'
     property :ReadUsers, node['msmq']['read_user']
   end

.. end_tag

**Example to show usage of module properties**

.. tag resource_dsc_resource_module_properties_usage

.. To show usage of module properties:

.. code-block:: ruby

   dsc_resource 'test-cluster' do
     resource :xCluster
     module_name 'xFailOverCluster'
     module_version '1.6.0.0'
     property :name, 'TestCluster'
     property :staticipaddress, '10.0.0.3'
     property :domainadministratorcredential, ps_credential('abcd')
   end

.. end_tag

dsc_script
-----------------------------------------------------

.. tag resources_common_generic

A :doc:`resource </resource>` defines the desired state for a single configuration item present on a node that is under management by Chef. A resource collection---one (or more) individual resources---defines the desired state for the entire node. During a `chef-client run </chef_client.html#the-chef-client-run>`_, the current state of each resource is tested, after which the chef-client will take any steps that are necessary to repair the node and bring it back into the desired state.

.. end_tag

.. tag resources_common_powershell

Windows PowerShell is a task-based command-line shell and scripting language developed by Microsoft. Windows PowerShell uses a document-oriented approach for managing Microsoft Windows-based machines, similar to the approach that is used for managing UNIX- and Linux-based machines. Windows PowerShell is `a tool-agnostic platform <http://technet.microsoft.com/en-us/library/bb978526.aspx>`_ that supports using Chef for configuration management.

.. end_tag

.. tag resources_common_powershell_dsc

Desired State Configuration (DSC) is a feature of Windows PowerShell that provides `a set of language extensions, cmdlets, and resources <http://technet.microsoft.com/en-us/library/dn249912.aspx>`_ that can be used to declaratively configure software. DSC is similar to Chef, in that both tools are idempotent, take similar approaches to the concept of resources, describe the configuration of a system, and then take the steps required to do that configuration. The most important difference between Chef and DSC is that Chef uses Ruby and DSC is exposed as configuration data from within Windows PowerShell.

.. end_tag

.. tag resource_dsc_script_summary

Many DSC resources are comparable to built-in Chef resources. For example, both DSC and Chef have **file**, **package**, and **service** resources. The **dsc_script** resource is most useful for those DSC resources that do not have a direct comparison to a resource in Chef, such as the ``Archive`` resource, a custom DSC resource, an existing DSC script that performs an important task, and so on. Use the **dsc_script** resource to embed the code that defines a DSC configuration directly within a Chef recipe.

.. end_tag

New in Chef Client 12.2.  Changed in Chef Client 12.6.

.. note:: Windows PowerShell 4.0 is required for using the **dsc_script** resource with Chef.

.. note:: The WinRM service must be enabled. (Use ``winrm quickconfig`` to enable the service.)

.. warning:: The **dsc_script** resource  may not be used in the same run-list with the **dsc_resource**. This is because the **dsc_script** resource requires that ``RefreshMode`` in the Local Configuration Manager be set to ``Push``, whereas the **dsc_resource** resource requires it to be set to ``Disabled``.

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_dsc_script_syntax

A **dsc_script** resource block embeds the code that defines a DSC configuration directly within a Chef recipe:

.. code-block:: ruby

   dsc_script 'get-dsc-resource-kit' do
     code <<-EOH
       Archive reskit
       {
         ensure = 'Present'
         path = "#{Chef::Config[:file_cache_path]}\\DSCResourceKit620082014.zip"
         destination = "#{ENV['PROGRAMW6432']}\\WindowsPowerShell\\Modules"
       }
     EOH
   end

where the **remote_file** resource is first used to download the ``DSCResourceKit620082014.zip`` file.

The full syntax for all of the properties that are available to the **dsc_script** resource is:

.. code-block:: ruby

   dsc_script 'name' do
     code                       String
     command                    String
     configuration_data         String
     configuration_data_script  String
     configuration_name         String
     cwd                        String
     environment                Hash
     flags                      Hash
     imports                    Array
     notifies                   # see description
     subscribes                 # see description
     timeout                    Integer
     action                     Symbol # defaults to :run if not specified
   end

where

* ``dsc_script`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``code``, ``command``, ``configuration_data``, ``configuration_data_script``, ``configuration_name``, ``cwd``, ``environment``, ``flags``, ``imports``, and ``timeout`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_dsc_script_actions

This resource has the following actions:

``:nothing``

   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:run``
   Default. Use to run the DSC configuration defined as defined in this resource.

.. end_tag

Attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_dsc_script_attributes

This resource has the following properties:

``code``
   **Ruby Type:** String

   The code for the DSC configuration script. This property may not be used in the same recipe as the ``command`` property.

``command``
   **Ruby Type:** String

   The path to a valid Windows PowerShell data file that contains the DSC configuration script. This data file must be capable of running independently of Chef and must generate a valid DSC configuration. This property may not be used in the same recipe as the ``code`` property.

``configuration_data``
   **Ruby Type:** String

   The configuration data for the DSC script. The configuration data must be `a valid Windows Powershell data file <http://msdn.microsoft.com/en-us/library/dd878337(v=vs.85).aspx>`_. This property may not be used in the same recipe as the ``configuration_data_script`` property.

``configuration_data_script``
   **Ruby Type:** String

   The path to a valid Windows PowerShell data file that also contains a node called ``localhost``. This property may not be used in the same recipe as the ``configuration_data`` property.

``configuration_name``
   **Ruby Type:** String

   The name of a valid Windows PowerShell cmdlet. The name may only contain letter (a-z, A-Z), number (0-9), and underscore (_) characters and should start with a letter. The name may not be null or empty. This property may not be used in the same recipe as the ``code`` property.

``cwd``
   **Ruby Type:** String

   The current working directory.

``environment``
   **Ruby Type:** Hash

   A Hash of environment variables in the form of ``({"ENV_VARIABLE" => "VALUE"})``. (These variables must exist for a command to be run successfully.)

``flags``
   **Ruby Type:** Hash

   Pass parameters to the DSC script that is specified by the ``command`` property. Parameters are defined as key-value pairs, where the value of each key is the parameter to pass. This property may not be used in the same recipe as the ``code`` property. For example: ``flags ({ :EditorChoice => 'emacs', :EditorFlags => '--maximized' })``. Default value: ``nil``.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``imports``
   **Ruby Type:** Array

   .. warning:: This property **MUST** be used with the ``code`` attribute.

   Use to import DSC resources from a module.

   To import all resources from a module, specify only the module name:

   .. code-block:: ruby

      imports 'module_name'

   To import specific resources, specify the module name, and then specify the name for each resource in that module to import:

   .. code-block:: ruby

      imports 'module_name', 'resource_name_a', 'resource_name_b', ...

   For example, to import all resources from a module named ``cRDPEnabled``:

   .. code-block:: ruby

      imports 'cRDPEnabled'

   To import only the ``PSHOrg_cRDPEnabled`` resource:

   .. code-block:: ruby

      imports 'cRDPEnabled', 'PSHOrg_cRDPEnabled'

   New in Chef Client 12.1.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_notifies_syntax

   The syntax for ``notifies`` is:

   .. code-block:: ruby

      notifies :action, 'resource[name]', :timer

   .. end_tag

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_subscribes_syntax

   The syntax for ``subscribes`` is:

   .. code-block:: ruby

      subscribes :action, 'resource[name]', :timer

   .. end_tag

``timeout``
   **Ruby Types:** Integer

   The amount of time (in seconds) a command is to wait before timing out.

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Specify DSC code directly**

.. tag resource_dsc_script_code

DSC data can be specified directly in a recipe:

.. code-block:: ruby

   dsc_script 'emacs' do
     code <<-EOH
     Environment 'texteditor'
     {
       Name = 'EDITOR'
       Value = 'c:\\emacs\\bin\\emacs.exe'
     }
     EOH
   end

.. end_tag

**Specify DSC code using a Windows Powershell data file**

.. tag resource_dsc_script_command

Use the ``command`` property to specify the path to a Windows PowerShell data file. For example, the following Windows PowerShell script defines the ``DefaultEditor``:

.. code-block:: powershell

   Configuration 'DefaultEditor'
   {
     Environment 'texteditor'
       {
         Name = 'EDITOR'
         Value = 'c:\emacs\bin\emacs.exe'
       }
   }

Use the following recipe to specify the location of that data file:

.. code-block:: ruby

   dsc_script 'DefaultEditor' do
     command 'c:\dsc_scripts\emacs.ps1'
   end

.. end_tag

**Pass parameters to DSC configurations**

.. tag resource_dsc_script_flags

If a DSC script contains configuration data that takes parameters, those parameters may be passed using the ``flags`` property. For example, the following Windows PowerShell script takes parameters for the ``EditorChoice`` and ``EditorFlags`` settings:

.. code-block:: powershell

   $choices = @{'emacs' = 'c:\emacs\bin\emacs';'vi' = 'c:\vim\vim.exe';'powershell' = 'powershell_ise.exe'}
     Configuration 'DefaultEditor'
       {
         [CmdletBinding()]
         param
           (
             $EditorChoice,
             $EditorFlags = ''
           )
         Environment 'TextEditor'
         {
           Name = 'EDITOR'
           Value =  "$($choices[$EditorChoice]) $EditorFlags"
         }
       }

Use the following recipe to set those parameters:

.. code-block:: ruby

   dsc_script 'DefaultEditor' do
     flags ({ :EditorChoice => 'emacs', :EditorFlags => '--maximized' })
     command 'c:\dsc_scripts\editors.ps1'
   end

.. end_tag

**Use custom configuration data**

.. tag resource_dsc_script_custom_config_data

Configuration data in DSC scripts may be customized from a recipe. For example, scripts are typically customized to set the behavior for Windows PowerShell credential data types. Configuration data may be specified in one of three ways:

* By using the ``configuration_data`` attribute
* By using the ``configuration_data_script`` attribute
* By specifying the path to a valid Windows PowerShell data file

.. end_tag

.. tag resource_dsc_script_configuration_data

The following example shows how to specify custom configuration data using the ``configuration_data`` property:

.. code-block:: ruby

   dsc_script 'BackupUser' do
     configuration_data <<-EOH
       @{
        AllNodes = @(
             @{
             NodeName = "localhost";
             PSDscAllowPlainTextPassword = $true
             })
        }
     EOH
     code <<-EOH
       $user = 'backup'
       $password = ConvertTo-SecureString -String "YourPass$(random)" -AsPlainText -Force
       $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $password

      User $user
        {
          UserName = $user
          Password = $cred
          Description = 'Backup operator'
          Ensure = "Present"
          Disabled = $false
          PasswordNeverExpires = $true
          PasswordChangeRequired = $false
        }
      EOH

     configuration_data <<-EOH
       @{
         AllNodes = @(
             @{
             NodeName = "localhost";
             PSDscAllowPlainTextPassword = $true
             })
         }
       EOH
   end

.. end_tag

.. tag resource_dsc_script_configuration_name

The following example shows how to specify custom configuration data using the ``configuration_name`` property. For example, the following Windows PowerShell script defines the ``vi`` configuration:

.. code-block:: powershell

   Configuration 'emacs'
     {
       Environment 'TextEditor'
       {
         Name = 'EDITOR'
         Value = 'c:\emacs\bin\emacs.exe'
       }
   }

   Configuration 'vi'
   {
       Environment 'TextEditor'
       {
         Name = 'EDITOR'
         Value = 'c:\vim\bin\vim.exe'
       }
   }

Use the following recipe to specify that configuration:

.. code-block:: ruby

   dsc_script 'EDITOR' do
     configuration_name 'vi'
     command 'C:\dsc_scripts\editors.ps1'
   end

.. end_tag

**Using DSC with other Chef resources**

.. tag resource_dsc_script_remote_files

The **dsc_script** resource can be used with other resources. The following example shows how to download a file using the **remote_file** resource, and then uncompress it using the DSC ``Archive`` resource:

.. code-block:: ruby

   remote_file "#{Chef::Config[:file_cache_path]}\\DSCResourceKit620082014.zip" do
     source 'http://gallery.technet.microsoft.com/DSC-Resource-Kit-All-c449312d/file/124481/1/DSC%20Resource%20Kit%20Wave%206%2008282014.zip'
   end

   dsc_script 'get-dsc-resource-kit' do
     code <<-EOH
       Archive reskit
       {
         ensure = 'Present'
         path = "#{Chef::Config[:file_cache_path]}\\DSCResourceKit620082014.zip"
         destination = "#{ENV['PROGRAMW6432']}\\WindowsPowerShell\\Modules"
       }
     EOH
   end

.. end_tag

env
-----------------------------------------------------
.. tag resource_env_summary

Use the **env** resource to manage environment keys in Microsoft Windows. After an environment key is set, Microsoft Windows must be restarted before the environment key will be available to the Task Scheduler.

.. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_env_syntax

A **env** resource block manages environment keys in Microsoft Windows:

.. code-block:: ruby

   env 'ComSpec' do
     value 'C:\\Windows\\system32\\cmd.exe'
   end

The full syntax for all of the properties that are available to the **env** resource is:

.. code-block:: ruby

   env 'name' do
     delim                      String
     key_name                   String # defaults to 'name' if not specified
     notifies                   # see description
     provider                   Chef::Provider::Env
     subscribes                 # see description
     value                      String
     action                     Symbol # defaults to :create if not specified
   end

where

* ``env`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``delim``, ``key_name``, ``provider``, and ``value`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_env_actions

This resource has the following actions:

``:create``
   Default. Create an environment variable. If an environment variable already exists (but does not match), update that environment variable to match.

``:delete``
   Delete an environment variable.

``:modify``
   Modify an existing environment variable. This prepends the new value to the existing value, using the delimiter specified by the ``delim`` property.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

.. end_tag

Attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_env_attributes

This resource has the following properties:

``delim``
   **Ruby Type:** String

   The delimiter that is used to separate multiple values for a single key.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``key_name``
   **Ruby Type:** String

   The name of the key that is to be created, deleted, or modified. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_notifies_syntax

   The syntax for ``notifies`` is:

   .. code-block:: ruby

      notifies :action, 'resource[name]', :timer

   .. end_tag

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_subscribes_syntax

   The syntax for ``subscribes`` is:

   .. code-block:: ruby

      subscribes :action, 'resource[name]', :timer

   .. end_tag

``value``
   **Ruby Type:** String

   The value with which ``key_name`` is set.

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Set an environment variable**

.. tag resource_environment_set_variable

.. To set an environment variable:

.. code-block:: ruby

   env 'ComSpec' do
     value "C:\\Windows\\system32\\cmd.exe"
   end

.. end_tag

powershell_script
-----------------------------------------------------
.. tag resource_powershell_script_summary

Use the **powershell_script** resource to execute a script using the Windows PowerShell interpreter, much like how the **script** and **script**-based resources---**bash**, **csh**, **perl**, **python**, and **ruby**---are used. The **powershell_script** is specific to the Microsoft Windows platform and the Windows PowerShell interpreter.

The **powershell_script** resource creates and executes a temporary file (similar to how the **script** resource behaves), rather than running the command inline. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

.. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_powershell_script_syntax

A **powershell_script** resource block executes a batch script using the Windows PowerShell interpreter. For example, writing to an interpolated path:

.. code-block:: ruby

   powershell_script 'write-to-interpolated-path' do
     code <<-EOH
     $stream = [System.IO.StreamWriter] "#{Chef::Config[:file_cache_path]}/powershell-test.txt"
     $stream.WriteLine("In #{Chef::Config[:file_cache_path]}...word.")
     $stream.close()
     EOH
   end

The full syntax for all of the properties that are available to the **powershell_script** resource is:

.. code-block:: ruby

   powershell_script 'name' do
     architecture               Symbol
     code                       String
     command                    String, Array
     convert_boolean_return     TrueClass, FalseClass
     creates                    String
     cwd                        String
     environment                Hash
     flags                      String
     group                      String, Integer
     guard_interpreter          Symbol
     interpreter                String
     notifies                   # see description
     provider                   Chef::Provider::PowershellScript
     returns                    Integer, Array
     subscribes                 # see description
     timeout                    Integer, Float
     user                       String
     password                   String
     domain                     String
     action                     Symbol # defaults to :run if not specified
   end

where

* ``powershell_script`` is the resource
* ``name`` is the name of the resource block
* ``command`` is the command to be run and ``cwd`` is the location from which the command is run
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``architecture``, ``code``, ``command``, ``convert_boolean_return``, ``creates``, ``cwd``, ``environment``, ``flags``, ``group``, ``guard_interpreter``, ``interpreter``, ``provider``, ``returns``,``timeout``, ``user``, ``password`` and ``domain`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_powershell_script_actions

This resource has the following actions:

``:nothing``
   Inherited from **execute** resource. Prevent a command from running. This action is used to specify that a command is run only when another resource notifies it.

``:run``
   Default. Run the script.

.. end_tag

Attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_powershell_script_attributes

This resource has the following properties:

``architecture``
   **Ruby Type:** Symbol

   The architecture of the process under which a script is executed. If a value is not provided, the chef-client defaults to the correct value for the architecture, as determined by Ohai. An exception is raised when anything other than ``:i386`` is specified for a 32-bit process. Possible values: ``:i386`` (for 32-bit processes) and ``:x86_64`` (for 64-bit processes).

``code``
   **Ruby Type:** String

   A quoted (" ") string of code to be executed.

``command``
   **Ruby Types:** String, Array

   The name of the command to be executed. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``convert_boolean_return``
   **Ruby Types:** TrueClass, FalseClass

   Return ``0`` if the last line of a command is evaluated to be true or to return ``1`` if the last line is evaluated to be false. Default value: ``false``.

   When the ``guard_intrepreter`` common attribute is set to ``:powershell_script``, a string command will be evaluated as if this value were set to ``true``. This is because the behavior of this attribute is similar to the value of the ``"$?"`` expression common in UNIX interpreters. For example, this:

   .. code-block:: ruby

      powershell_script 'make_safe_backup' do
        guard_interpreter :powershell_script
        code 'cp ~/data/nodes.json ~/data/nodes.bak'
        not_if 'test-path ~/data/nodes.bak'
      end

   is similar to:

   .. code-block:: ruby

      bash 'make_safe_backup' do
        code 'cp ~/data/nodes.json ~/data/nodes.bak'
        not_if 'test -e ~/data/nodes.bak'
      end

``creates``
   **Ruby Type:** String

   Inherited from **execute** resource. Prevent a command from creating a file when that file already exists.

``cwd``
   **Ruby Type:** String

   Inherited from **execute** resource. The current working directory from which a command is run.

``environment``
   **Ruby Type:** Hash

   Inherited from **execute** resource. A Hash of environment variables in the form of ``({"ENV_VARIABLE" => "VALUE"})``. (These variables must exist for a command to be run successfully.)

``flags``
   **Ruby Type:** String

   A string that is passed to the Windows PowerShell command. Default value: ``-NoLogo, -NonInteractive, -NoProfile, -ExecutionPolicy RemoteSigned, -InputFormat None, -File``.

``group``
   **Ruby Types:** String, Integer

   Inherited from **execute** resource. The group name or group ID that must be changed before running a command.

``guard_interpreter``
   **Ruby Type:** Symbol

   Default value: ``:powershell_script``. When this property is set to ``:powershell_script``, the 64-bit version of the Windows PowerShell shell will be used to evaluate strings values for the ``not_if`` and ``only_if`` properties. Set this value to ``:default`` to use the 32-bit version of the cmd.exe shell.

   Changed in Chef Client 12.0 to default to the specified property.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``interpreter``
   **Ruby Type:** String

   The script interpreter to use during code execution. Changing the default value of this property is not supported.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_notifies_syntax

   The syntax for ``notifies`` is:

   .. code-block:: ruby

      notifies :action, 'resource[name]', :timer

   .. end_tag

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``returns``
   **Ruby Types:** Integer, Array

   Inherited from **execute** resource. The return value for a command. This may be an array of accepted values. An exception is raised when the return value(s) do not match. Default value: ``0``.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_subscribes_syntax

   The syntax for ``subscribes`` is:

   .. code-block:: ruby

      subscribes :action, 'resource[name]', :timer

   .. end_tag

``timeout``
   **Ruby Types:** Integer, Float

   Inherited from **execute** resource. The amount of time (in seconds) a command is to wait before timing out. Default value: ``3600``.

``user``
   **Ruby Types:** String

   The user name of the user identity with which to launch the new process. Default value: `nil`. The user name may optionally be specifed with a domain, i.e. `domain\user` or `user@my.dns.domain.com` via Universal Principal Name (UPN)format. It can also be specified without a domain simply as user if the domain is instead specified using the `domain` attribute. On Windows only, if this property is specified, the `password` property must be specified.

``password``
   **Ruby Types:** String

   *Windows only*: The password of the user specified by the `user` property.
   Default value: `nil`. This property is mandatory if `user` is specified on Windows and may only be specified if `user` is specified. The `sensitive` property for this resource will automatically be set to true if password is specified.

``domain``
   **Ruby Types:** String

   *Windows only*: The domain of the user user specified by the `user` property.
   Default value: `nil`. If not specified, the user name and password specified by the `user` and `password` properties will be used to resolve that user against the domain in which the system running Chef client is joined, or if that system is not joined to a domain it will resolve the user as a local account on that system. An alternative way to specify the domain is to leave this property unspecified and specify the domain as part of the `user` property.

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Write to an interpolated path**

.. tag resource_powershell_write_to_interpolated_path

.. To write out to an interpolated path:

.. code-block:: ruby

   powershell_script 'write-to-interpolated-path' do
     code <<-EOH
     $stream = [System.IO.StreamWriter] "#{Chef::Config[:file_cache_path]}/powershell-test.txt"
     $stream.WriteLine("In #{Chef::Config[:file_cache_path]}...word.")
     $stream.close()
     EOH
   end

.. end_tag

**Change the working directory**

.. tag resource_powershell_cwd

.. To use the change working directory (``cwd``) attribute:

.. code-block:: ruby

   powershell_script 'cwd-then-write' do
     cwd Chef::Config[:file_cache_path]
     code <<-EOH
     $stream = [System.IO.StreamWriter] "C:/powershell-test2.txt"
     $pwd = pwd
     $stream.WriteLine("This is the contents of: $pwd")
     $dirs = dir
     foreach ($dir in $dirs) {
       $stream.WriteLine($dir.fullname)
     }
     $stream.close()
     EOH
   end

.. end_tag

**Change the working directory in Microsoft Windows**

.. tag resource_powershell_cwd_microsoft_env

.. To change the working directory to a Microsoft Windows environment variable:

.. code-block:: ruby

   powershell_script 'cwd-to-win-env-var' do
     cwd '%TEMP%'
     code <<-EOH
     $stream = [System.IO.StreamWriter] "./temp-write-from-chef.txt"
     $stream.WriteLine("chef on windows rox yo!")
     $stream.close()
     EOH
   end

.. end_tag

**Pass an environment variable to a script**

.. tag resource_powershell_pass_env_to_script

.. To pass a Microsoft Windows environment variable to a script:

.. code-block:: ruby

   powershell_script 'read-env-var' do
     cwd Chef::Config[:file_cache_path]
     environment ({'foo' => 'BAZ'})
     code <<-EOH
     $stream = [System.IO.StreamWriter] "./test-read-env-var.txt"
     $stream.WriteLine("FOO is $env:foo")
     $stream.close()
     EOH
   end

.. end_tag

registry_key
-----------------------------------------------------
.. tag resource_registry_key_summary

Use the **registry_key** resource to create and delete registry keys in Microsoft Windows.

.. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_registry_key_syntax

A **registry_key** resource block creates and deletes registry keys in Microsoft Windows:

.. code-block:: ruby

   registry_key "HKEY_LOCAL_MACHINE\\...\\System" do
     values [{
       :name => "NewRegistryKeyValue",
       :type => :multi_string,
       :data => ['foo\0bar\0\0']
     }]
     action :create
   end

Use multiple registry key entries with key values that are based on node attributes:

.. code-block:: ruby

   registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\name_of_registry_key' do
     values [{:name => 'key_name', :type => :string, :data => 'C:\Windows\System32\file_name.bmp'},
             {:name => 'key_name', :type => :string, :data => node['node_name']['attribute']['value']},
             {:name => 'key_name', :type => :string, :data => node['node_name']['attribute']['value']}
            ]
     action :create
   end

The full syntax for all of the properties that are available to the **registry_key** resource is:

.. code-block:: ruby

   registry_key 'name' do
     architecture               Symbol
     key                        String # defaults to 'name' if not specified
     notifies                   # see description
     provider                   Chef::Provider::Windows::Registry
     recursive                  TrueClass, FalseClass
     subscribes                 # see description
     values                     Hash, Array
     action                     Symbol # defaults to :create if not specified
   end

where

* ``registry_key`` is the resource
* ``name`` is the name of the resource block
* ``values`` is a hash that contains at least one registry key to be created or deleted. Each registry key in the hash is grouped by brackets in which the ``:name``, ``:type``, and ``:data`` values for that registry key are specified.
* ``:type`` represents the values available for registry keys in Microsoft Windows. Use ``:binary`` for REG_BINARY, ``:string`` for REG_SZ, ``:multi_string`` for REG_MULTI_SZ, ``:expand_string`` for REG_EXPAND_SZ, ``:dword`` for REG_DWORD, ``:dword_big_endian`` for REG_DWORD_BIG_ENDIAN, or ``:qword`` for REG_QWORD.

  .. warning:: ``:multi_string`` must be an array, even if there is only a single string.
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``architecture``, ``key``, ``provider``, ``recursive`` and ``values`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Path Separators
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag windows_registry_key_backslashes

A Microsoft Windows registry key can be used as a string in Ruby code, such as when a registry key is used as the name of a recipe. In Ruby, when a registry key is enclosed in a double-quoted string (``" "``), the same backslash character (``\``) that is used to define the registry key path separator is also used in Ruby to define an escape character. Therefore, the registry key path separators must be escaped when they are enclosed in a double-quoted string. For example, the following registry key:

.. code-block:: ruby

   HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Themes

may be encloused in a single-quoted string with a single backslash:

.. code-block:: ruby

   'HKCU\SOFTWARE\path\to\key\Themes'

or may be enclosed in a double-quoted string with an extra backslash as an escape character:

.. code-block:: ruby

   "HKCU\\SOFTWARE\\path\\to\\key\\Themes"

.. end_tag

Recipe DSL Methods
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_windows_methods

Six methods are present in the Recipe DSL to help verify the registry during a chef-client run on the Microsoft Windows platform---``registry_data_exists?``, ``registry_get_subkeys``, ``registry_get_values``, ``registry_has_subkeys?``, ``registry_key_exists?``, and ``registry_value_exists?``---these helpers ensure the **powershell_script** resource is idempotent.

.. end_tag

.. note:: .. tag notes_dsl_recipe_order_for_windows_methods

          The recommended order in which registry key-specific methods should be used within a recipe is: ``key_exists?``, ``value_exists?``, ``data_exists?``, ``get_values``, ``has_subkeys?``, and then ``get_subkeys``.

          .. end_tag

registry_data_exists?
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag dsl_recipe_method_registry_data_exists

Use the ``registry_data_exists?`` method to find out if a Microsoft Windows registry key contains the specified data of the specified type under the value.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_data_exists?`` method is as follows:

.. code-block:: ruby

   registry_data_exists?(
     KEY_PATH,
     { :name => 'NAME', :type => TYPE, :data => DATA },
     ARCHITECTURE
   )

where:

* ``KEY_PATH`` is the path to the registry key value. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``{ :name => 'NAME', :type => TYPE, :data => DATA }`` is a hash that contains the expected name, type, and data of the registry key value
* ``:type`` represents the values available for registry keys in Microsoft Windows. Use ``:binary`` for REG_BINARY, ``:string`` for REG_SZ, ``:multi_string`` for REG_MULTI_SZ, ``:expand_string`` for REG_EXPAND_SZ, ``:dword`` for REG_DWORD, ``:dword_big_endian`` for REG_DWORD_BIG_ENDIAN, or ``:qword`` for REG_QWORD.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_get_subkeys
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag dsl_recipe_method_registry_get_subkeys

Use the ``registry_get_subkeys`` method to get a list of registry key values that are present for a Microsoft Windows registry key.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_get_subkeys`` method is as follows:

.. code-block:: ruby

   subkey_array = registry_get_subkeys(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This returns an array of registry key values.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_get_values
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag dsl_recipe_method_registry_get_values

Use the ``registry_get_values`` method to get the registry key values (name, type, and data) for a Microsoft Windows registry key.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_get_values`` method is as follows:

.. code-block:: ruby

   subkey_array = registry_get_values(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This returns an array of registry key values.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_has_subkeys?
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag dsl_recipe_method_registry_has_subkeys

Use the ``registry_has_subkeys?`` method to find out if a Microsoft Windows registry key has one (or more) values.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_has_subkeys?`` method is as follows:

.. code-block:: ruby

   registry_has_subkeys?(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_key_exists?
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag dsl_recipe_method_registry_key_exists

Use the ``registry_key_exists?`` method to find out if a Microsoft Windows registry key exists at the specified path.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_key_exists?`` method is as follows:

.. code-block:: ruby

   registry_key_exists?(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``. (Any registry key values that are associated with this registry key are ignored.)

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_value_exists?
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag dsl_recipe_method_registry_value_exists

Use the ``registry_value_exists?`` method to find out if a registry key value exists. Use ``registry_data_exists?`` to test for the type and data of a registry key value.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_value_exists?`` method is as follows:

.. code-block:: ruby

   registry_value_exists?(
     KEY_PATH,
     { :name => 'NAME' },
     ARCHITECTURE
   )

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``{ :name => 'NAME' }`` is a hash that contains the name of the registry key value; if either ``:type`` or ``:value`` are specified in the hash, they are ignored
* ``:type`` represents the values available for registry keys in Microsoft Windows. Use ``:binary`` for REG_BINARY, ``:string`` for REG_SZ, ``:multi_string`` for REG_MULTI_SZ, ``:expand_string`` for REG_EXPAND_SZ, ``:dword`` for REG_DWORD, ``:dword_big_endian`` for REG_DWORD_BIG_ENDIAN, or ``:qword`` for REG_QWORD.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_registry_key_actions

This resource has the following actions:

``:create``
   Default. Create a registry key. If a registry key already exists (but does not match), update that registry key to match.

``:create_if_missing``
   Create a registry key if it does not exist. Also, create a registry key value if it does not exist.

``:delete``
   Delete the specified values for a registry key.

``:delete_key``
   Delete the specified registry key and all of its subkeys.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

.. note:: .. tag notes_registry_key_resource_recursive

          Be careful when using the ``:delete_key`` action with the ``recursive`` attribute. This will delete the registry key, all of its values and all of the names, types, and data associated with them. This cannot be undone by the chef-client.

          .. end_tag

.. end_tag

Attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_registry_key_attributes

This resource has the following properties:

``architecture``
   **Ruby Type:** Symbol

   The architecture of the node for which keys are to be created or deleted. Possible values: ``:i386`` (for nodes with a 32-bit registry), ``:x86_64`` (for nodes with a 64-bit registry), and ``:machine`` (to have the chef-client determine the architecture during the chef-client run). Default value: ``:machine``.

   In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

   .. note:: .. tag notes_registry_key_architecture

             The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

             .. end_tag

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``key``
   **Ruby Type:** String

   The path to the location in which a registry key is to be created or from which a registry key is to be deleted. Default value: the ``name`` of the resource block See "Syntax" section above for more information.
   The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_notifies_syntax

   The syntax for ``notifies`` is:

   .. code-block:: ruby

      notifies :action, 'resource[name]', :timer

   .. end_tag

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider.

``recursive``
   **Ruby Types:** TrueClass, FalseClass

   When creating a key, this value specifies that the required keys for the specified path are to be created. When using the ``:delete_key`` action in a recipe, and if the registry key has subkeys, then set the value for this property to ``true``.

   .. note:: .. tag notes_registry_key_resource_recursive

             Be careful when using the ``:delete_key`` action with the ``recursive`` attribute. This will delete the registry key, all of its values and all of the names, types, and data associated with them. This cannot be undone by the chef-client.

             .. end_tag

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_subscribes_syntax

   The syntax for ``subscribes`` is:

   .. code-block:: ruby

      subscribes :action, 'resource[name]', :timer

   .. end_tag

``values``
   **Ruby Types:** Hash, Array

   An array of hashes, where each Hash contains the values that are to be set under a registry key. Each Hash must contain ``:name``, ``:type``, and ``:data`` (and must contain no other key values).

   ``:type`` represents the values available for registry keys in Microsoft Windows. Use ``:binary`` for REG_BINARY, ``:string`` for REG_SZ, ``:multi_string`` for REG_MULTI_SZ, ``:expand_string`` for REG_EXPAND_SZ, ``:dword`` for REG_DWORD, ``:dword_big_endian`` for REG_DWORD_BIG_ENDIAN, or ``:qword`` for REG_QWORD.

   .. warning:: ``:multi_string`` must be an array, even if there is only a single string.

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Create a registry key**

.. tag resource_registry_key_create

.. To disable a registry key:

Use a double-quoted string:

.. code-block:: ruby

   registry_key "HKEY_LOCAL_MACHINE\\path-to-key\\Policies\\System" do
     values [{
       :name => 'EnableLUA',
       :type => :dword,
       :data => 0
     }]
     action :create
   end

or a single-quoted string:

.. code-block:: ruby

   registry_key 'HKEY_LOCAL_MACHINE\path-to-key\Policies\System' do
     values [{
       :name => 'EnableLUA',
       :type => :dword,
       :data => 0
     }]
     action :create
   end

.. end_tag

**Delete a registry key value**

.. tag resource_registry_key_delete_value

.. To delete a registry key:

Use a double-quoted string:

.. code-block:: ruby

   registry_key "HKEY_LOCAL_MACHINE\\SOFTWARE\\path\\to\\key\\AU" do
     values [{
       :name => 'NoAutoRebootWithLoggedOnUsers',
       :type => :dword,
       :data => ''
       }]
     action :delete
   end

or a single-quoted string:

.. code-block:: ruby

   registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\path\to\key\AU' do
     values [{
       :name => 'NoAutoRebootWithLoggedOnUsers',
       :type => :dword,
       :data => ''
       }]
     action :delete
   end

.. note:: If ``:data`` is not specified, you get an error: ``Missing data key in RegistryKey values hash``

.. end_tag

**Delete a registry key and its subkeys, recursively**

remote_file
-----------------------------------------------------

**Specify local Windows file path as a valid URI**

.. tag resource_remote_file_local_windows_path

When specifying a local Microsoft Windows file path as a valid file URI, an additional forward slash (``/``) is required. For example:

.. code-block:: ruby

   remote_file 'file:///c:/path/to/file' do
     ...       # other attributes
   end

.. end_tag

windows_package
-----------------------------------------------------
.. tag resource_package_windows

Use the **windows_package** resource to manage Microsoft Installer Package (MSI) packages for the Microsoft Windows platform.

.. end_tag

Changed in 12.4 to include ``checksum`` and ``remote_file_attributes`` and URL locations on the ``source`` properties. Changed in Chef Client 12.6 to support a greater variety of ``installer_type``; Changed in 12.0 for ``installer_type`` to require a symbol.

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_windows_syntax

A **windows_package** resource block manages a package on a node, typically by installing it. The simplest use of the **windows_package** resource is:

.. code-block:: ruby

   windows_package 'package_name'

which will install the named package using all of the default options and the default action (``:install``).

The full syntax for all of the properties that are available to the **windows_package** resource is:

.. code-block:: ruby

   windows_package 'name' do
     checksum                   String
     installer_type             Symbol
     notifies                   # see description
     options                    String
     provider                   Chef::Provider::Package::Windows
     remote_file_attributes     Hash
     returns                    Integer, Array of integers
     source                     String # defaults to 'name' if not specified
     subscribes                 # see description
     timeout                    String, Integer
     action                     Symbol # defaults to :install if not specified
   end

where

* ``windows_package`` tells the chef-client to manage a package
* ``'name'`` is the name of the package
* ``action`` identifies which steps the chef-client will take to bring the node into the desired state
* ``checksum``, ``installer_type``, ``options``, ``package_name``, ``provider``, ``remote_file_attributes``, ``returns``, ``source``, and ``timeout`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_windows_actions

This resource has the following actions:

``:install``
   Default. Install a package. If a version is specified, install the specified version of the package.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:remove``
   Remove a package.

.. end_tag

Attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_windows_attributes

This resource has the following properties:

``checksum``
   **Ruby Type:** String

   The SHA-256 checksum of the file. Use to prevent a file from being re-downloaded. When the local file matches the checksum, the chef-client does not download it. Use when a URL is specified by the ``source`` property.

   New in Chef Client 12.4, changed in 12.6.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``installer_type``
   **Ruby Type:** Symbol

   A symbol that specifies the type of package. Possible values: ``:custom`` (such as installing a non-.msi file that embeds an .msi-based installer), ``:inno`` (Inno Setup), ``:installshield`` (InstallShield), ``:msi`` (Microsoft Installer Package (MSI)), ``:nsis`` (Nullsoft Scriptable Install System (NSIS)), ``:wise`` (Wise).

   Changed in Chef Client 12.6 to support diverse installer types; Changed in 12.0 to require a symbol.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_notifies_syntax

   The syntax for ``notifies`` is:

   .. code-block:: ruby

      notifies :action, 'resource[name]', :timer

   .. end_tag

``options``
   **Ruby Type:** String

   One (or more) additional options that are passed to the command.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider. See "Providers" section below for more information.

``remote_file_attributes``
   **Ruby Type:** Hash

   A package at a remote location define as a Hash of properties that modifes the properties of the **remote_file** resource.

   New in Chef Client 12.4.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``returns``
   **Ruby Types:** Integer, Array of integers

   A comma-delimited list of return codes that indicate the success or failure of the command that was run remotely. This code signals a successful ``:install`` action. Default value: ``0``.

``source``
   **Ruby Type:** String

   Optional. The path to a package in the local file system. The location of the package may be at a URL. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

   If the ``source`` property is not specified, the package name MUST be exactly the same as the display name found in **Add/Remove programs** or exacty the same as the ``DisplayName`` property in the appropriate registry key:

   .. code-block:: ruby

      HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall
      HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall
      HKEY_LOCAL_MACHINE\Software\Wow6464Node\Microsoft\Windows\CurrentVersion\Uninstall

   .. note:: If there are multiple versions of a package installed with the same display name, all of those packages will be removed unless a version is provided in the ``version`` property or unless it can be discovered in the installer file specified by the ``source`` property.

   Changed in Chef Client 12.4 to support URL locations.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_subscribes_syntax

   The syntax for ``subscribes`` is:

   .. code-block:: ruby

      subscribes :action, 'resource[name]', :timer

   .. end_tag

``timeout``
   **Ruby Types:** String, Integer

   The amount of time (in seconds) to wait before timing out. Default value: ``600`` (seconds).

.. end_tag

Providers
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_windows_providers

This resource has the following providers:

``Chef::Provider::Package``, ``package``
   When this short name is used, the chef-client will attempt to determine the correct provider during the chef-client run.

``Chef::Provider::Package::Windows``, ``windows_package``
   The provider for the Microsoft Windows platform.

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Install a package**

.. tag resource_windows_package_install

.. To install a package:

.. code-block:: ruby

   windows_package '7zip' do
     action :install
     source 'C:\7z920.msi'
   end

.. end_tag

**Specify a URL for the source attribute**

.. tag resource_package_windows_source_url

.. To install a package using a URL for the source:

.. code-block:: ruby

   windows_package '7zip' do
     source 'http://www.7-zip.org/a/7z938-x64.msi'
   end

.. end_tag

**Specify path and checksum**

.. tag resource_package_windows_source_url_checksum

.. To install a package using a URL for the source and specifying a checksum:

.. code-block:: ruby

   windows_package '7zip' do
     source 'http://www.7-zip.org/a/7z938-x64.msi'
     checksum '7c8e873991c82ad9cfc123415254ea6101e9a645e12977dcd518979e50fdedf3'
   end

.. end_tag

**Modify remote_file resource attributes**

.. tag resource_package_windows_source_remote_file_attributes

The **windows_package** resource may specify a package at a remote location using the ``remote_file_attributes`` property. This uses the **remote_file** resource to download the contents at the specified URL and passes in a Hash that modifes the properties of the :doc:`remote_file resource </resource_remote_file>`.

For example:

.. code-block:: ruby

   windows_package '7zip' do
     source 'http://www.7-zip.org/a/7z938-x64.msi'
     remote_file_attributes ({
       :path => 'C:\\7zip.msi',
       :checksum => '7c8e873991c82ad9cfc123415254ea6101e9a645e12977dcd518979e50fdedf3'
     })
   end

.. end_tag

**Download a nsis (Nullsoft) package resource**

.. tag resource_package_windows_download_nsis_package

.. To download a nsis (Nullsoft) package resource:

.. code-block:: ruby

   windows_package 'Mercurial 3.6.1 (64-bit)' do
     source 'http://mercurial.selenic.com/release/windows/Mercurial-3.6.1-x64.exe'
     checksum 'febd29578cb6736163d232708b834a2ddd119aa40abc536b2c313fc5e1b5831d'
   end

.. end_tag

**Download a custom package**

.. tag resource_package_windows_download_custom_package

.. To download a custom package:

.. code-block:: ruby

   windows_package 'Microsoft Visual C++ 2005 Redistributable' do
     source 'https://download.microsoft.com/download/6/B/B/6BB661D6-A8AE-4819-B79F-236472F6070C/vcredist_x86.exe'
     installer_type :custom
     options '/Q'
   end

.. end_tag

windows_service
-----------------------------------------------------
.. tag resource_service_windows

Use the **windows_service** resource to manage a service on the Microsoft Windows platform. New in Chef Client 12.0.

.. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_service_windows_syntax

A **windows_service** resource block manages the state of a service on a machine that is running Microsoft Windows. For example:

.. code-block:: ruby

   windows_service 'BITS' do
     action :configure_startup
     startup_type :manual
   end

The full syntax for all of the properties that are available to the **windows_service** resource is:

.. code-block:: ruby

   windows_service 'name' do
     init_command               String
     notifies                   # see description
     pattern                    String
     provider                   Chef::Provider::Service::Windows
     reload_command             String
     restart_command            String
     run_as_password            String
     run_as_user                String
     service_name               String # defaults to 'name' if not specified
     start_command              String
     startup_type               Symbol
     status_command             String
     stop_command               String
     subscribes                 # see description
     supports                   Hash
     timeout                    Integer
     action                     Symbol # defaults to :nothing if not specified
   end

where

* ``windows_service`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``init_command``, ``pattern``, ``provider``, ``reload_command``, ``restart_command``, ``run_as_password``, ``run_as_user``, ``service_name``, ``start_command``, ``startup_type``, ``status_command``, ``stop_command``, ``supports``, and ``timeout`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_service_windows_actions

This resource has the following actions:

``:configure_startup``
   Configure a service based on the value of the ``startup_type`` property.

``:disable``
   Disable a service. This action is equivalent to a ``Disabled`` startup type on the Microsoft Windows platform.

``:enable``
   Enable a service at boot. This action is equivalent to an ``Automatic`` startup type on the Microsoft Windows platform.

``:nothing``
   Default. Do nothing with a service.

``:reload``
   Reload the configuration for this service.

``:restart``
   Restart a service.

``:start``
   Start a service, and keep it running until stopped or disabled.

``:stop``
   Stop a service.

.. end_tag

Attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_service_windows_attributes

This resource has the following properties:

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``init_command``
   **Ruby Type:** String

   The path to the init script that is associated with the service. This is typically ``/etc/init.d/SERVICE_NAME``. The ``init_command`` property can be used to prevent the need to specify  overrides for the ``start_command``, ``stop_command``, and ``restart_command`` attributes. Default value: ``nil``.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_notifies_syntax

   The syntax for ``notifies`` is:

   .. code-block:: ruby

      notifies :action, 'resource[name]', :timer

   .. end_tag

``pattern``
   **Ruby Type:** String

   The pattern to look for in the process table. Default value: ``service_name``.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider.

``reload_command``
   **Ruby Type:** String

   The command used to tell a service to reload its configuration.

``restart_command``
   **Ruby Type:** String

   The command used to restart a service.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``run_as_password``
   **Ruby Type:** String

   The password for the user specified by ``run_as_user``.

   New in Chef Client 12.1.

``run_as_user``
   **Ruby Type:** String

   The user under which a Microsoft Windows service runs.

   New in Chef Client 12.1.

``service_name``
   **Ruby Type:** String

   The name of the service. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``start_command``
   **Ruby Type:** String

   The command used to start a service.

``startup_type``
   **Ruby Type:** Symbol

   Use to specify the startup type for a Microsoft Windows service. Possible values: ``:automatic``, ``:disabled``, or ``:manual``. Default value: ``:automatic``.

``status_command``
   **Ruby Type:** String

   The command used to check the run status for a service.

``stop_command``
   **Ruby Type:** String

   The command used to stop a service.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_subscribes_syntax

   The syntax for ``subscribes`` is:

   .. code-block:: ruby

      subscribes :action, 'resource[name]', :timer

   .. end_tag

``supports``
   **Ruby Type:** Hash

   A list of properties that controls how the chef-client is to attempt to manage a service: ``:restart``, ``:reload``, ``:status``. For ``:restart``, the init script or other service provider can use a restart command; if ``:restart`` is not specified, the chef-client attempts to stop and then start a service. For ``:reload``, the init script or other service provider can use a reload command. For ``:status``, the init script or other service provider can use a status command to determine if the service is running; if ``:status`` is not specified, the chef-client attempts to match the ``service_name`` against the process table as a regular expression, unless a pattern is specified as a parameter property. Default value: ``{ :restart => false, :reload => false, :status => false }`` for all platforms (except for the Red Hat platform family, which defaults to ``{ :restart => false, :reload => false, :status => true }``.)

``timeout``
   **Ruby Type:** Integer

   The amount of time (in seconds) to wait before timing out. Default value: ``60``.

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**Start a service manually**

.. tag resource_service_windows_manual_start

.. To install a package:

.. code-block:: ruby

   windows_service 'BITS' do
     action :configure_startup
     startup_type :manual
   end

.. end_tag

Cookbook Resources
=====================================================
Some of the most popular Chef-maintained cookbooks that contain lightweight resources useful when configuring machines running Microsoft Windows are listed below:

.. list-table::
   :widths: 150 450
   :header-rows: 1

   * - Cookbook
     - Description
   * - `iis <https://github.com/chef-cookbooks/iis>`_
     - The ``iis`` cookbook is used to install and configure Internet Information Services (IIS).
   * - `webpi <https://github.com/chef-cookbooks/webpi>`_
     - The ``webpi`` cookbook is used to run the Microsoft Web Platform Installer (WebPI).
   * - `windows <https://github.com/chef-cookbooks/windows>`_
     - The ``windows`` cookbook is used to configure auto run, batch, reboot, enable built-in operating system packages, configure Microsoft Windows packages, reboot machines, and more.

Recipe DSL Methods
=====================================================
.. tag dsl_recipe_method_windows_methods

Six methods are present in the Recipe DSL to help verify the registry during a chef-client run on the Microsoft Windows platform---``registry_data_exists?``, ``registry_get_subkeys``, ``registry_get_values``, ``registry_has_subkeys?``, ``registry_key_exists?``, and ``registry_value_exists?``---these helpers ensure the **powershell_script** resource is idempotent.

.. end_tag

.. note:: .. tag notes_dsl_recipe_order_for_windows_methods

          The recommended order in which registry key-specific methods should be used within a recipe is: ``key_exists?``, ``value_exists?``, ``data_exists?``, ``get_values``, ``has_subkeys?``, and then ``get_subkeys``.

          .. end_tag

registry_data_exists?
-----------------------------------------------------
.. tag dsl_recipe_method_registry_data_exists

Use the ``registry_data_exists?`` method to find out if a Microsoft Windows registry key contains the specified data of the specified type under the value.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_data_exists?`` method is as follows:

.. code-block:: ruby

   registry_data_exists?(
     KEY_PATH,
     { :name => 'NAME', :type => TYPE, :data => DATA },
     ARCHITECTURE
   )

where:

* ``KEY_PATH`` is the path to the registry key value. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``{ :name => 'NAME', :type => TYPE, :data => DATA }`` is a hash that contains the expected name, type, and data of the registry key value
* ``:type`` represents the values available for registry keys in Microsoft Windows. Use ``:binary`` for REG_BINARY, ``:string`` for REG_SZ, ``:multi_string`` for REG_MULTI_SZ, ``:expand_string`` for REG_EXPAND_SZ, ``:dword`` for REG_DWORD, ``:dword_big_endian`` for REG_DWORD_BIG_ENDIAN, or ``:qword`` for REG_QWORD.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_get_subkeys
-----------------------------------------------------
.. tag dsl_recipe_method_registry_get_subkeys

Use the ``registry_get_subkeys`` method to get a list of registry key values that are present for a Microsoft Windows registry key.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_get_subkeys`` method is as follows:

.. code-block:: ruby

   subkey_array = registry_get_subkeys(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This returns an array of registry key values.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_get_values
-----------------------------------------------------
.. tag dsl_recipe_method_registry_get_values

Use the ``registry_get_values`` method to get the registry key values (name, type, and data) for a Microsoft Windows registry key.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_get_values`` method is as follows:

.. code-block:: ruby

   subkey_array = registry_get_values(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This returns an array of registry key values.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_has_subkeys?
-----------------------------------------------------
.. tag dsl_recipe_method_registry_has_subkeys

Use the ``registry_has_subkeys?`` method to find out if a Microsoft Windows registry key has one (or more) values.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_has_subkeys?`` method is as follows:

.. code-block:: ruby

   registry_has_subkeys?(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_key_exists?
-----------------------------------------------------
.. tag dsl_recipe_method_registry_key_exists

Use the ``registry_key_exists?`` method to find out if a Microsoft Windows registry key exists at the specified path.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_key_exists?`` method is as follows:

.. code-block:: ruby

   registry_key_exists?(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``. (Any registry key values that are associated with this registry key are ignored.)

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_value_exists?
-----------------------------------------------------
.. tag dsl_recipe_method_registry_value_exists

Use the ``registry_value_exists?`` method to find out if a registry key value exists. Use ``registry_data_exists?`` to test for the type and data of a registry key value.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_value_exists?`` method is as follows:

.. code-block:: ruby

   registry_value_exists?(
     KEY_PATH,
     { :name => 'NAME' },
     ARCHITECTURE
   )

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``{ :name => 'NAME' }`` is a hash that contains the name of the registry key value; if either ``:type`` or ``:value`` are specified in the hash, they are ignored
* ``:type`` represents the values available for registry keys in Microsoft Windows. Use ``:binary`` for REG_BINARY, ``:string`` for REG_SZ, ``:multi_string`` for REG_MULTI_SZ, ``:expand_string`` for REG_EXPAND_SZ, ``:dword`` for REG_DWORD, ``:dword_big_endian`` for REG_DWORD_BIG_ENDIAN, or ``:qword`` for REG_QWORD.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

Helpers
-----------------------------------------------------
.. tag dsl_recipe_helper_windows_platform

A recipe can define specific behaviors for specific Microsoft Windows platform versions by using a series of helper methods. To enable these helper methods, add the following to a recipe:

.. code-block:: ruby

   require 'chef/win32/version'

Then declare a variable using the ``Chef::ReservedNames::Win32::Version`` class:

.. code-block:: ruby

   variable_name = Chef::ReservedNames::Win32::Version.new

And then use this variable to define specific behaviors for specific Microsoft Windows platform versions. For example:

.. code-block:: ruby

   if variable_name.helper_name?
     # Ruby code goes here, such as
     resource_name do
       # resource block
     end

   elsif variable_name.helper_name?
     # Ruby code goes here
     resource_name do
       # resource block for something else
     end

   else variable_name.helper_name?
     # Ruby code goes here, such as
     log 'log entry' do
       level :level
     end

   end

.. end_tag

.. tag dsl_recipe_helper_windows_platform_helpers

The following Microsoft Windows platform-specific helpers can be used in recipes:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Helper
     - Description
   * - ``cluster?``
     - Use to test for a Cluster SKU (Windows Server 2003 and later).
   * - ``core?``
     - Use to test for a Core SKU (Windows Server 2003 and later).
   * - ``datacenter?``
     - Use to test for a Datacenter SKU.
   * - ``marketing_name``
     - Use to display the marketing name for a Microsoft Windows platform.
   * - ``windows_7?``
     - Use to test for Windows 7.
   * - ``windows_8?``
     - Use to test for Windows 8.
   * - ``windows_8_1?``
     - Use to test for Windows 8.1.
   * - ``windows_2000?``
     - Use to test for Windows 2000.
   * - ``windows_home_server?``
     - Use to test for Windows Home Server.
   * - ``windows_server_2003?``
     - Use to test for Windows Server 2003.
   * - ``windows_server_2003_r2?``
     - Use to test for Windows Server 2003 R2.
   * - ``windows_server_2008?``
     - Use to test for Windows Server 2008.
   * - ``windows_server_2008_r2?``
     - Use to test for Windows Server 2008 R2.
   * - ``windows_server_2012?``
     - Use to test for Windows Server 2012.
   * - ``windows_server_2012_r2?``
     - Use to test for Windows Server 2012 R2.
   * - ``windows_vista?``
     - Use to test for Windows Vista.
   * - ``windows_xp?``
     - Use to test for Windows XP.

.. end_tag

.. tag dsl_recipe_helper_windows_platform_summary

The following example installs Windows PowerShell 2.0 on systems that do not already have it installed. Microsoft Windows platform helper methods are used to define specific behaviors for specific platform versions:

.. code-block:: ruby

   case node['platform']
   when 'windows'

     require 'chef/win32/version'
     windows_version = Chef::ReservedNames::Win32::Version.new

     if (windows_version.windows_server_2008_r2? || windows_version.windows_7?) && windows_version.core?

       windows_feature 'NetFx2-ServerCore' do
         action :install
       end
       windows_feature 'NetFx2-ServerCore-WOW64' do
         action :install
         only_if { node['kernel']['machine'] == 'x86_64' }
       end

     elsif windows_version.windows_server_2008? || windows_version.windows_server_2003_r2? ||
         windows_version.windows_server_2003? || windows_version.windows_xp?

       if windows_version.windows_server_2008?
         windows_feature 'NET-Framework-Core' do
           action :install
         end

       else
         windows_package 'Microsoft .NET Framework 2.0 Service Pack 2' do
           source node['ms_dotnet2']['url']
           checksum node['ms_dotnet2']['checksum']
           installer_type :custom
           options '/quiet /norestart'
           action :install
         end
       end
     else
       log '.NET Framework 2.0 is already enabled on this version of Windows' do
         level :warn
       end
     end
   else
     log '.NET Framework 2.0 cannot be installed on platforms other than Windows' do
       level :warn
     end
   end

The previous example is from the `ms_dotnet2 cookbook <https://github.com/juliandunn/ms_dotnet2>`_, created by community member ``juliandunn``.

.. end_tag

chef-client
=====================================================
.. tag chef_client_summary

A chef-client is an agent that runs locally on every node that is under management by Chef. When a chef-client is run, it will perform all of the steps that are required to bring the node into the expected state, including:

* Registering and authenticating the node with the Chef server
* Building the node object
* Synchronizing cookbooks
* Compiling the resource collection by loading each of the required cookbooks, including recipes, attributes, and all other dependencies
* Taking the appropriate and required actions to configure the node
* Looking for exceptions and notifications, handling each as required

.. end_tag

This command has the following syntax:

.. code-block:: bash

   $ chef-client OPTION VALUE OPTION VALUE ...

This command has the following options specific to Microsoft Windows:

``-A``, ``--fatal-windows-admin-check``
   Cause a chef-client run to fail when the chef-client does not have administrator privileges in Microsoft Windows.

``-d``, ``--daemonize``
   Run the executable as a daemon.

   This option is only available on machines that run in UNIX or Linux environments. For machines that are running Microsoft Windows that require similar functionality, use the ``chef-client::service`` recipe in the ``chef-client`` cookbook: https://supermarket.chef.io/cookbooks/chef-client. This will install a chef-client service under Microsoft Windows using the Windows Service Wrapper.

.. note:: chef-solo also uses the ``--daemonize`` setting for Microsoft Windows.

Run w/Elevated Privileges
-----------------------------------------------------
.. tag ctl_chef_client_elevated_privileges

The chef-client may need to be run with elevated privileges in order to get a recipe to converge correctly. On UNIX and UNIX-like operating systems this can be done by running the command as root. On Microsoft Windows this can be done by running the command prompt as an administrator.

.. end_tag

.. tag ctl_chef_client_elevated_privileges_windows

On Microsoft Windows, running without elevated privileges (when they are necessary) is an issue that fails silently. It will appear that the chef-client completed its run successfully, but the changes will not have been made. When this occurs, do one of the following to run the chef-client as the administrator:

* Log in to the administrator account. (This is not the same as an account in the administrator's security group.)

* Run the chef-client process from the administrator account while being logged into another account. Run the following command:

   .. code-block:: bash

      $ runas /user:Administrator "cmd /C chef-client"

   This will prompt for the administrator account password.

* Open a command prompt by right-clicking on the command prompt application, and then selecting **Run as administrator**. After the command window opens, the chef-client can be run as the administrator

.. end_tag

knife.rb
=====================================================
When running Microsoft Windows, the knife.rb file is located at ``%HOMEDRIVE%:%HOMEPATH%\.chef`` (e.g. ``c:\Users\<username>\.chef``). If this path needs to be scripted, use ``%USERPROFILE%\.chef``.
