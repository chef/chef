=====================================================
Resource Code Examples
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_examples.rst>`__

This reference contains code examples for many of the core resources that are built in to the chef-client, sorted by resource. This topic is a subset of the topic that contains a :doc:`complete description of all resources </resources>`, including actions, properties, and providers (in addition to these examples).

Common Examples
=====================================================
The examples in this section show functionality that is common across all resources.

**Use the :nothing action**

.. tag resource_service_use_nothing_action

.. To use the ``:nothing`` common action in a recipe:

.. code-block:: ruby

   service 'memcached' do
     action :nothing
     supports :status => true, :start => true, :stop => true, :restart => true
   end

.. end_tag

**Use the ignore_failure common attribute**

.. tag resource_package_use_ignore_failure_attribute

.. To use the ``ignore_failure`` common attribute in a recipe:

.. code-block:: ruby

   gem_package 'syntax' do
     action :install
     ignore_failure true
   end

.. end_tag

**Use the provider common attribute**

.. tag resource_package_use_provider_attribute

.. To use the ``:provider`` common attribute in a recipe:

.. code-block:: ruby

   package 'some_package' do
     provider Chef::Provider::Package::Rubygems
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

**Create a file, but not if an attribute has a specific value**

.. tag resource_template_add_file_not_if_attribute_has_value

The following example shows how to use the ``not_if`` condition to create a file based on a template and using the presence of an attribute value on the node to specify the condition:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     not_if { node[:some_value] }
   end

.. end_tag

**Create a file with a Ruby block, but not if "/etc/passwd" exists**

.. tag resource_template_add_file_not_if_ruby

The following example shows how to use the ``not_if`` condition to create a file based on a template and then Ruby code to specify the condition:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     not_if do
       File.exist?('/etc/passwd')
     end
   end

.. end_tag

**Create a file with Ruby block that has curly braces, but not if "/etc/passwd" exists**

.. tag resource_template_add_file_not_if_ruby_with_curly_braces

The following example shows how to use the ``not_if`` condition to create a file based on a template and using a Ruby block (with curly braces) to specify the condition:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     not_if { File.exist?('/etc/passwd' )}
   end

.. end_tag

**Create a file using a string, but not if "/etc/passwd" exists**

.. tag resource_template_add_file_not_if_string

The following example shows how to use the ``not_if`` condition to create a file based on a template and using a string to specify the condition:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     not_if 'test -f /etc/passwd'
   end

.. end_tag

**Install a file from a remote location using bash**

.. tag resource_remote_file_install_with_bash

The following is an example of how to install the ``foo123`` module for Nginx. This module adds shell-style functionality to an Nginx configuration file and does the following:

* Declares three variables
* Gets the Nginx file from a remote location
* Installs the file using Bash to the path specified by the ``src_filepath`` variable

.. code-block:: ruby

   # the following code sample is similar to the ``upload_progress_module``
   # recipe in the ``nginx`` cookbook:
   # https://github.com/chef-cookbooks/nginx

   src_filename = "foo123-nginx-module-v#{
     node['nginx']['foo123']['version']
   }.tar.gz"
   src_filepath = "#{Chef::Config['file_cache_path']}/#{src_filename}"
   extract_path = "#{
     Chef::Config['file_cache_path']
     }/nginx_foo123_module/#{
     node['nginx']['foo123']['checksum']
   }"

   remote_file 'src_filepath' do
     source node['nginx']['foo123']['url']
     checksum node['nginx']['foo123']['checksum']
     owner 'root'
     group 'root'
     mode '0755'
   end

   bash 'extract_module' do
     cwd ::File.dirname(src_filepath)
     code <<-EOH
       mkdir -p #{extract_path}
       tar xzf #{src_filename} -C #{extract_path}
       mv #{extract_path}/*/* #{extract_path}/
       EOH
     not_if { ::File.exist?(extract_path) }
   end

.. end_tag

**Create a file, but only if an attribute has a specific value**

.. tag resource_template_add_file_only_if_attribute_has_value

The following example shows how to use the ``only_if`` condition to create a file based on a template and using the presence of an attribute on the node to specify the condition:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     only_if { node[:some_value] }
   end

.. end_tag

**Create a file with a Ruby block, but only if "/etc/passwd" does not exist**

.. tag resource_template_add_file_only_if_ruby

The following example shows how to use the ``only_if`` condition to create a file based on a template, and then use Ruby to specify a condition:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     only_if do ! File.exist?('/etc/passwd') end
   end

.. end_tag

**Create a file using a string, but only if "/etc/passwd" exists**

.. tag resource_template_add_file_only_if_string

The following example shows how to use the ``only_if`` condition to create a file based on a template and using a string to specify the condition:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     only_if 'test -f /etc/passwd'
   end

.. end_tag

**Delay notifications**

.. tag resource_template_notifies_delay

.. To delay running a notification:

.. code-block:: ruby

   template '/etc/nagios3/configures-nagios.conf' do
     # other parameters
     notifies :run, 'execute[test-nagios-config]', :delayed
   end

.. end_tag

**Notify immediately**

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

**Enable a service after a restart or reload**

.. tag resource_service_notifies_enable_after_restart_or_reload

.. To enable a service after restarting or reloading it:

.. code-block:: ruby

   service 'apache' do
     supports :restart => true, :reload => true
     action :enable
   end

.. end_tag

**Notify multiple resources**

.. tag resource_template_notifies_multiple_resources

.. To notify multiple resources:

.. code-block:: ruby

   template '/etc/chef/server.rb' do
     source 'server.rb.erb'
     owner 'root'
     group 'root'
     mode '0755'
     notifies :restart, 'service[chef-solr]', :delayed
     notifies :restart, 'service[chef-solr-indexer]', :delayed
     notifies :restart, 'service[chef-server]', :delayed
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

**Reload a service**

.. tag resource_template_notifies_reload_service

.. To reload a service:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     notifies :reload, 'service[apache]', :immediately
   end

.. end_tag

**Restart a service when a template is modified**

.. tag resource_template_notifies_restart_service_when_template_modified

.. To restart a resource when a template is modified, use the ``:restart`` attribute for ``notifies``:

.. code-block:: ruby

   template '/etc/www/configures-apache.conf' do
     notifies :restart, 'service[apache]', :immediately
   end

.. end_tag

**Send notifications to multiple resources**

.. tag resource_template_notifies_send_notifications_to_multiple_resources

To send notifications to multiple resources, just use multiple attributes. Multiple attributes will get sent to the notified resources in the order specified.

.. code-block:: ruby

   template '/etc/netatalk/netatalk.conf' do
     notifies :restart, 'service[afpd]', :immediately
     notifies :restart, 'service[cnid]', :immediately
   end

   service 'afpd'
   service 'cnid'

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

**Notify when a remote source changes**

.. tag resource_remote_file_transfer_remote_source_changes

.. To transfer a file only if the remote source has changed (using the |resource http request| resource):

.. The "Transfer a file only when the source has changed" example is deprecated in chef-client 11-6

.. code-block:: ruby

   remote_file '/tmp/couch.png' do
     source 'http://couchdb.apache.org/img/sketch.png'
     action :nothing
   end

   http_request 'HEAD http://couchdb.apache.org/img/sketch.png' do
     message ''
     url 'http://couchdb.apache.org/img/sketch.png'
     action :head
     if File.exist?('/tmp/couch.png')
       headers 'If-Modified-Since' => File.mtime('/tmp/couch.png').httpdate
     end
     notifies :create, 'remote_file[/tmp/couch.png]', :immediately
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

**Relative Paths**

.. tag resource_template_use_relative_paths

.. To use a relative path:

.. code-block:: ruby

   template "#{ENV['HOME']}/chef-getting-started.txt" do
     source 'chef-getting-started.txt.erb'
     mode '0755'
   end

.. end_tag

apt_package
=====================================================
.. tag resource_package_apt

Use the **apt_package** resource to manage packages for the Debian and Ubuntu platforms.

.. end_tag

**Install a package using package manager**

.. tag resource_apt_package_install_package

.. To install a package using package manager:

.. code-block:: ruby

   apt_package 'name of package' do
     action :install
   end

.. end_tag

**Install a package using local file**

.. tag resource_apt_package_install_package_using_local_file

.. To install a package using local file:

.. code-block:: ruby

   apt_package 'jwhois' do
     action :install
     source '/path/to/jwhois.deb'
   end

.. end_tag

**Install without using recommend packages as a dependency**

.. tag resource_apt_package_install_without_recommends_suggests

.. To install without using recommend packages as a dependency:

.. code-block:: ruby

   package 'apache2' do
     options '--no-install-recommends'
   end

.. end_tag

apt_update
=====================================================
.. tag resource_apt_update_summary

Use the **apt_update** resource to manage Apt repository updates on Debian and Ubuntu platforms.

.. end_tag

**Update the Apt repository at a specified interval**

.. tag resource_apt_update_periodic

.. To update the Apt repository at a specified interval:

.. code-block:: ruby

   apt_update 'all platforms' do
     frequency 86400
     action :periodic
   end

.. end_tag

**Update the Apt repository at the start of a chef-client run**

.. tag resource_apt_update_at_start_of_client_run

.. To update the Apt repository at the start of a chef-client run:

.. code-block:: ruby

   apt_update 'update' do
     action :update
   end

.. end_tag

bash
=====================================================
.. tag resource_script_bash

Use the **bash** resource to execute scripts using the Bash interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

.. note:: The **bash** script resource (which is based on the **script** resource) is different from the **ruby_block** resource because Ruby code that is run with this resource is created as a temporary file and executed like other script resources, rather than run inline.

.. end_tag

**Use a named provider to run a script**

.. tag resource_script_bash_provider_and_interpreter

.. To use the |resource bash| resource to run a script:

.. code-block:: ruby

   bash 'install_something' do
     user 'root'
     cwd '/tmp'
     code <<-EOH
     wget http://www.example.com/tarball.tar.gz
     tar -zxf tarball.tar.gz
     cd tarball
     ./configure
     make
     make install
     EOH
   end

.. end_tag

**Install a file from a remote location using bash**

.. tag resource_remote_file_install_with_bash

The following is an example of how to install the ``foo123`` module for Nginx. This module adds shell-style functionality to an Nginx configuration file and does the following:

* Declares three variables
* Gets the Nginx file from a remote location
* Installs the file using Bash to the path specified by the ``src_filepath`` variable

.. code-block:: ruby

   # the following code sample is similar to the ``upload_progress_module``
   # recipe in the ``nginx`` cookbook:
   # https://github.com/chef-cookbooks/nginx

   src_filename = "foo123-nginx-module-v#{
     node['nginx']['foo123']['version']
   }.tar.gz"
   src_filepath = "#{Chef::Config['file_cache_path']}/#{src_filename}"
   extract_path = "#{
     Chef::Config['file_cache_path']
     }/nginx_foo123_module/#{
     node['nginx']['foo123']['checksum']
   }"

   remote_file 'src_filepath' do
     source node['nginx']['foo123']['url']
     checksum node['nginx']['foo123']['checksum']
     owner 'root'
     group 'root'
     mode '0755'
   end

   bash 'extract_module' do
     cwd ::File.dirname(src_filepath)
     code <<-EOH
       mkdir -p #{extract_path}
       tar xzf #{src_filename} -C #{extract_path}
       mv #{extract_path}/*/* #{extract_path}/
       EOH
     not_if { ::File.exist?(extract_path) }
   end

.. end_tag

**Install an application from git using bash**

.. tag resource_scm_use_bash_and_ruby_build

The following example shows how Bash can be used to install a plug-in for rbenv named ``ruby-build``, which is located in git version source control. First, the application is synchronized, and then Bash changes its working directory to the location in which ``ruby-build`` is located, and then runs a command.

.. code-block:: ruby

   git "#{Chef::Config[:file_cache_path]}/ruby-build" do
     repository 'git://github.com/sstephenson/ruby-build.git'
     reference 'master'
     action :sync
   end

   bash 'install_ruby_build' do
     cwd '#{Chef::Config[:file_cache_path]}/ruby-build'
     user 'rbenv'
     group 'rbenv'
     code <<-EOH
       ./install.sh
       EOH
     environment 'PREFIX' => '/usr/local'
  end

To read more about ``ruby-build``, see here: https://github.com/sstephenson/ruby-build.

.. end_tag

**Store certain settings**

.. tag resource_remote_file_store_certain_settings

The following recipe shows how an attributes file can be used to store certain settings. An attributes file is located in the ``attributes/`` directory in the same cookbook as the recipe which calls the attributes file. In this example, the attributes file specifies certain settings for Python that are then used across all nodes against which this recipe will run.

Python packages have versions, installation directories, URLs, and checksum files. An attributes file that exists to support this type of recipe would include settings like the following:

.. code-block:: ruby

   default['python']['version'] = '2.7.1'

   if python['install_method'] == 'package'
     default['python']['prefix_dir'] = '/usr'
   else
     default['python']['prefix_dir'] = '/usr/local'
   end

   default['python']['url'] = 'http://www.python.org/ftp/python'
   default['python']['checksum'] = '80e387...85fd61'

and then the methods in the recipe may refer to these values. A recipe that is used to install Python will need to do the following:

* Identify each package to be installed (implied in this example, not shown)
* Define variables for the package ``version`` and the ``install_path``
* Get the package from a remote location, but only if the package does not already exist on the target system
* Use the **bash** resource to install the package on the node, but only when the package is not already installed

.. code-block:: ruby

   #  the following code sample comes from the ``oc-nginx`` cookbook on |github|: https://github.com/cookbooks/oc-nginx

   version = node['python']['version']
   install_path = "#{node['python']['prefix_dir']}/lib/python#{version.split(/(^\d+\.\d+)/)[1]}"

   remote_file "#{Chef::Config[:file_cache_path]}/Python-#{version}.tar.bz2" do
     source "#{node['python']['url']}/#{version}/Python-#{version}.tar.bz2"
     checksum node['python']['checksum']
     mode '0755'
     not_if { ::File.exist?(install_path) }
   end

   bash 'build-and-install-python' do
     cwd Chef::Config[:file_cache_path]
     code <<-EOF
       tar -jxvf Python-#{version}.tar.bz2
       (cd Python-#{version} && ./configure #{configure_options})
       (cd Python-#{version} && make && make install)
     EOF
     not_if { ::File.exist?(install_path) }
   end

.. end_tag

batch
=====================================================
.. tag resource_batch_summary

Use the **batch** resource to execute a batch script using the cmd.exe interpreter. The **batch** resource creates and executes a temporary file (similar to how the **script** resource behaves), rather than running the command inline. This resource inherits actions (``:run`` and ``:nothing``) and properties (``creates``, ``cwd``, ``environment``, ``group``, ``path``, ``timeout``, and ``user``) from the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

.. end_tag

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

bff_package
=====================================================
.. tag resource_package_bff

Use the **bff_package** resource to manage packages for the AIX platform using the installp utility. When a package is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources. New in Chef Client 12.0.

.. note:: A Backup File Format (BFF) package may not have a ``.bff`` file extension. The chef-client will still identify the correct provider to use based on the platform, regardless of the file extension.

.. end_tag

New in Chef Client 12.0.

**Install a package**

.. tag resource_bff_package_install

.. To install a package:

The **bff_package** resource is the default package provider on the AIX platform. The base **package** resource may be used, and then when the platform is AIX, the chef-client will identify the correct package provider. The following examples show how to install part of the IBM XL C/C++ compiler.

Using the base **package** resource:

.. code-block:: ruby

   package 'xlccmp.13.1.0' do
     source '/var/tmp/IBM_XL_C_13.1.0/usr/sys/inst.images/xlccmp.13.1.0'
     action :install
   end

Using the **bff_package** resource:

.. code-block:: ruby

   bff_package 'xlccmp.13.1.0' do
     source '/var/tmp/IBM_XL_C_13.1.0/usr/sys/inst.images/xlccmp.13.1.0'
     action :install
   end

.. end_tag

breakpoint
=====================================================
.. tag resource_breakpoint_summary

Use the **breakpoint** resource to add breakpoints to recipes. Run the chef-shell in chef-client mode, and then use those breakpoints to debug recipes. Breakpoints are ignored by the chef-client during an actual chef-client run. That said, breakpoints are typically used to debug recipes only when running them in a non-production environment, after which they are removed from those recipes before the parent cookbook is uploaded to the Chef server.

.. end_tag

**A recipe without a breakpoint**

.. tag resource_breakpoint_no

.. A resource without breakpoints:

.. code-block:: ruby

   yum_key node['yum']['elrepo']['key'] do
     url  node['yum']['elrepo']['key_url']
     action :add
   end

   yum_repository 'elrepo' do
     description 'ELRepo.org Community Enterprise Linux Extras Repository'
     key node['yum']['elrepo']['key']
     mirrorlist node['yum']['elrepo']['url']
     includepkgs node['yum']['elrepo']['includepkgs']
     exclude node['yum']['elrepo']['exclude']
     action :create
   end

.. end_tag

**The same recipe with breakpoints**

.. tag resource_breakpoint_yes

.. code-block:: ruby

   breakpoint "before yum_key node['yum']['repo_name']['key']" do
     action :break
   end

   yum_key node['yum']['repo_name']['key'] do
     url  node['yum']['repo_name']['key_url']
     action :add
   end

   breakpoint "after yum_key node['yum']['repo_name']['key']" do
     action :break
   end

   breakpoint "before yum_repository 'repo_name'" do
     action :break
   end

   yum_repository 'repo_name' do
     description 'description'
     key node['yum']['repo_name']['key']
     mirrorlist node['yum']['repo_name']['url']
     includepkgs node['yum']['repo_name']['includepkgs']
     exclude node['yum']['repo_name']['exclude']
     action :create
   end

   breakpoint "after yum_repository 'repo_name'" do
     action :break
   end

where the name of each breakpoint is an arbitrary string. In the previous examples, the names are used to indicate if the breakpoint is before or after a resource, and then also to specify which resource.

.. end_tag

chef_gem
=====================================================
.. tag resource_package_chef_gem

Use the **chef_gem** resource to install a gem only for the instance of Ruby that is dedicated to the chef-client. When a gem is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources.

The **chef_gem** resource works with all of the same properties and options as the **gem_package** resource, but does not accept the ``gem_binary`` property because it always uses the ``CurrentGemEnvironment`` under which the chef-client is running. In addition to performing actions similar to the **gem_package** resource, the **chef_gem** resource does the following:

* Runs its actions immediately, before convergence, allowing a gem to be used in a recipe immediately after it is installed
* Runs ``Gem.clear_paths`` after the action, ensuring that gem is aware of changes so that it can be required immediately after it is installed

.. end_tag

**Install a gems file for use in recipes**

.. tag resource_chef_gem_install_for_use_in_recipes

.. To install a gems file for use in a recipe:

To install a gem while the chef-client is configuring the node (the “converge phase”), set the ``compile_time`` property to ``false``:

.. code-block:: ruby

   chef_gem 'right_aws' do
     compile_time false
     action :install
   end

To install a gem while the resource collection is being built (the “compile phase”), set the ``compile_time`` property to ``true``:

.. code-block:: ruby

   chef_gem 'right_aws' do
     compile_time true
     action :install
   end

.. end_tag

New in Chef Client 12.1.

**Install MySQL for Chef**

.. tag resource_chef_gem_install_mysql

.. To install MySQL:

.. code-block:: ruby

   execute 'apt-get update' do
     ignore_failure true
     action :nothing
   end.run_action(:run) if node['platform_family'] == 'debian'

   node.set['build_essential']['compiletime'] = true
   include_recipe 'build-essential'
   include_recipe 'mysql::client'

   node['mysql']['client']['packages'].each do |mysql_pack|
     resources("package[#{mysql_pack}]").run_action(:install)
   end

   chef_gem 'mysql'

.. end_tag

chef_handler
=====================================================
.. tag resource_chef_handler_summary

Use the **chef_handler** resource to enable handlers during a chef-client run. The resource allows arguments to be passed to the chef-client, which then applies the conditions defined by the custom handler to the node attribute data collected during the chef-client run, and then processes the handler based on that data.

The **chef_handler** resource is typically defined early in a node's run-list (often being the first item). This ensures that all of the handlers will be available for the entire chef-client run.

The **chef_handler** resource `is included with the chef_handler cookbook <https://github.com/chef-cookbooks/chef_handler>`__. This cookbook defines the the resource itself and also provides the location in which the chef-client looks for custom handlers. All custom handlers should be added to the ``files/default/handlers`` directory in the **chef_handler** cookbook.

.. end_tag

**Enable the CloudkickHandler handler**

.. tag lwrp_chef_handler_enable_cloudkickhandler

The following example shows how to enable the ``CloudkickHandler`` handler, which adds it to the default handler path and passes the ``oauth`` key/secret to the handler's initializer:

.. code-block:: ruby

   chef_handler "CloudkickHandler" do
     source "#{node['chef_handler']['handler_path']}/cloudkick_handler.rb"
     arguments [node['cloudkick']['oauth_key'], node['cloudkick']['oauth_secret']]
     action :enable
   end

.. end_tag

**Enable handlers during the compile phase**

.. tag lwrp_chef_handler_enable_during_compile

.. To enable a handler during the compile phase:

.. code-block:: ruby

   chef_handler "Chef::Handler::JsonFile" do
     source "chef/handler/json_file"
     arguments :path => '/var/chef/reports'
     action :nothing
   end.run_action(:enable)

.. end_tag

**Handle only exceptions**

.. tag lwrp_chef_handler_exceptions_only

.. To handle exceptions only:

.. code-block:: ruby

   chef_handler "Chef::Handler::JsonFile" do
     source "chef/handler/json_file"
     arguments :path => '/var/chef/reports'
     supports :exception => true
     action :enable
   end

.. end_tag

**Cookbook Versions (a custom handler)**

.. tag handler_custom_example_cookbook_versions

Community member ``juliandunn`` created a custom `report handler that logs all of the cookbooks and cookbook versions <https://github.com/juliandunn/cookbook_versions_handler>`_ that were used during the chef-client run, and then reports after the run is complete. This handler requires the **chef_handler** resource (which is available from the **chef_handler** cookbook).

.. end_tag

cookbook_versions.rb:

.. tag handler_custom_example_cookbook_versions_handler

The following custom handler defines how cookbooks and cookbook versions that are used during the chef-client run will be compiled into a report using the ``Chef::Log`` class in the chef-client:

.. code-block:: ruby

   require 'chef/log'

   module Opscode
     class CookbookVersionsHandler < Chef::Handler

       def report
         cookbooks = run_context.cookbook_collection
         Chef::Log.info('Cookbooks and versions run: #{cookbooks.keys.map {|x| cookbooks[x].name.to_s + ' ' + cookbooks[x].version} }')
       end
     end
   end

.. end_tag

default.rb:

.. tag handler_custom_example_cookbook_versions_recipe

The following recipe is added to the run-list for every node on which a list of cookbooks and versions will be generated as report output after every chef-client run.

.. code-block:: ruby

   include_recipe 'chef_handler'

   cookbook_file "#{node['chef_handler']['handler_path']}/cookbook_versions.rb" do
     source 'cookbook_versions.rb'
     owner 'root'
     group 'root'
     mode '0755'
     action :create
   end

   chef_handler 'Opscode::CookbookVersionsHandler' do
     source "#{node['chef_handler']['handler_path']}/cookbook_versions.rb"
     supports :report => true
     action :enable
   end

This recipe will generate report output similar to the following:

.. code-block:: ruby

   [2013-11-26T03:11:06+00:00] INFO: Chef Run complete in 0.300029878 seconds
   [2013-11-26T03:11:06+00:00] INFO: Running report handlers
   [2013-11-26T03:11:06+00:00] INFO: Cookbooks and versions run: ["chef_handler 1.1.4", "cookbook_versions_handler 1.0.0"]
   [2013-11-26T03:11:06+00:00] INFO: Report handlers complete

.. end_tag

**JsonFile Handler**

.. tag handler_custom_example_json_file

The `json_file <https://github.com/chef/chef/blob/master/lib/chef/handler/json_file.rb>`_ handler is available from the **chef_handler** cookbook and can be used with exceptions and reports. It serializes run status data to a JSON file. This handler may be enabled in one of the following ways.

By adding the following lines of Ruby code to either the client.rb file or the solo.rb file, depending on how the chef-client is being run:

.. code-block:: ruby

   require 'chef/handler/json_file'
   report_handlers << Chef::Handler::JsonFile.new(:path => '/var/chef/reports')
   exception_handlers << Chef::Handler::JsonFile.new(:path => '/var/chef/reports')

By using the **chef_handler** resource in a recipe, similar to the following:

.. code-block:: ruby

   chef_handler 'Chef::Handler::JsonFile' do
     source 'chef/handler/json_file'
     arguments :path => '/var/chef/reports'
     action :enable
   end

After it has run, the run status data can be loaded and inspected via Interactive Ruby (IRb):

.. code-block:: ruby

   irb(main):001:0> require 'rubygems' => true
   irb(main):002:0> require 'json' => true
   irb(main):003:0> require 'chef' => true
   irb(main):004:0> r = JSON.parse(IO.read('/var/chef/reports/chef-run-report-20110322060731.json')) => ... output truncated
   irb(main):005:0> r.keys => ['end_time', 'node', 'updated_resources', 'exception', 'all_resources', 'success', 'elapsed_time', 'start_time', 'backtrace']
   irb(main):006:0> r['elapsed_time'] => 0.00246

.. end_tag

**Register the JsonFile handler**

.. tag lwrp_chef_handler_register

.. To register the ``Chef::Handler::JsonFile`` handler:

.. code-block:: ruby

   chef_handler "Chef::Handler::JsonFile" do
     source "chef/handler/json_file"
     arguments :path => '/var/chef/reports'
     action :enable
   end

.. end_tag

**ErrorReport Handler**

.. tag handler_custom_example_error_report

The `error_report <https://github.com/chef/chef/blob/master/lib/chef/handler/error_report.rb>`_ handler is built into the chef-client and can be used for both exceptions and reports. It serializes error report data to a JSON file. This handler may be enabled in one of the following ways.

By adding the following lines of Ruby code to either the client.rb file or the solo.rb file, depending on how the chef-client is being run:

.. code-block:: ruby

   require 'chef/handler/error_report'
   report_handlers << Chef::Handler::ErrorReport.new()
   exception_handlers << Chef::Handler::ErrorReport.new()

By using the :doc:`chef_handler </resource_chef_handler>` resource in a recipe, similar to the following:

.. code-block:: ruby

   chef_handler 'Chef::Handler::ErrorReport' do
     source 'chef/handler/error_report'
     action :enable
   end

.. end_tag

chocolatey_package
=====================================================
.. tag resource_package_chocolatey

Use the **chocolatey_package** resource to manage packages using Chocolatey for the Microsoft Windows platform.

.. end_tag

**Install a package**

.. tag resource_chocolatey_package_install

.. To install a package:

.. code-block:: ruby

   chocolatey_package 'name of package' do
     action :install
   end

.. end_tag

cookbook_file
=====================================================
.. tag resource_cookbook_file_summary

Use the **cookbook_file** resource to transfer files from a sub-directory of ``COOKBOOK_NAME/files/`` to a specified path located on a host that is running the chef-client. The file is selected according to file specificity, which allows different source files to be used based on the hostname, host platform (operating system, distro, or as appropriate), or platform version. Files that are located in the ``COOKBOOK_NAME/files/default`` sub-directory may be used on any platform.

.. end_tag

**Transfer a file**

.. tag resource_cookbook_file_transfer_a_file

.. To transfer a file in a cookbook:

.. code-block:: ruby

   cookbook_file 'file.txt' do
     mode '0755'
   end

.. end_tag

**Handle cookbook_file and yum_package resources in the same recipe**

.. tag resource_yum_package_handle_cookbook_file_and_yum_package

.. To handle cookbook_file and yum_package when both called in the same recipe

When a **cookbook_file** resource and a **yum_package** resource are both called from within the same recipe, use the ``flush_cache`` attribute to dump the in-memory Yum cache, and then use the repository immediately to ensure that the correct package is installed:

.. code-block:: ruby

   cookbook_file '/etc/yum.repos.d/custom.repo' do
     source 'custom'
     mode '0755'
   end

   yum_package 'only-in-custom-repo' do
     action :install
     flush_cache [ :before ]
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

**Use a case statement**

.. tag resource_cookbook_file_use_case_statement

The following example shows how a case statement can be used to handle a situation where an application needs to be installed on multiple platforms, but where the install directories are different paths, depending on the platform:

.. code-block:: ruby

   cookbook_file 'application.pm' do
     path case node['platform']
       when 'centos','redhat'
         '/usr/lib/version/1.2.3/dir/application.pm'
       when 'arch'
         '/usr/share/version/core_version/dir/application.pm'
       else
         '/etc/version/dir/application.pm'
       end
     source "application-#{node['languages']['perl']['version']}.pm"
     owner 'root'
     group 'root'
     mode '0755'
   end

.. end_tag

**Manage dotfiles**

.. tag resource_directory_manage_dotfiles

The following example shows using the **directory** and **cookbook_file** resources to manage dotfiles. The dotfiles are defined by a JSON data structure similar to:

.. code-block:: javascript

   "files": {
     ".zshrc": {
       "mode": '0755',
       "source": "dot-zshrc"
       },
     ".bashrc": {
       "mode": '0755',
       "source": "dot-bashrc"
        },
     ".bash_profile": {
       "mode": '0755',
       "source": "dot-bash_profile"
       },
     }

and then the following resources manage the dotfiles:

.. code-block:: ruby

   if u.has_key?('files')
     u['files'].each do |filename, file_data|

     directory "#{home_dir}/#{File.dirname(filename)}" do
       recursive true
       mode '0755'
     end if file_data['subdir']

     cookbook_file "#{home_dir}/#{filename}" do
       source "#{u['id']}/#{file_data['source']}"
       owner 'u['id']'
       group 'group_id'
       mode 'file_data['mode']'
       ignore_failure true
       backup 0
     end
   end

.. end_tag

cron
=====================================================
.. tag resource_cron_summary

Use the **cron** resource to manage cron entries for time-based job scheduling. Properties for a schedule will default to ``*`` if not provided. The **cron** resource requires access to a crontab program, typically cron.

.. warning:: The **cron** resource should only be used to modify an entry in a crontab file. Use the **cookbook_file** or **template** resources to add a crontab file to the cron.d directory. The ``cron_d`` lightweight resource (found in the `cron <https://github.com/chef-cookbooks/cron>`__ cookbook) is another option for managing crontab files.

.. end_tag

**Run a program at a specified interval**

.. tag resource_cron_run_program_on_fifth_hour

.. To run a program on the fifth hour of the day:

.. code-block:: ruby

   cron 'noop' do
     hour '5'
     minute '0'
     command '/bin/true'
   end

.. end_tag

**Run an entry if a folder exists**

.. tag resource_cron_run_entry_when_folder_exists

.. To run an entry if a folder exists:

.. code-block:: ruby

   cron 'ganglia_tomcat_thread_max' do
     command "/usr/bin/gmetric
       -n 'tomcat threads max'
       -t uint32
       -v '/usr/local/bin/tomcat-stat
       --thread-max'"
     only_if do File.exist?('/home/jboss') end
   end

.. end_tag

**Run every Saturday, 8:00 AM**

.. tag resource_cron_run_every_saturday

The following example shows a schedule that will run every hour at 8:00 each Saturday morning, and will then send an email to "admin@example.com" after each run.

.. code-block:: ruby

   cron 'name_of_cron_entry' do
     minute '0'
     hour '8'
     weekday '6'
     mailto 'admin@example.com'
     action :create
   end

.. end_tag

**Run only in November**

.. tag resource_cron_run_only_in_november

The following example shows a schedule that will run at 8:00 PM, every weekday (Monday through Friday), but only in November:

.. code-block:: ruby

   cron 'name_of_cron_entry' do
     minute '0'
     hour '20'
     day '*'
     month '11'
     weekday '1-5'
     action :create
   end

.. end_tag

csh
=====================================================
.. tag resource_script_csh

Use the **csh** resource to execute scripts using the csh interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

.. note:: The **csh** script resource (which is based on the **script** resource) is different from the **ruby_block** resource because Ruby code that is run with this resource is created as a temporary file and executed like other script resources, rather than run inline.

.. end_tag

No examples.

deploy
=====================================================
.. tag resource_deploy_summary

Use the **deploy** resource to manage and control deployments. This is a popular resource, but is also complex, having the most properties, multiple providers, the added complexity of callbacks, plus four attributes that support layout modifications from within a recipe.

.. end_tag

**Modify the layout of a Ruby on Rails application**

.. tag resource_deploy_custom_application_layout

The layout of the **deploy** resource matches a Ruby on Rails app by default, but this can be customized. To customize the layout, do something like the following:

.. code-block:: ruby

   deploy '/my/apps/dir/deploy' do
     # Use a local repo if you prefer
     repo '/path/to/gitrepo/typo/'
     environment 'RAILS_ENV' => 'production'
     revision 'HEAD'
     action :deploy
     migration_command 'rake db:migrate --trace'
     migrate true
     restart_command 'touch tmp/restart.txt'
     create_dirs_before_symlink  %w{tmp public config deploy}

     # You can use this to customize if your app has extra configuration files
     # such as amqp.yml or app_config.yml
     symlink_before_migrate  'config/database.yml' => 'config/database.yml'

     # If your app has extra files in the shared folder, specify them here
     symlinks  'system' => 'public/system',
               'pids' => 'tmp/pids',
               'log' => 'log',
               'deploy/before_migrate.rb' => 'deploy/before_migrate.rb',
               'deploy/before_symlink.rb' => 'deploy/before_symlink.rb',
               'deploy/before_restart.rb' => 'deploy/before_restart.rb',
               'deploy/after_restart.rb' => 'deploy/after_restart.rb'
   end

.. end_tag

**Use resources within callbacks**

.. tag resource_deploy_embedded_recipes_for_callbacks

Using resources from within your callbacks as blocks or within callback files distributed with your application's source code. To use embedded recipes for callbacks:

.. code-block:: ruby

   deploy "#{node['tmpdir']}/deploy" do
     repo "#{node['tmpdir']}/gitrepo/typo/"
     environment 'RAILS_ENV' => 'production'
     revision 'HEAD'
     action :deploy
     migration_command 'rake db:migrate --trace'
     migrate true

     # Callback awesomeness:
     before_migrate do
       current_release = release_path

       directory "#{current_release}/deploy" do
         mode '0755'
       end

       # creates a callback for before_symlink
       template "#{current_release}/deploy/before_symlink_callback.rb" do
         source 'embedded_recipe_before_symlink.rb.erb'
         mode '0755'
       end

     end

     # This file can contain Chef recipe code, plain ruby also works
     before_symlink 'deploy/before_symlink_callback.rb'

     restart do
       current_release = release_path
       file "#{release_path}/tmp/restart.txt" do
         mode '0755'
       end
     end

   end

.. end_tag

**Deploy from a private git repository without using the application cookbook**

.. tag resource_deploy_private_git_repo_using_application_cookbook

To deploy from a private git repository without using the ``application`` cookbook, first ensure that:

* the private key does not have a passphrase, as this will pause a chef-client run to wait for input
* an SSH wrapper is being used
* a private key has been added to the node

and then remove a passphrase from a private key by using code similar to:

.. code-block:: bash

   ssh-keygen -p -P 'PASSPHRASE' -N '' -f id_deploy

.. end_tag

**Use an SSH wrapper**

.. tag resource_deploy_recipe_uses_ssh_wrapper

To write a recipe that uses an SSH wrapper:

#. Create a file in the ``cookbooks/COOKBOOK_NAME/files/default`` directory that is named ``wrap-ssh4git.sh`` and which contains the following:

   .. code-block:: ruby

      #!/usr/bin/env bash
      /usr/bin/env ssh -o "StrictHostKeyChecking=no" -i "/tmp/private_code/.ssh/id_deploy" $1 $2

#. Set up the cookbook file.

#. Add a recipe to the cookbook file similar to the following:

   .. code-block:: ruby

      directory '/tmp/private_code/.ssh' do
        owner 'ubuntu'
        recursive true
      end

      cookbook_file '/tmp/private_code/wrap-ssh4git.sh' do
        source 'wrap-ssh4git.sh'
        owner 'ubuntu'
        mode '0755'
      end

      deploy 'private_repo' do
        repo 'git@github.com:acctname/private-repo.git'
        user 'ubuntu'
        deploy_to '/tmp/private_code'
        action :deploy
        ssh_wrapper '/tmp/private_code/wrap-ssh4git.sh'
      end

   This will deploy the git repository at ``git@github.com:acctname/private-repo.git`` in the ``/tmp/private_code`` directory.

.. end_tag

**Use a callback to include a file that will be passed as a code block**

.. tag resource_deploy_use_callback_to_include_code_from_file

The code in a file that is included in a recipe using a callback is evaluated exactly as if the code had been put in the recipe as a block. Files are searched relative to the current release.

To specify a file that contains code to be used as a block:

.. code-block:: ruby

   deploy '/deploy/dir/' do
     # ...

     before_migrate 'callbacks/do_this_before_migrate.rb'
   end

.. end_tag

**Use a callback to pass a code block**

.. tag resource_deploy_use_callback_to_pass_python

To pass a block of Python code before a migration is run:

.. code-block:: ruby

   deploy_revision '/deploy/dir/' do
     # other attributes
     # ...

     before_migrate do
       # release_path is the path to the timestamp dir
       # for the current release
       current_release = release_path

       # Create a local variable for the node so we'll have access to
       # the attributes
       deploy_node = node

       # A local variable with the deploy resource.
       deploy_resource = new_resource

       python do
         cwd current_release
         user 'myappuser'
         code<<-PYCODE
           # Woah, callbacks in python!
           # ...
           # current_release, deploy_node, and deploy_resource are all available
           # within the deploy hook now.
         PYCODE
       end
     end
   end

.. end_tag

**Use the same API for all recipes using the same gem**

.. tag resource_deploy_use_same_api_as_gitdeploy_gems

Any recipes using the ``git-deploy`` gem can continue using the same API. To include this behavior in a recipe, do something like the following:

.. code-block:: ruby

   deploy "/srv/#{appname}" do
     repo 'git://github.com/radiant/radiant.git'
     revision 'HEAD'
     user 'railsdev'
     enable_submodules false
     migrate true
     migration_command 'rake db:migrate'
     # Giving a string for environment sets RAILS_ENV, MERB_ENV, RACK_ENV
     environment 'production'
     shallow_clone true
     action :deploy
     restart_command 'touch tmp/restart.txt'
   end

.. end_tag

**Deploy without creating symbolic links to a shared folder**

.. tag resource_deploy_without_symlink_to_shared

To deploy without creating symbolic links to a shared folder:

.. code-block:: ruby

   deploy '/my/apps/dir/deploy' do
     symlinks {}
   end

When deploying code that is not Ruby on Rails and symbolic links to a shared folder are not wanted, use parentheses ``()`` or ``Hash.new`` to avoid ambiguity. For example, using parentheses:

.. code-block:: ruby

   deploy '/my/apps/dir/deploy' do
     symlinks({})
   end

or using ``Hash.new``:

.. code-block:: ruby

   deploy '/my/apps/dir/deploy' do
     symlinks Hash.new
   end

.. end_tag

**Clear a layout modifier attribute**

.. tag resource_deploy_clear_layout_modifiers

Using the default property values for the various resources is the recommended starting point when working with recipes. Then, depending on what each node requires, these default values can be overridden with node-, role-, environment-, and cookbook-specific values. The **deploy** resource has four layout modifiers: ``create_dirs_before_symlink``, ``purge_before_symlink``, ``symlink_before_migrate``, and ``symlinks``. Each of these is a Hash that behaves as a property of the **deploy** resource. When these layout modifiers are used in a recipe, they appear similar to the following:

.. code-block:: ruby

   deploy 'name' do
     ...
     symlink_before_migrate       {'config/database.yml' => 'config/database.yml'}
     create_dirs_before_symlink   %w{tmp public config}
     purge_before_symlink         %w{log tmp/pids public/system}
     symlinks                     { 'system' => 'public/system',
                                    'pids' => 'tmp/pids',
                                    'log' => 'log'
                                  }
     ...
   end

and then what these layout modifiers look like if they were empty:

.. code-block:: ruby

   deploy 'name' do
     ...
     symlink_before_migrate       nil
     create_dirs_before_symlink   []
     purge_before_symlink         []
     symlinks                     nil
     ...
   end

In most cases, using the empty values for the layout modifiers will prevent the chef-client from passing symbolic linking information to a node during the chef-client run. However, in some cases, it may be preferable to ensure that one (or more) of these layout modifiers do not pass any symbolic linking information to a node during the chef-client run at all. Because each of these layout modifiers are a Hash, the ``clear`` instance method can be used to clear out these values.

To clear the default values for a layout modifier:

.. code-block:: ruby

   deploy 'name' do
     ...
     symlink_before_migrate.clear
     create_dirs_before_symlink.clear
     purge_before_symlink.clear
     symlinks.clear
     ...
   end

In general, use this approach carefully and only after it is determined that nil or empty values won't provide the expected result.

.. end_tag

directory
=====================================================
.. tag resource_directory_summary

Use the **directory** resource to manage a directory, which is a hierarchy of folders that comprises all of the information stored on a computer. The root directory is the top-level, under which the rest of the directory is organized. The **directory** resource uses the ``name`` property to specify the path to a location in a directory. Typically, permission to access that location in the directory is required.

.. end_tag

**Create a directory**

.. tag resource_directory_create

.. To create a directory:

.. code-block:: ruby

   directory '/tmp/something' do
     owner 'root'
     group 'root'
     mode '0755'
     action :create
   end

.. end_tag

**Create a directory in Microsoft Windows**

.. tag resource_directory_create_in_windows

.. To create a directory in Microsoft Windows:

.. code-block:: ruby

   directory "C:\\tmp\\something.txt" do
     rights :full_control, "DOMAIN\\User"
     inherits false
     action :create
   end

or:

.. code-block:: ruby

   directory 'C:\tmp\something.txt' do
     rights :full_control, 'DOMAIN\User'
     inherits false
     action :create
   end

.. note:: The difference between the two previous examples is the single- versus double-quoted strings, where if the double quotes are used, the backslash character (``\``) must be escaped using the Ruby escape character (which is a backslash).

.. end_tag

**Create a directory recursively**

.. tag resource_directory_create_recursively

.. To create a directory recursively:

.. code-block:: ruby

   %w{dir1 dir2 dir3}.each do |dir|
     directory "/tmp/mydirs/#{dir}" do
       mode '0755'
       owner 'root'
       group 'root'
       action :create
       recursive true
     end
   end

.. end_tag

**Delete a directory**

.. tag resource_directory_delete

.. To delete a directory:

.. code-block:: ruby

   directory '/tmp/something' do
     recursive true
     action :delete
   end

.. end_tag

**Set directory permissions using a variable**

.. tag resource_directory_set_permissions_with_variable

The following example shows how read/write/execute permissions can be set using a variable named ``user_home``, and then for owners and groups on any matching node:

.. code-block:: ruby

   user_home = "/#{node[:matching_node][:user]}"

   directory user_home do
     owner 'node[:matching_node][:user]'
     group 'node[:matching_node][:group]'
     mode '0755'
     action :create
   end

where ``matching_node`` represents a type of node. For example, if the ``user_home`` variable specified ``{node[:nginx]...}``, a recipe might look similar to:

.. code-block:: ruby

   user_home = "/#{node[:nginx][:user]}"

   directory user_home do
     owner 'node[:nginx][:user]'
     group 'node[:nginx][:group]'
     mode '0755'
     action :create
   end

.. end_tag

**Set directory permissions for a specific type of node**

.. tag resource_directory_set_permissions_for_specific_node

The following example shows how permissions can be set for the ``/certificates`` directory on any node that is running Nginx. In this example, permissions are being set for the ``owner`` and ``group`` properties as ``root``, and then read/write permissions are granted to the root.

.. code-block:: ruby

   directory "#{node[:nginx][:dir]}/shared/certificates" do
     owner 'root'
     group 'root'
     mode '0755'
     recursive true
   end

.. end_tag

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

**Manage dotfiles**

.. tag resource_directory_manage_dotfiles

The following example shows using the **directory** and **cookbook_file** resources to manage dotfiles. The dotfiles are defined by a JSON data structure similar to:

.. code-block:: javascript

   "files": {
     ".zshrc": {
       "mode": '0755',
       "source": "dot-zshrc"
       },
     ".bashrc": {
       "mode": '0755',
       "source": "dot-bashrc"
        },
     ".bash_profile": {
       "mode": '0755',
       "source": "dot-bash_profile"
       },
     }

and then the following resources manage the dotfiles:

.. code-block:: ruby

   if u.has_key?('files')
     u['files'].each do |filename, file_data|

     directory "#{home_dir}/#{File.dirname(filename)}" do
       recursive true
       mode '0755'
     end if file_data['subdir']

     cookbook_file "#{home_dir}/#{filename}" do
       source "#{u['id']}/#{file_data['source']}"
       owner 'u['id']'
       group 'group_id'
       mode 'file_data['mode']'
       ignore_failure true
       backup 0
     end
   end

.. end_tag

dpkg_package
=====================================================
.. tag resource_package_dpkg

Use the **dpkg_package** resource to manage packages for the dpkg platform. When a package is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources.

.. end_tag

**Install a package**

.. tag resource_dpkg_package_install

.. To install a package:

.. code-block:: ruby

   dpkg_package 'name of package' do
     action :install
   end

.. end_tag

dsc_resource
=====================================================
.. tag resource_dsc_resource_summary

The **dsc_resource** resource allows any DSC resource to be used in a Chef recipe, as well as any custom resources that have been added to your Windows PowerShell environment. Microsoft `frequently adds new resources <https://github.com/powershell/DscResources>`_ to the DSC resource collection.

.. end_tag

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

dsc_script
=====================================================
.. tag resource_dsc_script_summary

Many DSC resources are comparable to built-in Chef resources. For example, both DSC and Chef have **file**, **package**, and **service** resources. The **dsc_script** resource is most useful for those DSC resources that do not have a direct comparison to a resource in Chef, such as the ``Archive`` resource, a custom DSC resource, an existing DSC script that performs an important task, and so on. Use the **dsc_script** resource to embed the code that defines a DSC configuration directly within a Chef recipe.

.. end_tag

New in Chef Client 12.2.  Changed in Chef Client 12.6.

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
=====================================================
.. tag resource_env_summary

Use the **env** resource to manage environment keys in Microsoft Windows. After an environment key is set, Microsoft Windows must be restarted before the environment key will be available to the Task Scheduler.

.. end_tag

**Set an environment variable**

.. tag resource_environment_set_variable

.. To set an environment variable:

.. code-block:: ruby

   env 'ComSpec' do
     value "C:\\Windows\\system32\\cmd.exe"
   end

.. end_tag

erl_call
=====================================================
.. tag resource_erlang_call_summary

Use the **erl_call** resource to connect to a node located within a distributed Erlang system. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

.. end_tag

**Run a command**

.. tag resource_erlang_call_run_command_on_node

.. To run a command on an Erlang node:

.. code-block:: ruby

   erl_call 'list names' do
     code 'net_adm:names().'
     distributed true
     node_name 'chef@latte'
   end

.. end_tag

execute
=====================================================
.. tag resource_execute_summary

Use the **execute** resource to execute a single command. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

.. end_tag

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

file
=====================================================
.. tag resource_file_summary

Use the **file** resource to manage files directly on a node.

.. end_tag

**Create a file**

.. tag resource_file_create

.. To create a file:

.. code-block:: ruby

   file '/tmp/something' do
     owner 'root'
     group 'root'
     mode '0755'
     action :create
   end

.. end_tag

**Create a file in Microsoft Windows**

.. tag resource_file_create_in_windows

To create a file in Microsoft Windows, be sure to add an escape character---``\``---before the backslashes in the paths:

.. code-block:: ruby

   file 'C:\\tmp\\something.txt' do
     rights :read, 'Everyone'
     rights :full_control, 'DOMAIN\\User'
     action :create
   end

.. end_tag

**Remove a file**

.. tag resource_file_remove

.. To remove a file:

.. code-block:: ruby

   file '/tmp/something' do
     action :delete
   end

.. end_tag

**Set file modes**

.. tag resource_file_set_file_mode

.. To set a file mode:

.. code-block:: ruby

   file '/tmp/something' do
     mode '0755'
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

**Add the value of a data bag item to a file**

.. tag resource_file_content_data_bag

The following example shows how to get the contents of a data bag item named ``impossible_things``, create a .pem file located at ``some/directory/path/``, and then use the ``content`` attribute to update the contents of that file with the value of the ``impossible_things`` data bag item:

.. code-block:: ruby

   private_key = data_bag_item('impossible_things', private_key_name)['private_key']

   file "some/directory/path/#{private_key_name}.pem" do
     content private_key
     owner 'root'
     group 'group'
     mode '0755'
   end

.. end_tag

**Write a YAML file**

.. tag resource_file_content_yaml_config

The following example shows how to use the ``content`` property to write a YAML file:

.. code-block:: ruby

   file "#{app['deploy_to']}/shared/config/settings.yml" do
     owner "app['owner']"
     group "app['group']"
     mode '0755'
     content app.to_yaml
   end

.. end_tag

**Write a string to a file**

.. tag resource_file_content_add_string

The following example specifies a directory, and then uses the ``content`` property to add a string to the file created in that directory:

.. code-block:: ruby

   status_file = '/path/to/file/status_file'

   file status_file do
     owner 'root'
     group 'root'
     mode '0755'
     content 'My favourite foremost coastal Antarctic shelf, oh Larsen B!'
   end

.. end_tag

**Create a file from a copy**

.. tag resource_file_copy

The following example shows how to copy a file from one directory to another, locally on a node:

.. code-block:: ruby

   file '/root/1.txt' do
     content IO.read('/tmp/1.txt')
     action :create
   end

where the ``content`` attribute uses the Ruby ``IO.read`` method to get the contents of the ``/tmp/1.txt`` file.

.. end_tag

freebsd_package
=====================================================
.. tag resource_package_freebsd

Use the **freebsd_package** resource to manage packages for the FreeBSD platform.

.. end_tag

**Install a package**

.. tag resource_freebsd_package_install

.. To install a package:

.. code-block:: ruby

   freebsd_package 'name of package' do
     action :install
   end

.. end_tag

gem_package
=====================================================
.. tag resource_package_gem

Use the **gem_package** resource to manage gem packages that are only included in recipes. When a package is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources.

.. end_tag

**Install a gems file from the local file system**

.. tag resource_package_install_gems_from_local

.. To install a gem from the local file system:

.. code-block:: ruby

   gem_package 'right_aws' do
     source '/tmp/right_aws-1.11.0.gem'
     action :install
   end

.. end_tag

**Use the ignore_failure common attribute**

.. tag resource_package_use_ignore_failure_attribute

.. To use the ``ignore_failure`` common attribute in a recipe:

.. code-block:: ruby

   gem_package 'syntax' do
     action :install
     ignore_failure true
   end

.. end_tag

git
=====================================================
.. tag resource_scm_git

Use the **git** resource to manage source control resources that exist in a git repository. git version 1.6.5 (or higher) is required to use all of the functionality in the **git** resource.

.. end_tag

**Use the git mirror**

.. tag resource_scm_use_git_mirror

.. To use the git mirror:

.. code-block:: ruby

   git '/opt/mysources/couch' do
     repository 'git://git.apache.org/couchdb.git'
     revision 'master'
     action :sync
   end

.. end_tag

**Use different branches**

.. tag resource_scm_use_different_branches

To use different branches, depending on the environment of the node:

.. code-block:: ruby

   if node.chef_environment == 'QA'
      branch_name = 'staging'
   else
      branch_name = 'master'
   end

   git '/home/user/deployment' do
      repository 'git@github.com:gitsite/deployment.git'
      revision branch_name
      action :sync
      user 'user'
      group 'test'
   end

where the ``branch_name`` variable is set to ``staging`` or ``master``, depending on the environment of the node. Once this is determined, the ``branch_name`` variable is used to set the revision for the repository. If the ``git status`` command is used after running the example above, it will return the branch name as ``deploy``, as this is the default value. Run the chef-client in debug mode to verify that the correct branches are being checked out:

.. code-block:: bash

   $ sudo chef-client -l debug

.. end_tag

**Install an application from git using bash**

.. tag resource_scm_use_bash_and_ruby_build

The following example shows how Bash can be used to install a plug-in for rbenv named ``ruby-build``, which is located in git version source control. First, the application is synchronized, and then Bash changes its working directory to the location in which ``ruby-build`` is located, and then runs a command.

.. code-block:: ruby

   git "#{Chef::Config[:file_cache_path]}/ruby-build" do
     repository 'git://github.com/sstephenson/ruby-build.git'
     reference 'master'
     action :sync
   end

   bash 'install_ruby_build' do
     cwd '#{Chef::Config[:file_cache_path]}/ruby-build'
     user 'rbenv'
     group 'rbenv'
     code <<-EOH
       ./install.sh
       EOH
     environment 'PREFIX' => '/usr/local'
  end

To read more about ``ruby-build``, see here: https://github.com/sstephenson/ruby-build.

.. end_tag

**Upgrade packages from git**

.. tag resource_scm_upgrade_packages

The following example uses the **git** resource to upgrade packages:

.. code-block:: ruby

   # the following code sample comes from the ``source`` recipe
   # in the ``libvpx-cookbook`` cookbook:
   # https://github.com/enmasse-entertainment/libvpx-cookbook

   git "#{Chef::Config[:file_cache_path]}/libvpx" do
     repository node[:libvpx][:git_repository]
     revision node[:libvpx][:git_revision]
     action :sync
     notifies :run, 'bash[compile_libvpx]', :immediately
   end

.. end_tag

**Pass in environment variables**

.. tag resource_scm_git_environment_variables

.. To pass in environment variables:

.. code-block:: ruby

   git '/opt/mysources/couch' do
     repository 'git://git.apache.org/couchdb.git'
     revision 'master'
     environment  { 'VAR' => 'whatever' }
     action :sync
   end

.. end_tag

group
=====================================================
.. tag resource_group_summary

Use the **group** resource to manage a local group.

.. end_tag

**Append users to groups**

.. tag resource_group_append_user

.. To append a user to an existing group:

.. code-block:: ruby

   group 'www-data' do
     action :modify
     members 'maintenance'
     append true
   end

.. end_tag

**Add a user to group on the Windows platform**

.. tag resource_group_add_user_on_windows

.. To add a group on the Windows platform:

.. code-block:: ruby

   group 'Administrators' do
     members ['domain\foo']
     append true
     action :modify
   end

.. end_tag

homebrew_package
=====================================================
.. tag resource_package_homebrew

Use the **homebrew_package** resource to manage packages for the macOS platform.

.. end_tag

New in Chef Client 12.0.

**Install a package**

.. tag resource_homebrew_package_install

.. To install a package:

.. code-block:: ruby

   homebrew_package 'name of package' do
     action :install
   end

.. end_tag

**Specify the Homebrew user with a UUID**

.. tag resource_homebrew_package_homebrew_user_as_uuid

.. To specify the Homebrew user as a UUID:

.. code-block:: ruby

   homebrew_package 'emacs' do
     homebrew_user 1001
   end

.. end_tag

**Specify the Homebrew user with a string**

.. tag resource_homebrew_package_homebrew_user_as_string

.. To specify the Homebrew user as a string:

.. code-block:: ruby

   homebrew_package 'vim' do
     homebrew_user 'user1'
   end

.. end_tag

http_request
=====================================================
.. tag resource_http_request_summary

Use the **http_request** resource to send an HTTP request (``GET``, ``PUT``, ``POST``, ``DELETE``, ``HEAD``, or ``OPTIONS``) with an arbitrary message. This resource is often useful when custom callbacks are necessary.

.. end_tag

**Send a GET request**

.. tag resource_http_request_send_get

.. To send a GET request:

.. code-block:: ruby

   http_request 'some_message' do
     url 'http://example.com/check_in'
   end

The message is sent as ``http://example.com/check_in?message=some_message``.

.. end_tag

Changed in Chef Client 12.0 to deprecate the hard-coded query string from earlier versions. Cookbooks that rely on this string need to be updated to manually add it to the URL as it is passed to the resource.

**Send a POST request**

.. tag resource_http_request_send_post

To send a ``POST`` request as JSON data, convert the message to JSON and include the correct content-type header. For example:

.. code-block:: ruby

   http_request 'posting data' do
     action :post
     url 'http://example.com/check_in'
     message ({:some => 'data'}.to_json)
     headers({'AUTHORIZATION' => "Basic #{
       Base64.encode64('username:password')}",
       'Content-Type' => 'application/data'
     })
   end

.. end_tag

**Transfer a file only when the remote source changes**

.. tag resource_remote_file_transfer_remote_source_changes

.. To transfer a file only if the remote source has changed (using the |resource http request| resource):

.. The "Transfer a file only when the source has changed" example is deprecated in chef-client 11-6

.. code-block:: ruby

   remote_file '/tmp/couch.png' do
     source 'http://couchdb.apache.org/img/sketch.png'
     action :nothing
   end

   http_request 'HEAD http://couchdb.apache.org/img/sketch.png' do
     message ''
     url 'http://couchdb.apache.org/img/sketch.png'
     action :head
     if File.exist?('/tmp/couch.png')
       headers 'If-Modified-Since' => File.mtime('/tmp/couch.png').httpdate
     end
     notifies :create, 'remote_file[/tmp/couch.png]', :immediately
   end

.. end_tag

ifconfig
=====================================================
.. tag resource_ifconfig_summary

Use the **ifconfig** resource to manage interfaces.

.. end_tag

**Configure a network interface**

.. tag resource_ifconfig_boot_protocol

.. To specify a boot protocol:

.. code-block:: ruby

   ifconfig "33.33.33.80" do
     bootproto "dhcp"
     device "eth1"
   end

will create the following interface:

.. code-block:: none

   vagrant@default-ubuntu-1204:~$ cat /etc/network/interfaces.d/ifcfg-eth1
   iface eth1 inet dhcp

.. end_tag

**Specify a boot protocol**

.. tag resource_ifconfig_configure_network_interface

.. To configure a network interface:

.. code-block:: ruby

   ifconfig '192.186.0.1' do
     device 'eth0'
   end

.. end_tag

**Specify a static IP address**

.. tag resource_ifconfig_static_ip_address

.. To specify a static IP address:

.. code-block:: ruby

   ifconfig "33.33.33.80" do
     device "eth1"
   end

will create the following interface:

.. code-block:: none

   iface eth1 inet static
     address 33.33.33.80

.. end_tag

**Update a static IP address with a boot protocol**

.. tag resource_ifconfig_update_static_ip_with_boot_protocol

.. To update a static IP address with a boot protocol*:

.. code-block:: ruby

   ifconfig "33.33.33.80" do
     bootproto "dhcp"
     device "eth1"
   end

will update the interface from ``static`` to ``dhcp``:

.. code-block:: none

   iface eth1 inet dhcp
     address 33.33.33.80

.. end_tag

ips_package
=====================================================
.. tag resource_package_ips

Use the **ips_package** resource to manage packages (using Image Packaging System (IPS)) on the Solaris 11 platform.

.. end_tag

**Install a package**

.. tag resource_ips_package_install

.. To install a package:

.. code-block:: ruby

   ips_package 'name of package' do
     action :install
   end

.. end_tag

ksh
=====================================================
.. tag resource_script_ksh

Use the **ksh** resource to execute scripts using the Korn shell (ksh) interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence. New in Chef Client 12.6.

.. note:: The **ksh** script resource (which is based on the **script** resource) is different from the **ruby_block** resource because Ruby code that is run with this resource is created as a temporary file and executed like other script resources, rather than run inline.

.. end_tag

No examples.

link
=====================================================
.. tag resource_link_summary

Use the **link** resource to create symbolic or hard links.

.. end_tag

**Create symbolic links**

.. tag resource_link_create_symbolic

The following example will create a symbolic link from ``/tmp/file`` to ``/etc/file``:

.. code-block:: ruby

   link '/tmp/file' do
     to '/etc/file'
   end

.. end_tag

**Create hard links**

.. tag resource_link_create_hard

The following example will create a hard link from ``/tmp/file`` to ``/etc/file``:

.. code-block:: ruby

   link '/tmp/file' do
     to '/etc/file'
     link_type :hard
   end

.. end_tag

**Delete links**

.. tag resource_link_delete

The following example will delete the ``/tmp/file`` symbolic link and uses the ``only_if`` guard to run the ``test -L`` command, which verifies that ``/tmp/file`` is a symbolic link, and then only deletes ``/tmp/file`` if the test passes:

.. code-block:: ruby

   link '/tmp/file' do
     action :delete
     only_if 'test -L /tmp/file'
   end

.. end_tag

**Create multiple symbolic links**

.. tag resource_link_multiple_links_files

The following example creates symbolic links from two files in the ``/vol/webserver/cert/`` directory to files located in the ``/etc/ssl/certs/`` directory:

.. code-block:: ruby

   link '/vol/webserver/cert/server.crt' do
     to '/etc/ssl/certs/ssl-cert-name.pem'
   end

   link '/vol/webserver/cert/server.key' do
     to '/etc/ssl/certs/ssl-cert-name.key'
   end

.. end_tag

**Create platform-specific symbolic links**

.. tag resource_link_multiple_links_redhat

The following example shows installing a filter module on Apache. The package name is different for different platforms, and for the Red Hat Enterprise Linux family, a symbolic link is required:

.. code-block:: ruby

   include_recipe 'apache2::default'

   case node['platform_family']
   when 'debian'
     ...
   when 'suse'
     ...
   when 'rhel', 'fedora'
     ...

     link '/usr/lib64/httpd/modules/mod_apreq.so' do
       to      '/usr/lib64/httpd/modules/mod_apreq2.so'
       only_if 'test -f /usr/lib64/httpd/modules/mod_apreq2.so'
     end

     link '/usr/lib/httpd/modules/mod_apreq.so' do
       to      '/usr/lib/httpd/modules/mod_apreq2.so'
       only_if 'test -f /usr/lib/httpd/modules/mod_apreq2.so'
     end
   end

   ...

For the entire recipe, see https://github.com/onehealth-cookbooks/apache2/blob/68bdfba4680e70b3e90f77e40223dd535bf22c17/recipes/mod_apreq2.rb.

.. end_tag

log
=====================================================
.. tag resource_log_summary

Use the **log** resource to create log entries. The **log** resource behaves like any other resource: built into the resource collection during the compile phase, and then run during the execution phase. (To create a log entry that is not built into the resource collection, use ``Chef::Log`` instead of the **log** resource.)

.. note:: By default, every log resource that executes will count as an updated resource in the updated resource count at the end of a Chef run. You can disable this behavior by adding ``count_log_resource_updates false`` to your Chef ``client.rb`` configuration file.

.. end_tag

**Set default logging level**

.. tag resource_log_set_info

.. To set the info (default) logging level:

.. code-block:: ruby

   log 'a string to log'

.. end_tag

**Set debug logging level**

.. tag resource_log_set_debug

.. To set the debug logging level:

.. code-block:: ruby

   log 'a debug string' do
     level :debug
   end

.. end_tag

**Add a message to a log file**

.. tag resource_log_add_message

.. To add a message to a log file:

.. code-block:: ruby

   log 'message' do
     message 'This is the message that will be added to the log.'
     level :info
   end

.. end_tag

macports_package
=====================================================
.. tag resource_package_macports

Use the **macports_package** resource to manage packages for the macOS platform.

.. end_tag

**Install a package**

.. tag resource_macports_package_install

.. To install a package:

.. code-block:: ruby

   macports_package 'name of package' do
     action :install
   end

.. end_tag

mdadm
=====================================================
.. tag resource_mdadm_summary

Use the **mdadm** resource to manage RAID devices in a Linux environment using the mdadm utility. The **mdadm** provider will create and assemble an array, but it will not create the config file that is used to persist the array upon reboot. If the config file is required, it must be done by specifying a template with the correct array layout, and then by using the **mount** provider to create a file systems table (fstab) entry.

.. end_tag

**Create and assemble a RAID 0 array**

.. tag resource_mdadm_raid0

The mdadm command can be used to create RAID arrays. For example, a RAID 0 array named ``/dev/md0`` with 10 devices would have a command similar to the following:

.. code-block:: bash

   $ mdadm --create /dev/md0 --level=0 --raid-devices=10 /dev/s01.../dev/s10

where ``/dev/s01 .. /dev/s10`` represents 10 devices (01, 02, 03, and so on). This same command, when expressed as a recipe using the **mdadm** resource, would be similar to:

.. code-block:: ruby

   mdadm '/dev/md0' do
     devices [ '/dev/s01', ... '/dev/s10' ]
     level 0
     action :create
   end

(again, where ``/dev/s01 .. /dev/s10`` represents devices /dev/s01, /dev/s02, /dev/s03, and so on).

.. end_tag

**Create and assemble a RAID 1 array**

.. tag resource_mdadm_raid1

.. To create and assemble a RAID 1 array from two disks with a 64k chunk size:

.. code-block:: ruby

   mdadm '/dev/md0' do
     devices [ '/dev/sda', '/dev/sdb' ]
     level 1
     action [ :create, :assemble ]
   end

.. end_tag

**Create and assemble a RAID 5 array**

.. tag resource_mdadm_raid5

The mdadm command can be used to create RAID arrays. For example, a RAID 5 array named ``/dev/sd0`` with 4, and a superblock type of ``0.90`` would be similar to:

.. code-block:: ruby

   mdadm '/dev/sd0' do
     devices [ '/dev/s1', '/dev/s2', '/dev/s3', '/dev/s4' ]
     level 5
     metadata '0.90'
     chunk 32
     action :create
   end

.. end_tag

mount
=====================================================
.. tag resource_mount_summary

Use the **mount** resource to manage a mounted file system.

.. end_tag

**Mount a labeled file system**

.. tag resource_mount_labeled_file_system

.. To mount a labeled file system:

.. code-block:: ruby

   mount '/mnt/volume1' do
     device 'volume1'
     device_type :label
     fstype 'xfs'
     options 'rw'
   end

.. end_tag

**Mount a local block drive**

.. tag resource_mount_local_block_device

.. To mount a local block device:

.. code-block:: ruby

   mount '/mnt/local' do
     device '/dev/sdb1'
     fstype 'ext3'
   end

.. end_tag

**Mount a non-block file system**

.. tag resource_mount_nonblock_file_system

.. To mount a non-block file system

.. code-block:: ruby

   mount '/mount/tmp' do
     pass     0
     fstype   'tmpfs'
     device   '/dev/null'
     options  'nr_inodes=999k,mode=755,size=500m'
     action   [:mount, :enable]
   end

.. end_tag

**Mount and add to the file systems table**

.. tag resource_mount_remote_file_system_add_to_fstab

.. To mount a remote file system and add it to the file systems table:

.. code-block:: ruby

   mount '/export/www' do
     device 'nas1prod:/export/web_sites'
     fstype 'nfs'
     options 'rw'
     action [:mount, :enable]
   end

.. end_tag

**Mount a remote file system**

.. tag resource_mount_remote_file_system

.. To mount a remote file system:

.. code-block:: ruby

   mount '/export/www' do
     device 'nas1prod:/export/web_sites'
     fstype 'nfs'
     options 'rw'
   end

.. end_tag

**Mount a remote folder in Microsoft Windows**

.. tag resource_mount_remote_windows_folder

.. To mount a remote Microsoft Windows folder on local drive letter T:

.. code-block:: ruby

   mount 'T:' do
     action :mount
     device '\\\\hostname.example.com\\folder'
   end

.. end_tag

**Unmount a remote folder in Microsoft Windows**

.. tag resource_mount_unmount_remote_windows_drive

.. To un-mount a remote Microsoft Windows D: drive attached as local drive letter T:

.. code-block:: ruby

   mount 'T:' do
     action :umount
     device '\\\\hostname.example.com\\D$'
   end

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

ohai
=====================================================
.. tag resource_ohai_summary

Use the **ohai** resource to reload the Ohai configuration on a node. This allows recipes that change system attributes (like a recipe that adds a user) to refer to those attributes later on during the chef-client run.

.. end_tag

**Reload Ohai**

.. tag resource_ohai_reload

.. To reload Ohai:

.. code-block:: ruby

   ohai 'reload' do
     action :reload
   end

.. end_tag

**Reload Ohai after a new user is created**

.. tag resource_ohai_reload_after_create_user

.. To reload Ohai configuration after a new user is created:

.. code-block:: ruby

   ohai 'reload_passwd' do
     action :nothing
     plugin 'etc'
   end

   user 'daemonuser' do
     home '/dev/null'
     shell '/sbin/nologin'
     system true
     notifies :reload, 'ohai[reload_passwd]', :immediately
   end

   ruby_block 'just an example' do
     block do
       # These variables will now have the new values
       puts node['etc']['passwd']['daemonuser']['uid']
       puts node['etc']['passwd']['daemonuser']['gid']
     end
   end

.. end_tag

openbsd_package
=====================================================
.. tag resource_package_openbsd

Use the **openbsd_package** resource to manage packages for the OpenBSD platform.

.. end_tag

**Install a package**

.. tag resource_openbsd_package_install

.. To install a package:

.. code-block:: ruby

   openbsd_package 'name of package' do
     action :install
   end

.. end_tag

New in Chef Client 12.1.

osx_profile
=====================================================
.. tag resource_osx_profile_summary

Use the **osx_profile** resource to manage configuration profiles (``.mobileconfig`` files) on the macOS platform. The **osx_profile** resource installs profiles by using the ``uuidgen`` library to generate a unique ``ProfileUUID``, and then using the ``profiles`` command to install the profile on the system.

.. end_tag

**One liner to install profile from cookbook file**

.. tag resource_osx_profile_install_file_oneline

The ``profiles`` command will be used to install the specified configuration profile.

.. code-block:: ruby

   osx_profile 'com.company.screensaver.mobileconfig'

.. end_tag

**Install profile from cookbook file**

.. tag resource_osx_profile_install_file

The ``profiles`` command will be used to install the specified configuration profile. It can be in sub-directory within a cookbook.

.. code-block:: ruby

   osx_profile 'Install screensaver profile' do
     profile 'screensaver/com.company.screensaver.mobileconfig'
   end

.. end_tag

**Install profile from a hash**

.. tag resource_osx_profile_install_hash

The ``profiles`` command will be used to install the configuration profile, which is provided as a hash.

.. code-block:: ruby

   profile_hash = {
     'PayloadIdentifier' => 'com.company.screensaver',
     'PayloadRemovalDisallowed' => false,
     'PayloadScope' => 'System',
     'PayloadType' => 'Configuration',
     'PayloadUUID' => '1781fbec-3325-565f-9022-8aa28135c3cc',
     'PayloadOrganization' => 'Chef',
     'PayloadVersion' => 1,
     'PayloadDisplayName' => 'Screensaver Settings',
     'PayloadContent'=> [
       {
         'PayloadType' => 'com.apple.ManagedClient.preferences',
         'PayloadVersion' => 1,
         'PayloadIdentifier' => 'com.company.screensaver',
         'PayloadUUID' => '73fc30e0-1e57-0131-c32d-000c2944c108',
         'PayloadEnabled' => true,
         'PayloadDisplayName' => 'com.apple.screensaver',
         'PayloadContent' => {
           'com.apple.screensaver' => {
             'Forced' => [
               {
                 'mcx_preference_settings' => {
                   'idleTime' => 0,
                 }
               }
             ]
           }
         }
       }
     ]
   }

   osx_profile 'Install screensaver profile' do
     profile profile_hash
   end

.. end_tag

**Remove profile using identifier in resource name**

.. tag resource_osx_profile_remove_by_name

The ``profiles`` command will be used to remove the configuration profile specified by the provided ``identifier`` property.

.. code-block:: ruby

   osx_profile 'com.company.screensaver' do
     action :remove
   end

.. end_tag

**Remove profile by identifier and user friendly resource name**

.. tag resource_osx_profile_remove_by_identifier

The ``profiles`` command will be used to remove the configuration profile specified by the provided ``identifier`` property.

.. code-block:: ruby

   osx_profile 'Remove screensaver profile' do
     identifier 'com.company.screensaver'
     action :remove
   end

.. end_tag

package
=====================================================
.. tag resource_package_summary

Use the **package** resource to manage packages. When the package is installed from a local file (such as with RubyGems, dpkg, or RPM Package Manager), the file must be added to the node using the **remote_file** or **cookbook_file** resources.

.. end_tag

**Install a gems file for use in recipes**

.. tag resource_package_install_gems_for_chef_recipe

.. To install a gem only for use in recipes:

.. code-block:: ruby

   chef_gem 'right_aws' do
     action :install
   end

   require 'right_aws'

.. end_tag

**Install a gems file from the local file system**

.. tag resource_package_install_gems_from_local

.. To install a gem from the local file system:

.. code-block:: ruby

   gem_package 'right_aws' do
     source '/tmp/right_aws-1.11.0.gem'
     action :install
   end

.. end_tag

**Install a package**

.. tag resource_package_install

.. To install a package:

.. code-block:: ruby

   package 'tar' do
     action :install
   end

.. end_tag

**Install a package version**

.. tag resource_package_install_version

.. To install a specific package version:

.. code-block:: ruby

   package 'tar' do
     version '1.16.1-1'
     action :install
   end

.. end_tag

**Install a package with options**

.. tag resource_package_install_with_options

.. To install a package with options:

.. code-block:: ruby

   package 'debian-archive-keyring' do
     action :install
     options '--force-yes'
   end

.. end_tag

**Install a package with a response_file**

.. tag resource_package_install_with_response_file

Use of a ``response_file`` is only supported on Debian and Ubuntu at this time. Custom resources must be written to support the use of a ``response_file``, which contains debconf answers to questions normally asked by the package manager on installation. Put the file in ``/files/default`` of the cookbook where the package is specified and the chef-client will use the **cookbook_file** resource to retrieve it.

To install a package with a ``response_file``:

.. code-block:: ruby

   package 'sun-java6-jdk' do
     response_file 'java.seed'
   end

.. end_tag

**Install a package using a specific provider**

.. tag resource_package_install_with_specific_provider

.. To install a package using a specific provider:

.. code-block:: ruby

   package 'tar' do
     action :install
     source '/tmp/tar-1.16.1-1.rpm'
     provider Chef::Provider::Package::Rpm
   end

.. end_tag

**Install a specified architecture using a named provider**

.. tag resource_package_install_with_yum

.. To install a Yum package with a specified architecture:

.. code-block:: ruby

   yum_package 'glibc-devel' do
     arch 'i386'
   end

.. end_tag

**Purge a package**

.. tag resource_package_purge

.. To purge a package:

.. code-block:: ruby

   package 'tar' do
     action :purge
   end

.. end_tag

**Remove a package**

.. tag resource_package_remove

.. To remove a package:

.. code-block:: ruby

   package 'tar' do
     action :remove
   end

.. end_tag

**Upgrade a package**

.. tag resource_package_upgrade

.. To upgrade a package

.. code-block:: ruby

   package 'tar' do
     action :upgrade
   end

.. end_tag

**Use the ignore_failure common attribute**

.. tag resource_package_use_ignore_failure_attribute

.. To use the ``ignore_failure`` common attribute in a recipe:

.. code-block:: ruby

   gem_package 'syntax' do
     action :install
     ignore_failure true
   end

.. end_tag

**Use the provider common attribute**

.. tag resource_package_use_provider_attribute

.. To use the ``:provider`` common attribute in a recipe:

.. code-block:: ruby

   package 'some_package' do
     provider Chef::Provider::Package::Rubygems
   end

.. end_tag

**Avoid unnecessary string interpolation**

.. tag resource_package_avoid_unnecessary_string_interpolation

.. To avoid unnecessary string interpolation

Do this:

.. code-block:: ruby

   package 'mysql-server' do
     version node['mysql']['version']
     action :install
   end

and not this:

.. code-block:: ruby

   package 'mysql-server' do
     version "#{node['mysql']['version']}"
     action :install
   end

.. end_tag

**Install a package in a platform**

.. tag resource_package_install_package_on_platform

The following example shows how to use the **package** resource to install an application named ``app`` and ensure that the correct packages are installed for the correct platform:

.. code-block:: ruby

   package 'app_name' do
     action :install
   end

   case node[:platform]
   when 'ubuntu','debian'
     package 'app_name-doc' do
       action :install
     end
   when 'centos'
     package 'app_name-html' do
       action :install
     end
   end

.. end_tag

**Install sudo, then configure /etc/sudoers/ file**

.. tag resource_package_install_sudo_configure_etc_sudoers

The following example shows how to install sudo and then configure the ``/etc/sudoers`` file:

.. code-block:: ruby

   #  the following code sample comes from the ``default`` recipe in the ``sudo`` cookbook: https://github.com/chef-cookbooks/sudo

   package 'sudo' do
     action :install
   end

   if node['authorization']['sudo']['include_sudoers_d']
     directory '/etc/sudoers.d' do
       mode        '0755'
       owner       'root'
       group       'root'
       action      :create
     end

     cookbook_file '/etc/sudoers.d/README' do
       source      'README'
       mode        '0440'
       owner       'root'
       group       'root'
       action      :create
     end
   end

   template '/etc/sudoers' do
     source 'sudoers.erb'
     mode '0440'
     owner 'root'
     group platform?('freebsd') ? 'wheel' : 'root'
     variables(
       :sudoers_groups => node['authorization']['sudo']['groups'],
       :sudoers_users => node['authorization']['sudo']['users'],
       :passwordless => node['authorization']['sudo']['passwordless']
     )
   end

where

* the **package** resource is used to install sudo
* the ``if`` statement is used to ensure availability of the ``/etc/sudoers.d`` directory
* the **template** resource tells the chef-client where to find the ``sudoers`` template
* the ``variables`` property is a hash that passes values to template files (that are located in the ``templates/`` directory for the cookbook

.. end_tag

**Use a case statement to specify the platform**

.. tag resource_package_use_case_statement

The following example shows how to use a case statement to tell the chef-client which platforms and packages to install using cURL.

.. code-block:: ruby

   package 'curl'
     case node[:platform]
     when 'redhat', 'centos'
       package 'package_1'
       package 'package_2'
       package 'package_3'
     when 'ubuntu', 'debian'
       package 'package_a'
       package 'package_b'
       package 'package_c'
     end
   end

where ``node[:platform]`` for each node is identified by Ohai during every chef-client run. For example:

.. code-block:: ruby

   package 'curl'
     case node[:platform]
     when 'redhat', 'centos'
       package 'zlib-devel'
       package 'openssl-devel'
       package 'libc6-dev'
     when 'ubuntu', 'debian'
       package 'openssl'
       package 'pkg-config'
       package 'subversion'
     end
   end

.. end_tag

**Use symbols to reference attributes**

.. tag resource_package_use_symbols_to_reference_attributes

.. To use symbols to reference attributes

Symbols may be used to reference attributes:

.. code-block:: ruby

   package 'mysql-server' do
     version node[:mysql][:version]
     action :install
   end

instead of strings:

.. code-block:: ruby

   package 'mysql-server' do
     version node['mysql']['version']
     action :install
   end

.. end_tag

**Use a whitespace array to simplify a recipe**

.. tag resource_package_use_whitespace_array

The following examples show different ways of doing the same thing. The first shows a series of packages that will be upgraded:

.. code-block:: ruby

   package 'package-a' do
     action :upgrade
   end

   package 'package-b' do
     action :upgrade
   end

   package 'package-c' do
     action :upgrade
   end

   package 'package-d' do
     action :upgrade
   end

and the next uses a single **package** resource and a whitespace array (``%w``):

.. code-block:: ruby

   %w{package-a package-b package-c package-d}.each do |pkg|
     package pkg do
       action :upgrade
     end
   end

where ``|pkg|`` is used to define the name of the resource, but also to ensure that each item in the whitespace array has its own name.

.. end_tag

**Specify the Homebrew user with a UUID**

.. tag resource_homebrew_package_homebrew_user_as_uuid

.. To specify the Homebrew user as a UUID:

.. code-block:: ruby

   homebrew_package 'emacs' do
     homebrew_user 1001
   end

.. end_tag

**Specify the Homebrew user with a string**

.. tag resource_homebrew_package_homebrew_user_as_string

.. To specify the Homebrew user as a string:

.. code-block:: ruby

   homebrew_package 'vim' do
     homebrew_user 'user1'
   end

.. end_tag

pacman_package
=====================================================
.. tag resource_package_pacman

Use the **pacman_package** resource to manage packages (using pacman) on the Arch Linux platform.

.. end_tag

**Install a package**

.. tag resource_pacman_package_install

.. To install a package:

.. code-block:: ruby

   pacman_package 'name of package' do
     action :install
   end

.. end_tag

paludis_package
=====================================================
.. tag resource_package_paludis

Use the **paludis_package** resource to manage packages for the Paludis platform.

.. end_tag

**Install a package**

.. tag resource_paludis_package_install

.. To install a package:

.. code-block:: ruby

   paludis_package 'name of package' do
     action :install
   end

.. end_tag

New in Chef Client 12.1.

perl
=====================================================
.. tag resource_script_perl

Use the **perl** resource to execute scripts using the Perl interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

.. note:: The **perl** script resource (which is based on the **script** resource) is different from the **ruby_block** resource because Ruby code that is run with this resource is created as a temporary file and executed like other script resources, rather than run inline.

.. end_tag

No examples.

portage_package
=====================================================
.. tag resource_package_portage

Use the **portage_package** resource to manage packages for the Gentoo platform.

.. end_tag

**Install a package**

.. tag resource_portage_package_install

.. To install a package:

.. code-block:: ruby

   portage_package 'name of package' do
     action :install
   end

.. end_tag

powershell_script
=====================================================
.. tag resource_powershell_script_summary

Use the **powershell_script** resource to execute a script using the Windows PowerShell interpreter, much like how the **script** and **script**-based resources---**bash**, **csh**, **perl**, **python**, and **ruby**---are used. The **powershell_script** is specific to the Microsoft Windows platform and the Windows PowerShell interpreter.

The **powershell_script** resource creates and executes a temporary file (similar to how the **script** resource behaves), rather than running the command inline. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

.. end_tag

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

**Evaluate for true and/or false**

.. tag resource_powershell_convert_boolean_return

.. To return ``0`` for true, ``1`` for false:

Use the ``convert_boolean_return`` attribute to raise an exception when certain conditions are met. For example, the following fragments will run successfully without error:

.. code-block:: ruby

   powershell_script 'false' do
     code '$false'
   end

and:

.. code-block:: ruby

   powershell_script 'true' do
     code '$true'
   end

whereas the following will raise an exception:

.. code-block:: ruby

   powershell_script 'false' do
     convert_boolean_return true
     code '$false'
   end

.. end_tag

**Use the flags attribute**

.. tag resource_powershell_script_use_flag

.. To use the flags attribute:

.. code-block:: ruby

   powershell_script 'Install IIS' do
     code <<-EOH
     Import-Module ServerManager
     Add-WindowsFeature Web-Server
     EOH
     flags '-NoLogo, -NonInteractive, -NoProfile, -ExecutionPolicy Unrestricted, -InputFormat None, -File'
     guard_interpreter :powershell_script
     not_if '(Get-WindowsFeature -Name Web-Server).Installed'
   end

.. end_tag

**Rename computer, join domain, reboot**

.. tag resource_powershell_rename_join_reboot

The following example shows how to rename a computer, join a domain, and then reboot the computer:

.. code-block:: ruby

   reboot 'Restart Computer' do
     action :nothing
   end

   powershell_script 'Rename and Join Domain' do
     code <<-EOH
       ...your rename and domain join logic here...
     EOH
     not_if <<-EOH
       $ComputerSystem = gwmi win32_computersystem
       ($ComputerSystem.Name -like '#{node['some_attribute_that_has_the_new_name']}') -and
         $ComputerSystem.partofdomain)
     EOH
     notifies :reboot_now, 'reboot[Restart Computer]', :immediately
   end

where:

* The **powershell_script** resource block renames a computer, and then joins a domain
* The **reboot** resource restarts the computer
* The ``not_if`` guard prevents the Windows PowerShell script from running when the settings in the ``not_if`` guard match the desired state
* The ``notifies`` statement tells the **reboot** resource block to run if the **powershell_script** block was executed during the chef-client run

.. end_tag

python
=====================================================
.. tag resource_script_python

Use the **python** resource to execute scripts using the Python interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

.. note:: The **python** script resource (which is based on the **script** resource) is different from the **ruby_block** resource because Ruby code that is run with this resource is created as a temporary file and executed like other script resources, rather than run inline.

.. end_tag

No examples.

reboot
=====================================================
.. tag resource_service_reboot

Use the **reboot** resource to reboot a node, a necessary step with some installations on certain platforms. This resource is supported for use on the Microsoft Windows, macOS, and Linux platforms.  New in Chef Client 12.0.

.. end_tag

**Reboot a node immediately**

.. tag resource_service_reboot_immediately

.. To reboot immediately:

.. code-block:: ruby

   reboot 'now' do
     action :nothing
     reason 'Cannot continue Chef run without a reboot.'
     delay_mins 2
   end

   execute 'foo' do
     command '...'
     notifies :reboot_now, 'reboot[now]', :immediately
   end

.. end_tag

**Reboot a node at the end of a chef-client run**

.. tag resource_service_reboot_request

.. To reboot a node at the end of the chef-client run:

.. code-block:: ruby

   reboot 'app_requires_reboot' do
     action :request_reboot
     reason 'Need to reboot when the run completes successfully.'
     delay_mins 5
   end

.. end_tag

**Cancel a reboot**

.. tag resource_service_reboot_cancel

.. To cancel a reboot request:

.. code-block:: ruby

   reboot 'cancel_reboot_request' do
     action :cancel
     reason 'Cancel a previous end-of-run reboot request.'
   end

.. end_tag

**Rename computer, join domain, reboot**

.. tag resource_powershell_rename_join_reboot

The following example shows how to rename a computer, join a domain, and then reboot the computer:

.. code-block:: ruby

   reboot 'Restart Computer' do
     action :nothing
   end

   powershell_script 'Rename and Join Domain' do
     code <<-EOH
       ...your rename and domain join logic here...
     EOH
     not_if <<-EOH
       $ComputerSystem = gwmi win32_computersystem
       ($ComputerSystem.Name -like '#{node['some_attribute_that_has_the_new_name']}') -and
         $ComputerSystem.partofdomain)
     EOH
     notifies :reboot_now, 'reboot[Restart Computer]', :immediately
   end

where:

* The **powershell_script** resource block renames a computer, and then joins a domain
* The **reboot** resource restarts the computer
* The ``not_if`` guard prevents the Windows PowerShell script from running when the settings in the ``not_if`` guard match the desired state
* The ``notifies`` statement tells the **reboot** resource block to run if the **powershell_script** block was executed during the chef-client run

.. end_tag

registry_key
=====================================================
.. tag resource_registry_key_summary

Use the **registry_key** resource to create and delete registry keys in Microsoft Windows.

.. end_tag

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

.. tag resource_registry_key_delete_recursively

.. To delete a registry key and all of its subkeys recursively:

Use a double-quoted string:

.. code-block:: ruby

   registry_key "HKCU\\SOFTWARE\\Policies\\path\\to\\key\\Themes" do
     recursive true
     action :delete_key
   end

or a single-quoted string:

.. code-block:: ruby

   registry_key 'HKCU\SOFTWARE\Policies\path\to\key\Themes' do
     recursive true
     action :delete_key
   end

.. note:: .. tag notes_registry_key_resource_recursive

          Be careful when using the ``:delete_key`` action with the ``recursive`` attribute. This will delete the registry key, all of its values and all of the names, types, and data associated with them. This cannot be undone by the chef-client.

          .. end_tag

.. end_tag

**Use re-directed keys**

.. tag resource_registry_key_redirect

In 64-bit versions of Microsoft Windows, ``HKEY_LOCAL_MACHINE\SOFTWARE\Example`` is a re-directed key. In the following examples, because ``HKEY_LOCAL_MACHINE\SOFTWARE\Example`` is a 32-bit key, the output will be "Found 32-bit key" if they are run on a version of Microsoft Windows that is 64-bit:

.. code-block:: ruby

   registry_key "HKEY_LOCAL_MACHINE\\SOFTWARE\\Example" do
     architecture :i386
     recursive true
     action :create
   end

or:

.. code-block:: ruby

   registry_key "HKEY_LOCAL_MACHINE\\SOFTWARE\\Example" do
     architecture :x86_64
     recursive true
     action :delete_key
   end

or:

.. code-block:: ruby

   ruby_block 'check 32-bit' do
     block do
       puts 'Found 32-bit key'
     end
     only_if {
       registry_key_exists?("HKEY_LOCAL_MACHINE\SOFTWARE\\Example",
       :i386)
     }
   end

or:

.. code-block:: ruby

   ruby_block 'check 64-bit' do
     block do
       puts 'Found 64-bit key'
     end
     only_if {
       registry_key_exists?("HKEY_LOCAL_MACHINE\\SOFTWARE\\Example",
       :x86_64)
     }
   end

.. end_tag

**Set proxy settings to be the same as those used by the chef-client**

.. tag resource_registry_key_set_proxy_settings_to_same_as_chef_client

.. To set system proxy settings to be the same as used by the chef-client:

Use a double-quoted string:

.. code-block:: ruby

   proxy = URI.parse(Chef::Config[:http_proxy])
   registry_key "HKCU\Software\Microsoft\path\to\key\Internet Settings" do
     values [{:name => 'ProxyEnable', :type => :reg_dword, :data => 1},
             {:name => 'ProxyServer', :data => "#{proxy.host}:#{proxy.port}"},
             {:name => 'ProxyOverride', :type => :reg_string, :data => <local>},
            ]
     action :create
   end

or a single-quoted string:

.. code-block:: ruby

   proxy = URI.parse(Chef::Config[:http_proxy])
   registry_key 'HKCU\Software\Microsoft\path\to\key\Internet Settings' do
     values [{:name => 'ProxyEnable', :type => :reg_dword, :data => 1},
             {:name => 'ProxyServer', :data => "#{proxy.host}:#{proxy.port}"},
             {:name => 'ProxyOverride', :type => :reg_string, :data => <local>},
            ]
     action :create
   end

.. end_tag

**Set the name of a registry key to "(Default)"**

.. tag resource_registry_key_set_default

.. To set the "(Default)" name of a registry key:

Use a double-quoted string:

.. code-block:: ruby

   registry_key 'Set (Default) value' do
     action :create
     key "HKLM\\Software\\Test\\Key\\Path"
     values [
       {:name => '', :type => :string, :data => 'test'},
     ]
   end

or a single-quoted string:

.. code-block:: ruby

   registry_key 'Set (Default) value' do
     action :create
     key 'HKLM\Software\Test\Key\Path'
     values [
       {:name => '', :type => :string, :data => 'test'},
     ]
   end

where ``:name => ''`` contains an empty string, which will set the name of the registry key to ``(Default)``.

.. end_tag

remote_directory
=====================================================
.. tag resource_remote_directory_summary

Use the **remote_directory** resource to incrementally transfer a directory from a cookbook to a node. The directory that is copied from the cookbook should be located under ``COOKBOOK_NAME/files/default/REMOTE_DIRECTORY``. The **remote_directory** resource will obey file specificity.

.. end_tag

**Recursively transfer a directory from a remote location**

.. tag resource_remote_directory_recursive_transfer

.. To recursively transfer a directory from a remote location:

.. code-block:: ruby

   # create up to 10 backups of the files
   # set the files owner different from the directory
   remote_directory '/tmp/remote_something' do
     source 'something'
     files_backup 10
     files_owner 'root'
     files_group 'root'
     files_mode '0644'
     owner 'nobody'
     group 'nobody'
     mode '0755'
   end

.. end_tag

**Use with the chef_handler lightweight resource**

.. tag resource_remote_directory_report_handler

The following example shows how to use the **remote_directory** resource and the **chef_handler** resource to reboot a handler named ``WindowsRebootHandler``:

.. code-block:: ruby

   # the following code sample comes from the
   # ``reboot_handler`` recipe in the ``windows`` cookbook:
   # https://github.com/chef-cookbooks/windows

   remote_directory node['chef_handler']['handler_path'] do
     source 'handlers'
     recursive true
     action :create
   end

   chef_handler 'WindowsRebootHandler' do
     source "#{node['chef_handler']['handler_path']}/windows_reboot_handler.rb"
     arguments node['windows']['allow_pending_reboots']
     supports :report => true, :exception => false
     action :enable
   end

.. end_tag

remote_file
=====================================================
.. tag resource_remote_file_summary

Use the **remote_file** resource to transfer a file from a remote location using file specificity. This resource is similar to the **file** resource.

.. end_tag

**Transfer a file from a URL**

.. tag resource_remote_file_transfer_from_url

.. To transfer a file from a URL:

.. code-block:: ruby

   remote_file '/tmp/testfile' do
     source 'http://www.example.com/tempfiles/testfile'
     mode '0755'
     checksum '3a7dac00b1' # A SHA256 (or portion thereof) of the file.
   end

.. end_tag

**Install a file from a remote location using bash**

.. tag resource_remote_file_install_with_bash

The following is an example of how to install the ``foo123`` module for Nginx. This module adds shell-style functionality to an Nginx configuration file and does the following:

* Declares three variables
* Gets the Nginx file from a remote location
* Installs the file using Bash to the path specified by the ``src_filepath`` variable

.. code-block:: ruby

   # the following code sample is similar to the ``upload_progress_module``
   # recipe in the ``nginx`` cookbook:
   # https://github.com/chef-cookbooks/nginx

   src_filename = "foo123-nginx-module-v#{
     node['nginx']['foo123']['version']
   }.tar.gz"
   src_filepath = "#{Chef::Config['file_cache_path']}/#{src_filename}"
   extract_path = "#{
     Chef::Config['file_cache_path']
     }/nginx_foo123_module/#{
     node['nginx']['foo123']['checksum']
   }"

   remote_file 'src_filepath' do
     source node['nginx']['foo123']['url']
     checksum node['nginx']['foo123']['checksum']
     owner 'root'
     group 'root'
     mode '0755'
   end

   bash 'extract_module' do
     cwd ::File.dirname(src_filepath)
     code <<-EOH
       mkdir -p #{extract_path}
       tar xzf #{src_filename} -C #{extract_path}
       mv #{extract_path}/*/* #{extract_path}/
       EOH
     not_if { ::File.exist?(extract_path) }
   end

.. end_tag

**Store certain settings**

.. tag resource_remote_file_store_certain_settings

The following recipe shows how an attributes file can be used to store certain settings. An attributes file is located in the ``attributes/`` directory in the same cookbook as the recipe which calls the attributes file. In this example, the attributes file specifies certain settings for Python that are then used across all nodes against which this recipe will run.

Python packages have versions, installation directories, URLs, and checksum files. An attributes file that exists to support this type of recipe would include settings like the following:

.. code-block:: ruby

   default['python']['version'] = '2.7.1'

   if python['install_method'] == 'package'
     default['python']['prefix_dir'] = '/usr'
   else
     default['python']['prefix_dir'] = '/usr/local'
   end

   default['python']['url'] = 'http://www.python.org/ftp/python'
   default['python']['checksum'] = '80e387...85fd61'

and then the methods in the recipe may refer to these values. A recipe that is used to install Python will need to do the following:

* Identify each package to be installed (implied in this example, not shown)
* Define variables for the package ``version`` and the ``install_path``
* Get the package from a remote location, but only if the package does not already exist on the target system
* Use the **bash** resource to install the package on the node, but only when the package is not already installed

.. code-block:: ruby

   #  the following code sample comes from the ``oc-nginx`` cookbook on |github|: https://github.com/cookbooks/oc-nginx

   version = node['python']['version']
   install_path = "#{node['python']['prefix_dir']}/lib/python#{version.split(/(^\d+\.\d+)/)[1]}"

   remote_file "#{Chef::Config[:file_cache_path]}/Python-#{version}.tar.bz2" do
     source "#{node['python']['url']}/#{version}/Python-#{version}.tar.bz2"
     checksum node['python']['checksum']
     mode '0755'
     not_if { ::File.exist?(install_path) }
   end

   bash 'build-and-install-python' do
     cwd Chef::Config[:file_cache_path]
     code <<-EOF
       tar -jxvf Python-#{version}.tar.bz2
       (cd Python-#{version} && ./configure #{configure_options})
       (cd Python-#{version} && make && make install)
     EOF
     not_if { ::File.exist?(install_path) }
   end

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

**Specify local Windows file path as a valid URI**

.. tag resource_remote_file_local_windows_path

When specifying a local Microsoft Windows file path as a valid file URI, an additional forward slash (``/``) is required. For example:

.. code-block:: ruby

   remote_file 'file:///c:/path/to/file' do
     ...       # other attributes
   end

.. end_tag

route
=====================================================
.. tag resource_route_summary

Use the **route** resource to manage the system routing table in a Linux environment.

.. end_tag

**Add a host route**

.. tag resource_route_add_host

.. To add a host route:

.. code-block:: ruby

   route '10.0.1.10/32' do
     gateway '10.0.0.20'
     device 'eth1'
   end

.. end_tag

**Delete a network route**

.. tag resource_route_delete_network

.. To delete a network route:

.. code-block:: ruby

   route '10.1.1.0/24' do
     gateway '10.0.0.20'
     action :delete
   end

.. end_tag

rpm_package
=====================================================
.. tag resource_package_rpm

Use the **rpm_package** resource to manage packages for the RPM Package Manager platform.

.. end_tag

**Install a package**

.. tag resource_rpm_package_install

.. To install a package:

.. code-block:: ruby

   rpm_package 'name of package' do
     action :install
   end

.. end_tag

ruby
=====================================================
.. tag resource_script_ruby

Use the **ruby** resource to execute scripts using the Ruby interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

.. note:: The **ruby** script resource (which is based on the **script** resource) is different from the **ruby_block** resource because Ruby code that is run with this resource is created as a temporary file and executed like other script resources, rather than run inline.

.. end_tag

No examples.

ruby_block
=====================================================
.. tag resource_ruby_block_summary

Use the **ruby_block** resource to execute Ruby code during a chef-client run. Ruby code in the ``ruby_block`` resource is evaluated with other resources during convergence, whereas Ruby code outside of a ``ruby_block`` resource is evaluated before other resources, as the recipe is compiled.

.. end_tag

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

script
=====================================================
.. tag resource_script_summary

Use the **script** resource to execute scripts using a specified interpreter, such as Bash, csh, Perl, Python, or Ruby. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

.. note:: The **script** resource is different from the **ruby_block** resource because Ruby code that is run with this resource is created as a temporary file and executed like other script resources, rather than run inline.

.. end_tag

**Use a named provider to run a script**

.. tag resource_script_bash_provider_and_interpreter

.. To use the |resource bash| resource to run a script:

.. code-block:: ruby

   bash 'install_something' do
     user 'root'
     cwd '/tmp'
     code <<-EOH
     wget http://www.example.com/tarball.tar.gz
     tar -zxf tarball.tar.gz
     cd tarball
     ./configure
     make
     make install
     EOH
   end

.. end_tag

**Run a script**

.. tag resource_script_bash_script

.. To run a Bash script:

.. code-block:: ruby

   script 'install_something' do
     interpreter 'bash'
     user 'root'
     cwd '/tmp'
     code <<-EOH
     wget http://www.example.com/tarball.tar.gz
     tar -zxf tarball.tar.gz
     cd tarball
     ./configure
     make
     make install
     EOH
   end

or something like:

.. code-block:: ruby

   bash 'openvpn-server-key' do
     environment('KEY_CN' => 'server')
     code <<-EOF
       openssl req -batch -days #{node['openvpn']['key']['expire']} \
         -nodes -new -newkey rsa:#{key_size} -keyout #{key_dir}/server.key \
         -out #{key_dir}/server.csr -extensions server \
         -config #{key_dir}/openssl.cnf
     EOF
     not_if { File.exist?('#{key_dir}/server.crt') }
   end

where ``code`` contains the OpenSSL command to be run. The ``not_if`` property tells the chef-client not to run the command if the file already exists.

.. end_tag

**Install a file from a remote location using bash**

.. tag resource_remote_file_install_with_bash

The following is an example of how to install the ``foo123`` module for Nginx. This module adds shell-style functionality to an Nginx configuration file and does the following:

* Declares three variables
* Gets the Nginx file from a remote location
* Installs the file using Bash to the path specified by the ``src_filepath`` variable

.. code-block:: ruby

   # the following code sample is similar to the ``upload_progress_module``
   # recipe in the ``nginx`` cookbook:
   # https://github.com/chef-cookbooks/nginx

   src_filename = "foo123-nginx-module-v#{
     node['nginx']['foo123']['version']
   }.tar.gz"
   src_filepath = "#{Chef::Config['file_cache_path']}/#{src_filename}"
   extract_path = "#{
     Chef::Config['file_cache_path']
     }/nginx_foo123_module/#{
     node['nginx']['foo123']['checksum']
   }"

   remote_file 'src_filepath' do
     source node['nginx']['foo123']['url']
     checksum node['nginx']['foo123']['checksum']
     owner 'root'
     group 'root'
     mode '0755'
   end

   bash 'extract_module' do
     cwd ::File.dirname(src_filepath)
     code <<-EOH
       mkdir -p #{extract_path}
       tar xzf #{src_filename} -C #{extract_path}
       mv #{extract_path}/*/* #{extract_path}/
       EOH
     not_if { ::File.exist?(extract_path) }
   end

.. end_tag

**Install an application from git using bash**

.. tag resource_scm_use_bash_and_ruby_build

The following example shows how Bash can be used to install a plug-in for rbenv named ``ruby-build``, which is located in git version source control. First, the application is synchronized, and then Bash changes its working directory to the location in which ``ruby-build`` is located, and then runs a command.

.. code-block:: ruby

   git "#{Chef::Config[:file_cache_path]}/ruby-build" do
     repository 'git://github.com/sstephenson/ruby-build.git'
     reference 'master'
     action :sync
   end

   bash 'install_ruby_build' do
     cwd '#{Chef::Config[:file_cache_path]}/ruby-build'
     user 'rbenv'
     group 'rbenv'
     code <<-EOH
       ./install.sh
       EOH
     environment 'PREFIX' => '/usr/local'
  end

To read more about ``ruby-build``, see here: https://github.com/sstephenson/ruby-build.

.. end_tag

**Store certain settings**

.. tag resource_remote_file_store_certain_settings

The following recipe shows how an attributes file can be used to store certain settings. An attributes file is located in the ``attributes/`` directory in the same cookbook as the recipe which calls the attributes file. In this example, the attributes file specifies certain settings for Python that are then used across all nodes against which this recipe will run.

Python packages have versions, installation directories, URLs, and checksum files. An attributes file that exists to support this type of recipe would include settings like the following:

.. code-block:: ruby

   default['python']['version'] = '2.7.1'

   if python['install_method'] == 'package'
     default['python']['prefix_dir'] = '/usr'
   else
     default['python']['prefix_dir'] = '/usr/local'
   end

   default['python']['url'] = 'http://www.python.org/ftp/python'
   default['python']['checksum'] = '80e387...85fd61'

and then the methods in the recipe may refer to these values. A recipe that is used to install Python will need to do the following:

* Identify each package to be installed (implied in this example, not shown)
* Define variables for the package ``version`` and the ``install_path``
* Get the package from a remote location, but only if the package does not already exist on the target system
* Use the **bash** resource to install the package on the node, but only when the package is not already installed

.. code-block:: ruby

   #  the following code sample comes from the ``oc-nginx`` cookbook on |github|: https://github.com/cookbooks/oc-nginx

   version = node['python']['version']
   install_path = "#{node['python']['prefix_dir']}/lib/python#{version.split(/(^\d+\.\d+)/)[1]}"

   remote_file "#{Chef::Config[:file_cache_path]}/Python-#{version}.tar.bz2" do
     source "#{node['python']['url']}/#{version}/Python-#{version}.tar.bz2"
     checksum node['python']['checksum']
     mode '0755'
     not_if { ::File.exist?(install_path) }
   end

   bash 'build-and-install-python' do
     cwd Chef::Config[:file_cache_path]
     code <<-EOF
       tar -jxvf Python-#{version}.tar.bz2
       (cd Python-#{version} && ./configure #{configure_options})
       (cd Python-#{version} && make && make install)
     EOF
     not_if { ::File.exist?(install_path) }
   end

.. end_tag

service
=====================================================
.. tag resource_service_summary

Use the **service** resource to manage a service.

.. end_tag

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

smartos_package
=====================================================
.. tag resource_package_smartos

Use the **smartos_package** resource to manage packages for the SmartOS platform.

.. end_tag

**Install a package**

.. tag resource_smartos_package_install

.. To install a package:

.. code-block:: ruby

   smartos_package 'name of package' do
     action :install
   end

.. end_tag

solaris_package
=====================================================
.. tag resource_package_solaris

The **solaris_package** resource is used to manage packages for the Solaris platform.

.. end_tag

**Install a package**

.. tag resource_solaris_package_install

.. To install a package:

.. code-block:: ruby

   solaris_package 'name of package' do
     action :install
   end

.. end_tag

subversion
=====================================================
.. tag resource_scm_subversion

Use the **subversion** resource to manage source control resources that exist in a Subversion repository.

.. end_tag

**Get the latest version of an application**

.. tag resource_scm_get_latest_version

.. To get the latest version of CouchDB:

.. code-block:: ruby

   subversion 'CouchDB Edge' do
     repository 'http://svn.apache.org/repos/asf/couchdb/trunk'
     revision 'HEAD'
     destination '/opt/mysources/couch'
     action :sync
   end

.. end_tag

template
=====================================================
.. tag resource_template_summary

Use the **template** resource to manage the contents of a file using an Embedded Ruby (ERB) template by transferring files from a sub-directory of ``COOKBOOK_NAME/templates/`` to a specified path located on a host that is running the chef-client. This resource includes actions and properties from the **file** resource. Template files managed by the **template** resource follow the same file specificity rules as the **remote_file** and **file** resources.

.. end_tag

**Configure a file from a template**

.. tag resource_template_configure_file

.. To configure a file from a template:

.. code-block:: ruby

   template '/tmp/config.conf' do
     source 'config.conf.erb'
   end

.. end_tag

**Configure a file from a local template**

.. tag resource_template_configure_file_from_local

.. To configure a file from a local template:

.. code-block:: ruby

   template '/tmp/config.conf' do
     local true
     source '/tmp/config.conf.erb'
   end

.. end_tag

**Configure a file using a variable map**

.. tag resource_template_configure_file_with_variable_map

.. To configure a file from a template with a variable map:

.. code-block:: ruby

   template '/tmp/config.conf' do
     source 'config.conf.erb'
     variables(
       :config_var => node['configs']['config_var']
     )
   end

.. end_tag

**Use the not_if condition**

.. tag resource_template_add_file_not_if_attribute_has_value

The following example shows how to use the ``not_if`` condition to create a file based on a template and using the presence of an attribute value on the node to specify the condition:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     not_if { node[:some_value] }
   end

.. end_tag

.. tag resource_template_add_file_not_if_ruby

The following example shows how to use the ``not_if`` condition to create a file based on a template and then Ruby code to specify the condition:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     not_if do
       File.exist?('/etc/passwd')
     end
   end

.. end_tag

.. tag resource_template_add_file_not_if_ruby_with_curly_braces

The following example shows how to use the ``not_if`` condition to create a file based on a template and using a Ruby block (with curly braces) to specify the condition:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     not_if { File.exist?('/etc/passwd' )}
   end

.. end_tag

.. tag resource_template_add_file_not_if_string

The following example shows how to use the ``not_if`` condition to create a file based on a template and using a string to specify the condition:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     not_if 'test -f /etc/passwd'
   end

.. end_tag

**Use the only_if condition**

.. tag resource_template_add_file_only_if_attribute_has_value

The following example shows how to use the ``only_if`` condition to create a file based on a template and using the presence of an attribute on the node to specify the condition:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     only_if { node[:some_value] }
   end

.. end_tag

.. tag resource_template_add_file_only_if_ruby

The following example shows how to use the ``only_if`` condition to create a file based on a template, and then use Ruby to specify a condition:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     only_if do ! File.exist?('/etc/passwd') end
   end

.. end_tag

.. tag resource_template_add_file_only_if_string

The following example shows how to use the ``only_if`` condition to create a file based on a template and using a string to specify the condition:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     only_if 'test -f /etc/passwd'
   end

.. end_tag

**Use a whitespace array (%w)**

.. tag resource_template_use_whitespace_array

The following example shows how to use a Ruby whitespace array to define a list of configuration tools, and then use that list of tools within the **template** resource to ensure that all of these configuration tools are using the same RSA key:

.. code-block:: ruby

   %w{openssl.cnf pkitool vars Rakefile}.each do |f|
     template "/etc/openvpn/easy-rsa/#{f}" do
       source "#{f}.erb"
       owner 'root'
       group 'root'
       mode '0755'
     end
   end

.. end_tag

**Use a relative path**

.. tag resource_template_use_relative_paths

.. To use a relative path:

.. code-block:: ruby

   template "#{ENV['HOME']}/chef-getting-started.txt" do
     source 'chef-getting-started.txt.erb'
     mode '0755'
   end

.. end_tag

**Delay notifications**

.. tag resource_template_notifies_delay

.. To delay running a notification:

.. code-block:: ruby

   template '/etc/nagios3/configures-nagios.conf' do
     # other parameters
     notifies :run, 'execute[test-nagios-config]', :delayed
   end

.. end_tag

**Notify immediately**

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

**Notify multiple resources**

.. tag resource_template_notifies_multiple_resources

.. To notify multiple resources:

.. code-block:: ruby

   template '/etc/chef/server.rb' do
     source 'server.rb.erb'
     owner 'root'
     group 'root'
     mode '0755'
     notifies :restart, 'service[chef-solr]', :delayed
     notifies :restart, 'service[chef-solr-indexer]', :delayed
     notifies :restart, 'service[chef-server]', :delayed
   end

.. end_tag

**Reload a service**

.. tag resource_template_notifies_reload_service

.. To reload a service:

.. code-block:: ruby

   template '/tmp/somefile' do
     mode '0755'
     source 'somefile.erb'
     notifies :reload, 'service[apache]', :immediately
   end

.. end_tag

**Restart a service when a template is modified**

.. tag resource_template_notifies_restart_service_when_template_modified

.. To restart a resource when a template is modified, use the ``:restart`` attribute for ``notifies``:

.. code-block:: ruby

   template '/etc/www/configures-apache.conf' do
     notifies :restart, 'service[apache]', :immediately
   end

.. end_tag

**Send notifications to multiple resources**

.. tag resource_template_notifies_send_notifications_to_multiple_resources

To send notifications to multiple resources, just use multiple attributes. Multiple attributes will get sent to the notified resources in the order specified.

.. code-block:: ruby

   template '/etc/netatalk/netatalk.conf' do
     notifies :restart, 'service[afpd]', :immediately
     notifies :restart, 'service[cnid]', :immediately
   end

   service 'afpd'
   service 'cnid'

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

**Apply proxy settings consistently across a Chef organization**

.. tag resource_template_consistent_proxy_settings

The following example shows how a template can be used to apply consistent proxy settings for all nodes of the same type:

.. code-block:: ruby

   template "#{node[:matching_node][:dir]}/sites-available/site_proxy.conf" do
     source 'site_proxy.matching_node.conf.erb'
     owner 'root'
     group 'root'
     mode '0755'
     variables(
       :ssl_certificate =>    "#{node[:matching_node][:dir]}/shared/certificates/site_proxy.crt",
       :ssl_key =>            "#{node[:matching_node][:dir]}/shared/certificates/site_proxy.key",
       :listen_port =>        node[:site][:matching_node_proxy][:listen_port],
       :server_name =>        node[:site][:matching_node_proxy][:server_name],
       :fqdn =>               node[:fqdn],
       :server_options =>     node[:site][:matching_node][:server][:options],
       :proxy_options =>      node[:site][:matching_node][:proxy][:options]
     )
   end

where ``matching_node`` represents a type of node (like Nginx) and ``site_proxy`` represents the type of proxy being used for that type of node (like Nexus).

.. end_tag

**Get template settings from a local file**

.. tag resource_template_get_settings_from_local_file

The **template** resource can be used to render a template based on settings contained in a local file on disk or to get the settings from a template in a cookbook. Most of the time, the settings are retrieved from a template in a cookbook. The following example shows how the **template** resource can be used to retrieve these settings from a local file.

The following example is based on a few assumptions:

* The environment is a Ruby on Rails application that needs render a file named ``database.yml``
* Information about the application---the user, their password, the server---is stored in a data bag on the Chef server
* The application is already deployed to the system and that only requirement in this example is to render the ``database.yml`` file

The application source tree looks something like::

   myapp/
   -> config/
      -> database.yml.erb

.. note:: There should not be a file named ``database.yml`` (without the ``.erb``), as the ``database.yml`` file is what will be rendered using the **template** resource.

The deployment of the app will end up in ``/srv``, so the full path to this template would be something like ``/srv/myapp/current/config/database.yml.erb``.

The content of the template itself may look like this:

.. code-block:: ruby

   <%= @rails_env %>:
      adapter: <%= @adapter %>
      host: <%= @host %>
      database: <%= @database %>
      username: <%= @username %>
      password: <%= @password %>
      encoding: 'utf8'
      reconnect: true

The recipe will be similar to the following:

.. code-block:: ruby

   results = search(:node, "role:myapp_database_master AND chef_environment:#{node.chef_environment}")
   db_master = results[0]

   template '/srv/myapp/shared/database.yml' do
     source '/srv/myapp/current/config/database.yml.erb'
     local true
     variables(
       :rails_env => node.chef_environment,
       :adapter => db_master['myapp']['db_adapter'],
       :host => db_master['fqdn'],
       :database => "myapp_#{node.chef_environment}",
       :username => "myapp",
       :password => "SUPERSECRET",
     )
   end

where:

* the ``search`` method in the Recipe DSL is used to find the first node that is the database master (of which there should only be one)
* the ``:adapter`` variable property may also require an attribute to have been set on a role, which then determines the correct adapter

The template will render similar to the following:

.. code-block:: ruby

   production:
     adapter: mysql
     host: domU-12-31-39-14-F1-C3.compute-1.internal
     database: myapp_production
     username: myapp
     password: SUPERSECRET
     encoding: utf8
     reconnect: true

This example showed how to use the **template** resource to render a template based on settings contained in a local file. Some other issues that should be considered when using this type of approach include:

* Should the ``database.yml`` file be in a ``.gitignore`` file?
* How do developers run the application locally?
* Does this work with chef-solo?

.. end_tag

**Pass values from recipe to template**

.. tag resource_template_pass_values_to_template_from_recipe

The following example shows how pass a value to a template using the ``variables`` property in the **template** resource. The template file is similar to:

.. code-block:: ruby

   [tcpout]
   defaultGroup = splunk_indexers_<%= node['splunk']['receiver_port'] %>
   disabled=false

   [tcpout:splunk_indexers_<%= node['splunk']['receiver_port'] %>]
   server=<% @splunk_servers.map do |s| -%><%= s['ipaddress'] %>:<%= s['splunk']['receiver_port'] %> <% end.join(', ') -%>
   <% @outputs_conf.each_pair do |name, value| -%>
   <%= name %> = <%= value %>
   <% end -%>

The recipe then uses the ``variables`` attribute to find the values for ``splunk_servers`` and ``outputs_conf``, before passing them into the template:

.. code-block:: ruby

   template "#{splunk_dir}/etc/system/local/outputs.conf" do
     source 'outputs.conf.erb'
     mode '0755'
     variables :splunk_servers => splunk_servers, :outputs_conf => node['splunk']['outputs_conf']
     notifies :restart, 'service[splunk]'
   end

This example can be found in the ``client.rb`` recipe and the ``outputs.conf.erb`` template files that are located in the `chef-splunk cookbook <https://github.com/chef-cookbooks/chef-splunk/>`_  that is maintained by Chef.

.. end_tag

user
=====================================================
.. tag resource_user_summary

Use the **user** resource to add users, update existing users, remove users, and to lock/unlock user passwords.

.. note:: System attributes are collected by Ohai at the start of every chef-client run. By design, the actions available to the **user** resource are processed **after** the start of the chef-client run. This means that system attributes added or modified by the **user** resource during the chef-client run must be reloaded before they can be available to the chef-client. These system attributes can be reloaded in two ways: by picking up the values at the start of the (next) chef-client run or by using the :doc:`ohai resource </resource_ohai>` to reload the system attributes during the current chef-client run.

.. end_tag

**Create a user named "random"**

.. tag resource_user_create_random

.. To create a user named "random":

.. code-block:: ruby

   user 'random' do
     manage_home true
     comment 'User Random'
     uid '1234'
     gid '1234'
     home '/home/random'
     shell '/bin/bash'
     password '$1$JJsvHslV$szsCjVEroftprNn4JHtDi'
   end

.. end_tag

**Create a system user**

.. tag resource_user_create_system

.. To create a system user:

.. code-block:: ruby

   user 'systemguy' do
     comment 'system guy'
     system true
     shell '/bin/false'
   end

.. end_tag

**Create a system user with a variable**

.. tag resource_user_create_system_user_with_variable

The following example shows how to create a system user. In this instance, the ``home`` value is calculated and stored in a variable called ``user_home`` which sets the user's ``home`` attribute.

.. code-block:: ruby

   user_home = "/home/#{node['cookbook_name']['user']}"

   user node['cookbook_name']['user'] do
     gid node['cookbook_name']['group']
     shell '/bin/bash'
     home user_home
     system true
     action :create
   end

.. end_tag

**Use SALTED-SHA512 passwords**

.. tag resource_user_password_shadow_hash_salted_sha512

macOS 10.7 calculates the password shadow hash using SALTED-SHA512. The length of the shadow hash value is 68 bytes, the salt value is the first 4 bytes, with the remaining 64 being the shadow hash itself. The following code will calculate password shadow hashes for macOS 10.7:

.. code-block:: ruby

   password = 'my_awesome_password'
   salt = OpenSSL::Random.random_bytes(4)
   encoded_password = OpenSSL::Digest::SHA512.hexdigest(salt + password)
   shadow_hash = salt.unpack('H*').first + encoded_password

Use the calculated password shadow hash with the **user** resource:

.. code-block:: ruby

   user 'my_awesome_user' do
     password 'c9b3bd....d843'  # Length: 136
   end

.. end_tag

New in Chef Client 12.0.

**Use SALTED-SHA512-PBKDF2 passwords**

.. tag resource_user_password_shadow_hash_salted_sha512_pbkdf2

macOS 10.8 (and higher) calculates the password shadow hash using SALTED-SHA512-PBKDF2. The length of the shadow hash value is 128 bytes, the salt value is 32 bytes, and an integer specifies the number of iterations. The following code will calculate password shadow hashes for macOS 10.8 (and higher):

.. code-block:: ruby

   password = 'my_awesome_password'
   salt = OpenSSL::Random.random_bytes(32)
   iterations = 25000 # Any value above 20k should be fine.

   shadow_hash = OpenSSL::PKCS5::pbkdf2_hmac(
     password,
     salt,
     iterations,
     128,
     OpenSSL::Digest::SHA512.new
   ).unpack('H*').first
   salt_value = salt.unpack('H*').first

Use the calculated password shadow hash with the **user** resource:

.. code-block:: ruby

   user 'my_awesome_user' do
     password 'cbd1a....fc843'  # Length: 256
     salt 'bd1a....fc83'        # Length: 64
     iterations 25000
   end

.. end_tag

New in Chef Client 12.0.

windows_package
=====================================================
.. tag resource_package_windows

Use the **windows_package** resource to manage Microsoft Installer Package (MSI) packages for the Microsoft Windows platform.

.. end_tag

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
=====================================================
.. tag resource_service_windows

Use the **windows_service** resource to manage a service on the Microsoft Windows platform. New in Chef Client 12.0.

.. end_tag

**Start a service manually**

.. tag resource_service_windows_manual_start

.. To install a package:

.. code-block:: ruby

   windows_service 'BITS' do
     action :configure_startup
     startup_type :manual
   end

.. end_tag

yum_package
=====================================================
.. tag resource_package_yum

Use the **yum_package** resource to install, upgrade, and remove packages with Yum for the Red Hat and CentOS platforms. The **yum_package** resource is able to resolve ``provides`` data for packages much like Yum can do when it is run from the command line. This allows a variety of options for installing packages, like minimum versions, virtual provides, and library names.

.. end_tag

**Install an exact version**

.. tag resource_yum_package_install_exact_version

.. To install an exact version:

.. code-block:: ruby

   yum_package 'netpbm = 10.35.58-8.el5'

.. end_tag

**Install a minimum version**

.. tag resource_yum_package_install_minimum_version

.. To install a minimum version:

.. code-block:: ruby

   yum_package 'netpbm >= 10.35.58-8.el5'

.. end_tag

**Install a minimum version using the default action**

.. tag resource_yum_package_install_package_using_default_action

.. To install the same package using the default action:

.. code-block:: ruby

   yum_package 'netpbm'

.. end_tag

**To install a package**

.. tag resource_yum_package_install_package

.. To install a package:

.. code-block:: ruby

   yum_package 'netpbm' do
     action :install
   end

.. end_tag

**To install a partial minimum version**

.. tag resource_yum_package_install_partial_minimum_version

.. To install a partial minimum version:

.. code-block:: ruby

   yum_package 'netpbm >= 10'

.. end_tag

**To install a specific architecture**

.. tag resource_yum_package_install_specific_architecture

.. To install a specific architecture:

.. code-block:: ruby

   yum_package 'netpbm' do
     arch 'i386'
   end

or:

.. code-block:: ruby

   yum_package 'netpbm.x86_64'

.. end_tag

**To install a specific version-release**

.. tag resource_yum_package_install_specific_version_release

.. To install a specific version-release:

.. code-block:: ruby

   yum_package 'netpbm' do
     version '10.35.58-8.el5'
   end

.. end_tag

**To install a specific version (even when older than the current)**

.. tag resource_yum_package_install_specific_version

.. To install a specific version (even if it is older than the version currently installed):

.. code-block:: ruby

   yum_package 'tzdata' do
     version '2011b-1.el5'
     allow_downgrade true
   end

.. end_tag

**Handle cookbook_file and yum_package resources in the same recipe**

.. tag resource_yum_package_handle_cookbook_file_and_yum_package

.. To handle cookbook_file and yum_package when both called in the same recipe

When a **cookbook_file** resource and a **yum_package** resource are both called from within the same recipe, use the ``flush_cache`` attribute to dump the in-memory Yum cache, and then use the repository immediately to ensure that the correct package is installed:

.. code-block:: ruby

   cookbook_file '/etc/yum.repos.d/custom.repo' do
     source 'custom'
     mode '0755'
   end

   yum_package 'only-in-custom-repo' do
     action :install
     flush_cache [ :before ]
   end

.. end_tag
