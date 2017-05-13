*****************************************************
Resources Reference
*****************************************************
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resources.rst>`__

.. tag resources_common

A resource is a statement of configuration policy that:

* Describes the desired state for a configuration item
* Declares the steps needed to bring that item to the desired state
* Specifies a resource type---such as ``package``, ``template``, or ``service``
* Lists additional details (also known as resource properties), as necessary
* Are grouped into recipes, which describe working configurations

.. end_tag

.. tag resources_common_provider

Where a resource represents a piece of the system (and its desired state), a provider defines the steps that are needed to bring that piece of the system from its current state into the desired state.

.. end_tag

.. tag resources_common_provider_platform

The ``Chef::Platform`` class maps providers to platforms (and platform versions). At the beginning of every chef-client run, Ohai verifies the ``platform`` and ``platform_version`` attributes on each node. The chef-client then uses those values to identify the correct provider, build an instance of that provider, identify the current state of the resource, do the specified action, and then mark the resource as updated (if changes were made).

For example:

.. code-block:: ruby

   directory '/tmp/folder' do
     owner 'root'
     group 'root'
     mode '0755'
     action :create
   end

The chef-client will look up the provider for the ``directory`` resource, which happens to be ``Chef::Provider::Directory``, call ``load_current_resource`` to create a ``directory["/tmp/folder"]`` resource, and then, based on the current state of the directory, do the specified action, which in this case is to create a directory called ``/tmp/folder``. If the directory already exists, nothing will happen. If the directory was changed in any way, the resource is marked as updated.

.. end_tag

This reference describes each of the resources available to the chef-client, including a list of actions, a list of properties, (when applicable) a list of providers, and examples of using each resource.

=====================================================
Common Functionality
=====================================================
The properties and actions in this section apply to all resources.

Actions
=====================================================
.. tag resources_common_actions

The following actions may be used with any resource:

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

.. end_tag

Examples
-----------------------------------------------------
The following examples show how to use common actions in a recipe.

**Use the :nothing action**

.. tag resource_service_use_nothing_action

.. To use the ``:nothing`` common action in a recipe:

.. code-block:: ruby

   service 'memcached' do
     action :nothing
     supports :status => true, :start => true, :stop => true, :restart => true
   end

.. end_tag

Properties
=====================================================
.. tag resources_common_attributes

The following properties are common to every resource:

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``provider``
   **Ruby Type:** Chef Class

   Optional. The chef-client will attempt to determine the correct provider during the chef-client run, and then choose the best/correct provider based on configuration data collected at the start of the chef-client run. In general, a provider does not need to be specified.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``sensitive``
   **Ruby Types:** TrueClass, FalseClass

   Ensure that sensitive resource data is not logged by the chef-client. Default value: ``false``. This property only applies to the **execute**, **file** and **template** resources.

``supports``
   **Ruby Type:** Hash

   A hash of options that contains hints about the capabilities of a resource. The chef-client may use these hints to help identify the correct provider. This property is only used by a small number of providers, including **user** and **service**.

.. end_tag

Provider
-----------------------------------------------------
.. tag resources_common_provider_attributes

The chef-client will determine the correct provider based on configuration data collected by Ohai at the start of the chef-client run. This configuration data is then mapped to a platform and an associated list of providers.

Generally, it's best to let the chef-client choose the provider, and this is (by far) the most common approach. However, in some cases, specifying a provider may be desirable. There are two approaches:

* Use a more specific short name---``yum_package "foo" do`` instead of ``package "foo" do``, ``script "foo" do`` instead of ``bash "foo" do``, and so on---when available
* Use the ``provider`` property within the resource block to specify the long name of the provider as a property of a resource. For example: ``provider Chef::Provider::Long::Name``

.. end_tag

Examples
-----------------------------------------------------
The following examples show how to use common properties in a recipe.

**Use the ignore_failure common property**

.. tag resource_package_use_ignore_failure_attribute

.. To use the ``ignore_failure`` common attribute in a recipe:

.. code-block:: ruby

   gem_package 'syntax' do
     action :install
     ignore_failure true
   end

.. end_tag

**Use the provider common property**

.. tag resource_package_use_provider_attribute

.. To use the ``:provider`` common attribute in a recipe:

.. code-block:: ruby

   package 'some_package' do
     provider Chef::Provider::Package::Rubygems
   end

.. end_tag

**Use the supports common property**

.. tag resource_service_use_supports_attribute

.. To use the ``supports`` common attribute in a recipe:

.. code-block:: ruby

   service 'apache' do
     supports :restart => true, :reload => true
     action :enable
   end

.. end_tag

**Use the supports and providers common properties**

.. tag resource_service_use_provider_and_supports_attributes

.. To use the ``provider`` and ``supports`` common attributes in a recipe:

.. code-block:: ruby

   service 'some_service' do
     provider Chef::Provider::Service::Upstart
     supports :status => true, :restart => true, :reload => true
     action [ :enable, :start ]
   end

.. end_tag

Guards
=====================================================
.. tag resources_common_guards

A guard property can be used to evaluate the state of a node during the execution phase of the chef-client run. Based on the results of this evaluation, a guard property is then used to tell the chef-client if it should continue executing a resource. A guard property accepts either a string value or a Ruby block value:

* A string is executed as a shell command. If the command returns ``0``, the guard is applied. If the command returns any other value, then the guard property is not applied. String guards in a **powershell_script** run Windows PowerShell commands and may return ``true`` in addition to ``0``.
* A block is executed as Ruby code that must return either ``true`` or ``false``. If the block returns ``true``, the guard property is applied. If the block returns ``false``, the guard property is not applied.

A guard property is useful for ensuring that a resource is idempotent by allowing that resource to test for the desired state as it is being executed, and then if the desired state is present, for the chef-client to do nothing.

.. end_tag

Attributes
-----------------------------------------------------
.. tag resources_common_guards_attributes

The following properties can be used to define a guard that is evaluated during the execution phase of the chef-client run:

``not_if``
   Prevent a resource from executing when the condition returns ``true``.

``only_if``
   Allow a resource to execute only if the condition returns ``true``.

.. end_tag

Arguments
-----------------------------------------------------
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

not_if Examples
-----------------------------------------------------
The following examples show how to use ``not_if`` as a condition in a recipe:

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

only_if Examples
-----------------------------------------------------
The following examples show how to use ``only_if`` as a condition in a recipe:

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

Guard Interpreters
=====================================================
.. tag resources_common_guard_interpreter

Any resource that passes a string command may also specify the interpreter that will be used to evaluate that string command. This is done by using the ``guard_interpreter`` property to specify a **script**-based resource.

.. end_tag

Changed in Chef Client 12.0 to default to the specified property.

Attributes
-----------------------------------------------------
.. tag resources_common_guard_interpreter_attributes

The ``guard_interpreter`` property may be set to any of the following values:

``:bash``
   Evaluates a string command using the **bash** resource.

``:batch``
   Evaluates a string command using the **batch** resource. Default value (within a **batch** resource block): ``:batch``.

``:csh``
   Evaluates a string command using the **csh** resource.

``:default``
   Default. Executes the default interpreter as identified by the chef-client.

``:perl``
   Evaluates a string command using the **perl** resource.

``:powershell_script``
   Evaluates a string command using the **powershell_script** resource. Default value (within a **batch** resource block): ``:powershell_script``.

``:python``
   Evaluates a string command using the **python** resource.

``:ruby``
   Evaluates a string command using the **ruby** resource.

.. end_tag

Inheritance
-----------------------------------------------------
.. tag resources_common_guard_interpreter_attributes_inherit

The ``guard_interpreter`` property is set to ``:default`` by default for the **bash**, **csh**, **perl**, **python**, and **ruby** resources. When the ``guard_interpreter`` property is set to ``:default``, ``not_if`` or ``only_if`` guard statements **do not inherit** properties that are defined by the **script**-based resource.

.. warning:: The **batch** and **powershell_script** resources inherit properties by default. The ``guard_interpreter`` property is set to ``:batch`` or ``:powershell_script`` automatically when using a ``not_if`` or ``only_if`` guard statement within a **batch** or **powershell_script** resource, respectively.

For example, the ``not_if`` guard statement in the following resource example **does not inherit** the ``environment`` property:

.. code-block:: ruby

   bash 'javatooling' do
     environment 'JAVA_HOME' => '/usr/lib/java/jdk1.7/home'
     code 'java-based-daemon-ctl.sh -start'
     not_if 'java-based-daemon-ctl.sh -test-started'
   end

and requires adding the ``environment`` property to the ``not_if`` guard statement so that it may use the ``JAVA_HOME`` path as part of its evaluation:

.. code-block:: ruby

   bash 'javatooling' do
     environment 'JAVA_HOME' => '/usr/lib/java/jdk1.7/home'
     code 'java-based-daemon-ctl.sh -start'
     not_if 'java-based-daemon-ctl.sh -test-started', :environment => 'JAVA_HOME' => '/usr/lib/java/jdk1.7/home'
   end

To inherit properties, add the ``guard_interpreter`` property to the resource block and set it to the appropriate value:

* ``:bash`` for **bash**
* ``:csh`` for **csh**
* ``:perl`` for **perl**
* ``:python`` for **python**
* ``:ruby`` for **ruby**

For example, using the same example as from above, but this time adding the ``guard_interpreter`` property and setting it to ``:bash``:

.. code-block:: ruby

   bash 'javatooling' do
     guard_interpreter :bash
     environment 'JAVA_HOME' => '/usr/lib/java/jdk1.7/home'
     code 'java-based-daemon-ctl.sh -start'
     not_if 'java-based-daemon-ctl.sh -test-started'
   end

The ``not_if`` statement now inherits the ``environment`` property and will use the ``JAVA_HOME`` path as part of its evaluation.

.. end_tag

Examples
-----------------------------------------------------
.. tag resources_common_guard_interpreter_example_default

For example, the following code block will ensure the command is evaluated using the default intepreter as identified by the chef-client:

.. code-block:: ruby

   resource 'name' do
     guard_interpreter :default
     # code
   end

.. end_tag

Lazy Evaluation
=====================================================
.. tag resources_common_lazy_evaluation

In some cases, the value for a property cannot be known until the execution phase of a chef-client run. In this situation, using lazy evaluation of property values can be helpful. Instead of a property being assigned a value, it may instead be assigned a code block. The syntax for using lazy evaluation is as follows:

.. code-block:: ruby

   attribute_name lazy { code_block }

where ``lazy`` is used to tell the chef-client to evaluate the contents of the code block later on in the resource evaluation process (instead of immediately) and ``{ code_block }`` is arbitrary Ruby code that provides the value.

For example, a resource that is **not** doing lazy evaluation:

.. code-block:: ruby

   template 'template_name' do
     # some attributes
     path '/foo/bar'
   end

and a resource block that is doing lazy evaluation:

.. code-block:: ruby

   template 'template_name' do
     # some attributes
     path lazy { ' some Ruby code ' }
   end

In the previous examples, the first resource uses the value ``/foo/bar`` and the second resource uses the value provided by the code block, as long as the contents of that code block are a valid resource property.

The following example shows how to use lazy evaluation with template variables:

.. code-block:: ruby

   template '/tmp/canvey_island.txt' do
     source 'canvey_island.txt.erb'
     variables(
       { :canvey_island => lazy { node.run_state['sea_power'] } }
     )
   end

.. end_tag

Notifications
=====================================================
.. tag resources_common_notification

A notification is a property on a resource that listens to other resources in the resource collection and then takes actions based on the notification type (``notifies`` or ``subscribes``).

.. end_tag

Timers
-----------------------------------------------------
.. tag resources_common_notification_timers

A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

``:before``
   Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

``:delayed``
   Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

``:immediate``, ``:immediately``
   Specifies that a notification should be run immediately, per resource notified.

.. end_tag

Notifies
-----------------------------------------------------
.. tag resources_common_notification_notifies

A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

.. end_tag

.. tag resources_common_notification_notifies_syntax

The syntax for ``notifies`` is:

.. code-block:: ruby

   notifies :action, 'resource[name]', :timer

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following examples show how to use the ``notifies`` notification in a recipe.

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

Subscribes
-----------------------------------------------------
.. tag resources_common_notification_subscribes

A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

.. end_tag

.. tag resources_common_notification_subscribes_syntax

The syntax for ``subscribes`` is:

.. code-block:: ruby

   subscribes :action, 'resource[name]', :timer

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following examples show how to use the ``subscribes`` notification in a recipe.

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

Relative Paths
=====================================================
.. tag resources_common_relative_paths

The following relative paths can be used with any resource:

``#{ENV['HOME']}``
   Use to return the ``~`` path in Linux and macOS or the ``%HOMEPATH%`` in Microsoft Windows.

.. end_tag

Examples
-----------------------------------------------------
.. tag resource_template_use_relative_paths

.. To use a relative path:

.. code-block:: ruby

   template "#{ENV['HOME']}/chef-getting-started.txt" do
     source 'chef-getting-started.txt.erb'
     mode '0755'
   end

.. end_tag

Run in Compile Phase
=====================================================
.. tag resources_common_compile

The chef-client processes recipes in two phases:

#. First, each resource in the node object is identified and a resource collection is built. All recipes are loaded in a specific order, and then the actions specified within each of them are identified. This is also referred to as the "compile phase".
#. Next, the chef-client configures the system based on the order of the resources in the resource collection. Each resource is mapped to a provider, which then examines the node and performs the necessary steps to complete the action. This is also referred to as the "execution phase".

Typically, actions are processed during the execution phase of the chef-client run. However, sometimes it is necessary to run an action during the compile phase. For example, a resource can be configured to install a package during the compile phase to ensure that application is available to other resources during the execution phase.

.. note:: Use the **chef_gem** resource to install gems that are needed by the chef-client during the execution phase.

.. end_tag

run_action
-----------------------------------------------------
.. tag resources_common_compile_begin

Use ``.run_action(:some_action)`` at the end of a resource block to run the specified action during the compile phase. For example:

.. code-block:: ruby

   resource_name 'foo' do
     action :nothing
   end.run_action(:some_action)

where ``action`` is set to ``:nothing`` to ensure the ``run_action`` is run during the compile phase and not later during the execution phase.

The following examples show when (and when not) to use ``run_action``.

**Update a package cache**

Sometimes it is necessary to ensure that an operating system's package cache is up to date before installing packages. For example, on Debian or Ubuntu systems, the Apt cache should be updated:

.. code-block:: ruby

   if node['apt']['compile_time_update'] && ( !::File.exist?('/var/lib/apt/periodic/update-success-stamp') || !::File.exist?(first_run_file) )
     e = bash 'apt-get-update at compile time' do
       code <<-EOH
         apt-get update
         touch #{first_run_file}
       EOH
       ignore_failure true
       only_if { apt_installed? }
       action :nothing
     end
     e.run_action(:run)
   end

where ``e.run_action(:run)`` tells the chef-client to run the ``apt-get update`` command during the compile phase. This example can be found in the ``default.rb`` recipe of the `apt cookbook <https://github.com/chef-cookbooks/apt>`_ that is maintained by Chef.

**Use the chef_gem resource for Ruby gems**

A very common use case us to install a gem during the compile phase so that it will be available to the chef-client during the execution phase. This is why the **chef_gem** resource exists. For example, this:

.. code-block:: ruby

   chef_gem 'foo' do
     action :install
   end

is effectively the same as

.. code-block:: ruby

   gem_package 'foo' do
     action :nothing
   end.run_action(:install)
   Gem.clear_paths

but without needing to define a ``run_action``.

**Notifications will not work**

Resources that are executed during the compile phase cannot notify other resources. For example:

.. code-block:: ruby

   execute 'ifconfig'

   p = package 'vim-enhanced' do
     action :nothing
     notifies :run, 'execute[ifconfig]', :immediately
   end
   p.run_action(:install)

A better approach in this type of situation is to install the package before the resource collection is built to ensure that it is available to other resources later on.

.. end_tag

Atomic File Updates
=====================================================
.. tag resources_common_atomic_update

Atomic updates are used with **file**-based resources to help ensure that file updates can be made when updating a binary or if disk space runs out.

Atomic updates are enabled by default. They can be managed globally using the ``file_atomic_update`` setting in the client.rb file. They can be managed on a per-resource basis using the ``atomic_update`` property that is available with the **cookbook_file**, **file**, **remote_file**, and **template** resources.

.. note:: On certain platforms, and after a file has been moved into place, the chef-client may modify file permissions to support features specific to those platforms. On platforms with SELinux enabled, the chef-client will fix up the security contexts after a file has been moved into the correct location by running the ``restorecon`` command. On the Microsoft Windows platform, the chef-client will create files so that ACL inheritance works as expected.

.. end_tag

Windows File Security
=====================================================
.. tag resources_common_windows_security

To support Microsoft Windows security, the **template**, **file**, **remote_file**, **cookbook_file**, **directory**, and **remote_directory** resources support the use of inheritance and access control lists (ACLs) within recipes.

.. end_tag

**Access Control Lists (ACLs)**

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

**Inheritance**

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

=====================================================
Resources
=====================================================
The following resources are built-in to the chef-client:

* apt_package (based on the package resource)
* apt_repository
* apt_update
* bash
* batch
* bff_package (based on the package resource)
* breakpoint
* chef_gem (based on the package resource)
* chef_handler (available from the chef_handler cookbook)
* chocolatey_package (based on the package resource)
* cookbook_file
* cron
* csh
* deploy (including git and Subversion)
* directory
* dpkg_package (based on the package resource)
* dsc_resource
* dsc_script
* env
* erl_call
* execute
* file
* freebsd_package (based on the package resource)
* gem_package (based on the package resource)
* git
* group
* homebrew_package (based on the package resource)
* http_request
* ifconfig
* ips_package (based on the package resource)
* ksh
* link
* log
* macports_package (based on the package resource)
* mdadm
* mount
* ohai
* openbsd_package (based on the package resource)
* osx_profile
* package
* pacman_package (based on the package resource)
* paludis_package (based on the package resource)
* perl
* portage_package (based on the package resource)
* powershell_script
* python
* reboot
* registry_key
* remote_directory
* remote_file
* route
* rpm_package (based on the package resource)
* ruby
* ruby_block
* script
* service
* smartos_package (based on the package resource)
* solaris_package (based on the package resource)
* subversion
* template
* user
* windows_package
* windows_service
* yum (based on the package resource)
* yum_repository
* zypper (based on the package resource)

See below for more information about each of these resources, their related actions and properties, and examples of how these resources can be used in recipes.

.. include:: resource_apt_package.rst

.. include:: resource_apt_repository.rst

.. include:: resource_apt_update.rst

.. include:: resource_bash.rst

.. include:: resource_batch.rst

.. include:: resource_bff_package.rst

.. include:: resource_breakpoint.rst

.. include:: resource_chef_gem.rst

.. include:: resource_chef_handler.rst

.. include:: resource_chocolatey_package.rst

.. include:: resource_cookbook_file.rst

.. include:: resource_cron.rst

.. include:: resource_csh.rst

.. include:: resource_deploy.rst

.. include:: resource_directory.rst

.. include:: resource_dpkg_package.rst

.. include:: resource_dsc_resource.rst

.. include:: resource_dsc_script.rst

.. include:: resource_env.rst

.. include:: resource_erlang_call.rst

.. include:: resource_execute.rst

.. include:: resource_file.rst

.. include:: resource_freebsd_package.rst

.. include:: resource_gem_package.rst

.. include:: resource_git.rst

.. include:: resource_group.rst

.. include:: resource_homebrew_package.rst

.. include:: resource_http_request.rst

.. include:: resource_ifconfig.rst

.. include:: resource_ips_package.rst

.. include:: resource_link.rst

.. include:: resource_log.rst

.. include:: resource_macports_package.rst

.. include:: resource_mdadm.rst

.. include:: resource_mount.rst

.. include:: resource_ohai.rst

.. include:: resource_openbsd_package.rst

.. include:: resource_osx_profile.rst

.. include:: resource_package.rst

.. include:: resource_pacman_package.rst

.. include:: resource_paludis_package.rst

.. include:: resource_perl.rst

.. include:: resource_portage_package.rst

.. include:: resource_powershell_script.rst

.. include:: resource_python.rst

.. include:: resource_reboot.rst

.. include:: resource_registry_key.rst

.. include:: resource_remote_directory.rst

.. include:: resource_remote_file.rst

.. include:: resource_route.rst

.. include:: resource_rpm_package.rst

.. include:: resource_ruby.rst

.. include:: resource_ruby_block.rst

.. include:: resource_script.rst

.. include:: resource_service.rst

.. include:: resource_smartos_package.rst

.. include:: resource_solaris_package.rst

.. include:: resource_subversion.rst

.. include:: resource_systemd_unit.rst

.. include:: resource_template.rst

.. include:: resource_user.rst

.. include:: resource_windows_package.rst

.. include:: resource_windows_service.rst

.. include:: resource_yum.rst

.. include:: resource_yum_repository.rst

.. include:: resource_zypper_package.rst
