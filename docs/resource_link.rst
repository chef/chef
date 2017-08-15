=====================================================
link
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_link.rst>`__

.. tag resource_link_summary

Use the **link** resource to create symbolic or hard links.

.. end_tag

A symbolic link---sometimes referred to as a soft link---is a directory entry that associates a file name with a string that contains an absolute or relative path to a file on any file system. In other words, "a file that contains a path that points to another file." A symbolic link creates a new file with a new inode that points to the inode location of the original file.

A hard link is a directory entry that associates a file with another file in the same file system. In other words, "multiple directory entries to the same file." A hard link creates a new file that points to the same inode as the original file.

Syntax
=====================================================
A **link** resource block creates symbolic or hard links. For example, to create a hard link from ``/tmp/file`` to ``/etc/file``:

.. code-block:: ruby

   link '/tmp/file' do
     to '/etc/file'
     link_type :hard
   end

Because the default value for ``link_type`` is symbolic, and because properties that are not specified in the resource block will be assigned their default values, the following example creates a symbolic link:

.. code-block:: ruby

   link '/tmp/file' do
     to '/etc/file'
   end

The full syntax for all of the properties that are available to the **link** resource is:

.. code-block:: ruby

   link 'name' do
     group                      Integer, String
     link_type                  Symbol
     mode                       Integer, String
     notifies                   # see description
     owner                      Integer, String
     provider                   Chef::Provider::Link
     subscribes                 # see description
     target_file                String # defaults to 'name' if not specified
     to                         String
     action                     Symbol # defaults to :create if not specified
   end

where

* ``link`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``group``, ``link_type``, ``mode``, ``owner``, ``provider``, ``target_file``, and ``to`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

``:create``
   Default. Create a link. If a link already exists (but does not match), update that link to match.

``:delete``
   Delete a link.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

Properties
=====================================================
This resource has the following properties:

``group``
   **Ruby Types:** Integer, String

   A string or ID that identifies the group associated with a symbolic link.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``link_type``
   **Ruby Type:** Symbol

   The type of link: ``:symbolic`` or ``:hard``. Default value: ``:symbolic``.

``mode``
   **Ruby Types:** Integer, String

   If ``mode`` is not specified and if the file already exists, the existing mode on the file is used. If ``mode`` is not specified, the file does not exist, and the ``:create`` action is specified, the chef-client assumes a mask value of ``'0777'`` and then applies the umask for the system on which the file is to be created to the ``mask`` value. For example, if the umask on a system is ``'022'``, the chef-client uses the default value of ``'0755'``. Default value: ``777``.

   The behavior is different depending on the platform.

   UNIX- and Linux-based systems: A quoted 3-5 character string that defines the octal mode that is passed to chmod. For example: ``'755'``, ``'0755'``, or ``00755``. If the value is specified as a quoted string, it works exactly as if the ``chmod`` command was passed. If the value is specified as an integer, prepend a zero (``0``) to the value to ensure that it is interpreted as an octal number. For example, to assign read, write, and execute rights for all users, use ``'0777'`` or ``'777'``; for the same rights, plus the sticky bit, use ``01777`` or ``'1777'``.

   Microsoft Windows: A quoted 3-5 character string that defines the octal mode that is translated into rights for Microsoft Windows security. For example: ``'755'``, ``'0755'``, or ``00755``. Values up to ``'0777'`` are allowed (no sticky bits) and mean the same in Microsoft Windows as they do in UNIX, where ``4`` equals ``GENERIC_READ``, ``2`` equals ``GENERIC_WRITE``, and ``1`` equals ``GENERIC_EXECUTE``. This property cannot be used to set ``:full_control``. This property has no effect if not specified, but when it and ``rights`` are both specified, the effects are cumulative.

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

``owner``
   **Ruby Types:** Integer, String

   The owner associated with a symbolic link.

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

``target_file``
   **Ruby Type:** String

   The name of the link. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``to``
   **Ruby Type:** String

   The actual file to which the link is to be created.

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

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

