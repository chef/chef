=====================================================
subversion
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_subversion.rst>`__

.. tag resource_scm_subversion

Use the **subversion** resource to manage source control resources that exist in a Subversion repository.

.. end_tag

.. warning:: The subversion resource has known bugs and may not work as expected. For more information see Chef GitHub issues, particularly `#4050 <https://github.com/chef/chef/issues/4050>`_ and `#4257 <https://github.com/chef/chef/issues/4257>`_.

.. note:: .. tag notes_scm_resource_use_with_resource_deploy

          This resource is often used in conjunction with the **deploy** resource.

          .. end_tag

Syntax
=====================================================
A **subversion** resource block manages source control resources that exist in a Subversion repository:

.. code-block:: ruby

   subversion 'CouchDB Edge' do
     repository 'http://svn.apache.org/repos/asf/couchdb/trunk'
     revision 'HEAD'
     destination '/opt/mysources/couch'
     action :sync
   end

The full syntax for all of the properties that are available to the **subversion** resource is:

.. code-block:: ruby

   subversion 'name' do
     destination                String # defaults to 'name' if not specified
     group                      String, Integer
     notifies                   # see description
     provider                   Chef::Provider::Scm::Subversion
     repository                 String
     revision                   String
     subscribes                 # see description
     svn_arguments              String
     svn_info_args              String
     svn_password               String
     svn_username               String
     timeout                    Integer
     user                       String, Integer
     action                     Symbol # defaults to :sync if not specified
   end

where

* ``subversion`` is the resource
* ``name`` is the name of the resource block and also (when the ``destination`` property is not specified) the location in which the source files will be placed and/or synchronized with the files under source control management
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``destination``, ``group``, ``provider``, ``repository``, ``revision``, ``svn_arguments``, ``svn_info_args``, ``svn_password``, ``svn_username``, ``timeout``, and ``user`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

``:checkout``
   Clone or check out the source. When a checkout is available, this provider does nothing.

``:export``
   Export the source, excluding or removing any version control artifacts.

``:force_export``
   Export the source, excluding or removing any version control artifacts and force an export of the source that is overwriting the existing copy (if it exists).

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:sync``
   Default. Update the source to the specified version, or get a new clone or checkout. This action causes a hard reset of the index and working tree, discarding any uncommitted changes.

Properties
=====================================================
This resource has the following properties:

``destination``
   **Ruby Type:** String

   The location path to which the source is to be cloned, checked out, or exported. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``group``
   **Ruby Types:** String, Integer

   The system group that is responsible for the checked-out code.

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

``repository``
   **Ruby Type:** String

   The URI for the Subversion repository.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``revision``
   **Ruby Type:** String

   A branch, tag, or commit to be synchronized with git. This can be symbolic, like ``HEAD`` or it can be a source control management-specific revision identifier. Default value: ``HEAD``.

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

``svn_arguments``
   **Ruby Type:** String

   The extra arguments that are passed to the Subversion command.

``svn_info_args``
   **Ruby Type:** String

   Use when the ``svn info`` command is used by the chef-client and arguments need to be passed. The ``svn_arguments`` command does not work when the ``svn info`` command is used.

``svn_password``
   **Ruby Type:** String

   The password for a user that has access to the Subversion repository.

``svn_username``
   **Ruby Type:** String

   The user name for a user that has access to the Subversion repository.

``timeout``
   **Ruby Type:** Integer

   The amount of time (in seconds) to wait for a command to execute before timing out. When this property is specified using the **deploy** resource, the value of the ``timeout`` property is passed from the **deploy** resource to the **subversion** resource.

``user``
   **Ruby Types:** String, Integer

   The system user that is responsible for the checked-out code.

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

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
