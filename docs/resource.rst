=====================================================
About Resources
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource.rst>`__

.. note:: If you want to see all of the information about resources in a single document, see: |url docs_resources_all|. Keep reading this page for topics about individual resources.

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

Resources Syntax
=====================================================
A resource is a Ruby block with four components: a type, a name, one (or more) properties (with values), and one (or more) actions. The syntax for a resource is like this:

.. code-block:: ruby

   type 'name' do
      attribute 'value'
      action :type_of_action
   end

Every resource has its own set of actions and properties. Most properties have default values. Some properties are available to all resources, for example those used to send notifications to other resources and guards that help ensure that some resources are idempotent.

For example, a resource that is used to install a tar.gz package for version 1.16.1 may look something like this:

.. code-block:: ruby

   package 'tar' do
     version '1.16.1'
     action :install
   end

All actions have a default value. Only non-default behaviors of actions and properties need to be specified. For example, the **package** resource's default action is ``:install`` and the name of the package defaults to the ``name`` of the resource. Therefore, it is possible to write a resource block that installs the latest tar.gz package like this:

.. code-block:: ruby

   package 'tar'

and a resource block that installs a tar.gz package for version 1.6.1 like this:

.. code-block:: ruby

   package 'tar' do
     version '1.16.1'
   end

In both cases, the chef-client will use the default action (``:install``) to install the ``tar`` package.

Common Functionality
=====================================================
.. tag resources_common_intro

All resources (including custom resources) share a set of common actions, properties, conditional executions, notifications, and relative path options.

.. end_tag

.. list-table::
   :widths: 160 440
   :header-rows: 1

   * - Common Item
     - Description
   * - :ref:`resource_common_actions`
     - The ``:nothing`` action can be used with any resource or custom resource.
   * - :ref:`resource_common_properties`
     - The ``ignore_failure``, ``provider``, ``retries``, ``retry_delay``, and ``supports`` properties can be used with any resource or custom resources.
   * - :ref:`resource_common_guards`
     - The ``not_if`` and ``only_if`` conditional executions can be used to put additional guards around certain resources so that they are only run when the condition is met.
   * - :ref:`resource_common_guard_interpreters`
     - Evaluate a string command using a **script**-based resource: **bash**, **csh**, **perl**, **powershell_script**, **python**, or **ruby**.
   * - :ref:`resource_common_notifications`
     - The ``notifies`` and ``subscribes`` notifications can be used with any resource.
   * - :ref:`resource_common_relative_paths`
     - The ``#{ENV['HOME']}`` relative path can be used with any resource.
   * - :ref:`resource_common_windows_file_security`
     - The **template**, **file**, **remote_file**, **cookbook_file**, **directory**, and **remote_directory** resources support the use of inheritance and access control lists (ACLs) within recipes.
   * - :ref:`resource_common_run_in_compile_phase`
     - Sometimes a resource needs to be run before every other resource or after all resources have been added to the resource collection.

Resources
=====================================================
The following resources are platform resources (i.e. "are available from the chef-client directly and do not require a cookbook"):

.. list-table::
   :widths: 150 450
   :header-rows: 1

   * - Resource
     - Description
   * - :doc:`apt_package </resource_apt_package>`
     - .. tag resource_package_apt

       Use the **apt_package** resource to manage packages for the Debian and Ubuntu platforms.

       .. end_tag

   * - :doc:`bash </resource_bash>`
     - .. tag resource_script_bash

       Use the **bash** resource to execute scripts using the Bash interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

       .. note:: The **bash** script resource (which is based on the **script** resource) is different from the **ruby_block** resource because Ruby code that is run with this resource is created as a temporary file and executed like other script resources, rather than run inline.

       .. end_tag

   * - :doc:`batch </resource_batch>`
     - .. tag resource_batch_summary

       Use the **batch** resource to execute a batch script using the cmd.exe interpreter. The **batch** resource creates and executes a temporary file (similar to how the **script** resource behaves), rather than running the command inline. This resource inherits actions (``:run`` and ``:nothing``) and properties (``creates``, ``cwd``, ``environment``, ``group``, ``path``, ``timeout``, and ``user``) from the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

       .. end_tag

   * - :doc:`bff_package </resource_bff_package>`
     - .. tag resource_package_bff

       Use the **bff_package** resource to manage packages for the AIX platform using the installp utility. When a package is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources. New in Chef Client 12.0.

       .. note:: A Backup File Format (BFF) package may not have a ``.bff`` file extension. The chef-client will still identify the correct provider to use based on the platform, regardless of the file extension.

       .. end_tag

   * - :doc:`breakpoint </resource_breakpoint>`
     - .. tag resource_breakpoint_summary

       Use the **breakpoint** resource to add breakpoints to recipes. Run the chef-shell in chef-client mode, and then use those breakpoints to debug recipes. Breakpoints are ignored by the chef-client during an actual chef-client run. That said, breakpoints are typically used to debug recipes only when running them in a non-production environment, after which they are removed from those recipes before the parent cookbook is uploaded to the Chef server.

       .. end_tag

   * - :doc:`chef_gem </resource_chef_gem>`
     - .. tag resource_package_chef_gem

       Use the **chef_gem** resource to install a gem only for the instance of Ruby that is dedicated to the chef-client. When a gem is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources.

       The **chef_gem** resource works with all of the same properties and options as the **gem_package** resource, but does not accept the ``gem_binary`` property because it always uses the ``CurrentGemEnvironment`` under which the chef-client is running. In addition to performing actions similar to the **gem_package** resource, the **chef_gem** resource does the following:

       * Runs its actions immediately, before convergence, allowing a gem to be used in a recipe immediately after it is installed
       * Runs ``Gem.clear_paths`` after the action, ensuring that gem is aware of changes so that it can be required immediately after it is installed

       .. end_tag

   * - :doc:`cookbook_file </resource_cookbook_file>`
     - .. tag resource_cookbook_file_summary

       Use the **cookbook_file** resource to transfer files from a sub-directory of ``COOKBOOK_NAME/files/`` to a specified path located on a host that is running the chef-client. The file is selected according to file specificity, which allows different source files to be used based on the hostname, host platform (operating system, distro, or as appropriate), or platform version. Files that are located in the ``COOKBOOK_NAME/files/default`` sub-directory may be used on any platform.

       .. end_tag

   * - :doc:`cron </resource_cron>`
     - .. tag resource_cron_summary

       Use the **cron** resource to manage cron entries for time-based job scheduling. Properties for a schedule will default to ``*`` if not provided. The **cron** resource requires access to a crontab program, typically cron.

       .. warning:: The **cron** resource should only be used to modify an entry in a crontab file. Use the **cookbook_file** or **template** resources to add a crontab file to the cron.d directory. The ``cron_d`` lightweight resource (found in the `cron <https://github.com/chef-cookbooks/cron>`__ cookbook) is another option for managing crontab files.

       .. end_tag

   * - :doc:`csh </resource_csh>`
     - .. tag resource_script_csh

       Use the **csh** resource to execute scripts using the csh interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

       .. note:: The **csh** script resource (which is based on the **script** resource) is different from the **ruby_block** resource because Ruby code that is run with this resource is created as a temporary file and executed like other script resources, rather than run inline.

       .. end_tag

   * - :doc:`deploy </resource_deploy>`
     - .. tag resource_deploy_summary

       Use the **deploy** resource to manage and control deployments. This is a popular resource, but is also complex, having the most properties, multiple providers, the added complexity of callbacks, plus four attributes that support layout modifications from within a recipe.

       .. end_tag

   * - :doc:`directory </resource_directory>`
     - .. tag resource_directory_summary

       Use the **directory** resource to manage a directory, which is a hierarchy of folders that comprises all of the information stored on a computer. The root directory is the top-level, under which the rest of the directory is organized. The **directory** resource uses the ``name`` property to specify the path to a location in a directory. Typically, permission to access that location in the directory is required.

       .. end_tag

   * - :doc:`dpkg_package </resource_dpkg_package>`
     - .. tag resource_package_dpkg

       Use the **dpkg_package** resource to manage packages for the dpkg platform. When a package is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources.

       .. end_tag

   * - :doc:`dsc_script </resource_dsc_script>`
     - .. tag resource_dsc_script_summary

       Many DSC resources are comparable to built-in Chef resources. For example, both DSC and Chef have **file**, **package**, and **service** resources. The **dsc_script** resource is most useful for those DSC resources that do not have a direct comparison to a resource in Chef, such as the ``Archive`` resource, a custom DSC resource, an existing DSC script that performs an important task, and so on. Use the **dsc_script** resource to embed the code that defines a DSC configuration directly within a Chef recipe.

       .. end_tag

   * - :doc:`env </resource_env>`
     - .. tag resource_env_summary

       Use the **env** resource to manage environment keys in Microsoft Windows. After an environment key is set, Microsoft Windows must be restarted before the environment key will be available to the Task Scheduler.

       .. end_tag

   * - :doc:`erl_call </resource_erlang_call>`
     - .. tag resource_erlang_call_summary

       Use the **erl_call** resource to connect to a node located within a distributed Erlang system. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

       .. end_tag

   * - :doc:`execute </resource_execute>`
     - .. tag resource_execute_summary

       Use the **execute** resource to execute a single command. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

       .. end_tag

   * - :doc:`file </resource_file>`
     - .. tag resource_file_summary

       Use the **file** resource to manage files directly on a node.

       .. end_tag

   * - :doc:`freebsd_package </resource_freebsd_package>`
     - .. tag resource_package_freebsd

       Use the **freebsd_package** resource to manage packages for the FreeBSD platform.

       .. end_tag

   * - :doc:`gem_package </resource_gem_package>`
     - .. tag resource_package_gem

       Use the **gem_package** resource to manage gem packages that are only included in recipes. When a package is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources.

       .. end_tag

   * - :doc:`git </resource_git>`
     - .. tag resource_scm_git

       Use the **git** resource to manage source control resources that exist in a git repository. git version 1.6.5 (or higher) is required to use all of the functionality in the **git** resource.

       .. end_tag

   * - :doc:`group </resource_group>`
     - .. tag resource_group_summary

       Use the **group** resource to manage a local group.

       .. end_tag

   * - :doc:`homebrew_package </resource_homebrew_package>`
     - .. tag resource_package_homebrew

       Use the **homebrew_package** resource to manage packages for the macOS platform.

       .. end_tag

   * - :doc:`http_request </resource_http_request>`
     - .. tag resource_http_request_summary

       Use the **http_request** resource to send an HTTP request (``GET``, ``PUT``, ``POST``, ``DELETE``, ``HEAD``, or ``OPTIONS``) with an arbitrary message. This resource is often useful when custom callbacks are necessary.

       .. end_tag

   * - :doc:`ifconfig </resource_ifconfig>`
     - .. tag resource_ifconfig_summary

       Use the **ifconfig** resource to manage interfaces.

       .. end_tag

   * - :doc:`ips_package </resource_ips_package>`
     - .. tag resource_package_ips

       Use the **ips_package** resource to manage packages (using Image Packaging System (IPS)) on the Solaris 11 platform.

       .. end_tag

   * - :doc:`ksh </resource_ksh>`
     - .. tag resource_script_ksh

       Use the **ksh** resource to execute scripts using the Korn shell (ksh) interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence. New in Chef Client 12.6.

       .. note:: The **ksh** script resource (which is based on the **script** resource) is different from the **ruby_block** resource because Ruby code that is run with this resource is created as a temporary file and executed like other script resources, rather than run inline.

       .. end_tag

   * - :doc:`link </resource_link>`
     - .. tag resource_link_summary

       Use the **link** resource to create symbolic or hard links.

       .. end_tag

   * - :doc:`log </resource_log>`
     - .. tag resource_log_summary

       Use the **log** resource to create log entries. The **log** resource behaves like any other resource: built into the resource collection during the compile phase, and then run during the execution phase. (To create a log entry that is not built into the resource collection, use ``Chef::Log`` instead of the **log** resource.)

       .. note:: By default, every log resource that executes will count as an updated resource in the updated resource count at the end of a Chef run. You can disable this behavior by adding ``count_log_resource_updates false`` to your Chef ``client.rb`` configuration file.

       .. end_tag

   * - :doc:`macports_package </resource_macports_package>`
     - .. tag resource_package_macports

       Use the **macports_package** resource to manage packages for the macOS platform.

       .. end_tag

   * - :doc:`mdadm </resource_mdadm>`
     - .. tag resource_mdadm_summary

       Use the **mdadm** resource to manage RAID devices in a Linux environment using the mdadm utility. The **mdadm** provider will create and assemble an array, but it will not create the config file that is used to persist the array upon reboot. If the config file is required, it must be done by specifying a template with the correct array layout, and then by using the **mount** provider to create a file systems table (fstab) entry.

       .. end_tag

   * - :doc:`mount </resource_mount>`
     - .. tag resource_mount_summary

       Use the **mount** resource to manage a mounted file system.

       .. end_tag

   * - :doc:`ohai </resource_ohai>`
     - .. tag resource_ohai_summary

       Use the **ohai** resource to reload the Ohai configuration on a node. This allows recipes that change system attributes (like a recipe that adds a user) to refer to those attributes later on during the chef-client run.

       .. end_tag

   * - :doc:`package </resource_package>`
     - .. tag resource_package_summary

       Use the **package** resource to manage packages. When the package is installed from a local file (such as with RubyGems, dpkg, or RPM Package Manager), the file must be added to the node using the **remote_file** or **cookbook_file** resources.

       .. end_tag

   * - :doc:`pacman_package </resource_pacman_package>`
     - .. tag resource_package_pacman

       Use the **pacman_package** resource to manage packages (using pacman) on the Arch Linux platform.

       .. end_tag

   * - :doc:`perl </resource_perl>`
     - .. tag resource_script_perl

       Use the **perl** resource to execute scripts using the Perl interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

       .. note:: The **perl** script resource (which is based on the **script** resource) is different from the **ruby_block** resource because Ruby code that is run with this resource is created as a temporary file and executed like other script resources, rather than run inline.

       .. end_tag

   * - :doc:`portage_package </resource_portage_package>`
     - .. tag resource_package_portage

       Use the **portage_package** resource to manage packages for the Gentoo platform.

       .. end_tag

   * - :doc:`powershell_script </resource_powershell_script>`
     - .. tag resource_powershell_script_summary

       Use the **powershell_script** resource to execute a script using the Windows PowerShell interpreter, much like how the **script** and **script**-based resources---**bash**, **csh**, **perl**, **python**, and **ruby**---are used. The **powershell_script** is specific to the Microsoft Windows platform and the Windows PowerShell interpreter.

       The **powershell_script** resource creates and executes a temporary file (similar to how the **script** resource behaves), rather than running the command inline. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

       .. end_tag

   * - :doc:`python </resource_python>`
     - .. tag resource_script_python

       Use the **python** resource to execute scripts using the Python interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

       .. note:: The **python** script resource (which is based on the **script** resource) is different from the **ruby_block** resource because Ruby code that is run with this resource is created as a temporary file and executed like other script resources, rather than run inline.

       .. end_tag

   * - :doc:`reboot </resource_reboot>`
     - .. tag resource_service_reboot

       Use the **reboot** resource to reboot a node, a necessary step with some installations on certain platforms. This resource is supported for use on the Microsoft Windows, macOS, and Linux platforms.  New in Chef Client 12.0.

       .. end_tag

   * - :doc:`registry_key </resource_registry_key>`
     - .. tag resource_registry_key_summary

       Use the **registry_key** resource to create and delete registry keys in Microsoft Windows.

       .. end_tag

   * - :doc:`remote_directory </resource_remote_directory>`
     - .. tag resource_remote_directory_summary

       Use the **remote_directory** resource to incrementally transfer a directory from a cookbook to a node. The directory that is copied from the cookbook should be located under ``COOKBOOK_NAME/files/default/REMOTE_DIRECTORY``. The **remote_directory** resource will obey file specificity.

       .. end_tag

   * - :doc:`remote_file </resource_remote_file>`
     - .. tag resource_remote_file_summary

       Use the **remote_file** resource to transfer a file from a remote location using file specificity. This resource is similar to the **file** resource.

       .. end_tag

   * - :doc:`route </resource_route>`
     - .. tag resource_route_summary

       Use the **route** resource to manage the system routing table in a Linux environment.

       .. end_tag

   * - :doc:`rpm_package </resource_rpm_package>`
     - .. tag resource_package_rpm

       Use the **rpm_package** resource to manage packages for the RPM Package Manager platform.

       .. end_tag

   * - :doc:`ruby </resource_ruby>`
     - .. tag resource_script_ruby

       Use the **ruby** resource to execute scripts using the Ruby interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

       .. note:: The **ruby** script resource (which is based on the **script** resource) is different from the **ruby_block** resource because Ruby code that is run with this resource is created as a temporary file and executed like other script resources, rather than run inline.

       .. end_tag

   * - :doc:`ruby_block </resource_ruby_block>`
     - .. tag resource_ruby_block_summary

       Use the **ruby_block** resource to execute Ruby code during a chef-client run. Ruby code in the ``ruby_block`` resource is evaluated with other resources during convergence, whereas Ruby code outside of a ``ruby_block`` resource is evaluated before other resources, as the recipe is compiled.

       .. end_tag

   * - :doc:`script </resource_script>`
     - .. tag resource_script_summary

       Use the **script** resource to execute scripts using a specified interpreter, such as Bash, csh, Perl, Python, or Ruby. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence.

       .. note:: The **script** resource is different from the **ruby_block** resource because Ruby code that is run with this resource is created as a temporary file and executed like other script resources, rather than run inline.

       .. end_tag

   * - :doc:`service </resource_service>`
     - .. tag resource_service_summary

       Use the **service** resource to manage a service.

       .. end_tag

   * - :doc:`smart_os_package </resource_smartos_package>`
     - .. tag resource_package_smartos

       Use the **smartos_package** resource to manage packages for the SmartOS platform.

       .. end_tag

   * - :doc:`solaris_package </resource_solaris_package>`
     - .. tag resource_package_solaris

       The **solaris_package** resource is used to manage packages for the Solaris platform.

       .. end_tag

   * - :doc:`subversion </resource_subversion>`
     - .. tag resource_scm_subversion

       Use the **subversion** resource to manage source control resources that exist in a Subversion repository.

       .. end_tag

   * - :doc:`template </resource_template>`
     - .. tag resource_template_summary

       Use the **template** resource to manage the contents of a file using an Embedded Ruby (ERB) template by transferring files from a sub-directory of ``COOKBOOK_NAME/templates/`` to a specified path located on a host that is running the chef-client. This resource includes actions and properties from the **file** resource. Template files managed by the **template** resource follow the same file specificity rules as the **remote_file** and **file** resources.

       .. end_tag

   * - :doc:`user </resource_user>`
     - .. tag resource_user_summary

       Use the **user** resource to add users, update existing users, remove users, and to lock/unlock user passwords.

       .. note:: System attributes are collected by Ohai at the start of every chef-client run. By design, the actions available to the **user** resource are processed **after** the start of the chef-client run. This means that system attributes added or modified by the **user** resource during the chef-client run must be reloaded before they can be available to the chef-client. These system attributes can be reloaded in two ways: by picking up the values at the start of the (next) chef-client run or by using the :doc:`ohai resource </resource_ohai>` to reload the system attributes during the current chef-client run.

       .. end_tag

   * - :doc:`windows_package </resource_windows_package>`
     - .. tag resource_package_windows

       Use the **windows_package** resource to manage Microsoft Installer Package (MSI) packages for the Microsoft Windows platform.

       .. end_tag

   * - :doc:`windows_service </resource_windows_service>`
     - .. tag resource_service_windows

       Use the **windows_service** resource to manage a service on the Microsoft Windows platform. New in Chef Client 12.0.

       .. end_tag

   * - :doc:`yum_package </resource_yum>`
     - .. tag resource_package_yum

       Use the **yum_package** resource to install, upgrade, and remove packages with Yum for the Red Hat and CentOS platforms. The **yum_package** resource is able to resolve ``provides`` data for packages much like Yum can do when it is run from the command line. This allows a variety of options for installing packages, like minimum versions, virtual provides, and library names.

       .. end_tag

   * - :doc:`zypper_package </resource_zypper_package>`
     - .. tag resource_package_zypper

       Use the **zypper_package** resource to install, upgrade, and remove packages with Zypper for the SUSE Enterprise and OpenSUSE platforms.

       .. end_tag

In addition, the :doc:`chef_handler </resource_chef_handler>` resource is configured and run using the **chef_handler** cookbook, which is the location in which custom handlers are defined and maintained. Despite being defined in a cookbook (and as a "lightweight resource"), the **chef_handler** resource should otherwise be considered a "platform resource".
