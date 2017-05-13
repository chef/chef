.. THIS PAGE DOCUMENTS chef-client version 12.5

=====================================================
About the Handler DSL
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/dsl_handler.rst>`__

.. tag dsl_handler_summary

Use the Handler DSL to attach a callback to an event. If the event occurs during the chef-client run, the associated callback is executed. For example:

* Sending email if a chef-client run fails
* Sending a notification to chat application if an audit run fails
* Aggregating statistics about resources updated during a chef-client runs to StatsD

.. end_tag

New in Chef Client 12.5

on Method
=====================================================
.. tag dsl_handler_method_on

Use the ``on`` method to associate an event type with a callback. The callback defines what steps are taken if the event occurs during the chef-client run and is defined using arbitrary Ruby code. The syntax is as follows:

.. code-block:: ruby

   Chef.event_handler do
     on :event_type do
       # some Ruby
     end
   end

where

* ``Chef.event_handler`` declares a block of code within a recipe that is processed when the named event occurs during a chef-client run
* ``on`` defines the block of code that will tell the chef-client how to handle the event
* ``:event_type`` is a valid exception event type, such as ``:run_start``, ``:run_failed``, ``:converge_failed``, ``:resource_failed``, or ``:recipe_not_found``

For example:

.. code-block:: bash

   Chef.event_handler do
     on :converge_start do
       puts "Ohai! I have started a converge."
     end
   end

.. end_tag

Event Types
=====================================================
.. tag dsl_handler_event_types

The following table describes the events that may occur during a chef-client run. Each of these events may be referenced in an ``on`` method block by declaring it as the event type.

.. list-table::
   :widths: 100 420
   :header-rows: 1

   * - Event
     - Description
   * - ``:run_start``
     - The start of the chef-client run.
   * - ``:run_started``
     - The chef-client run has started.
   * - ``:ohai_completed``
     - The Ohai run has completed.
   * - ``:skipping_registration``
     - The chef-client is not registering with the Chef server because it already has a private key or because it does not need one.
   * - ``:registration_start``
     - The chef-client is attempting to create a private key with which to register to the Chef server.
   * - ``:registration_completed``
     - The chef-client created its private key successfully.
   * - ``:registration_failed``
     - The chef-client encountered an error and was unable to register with the Chef server.
   * - ``:node_load_start``
     - The chef-client is attempting to load node data from the Chef server.
   * - ``:node_load_failed``
     - The chef-client encountered an error and was unable to load node data from the Chef server.
   * - ``:run_list_expand_failed``
     - The chef-client failed to expand the run-list.
   * - ``:node_load_completed``
     - The chef-client successfully loaded node data from the Chef server. Default and override attributes for roles have been computed, but are not yet applied.
   * - ``:policyfile_loaded``
     - The policy file was loaded.
   * - ``:cookbook_resolution_start``
     - The chef-client is attempting to pull down the cookbook collection from the Chef server.
   * - ``:cookbook_resolution_failed``
     - The chef-client failed to pull down the cookbook collection from the Chef server.
   * - ``:cookbook_resolution_complete``
     - The chef-client successfully pulled down the cookbook collection from the Chef server.
   * - ``:cookbook_clean_start``
     - The chef-client is attempting to remove unneeded cookbooks.
   * - ``:removed_cookbook_file``
     - The chef-client removed a file from a cookbook.
   * - ``:cookbook_clean_complete``
     - The chef-client is done removing cookbooks and/or cookbook files.
   * - ``:cookbook_sync_start``
     - The chef-client is attempting to synchronize cookbooks.
   * - ``:synchronized_cookbook``
     - The chef-client is attempting to synchronize the named cookbook.
   * - ``:updated_cookbook_file``
     - The chef-client updated the named file in the named cookbook.
   * - ``:cookbook_sync_failed``
     - The chef-client was unable to synchronize cookbooks.
   * - ``:cookbook_sync_complete``
     - The chef-client is finished synchronizing cookbooks.
   * - ``:library_load_start``
     - The chef-client is loading library files.
   * - ``:library_file_loaded``
     - The chef-client successfully loaded the named library file.
   * - ``:library_file_load_failed``
     - The chef-client was unable to load the named library file.
   * - ``:library_load_complete``
     - The chef-client is finished loading library files.
   * - ``:lwrp_load_start``
     - The chef-client is loading custom resources.
   * - ``:lwrp_file_loaded``
     - The chef-client successfully loaded the named custom resource.
   * - ``:lwrp_file_load_failed``
     - The chef-client was unable to load the named custom resource.
   * - ``:lwrp_load_complete``
     - The chef-client is finished loading custom resources.
   * - ``:attribute_load_start``
     - The chef-client is loading attribute files.
   * - ``:attribute_file_loaded``
     - The chef-client successfully loaded the named attribute file.
   * - ``:attribute_file_load_failed``
     - The chef-client was unable to load the named attribute file.
   * - ``:attribute_load_complete``
     - The chef-client is finished loading attribute files.
   * - ``:definition_load_start``
     - The chef-client is loading definitions.
   * - ``:definition_file_loaded``
     - The chef-client successfully loaded the named definition.
   * - ``:definition_file_load_failed``
     - The chef-client was unable to load the named definition.
   * - ``:definition_load_complete``
     - The chef-client is finished loading definitions.
   * - ``:recipe_load_start``
     - The chef-client is loading recipes.
   * - ``:recipe_file_loaded``
     - The chef-client successfully loaded the named recipe.
   * - ``:recipe_file_load_failed``
     - The chef-client was unable to load the named recipe.
   * - ``:recipe_not_found``
     - The chef-client was unable to find the named recipe.
   * - ``:recipe_load_complete``
     - The chef-client is finished loading recipes.
   * - ``:converge_start``
     - The chef-client run converge phase has started.
   * - ``:converge_complete``
     - The chef-client run converge phase is complete.
   * - ``:converge_failed``
     - The chef-client run converge phase has failed.
   * - ``:audit_phase_start``
     - The chef-client run audit phase has started.
   * - ``:audit_phase_complete``
     - The chef-client run audit phase is finished.
   * - ``:audit_phase_failed``
     - The chef-client run audit phase has failed.
   * - ``:control_group_started``
     - The named control group is being processed.
   * - ``:control_example_success``
     - The named control group has been processed.
   * - ``:control_example_failure``
     - The named control group's processing has failed.
   * - ``:resource_action_start``
     - A resource action is starting.
   * - ``:resource_skipped``
     - A resource action was skipped.
   * - ``:resource_current_state_loaded``
     - A resource's current state was loaded.
   * - ``:resource_current_state_load_bypassed``
     - A resource's current state was not loaded because the resource does not support why-run mode.
   * - ``:resource_bypassed``
     - A resource action was skipped because the resource does not support why-run mode.
   * - ``:resource_update_applied``
     - A change has been made to a resource. (This event occurs for each change made to a resource.)
   * - ``:resource_failed_retriable``
     - A resource action has failed and will be retried.
   * - ``:resource_failed``
     - A resource action has failed and will not be retried.
   * - ``:resource_updated``
     - A resource requires modification.
   * - ``:resource_up_to_date``
     - A resource is already correct.
   * - ``:resource_completed``
     - All actions for the resource are complete.
   * - ``:stream_opened``
     - A stream has opened.
   * - ``:stream_closed``
     - A stream has closed.
   * - ``:stream_output``
     - A chunk of data from a single named stream.
   * - ``:handlers_start``
     - The handler processing phase of the chef-client run has started.
   * - ``:handler_executed``
     - The named handler was processed.
   * - ``:handlers_completed``
     - The handler processing phase of the chef-client run is complete.
   * - ``:provider_requirement_failed``
     - An assertion declared by a provider has failed.
   * - ``:whyrun_assumption``
     - An assertion declared by a provider has failed, but execution is allowed to continue because the chef-client is running in why-run mode.
   * - ``:run_completed``
     - The chef-client run has completed.
   * - ``:run_failed``
     - The chef-client run has failed.
   * - ``:attribute_changed``
     - Prints out all the attribute changes in cookbooks or sets a policy that override attributes should never be used.

.. end_tag

   New in Chef Client 12.16, ``:attribute_changed``

Examples
=====================================================
The following examples show ways to use the Handler DSL.

Send Email
-----------------------------------------------------
.. tag dsl_handler_slide_send_email

Use the ``on`` method to create an event handler that sends email when the chef-client run fails. This will require:

* A way to tell the chef-client how to send email
* An event handler that describes what to do when the ``:run_failed`` event is triggered
* A way to trigger the exception and test the behavior of the event handler

.. end_tag

Define How Email is Sent
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_handler_slide_send_email_library

Use a library to define the code that sends email when a chef-client run fails. Name the file ``helper.rb`` and add it to a cookbook's ``/libraries`` directory:

.. code-block:: ruby

   require 'net/smtp'

   module HandlerSendEmail
     class Helper

       def send_email_on_run_failure(node_name)

         message = "From: Chef <chef@chef.io>\n"
         message << "To: Grant <grantmc@chef.io>\n"
         message << "Subject: Chef run failed\n"
         message << "Date: #{Time.now.rfc2822}\n\n"
         message << "Chef run failed on #{node_name}\n"
         Net::SMTP.start('localhost', 25) do |smtp|
           smtp.send_message message, 'chef@chef.io', 'grantmc@chef.io'
         end
       end
     end
   end

.. end_tag

Add the Handler
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_handler_slide_send_email_handler

Invoke the library helper in a recipe:

.. code-block:: ruby

   Chef.event_handler do
     on :run_failed do
       HandlerSendEmail::Helper.new.send_email_on_run_failure(
         Chef.run_context.node.name
       )
     end
   end

* Use ``Chef.event_handler`` to define the event handler
* Use the ``on`` method to specify the event type

Within the ``on`` block, tell the chef-client how to handle the event when it's triggered.

.. end_tag

Test the Handler
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_handler_slide_send_email_test

Use the following code block to trigger the exception and have the chef-client send email to the specified email address:

.. code-block:: ruby

   ruby_block 'fail the run' do
     block do
       fail 'deliberately fail the run'
     end
   end

.. end_tag

etcd Locks
-----------------------------------------------------
.. tag dsl_handler_example_etcd_lock

The following example shows how to prevent concurrent chef-client runs from both holding a lock on etcd:

.. code-block:: ruby

   lock_key = "#{node.chef_environment}/#{node.name}"

   Chef.event_handler do
     on :converge_start do |run_context|
       Etcd.lock_acquire(lock_key)
     end
   end

   Chef.event_handler do
     on :converge_complete do
       Etcd.lock_release(lock_key)
     end
   end

.. end_tag

HipChat Notifications
-----------------------------------------------------
.. tag dsl_handler_example_hipchat

Event messages can be sent to a team communication tool like HipChat. For example, if a chef-client run fails:

.. code-block:: ruby

   Chef.event_handler do
     on :run_failed do |exception|
       hipchat_notify exception.message
     end
   end

or send an alert on a configuration change:

.. code-block:: ruby

   Chef.event_handler do
     on :resource_updated do |resource, action|
       if resource.to_s == 'template[/etc/nginx/nginx.conf]'
         Helper.hipchat_message("#{resource} was updated by chef")
       end
     end
   end

.. end_tag

``attribute_changed`` event hook
-----------------------------------------------------

In a cookbook library file, you can add this in order to print out all attribute changes in cookbooks:

.. code-block:: ruby

   Chef.event_handler do
     on :attribute_changed do |precedence, key, value|
       puts "setting attribute #{precedence}#{key.map {|n| "[\"#{n}\"]" }.join} = #{value}"
     end
   end

If you want to setup a policy that override attributes should never be used:

.. code-block:: ruby

   Chef.event_handler do
     on :attribute_changed do |precedence, key, value|
       raise "override policy violation" if precedence == :override
     end
   end
