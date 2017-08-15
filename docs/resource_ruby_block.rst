=====================================================
ruby_block
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_ruby_block.rst>`__

.. tag resource_ruby_block_summary

Use the **ruby_block** resource to execute Ruby code during a chef-client run. Ruby code in the ``ruby_block`` resource is evaluated with other resources during convergence, whereas Ruby code outside of a ``ruby_block`` resource is evaluated before other resources, as the recipe is compiled.

.. end_tag

Syntax
=====================================================
A **ruby_block** resource block executes a block of arbitrary Ruby code. For example, to reload the client.rb file during the chef-client run:

.. code-block:: ruby

   ruby_block 'reload_client_config' do
     block do
       Chef::Config.from_file("/etc/chef/client.rb")
     end
     action :run
   end

The full syntax for all of the properties that are available to the **ruby_block** resource is:

.. code-block:: ruby

   ruby_block 'name' do
     block                      Block
     block_name                 String # defaults to 'name' if not specified
     notifies                   # see description
     provider                   Chef::Provider::RubyBlock
     subscribes                 # see description
     action                     Symbol # defaults to :run if not specified
   end

where

* ``ruby_block`` is the resource
* ``name`` is the name of the resource block
* ``block`` is the block of Ruby code to be executed
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``block``, ``block_name``, and ``provider`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

``:create``
   The same as ``:run``.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:run``
   Default. Run a Ruby block.

Properties
=====================================================
This resource has the following properties:

``block``
   **Ruby Type:** Block

   A block of Ruby code.

``block_name``
   **Ruby Type:** String

   The name of the Ruby block. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

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

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Re-read configuration data**

.. tag resource_ruby_block_reread_chef_client

.. To re-read the chef-client configuration during a chef-client run:

.. code-block:: ruby

   ruby_block 'reload_client_config' do
     block do
       Chef::Config.from_file('/etc/chef/client.rb')
     end
     action :run
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

**Use an if statement with the platform recipe DSL method**

.. tag resource_ruby_block_if_statement_use_with_platform

The following example shows how an if statement can be used with the ``platform?`` method in the Recipe DSL to run code specific to Microsoft Windows. The code is defined using the **ruby_block** resource:

.. code-block:: ruby

   # the following code sample comes from the ``client`` recipe
   # in the following cookbook: https://github.com/chef-cookbooks/mysql

   if platform?('windows')
     ruby_block 'copy libmysql.dll into ruby path' do
       block do
         require 'fileutils'
         FileUtils.cp "#{node['mysql']['client']['lib_dir']}\\libmysql.dll",
           node['mysql']['client']['ruby_dir']
       end
       not_if { File.exist?("#{node['mysql']['client']['ruby_dir']}\\libmysql.dll") }
     end
   end

.. end_tag

**Stash a file in a data bag**

.. tag resource_ruby_block_stash_file_in_data_bag

The following example shows how to use the **ruby_block** resource to stash a BitTorrent file in a data bag so that it can be distributed to nodes in the organization.

.. code-block:: ruby

   # the following code sample comes from the ``seed`` recipe
   # in the following cookbook: https://github.com/mattray/bittorrent-cookbook

   ruby_block 'share the torrent file' do
     block do
       f = File.open(node['bittorrent']['torrent'],'rb')
       #read the .torrent file and base64 encode it
       enc = Base64.encode64(f.read)
       data = {
         'id'=>bittorrent_item_id(node['bittorrent']['file']),
         'seed'=>node.ipaddress,
         'torrent'=>enc
       }
       item = Chef::DataBagItem.new
       item.data_bag('bittorrent')
       item.raw_data = data
       item.save
     end
     action :nothing
     subscribes :create, "bittorrent_torrent[#{node['bittorrent']['torrent']}]", :immediately
   end

.. end_tag

**Update the /etc/hosts file**

.. tag resource_ruby_block_update_etc_host

The following example shows how the **ruby_block** resource can be used to update the ``/etc/hosts`` file:

.. code-block:: ruby

   # the following code sample comes from the ``ec2`` recipe
   # in the following cookbook: https://github.com/chef-cookbooks/dynect

   ruby_block 'edit etc hosts' do
     block do
       rc = Chef::Util::FileEdit.new('/etc/hosts')
       rc.search_file_replace_line(/^127\.0\.0\.1 localhost$/,
          '127.0.0.1 #{new_fqdn} #{new_hostname} localhost')
       rc.write_file
     end
   end

.. end_tag

**Set environment variables**

.. tag resource_ruby_block_use_variables_to_set_env_variables

The following example shows how to use variables within a Ruby block to set environment variables using rbenv.

.. code-block:: ruby

   node.set[:rbenv][:root] = rbenv_root
   node.set[:ruby_build][:bin_path] = rbenv_binary_path

   ruby_block 'initialize' do
     block do
       ENV['RBENV_ROOT'] = node[:rbenv][:root]
       ENV['PATH'] = "#{node[:rbenv][:root]}/bin:#{node[:ruby_build][:bin_path]}:#{ENV['PATH']}"
     end
   end

.. end_tag

**Set JAVA_HOME**

.. tag resource_ruby_block_use_variables_to_set_java_home

The following example shows how to use a variable within a Ruby block to set the ``java_home`` environment variable:

.. code-block:: ruby

   ruby_block 'set-env-java-home' do
     block do
       ENV['JAVA_HOME'] = java_home
     end
   end

.. end_tag

**Run specific blocks of Ruby code on specific platforms**

.. THIS EXAMPLE IS DEPRECATED UNTIL THE Chef::ShellOut SECTION IS UPDATED FOR CORRECT Mixlib::ShellOut BEHAVIOR INCLUDING, BUT NOT LIMITED TO THE Chef::Application.fatal BIT BEING REMOVED ENTIRELY IN FAVOR OF SHELLOUT'S OWN ERROR HANDLING. WHEN UPDATED, ADD BACK INTO dsl_recipe_method_platform, resource_ruby_block, and dsl_recipe.

The following example shows how the ``platform?`` method and an if statement can be used in a recipe along with the ``ruby_block`` resource to run certain blocks of Ruby code on certain platforms:

.. code-block:: ruby

   if platform?('ubuntu', 'debian', 'redhat', 'centos', 'fedora', 'scientific', 'amazon')
     ruby_block 'update-java-alternatives' do
       block do
         if platform?('ubuntu', 'debian') and version == 6
           run_context = Chef::RunContext.new(node, {})
           r = Chef::Resource::Execute.new('update-java-alternatives', run_context)
           r.command 'update-java-alternatives -s java-6-openjdk'
           r.returns [0,2]
           r.run_action(:create)
         else

           require 'fileutils'
           arch = node['kernel']['machine'] =~ /x86_64/ ? 'x86_64' : 'i386'
           Chef::Log.debug("glob is #{java_home_parent}/java*#{version}*openjdk*")
           jdk_home = Dir.glob("#{java_home_parent}/java*#{version}*openjdk{,[-\.]#{arch}}")[0]
           Chef::Log.debug("jdk_home is #{jdk_home}")

           if File.exist? java_home
             FileUtils.rm_f java_home
           end
           FileUtils.ln_sf jdk_home, java_home

           cmd = Chef::ShellOut.new(
                 %Q[ update-alternatives --install /usr/bin/java java #{java_home}/bin/java 1;
                 update-alternatives --set java #{java_home}/bin/java ]
                 ).run_command
              unless cmd.exitstatus == 0 or cmd.exitstatus == 2
             Chef::Application.fatal!('Failed to update-alternatives for openjdk!')
           end
         end
       end
       action :nothing
     end
   end

**Reload the configuration**

.. tag resource_ruby_block_reload_configuration

The following example shows how to reload the configuration of a chef-client using the **remote_file** resource to:

* using an if statement to check whether the plugins on a node are the latest versions
* identify the location from which Ohai plugins are stored
* using the ``notifies`` property and a **ruby_block** resource to trigger an update (if required) and to then reload the client.rb file.

.. code-block:: ruby

   directory 'node[:ohai][:plugin_path]' do
     owner 'chef'
     recursive true
   end

   ruby_block 'reload_config' do
     block do
       Chef::Config.from_file('/etc/chef/client.rb')
     end
     action :nothing
   end

   if node[:ohai].key?(:plugins)
     node[:ohai][:plugins].each do |plugin|
       remote_file node[:ohai][:plugin_path] +"/#{plugin}" do
         source plugin
         owner 'chef'
		 notifies :run, 'ruby_block[reload_config]', :immediately
       end
     end
   end

.. end_tag

