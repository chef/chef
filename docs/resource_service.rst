=====================================================
service
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_service.rst>`__

.. tag resource_service_summary

Use the **service** resource to manage a service.

.. end_tag

Syntax
=====================================================
A **service** resource block manages the state of a service. For example:

.. code-block:: ruby

   service "tomcat" do
     action :start
   end

will start the Apache Tomcat service.

The full syntax for all of the properties that are available to the **service** resource is:

.. code-block:: ruby

   service 'name' do
     init_command               String
     notifies                   # see description
     options                    Array, String
     pattern                    String
     priority                   Integer, String, Hash
     provider                   Chef::Provider::Service
     reload_command             String
     restart_command            String
     service_name               String # defaults to 'name' if not specified
     start_command              String
     status_command             String
     stop_command               String
     subscribes                 # see description
     supports                   Hash
     timeout                    Integer # Microsoft Windows only
     action                     Symbol # defaults to :nothing if not specified
   end

where

* ``service`` is the resource; depending on the platform, more specific providers are run: ``Chef::Provider::Service::Init``, ``Chef::Provider::Service::Init::Debian``, ``Chef::Provider::Service::Upstart``, ``Chef::Provider::Service::Init::Freebsd``, ``Chef::Provider::Service::Init::Gentoo``, ``Chef::Provider::Service::Init::Redhat``, ``Chef::Provider::Service::Solaris``, ``Chef::Provider::Service::Windows``, or ``Chef::Provider::Service::Macosx``
* ``name`` is the name of the resource block; when the ``path`` property is not specified, ``name`` is also the path to the directory, from the root
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``init_command``, ``options``, ``pattern``, ``priority``, ``provider``, ``reload_command``, ``restart_command``, ``service_name``, ``start_command``, ``status_command``, ``stop_command``, ``supports``, and ``timeout`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

``:disable``
   Disable a service. This action is equivalent to a ``Disabled`` startup type on the Microsoft Windows platform. This action is not supported when using System Resource Controller (SRC) on the AIX platform because System Resource Controller (SRC) does not have a standard mechanism for enabling and disabling services on system boot.

``:enable``
   Enable a service at boot. This action is equivalent to an ``Automatic`` startup type on the Microsoft Windows platform. This action is not supported when using System Resource Controller (SRC) on the AIX platform because System Resource Controller (SRC) does not have a standard mechanism for enabling and disabling services on system boot.

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

.. note:: To manage a Microsoft Windows service with a ``Manual`` startup type, the **windows_service** resource must be used.

Properties
=====================================================
This resource has the following properties:

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``init_command``
   **Ruby Type:** String

   The path to the init script that is associated with the service. Use ``init_command`` to prevent the need to specify overrides for the ``start_command``, ``stop_command``, and ``restart_command`` properties. When this property is not specified, the chef-client will use the default init command for the service provider being used.

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
   **Ruby Type:** Array, String

   Solaris platform only. Options to pass to the service command. See the ``svcadm`` manual for details of possible options.

``pattern``
   **Ruby Type:** String

   The pattern to look for in the process table. Default value: ``service_name``.

``priority``
   **Ruby Types:** Integer, String, Hash

   Debian platform only. The relative priority of the program for start and shutdown ordering. May be an integer or a Hash. An integer is used to define the start run levels; stop run levels are then 100-integer. A Hash is used to define values for specific run levels. For example, ``{ 2 => [:start, 20], 3 => [:stop, 55] }`` will set a priority of twenty for run level two and a priority of fifty-five for run level three.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider. See "Providers" section below for more information.

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

``service_name``
   **Ruby Type:** String

   The name of the service. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``start_command``
   **Ruby Type:** String

   The command used to start a service.

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

   Microsoft Windows platform only. The amount of time (in seconds) to wait before timing out. Default value: ``60``.

Providers
=====================================================
.. tag resources_common_provider

Where a resource represents a piece of the system (and its desired state), a provider defines the steps that are needed to bring that piece of the system from its current state into the desired state.

.. end_tag

.. tag resources_common_provider_attributes

The chef-client will determine the correct provider based on configuration data collected by Ohai at the start of the chef-client run. This configuration data is then mapped to a platform and an associated list of providers.

Generally, it's best to let the chef-client choose the provider, and this is (by far) the most common approach. However, in some cases, specifying a provider may be desirable. There are two approaches:

* Use a more specific short name---``yum_package "foo" do`` instead of ``package "foo" do``, ``script "foo" do`` instead of ``bash "foo" do``, and so on---when available
* Use the ``provider`` property within the resource block to specify the long name of the provider as a property of a resource. For example: ``provider Chef::Provider::Long::Name``

.. end_tag

The **service** resource does not have service-specific short names. This is because the chef-client identifies the platform at the start of every chef-client run based on data collected by Ohai. The chef-client looks up the platform, and then determines the correct provider for that platform. In certain situations, such as when more than one init system is available on a node, a specific provider may need to be identified by using the ``provider`` attribute and the long name for that provider.

This resource has the following providers:

``Chef::Provider::Service::Init``, ``service``
   When this short name is used, the chef-client will determine the correct provider during the chef-client run.

``Chef::Provider::Service::Aix``, ``service``
   Default on the AIX platform. The provider that is used to start, stop, and restart services with System Resource Controller (SRC).

``Chef::Provider::Service::AixInit``
   Use the long name---``Chef::Provider::Service::AixInit``---in a recipe to manage services with BSD-based init systems on the AIX platform.

``Chef::Provider::Service::Init::Debian``, ``service``
   The provider for the Debian and Ubuntu platforms.

``Chef::Provider::Service::Init::Freebsd``, ``service``
   The provider for the FreeBSD platform.

``Chef::Provider::Service::Init::Gentoo``, ``service``
   The provider for the Gentoo platform.

``Chef::Provider::Service::Init::Redhat``, ``service``
   The provider for the Red Hat and CentOS platforms.

``Chef::Provider::Service::Simple``
   A provider that is used to create custom service providers by defining the custom provider as a sub-class of this provider. This provider should not be used in recipes as a value of the ``provider`` attribute.

``Chef::Provider::Service::Solaris``, ``service``
   The provider for the Solaris platform.

``Chef::Provider::Service::Systemd``, ``systemd``
   The provider that is used when systemd is available on the platform.

``Chef::Provider::Service::Upstart``, ``service``
   The provider that is used when Upstart is available on the platform.

``Chef::Provider::Service::Windows``, ``service``
   The provider for the Microsoft Windows platform.

``Chef::Provider::Service::Macosx``, ``service``
   The provider for the macOS platform.

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Start a service**

.. tag resource_service_start_service

.. To start a service when it is not running:

.. code-block:: ruby

   service 'example_service' do
     action :start
   end

.. end_tag

**Start a service, enable it**

.. tag resource_service_start_service_and_enable_at_boot

.. To start the service when it is not running and enable it so that it starts at system boot time:

.. code-block:: ruby

   service 'example_service' do
     supports :status => true, :restart => true, :reload => true
     action [ :enable, :start ]
   end

.. end_tag

**Use a pattern**

.. tag resource_service_process_table_has_different_value

.. To handle situations when the process table has a different value than the name of the service script:

.. code-block:: ruby

   service 'samba' do
     pattern 'smbd'
     action [:enable, :start]
   end

.. end_tag

**Use the :nothing common action**

.. tag resource_service_use_nothing_action

.. To use the ``:nothing`` common action in a recipe:

.. code-block:: ruby

   service 'memcached' do
     action :nothing
     supports :status => true, :start => true, :stop => true, :restart => true
   end

.. end_tag

**Use the supports common attribute**

.. tag resource_service_use_supports_attribute

.. To use the ``supports`` common attribute in a recipe:

.. code-block:: ruby

   service 'apache' do
     supports :restart => true, :reload => true
     action :enable
   end

.. end_tag

**Use the supports and providers common attributes**

.. tag resource_service_use_provider_and_supports_attributes

.. To use the ``provider`` and ``supports`` common attributes in a recipe:

.. code-block:: ruby

   service 'some_service' do
     provider Chef::Provider::Service::Upstart
     supports :status => true, :restart => true, :reload => true
     action [ :enable, :start ]
   end

.. end_tag

**Manage a service, depending on the node platform**

.. tag resource_service_manage_ssh_based_on_node_platform

.. To manage a service whose name depends on the platform of the node on which it runs:

.. code-block:: ruby

   service 'example_service' do
     case node['platform']
     when 'centos','redhat','fedora'
       service_name 'redhat_name'
     else
       service_name 'other_name'
     end
     supports :restart => true
     action [ :enable, :start ]
   end

.. end_tag

**Change a service provider, depending on the node platform**

.. tag resource_service_change_service_provider_based_on_node

.. To change a service provider depending on a node's platform:

.. code-block:: ruby

   service 'example_service' do
     case node['platform']
     when 'ubuntu'
       if node['platform_version'].to_f >= 9.10
         provider Chef::Provider::Service::Upstart
       end
     end
     action [:enable, :start]
   end

.. end_tag

**Reload a service using a template**

.. tag resource_service_subscribes_reload_using_template

To reload a service based on a template, use the **template** and **service** resources together in the same recipe, similar to the following:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
   end

   service 'apache' do
     supports :restart => true, :reload => true
     action :enable
     subscribes :reload, 'template[/tmp/somefile]', :immediately
   end

where the ``subscribes`` notification is used to reload the service using the template specified by the **template** resource.

.. end_tag

**Enable a service after a restart or reload**

.. tag resource_service_notifies_enable_after_restart_or_reload

.. To enable a service after restarting or reloading it:

.. code-block:: ruby

   service 'apache' do
     supports :restart => true, :reload => true
     action :enable
   end

.. end_tag

**Set an IP address using variables and a template**

.. tag resource_template_set_ip_address_with_variables_and_template

The following example shows how the **template** resource can be used in a recipe to combine settings stored in an attributes file, variables within a recipe, and a template to set the IP addresses that are used by the Nginx service. The attributes file contains the following:

.. code-block:: ruby

   default['nginx']['dir'] = '/etc/nginx'

The recipe then does the following to:

* Declare two variables at the beginning of the recipe, one for the remote IP address and the other for the authorized IP address
* Use the **service** resource to restart and reload the Nginx service
* Load a template named ``authorized_ip.erb`` from the ``/templates`` directory that is used to set the IP address values based on the variables specified in the recipe

.. code-block:: ruby

   node.default['nginx']['remote_ip_var'] = 'remote_addr'
   node.default['nginx']['authorized_ips'] = ['127.0.0.1/32']

   service 'nginx' do
     supports :status => true, :restart => true, :reload => true
   end

   template 'authorized_ip' do
     path "#{node['nginx']['dir']}/authorized_ip"
     source 'modules/authorized_ip.erb'
     owner 'root'
     group 'root'
     mode '0755'
     variables(
       :remote_ip_var => node['nginx']['remote_ip_var'],
       :authorized_ips => node['nginx']['authorized_ips']
     )

     notifies :reload, 'service[nginx]', :immediately
   end

where the ``variables`` property tells the template to use the variables set at the beginning of the recipe and the ``source`` property is used to call a template file located in the cookbook's ``/templates`` directory. The template file looks similar to:

.. code-block:: ruby

   geo $<%= @remote_ip_var %> $authorized_ip {
     default no;
     <% @authorized_ips.each do |ip| %>
     <%= "#{ip} yes;" %>
     <% end %>
   }

.. end_tag

**Use a cron timer to manage a service**

.. tag resource_service_use_variable

The following example shows how to install the crond application using two resources and a variable:

.. code-block:: ruby

   # the following code sample comes from the ``cron`` cookbook:
   # https://github.com/chef-cookbooks/cron

   cron_package = case node['platform']
     when 'redhat', 'centos', 'scientific', 'fedora', 'amazon'
       node['platform_version'].to_f >= 6.0 ? 'cronie' : 'vixie-cron'
     else
       'cron'
     end

   package cron_package do
     action :install
   end

   service 'crond' do
     case node['platform']
     when 'redhat', 'centos', 'scientific', 'fedora', 'amazon'
       service_name 'crond'
     when 'debian', 'ubuntu', 'suse'
       service_name 'cron'
     end
     action [:start, :enable]
   end

where

* ``cron_package`` is a variable that is used to identify which platforms apply to which install packages
* the **package** resource uses the ``cron_package`` variable to determine how to install the crond application on various nodes (with various platforms)
* the **service** resource enables the crond application on nodes that have Red Hat, CentOS, Red Hat Enterprise Linux, Fedora, or Amazon Web Services (AWS), and the cron service on nodes that run Debian, Ubuntu, or openSUSE

.. end_tag

**Restart a service, and then notify a different service**

.. tag resource_service_restart_and_notify

The following example shows how start a service named ``example_service`` and immediately notify the Nginx service to restart.

.. code-block:: ruby

   service 'example_service' do
     action :start
     provider Chef::Provider::Service::Init
     notifies :restart, 'service[nginx]', :immediately
   end

where by using the default ``provider`` for the **service**, the recipe is telling the chef-client to determine the specific provider to be used during the chef-client run based on the platform of the node on which the recipe will run.

.. end_tag

**Stop a service, do stuff, and then restart it**

.. tag resource_service_stop_do_stuff_start

The following example shows how to use the **execute**, **service**, and **mount** resources together to ensure that a node running on Amazon EC2 is running MySQL. This example does the following:

* Checks to see if the Amazon EC2 node has MySQL
* If the node has MySQL, stops MySQL
* Installs MySQL
* Mounts the node
* Restarts MySQL

.. code-block:: ruby

   # the following code sample comes from the ``server_ec2``
   # recipe in the following cookbook:
   # https://github.com/chef-cookbooks/mysql

   if (node.attribute?('ec2') && ! FileTest.directory?(node['mysql']['ec2_path']))

     service 'mysql' do
       action :stop
     end

     execute 'install-mysql' do
       command "mv #{node['mysql']['data_dir']} #{node['mysql']['ec2_path']}"
       not_if do FileTest.directory?(node['mysql']['ec2_path']) end
     end

     [node['mysql']['ec2_path'], node['mysql']['data_dir']].each do |dir|
       directory dir do
         owner 'mysql'
         group 'mysql'
       end
     end

     mount node['mysql']['data_dir'] do
       device node['mysql']['ec2_path']
       fstype 'none'
       options 'bind,rw'
       action [:mount, :enable]
     end

     service 'mysql' do
       action :start
     end

   end

where

* the two **service** resources are used to stop, and then restart the MySQL service
* the **execute** resource is used to install MySQL
* the **mount** resource is used to mount the node and enable MySQL

.. end_tag

**Control a service using the execute resource**

.. tag resource_execute_control_a_service

.. warning:: This is an example of something that should NOT be done. Use the **service** resource to control a service, not the **execute** resource.

Do something like this:

.. code-block:: ruby

   service 'tomcat' do
     action :start
   end

and NOT something like this:

.. code-block:: ruby

   execute 'start-tomcat' do
     command '/etc/init.d/tomcat6 start'
     action :run
   end

There is no reason to use the **execute** resource to control a service because the **service** resource exposes the ``start_command`` property directly, which gives a recipe full control over the command issued in a much cleaner, more direct manner.

.. end_tag

**Enable a service on AIX using the mkitab command**

.. tag resource_service_aix_mkitab

The **service** resource does not support using the ``:enable`` and ``:disable`` actions with resources that are managed using System Resource Controller (SRC). This is because System Resource Controller (SRC) does not have a standard mechanism for enabling and disabling services on system boot.

One approach for enabling or disabling services that are managed by System Resource Controller (SRC) is to use the **execute** resource to invoke ``mkitab``, and then use that command to enable or disable the service.

The following example shows how to install a service:

.. code-block:: ruby

   execute "install #{node['chef_client']['svc_name']} in SRC" do
     command "mkssys -s #{node['chef_client']['svc_name']}
                     -p #{node['chef_client']['bin']}
                     -u root
                     -S
                     -n 15
                     -f 9
                     -o #{node['chef_client']['log_dir']}/client.log
                     -e #{node['chef_client']['log_dir']}/client.log -a '
                     -i #{node['chef_client']['interval']}
                     -s #{node['chef_client']['splay']}'"
     not_if "lssrc -s #{node['chef_client']['svc_name']}"
     action :run
   end

and then enable it using the ``mkitab`` command:

.. code-block:: ruby

   execute "enable #{node['chef_client']['svc_name']}" do
     command "mkitab '#{node['chef_client']['svc_name']}:2:once:/usr/bin/startsrc
                     -s #{node['chef_client']['svc_name']} > /dev/console 2>&1'"
     not_if "lsitab #{node['chef_client']['svc_name']}"
   end

.. end_tag

