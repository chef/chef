=====================================================
chef_handler
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_chef_handler.rst>`__

.. tag resource_chef_handler_summary

Use the **chef_handler** resource to enable handlers during a chef-client run. The resource allows arguments to be passed to the chef-client, which then applies the conditions defined by the custom handler to the node attribute data collected during the chef-client run, and then processes the handler based on that data.

The **chef_handler** resource is typically defined early in a node's run-list (often being the first item). This ensures that all of the handlers will be available for the entire chef-client run.

The **chef_handler** resource `is included with the chef_handler cookbook <https://github.com/chef-cookbooks/chef_handler>`__. This cookbook defines the the resource itself and also provides the location in which the chef-client looks for custom handlers. All custom handlers should be added to the ``files/default/handlers`` directory in the **chef_handler** cookbook.

.. end_tag

Handler Types
=====================================================
.. tag handler_types

There are three types of handlers:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Handler
     - Description
   * - exception
     - An exception handler is used to identify situations that have caused a chef-client run to fail. An exception handler can be loaded at the start of a chef-client run by adding a recipe that contains the **chef_handler** resource to a node's run-list. An exception handler runs when the ``failed?`` property for the ``run_status`` object returns ``true``.
   * - report
     - A report handler is used when a chef-client run succeeds and reports back on certain details about that chef-client run. A report handler can be loaded at the start of a chef-client run by adding a recipe that contains the **chef_handler** resource to a node's run-list. A report handler runs when the ``success?`` property for the ``run_status`` object returns ``true``.
   * - start
     - A start handler is used to run events at the beginning of the chef-client run. A start handler can be loaded at the start of a chef-client run by adding the start handler to the ``start_handlers`` setting in the client.rb file or by installing the gem that contains the start handler by using the **chef_gem** resource in a recipe in the **chef-client** cookbook. (A start handler may not be loaded using the ``chef_handler`` resource.)

.. end_tag

Exception / Report
-----------------------------------------------------
.. tag handler_type_exception_report

Exception and report handlers are used to trigger certain behaviors in response to specific situations, typically identified during a chef-client run.

* An exception handler is used to trigger behaviors when a defined aspect of a chef-client run fails.
* A report handler is used to trigger behaviors when a defined aspect of a chef-client run is successful.

Both types of handlers can be used to gather data about a chef-client run and can provide rich levels of data about all types of usage, which can be used later for trending and analysis across the entire organization.

Exception and report handlers are made available to the chef-client run in one of the following ways:

* By adding the **chef_handler** resource to a recipe, and then adding that recipe to the run-list for a node. (The **chef_handler** resource is available from the **chef_handler** cookbook.)
* By adding the handler to one of the following settings in the node's client.rb file: ``exception_handlers`` and/or ``report_handlers``

.. end_tag

.. tag handler_type_exception_report_run_from_recipe

The **chef_handler** resource allows exception and report handlers to be enabled from within recipes, which can then added to the run-list for any node on which the exception or report handler should run. The **chef_handler** resource is available from the **chef_handler** cookbook.

To use the **chef_handler** resource in a recipe, add code similar to the following:

.. code-block:: ruby

   chef_handler 'name_of_handler' do
     source '/path/to/handler/handler_name'
     action :enable
   end

For example, a handler for Growl needs to be enabled at the beginning of the chef-client run:

.. code-block:: ruby

   chef_gem 'chef-handler-growl'

and then is activated in a recipe by using the **chef_handler** resource:

.. code-block:: ruby

   chef_handler 'Chef::Handler::Growl' do
     source 'chef/handler/growl'
     action :enable
   end

.. end_tag

Start
-----------------------------------------------------
.. tag handler_type_start

A start handler is not loaded into the chef-client run from a recipe, but is instead listed in the client.rb file using the ``start_handlers`` attribute. The start handler must be installed on the node and be available to the chef-client prior to the start of the chef-client run. Use the **chef-client** cookbook to install the start handler.

Start handlers are made available to the chef-client run in one of the following ways:

* By adding a start handler to the **chef-client** cookbook, which installs the handler on the node so that it is available to the chef-client at the start of the chef-client run
* By adding the handler to one of the following settings in the node's client.rb file: ``start_handlers``

.. end_tag

.. tag handler_type_start_run_from_recipe

The **chef-client** cookbook can be configured to automatically install and configure gems that are required by a start handler. For example:

.. code-block:: ruby

   node.set['chef_client']['load_gems']['chef-reporting'] = {
     :require_name => 'chef_reporting',
     :action => :install
   }

   node.set['chef_client']['config']['start_handlers'] = [
     {
       :class => 'Chef::Reporting::StartHandler',
       :arguments => []
     }
   ]

   include_recipe 'chef-client::config'

.. end_tag

Syntax
=====================================================
A **chef_handler** resource block enables handlers during a chef-client run. Two handlers---``JsonFile`` and ``ErrorReport``---are built into Chef:

.. code-block:: ruby

   chef_handler 'Chef::Handler::JsonFile' do
     source 'chef/handler/json_file'
     arguments :path => '/var/chef/reports'
     action :enable
   end

and:

.. code-block:: ruby

   chef_handler 'Chef::Handler::ErrorReport' do
     source 'chef/handler/error_report'
     action :enable
   end

show how to enable those handlers in a recipe.

The full syntax for all of the properties that are available to the **chef_handler** resource is:

.. code-block:: ruby

   chef_handler 'name' do
     arguments                  Array
     class_name                 String
     notifies                   # see description
     source                     String
     subscribes                 # see description
     supports                   Hash
     action                     Symbol
   end

where

* ``chef_handler`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``arguments``, ``class_name``, ``source``, and ``supports`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

``:disable``
   Disable the handler for the current chef-client run on the current node.

``:enable``
   Enable the handler for the current chef-client run on the current node.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

Properties
=====================================================
This resource has the following properties:

``arguments``
   **Ruby Type:** Array

   An array of arguments that are passed to the initializer for the handler class. Default value: ``[]``. For example:

   .. code-block:: ruby

      arguments :key1 => 'val1'

   or:

   .. code-block:: ruby

      arguments [:key1 => 'val1', :key2 => 'val2']

``class_name``
   **Ruby Type:** String

   The name of the handler class. This can be module name-spaced.

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

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``source``
   **Ruby Type:** String

   The full path to the handler file or the path to a gem (if the handler ships as part of a Ruby gem).

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

   The type of handler. Possible values: ``:exception``, ``:report``, or ``:start``. Default value: ``{ :report => true, :exception => true }``.

Custom Handlers
=====================================================
.. tag handler_custom

A custom handler can be created to support any situation. The easiest way to build a custom handler:

#. Download the **chef_handler** cookbook
#. Create a custom handler
#. Write a recipe using the **chef_handler** resource
#. Add that recipe to a node's run-list, often as the first recipe in that run-list

.. end_tag

Syntax
-----------------------------------------------------
.. tag handler_custom_syntax

The syntax for a handler can vary, depending on what the the situations the handler is being asked to track, the type of handler being used, and so on. All custom exception and report handlers are defined using Ruby and must be a subclass of the ``Chef::Handler`` class.

.. code-block:: ruby

   require 'chef/log'

   module ModuleName
     class HandlerName < Chef::Handler
       def report
         # Ruby code goes here
       end
     end
   end

where:

* ``require`` ensures that the logging functionality of the chef-client is available to the handler
* ``ModuleName`` is the name of the module as it exists within the ``Chef`` library
* ``HandlerName`` is the name of the handler as it is used in a recipe
* ``report`` is an interface that is used to define the custom handler

For example, the following shows a custom handler that sends an email that contains the exception data when a chef-client run fails:

.. code-block:: ruby

   require 'net/smtp'

   module OrgName
     class SendEmail < Chef::Handler
       def report
         if run_status.failed? then
           message  = "From: sender_name <sender@example.com>\n"
           message << "To: recipient_address <recipient@example.com>\n"
           message << "Subject: chef-client Run Failed\n"
           message << "Date: #{Time.now.rfc2822}\n\n"
           message << "Chef run failed on #{node.name}\n"
           message << "#{run_status.formatted_exception}\n"
           message << Array(backtrace).join('\n')
           Net::SMTP.start('your.smtp.server', 25) do |smtp|
             smtp.send_message message, 'sender@example', 'recipient@example'
           end
         end
       end
     end
   end

and then is used in a recipe like:

.. code-block:: ruby

   send_email 'blah' do
     # recipe code
   end

.. end_tag

report Interface
-----------------------------------------------------
.. tag handler_custom_interface_report

The ``report`` interface is used to define how a handler will behave and is a required part of any custom handler. The syntax for the ``report`` interface is as follows:

.. code-block:: ruby

   def report
     # Ruby code
   end

The Ruby code used to define a custom handler will vary significantly from handler to handler. The chef-client includes two default handlers: ``error_report`` and ``json_file``. Their use of the ``report`` interface is shown below.

The `error_report <https://github.com/chef/chef/blob/master/lib/chef/handler/error_report.rb>`_ handler:

.. code-block:: ruby

   require 'chef/handler'
   require 'chef/resource/directory'

   class Chef
     class Handler
       class ErrorReport < ::Chef::Handler
         def report
           Chef::FileCache.store('failed-run-data.json', Chef::JSONCompat.to_json_pretty(data), 0640)
           Chef::Log.fatal("Saving node information to #{Chef::FileCache.load('failed-run-data.json', false)}")
         end
       end
    end
   end

The `json_file <https://github.com/chef/chef/blob/master/lib/chef/handler/json_file.rb>`_ handler:

.. code-block:: ruby

   require 'chef/handler'
   require 'chef/resource/directory'

   class Chef
     class Handler
       class JsonFile < ::Chef::Handler
         attr_reader :config
         def initialize(config={})
           @config = config
           @config[:path] ||= '/var/chef/reports'
           @config
         end
         def report
           if exception
             Chef::Log.error('Creating JSON exception report')
           else
             Chef::Log.info('Creating JSON run report')
           end
           build_report_dir
           savetime = Time.now.strftime('%Y%m%d%H%M%S')
           File.open(File.join(config[:path], 'chef-run-report-#{savetime}.json'), 'w') do |file|
             run_data = data
             run_data[:start_time] = run_data[:start_time].to_s
             run_data[:end_time] = run_data[:end_time].to_s
             file.puts Chef::JSONCompat.to_json_pretty(run_data)
           end
         end
         def build_report_dir
           unless File.exist?(config[:path])
             FileUtils.mkdir_p(config[:path])
             File.chmod(00700, config[:path])
           end
         end
       end
     end
   end

.. end_tag

Optional Interfaces
-----------------------------------------------------
The following interfaces may be used in a handler in the same way as the ``report`` interface to override the default handler behavior in the chef-client. That said, the following interfaces are not typically used in a handler and, for the most part, are completely unnecessary for a handler to work properly and/or as desired.

data
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag handler_custom_interface_data

The ``data`` method is used to return the Hash representation of the ``run_status`` object. For example:

.. code-block:: ruby

   def data
     @run_status.to_hash
   end

.. end_tag

run_report_safely
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag handler_custom_interface_run_report_safely

The ``run_report_safely`` method is used to run the report handler, rescuing and logging errors that may arise as the handler runs and ensuring that all handlers get a chance to run during the chef-client run (even if some handlers fail during that run). In general, this method should never be used as an interface in a custom handler unless this default behavior simply must be overridden.

.. code-block:: ruby

   def run_report_safely(run_status)
     run_report_unsafe(run_status)
   rescue Exception => e
     Chef::Log.error('Report handler #{self.class.name} raised #{e.inspect}')
     Array(e.backtrace).each { |line| Chef::Log.error(line) }
   ensure
     @run_status = nil
   end

.. end_tag

run_report_unsafe
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag handler_custom_interface_run_report_unsafe

The ``run_report_unsafe`` method is used to run the report handler without any error handling. This method should never be used directly in any handler, except during testing of that handler. For example:

.. code-block:: ruby

   def run_report_unsafe(run_status)
     @run_status = run_status
     report
   end

.. end_tag

run_status Object
-----------------------------------------------------
.. tag handler_custom_object_run_status

The ``run_status`` object is initialized by the chef-client before the ``report`` interface is run for any handler. The ``run_status`` object keeps track of the status of the chef-client run and will contain some (or all) of the following properties:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Property
     - Description
   * - ``all_resources``
     - A list of all resources that are included in the ``resource_collection`` property for the current chef-client run.
   * - ``backtrace``
     - A backtrace associated with the uncaught exception data that caused a chef-client run to fail, if present; ``nil`` for a successful chef-client run.
   * - ``elapsed_time``
     - The amount of time between the start (``start_time``) and end (``end_time``) of a chef-client run.
   * - ``end_time``
     - The time at which a chef-client run ended.
   * - ``exception``
     - The uncaught exception data which caused a chef-client run to fail; ``nil`` for a successful chef-client run.
   * - ``failed?``
     - Show that a chef-client run has failed when uncaught exceptions were raised during a chef-client run. An exception handler runs when the ``failed?`` indicator is ``true``.
   * - ``node``
     - The node on which the chef-client run occurred.
   * - ``run_context``
     - An instance of the ``Chef::RunContext`` object; used by the chef-client to track the context of the run; provides access to the ``cookbook_collection``, ``resource_collection``, and ``definitions`` properties.
   * - ``start_time``
     - The time at which a chef-client run started.
   * - ``success?``
     - Show that a chef-client run succeeded when uncaught exceptions were not raised during a chef-client run. A report handler runs when the ``success?`` indicator is ``true``.
   * - ``updated_resources``
     - A list of resources that were marked as updated as a result of the chef-client run.

.. note:: These properties are not always available. For example, a start handler runs at the beginning of the chef-client run, which means that properties like ``end_time`` and ``elapsed_time`` are still unknown and will be unavailable to the ``run_status`` object.

.. end_tag

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

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

