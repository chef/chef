=====================================================
template
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_template.rst>`__

.. tag template

A cookbook template is an Embedded Ruby (ERB) template that is used to dynamically generate static text files. Templates may contain Ruby expressions and statements, and are a great way to manage configuration files. Use the **template** resource to add cookbook templates to recipes; place the corresponding Embedded Ruby (ERB) template file in a cookbook's ``/templates`` directory.

.. end_tag

.. note:: .. tag notes_cookbook_template_erubis

          The chef-client uses Erubis for templates, which is a fast, secure, and extensible implementation of embedded Ruby. Erubis should be familiar to members of the Ruby on Rails, Merb, or Puppet communities. For more information about Erubis, see: http://www.kuwata-lab.com/erubis/.

          .. end_tag

.. tag resource_template_summary

Use the **template** resource to manage the contents of a file using an Embedded Ruby (ERB) template by transferring files from a sub-directory of ``COOKBOOK_NAME/templates/`` to a specified path located on a host that is running the chef-client. This resource includes actions and properties from the **file** resource. Template files managed by the **template** resource follow the same file specificity rules as the **remote_file** and **file** resources.

.. end_tag

Syntax
=====================================================
A **template** resource block typically declares the location in which a file is to be created, the source template that will be used to create the file, and the permissions needed on that file. For example:

.. code-block:: ruby

   template '/etc/motd' do
     source 'motd.erb'
     owner 'root'
     group 'root'
     mode '0755'
   end

where

* ``'/etc/motd'`` specifies the location in which the file is created
* ``'motd.erb'`` specifies the name of a template that exists in in the ``/templates`` folder of a cookbook
* ``owner``, ``group``, and ``mode`` define the permissions

The full syntax for all of the properties that are available to the **template** resource is:

.. code-block:: ruby

   template 'name' do
     atomic_update              TrueClass, FalseClass
     backup                     FalseClass, Integer
     cookbook                   String
     force_unlink               TrueClass, FalseClass
     group                      String, Integer
     helper(:method)            Method { String } # see Helpers below
     helpers(module)            Module # see Helpers below
     inherits                   TrueClass, FalseClass
     local                      TrueClass, FalseClass
     manage_symlink_source      TrueClass, FalseClass, NilClass
     mode                       String, Integer
     notifies                   # see description
     owner                      String, Integer
     path                       String # defaults to 'name' if not specified
     provider                   Chef::Provider::File::Template
     rights                     Hash
     sensitive                  TrueClass, FalseClass
     source                     String, Array
     subscribes                 # see description
     variables                  Hash
     verify                     String, Block
     action                     Symbol # defaults to :create if not specified
   end

where

* ``template`` is the resource
* ``name`` is the name of the resource block, typically the path to the location in which a file is created *and also* the name of the file to be managed. For example: ``/var/www/html/index.html``, where ``/var/www/html/`` is the fully qualified path to the location and ``index.html`` is the name of the file
* ``source`` is the template file that will be used to create the file on the node, for example: ``index.html.erb``; the template file is located in the ``/templates`` directory of a cookbook
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``atomic_update``, ``backup``, ``cookbook``, ``force_unlink``, ``group``, ``helper``, ``helpers``, ``inherits``, ``local``, ``manage_symlink_source``, ``mode``, ``owner``, ``path``, ``provider``, ``rights``, ``sensitive``, ``source``, ``variables``, and ``verify`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

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
   Touch a file. This updates the access (atime) and file modification (mtime) times for a file. (This action may be used with this resource, but is typically only used with the **file** resource.)

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

``cookbook``
   **Ruby Type:** String

   The cookbook in which a file is located (if it is not located in the current cookbook). The default value is the current cookbook.

``force_unlink``
   **Ruby Types:** TrueClass, FalseClass

   How the chef-client handles certain situations when the target file turns out not to be a file. For example, when a target file is actually a symlink. Set to ``true`` for the chef-client delete the non-file target and replace it with the specified file. Set to ``false`` for the chef-client to raise an error. Default value: ``false``.

``group``
   **Ruby Types:** Integer, String

   A string or ID that identifies the group owner by group name, including fully qualified group names such as ``domain\group`` or ``group@domain``. If this value is not specified, existing groups remain unchanged and new group assignments use the default ``POSIX`` group (if available).

``helper``
   **Ruby Type:** Method

   Define a helper method inline. For example: ``helper(:hello_world) { "hello world" }`` or ``helper(:app) { node["app"] }`` or ``helper(:app_conf) { |setting| node["app"][setting] }``. Default value: ``{}``.

``helpers``
   **Ruby Type:** Module

   Define a helper module inline or in a library. For example, an inline module: ``helpers do``, which is then followed by a block of Ruby code. And for a library module: ``helpers(MyHelperModule)``. Default value: ``[]``.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``inherits``
   **Ruby Types:** TrueClass, FalseClass

   Microsoft Windows only. Whether a file inherits rights from its parent directory. Default value: ``true``.

``local``
   **Ruby Types:** TrueClass, FalseClass

   Load a template from a local path. By default, the chef-client loads templates from a cookbook's ``/templates`` directory. When this property is set to ``true``, use the ``source`` property to specify the path to a template on the local node. Default value: ``false``.

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

   The full path to the file, including the file name and its extension.

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

``source``
   **Ruby Types:** String, Array

   The location of a template file. By default, the chef-client looks for a template file in the ``/templates`` directory of a cookbook. When the ``local`` property is set to ``true``, use to specify the path to a template on the local node. This property may also be used to distribute specific files to specific platforms. See "File Specificity" below for more information. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

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

``variables``
   **Ruby Type:** Hash

   A Hash of variables that are passed into a Ruby template file.

   .. tag template_partials_variables_attribute

   The ``variables`` property of the **template** resource can be used to reference a partial template file by using a Hash. For example:

   .. code-block:: ruby

       template '/file/name.txt' do
         variables partials: {
           'partial_name_1.txt.erb' => 'message',
           'partial_name_2.txt.erb' => 'message',
           'partial_name_3.txt.erb' => 'message'
         }
       end

   where each of the partial template files can then be combined using normal Ruby template patterns within a template file, such as:

   .. code-block:: ruby

      <% @partials.each do |partial, message| %>
        Here is <%= partial %>
        <%= render partial, :variables => {:message => message} %>
      <% end %>

   .. end_tag

``verify``
   **Ruby Types:** String, Block

   A block or a string that returns ``true`` or ``false``. A string, when ``true`` is executed as a system command.

   .. tag resource_template_attributes_verify

   A block is arbitrary Ruby defined within the resource block by using the ``verify`` property. When a block is ``true``, the chef-client will continue to update the file as appropriate.

   For example, this should return ``true``:

   .. code-block:: ruby

      template '/tmp/baz' do
        verify { 1 == 1 }
      end

   This should return ``true``:

   .. code-block:: ruby

      template '/etc/nginx.conf' do
        verify 'nginx -t -c %{path}'
      end

   .. warning:: For releases of the chef-client prior to 12.5 (chef-client 12.4 and earlier) the correct syntax is:

      .. code-block:: ruby

         template '/etc/nginx.conf' do
           verify 'nginx -t -c %{file}'
         end

      See GitHub issues https://github.com/chef/chef/issues/3232 and https://github.com/chef/chef/pull/3693 for more information about these differences.

   This should return ``true``:

   .. code-block:: ruby

      template '/tmp/bar' do
        verify { 1 == 1}
      end

   And this should return ``true``:

   .. code-block:: ruby

      template '/tmp/foo' do
        verify do |path|
          true
        end
      end

   Whereas, this should return ``false``:

   .. code-block:: ruby

      template '/tmp/turtle' do
        verify '/usr/bin/false'
      end

   If a string or a block return ``false``, the chef-client run will stop and an error is returned.

   .. end_tag

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

Using Templates
=====================================================
.. tag template_requirements

To use a template, two things must happen:

#. A template resource must be added to a recipe
#. An Embedded Ruby (ERB) template must be added to a cookbook

For example, the following template file and template resource settings can be used to manage a configuration file named ``/etc/sudoers``. Within a cookbook that uses sudo, the following resource could be added to ``/recipes/default.rb``:

.. code-block:: ruby

   template '/etc/sudoers' do
     source 'sudoers.erb'
     mode '0440'
     owner 'root'
     group 'root'
     variables({
       sudoers_groups: node['authorization']['sudo']['groups'],
       sudoers_users: node['authorization']['sudo']['users']
     })
   end

And then create a template called ``sudoers.erb`` and save it to ``templates/default/sudoers.erb``:

.. code-block:: ruby

   #
   # /etc/sudoers
   #
   # Generated by Chef for <%= node['fqdn'] %>
   #

   Defaults        !lecture,tty_tickets,!fqdn

   # User privilege specification
   root          ALL=(ALL) ALL

   <% @sudoers_users.each do |user| -%>
   <%= user %>   ALL=(ALL) <%= "NOPASSWD:" if @passwordless %>ALL
   <% end -%>

   # Members of the sysadmin group may gain root privileges
   %sysadmin     ALL=(ALL) <%= "NOPASSWD:" if @passwordless %>ALL

   <% @sudoers_groups.each do |group| -%>
   # Members of the group '<%= group %>' may gain root privileges
   %<%= group %> ALL=(ALL) <%= "NOPASSWD:" if @passwordless %>ALL
   <% end -%>

And then set the default attributes in ``attributes/default.rb``:

.. code-block:: ruby

   default['authorization']['sudo']['groups'] = [ 'sysadmin', 'wheel', 'admin' ]
   default['authorization']['sudo']['users']  = [ 'jerry', 'greg']

.. end_tag

File Specificity
-----------------------------------------------------
.. tag template_specificity

A cookbook is frequently designed to work across many platforms and is often required to distribute a specific template to a specific platform. A cookbook can be designed to support the distribution of templates across platforms, while ensuring that the correct template ends up on each system.

.. end_tag

.. tag template_specificity_pattern

The pattern for template specificity depends on two things: the lookup path and the source. The first pattern that matches is used:

#. /host-$fqdn/$source
#. /$platform-$platform_version/$source
#. /$platform/$source
#. /default/$source
#. /$source

Use an array with the ``source`` property to define an explicit lookup path. For example:

.. code-block:: ruby

   template '/test' do
     source ["#{node.chef_environment}.erb", 'default.erb']
   end

The following example emulates the entire file specificity pattern by defining it as an explicit path:

.. code-block:: ruby

   template '/test' do
     source %W{
       host-#{node['fqdn']}/test.erb
       #{node['platform']}-#{node['platform_version']}/test.erb
       #{node['platform']}/test.erb
       default/test.erb
     }
   end

.. end_tag

.. tag template_specificity_example

A cookbook may have a ``/templates`` directory structure like this:

.. code-block:: ruby

   /templates/
     windows-6.2
     windows-6.1
     windows-6.0
     windows
     default

and a resource that looks something like the following:

.. code-block:: ruby

   template 'C:\path\to\file\text_file.txt' do
     source 'text_file.txt'
     mode '0755'
     owner 'root'
     group 'root'
   end

This resource would be matched in the same order as the ``/templates`` directory structure. For a node named ``host-node-desktop`` that is running Windows 7, the second item would be the matching item and the location:

.. code-block:: ruby

   /templates
     windows-6.2/text_file.txt
     windows-6.1/text_file.txt
     windows-6.0/text_file.txt
     windows/text_file.txt
     default/text_file.txt

.. end_tag

Changed in Chef Client 12.0.

Helpers
-----------------------------------------------------
A helper is a method or a module that can be used to extend a template. There are three approaches:

* An inline helper method
* An inline helper module
* A cookbook library module

Use the ``helper`` attribute in a recipe to define an inline helper method. Use the ``helpers`` attribute to define an inline helper module or a cookbook library module.

Inline Methods
+++++++++++++++++++++++++++++++++++++++++++++++++++++
A template helper method is always defined inline on a per-resource basis. A simple example:

.. code-block:: ruby

   template '/path' do
     helper(:hello_world) { 'hello world' }
   end

Another way to define an inline helper method is to reference a node object so that repeated calls to one (or more) cookbook attributes can be done efficiently:

.. code-block:: ruby

   template '/path' do
     helper(:app) { node['app'] }
   end

An inline helper method can also take arguments:

.. code-block:: ruby

   template '/path' do
     helper(:app_conf) { |setting| node['app'][setting] }
   end

Once declared, a template can then use the helper methods to build a file. For example:

.. code-block:: ruby

   Say hello: <%= hello_world %>

or:

.. code-block:: ruby

   node['app']['listen_port'] is: <%= app['listen_port'] %>

or:

.. code-block:: ruby

   node['app']['log_location'] is: <%= app_conf('log_location') %>

Inline Modules
+++++++++++++++++++++++++++++++++++++++++++++++++++++
A template helper module can be defined inline on a per-resource basis. This approach can be useful when a template requires more complex information. For example:

.. code-block:: ruby

   template '/path' do
     helpers do

       def hello_world
         'hello world'
       end

       def app
         node['app']
       end

       def app_conf(setting)
         node['app']['setting']
       end

     end
   end

where the ``hello_world``, ``app``, and ``app_conf(setting)`` methods comprise the module that extends a template.

Library Modules
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_template_library_module

A template helper module can be defined in a library. This is useful when extensions need to be reused across recipes or to make it easier to manage code that would otherwise be defined inline on a per-recipe basis.

.. code-block:: ruby

   template '/path/to/template.erb' do
     helpers(MyHelperModule)
   end

.. end_tag

Host Notation
-----------------------------------------------------
.. tag template_host_notation

The naming of folders within cookbook directories must literally match the host notation used for template specificity matching. For example, if a host is named ``foo.example.com``, then the folder must be named ``host-foo.example.com``.

.. end_tag

Partial Templates
-----------------------------------------------------
.. tag template_partials

A template can be built in a way that allows it to contain references to one (or more) smaller template files. (These smaller template files are also referred to as partials.) A partial can be referenced from a template file in one of the following ways:

* By using the ``render`` method in the template file
* By using the **template** resource and the ``variables`` property.

.. end_tag

render Method
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag template_partials_render_method

Use the ``render`` method in a template to reference a partial template file:

.. code-block:: ruby

   <%= render "partial_name.txt.erb", :option => {} %>

where ``partial_name`` is the name of the partial template file and ``:option`` is one (or more) of the following:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Option
     - Description
   * - ``:cookbook``
     - By default, a partial template file is assumed to be located in the cookbook that contains the top-level template. Use this option to specify the path to a different cookbook
   * - ``:local``
     - Indicates that the name of the partial template file should be interpreted as a path to a file in the local file system or looked up in a cookbook using the normal rules for template files. Set to ``true`` to interpret as a path to a file in the local file system and to ``false`` to use the normal rules for template files
   * - ``:source``
     - By default, a partial template file is identified by its file name. Use this option to specify a different name or a local path to use (instead of the name of the partial template file)
   * - ``:variables``
     - A hash of ``variable_name => value`` that will be made available to the partial template file. When this option is used, any variables that are defined in the top-level template that are required by the partial template file must have them defined explicitly using this option

For example:

.. code-block:: ruby

   <%= render "simple.txt.erb", :variables => {:user => Etc.getlogin }, :local => true %>

.. end_tag

Transfer Frequency
-----------------------------------------------------
.. tag template_transfer_frequency

The chef-client caches a template when it is first requested. On each subsequent request for that template, the chef-client compares that request to the template located on the Chef server. If the templates are the same, no transfer occurs.

.. end_tag

Variables
-----------------------------------------------------
.. tag template_variables

A template is an Embedded Ruby (ERB) template. An Embedded Ruby (ERB) template allows Ruby code to be embedded inside a text file within specially formatted tags. Ruby code can be embedded using expressions and statements. An expression is delimited by ``<%=`` and ``%>``. For example:

.. code-block:: ruby

   <%= "my name is #{$ruby}" %>

A statement is delimited by a modifier, such as ``if``, ``elseif``, and ``else``. For example:

.. code-block:: ruby

   if false
      # this won't happen
   elsif nil
      # this won't either
   else
      # code here will run though
   end

Using a Ruby expression is the most common approach for defining template variables because this is how all variables that are sent to a template are referenced. Whenever a template needs to use an ``each``, ``if``, or ``end``, use a Ruby statement.

When a template is rendered, Ruby expressions and statements are evaluated by the chef-client. The variables listed in the **template** resource's ``variables`` parameter and in the node object are evaluated. The chef-client then passes these variables to the template, where they will be accessible as instance variables within the template. The node object can be accessed just as if it were part of a recipe, using the same syntax.

For example, a simple template resource like this:

.. code-block:: ruby

   node['fqdn'] = 'latte'
   template '/tmp/foo' do
     source 'foo.erb'
     variables({
       :x_men => 'are keen'
     })
   end

And a simple Embedded Ruby (ERB) template like this:

.. code-block:: ruby

   The node <%= node[:fqdn] %> thinks the x-men <%= @x_men %>

Would render something like:

.. code-block:: ruby

   The node latte thinks the x-men are keen

Even though this is a very simple example, the full capabilities of Ruby can be used to tackle even the most complex and demanding template requirements.

.. end_tag

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

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
