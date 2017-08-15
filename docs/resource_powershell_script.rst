=====================================================
powershell_script
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_powershell_script.rst>`__

.. tag resource_powershell_script_summary

Use the **powershell_script** resource to execute a script using the Windows PowerShell interpreter, much like how the **script** and **script**-based resources---**bash**, **csh**, **perl**, **python**, and **ruby**---are used. The **powershell_script** is specific to the Microsoft Windows platform and the Windows PowerShell interpreter.

The **powershell_script** resource creates and executes a temporary file (similar to how the **script** resource behaves), rather than running the command inline. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

.. end_tag

Changed in 12.19 to support windows alternate user identity in execute resources

Syntax
=====================================================
.. tag resource_powershell_script_syntax

A **powershell_script** resource block executes a batch script using the Windows PowerShell interpreter. For example, writing to an interpolated path:

.. code-block:: ruby

   powershell_script 'write-to-interpolated-path' do
     code <<-EOH
     $stream = [System.IO.StreamWriter] "#{Chef::Config[:file_cache_path]}/powershell-test.txt"
     $stream.WriteLine("In #{Chef::Config[:file_cache_path]}...word.")
     $stream.close()
     EOH
   end

The full syntax for all of the properties that are available to the **powershell_script** resource is:

.. code-block:: ruby

   powershell_script 'name' do
     architecture               Symbol
     code                       String
     command                    String, Array
     convert_boolean_return     TrueClass, FalseClass
     creates                    String
     cwd                        String
     environment                Hash
     flags                      String
     group                      String, Integer
     guard_interpreter          Symbol
     interpreter                String
     notifies                   # see description
     provider                   Chef::Provider::PowershellScript
     returns                    Integer, Array
     subscribes                 # see description
     timeout                    Integer, Float
     user                       String
     password                   String
     domain                     String
     action                     Symbol # defaults to :run if not specified
   end

where

* ``powershell_script`` is the resource
* ``name`` is the name of the resource block
* ``command`` is the command to be run and ``cwd`` is the location from which the command is run
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``architecture``, ``code``, ``command``, ``convert_boolean_return``, ``creates``, ``cwd``, ``environment``, ``flags``, ``group``, ``guard_interpreter``, ``interpreter``, ``provider``, ``returns``,``timeout``, ``user``, ``password`` and ``domain`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
=====================================================
.. tag resource_powershell_script_actions

This resource has the following actions:

``:nothing``
   Inherited from **execute** resource. Prevent a command from running. This action is used to specify that a command is run only when another resource notifies it.

``:run``
   Default. Run the script.

.. end_tag

Properties
=====================================================
.. tag resource_powershell_script_attributes

This resource has the following properties:

``architecture``
   **Ruby Type:** Symbol

   The architecture of the process under which a script is executed. If a value is not provided, the chef-client defaults to the correct value for the architecture, as determined by Ohai. An exception is raised when anything other than ``:i386`` is specified for a 32-bit process. Possible values: ``:i386`` (for 32-bit processes) and ``:x86_64`` (for 64-bit processes).

``code``
   **Ruby Type:** String

   A quoted (" ") string of code to be executed.

``command``
   **Ruby Types:** String, Array

   The name of the command to be executed. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``convert_boolean_return``
   **Ruby Types:** TrueClass, FalseClass

   Return ``0`` if the last line of a command is evaluated to be true or to return ``1`` if the last line is evaluated to be false. Default value: ``false``.

   When the ``guard_intrepreter`` common attribute is set to ``:powershell_script``, a string command will be evaluated as if this value were set to ``true``. This is because the behavior of this attribute is similar to the value of the ``"$?"`` expression common in UNIX interpreters. For example, this:

   .. code-block:: ruby

      powershell_script 'make_safe_backup' do
        guard_interpreter :powershell_script
        code 'cp ~/data/nodes.json ~/data/nodes.bak'
        not_if 'test-path ~/data/nodes.bak'
      end

   is similar to:

   .. code-block:: ruby

      bash 'make_safe_backup' do
        code 'cp ~/data/nodes.json ~/data/nodes.bak'
        not_if 'test -e ~/data/nodes.bak'
      end

``creates``
   **Ruby Type:** String

   Inherited from **execute** resource. Prevent a command from creating a file when that file already exists.

``cwd``
   **Ruby Type:** String

   Inherited from **execute** resource. The current working directory from which a command is run.

``environment``
   **Ruby Type:** Hash

   Inherited from **execute** resource. A Hash of environment variables in the form of ``({"ENV_VARIABLE" => "VALUE"})``. (These variables must exist for a command to be run successfully.)

``flags``
   **Ruby Type:** String

   A string that is passed to the Windows PowerShell command. Default value: ``-NoLogo, -NonInteractive, -NoProfile, -ExecutionPolicy RemoteSigned, -InputFormat None, -File``.

``group``
   **Ruby Types:** String, Integer

   Inherited from **execute** resource. The group name or group ID that must be changed before running a command.

``guard_interpreter``
   **Ruby Type:** Symbol

   Default value: ``:powershell_script``. When this property is set to ``:powershell_script``, the 64-bit version of the Windows PowerShell shell will be used to evaluate strings values for the ``not_if`` and ``only_if`` properties. Set this value to ``:default`` to use the 32-bit version of the cmd.exe shell.

   Changed in Chef Client 12.0 to default to the specified property.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``interpreter``
   **Ruby Type:** String

   The script interpreter to use during code execution. Changing the default value of this property is not supported.

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

``returns``
   **Ruby Types:** Integer, Array

   Inherited from **execute** resource. The return value for a command. This may be an array of accepted values. An exception is raised when the return value(s) do not match. Default value: ``0``.

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

``timeout``
   **Ruby Types:** Integer, Float

   Inherited from **execute** resource. The amount of time (in seconds) a command is to wait before timing out. Default value: ``3600``.

``user``
   **Ruby Types:** String

   The user name of the user identity with which to launch the new process. Default value: `nil`. The user name may optionally be specifed with a domain, i.e. `domain\user` or `user@my.dns.domain.com` via Universal Principal Name (UPN)format. It can also be specified without a domain simply as user if the domain is instead specified using the `domain` attribute. On Windows only, if this property is specified, the `password` property must be specified.

``password``
   **Ruby Types:** String

   *Windows only*: The password of the user specified by the `user` property.
   Default value: `nil`. This property is mandatory if `user` is specified on Windows and may only be specified if `user` is specified. The `sensitive` property for this resource will automatically be set to true if password is specified.

``domain``
   **Ruby Types:** String

   *Windows only*: The domain of the user user specified by the `user` property.
   Default value: `nil`. If not specified, the user name and password specified by the `user` and `password` properties will be used to resolve that user against the domain in which the system running Chef client is joined, or if that system is not joined to a domain it will resolve the user as a local account on that system. An alternative way to specify the domain is to leave this property unspecified and specify the domain as part of the `user` property.

.. end_tag

Guards
-----------------------------------------------------
.. tag resources_common_guards

A guard property can be used to evaluate the state of a node during the execution phase of the chef-client run. Based on the results of this evaluation, a guard property is then used to tell the chef-client if it should continue executing a resource. A guard property accepts either a string value or a Ruby block value:

* A string is executed as a shell command. If the command returns ``0``, the guard is applied. If the command returns any other value, then the guard property is not applied. String guards in a **powershell_script** run Windows PowerShell commands and may return ``true`` in addition to ``0``.
* A block is executed as Ruby code that must return either ``true`` or ``false``. If the block returns ``true``, the guard property is applied. If the block returns ``false``, the guard property is not applied.

A guard property is useful for ensuring that a resource is idempotent by allowing that resource to test for the desired state as it is being executed, and then if the desired state is present, for the chef-client to do nothing.

.. end_tag

**Attributes**

.. tag resources_common_guards_attributes

The following properties can be used to define a guard that is evaluated during the execution phase of the chef-client run:

``not_if``
   Prevent a resource from executing when the condition returns ``true``.

``only_if``
   Allow a resource to execute only if the condition returns ``true``.

.. end_tag

**Arguments**

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

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

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

**Run a command as an alternate user**

.. tag resource_batch_alternate_user

*Note*: When Chef is running as a service, this feature requires that the user that Chef runs as has 'SeAssignPrimaryTokenPrivilege' (aka 'SE_ASSIGNPRIMARYTOKEN_NAME') user right. By default only LocalSystem and NetworkService have this right when running as a service. This is necessary even if the user is an Administrator.

This right can be added and checked in a recipe using this example:

.. code-block:: ruby

    # Add 'SeAssignPrimaryTokenPrivilege' for the user
    Chef::ReservedNames::Win32::Security.add_account_right('<user>', 'SeAssignPrimaryTokenPrivilege')

    # Check if the user has 'SeAssignPrimaryTokenPrivilege' rights
    Chef::ReservedNames::Win32::Security.get_account_right('<user>').include?('SeAssignPrimaryTokenPrivilege')

The following example shows how to run ``mkdir test_dir`` from a chef-client run as an alternate user.

.. code-block:: ruby

   # Passing only username and password
   batch 'mkdir test_dir' do
    code "mkdir test_dir"
    cwd Chef::Config[:file_cache_path]
    user "username"
    password "password"
   end

   # Passing username and domain
   batch 'mkdir test_dir' do
    code "mkdir test_dir"
    cwd Chef::Config[:file_cache_path]
    domain "domain"
    user "username"
    password "password"
   end

   # Passing username = 'domain-name\\username'. No domain is passed
   batch 'mkdir test_dir' do
    code "mkdir test_dir"
    cwd Chef::Config[:file_cache_path]
    user "domain-name\\username"
    password "password"
   end

   # Passing username = 'username@domain-name'. No domain is passed
   batch 'mkdir test_dir' do
    code "mkdir test_dir"
    cwd Chef::Config[:file_cache_path]
    user "username@domain-name"
    password "password"
   end

.. end_tag

New in Chef Client 12.19.
