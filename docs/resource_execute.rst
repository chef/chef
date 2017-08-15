=====================================================
execute
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_execute.rst>`__

.. tag resource_execute_summary

Use the **execute** resource to execute a single command. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

.. end_tag

.. note:: Use the **script** resource to execute a script using a specific interpreter (Ruby, Python, Perl, csh, or Bash).

Changed in 12.19 to support windows alternate user identity in execute resources.

Syntax
=====================================================
A **execute** resource block typically executes a single command that is unique to the environment in which a recipe will run. Some **execute** resource commands are run by themselves, but often they are run in combination with other Chef resources. For example, a single command that is run by itself:

.. code-block:: ruby

   execute 'apache_configtest' do
     command '/usr/sbin/apachectl configtest'
   end

where ``'/usr/sbin/apachectl configtest'`` is a command that tests if the configuration files for Apache are valid.

Commands are often run in combination with other Chef resources. The following example shows the **template** resource run with the **execute** resource to add an entry to a LDAP Directory Interchange Format (LDIF) file:

.. code-block:: ruby

   execute 'slapadd' do
     command 'slapadd < /tmp/something.ldif'
     creates '/var/lib/slapd/uid.bdb'
     action :nothing
   end

   template '/tmp/something.ldif' do
     source 'something.ldif'
     notifies :run, 'execute[slapadd]', :immediately
   end

where

* ``'/tmp/something.ldif'`` specifies the location of the file
* ``'something.ldif'`` specifies template file from which ``/tmp/something.ldif`` is created
* ``'slapadd < /tmp/something.ldif'`` is the command that is run
* ``/var/lib/slapd/uid.bdb`` prevents the **execute** resource block from running if that file already exists

The full syntax for all of the properties that are available to the **execute** resource is:

.. code-block:: ruby

   execute 'name' do
     command                    String, Array # defaults to 'name' if not specified
     creates                    String
     cwd                        String
     environment                Hash # env is an alias for environment
     group                      String, Integer
     live_stream                TrueClass, FalseClass
     notifies                   # see description
     path                       Array
     provider                   Chef::Provider::Execute
     returns                    Integer, Array
     sensitive                  TrueClass, FalseClass
     subscribes                 # see description
     timeout                    Integer, Float
     umask                      String, Integer
     user                       String
     password                   String
     domain                     String
     action                     Symbol # defaults to :run if not specified
   end

where

* ``execute`` is the resource
* ``name`` is the name of the resource block
* ``command`` is the command to be run
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``command``, ``creates``, ``cwd``, ``environment``, ``group``, ``live_stream``, ``path``, ``provider``, ``returns``, ``sensitive``, ``timeout``, ``user``, ``password``, ``domain`` and ``umask`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

``:nothing``
   Prevent a command from running. This action is used to specify that a command is run only when another resource notifies it.

``:run``
   Default. Run a command.

Properties
=====================================================
This resource has the following properties:

``command``
   **Ruby Types:** String, Array

   The name of the command to be executed. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

   .. note:: Use the **execute** resource to run a single command. Use multiple **execute** resource blocks to run multiple commands.

``creates``
   **Ruby Type:** String

   Prevent a command from creating a file when that file already exists.

``cwd``
   **Ruby Type:** String

   The current working directory from which a command is run.

``environment``
   **Ruby Type:** Hash

   A Hash of environment variables in the form of ``({"ENV_VARIABLE" => "VALUE"})``. (These variables must exist for a command to be run successfully.)

``group``
   **Ruby Types:** String, Integer

   The group name or group ID that must be changed before running a command.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``live_stream``
   **Ruby Types:** TrueClass, FalseClass

   Send the output of the command run by this **execute** resource block to the chef-client event stream. Default value: ``false``.

   New in Chef Client 12.6.

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

``path``
   **Ruby Type:** Array

   An array of paths to use when searching for a command. These paths are not added to the command's environment $PATH. The default value uses the system path.

   .. warning::
      .. tag resources_common_resource_execute_attribute_path

      The ``path`` property has been deprecated and will throw an exception in Chef Client 12 or later. We recommend you use the ``environment`` property instead.

      .. end_tag

      For example:

      .. code-block:: ruby

         execute 'mycommand' do
           environment 'PATH' => "/my/path/to/bin:#{ENV['PATH']}"
         end

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

``sensitive``
   **Ruby Types:** TrueClass, FalseClass

   Ensure that sensitive resource data is not logged by the chef-client. Default value: ``false``.

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

``umask``
   **Ruby Types:** String, Integer

   The file mode creation mask, or umask.

Guards
-----------------------------------------------------
.. tag resources_common_guards

A guard property can be used to evaluate the state of a node during the execution phase of the chef-client run. Based on the results of this evaluation, a guard property is then used to tell the chef-client if it should continue executing a resource. A guard property accepts either a string value or a Ruby block value:

* A string is executed as a shell command. If the command returns ``0``, the guard is applied. If the command returns any other value, then the guard property is not applied. String guards in a **powershell_script** run Windows PowerShell commands and may return ``true`` in addition to ``0``.
* A block is executed as Ruby code that must return either ``true`` or ``false``. If the block returns ``true``, the guard property is applied. If the block returns ``false``, the guard property is not applied.

A guard property is useful for ensuring that a resource is idempotent by allowing that resource to test for the desired state as it is being executed, and then if the desired state is present, for the chef-client to do nothing.

.. end_tag

.. note:: .. tag resources_common_guards_execute_resource

          When using the ``not_if`` and ``only_if`` guards with the **execute** resource, the current working directory property (``cwd``) is **not** inherited from the resource. For example:

          .. code-block:: ruby

             execute 'bundle install' do
               cwd '/myapp'
               not_if 'bundle check' # This is not run inside /myapp
             end

          .. end_tag

**Attributes**

.. tag resources_common_guards_attributes

The following properties can be used to define a guard that is evaluated during the execution phase of the chef-client run:

``not_if``
   Prevent a resource from executing when the condition returns ``true``.

``only_if``
   Allow a resource to execute only if the condition returns ``true``.

.. end_tag

**Arguments**

.. tag resources_common_guards_arguments

The following arguments can be used with the ``not_if`` or ``only_if`` guard properties:

``:user``
   Specify the user that a command will run as. For example:

   .. code-block:: ruby

      not_if 'grep adam /etc/passwd', :user => 'adam'

``:group``
   Specify the group that a command will run as. For example:

   .. code-block:: ruby

      not_if 'grep adam /etc/passwd', :group => 'adam'

``:environment``
   Specify a Hash of environment variables to be set. For example:

   .. code-block:: ruby

      not_if 'grep adam /etc/passwd', :environment => {
        'HOME' => '/home/adam'
      }

``:cwd``
   Set the current working directory before running a command. For example:

   .. code-block:: ruby

      not_if 'grep adam passwd', :cwd => '/etc'

``:timeout``
   Set a timeout for a command. For example:

   .. code-block:: ruby

      not_if 'sleep 10000', :timeout => 10

.. end_tag

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Run a command upon notification**

.. tag resource_execute_command_upon_notification

.. To execute a command only upon notification:

.. code-block:: ruby

   execute 'slapadd' do
     command 'slapadd < /tmp/something.ldif'
     creates '/var/lib/slapd/uid.bdb'
     action :nothing
   end

   template '/tmp/something.ldif' do
     source 'something.ldif'
     notifies :run, 'execute[slapadd]', :immediately
   end

.. end_tag

**Run a touch file only once while running a command**

.. tag resource_execute_command_with_touch_file

.. To execute a command with a touch file running only once:

.. code-block:: ruby

   execute 'upgrade script' do
     command 'php upgrade-application.php && touch /var/application/.upgraded'
     creates '/var/application/.upgraded'
     action :run
   end

.. end_tag

**Run a command which requires an environment variable**

.. tag resource_execute_command_with_variable

.. To execute a command with an environment variable:

.. code-block:: ruby

   execute 'slapadd' do
     command 'slapadd < /tmp/something.ldif'
     creates '/var/lib/slapd/uid.bdb'
     action :run
     environment ({'HOME' => '/home/myhome'})
   end

.. end_tag

**Delete a repository using yum to scrub the cache**

.. tag resource_yum_package_delete_repo_use_yum_to_scrub_cache

.. To delete a repository while using Yum to scrub the cache to avoid issues:

.. code-block:: ruby

   # the following code sample thanks to gaffneyc @ https://gist.github.com/918711

   execute 'clean-yum-cache' do
     command 'yum clean all'
     action :nothing
   end

   file '/etc/yum.repos.d/bad.repo' do
     action :delete
     notifies :run, 'execute[clean-yum-cache]', :immediately
     notifies :create, 'ruby_block[reload-internal-yum-cache]', :immediately
   end

.. end_tag

**Install repositories from a file, trigger a command, and force the internal cache to reload**

.. tag resource_yum_package_install_yum_repo_from_file

The following example shows how to install new Yum repositories from a file, where the installation of the repository triggers a creation of the Yum cache that forces the internal cache for the chef-client to reload:

.. code-block:: ruby

   execute 'create-yum-cache' do
    command 'yum -q makecache'
    action :nothing
   end

   ruby_block 'reload-internal-yum-cache' do
     block do
       Chef::Provider::Package::Yum::YumCache.instance.reload
     end
     action :nothing
   end

   cookbook_file '/etc/yum.repos.d/custom.repo' do
     source 'custom'
     mode '0755'
     notifies :run, 'execute[create-yum-cache]', :immediately
     notifies :create, 'ruby_block[reload-internal-yum-cache]', :immediately
   end

.. end_tag

**Prevent restart and reconfigure if configuration is broken**

.. tag resource_execute_subscribes_prevent_restart_and_reconfigure

Use the ``:nothing`` action (common to all resources) to prevent an application from restarting, and then use the ``subscribes`` notification to ask the broken configuration to be reconfigured immediately:

.. code-block:: ruby

   execute 'test-nagios-config' do
     command 'nagios3 --verify-config'
     action :nothing
     subscribes :run, 'template[/etc/nagios3/configures-nagios.conf]', :immediately
   end

.. end_tag

**Notify in a specific order**

.. tag resource_execute_notifies_specific_order

To notify multiple resources, and then have these resources run in a certain order, do something like the following:

.. code-block:: ruby

   execute 'foo' do
     command '...'
     notifies :create, 'template[baz]', :immediately
     notifies :install, 'package[bar]', :immediately
     notifies :run, 'execute[final]', :immediately
   end

   template 'baz' do
     ...
     notifies :run, 'execute[restart_baz]', :immediately
   end

   package 'bar'

   execute 'restart_baz'

   execute 'final' do
     command '...'
   end

where the sequencing will be in the same order as the resources are listed in the recipe: ``execute 'foo'``, ``template 'baz'``, ``execute [restart_baz]``, ``package 'bar'``, and ``execute 'final'``.

.. end_tag

**Execute a command using a template**

.. tag resource_execute_command_from_template

The following example shows how to set up IPv4 packet forwarding using the **execute** resource to run a command named ``forward_ipv4`` that uses a template defined by the **template** resource:

.. code-block:: ruby

   execute 'forward_ipv4' do
     command 'echo > /proc/.../ipv4/ip_forward'
     action :nothing
   end

   template '/etc/file_name.conf' do
     source 'routing/file_name.conf.erb'
     notifies :run, 'execute[forward_ipv4]', :delayed
   end

where the ``command`` property for the **execute** resource contains the command that is to be run and the ``source`` property for the **template** resource specifies which template to use. The ``notifies`` property for the **template** specifies that the ``execute[forward_ipv4]`` (which is defined by the **execute** resource) should be queued up and run at the end of the chef-client run.

.. end_tag

**Add a rule to an IP table**

.. tag resource_execute_add_rule_to_iptable

The following example shows how to add a rule named ``test_rule`` to an IP table using the **execute** resource to run a command using a template that is defined by the **template** resource:

.. code-block:: ruby

   execute 'test_rule' do
     command 'command_to_run
       --option value
       ...
       --option value
       --source #{node[:name_of_node][:ipsec][:local][:subnet]}
       -j test_rule'
     action :nothing
   end

   template '/etc/file_name.local' do
     source 'routing/file_name.local.erb'
     notifies :run, 'execute[test_rule]', :delayed
   end

where the ``command`` property for the **execute** resource contains the command that is to be run and the ``source`` property for the **template** resource specifies which template to use. The ``notifies`` property for the **template** specifies that the ``execute[test_rule]`` (which is defined by the **execute** resource) should be queued up and run at the end of the chef-client run.

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

**Use the platform_family? method**

.. tag resource_remote_file_use_platform_family

The following is an example of using the ``platform_family?`` method in the Recipe DSL to create a variable that can be used with other resources in the same recipe. In this example, ``platform_family?`` is being used to ensure that a specific binary is used for a specific platform before using the **remote_file** resource to download a file from a remote location, and then using the **execute** resource to install that file by running a command.

.. code-block:: ruby

   if platform_family?('rhel')
     pip_binary = '/usr/bin/pip'
   else
     pip_binary = '/usr/local/bin/pip'
   end

   remote_file "#{Chef::Config[:file_cache_path]}/distribute_setup.py" do
     source 'http://python-distribute.org/distribute_setup.py'
     mode '0755'
     not_if { File.exist?(pip_binary) }
   end

   execute 'install-pip' do
     cwd Chef::Config[:file_cache_path]
     command <<-EOF
       # command for installing Python goes here
       EOF
     not_if { File.exist?(pip_binary) }
   end

where a command for installing Python might look something like:

.. code-block:: ruby

    #{node['python']['binary']} distribute_setup.py
    #{::File.dirname(pip_binary)}/easy_install pip

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

**Use the search recipe DSL method to find users**

.. tag resource_execute_use_search_dsl_method

The following example shows how to use the ``search`` method in the Recipe DSL to search for users:

.. code-block:: ruby

   #  the following code sample comes from the openvpn cookbook: https://github.com/chef-cookbooks/openvpn

   search("users", "*:*") do |u|
     execute "generate-openvpn-#{u['id']}" do
       command "./pkitool #{u['id']}"
       cwd '/etc/openvpn/easy-rsa'
       environment(
         'EASY_RSA' => '/etc/openvpn/easy-rsa',
         'KEY_CONFIG' => '/etc/openvpn/easy-rsa/openssl.cnf',
         'KEY_DIR' => node['openvpn']['key_dir'],
         'CA_EXPIRE' => node['openvpn']['key']['ca_expire'].to_s,
         'KEY_EXPIRE' => node['openvpn']['key']['expire'].to_s,
         'KEY_SIZE' => node['openvpn']['key']['size'].to_s,
         'KEY_COUNTRY' => node['openvpn']['key']['country'],
         'KEY_PROVINCE' => node['openvpn']['key']['province'],
         'KEY_CITY' => node['openvpn']['key']['city'],
         'KEY_ORG' => node['openvpn']['key']['org'],
         'KEY_EMAIL' => node['openvpn']['key']['email']
       )
       not_if { File.exist?("#{node['openvpn']['key_dir']}/#{u['id']}.crt") }
     end

     %w{ conf ovpn }.each do |ext|
       template "#{node['openvpn']['key_dir']}/#{u['id']}.#{ext}" do
         source 'client.conf.erb'
         variables :username => u['id']
       end
     end

     execute "create-openvpn-tar-#{u['id']}" do
       cwd node['openvpn']['key_dir']
       command <<-EOH
         tar zcf #{u['id']}.tar.gz \
         ca.crt #{u['id']}.crt #{u['id']}.key \
         #{u['id']}.conf #{u['id']}.ovpn \
       EOH
       not_if { File.exist?("#{node['openvpn']['key_dir']}/#{u['id']}.tar.gz") }
     end
   end

where

* the search will use both of the **execute** resources, unless the condition specified by the ``not_if`` commands are met
* the ``environments`` property in the first **execute** resource is being used to define values that appear as variables in the OpenVPN configuration
* the **template** resource tells the chef-client which template to use

.. end_tag

**Enable remote login for macOS**

.. tag resource_execute_enable_remote_login

.. To enable remote login on macOS:

.. code-block:: ruby

   execute 'enable ssh' do
     command '/usr/sbin/systemsetup -setremotelogin on'
     not_if '/usr/sbin/systemsetup -getremotelogin | /usr/bin/grep On'
     action :run
   end

.. end_tag

**Execute code immediately, based on the template resource**

.. tag resource_template_notifies_run_immediately

By default, notifications are ``:delayed``, that is they are queued up as they are triggered, and then executed at the very end of a chef-client run. To run an action immediately, use ``:immediately``:

.. code-block:: ruby

   template '/etc/nagios3/configures-nagios.conf' do
     # other parameters
     notifies :run, 'execute[test-nagios-config]', :immediately
   end

and then the chef-client would immediately run the following:

.. code-block:: ruby

   execute 'test-nagios-config' do
     command 'nagios3 --verify-config'
     action :nothing
   end

.. end_tag

**Sourcing a file**

.. tag resource_execute_source_a_file

The **execute** resource cannot be used to source a file (e.g. ``command 'source filename'``). The following example will fail because ``source`` is not an executable:

.. code-block:: ruby

   execute 'foo' do
     command 'source /tmp/foo.sh'
   end

Instead, use the **script** resource or one of the **script**-based resources (**bash**, **csh**, **perl**, **python**, or **ruby**). For example:

.. code-block:: ruby

   bash 'foo' do
     code 'source /tmp/foo.sh'
   end

.. end_tag

**Run a Knife command**

.. tag resource_execute_knife_user_create

.. To create a user with knife user create:

.. code-block:: ruby

   execute 'create_user' do
     command <<-EOM.gsub(/\s+/, ' ').strip!
	   knife user create #{user}
         --admin
         --password password
         --disable-editing
         --file /home/vagrant/.chef/user.pem
         --config /tmp/knife-admin.rb
       EOM
   end

.. end_tag

**Run install command into virtual environment**

.. tag resource_execute_install_q

The following example shows how to install a lightweight JavaScript framework into Vagrant:

.. code-block:: ruby

   execute "install q and zombiejs" do
     cwd "/home/vagrant"
     user "vagrant"
     environment ({'HOME' => '/home/vagrant', 'USER' => 'vagrant'})
     command "npm install -g q zombie should mocha coffee-script"
     action :run
   end

.. end_tag

**Run a command as a named user**

.. tag resource_execute_bundle_install

The following example shows how to run ``bundle install`` from a chef-client run as a specific user. This will put the gem into the path of the user (``vagrant``) instead of the root user (under which the chef-client runs):

.. code-block:: ruby

   execute '/opt/chefdk/embedded/bin/bundle install' do
     cwd node['chef_workstation']['bundler_path']
     user node['chef_workstation']['user']
     environment ({
       'HOME' => "/home/#{node['chef_workstation']['user']}",
       'USER' => node['chef_workstation']['user']
     })
     not_if 'bundle check'
   end

.. end_tag

**Run a command as an alternate user**

.. tag resource_execute_alternate_user

*Note*: When Chef is running as a service, this feature requires that the user that Chef runs as has 'SeAssignPrimaryTokenPrivilege' (aka 'SE_ASSIGNPRIMARYTOKEN_NAME') user right. By default only LocalSystem and NetworkService have this right when running as a service. This is necessary even if the user is an Administrator.

This right can be added and checked in a recipe using this example:

.. code-block:: ruby

    # Add 'SeAssignPrimaryTokenPrivilege' for the user
    Chef::ReservedNames::Win32::Security.add_account_right('<user>', 'SeAssignPrimaryTokenPrivilege')

    # Check if the user has 'SeAssignPrimaryTokenPrivilege' rights
    Chef::ReservedNames::Win32::Security.get_account_right('<user>').include?('SeAssignPrimaryTokenPrivilege')

The following example shows how to run ``mkdir test_dir`` from a chef-client run as an alternate user.

.. code-block:: ruby

   # Passing only username and password
   execute 'mkdir test_dir' do
    cwd Chef::Config[:file_cache_path]
    user "username"
    password "password"
   end

   # Passing username and domain
   execute 'mkdir test_dir' do
    cwd Chef::Config[:file_cache_path]
    domain "domain-name"
    user "user"
    password "password"
   end

   # Passing username = 'domain-name\\username'. No domain is passed
   execute 'mkdir test_dir' do
    cwd Chef::Config[:file_cache_path]
    user "domain-name\\username"
    password "password"
   end

   # Passing username = 'username@domain-name'. No domain is passed
   execute 'mkdir test_dir' do
    cwd Chef::Config[:file_cache_path]
    user "username@domain-name"
    password "password"
   end

.. end_tag

New in Chef Client 12.19.
