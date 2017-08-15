=====================================================
file
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_file.rst>`__

.. tag resource_file_summary

Use the **file** resource to manage files directly on a node.

.. end_tag

.. note:: Use the **cookbook_file** resource to copy a file from a cookbook's ``/files`` directory. Use the **template** resource to create a file based on a template in a cookbook's ``/templates`` directory. And use the **remote_file** resource to transfer a file to a node from a remote location.

Syntax
=====================================================
A **file** resource block manages files that exist on nodes. For example, to write the home page for an Apache website:

.. code-block:: ruby

   file '/var/www/customers/public_html/index.php' do
     content '<html>This is a placeholder for the home page.</html>'
     mode '0755'
     owner 'web_admin'
     group 'web_admin'
   end

where

* ``'/var/www/customers/public_html/index.php'`` is path to the file and also the filename to be managed
* ``content`` defines the contents of the file

The full syntax for all of the properties that are available to the **file** resource is:

.. code-block:: ruby

   file 'name' do
     atomic_update              TrueClass, FalseClass
     backup                     FalseClass, Integer
     checksum                   String
     content                    String
     force_unlink               TrueClass, FalseClass
     group                      String, Integer
     inherits                   TrueClass, FalseClass
     manage_symlink_source      TrueClass, FalseClass, NilClass
     mode                       String, Integer
     notifies                   # see description
     owner                      String, Integer
     path                       String # defaults to 'name' if not specified
     provider                   Chef::Provider::File
     rights                     Hash
     sensitive                  TrueClass, FalseClass
     subscribes                 # see description
     verify                     String, Block
     action                     Symbol # defaults to :create if not specified
   end

where

* ``file`` is the resource
* ``name`` is the name of the resource block; when the ``path`` property is not specified as part of a recipe, ``name`` is also the path to the file
* ``content`` specifies the contents of the file
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``atomic_update``, ``backup``, ``checksum``, ``content``, ``force_unlink``, ``group``, ``inherits``, ``manage_symlink_source``, ``mode``, ``owner``, ``path``, ``provider``, ``rights``, ``sensitive``, and ``verify`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

``:create``
   Default. Create a file. If a file already exists (but does not match), update that file to match.

``:create_if_missing``
   Create a file only if the file does not exist. When the file exists, nothing happens.

``:delete``
   Delete a file.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:touch``
   Touch a file. This updates the access (atime) and file modification (mtime) times for a file.

.. warning:: .. tag notes_selinux_file_based_resources

             For a machine on which SELinux is enabled, the chef-client will create files that correctly match the default policy settings only when the cookbook that defines the action also conforms to the same policy.

             .. end_tag

Properties
=====================================================
This resource has the following properties:

``atomic_update``
   **Ruby Types:** TrueClass, FalseClass

   Perform atomic file updates on a per-resource basis. Set to ``true`` for atomic file updates. Set to ``false`` for non-atomic file updates. This setting overrides ``file_atomic_update``, which is a global setting found in the client.rb file. Default value: ``true``.

``backup``
   **Ruby Types:** FalseClass, Integer

   The number of backups to be kept in ``/var/chef/backup`` (for UNIX- and Linux-based platforms) or ``C:/chef/backup`` (for the Microsoft Windows platform). Set to ``false`` to prevent backups from being kept. Default value: ``5``.

``checksum``
   **Ruby Types:** String

   The SHA-256 checksum of the file. Use to ensure that a specific file is used. If the checksum does not match, the file is not used. Default value: no checksum required.

``content``
   **Ruby Type:** String

   A string that is written to the file. The contents of this property replace any previous content when this property has something other than the default value. The default behavior will not modify content.

``force_unlink``
   **Ruby Types:** TrueClass, FalseClass

   How the chef-client handles certain situations when the target file turns out not to be a file. For example, when a target file is actually a symlink. Set to ``true`` for the chef-client delete the non-file target and replace it with the specified file. Set to ``false`` for the chef-client to raise an error. Default value: ``false``.

``group``
   **Ruby Types:** Integer, String

   A string or ID that identifies the group owner by group name, including fully qualified group names such as ``domain\group`` or ``group@domain``. If this value is not specified, existing groups remain unchanged and new group assignments use the default ``POSIX`` group (if available).

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``inherits``
   **Ruby Types:** TrueClass, FalseClass

   Microsoft Windows only. Whether a file inherits rights from its parent directory. Default value: ``true``.

``manage_symlink_source``
   **Ruby Types:** TrueClass, FalseClass, NilClass

   Cause the chef-client to detect and manage the source file for a symlink. Possible values: ``nil``, ``true``, or ``false``. When this value is set to ``nil``, the chef-client will manage a symlink's source file and emit a warning. When this value is set to ``true``, the chef-client will manage a symlink's source file and not emit a warning. Default value: ``nil``. The default value will be changed to ``false`` in a future version.

``mode``
   **Ruby Types:** Integer, String

   A quoted 3-5 character string that defines the octal mode. For example: ``'755'``, ``'0755'``, or ``00755``. If ``mode`` is not specified and if the file already exists, the existing mode on the file is used. If ``mode`` is not specified, the file does not exist, and the ``:create`` action is specified, the chef-client assumes a mask value of ``'0777'`` and then applies the umask for the system on which the file is to be created to the ``mask`` value. For example, if the umask on a system is ``'022'``, the chef-client uses the default value of ``'0755'``.

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

   A string or ID that identifies the group owner by user name, including fully qualified user names such as ``domain\user`` or ``user@domain``. If this value is not specified, existing owners remain unchanged and new owner assignments use the current user (when necessary).

``path``
   **Ruby Type:** String

   The full path to the file, including the file name and its extension. For example: ``/files/file.txt``. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

   Microsoft Windows: A path that begins with a forward slash (``/``) will point to the root of the current working directory of the chef-client process. This path can vary from system to system. Therefore, using a path that begins with a forward slash (``/``) is not recommended.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``rights``
   **Ruby Types:** Integer, String

   Microsoft Windows only. The permissions for users and groups in a Microsoft Windows environment. For example: ``rights <permissions>, <principal>, <options>`` where ``<permissions>`` specifies the rights granted to the principal, ``<principal>`` is the group or user name, and ``<options>`` is a Hash with one (or more) advanced rights options.

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

``verify``
   **Ruby Types:** String, Block

   Allows verification of a file's contents before it is created. Creates a temporary file and then allows execution of commands or Ruby code. If this code evalutes to true, the file is created. If the code evaluates to false, an error is raised.

   The types for this property are a block or a string. When specified as a block, it returns ``true`` or ``false``. When specified as a string, it is executed as a system command. It evaluates to ``true`` if the command returns 0 as its exit status code and ``false`` if the command returns a non-zero exit status code.

   .. note:: A block is arbitrary Ruby defined within the resource block by using the ``verify`` property. When a block returns ``true``, the chef-client will continue to update the file as appropriate.

   For example, this should return ``true``:

   .. code-block:: ruby

      file '/tmp/baz' do
        verify { 1 == 1 }
      end

   This should also return ``true``:

   .. code-block:: ruby

      file '/etc/nginx.conf' do
        verify 'nginx -t -c %{path}'
      end

   In this example, the ``%{path}`` portion of this command is expanded to the temporary location where a copy of the file to be created exists. This will use Nginx's syntax checking feature to ensure the file is a valid Nginx configuration file before writing the file. An error will be raised if the executed command returns a non-zero exit status code.

   .. warning:: For releases of the Chef Client prior to 12.5 (Chef Client 12.4 and earlier), the correct syntax is:

      .. code-block:: ruby

         file '/etc/nginx.conf' do
           verify 'nginx -t -c %{file}'
         end

      See GitHub issues https://github.com/chef/chef/issues/3232 and https://github.com/chef/chef/pull/3693 for more information about these differences.

   This should return ``true``:

   .. code-block:: ruby

      file '/tmp/foo' do
        content "hello"
        verify do |path|
          open(path).read.include? "hello"
        end
      end

   Whereas, this should return ``false``:

   .. code-block:: ruby

      file '/tmp/foo' do
        content "goodbye"
        verify do |path|
          open(path).read.include? "hello"
        end
      end

   If a string or a block return ``false``, the chef-client run will stop and an error is raised.

   Originally proposed in `RFC 27 <https://github.com/chef/chef-rfc/blob/master/rfc027-file-content-verification.md>`_.

   New in Chef Client 12.1.

Atomic File Updates
-----------------------------------------------------
.. tag resources_common_atomic_update

Atomic updates are used with **file**-based resources to help ensure that file updates can be made when updating a binary or if disk space runs out.

Atomic updates are enabled by default. They can be managed globally using the ``file_atomic_update`` setting in the client.rb file. They can be managed on a per-resource basis using the ``atomic_update`` property that is available with the **cookbook_file**, **file**, **remote_file**, and **template** resources.

.. note:: On certain platforms, and after a file has been moved into place, the chef-client may modify file permissions to support features specific to those platforms. On platforms with SELinux enabled, the chef-client will fix up the security contexts after a file has been moved into the correct location by running the ``restorecon`` command. On the Microsoft Windows platform, the chef-client will create files so that ACL inheritance works as expected.

.. end_tag

Windows File Security
-----------------------------------------------------
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

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

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
