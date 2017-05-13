=====================================================
remote_directory
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_remote_directory.rst>`__

.. tag resource_remote_directory_summary

Use the **remote_directory** resource to incrementally transfer a directory from a cookbook to a node. The directory that is copied from the cookbook should be located under ``COOKBOOK_NAME/files/default/REMOTE_DIRECTORY``. The **remote_directory** resource will obey file specificity.

.. end_tag

Syntax
=====================================================
A **remote_directory** resource block transfers a directory from a cookbook to a node, and then assigns the permissions needed on that directory. For example:

.. code-block:: ruby

   remote_directory '/etc/apache2' do
     source 'apache2'
     owner 'root'
     group 'root'
     mode '0755'
     action :create
   end

where

* ``'/etc/apache2'`` specifies the directory
* ``source`` specifies a directory in the current cookbook (use the ``cookbook`` property to specify a file that is in a different cookbook)
* ``owner``, ``group``, and ``mode`` define the permissions

The full syntax for all of the properties that are available to the **remote_directory** resource is:

.. code-block:: ruby

   remote_directory 'name' do
     cookbook                   String
     files_backup               Integer, FalseClass
     files_group                String
     files_mode                 String
     files_owner                String
     group                      String, Integer
     inherits                   TrueClass, FalseClass
     mode                       String, Integer
     notifies                   # see description
     overwrite                  TrueClass, FalseClass
     owner                      String, Integer
     path                       String # defaults to 'name' if not specified
     provider                   Chef::Provider::Directory::RemoteDirectory
     purge                      TrueClass, FalseClass
     recursive                  TrueClass, FalseClass
     rights                     Hash
     source                     String
     subscribes                 # see description
     action                     Symbol # defaults to :create if not specified
   end

where

* ``remote_directory`` is the resource
* ``name`` is the name of the resource block; when the ``path`` property is not specified, ``name`` is also the path to the directory, from the root
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``cookbook``, ``files_backup``, ``files_group``, ``files_mode``, ``files_owner``, ``group``, ``inherits``, ``mode``, ``overwrite``, ``owner``, ``path``, ``provider``, ``recursive``, ``rights``, and ``source`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

``:create``
   Default. Create a directory and/or the contents of that directory. If a directory or its contents already exist (but does not match), update that directory or its contents to match.

``:create_if_missing``
   Create a directory and/or the contents of that directory, but only if it does not exist.

``:delete``
   Delete a directory, including the contents of that directory.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

Properties
=====================================================
This resource has the following properties:

``cookbook``
   **Ruby Type:** String

   The cookbook in which a file is located (if it is not located in the current cookbook). The default value is the current cookbook.

``files_backup``
   **Ruby Types:** Integer, FalseClass

   The number of backup copies to keep for files in the directory. Default value: ``5``.

``files_group``
   **Ruby Type:** String

   Configure group permissions for files. A string or ID that identifies the group owner by group name, including fully qualified group names such as ``domain\group`` or ``group@domain``. If this value is not specified, existing groups remain unchanged and new group assignments use the default ``POSIX`` group (if available).

``files_mode``
   **Ruby Type:** String

   The octal mode for a file.

   UNIX- and Linux-based systems: A quoted 3-5 character string that defines the octal mode that is passed to chmod. For example: ``'755'``, ``'0755'``, or ``00755``. If the value is specified as a quoted string, it works exactly as if the ``chmod`` command was passed. If the value is specified as an integer, prepend a zero (``0``) to the value to ensure that it is interpreted as an octal number. For example, to assign read, write, and execute rights for all users, use ``'0777'`` or ``'777'``; for the same rights, plus the sticky bit, use ``01777`` or ``'1777'``.

   Microsoft Windows: A quoted 3-5 character string that defines the octal mode that is translated into rights for Microsoft Windows security. For example: ``'755'``, ``'0755'``, or ``00755``. Values up to ``'0777'`` are allowed (no sticky bits) and mean the same in Microsoft Windows as they do in UNIX, where ``4`` equals ``GENERIC_READ``, ``2`` equals ``GENERIC_WRITE``, and ``1`` equals ``GENERIC_EXECUTE``. This property cannot be used to set ``:full_control``. This property has no effect if not specified, but when it and ``rights`` are both specified, the effects are cumulative.

``files_owner``
   **Ruby Type:** String

   Configure owner permissions for files. A string or ID that identifies the group owner by user name, including fully qualified user names such as ``domain\user`` or ``user@domain``. If this value is not specified, existing owners remain unchanged and new owner assignments use the current user (when necessary).

``group``
   **Ruby Types:** Integer, String

   Use to configure permissions for directories. A string or ID that identifies the group owner by group name, including fully qualified group names such as ``domain\group`` or ``group@domain``. If this value is not specified, existing groups remain unchanged and new group assignments use the default ``POSIX`` group (if available).

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``inherits``
   **Ruby Types:** TrueClass, FalseClass

   Microsoft Windows only. Whether a file inherits rights from its parent directory. Default value: ``true``.

``mode``
   **Ruby Types:** Integer, String

   A quoted 3-5 character string that defines the octal mode. For example: ``'755'``, ``'0755'``, or ``00755``. If ``mode`` is not specified and if the directory already exists, the existing mode on the directory is used. If ``mode`` is not specified, the directory does not exist, and the ``:create`` action is specified, the chef-client assumes a mask value of ``'0777'``, and then applies the umask for the system on which the directory is to be created to the ``mask`` value. For example, if the umask on a system is ``'022'``, the chef-client uses the default value of ``'0755'``.

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

``overwrite``
   **Ruby Types:** TrueClass, FalseClass

   Overwrite a file when it is different. Default value: ``true``.

``owner``
   **Ruby Types:** Integer, String

   Use to configure permissions for directories. A string or ID that identifies the group owner by user name, including fully qualified user names such as ``domain\user`` or ``user@domain``. If this value is not specified, existing owners remain unchanged and new owner assignments use the current user (when necessary).

``path``
   **Ruby Type:** String

   The path to the directory. Using a fully qualified path is recommended, but is not always required. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider.

``purge``
   **Ruby Types:** TrueClass, FalseClass

   Purge extra files found in the target directory. Default value: ``false``.

``recursive``
   **Ruby Types:** TrueClass, FalseClass

   Create or delete directories recursively. Default value: ``true``; the chef-client must be able to create the directory structure, including parent directories (if missing), as defined in ``COOKBOOK_NAME/files/default/REMOTE_DIRECTORY``.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``rights``
   **Ruby Types:** Integer, String

   Microsoft Windows only. The permissions for users and groups in a Microsoft Windows environment. For example: ``rights <permissions>, <principal>, <options>`` where ``<permissions>`` specifies the rights granted to the principal, ``<principal>`` is the group or user name, and ``<options>`` is a Hash with one (or more) advanced rights options.

``source``
   **Ruby Type:** String

   The base name of the source file (and inferred from the ``path`` property).

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

Recursive Directories
-----------------------------------------------------
The **remote_directory** resource can be used to recursively create the path outside of remote directory structures, but the permissions of those outside paths are not managed. This is because the ``recursive`` attribute only applies ``group``, ``mode``, and ``owner`` attribute values to the remote directory itself and any inner directories the resource copies.

A directory structure::

  /foo
    /bar
      /baz

The following example shows a way create a file in the ``/baz`` directory:

.. code-block:: ruby

   remote_directory "/foo/bar/baz" do
     owner 'root'
     group 'root'
     mode '0755'
     action :create
   end

But with this example, the ``group``, ``mode``, and ``owner`` attribute values will only be applied to ``/baz``. Which is fine, if that's what you want. But most of the time, when the entire ``/foo/bar/baz`` directory structure is not there, you must be explicit about each directory. For example:

.. code-block:: ruby

   %w[ /foo /foo/bar /foo/bar/baz ].each do |path|
     remote_directory path do
       owner 'root'
       group 'root'
       mode '0755'
     end
   end

This approach will create the correct hierarchy---``/foo``, then ``/bar`` in ``/foo``, and then ``/baz`` in ``/bar``---and also with the correct attribute values for ``group``, ``mode``, and ``owner``.

Example
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This section contains a more detailed example of how the chef-client manages recursive directory structures:

* A cookbook named ``cumbria`` that is used to build a website
* A subfolder in the ``/files/default`` directory named ``/website``
* A file named ``index.html``, which is the root page for the website
* Directories within ``/website`` named ``/cities``, ``/places``, and ``/football``, which contains pages about cities, places, and football teams
* A directory named ``/images``, which contains images

These files are placed in the ``/files/default`` directory in the ``cumbria`` cookbook, like this:

.. code-block:: text

   cumbria
     /files
       /default
         /website
           index.html
           /cities
             carisle.html
             kendal.html
             penrith.html
             windermere.html
           /football
             carisle_united.html
           /images
             carisle_united.png
             furness_abbey.png
             hadrians_wall.png
             kendal.png
           /places
             furness_abbey.html
             hadrians_wall.html

The **remote_directory** resource can be used to build a website using these files. This website is being run on an Apache web server. The resource would be similar to the following:

.. code-block:: ruby

   remote_directory "/var/www/html" do
     files_mode '0440'
     files_owner 'yan'
     mode '0770'
     owner 'hamilton'
     source "website"
   end

When the chef-client runs, the **remote_directory** resource will tell the chef-client to copy the directory tree from the cookbook to the file system using the structure defined in cookbook:

.. code-block:: text

   /var
     /www
       /html
         index.html
         /cities
           carisle.html
           kendal.html
           penrith.html
           windermere.html
         /football
           carisle_united.html
         /images
           carisle_united.png
           furness_abbey.png
           hadrians_wall.png
           kendal.png
         /places
           furness_abbey.html
           hadrians_wall.html

The chef-client will manage the permissions of the entire directory structure below ``/html``, for a total of 12 files and 4 directories. For example:

.. code-block:: bash

   dr-xr-xr-x 2 root     root 4096 /var/www/html
   dr--r----- 1 yan      root 4096 /var/www/html/index.html
   drwxrwx--- 2 hamilton root 4096 /var/www/html/cities
   dr--r----- 1 yan      root 4096 /var/www/html/cities/carlisle.html
   dr--r----- 1 yan      root 4096 /var/www/html/cities/kendal.html
   dr--r----- 1 yan      root 4096 /var/www/html/cities/penrith.html
   dr--r----- 1 yan      root 4096 /var/www/html/cities/windermere.html
   drwxrwx--- 2 hamilton root 4096 /var/www/html/football
   dr--r----- 1 yan      root 4096 /var/www/html/football/carlisle_united.html
   drwxrwx--- 2 hamilton root 4096 /var/www/html/images
   dr--r----- 1 yan      root 4096 /var/www/html/images/carlisle_united/png
   dr--r----- 1 yan      root 4096 /var/www/html/images/furness_abbey/png
   dr--r----- 1 yan      root 4096 /var/www/html/images/hadrians_wall.png
   dr--r----- 1 yan      root 4096 /var/www/html/images/kendal.png
   drwxrwx--- 2 hamilton root 4096 /var/www/html/places
   dr--r----- 1 yan      root 4096 /var/www/html/places/furness_abbey.html
   dr--r----- 1 yan      root 4096 /var/www/html/places/hadrians_wall.html

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

