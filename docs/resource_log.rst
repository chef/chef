=====================================================
log
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_log.rst>`__

.. tag resource_log_summary

Use the **log** resource to create log entries. The **log** resource behaves like any other resource: built into the resource collection during the compile phase, and then run during the execution phase. (To create a log entry that is not built into the resource collection, use ``Chef::Log`` instead of the **log** resource.)

.. note:: By default, every log resource that executes will count as an updated resource in the updated resource count at the end of a Chef run. You can disable this behavior by adding ``count_log_resource_updates false`` to your Chef ``client.rb`` configuration file.

.. end_tag

Syntax
=====================================================
.. tag resource_log_syntax

A **log** resource block adds messages to the log file based on events that occur during the chef-client run:

.. code-block:: ruby

   log 'message' do
     message 'A message add to the log.'
     level :info
   end

The full syntax for all of the properties that are available to the **log** resource is:

.. code-block:: ruby

   log 'name' do
     level                      Symbol
     message                    String # defaults to 'name' if not specified
     notifies                   # see description
     provider                   Chef::Provider::ChefLog
     subscribes                 # see description
     action                     Symbol # defaults to :write if not specified
   end

where

* ``log`` is the resource
* ``name`` is the name of the resource block
* ``message`` is the log message to write
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``level``, ``message``, and ``provider`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
=====================================================
.. tag resource_log_actions

This resource has the following actions:

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:write``
   Default. Write to log.

.. end_tag

Properties
=====================================================
.. tag resource_log_attributes

This resource has the following properties:

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``level``
   **Ruby Type:** Symbol

   The level of logging that is to be displayed by the chef-client. The chef-client uses the ``mixlib-log`` (https://github.com/chef/mixlib-log) to handle logging behavior. Options (in order of priority): ``:debug``, ``:info``, ``:warn``, ``:error``, and ``:fatal``. Default value: ``:info``.

``message``
   **Ruby Type:** String

   The message to be added to a log file. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

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

.. end_tag

Chef::Log Entries
=====================================================
.. tag ruby_style_basics_chef_log

``Chef::Log`` extends ``Mixlib::Log`` and will print log entries to the default logger that is configured for the machine on which the chef-client is running. (To create a log entry that is built into the resource collection, use the **log** resource instead of ``Chef::Log``.)

The following log levels are supported:

.. list-table::
   :widths: 150 450
   :header-rows: 1

   * - Log Level
     - Syntax
   * - Fatal
     - ``Chef::Log.fatal('string')``
   * - Error
     - ``Chef::Log.error('string')``
   * - Warn
     - ``Chef::Log.warn('string')``
   * - Info
     - ``Chef::Log.info('string')``
   * - Debug
     - ``Chef::Log.debug('string')``

.. note:: The parentheses are optional, e.g. ``Chef::Log.info 'string'`` may be used instead of ``Chef::Log.info('string')``.

.. end_tag

.. tag ruby_class_chef_log_fatal

The following example shows a series of fatal ``Chef::Log`` entries:

.. code-block:: ruby

   unless node['splunk']['upgrade_enabled']
     Chef::Log.fatal('The chef-splunk::upgrade recipe was added to the node,')
     Chef::Log.fatal('but the attribute `node["splunk"]["upgrade_enabled"]` was not set.')
     Chef::Log.fatal('I am bailing here so this node does not upgrade.')
     raise
   end

   service 'splunk_stop' do
     service_name 'splunk'
     supports status: true
     action :stop
   end

   if node['splunk']['is_server']
     splunk_package = 'splunk'
     url_type = 'server'
   else
     splunk_package = 'splunkforwarder'
     url_type = 'forwarder'
   end

   splunk_installer splunk_package do
     url node['splunk']['upgrade']["#{url_type}_url"]
   end

   if node['splunk']['accept_license']
     execute 'splunk-unattended-upgrade' do
       command "#{splunk_cmd} start --accept-license --answer-yes"
     end
   else
     Chef::Log.fatal('You did not accept the license (set node["splunk"]["accept_license"] to true)')
     Chef::Log.fatal('Splunk is stopped and cannot be restarted until the license is accepted!')
     raise
   end

The full recipe is the ``upgrade.rb`` recipe of the `chef-splunk cookbook <https://github.com/chef-cookbooks/chef-splunk/>`_ that is maintained by Chef.

.. end_tag

.. tag ruby_class_chef_log_multiple

The following example shows using multiple ``Chef::Log`` entry types:

.. code-block:: ruby

   ...

   begin
     aws = Chef::DataBagItem.load(:aws, :main)
     Chef::Log.info("Loaded AWS information from DataBagItem aws[#{aws['id']}]")
   rescue
     Chef::Log.fatal("Could not find the 'main' item in the 'aws' data bag")
     raise
   end

   ...

The full recipe is in the ``ebs_volume.rb`` recipe of the `database cookbook <https://github.com/chef-cookbooks/database/>`_ that is maintained by Chef.

.. end_tag

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

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

