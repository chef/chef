=====================================================
About the Recipe DSL
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/dsl_recipe.rst>`__

.. tag dsl_recipe_summary

The Recipe DSL is a Ruby DSL that is primarily used to declare resources from within a recipe. The Recipe DSL also helps ensure that recipes interact with nodes (and node properties) in the desired manner. Most of the methods in the Recipe DSL are used to find a specific parameter and then tell the chef-client what action(s) to take, based on whether that parameter is present on a node.

.. end_tag

Because the Recipe DSL is a Ruby DSL, then anything that can be done using Ruby can also be done in a recipe, including ``if`` and ``case`` statements, using the ``include?`` Ruby method, including recipes in recipes, and checking for dependencies.

New in Chef Client 12.10 ``declare_resource``, ``delete_resource``, ``edit_resource``, ``find_resource``, ``delete_resource!``, ``edit_resource!`` and ``find_resource!``. New in 12.1, ``control_group`` method added. New in 12.0, ``data_bag``, ``data_bag_item``, ``:filter_result``, ``platform?``, ``shell_out!``, ``shell_out_with_systems_locale``, ``tag``, ``tagged?``, ``untag``.

Use Ruby
=====================================================
Common Ruby techniques can be used with the Recipe DSL methods.

if Statements
-----------------------------------------------------
.. tag ruby_style_basics_statement_if

An ``if`` statement can be used to specify part of a recipe to be used when certain conditions are met. ``else`` and ``elseif`` statements can be used to handle situations where either the initial condition is not met or when there are other possible conditions that can be met. Since this behavior is 100% Ruby, do this in a recipe the same way here as anywhere else.

For example, using an ``if`` statement with the ``platform`` node attribute:

.. code-block:: ruby

   if node['platform'] == 'ubuntu'
     # do ubuntu things
   end

.. future example: step_resource_ruby_block_reload_configuration
.. future example: step_resource_ruby_block_run_specific_blocks_on_specific_platforms
.. future example: step_resource_mount_mysql
.. future example: step_resource_package_install_sudo_configure_etc_sudoers
.. future example: step_resource_ruby_block_if_statement_use_with_platform
.. future example: step_resource_remote_file_transfer_remote_source_changes
.. future example: step_resource_remote_file_use_platform_family
.. future example: step_resource_scm_use_different_branches
.. future example: step_resource_service_stop_do_stuff_start

.. end_tag

case Statements
-----------------------------------------------------
.. tag ruby_style_basics_statement_case

A ``case`` statement can be used to handle a situation where there are a lot of conditions. Use the ``when`` statement for each condition, as many as are required.

For example, using a ``case`` statement with the ``platform`` node attribute:

.. code-block:: ruby

   case node['platform']
   when 'debian', 'ubuntu'
     # do debian/ubuntu things
   when 'redhat', 'centos', 'fedora'
     # do redhat/centos/fedora things
   end

For example, using a ``case`` statement with the ``platform_family`` node attribute:

.. code-block:: ruby

   case node['platform_family']
   when 'debian'
     # do things on debian-ish platforms (debian, ubuntu, linuxmint)
   when 'rhel'
     # do things on RHEL platforms (redhat, centos, scientific, etc)
   end

.. future example: step_resource_package_install_package_on_platform
.. future example: step_resource_package_use_case_statement
.. future example: step_resource_service_manage_ssh_based_on_node_platform

.. end_tag

include? Method
-----------------------------------------------------
.. tag ruby_style_basics_parameter_include

The ``include?`` method can be used to ensure that a specific parameter is included before an action is taken. For example, using the ``include?`` method to find a specific parameter:

.. code-block:: ruby

   if %w(debian ubuntu).include?(node['platform'])
     # do debian/ubuntu things
   end

or:

.. code-block:: ruby

   if %w{rhel}.include?(node['platform_family'])
     # do RHEL things
   end

.. end_tag

Array Syntax Shortcut
-----------------------------------------------------
.. tag ruby_style_basics_array_shortcut

The ``%w`` syntax is a Ruby shortcut for creating an array without requiring quotes and commas around the elements.

For example:

.. code-block:: ruby

   if %w(debian ubuntu).include?(node['platform'])
     # do debian/ubuntu things with the Ruby array %w() shortcut
   end

.. end_tag

Include Recipes
=====================================================
.. tag cookbooks_recipe_include_in_recipe

A recipe can include one (or more) recipes from cookbooks by using the ``include_recipe`` method. When a recipe is included, the resources found in that recipe will be inserted (in the same exact order) at the point where the ``include_recipe`` keyword is located.

The syntax for including a recipe is like this:

.. code-block:: ruby

   include_recipe 'recipe'

For example:

.. code-block:: ruby

   include_recipe 'apache2::mod_ssl'

Multiple recipes can be included within a recipe. For example:

.. code-block:: ruby

   include_recipe 'cookbook::setup'
   include_recipe 'cookbook::install'
   include_recipe 'cookbook::configure'

If a specific recipe is included more than once with the ``include_recipe`` method or elsewhere in the run_list directly, only the first instance is processed and subsequent inclusions are ignored.

.. end_tag

Reload Attributes
-----------------------------------------------------
.. tag cookbooks_attribute_file_reload_from_recipe

Attributes sometimes depend on actions taken from within recipes, so it may be necessary to reload a given attribute from within a recipe. For example:

.. code-block:: ruby

   ruby_block 'some_code' do
     block do
       node.from_file(run_context.resolve_attribute('COOKBOOK_NAME', 'ATTR_FILE'))
     end
     action :nothing
   end

.. end_tag

Recipe DSL Methods
=====================================================
The Recipe DSL provides support for using attributes, data bags (and encrypted data), and search results in a recipe, as well as four helper methods that can be used to check for a node's platform from the recipe to ensure that specific actions are taken for specific platforms. The helper methods are:

* ``platform?``
* ``platform_family?``
* ``value_for_platform``
* ``value_for_platform_family``

attribute?
-----------------------------------------------------
Use the ``attribute?`` method to ensure that certain actions only execute in the presence of a particular node attribute. The ``attribute?`` method will return true if one of the listed node attributes matches a node attribute that is detected by Ohai during every chef-client run.

The syntax for the ``attribute?`` method is as follows:

.. code-block:: ruby

   attribute?('name_of_attribute')

For example:

.. code-block:: ruby

   if node.attribute?('ipaddress')
     # the node has an ipaddress
   end

control
-----------------------------------------------------
.. tag dsl_recipe_method_control

Use the ``control`` method to define a specific series of tests that comprise an individual audit. A ``control`` method MUST be contained within a ``control_group`` block. A ``control_group`` block may contain multiple ``control`` methods.

.. end_tag

.. tag dsl_recipe_method_control_syntax

The syntax for the ``control`` method is as follows:

.. code-block:: ruby

   control_group 'audit name' do
     control 'name' do
       it 'should do something' do
         expect(something).to/.to_not be_something
       end
     end
   end

where:

* ``control_group`` groups one (or more) ``control`` blocks
* ``control 'name' do`` defines an individual audit
* Each ``control`` block must define at least one validation
* Each ``it`` statement defines a single validation. ``it`` statements are processed individually when the chef-client is run in audit-mode
* An ``expect(something).to/.to_not be_something`` is a statement that represents the individual test. In other words, this statement tests if something is expected to be (or not be) something. For example, a test that expects the PostgreSQL pacakge to not be installed would be similar to ``expect(package('postgresql')).to_not be_installed`` and a test that ensures a service is enabled would be similar to ``expect(service('init')).to be_enabled``
* An ``it`` statement may contain multiple ``expect`` statements

.. end_tag

directory Matcher
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_control_matcher_directory

Matchers are available for directories. Use this matcher to define audits for directories that test if the directory exists, is mounted, and if it is linked to. This matcher uses the same matching syntax---``expect(file('foo'))``---as the files. The following matchers are available for directories:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Matcher
     - Description, Example
   * - ``be_directory``
     - Use to test if directory exists. For example:

       .. code-block:: ruby

          it 'should be a directory' do
            expect(file('/var/directory')).to be_directory
          end

   * - ``be_linked_to``
     - Use to test if a subject is linked to the named directory. For example:

       .. code-block:: ruby

          it 'should be linked to the named directory' do
            expect(file('/etc/directory')).to be_linked_to('/etc/some/other/directory')
          end

   * - ``be_mounted``
     - Use to test if a directory is mounted. For example:

       .. code-block:: ruby

          it 'should be mounted' do
            expect(file('/')).to be_mounted
          end

       For directories with a single attribute that requires testing:

       .. code-block:: ruby

          it 'should be mounted with an ext4 partition' do
            expect(file('/')).to be_mounted.with( :type => 'ext4' )
          end

       For directories with multiple attributes that require testing:

       .. code-block:: ruby

          it 'should be mounted only with certain attributes' do
            expect(file('/')).to be_mounted.only_with(
              :attribute => 'value',
              :attribute => 'value',
          )
          end

.. end_tag

file Matcher
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_control_matcher_file

Matchers are available for files and directories. Use this matcher to define audits for files that test if the file exists, its version, if it is is executable, writable, or readable, who owns it, verify checksums (both MD5 and SHA-256) and so on. The following matchers are available for files:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Matcher
     - Description, Example
   * - ``be_executable``
     - Use to test if a file is executable. For example:

       .. code-block:: ruby

          it 'should be executable' do
            expect(file('/etc/file')).to be_executable
          end

       For a file that is executable by its owner:

       .. code-block:: ruby

          it 'should be executable by owner' do
            expect(file('/etc/file')).to be_executable.by('owner')
          end

       For a file that is executable by a group:

       .. code-block:: ruby

          it 'should be executable by group members' do
            expect(file('/etc/file')).to be_executable.by('group')
          end

       For a file that is executable by a specific user:

       .. code-block:: ruby

          it 'should be executable by user foo' do
            expect(file('/etc/file')).to be_executable.by_user('foo')
          end

   * - ``be_file``
     - Use to test if a file exists. For example:

       .. code-block:: ruby

          it 'should be a file' do
            expect(file('/etc/file')).to be_file
          end

   * - ``be_grouped_into``
     - Use to test if a file is grouped into the named group. For example:

       .. code-block:: ruby

          it 'should be grouped into foo' do
            expect(file('/etc/file')).to be_grouped_into('foo')
          end

   * - ``be_linked_to``
     - Use to test if a subject is linked to the named file. For example:

       .. code-block:: ruby

          it 'should be linked to the named file' do
            expect(file('/etc/file')).to be_linked_to('/etc/some/other/file')
          end

   * - ``be_mode``
     - Use to test if a file is set to the specified mode. For example:

       .. code-block:: ruby

          it 'should be mode 440' do
            expect(file('/etc/file')).to be_mode(440)
          end

   * - ``be_owned_by``
     - Use to test if a file is owned by the named owner. For example:

       .. code-block:: ruby

          it 'should be owned by the root user' do
            expect(file('/etc/sudoers')).to be_owned_by('root')
          end

   * - ``be_readable``
     - Use to test if a file is readable. For example:

       .. code-block:: ruby

          it 'should be readable' do
            expect(file('/etc/file')).to be_readable
          end

       For a file that is readable by its owner:

       .. code-block:: ruby

          it 'should be readable by owner' do
            expect(file('/etc/file')).to be_readable.by('owner')
          end

       For a file that is readable by a group:

       .. code-block:: ruby

          it 'should be readable by group members' do
            expect(file('/etc/file')).to be_readable.by('group')
          end

       For a file that is readable by a specific user:

       .. code-block:: ruby

          it 'should be readable by user foo' do
            expect(file('/etc/file')).to be_readable.by_user('foo')
          end

   * - ``be_socket``
     - Use to test if a file exists as a socket. For example:

       .. code-block:: ruby

          it 'should be a socket' do
            expect(file('/var/file.sock')).to be_socket
          end

   * - ``be_symlink``
     - Use to test if a file exists as a symbolic link. For example:

       .. code-block:: ruby

          it 'should be a symlink' do
            expect(file('/etc/file')).to be_symlink
          end

   * - ``be_version``
     - Microsoft Windows only. Use to test if a file is the specified version. For example:

       .. code-block:: ruby

          it 'should be version 1.2' do
            expect(file('C:\\Windows\\path\\to\\file')).to be_version('1.2')
          end

   * - ``be_writable``
     - Use to test if a file is writable. For example:

       .. code-block:: ruby

          it 'should be writable' do
            expect(file('/etc/file')).to be_writable
          end

       For a file that is writable by its owner:

       .. code-block:: ruby

          it 'should be writable by owner' do
            expect(file('/etc/file')).to be_writable.by('owner')
          end

       For a file that is writable by a group:

       .. code-block:: ruby

          it 'should be writable by group members' do
            expect(file('/etc/file')).to be_writable.by('group')
          end

       For a file that is writable by a specific user:

       .. code-block:: ruby

          it 'should be writable by user foo' do
            expect(file('/etc/file')).to be_writable.by_user('foo')
          end

   * - ``contain``
     - Use to test if a file contains specific contents. For example:

       .. code-block:: ruby

          it 'should contain docs.chef.io' do
            expect(file('/etc/file')).to contain('docs.chef.io')
          end

.. end_tag

package Matcher
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_control_matcher_package

Matchers are available for packages and may be used to define audits that test if a package or a package version is installed. The following matchers are available:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Matcher
     - Description, Example
   * - ``be_installed``
     - Use to test if the named package is installed. For example:

       .. code-block:: ruby

          it 'should be installed' do
            expect(package('httpd')).to be_installed
          end

       For a specific package version:

       .. code-block:: ruby

          it 'should be installed' do
            expect(package('httpd')).to be_installed.with_version('0.1.2')
          end

.. end_tag

port Matcher
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_control_matcher_port

Matchers are available for ports and may be used to define audits that test if a port is listening. The following matchers are available:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Matcher
     - Description, Example
   * - ``be_listening``
     - Use to test if the named port is listening. For example:

       .. code-block:: ruby

          it 'should be listening' do
            expect(port(23)).to be_listening
          end

       For a named port that is not listening:

       .. code-block:: ruby

          it 'should not be listening' do
            expect(port(23)).to_not be_listening
          end

       For a specific port type use ``.with('port_type')``. For example, UDP:

       .. code-block:: ruby

          it 'should be listening with UDP' do
            expect(port(23)).to_not be_listening.with('udp')
          end

       For UDP, version 6:

       .. code-block:: ruby

          it 'should be listening with UDP6' do
            expect(port(23)).to_not be_listening.with('udp6')
          end

       For TCP/IP:

       .. code-block:: ruby

          it 'should be listening with TCP' do
            expect(port(23)).to_not be_listening.with('tcp')
          end

       For TCP/IP, version 6:

       .. code-block:: ruby

          it 'should be listening with TCP6' do
            expect(port(23)).to_not be_listening.with('tcp6')
          end

.. end_tag

service Matcher
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_control_matcher_service

Matchers are available for services and may be used to define audits that test for conditions related to services, such as if they are enabled, running, have the correct startup mode, and so on. The following matchers are available:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Matcher
     - Description, Example
   * - ``be_enabled``
     - Use to test if the named service is enabled (i.e. will start up automatically). For example:

       .. code-block:: ruby

          it 'should be enabled' do
            expect(service('ntpd')).to be_enabled
          end

       For a service that is enabled at a given run level:

       .. code-block:: ruby

          it 'should be enabled at the specified run level' do
            expect(service('ntpd')).to be_enabled.with_level(3)
          end

   * - ``be_installed``
     - Microsoft Windows only. Use to test if the named service is installed on the Microsoft Windows platform. For example:

       .. code-block:: ruby

          it 'should be installed' do
            expect(service('DNS Client')).to be_installed
          end

   * - ``be_running``
     - Use to test if the named service is running. For example:

       .. code-block:: ruby

          it 'should be running' do
            expect(service('ntpd')).to be_running
          end

       For a service that is running under supervisor:

       .. code-block:: ruby

          it 'should be running under supervisor' do
            expect(service('ntpd')).to be_running.under('supervisor')
          end

       or daemontools:

       .. code-block:: ruby

          it 'should be running under daemontools' do
            expect(service('ntpd')).to be_running.under('daemontools')
          end

       or Upstart:

       .. code-block:: ruby

          it 'should be running under upstart' do
            expect(service('ntpd')).to be_running.under('upstart')
          end

   * - ``be_monitored_by``
     - Use to test if the named service is being monitored by the named monitoring application. For example:

       .. code-block:: ruby

          it 'should be monitored by' do
            expect(service('ntpd')).to be_monitored_by('monit')
          end

   * - ``have_start_mode``
     - Microsoft Windows only. Use to test if the named service's startup mode is correct on the Microsoft Windows platform. For example:

       .. code-block:: ruby

          it 'should start manually' do
            expect(service('DNS Client')).to have_start_mode.Manual
          end

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**A package is installed**

.. tag dsl_recipe_control_matcher_package_installed

For example, a package is installed:

.. code-block:: ruby

   control_group 'audit name' do
     control 'mysql package' do
       it 'should be installed' do
         expect(package('mysql')).to be_installed
       end
     end
   end

The ``control_group`` block is processed when the chef-client run is run in audit-mode. If the audit was successful, the chef-client will return output similar to:

.. code-block:: bash

   Audit Mode
     mysql package
       should be installed

If an audit was unsuccessful, the chef-client will return output similar to:

.. code-block:: bash

   Starting audit phase

   Audit Mode
     mysql package
     should be installed (FAILED - 1)

   Failures:

   1) Audit Mode mysql package should be installed
     Failure/Error: expect(package('mysql')).to be_installed.with_version('5.6')
       expected Package 'mysql' to be installed
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:22:in 'block (3 levels) in from_file'

   Finished in 0.5745 seconds (files took 0.46481 seconds to load)
   1 examples, 1 failures

   Failed examples:

   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:21 # Audit Mode mysql package should be installed

.. end_tag

**A package version is installed**

.. tag dsl_recipe_control_matcher_package_installed_version

A package that is installed with a specific version:

.. code-block:: ruby

   control_group 'audit name' do
     control 'mysql package' do
       it 'should be installed' do
         expect(package('mysql')).to be_installed.with_version('5.6')
       end
     end
   end

.. end_tag

**A package is not installed**

.. tag dsl_recipe_control_matcher_package_not_installed

A package that is not installed:

.. code-block:: ruby

   control_group 'audit name' do
     control 'postgres package' do
       it 'should not be installed' do
         expect(package('postgresql')).to_not be_installed
       end
     end
   end

If the audit was successful, the chef-client will return output similar to:

.. code-block:: bash

   Audit Mode
     postgres audit
       postgres package
         is not installed

.. end_tag

**A service is enabled**

.. tag dsl_recipe_control_matcher_service_enabled

A service that is enabled and running:

.. code-block:: ruby

   control_group 'audit name' do
     control 'mysql service' do
       let(:mysql_service) { service('mysql') }
       it 'should be enabled' do
         expect(mysql_service).to be_enabled
       end
       it 'should be running' do
         expect(mysql_service).to be_running
       end
     end
   end

If the audit was successful, the chef-client will return output similar to:

.. code-block:: bash

   Audit Mode
     mysql service audit
       mysql service
         is enabled
         is running

.. end_tag

**A configuration file contains specific settings**

.. tag dsl_recipe_control_matcher_file_sshd_configuration

The following example shows how to verify ``sshd`` configration, including whether it's installed, what the permissions are, and how it can be accessed:

.. code-block:: ruby

   control_group 'check sshd configuration' do

     control 'sshd package' do
       it 'should be installed' do
         expect(package('openssh-server')).to be_installed
       end
     end

     control 'sshd configuration' do
       let(:config_file) { file('/etc/ssh/sshd_config') }
       it 'should exist with the right permissions' do
         expect(config_file).to be_file
         expect(config_file).to be_mode(644)
         expect(config_file).to be_owned_by('root')
         expect(config_file).to be_grouped_into('root')
       end
       it 'should not permit RootLogin' do
         expect(config_file.content).to_not match(/^PermitRootLogin yes/)
       end
       it 'should explicitly not permit PasswordAuthentication' do
         expect(config_file.content).to match(/^PasswordAuthentication no/)
       end
       it 'should force privilege separation' do
         expect(config_file.content).to match(/^UsePrivilegeSeparation sandbox/)
       end
     end
   end

where

* ``let(:config_file) { file('/etc/ssh/sshd_config') }`` uses the ``file`` matcher to test specific settings within the ``sshd`` configuration file

.. end_tag

**A file contains desired permissions and contents**

.. tag dsl_recipe_control_matcher_file_permissions

The following example shows how to verify that a file has the desired permissions and contents:

.. code-block:: ruby

   controls 'mysql config' do
     control 'mysql config file' do
       let(:config_file) { file('/etc/mysql/my.cnf') }
       it 'exists with correct permissions' do
         expect(config_file).to be_file
         expect(config_file).to be_mode(0400)
       end
       it 'contains required configuration' do
         expect(its('contents')).to match(/default-time-zone='UTC'/)
       end
     end
   end

If the audit was successful, the chef-client will return output similar to:

.. code-block:: bash

   Audit Mode
     mysql config
       mysql config file
         exists with correct permissions
         contains required configuration

.. end_tag

**Test an attribute value**

To audit attribute values in a ``control`` block, first assign the attribute as a variable, and then use the variable within the ``control`` block to specify the test:

.. code-block:: ruby

   memory_mb = node['memory']['total'].gsub(/kB$/i, '').to_i / 1024
   control 'minimum memory check' do
     it 'should be at least 400MB free' do
       expect(memory_mb).to be >= 400
     end
   end

control_group
-----------------------------------------------------
.. tag dsl_recipe_method_control_group

Use the ``control_group`` method to define a group of ``control`` methods that comprise a single audit. The name of each ``control_group`` must be unique within the organization.

.. end_tag

.. tag dsl_recipe_method_control_group_syntax

The syntax for the ``control_group`` method is as follows:

.. code-block:: ruby

   control_group 'name' do
     control 'name' do
       it 'should do something' do
         expect(something).to/.to_not be_something
       end
     end
     control 'name' do
       ...
     end
     ...
   end

where:

* ``control_group`` groups one (or more) ``control`` blocks
* ``'name'`` is the unique name for the ``control_group``; the chef-client will raise an exception if duplicate ``control_group`` names are present
* ``control`` defines each individual audit within the ``control_group`` block. There is no limit to the number of ``control`` blocks that may defined within a ``control_group`` block

.. end_tag

New in Chef Client 12.1.

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**control_group block with multiple control blocks**

.. tag dsl_recipe_control_group_many_controls

The following ``control_group`` ensures that MySQL is installed, that PostgreSQL is not installed, and that the services and configuration files associated with MySQL are configured correctly:

.. code-block:: ruby

   control_group 'Audit Mode' do

     control 'mysql package' do
       it 'should be installed' do
         expect(package('mysql')).to be_installed.with_version('5.6')
       end
     end

     control 'postgres package' do
       it 'should not be installed' do
         expect(package('postgresql')).to_not be_installed
       end
     end

     control 'mysql service' do
       let(:mysql_service) { service('mysql') }
       it 'should be enabled' do
         expect(mysql_service).to be_enabled
       end
       it 'should be running' do
         expect(mysql_service).to be_running
       end
     end

     control 'mysql config directory' do
       let(:config_dir) { file('/etc/mysql') }
       it 'should exist with correct permissions' do
         expect(config_dir).to be_directory
         expect(config_dir).to be_mode(0700)
       end
       it 'should be owned by the db user' do
         expect(config_dir).to be_owned_by('db_service_user')
       end
     end

     control 'mysql config file' do
       let(:config_file) { file('/etc/mysql/my.cnf') }
       it 'should exist with correct permissions' do
         expect(config_file).to be_file
         expect(config_file).to be_mode(0400)
       end
       it 'should contain required configuration' do
         expect(config_file.content).to match(/default-time-zone='UTC'/)
       end
     end

   end

The ``control_group`` block is processed when the chef-client is run in audit-mode. If the chef-client run was successful, the chef-client will return output similar to:

.. code-block:: bash

   Audit Mode
     mysql package
       should be installed
     postgres package
       should not be installed
     mysql service
       should be enabled
       should be running
     mysql config directory
       should exist with correct permissions
       should be owned by the db user
     mysql config file
       should exist with correct permissions
       should contain required configuration

If an audit was unsuccessful, the chef-client will return output similar to:

.. code-block:: bash

   Starting audit phase

   Audit Mode
     mysql package
     should be installed (FAILED - 1)
   postgres package
     should not be installed
   mysql service
     should be enabled (FAILED - 2)
     should be running (FAILED - 3)
   mysql config directory
     should exist with correct permissions (FAILED - 4)
     should be owned by the db user (FAILED - 5)
   mysql config file
     should exist with correct permissions (FAILED - 6)
     should contain required configuration (FAILED - 7)

   Failures:

   1) Audit Mode mysql package should be installed
     Failure/Error: expect(package('mysql')).to be_installed.with_version('5.6')
       expected Package 'mysql' to be installed
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:22:in 'block (3 levels) in from_file'

   2) Audit Mode mysql service should be enabled
     Failure/Error: expect(mysql_service).to be_enabled
       expected Service 'mysql' to be enabled
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:35:in 'block (3 levels) in from_file'

   3) Audit Mode mysql service should be running
      Failure/Error: expect(mysql_service).to be_running
       expected Service 'mysql' to be running
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:38:in 'block (3 levels) in from_file'

   4) Audit Mode mysql config directory should exist with correct permissions
     Failure/Error: expect(config_dir).to be_directory
       expected `File '/etc/mysql'.directory?` to return true, got false
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:45:in 'block (3 levels) in from_file'

   5) Audit Mode mysql config directory should be owned by the db user
     Failure/Error: expect(config_dir).to be_owned_by('db_service_user')
       expected `File '/etc/mysql'.owned_by?('db_service_user')` to return true, got false
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:49:in 'block (3 levels) in from_file'

   6) Audit Mode mysql config file should exist with correct permissions
     Failure/Error: expect(config_file).to be_file
       expected `File '/etc/mysql/my.cnf'.file?` to return true, got false
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:56:in 'block (3 levels) in from_file'

   7) Audit Mode mysql config file should contain required configuration
     Failure/Error: expect(config_file.content).to match(/default-time-zone='UTC'/)
       expected '-n\n' to match /default-time-zone='UTC'/
       Diff:
       @@ -1,2 +1,2 @@
       -/default-time-zone='UTC'/
       +-n
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:60:in 'block (3 levels) in from_file'

   Finished in 0.5745 seconds (files took 0.46481 seconds to load)
   8 examples, 7 failures

   Failed examples:

   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:21 # Audit Mode mysql package should be installed
   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:34 # Audit Mode mysql service should be enabled
   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:37 # Audit Mode mysql service should be running
   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:44 # Audit Mode mysql config directory should exist with correct permissions
   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:48 # Audit Mode mysql config directory should be owned by the db user
   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:55 # Audit Mode mysql config file should exist with correct permissions
   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:59 # Audit Mode mysql config file should contain required configuration
   Auditing complete

.. end_tag

**Duplicate control_group names**

.. tag dsl_recipe_control_group_duplicate_names

If two ``control_group`` blocks have the same name, the chef-client will raise an exception. For example, the following ``control_group`` blocks exist in different cookbooks:

.. code-block:: ruby

   control_group 'basic control group' do
     it 'should pass' do
       expect(2 - 2).to eq(0)
     end
   end

.. code-block:: ruby

   control_group 'basic control group' do
     it 'should pass' do
       expect(3 - 2).to eq(1)
     end
   end

Because the two ``control_group`` block names are identical, the chef-client will return an exception similar to:

.. code-block:: ruby

   Synchronizing Cookbooks:
     - audit_test
   Compiling Cookbooks...

   ================================================================================
   Recipe Compile Error in /Users/grantmc/.cache/chef/cache/cookbooks
                           /audit_test/recipes/error_duplicate_control_groups.rb
   ================================================================================

   Chef::Exceptions::AuditControlGroupDuplicate
   --------------------------------------------
   Audit control group with name 'basic control group' has already been defined

   Cookbook Trace:
   ---------------
   /Users/grantmc/.cache/chef/cache/cookbooks
   /audit_test/recipes/error_duplicate_control_groups.rb:13:in 'from_file'

   Relevant File Content:
   ----------------------
   /Users/grantmc/.cache/chef/cache/cookbooks/audit_test/recipes/error_duplicate_control_groups.rb:

   control_group 'basic control group' do
     it 'should pass' do
       expect(2 - 2).to eq(0)
     end
   end

   control_group 'basic control group' do
     it 'should pass' do
       expect(3 - 2).to eq(1)
     end
   end

   Running handlers:
   [2015-01-15T09:36:14-08:00] ERROR: Running exception handlers
   Running handlers complete

.. end_tag

**Verify a package is installed**

.. tag dsl_recipe_control_group_simple_recipe

The following ``control_group`` verifies that the ``git`` package has been installed:

.. code-block:: ruby

   package 'git' do
     action :install
   end

   execute 'list packages' do
     command 'dpkg -l'
   end

   execute 'list directory' do
     command 'ls -R ~'
   end

   control_group 'my audits' do
     control 'check git' do
       it 'should be installed' do
         expect(package('git')).to be_installed
       end
     end
   end

.. end_tag

cookbook_name
-----------------------------------------------------
Use the ``cookbook_name`` method to return the name of a cookbook.

The syntax for the ``cookbook_name`` method is as follows:

.. code-block:: ruby

   cookbook_name

This method is often used as part of a log entry. For example:

.. code-block:: ruby

   Chef::Log.info('I am a message from the #{recipe_name} recipe in the #{cookbook_name} cookbook.')

data_bag
-----------------------------------------------------
.. tag data_bag

A data bag is a global variable that is stored as JSON data and is accessible from a Chef server. A data bag is indexed for searching and can be loaded by a recipe or accessed during a search.

.. end_tag

Use the ``data_bag`` method to get a list of the contents of a data bag.

The syntax for the ``data_bag`` method is as follows:

.. code-block:: ruby

   data_bag(bag_name)

**Examples**

The following example shows how the ``data_bag`` method can be used in a recipe.

**Get a data bag, and then iterate through each data bag item**

.. tag dsl_recipe_data_bag

.. The following is an example of using the ``data_bag`` method:

.. code-block:: ruby

   data_bag('users') #=> ['sandy', 'jill']

Iterate over the contents of the data bag to get the associated ``data_bag_item``:

.. code-block:: ruby

   data_bag('users').each do |user|
     data_bag_item('users', user)
   end

The ``id`` for each data bag item will be returned as a string.

.. end_tag

New in Chef Client 12.0.

data_bag_item
-----------------------------------------------------
.. tag data_bag

A data bag is a global variable that is stored as JSON data and is accessible from a Chef server. A data bag is indexed for searching and can be loaded by a recipe or accessed during a search.

.. end_tag

The ``data_bag_item`` method can be used in a recipe to get the contents of a data bag item.

The syntax for the ``data_bag_item`` method is as follows:

.. code-block:: ruby

   data_bag_item(bag_name, item, secret)

where ``secret`` is the secret used to load an encrypted data bag. If ``secret`` is not specified, the chef-client looks for a secret at the path specified by the ``encrypted_data_bag_secret`` setting in the client.rb file.

**Examples**

The following examples show how the ``data_bag_item`` method can be used in a recipe.

**Get a data bag, and then iterate through each data bag item**

.. tag dsl_recipe_data_bag

.. The following is an example of using the ``data_bag`` method:

.. code-block:: ruby

   data_bag('users') #=> ['sandy', 'jill']

Iterate over the contents of the data bag to get the associated ``data_bag_item``:

.. code-block:: ruby

   data_bag('users').each do |user|
     data_bag_item('users', user)
   end

The ``id`` for each data bag item will be returned as a string.

.. end_tag

**Use the contents of a data bag in a recipe**

The following example shows how to use the ``data_bag`` and ``data_bag_item`` methods in a recipe, also using a data bag named ``sea-power``):

.. code-block:: ruby

   package 'sea-power' do
     action :install
   end

   directory node['sea-power']['base_path'] do
     # attributes for owner, group, mode
   end

   gale_warnings = data_bag('sea-power').map do |viking_north|
     data_bag_item('sea-power', viking_north)['source']
   end

   template '/etc/seattle/power.list' do
     source 'seattle-power.erb'
     # attributes for owner, group, mode
     variables(
       :base_path => node['sea-power']['base_path'],
       # more variables
       :repo_location => gale_warnings
     )
   end

For a more complete version of the previous example, see the default recipe in the https://github.com/hw-cookbooks/apt-mirror community cookbook.

New in Chef Client 12.0.

declare_resource
-----------------------------------------------------
.. tag dsl_recipe_method_declare_resource

Use the ``declare_resource`` method to instantiate a resource and then add it to the resource collection.

The syntax for the ``declare_resource`` method is as follows:

.. code-block:: ruby

   declare_resource(:resource_type, 'resource_name', resource_attrs_block)

where:

* ``:resource_type`` is the resource type, such as ``:file ``(for the **file** resource), ``:template`` (for the **template** resource), and so on. Any resource available to Chef may be declared.
* ``resource_name`` the property that is the default name of the resource, typically the string that appears in the ``resource 'name' do`` block of a resource (but not always); see the Syntax section for the resource to be declared to verify the default name property.
* ``resource_attrs_block`` is a block in which properties of the instantiated resource are declared.

For example:

.. code-block:: ruby

   declare_resource(:file, '/x/y.txy', caller[0]) do
     action :delete
   end

is equivalent to:

.. code-block:: ruby

   file '/x/y.txt' do
     action :delete
   end

New in Chef Client 12.10.

.. end_tag

delete_resource
-----------------------------------------------------
.. tag dsl_recipe_method_delete_resource

Use the ``delete_resource`` method to find a resource in the resource collection, and then delete it.

The syntax for the ``delete_resource`` method is as follows:

.. code-block:: ruby

   delete_resource(:resource_type, 'resource_name')

where:

* ``:resource_type`` is the resource type, such as ``:file ``(for the **file** resource), ``:template`` (for the **template** resource), and so on. Any resource available to Chef may be declared.
* ``resource_name`` the property that is the default name of the resource, typically the string that appears in the ``resource 'name' do`` block of a resource (but not always); see the Syntax section for the resource to be declared to verify the default name property.

For example:

.. code-block:: ruby

   delete_resource(:template, '/x/y.erb')

New in Chef Client 12.10.

.. end_tag

delete_resource!
-----------------------------------------------------
.. tag dsl_recipe_method_delete_resource_bang

Use the ``delete_resource!`` method to find a resource in the resource collection, and then delete it. If the resource is not found, an exception is returned.

The syntax for the ``delete_resource!`` method is as follows:

.. code-block:: ruby

delete_resource!(:resource_type, 'resource_name')

where:

* ``:resource_type`` is the resource type, such as ``:file ``(for the **file** resource), ``:template`` (for the **template** resource), and so on. Any resource available to Chef may be declared.
* ``resource_name`` the property that is the default name of the resource, typically the string that appears in the ``resource 'name' do`` block of a resource (but not always); see the Syntax section for the resource to be declared to verify the default name property.

For example:

.. code-block:: ruby

   delete_resource!(:file, '/x/file.txt')

New in Chef Client 12.10.

.. end_tag

edit_resource
-----------------------------------------------------
.. tag dsl_recipe_method_edit_resource

Use the ``edit_resource`` method to:

* Find a resource in the resource collection, and then edit it.
* Define a resource block. If a resource block with the same name exists in the resource collection, it will be updated with the contents of the resource block defined by the ``edit_resource`` method. If a resource block does not exist in the resource collection, it will be created.

The syntax for the ``edit_resource`` method is as follows:

.. code-block:: ruby

   edit_resource(:resource_type, 'resource_name', resource_attrs_block)

where:

* ``:resource_type`` is the resource type, such as ``:file`` (for the **file** resource), ``:template`` (for the **template** resource), and so on. Any resource available to Chef may be declared.
* ``resource_name`` the property that is the default name of the resource, typically the string that appears in the ``resource 'name' do`` block of a resource (but not always); see the Syntax section for the resource to be declared to verify the default name property.
* ``resource_attrs_block`` is a block in which properties of the instantiated resource are declared.

For example:

.. code-block:: ruby

   edit_resource(:template, '/x/y.txy') do
     cookbook_name: cookbook_name
   end

and a resource block:

.. code-block:: ruby

   edit_resource(:template, '/etc/aliases') do
     source 'aliases.erb'
     cookbook 'aliases'
     variables({:aliases => {} })
     notifies :run, 'execute[newaliases]'
   end

New in Chef Client 12.10.

.. end_tag

edit_resource!
-----------------------------------------------------
.. tag dsl_recipe_method_edit_resource_bang

Use the ``edit_resource!`` method to:

* Find a resource in the resource collection, and then edit it.
* Define a resource block. If a resource with the same name exists in the resource collection, its properties will be updated with the contents of the resource block defined by the ``edit_resource`` method.

In both cases, if the resource is not found, an exception is returned.

The syntax for the ``edit_resource!`` method is as follows:

.. code-block:: ruby

   edit_resource!(:resource_type, 'resource_name')

where:

* ``:resource_type`` is the resource type, such as ``:file ``(for the **file** resource), ``:template`` (for the **template** resource), and so on. Any resource available to Chef may be declared.
* ``resource_name`` the property that is the default name of the resource, typically the string that appears in the ``resource 'name' do`` block of a resource (but not always); see the Syntax section for the resource to be declared to verify the default name property.
* ``resource_attrs_block`` is a block in which properties of the instantiated resource are declared.

For example:

.. code-block:: ruby

   edit_resource!(:file, '/x/y.rst')

New in Chef Client 12.10.

.. end_tag

find_resource
-----------------------------------------------------
.. tag dsl_recipe_method_find_resource

Use the ``find_resource`` method to:

* Find a resource in the resource collection.
* Define a resource block. If a resource block with the same name exists in the resource collection, it will be returned. If a resource block does not exist in the resource collection, it will be created.

The syntax for the ``find_resource`` method is as follows:

.. code-block:: ruby

   find_resource(:resource_type, 'resource_name')

where:

* ``:resource_type`` is the resource type, such as ``:file ``(for the **file** resource), ``:template`` (for the **template** resource), and so on. Any resource available to Chef may be declared.
* ``resource_name`` the property that is the default name of the resource, typically the string that appears in the ``resource 'name' do`` block of a resource (but not always); see the Syntax section for the resource to be declared to verify the default name property.

For example:

.. code-block:: ruby

   find_resource(:template, '/x/y.txy')

and a resource block:

.. code-block:: ruby

   find_resource(:template, '/etc/seapower') do
     source 'seapower.erb'
     cookbook 'seapower'
     variables({:seapower => {} })
     notifies :run, 'execute[newseapower]'
   end

New in Chef Client 12.10.

.. end_tag

find_resource!
-----------------------------------------------------
.. tag dsl_recipe_method_find_resource_bang

Use the ``find_resource!`` method to find a resource in the resource collection. If the resource is not found, an exception is returned.

The syntax for the ``find_resource!`` method is as follows:

.. code-block:: ruby

   find_resource!(:resource_type, 'resource_name')

where:

* ``:resource_type`` is the resource type, such as ``:file ``(for the **file** resource), ``:template`` (for the **template** resource), and so on. Any resource available to Chef may be declared.
* ``resource_name`` the property that is the default name of the resource, typically the string that appears in the ``resource 'name' do`` block of a resource (but not always); see the Syntax section for the resource to be declared to verify the default name property.

For example:

.. code-block:: ruby

   find_resource!(:template, '/x/y.erb')

New in Chef Client 12.10.

.. end_tag

platform?
-----------------------------------------------------
Use the ``platform?`` method to ensure that certain actions are run for specific platform. The ``platform?`` method will return true if one of the listed parameters matches the ``node['platform']`` attribute that is detected by Ohai during every chef-client run.

The syntax for the ``platform?`` method is as follows:

.. code-block:: ruby

   platform?('parameter', 'parameter')

where:

* ``parameter`` is a comma-separated list, each specifying a platform, such as Red Hat, CentOS, or Fedora
* ``platform?`` method is typically used with an ``if``, ``elseif``, or ``case`` statement that contains Ruby code that is specific for the platform, if detected

.. future example: step_resource_ruby_block_if_statement_use_with_platform
.. future example: step_resource_ruby_block_run_specific_blocks_on_specific_platforms

Parameters
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following parameters can be used with this method:

.. list-table::
   :widths: 100 500
   :header-rows: 1

   * - Parameter
     - Platforms
   * - ``aix``
     - AIX. All platform variants of AIX return ``aix``.
   * - ``arch``
     - Arch Linux
   * - ``debian``
     - Debian, Linux Mint, Ubuntu
   * - ``fedora``
     - Fedora
   * - ``freebsd``
     - FreeBSD. All platform variants of FreeBSD return ``freebsd``.
   * - ``gentoo``
     - Gentoo
   * - ``hpux``
     - HP-UX. All platform variants of HP-UX return ``hpux``.
   * - ``mac_os_x``
     - macOS
   * - ``netbsd``
     - NetBSD. All platform variants of NetBSD return ``netbsd``.
   * - ``openbsd``
     - OpenBSD. All platform variants of OpenBSD return ``openbsd``.
   * - ``slackware``
     - Slackware
   * - ``solaris``
     - Solaris. For Solaris-related platforms, the ``platform_family`` method does not support the Solaris platform family and will default back to ``platform_family = platform``. For example, if the platform is OmniOS, the ``platform_family`` is ``omnios``, if the platform is SmartOS, the ``platform_family`` is ``smartos``, and so on. All platform variants of Solaris return ``solaris``.
   * - ``suse``
     - openSUSE, SUSE Enterprise Linux Server.
   * - ``windows``
     - Microsoft Windows. All platform variants of Microsoft Windows return ``windows``.

.. note:: Ohai collects platform information at the start of the chef-client run and stores that information in the ``node['platform']`` attribute.

For example:

.. code-block:: ruby

   platform?('debian')

or:

.. code-block:: ruby

   platform?('rhel', 'debian')

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following example shows how the ``platform?`` method can be used in a recipe.

**Use an if statement with the platform recipe DSL method**

.. tag resource_ruby_block_if_statement_use_with_platform

The following example shows how an if statement can be used with the ``platform?`` method in the Recipe DSL to run code specific to Microsoft Windows. The code is defined using the **ruby_block** resource:

.. code-block:: ruby

   # the following code sample comes from the ``client`` recipe
   # in the following cookbook: https://github.com/chef-cookbooks/mysql

   if platform?('windows')
     ruby_block 'copy libmysql.dll into ruby path' do
       block do
         require 'fileutils'
         FileUtils.cp "#{node['mysql']['client']['lib_dir']}\\libmysql.dll",
           node['mysql']['client']['ruby_dir']
       end
       not_if { File.exist?("#{node['mysql']['client']['ruby_dir']}\\libmysql.dll") }
     end
   end

.. end_tag

platform_family?
-----------------------------------------------------
Use the ``platform_family?`` method to ensure that certain actions are run for specific platform family. The ``platform_family?`` method will return true if one of the listed parameters matches the ``node['platform_family']`` attribute that is detected by Ohai during every chef-client run.

The syntax for the ``platform_family?`` method is as follows:

.. code-block:: ruby

   platform_family?('parameter', 'parameter')

where:

* ``'parameter'`` is a comma-separated list, each specifying a platform family, such as Debian, or Red Hat Enterprise Linux
* ``platform_family?`` method is typically used with an ``if``, ``elseif``, or ``case`` statement that contains Ruby code that is specific for the platform family, if detected

For example:

.. code-block:: ruby

   if platform_family?('rhel')
     # do RHEL things
   end

or:

.. code-block:: ruby

   if platform_family?('debian', 'rhel')
     # do things on debian and rhel families
   end

For example:

.. code-block:: ruby

   platform_family?('gentoo')

or:

.. code-block:: ruby

   platform_family?('slackware', 'suse', 'arch')

.. note:: ``platform_family?`` will default to ``platform?`` when ``platform_family?`` is not explicitly defined.

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following examples show how the ``platform_family?`` method can be used in a recipe.

**Use a specific binary for a specific platform**

.. tag resource_remote_file_use_platform_family

The following is an example of using the ``platform_family?`` method in the Recipe DSL to create a variable that can be used with other resources in the same recipe. In this example, ``platform_family?`` is being used to ensure that a specific binary is used for a specific platform before using the **remote_file** resource to download a file from a remote location, and then using the **execute** resource to install that file by running a command.

.. code-block:: ruby

   if platform_family?('rhel')
     pip_binary = '/usr/bin/pip'
   else
     pip_binary = '/usr/local/bin/pip'
   end

   remote_file "#{Chef::Config[:file_cache_path]}/distribute_setup.py" do
     source 'http://python-distribute.org/distribute_setup.py'
     mode '0755'
     not_if { File.exist?(pip_binary) }
   end

   execute 'install-pip' do
     cwd Chef::Config[:file_cache_path]
     command <<-EOF
       # command for installing Python goes here
       EOF
     not_if { File.exist?(pip_binary) }
   end

where a command for installing Python might look something like:

.. code-block:: ruby

    #{node['python']['binary']} distribute_setup.py
    #{::File.dirname(pip_binary)}/easy_install pip

.. end_tag

reboot_pending?
-----------------------------------------------------
Use the ``reboot_pending?`` method to test if a node needs a reboot, or is expected to reboot. ``reboot_pending?`` returns ``true`` when the node needs a reboot.

The syntax for the ``reboot_pending?`` method is as follows:

.. code-block:: ruby

   reboot_pending?

recipe_name
-----------------------------------------------------
Use the ``recipe_name`` method to return the name of a recipe.

The syntax for the ``recipe_name`` method is as follows:

.. code-block:: ruby

   recipe_name

This method is often used as part of a log entry. For example:

.. code-block:: ruby

   Chef::Log.info('I am a message from the #{recipe_name} recipe in the #{cookbook_name} cookbook.')

resources
-----------------------------------------------------
Use the ``resources`` method to look up a resource in the resource collection. The ``resources`` method returns the value for the resource that it finds in the resource collection. The preferred syntax for the ``resources`` method is as follows:

.. code-block:: ruby

   resources('resource_type[resource_name]')

but the following syntax can also be used:

.. code-block:: ruby

   resources(:resource_type => 'resource_name')

where in either approach ``resource_type`` is the name of a resource and ``resource_name`` is the name of a resource that can be configured by the chef-client.

The ``resources`` method can be used to modify a resource later on in a recipe. For example:

.. code-block:: ruby

   file '/etc/hosts' do
     content '127.0.0.1 localhost.localdomain localhost'
   end

and then later in the same recipe, or elsewhere:

.. code-block:: ruby

   f = resources('file[/etc/hosts]')
   f.mode '0644'

where ``file`` is the type of resource, ``/etc/hosts`` is the name, and ``f.mode`` is used to set the ``mode`` property on the **file** resource.

search
-----------------------------------------------------
.. tag search

Search indexes allow queries to be made for any type of data that is indexed by the Chef server, including data bags (and data bag items), environments, nodes, and roles. A defined query syntax is used to support search patterns like exact, wildcard, range, and fuzzy. A search is a full-text query that can be done from several locations, including from within a recipe, by using the ``search`` subcommand in knife, the ``search`` method in the Recipe DSL, the search box in the Chef management console, and by using the ``/search`` or ``/search/INDEX`` endpoints in the Chef server API. The search engine is based on Apache Solr and is run from the Chef server.

.. end_tag

Use the ``search`` method to perform a search query against the Chef server from within a recipe.

The syntax for the ``search`` method is as follows:

.. code-block:: ruby

   search(:index, 'query')

where:

* ``:index`` is of name of the index on the Chef server against which the search query will run: ``:client``, ``:data_bag_name``, ``:environment``, ``:node``, and ``:role``
* ``'query'`` is a valid search query against an object on the Chef server (see below for more information about how to build the query)

For example, using the results of a search query within a variable:

.. code-block:: ruby

   webservers = search(:node, 'role:webserver')

and then using the results of that query to populate a template:

.. code-block:: ruby

   template '/tmp/list_of_webservers' do
     source 'list_of_webservers.erb'
     variables(:webservers => webservers)
   end

:filter_result
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_search_filter_result

Use ``:filter_result`` as part of a search query to filter the search output based on the pattern specified by a Hash. Only attributes in the Hash will be returned.

.. note:: .. tag notes_filter_search_vs_partial_search

          Prior to chef-client 12.0, this functionality was available from the ``partial_search`` cookbook and was referred to as "partial search".

          .. end_tag

The syntax for the ``search`` method that uses ``:filter_result`` is as follows:

.. code-block:: ruby

   search(:index, 'query',
     :filter_result => { 'foo' => [ 'abc' ],
                         'bar' => [ '123' ],
                         'baz' => [ 'sea', 'power' ]
                       }
         ).each do |result|
     puts result['foo']
     puts result['bar']
     puts result['baz']
   end

where:

* ``:index`` is of name of the index on the Chef server against which the search query will run: ``:client``, ``:data_bag_name``, ``:environment``, ``:node``, and ``:role``
* ``'query'`` is a valid search query against an object on the Chef server
* ``:filter_result`` defines a Hash of values to be returned

For example:

.. code-block:: ruby

   search(:node, 'role:web',
     :filter_result => { 'name' => [ 'name' ],
                         'ip' => [ 'ipaddress' ],
                         'kernel_version' => [ 'kernel', 'version' ]
                       }
         ).each do |result|
     puts result['name']
     puts result['ip']
     puts result['kernel_version']
   end

.. end_tag

New in Chef Client 12.0.

Query Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag search_query_syntax

A search query is comprised of two parts: the key and the search pattern. A search query has the following syntax:

.. code-block:: ruby

   key:search_pattern

where ``key`` is a field name that is found in the JSON description of an indexable object on the Chef server (a role, node, client, environment, or data bag) and ``search_pattern`` defines what will be searched for, using one of the following search patterns: exact, wildcard, range, or fuzzy matching. Both ``key`` and ``search_pattern`` are case-sensitive; ``key`` has limited support for multiple character wildcard matching using an asterisk ("*") (and as long as it is not the first character).

.. end_tag

Keys
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag search_key

A field name/description pair is available in the JSON object. Use the field name when searching for this information in the JSON object. Any field that exists in any JSON description for any role, node, chef-client, environment, or data bag can be searched.

.. end_tag

**Nested Fields**

.. tag search_key_nested

A nested field appears deeper in the JSON data structure. For example, information about a network interface might be several layers deep: ``node[:network][:interfaces][:en1]``. When nested fields are present in a JSON structure, the chef-client will extract those nested fields to the top-level, flattening them into compound fields that support wildcard search patterns.

By combining wildcards with range-matching patterns and wildcard queries, it is possible to perform very powerful searches, such as using the vendor part of the MAC address to find every node that has a network card made by the specified vendor.

Consider the following snippet of JSON data:

.. code-block:: javascript

   {"network":
     [
     //snipped...
       "interfaces",
         {"en1": {
           "number": "1",
           "flags": [
             "UP",
             "BROADCAST",
             "SMART",
             "RUNNING",
             "SIMPLEX",
             "MULTICAST"
           ],
           "addresses": {
             "fe80::fa1e:dfff:fed8:63a2": {
               "scope": "Link",
               "prefixlen": "64",
               "family": "inet6"
             },
             "f8:1e:df:d8:63:a2": {
               "family": "lladdr"
             },
             "192.168.0.195": {
               "netmask": "255.255.255.0",
               "broadcast": "192.168.0.255",
               "family": "inet"
             }
           },
           "mtu": "1500",
           "media": {
             "supported": {
               "autoselect": {
                 "options": [

                 ]
               }
             },
             "selected": {
               "autoselect": {
                 "options": [

                 ]
               }
             }
           },
           "type": "en",
           "status": "active",
           "encapsulation": "Ethernet"
         },
     //snipped...

Before this data is indexed on the Chef server, the nested fields are extracted into the top level, similar to:

.. code-block:: none

   "broadcast" => "192.168.0.255",
   "flags"     => ["UP", "BROADCAST", "SMART", "RUNNING", "SIMPLEX", "MULTICAST"]
   "mtu"       => "1500"

which allows searches like the following to find data that is present in this node:

.. code-block:: ruby

   node "broadcast:192.168.0.*"

or:

.. code-block:: ruby

   node "mtu:1500"

or:

.. code-block:: ruby

   node "flags:UP"

This data is also flattened into various compound fields, which follow the same pattern as the JSON hierarchy and use underscores (``_``) to separate the levels of data, similar to:

.. code-block:: none

     # ...snip...
     "network_interfaces_en1_addresses_192.168.0.195_broadcast" => "192.168.0.255",
     "network_interfaces_en1_addresses_fe80::fa1e:tldr_family"  => "inet6",
     "network_interfaces_en1_addresses"                         => ["fe80::fa1e:tldr","f8:1e:df:tldr","192.168.0.195"]
     # ...snip...

which allows searches like the following to find data that is present in this node:

.. code-block:: ruby

   node "network_interfaces_en1_addresses:192.168.0.195"

This flattened data structure also supports using wildcard compound fields, which allow searches to omit levels within the JSON data structure that are not important to the search query. In the following example, an asterisk (``*``) is used to show where the wildcard can exist when searching for a nested field:

.. code-block:: ruby

   "network_interfaces_*_flags"     => ["UP", "BROADCAST", "SMART", "RUNNING", "SIMPLEX", "MULTICAST"]
   "network_interfaces_*_addresses" => ["fe80::fa1e:dfff:fed8:63a2", "192.168.0.195", "f8:1e:df:d8:63:a2"]
   "network_interfaces_en0_media_*" => ["autoselect", "none", "1000baseT", "10baseT/UTP", "100baseTX"]
   "network_interfaces_en1_*"       => ["1", "UP", "BROADCAST", "SMART", "RUNNING", "SIMPLEX", "MULTICAST",
                                        "fe80::fa1e:dfff:fed8:63a2", "f8:1e:df:d8:63:a2", "192.168.0.195",
                                        "1500", "supported", "selected", "en", "active", "Ethernet"]

For each of the wildcard examples above, the possible values are shown contained within the brackets. When running a search query, the query syntax for wildcards is to simply omit the name of the node (while preserving the underscores), similar to:

.. code-block:: ruby

   network_interfaces__flags

This query will search within the ``flags`` node, within the JSON structure, for each of ``UP``, ``BROADCAST``, ``SMART``, ``RUNNING``, ``SIMPLEX``, and ``MULTICAST``.

.. end_tag

Patterns
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag search_pattern

A search pattern is a way to fine-tune search results by returning anything that matches some type of incomplete search query. There are four types of search patterns that can be used when searching the search indexes on the Chef server: exact, wildcard, range, and fuzzy.

.. end_tag

**Exact Match**

.. tag search_pattern_exact

An exact matching search pattern is used to search for a key with a name that exactly matches a search query. If the name of the key contains spaces, quotes must be used in the search pattern to ensure the search query finds the key. The entire query must also be contained within quotes, so as to prevent it from being interpreted by Ruby or a command shell. The best way to ensure that quotes are used consistently is to quote the entire query using single quotes (' ') and a search pattern with double quotes (" ").

.. end_tag

**Wildcard Match**

.. tag search_pattern_wildcard

A wildcard matching search pattern is used to query for substring matches that replace zero (or more) characters in the search pattern with anything that could match the replaced character. There are two types of wildcard searches:

* A question mark (``?``) can be used to replace exactly one character (as long as that character is not the first character in the search pattern)
* An asterisk (``*``) can be used to replace any number of characters (including zero)

.. end_tag

**Range Match**

.. tag search_pattern_range

A range matching search pattern is used to query for values that are within a range defined by upper and lower boundaries. A range matching search pattern can be inclusive or exclusive of the boundaries. Use square brackets ("[ ]") to denote inclusive boundaries and curly braces ("{ }") to denote exclusive boundaries and with the following syntax:

.. code-block:: ruby

   boundary TO boundary

where ``TO`` is required (and must be capitalized).

.. end_tag

**Fuzzy Match**

.. tag search_pattern_fuzzy

A fuzzy matching search pattern is used to search based on the proximity of two strings of characters. An (optional) integer may be used as part of the search query to more closely define the proximity. A fuzzy matching search pattern has the following syntax:

.. code-block:: ruby

   "search_query"~edit_distance

where ``search_query`` is the string that will be used during the search and ``edit_distance`` is the proximity. A tilde ("~") is used to separate the edit distance from the search query.

.. end_tag

Operators
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag search_boolean_operators

An operator can be used to ensure that certain terms are included in the results, are excluded from the results, or are not included even when other aspects of the query match. Searches can use the following operators:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Operator
     - Description
   * - ``AND``
     - Use to find a match when both terms exist.
   * - ``OR``
     - Use to find a match if either term exists.
   * - ``NOT``
     - Use to exclude the term after ``NOT`` from the search results.

.. end_tag

Special Characters
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag search_special_characters

A special character can be used to fine-tune a search query and to increase the accuracy of the search results. The following characters can be included within the search query syntax, but each occurrence of a special character must be escaped with a backslash (``\``):

.. code-block:: ruby

   +  -  &&  | |  !  ( )  { }  [ ]  ^  "  ~  *  ?  :  \

For example:

.. code-block:: ruby

   \(1\+1\)\:2

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following examples show how the ``search`` method can be used in a recipe.

**Use the search recipe DSL method to find users**

.. tag resource_execute_use_search_dsl_method

The following example shows how to use the ``search`` method in the Recipe DSL to search for users:

.. code-block:: ruby

   #  the following code sample comes from the openvpn cookbook: https://github.com/chef-cookbooks/openvpn

   search("users", "*:*") do |u|
     execute "generate-openvpn-#{u['id']}" do
       command "./pkitool #{u['id']}"
       cwd '/etc/openvpn/easy-rsa'
       environment(
         'EASY_RSA' => '/etc/openvpn/easy-rsa',
         'KEY_CONFIG' => '/etc/openvpn/easy-rsa/openssl.cnf',
         'KEY_DIR' => node['openvpn']['key_dir'],
         'CA_EXPIRE' => node['openvpn']['key']['ca_expire'].to_s,
         'KEY_EXPIRE' => node['openvpn']['key']['expire'].to_s,
         'KEY_SIZE' => node['openvpn']['key']['size'].to_s,
         'KEY_COUNTRY' => node['openvpn']['key']['country'],
         'KEY_PROVINCE' => node['openvpn']['key']['province'],
         'KEY_CITY' => node['openvpn']['key']['city'],
         'KEY_ORG' => node['openvpn']['key']['org'],
         'KEY_EMAIL' => node['openvpn']['key']['email']
       )
       not_if { File.exist?("#{node['openvpn']['key_dir']}/#{u['id']}.crt") }
     end

     %w{ conf ovpn }.each do |ext|
       template "#{node['openvpn']['key_dir']}/#{u['id']}.#{ext}" do
         source 'client.conf.erb'
         variables :username => u['id']
       end
     end

     execute "create-openvpn-tar-#{u['id']}" do
       cwd node['openvpn']['key_dir']
       command <<-EOH
         tar zcf #{u['id']}.tar.gz \
         ca.crt #{u['id']}.crt #{u['id']}.key \
         #{u['id']}.conf #{u['id']}.ovpn \
       EOH
       not_if { File.exist?("#{node['openvpn']['key_dir']}/#{u['id']}.tar.gz") }
     end
   end

where

* the search will use both of the **execute** resources, unless the condition specified by the ``not_if`` commands are met
* the ``environments`` property in the first **execute** resource is being used to define values that appear as variables in the OpenVPN configuration
* the **template** resource tells the chef-client which template to use

.. end_tag

shell_out
-----------------------------------------------------
.. tag dsl_recipe_method_shell_out

The ``shell_out`` method can be used to run a command against the node, and then display the output to the console when the log level is set to ``debug``.

The syntax for the ``shell_out`` method is as follows:

.. code-block:: ruby

   shell_out(command_args)

where ``command_args`` is the command that is run against the node.

.. end_tag

New in Chef Client 12.0.

shell_out!
-----------------------------------------------------
.. tag dsl_recipe_method_shell_out_bang

The ``shell_out!`` method can be used to run a command against the node, display the output to the console when the log level is set to ``debug``, and then raise an error when the method returns ``false``.

The syntax for the ``shell_out!`` method is as follows:

.. code-block:: ruby

   shell_out!(command_args)

where ``command_args`` is the command that is run against the node. This method will return ``true`` or ``false``.

.. end_tag

New in Chef Client 12.0.

shell_out_with_systems_locale
-----------------------------------------------------
.. tag dsl_recipe_method_shell_out_with_systems_locale

The ``shell_out_with_systems_locale`` method can be used to run a command against the node (via the ``shell_out`` method), but using the ``LC_ALL`` environment variable.

The syntax for the ``shell_out_with_systems_locale`` method is as follows:

.. code-block:: ruby

   shell_out_with_systems_locale(command_args)

where ``command_args`` is the command that is run against the node.

.. end_tag

New in Chef Client 12.0.

tag, tagged?, untag
-----------------------------------------------------
.. tag chef_tags

A tag is a custom description that is applied to a node. A tag, once applied, can be helpful when managing nodes using knife or when building recipes by providing alternate methods of grouping similar types of information.

.. end_tag

.. tag cookbooks_recipe_tags

Tags can be added and removed. Machines can be checked to see if they already have a specific tag. To use tags in your recipe simply add the following:

.. code-block:: ruby

   tag('mytag')

To test if a machine is tagged, add the following:

.. code-block:: ruby

   tagged?('mytag')

to return ``true`` or ``false``. ``tagged?`` can also use an array as an argument.

To remove a tag:

.. code-block:: ruby

   untag('mytag')

For example:

.. code-block:: ruby

   tag('machine')

   if tagged?('machine')
      Chef::Log.info('Hey I'm #{node[:tags]}')
   end

   untag('machine')

   if not tagged?('machine')
      Chef::Log.info('I has no tagz')
   end

Will return something like this:

.. code-block:: none

   [Thu, 22 Jul 2010 18:01:45 +0000] INFO: Hey I'm machine
   [Thu, 22 Jul 2010 18:01:45 +0000] INFO: I has no tagz

.. end_tag

value_for_platform
-----------------------------------------------------
Use the ``value_for_platform`` method in a recipe to select a value based on the ``node['platform']`` and ``node['platform_version']`` attributes. These values are detected by Ohai during every chef-client run.

The syntax for the ``value_for_platform`` method is as follows:

.. code-block:: ruby

   value_for_platform( ['platform', ...] => { 'version' => 'value' } )

where:

* ``'platform', ...`` is a comma-separated list of platforms, such as Red Hat, openSUSE, or Fedora
* ``version`` specifies the version of that platform
* Version constraints---``>``, ``<``, ``>=``, ``<=``, ``~>``---may be used with ``version``; an exception is raised if two version constraints match; an exact match will always take precedence over a match made from a version constraint
* ``value`` specifies the value that will be used if the node's platform matches the ``value_for_platform`` method

When each value only has a single platform, use the following syntax:

.. code-block:: ruby

   value_for_platform(
     'platform' => { 'version' => 'value' },
     'platform' => { 'version' => 'value' },
     'platform' => 'value'
   )

When each value has more than one platform, the syntax changes to:

.. code-block:: ruby

   value_for_platform(
     ['platform', 'platform', ... ] => {
       'version' => 'value'
     },
   )

Changed in Chef Client 12.0 to support version constraints.

Operators
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag cookbooks_version_constraints_operators

The following operators may be used:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Operator
     - Description
   * - ``=``
     - equal to
   * - ``>``
     - greater than
   * - ``<``
     - less than
   * - ``>=``
     - greater than or equal to; also known as "optimistically greater than", or "optimistic"
   * - ``<=``
     - less than or equal to
   * - ``~>``
     - approximately greater than; also known as "pessimistically greater than", or "pessimistic"

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following example will set ``package_name`` to ``httpd`` for the Red Hat platform and to ``apache2`` for the Debian platform:

.. code-block:: ruby

   package_name = value_for_platform(
     ['centos', 'redhat', 'suse', 'fedora' ] => {
       'default' => 'httpd'
     },
     ['ubuntu', 'debian'] => {
       'default' => 'apache2'
     }
   )

The following example will set ``package`` to ``apache-couchdb`` for OpenBSD platforms, ``dev-db/couchdb`` for Gentoo platforms, and ``couchdb`` for all other platforms:

.. code-block:: ruby

   package = value_for_platform(
     'openbsd' => { 'default' => 'apache-couchdb' },
     'gentoo' => { 'default' => 'dev-db/couchdb' },
     'default' => 'couchdb'
   )

The following example shows using version constraints to specify a value based on the version:

.. code-block:: ruby

   value_for_platform(
     'os1' => { '< 1.0' => 'less than 1.0',
                '~> 2.0' => 'version 2.x',
                '>= 3.0' => 'version 3.0',
                '3.0.1' => '3.0.1 will always use this value' }
   )

value_for_platform_family
-----------------------------------------------------
Use the ``value_for_platform_family`` method in a recipe to select a value based on the ``node['platform_family']`` attribute. This value is detected by Ohai during every chef-client run.

The syntax for the ``value_for_platform_family`` method is as follows:

.. code-block:: ruby

   value_for_platform_family( 'platform_family' => 'value', ... )

where:

* ``'platform_family' => 'value', ...`` is a comma-separated list of platforms, such as Fedora, openSUSE, or Red Hat Enterprise Linux
* ``value`` specifies the value that will be used if the node's platform family matches the ``value_for_platform_family`` method

When each value only has a single platform, use the following syntax:

.. code-block:: ruby

   value_for_platform_family(
     'platform_family' => 'value',
     'platform_family' => 'value',
     'platform_family' => 'value'
   )

When each value has more than one platform, the syntax changes to:

.. code-block:: ruby

   value_for_platform_family(
     ['platform_family', 'platform_family', 'platform_family', 'platform_family' ] => 'value',
     ['platform_family', 'platform_family'] => 'value',
     'default' => 'value'
   )

The following example will set ``package`` to ``httpd-devel`` for the Red Hat Enterprise Linux, Fedora, and openSUSE platforms and to ``apache2-dev`` for the Debian platform:

.. code-block:: ruby

   package = value_for_platform_family(
     ['rhel', 'fedora', 'suse'] => 'httpd-devel',
       'debian' => 'apache2-dev'
   )

with_run_context
-----------------------------------------------------
.. tag dsl_recipe_method_with_run_context

Use the ``with_run_context`` method to define a block that has a pointer to a location in the ``run_context`` hierarchy. Resources in recipes always run at the root of the ``run_context`` hierarchy, whereas custom resources and notification blocks always build a child ``run_context`` which contains their sub-resources.

The syntax for the ``with_run_context`` method is as follows:

.. code-block:: ruby

   with_run_context :type do
     # some arbitrary pure Ruby stuff goes here
   end

where ``:type`` may be one of the following:

* ``:root`` runs the block as part of the root ``run_context`` hierarchy
* ``:parent`` runs the block as part of the parent process in the ``run_context`` hierarchy

For example:

.. code-block:: ruby

   action :run do
     with_run_context :root do
       edit_resource(:my_thing, "accumulated state") do
         action :nothing
         my_array_property << accumulate_some_stuff
       end
     end
     log "kick it off" do
       notifies :run, "my_thing[accumulated state], :delayed
     end
   end

.. end_tag

Event Handlers
=====================================================
.. note:: Event handlers are not specifically part of the Recipe DSL. An event handler is declared using the ``Chef.event_hander`` method, which declares the event handler within recipes in a similar manner to other Recipe DSL methods.

.. tag dsl_handler_summary

Use the Handler DSL to attach a callback to an event. If the event occurs during the chef-client run, the associated callback is executed. For example:

* Sending email if a chef-client run fails
* Sending a notification to chat application if an audit run fails
* Aggregating statistics about resources updated during a chef-client runs to StatsD

.. end_tag

on Method
-----------------------------------------------------
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
-----------------------------------------------------
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

Examples
-----------------------------------------------------
The following examples show ways to use the Handler DSL.

Send Email
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_handler_slide_send_email

Use the ``on`` method to create an event handler that sends email when the chef-client run fails. This will require:

* A way to tell the chef-client how to send email
* An event handler that describes what to do when the ``:run_failed`` event is triggered
* A way to trigger the exception and test the behavior of the event handler

.. end_tag

**Define How Email is Sent**

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

**Add the Handler**

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

**Test the Handler**

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
+++++++++++++++++++++++++++++++++++++++++++++++++++++
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
+++++++++++++++++++++++++++++++++++++++++++++++++++++
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

Windows Platform
=====================================================
.. tag dsl_recipe_method_windows_methods

Six methods are present in the Recipe DSL to help verify the registry during a chef-client run on the Microsoft Windows platform---``registry_data_exists?``, ``registry_get_subkeys``, ``registry_get_values``, ``registry_has_subkeys?``, ``registry_key_exists?``, and ``registry_value_exists?``---these helpers ensure the **powershell_script** resource is idempotent.

.. end_tag

.. note:: .. tag notes_dsl_recipe_order_for_windows_methods

          The recommended order in which registry key-specific methods should be used within a recipe is: ``key_exists?``, ``value_exists?``, ``data_exists?``, ``get_values``, ``has_subkeys?``, and then ``get_subkeys``.

          .. end_tag

registry_data_exists?
-----------------------------------------------------
.. tag dsl_recipe_method_registry_data_exists

Use the ``registry_data_exists?`` method to find out if a Microsoft Windows registry key contains the specified data of the specified type under the value.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_data_exists?`` method is as follows:

.. code-block:: ruby

   registry_data_exists?(
     KEY_PATH,
     { :name => 'NAME', :type => TYPE, :data => DATA },
     ARCHITECTURE
   )

where:

* ``KEY_PATH`` is the path to the registry key value. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``{ :name => 'NAME', :type => TYPE, :data => DATA }`` is a hash that contains the expected name, type, and data of the registry key value
* ``:type`` represents the values available for registry keys in Microsoft Windows. Use ``:binary`` for REG_BINARY, ``:string`` for REG_SZ, ``:multi_string`` for REG_MULTI_SZ, ``:expand_string`` for REG_EXPAND_SZ, ``:dword`` for REG_DWORD, ``:dword_big_endian`` for REG_DWORD_BIG_ENDIAN, or ``:qword`` for REG_QWORD.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_get_subkeys
-----------------------------------------------------
.. tag dsl_recipe_method_registry_get_subkeys

Use the ``registry_get_subkeys`` method to get a list of registry key values that are present for a Microsoft Windows registry key.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_get_subkeys`` method is as follows:

.. code-block:: ruby

   subkey_array = registry_get_subkeys(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This returns an array of registry key values.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_get_values
-----------------------------------------------------
.. tag dsl_recipe_method_registry_get_values

Use the ``registry_get_values`` method to get the registry key values (name, type, and data) for a Microsoft Windows registry key.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_get_values`` method is as follows:

.. code-block:: ruby

   subkey_array = registry_get_values(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This returns an array of registry key values.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_has_subkeys?
-----------------------------------------------------
.. tag dsl_recipe_method_registry_has_subkeys

Use the ``registry_has_subkeys?`` method to find out if a Microsoft Windows registry key has one (or more) values.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_has_subkeys?`` method is as follows:

.. code-block:: ruby

   registry_has_subkeys?(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_key_exists?
-----------------------------------------------------
.. tag dsl_recipe_method_registry_key_exists

Use the ``registry_key_exists?`` method to find out if a Microsoft Windows registry key exists at the specified path.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_key_exists?`` method is as follows:

.. code-block:: ruby

   registry_key_exists?(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``. (Any registry key values that are associated with this registry key are ignored.)

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_value_exists?
-----------------------------------------------------
.. tag dsl_recipe_method_registry_value_exists

Use the ``registry_value_exists?`` method to find out if a registry key value exists. Use ``registry_data_exists?`` to test for the type and data of a registry key value.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_value_exists?`` method is as follows:

.. code-block:: ruby

   registry_value_exists?(
     KEY_PATH,
     { :name => 'NAME' },
     ARCHITECTURE
   )

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``{ :name => 'NAME' }`` is a hash that contains the name of the registry key value; if either ``:type`` or ``:value`` are specified in the hash, they are ignored
* ``:type`` represents the values available for registry keys in Microsoft Windows. Use ``:binary`` for REG_BINARY, ``:string`` for REG_SZ, ``:multi_string`` for REG_MULTI_SZ, ``:expand_string`` for REG_EXPAND_SZ, ``:dword`` for REG_DWORD, ``:dword_big_endian`` for REG_DWORD_BIG_ENDIAN, or ``:qword`` for REG_QWORD.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

Helpers
-----------------------------------------------------
.. tag dsl_recipe_helper_windows_platform

A recipe can define specific behaviors for specific Microsoft Windows platform versions by using a series of helper methods. To enable these helper methods, add the following to a recipe:

.. code-block:: ruby

   require 'chef/win32/version'

Then declare a variable using the ``Chef::ReservedNames::Win32::Version`` class:

.. code-block:: ruby

   variable_name = Chef::ReservedNames::Win32::Version.new

And then use this variable to define specific behaviors for specific Microsoft Windows platform versions. For example:

.. code-block:: ruby

   if variable_name.helper_name?
     # Ruby code goes here, such as
     resource_name do
       # resource block
     end

   elsif variable_name.helper_name?
     # Ruby code goes here
     resource_name do
       # resource block for something else
     end

   else variable_name.helper_name?
     # Ruby code goes here, such as
     log 'log entry' do
       level :level
     end

   end

.. end_tag

.. tag dsl_recipe_helper_windows_platform_helpers

The following Microsoft Windows platform-specific helpers can be used in recipes:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Helper
     - Description
   * - ``cluster?``
     - Use to test for a Cluster SKU (Windows Server 2003 and later).
   * - ``core?``
     - Use to test for a Core SKU (Windows Server 2003 and later).
   * - ``datacenter?``
     - Use to test for a Datacenter SKU.
   * - ``marketing_name``
     - Use to display the marketing name for a Microsoft Windows platform.
   * - ``windows_7?``
     - Use to test for Windows 7.
   * - ``windows_8?``
     - Use to test for Windows 8.
   * - ``windows_8_1?``
     - Use to test for Windows 8.1.
   * - ``windows_2000?``
     - Use to test for Windows 2000.
   * - ``windows_home_server?``
     - Use to test for Windows Home Server.
   * - ``windows_server_2003?``
     - Use to test for Windows Server 2003.
   * - ``windows_server_2003_r2?``
     - Use to test for Windows Server 2003 R2.
   * - ``windows_server_2008?``
     - Use to test for Windows Server 2008.
   * - ``windows_server_2008_r2?``
     - Use to test for Windows Server 2008 R2.
   * - ``windows_server_2012?``
     - Use to test for Windows Server 2012.
   * - ``windows_server_2012_r2?``
     - Use to test for Windows Server 2012 R2.
   * - ``windows_vista?``
     - Use to test for Windows Vista.
   * - ``windows_xp?``
     - Use to test for Windows XP.

.. end_tag

.. tag dsl_recipe_helper_windows_platform_summary

The following example installs Windows PowerShell 2.0 on systems that do not already have it installed. Microsoft Windows platform helper methods are used to define specific behaviors for specific platform versions:

.. code-block:: ruby

   case node['platform']
   when 'windows'

     require 'chef/win32/version'
     windows_version = Chef::ReservedNames::Win32::Version.new

     if (windows_version.windows_server_2008_r2? || windows_version.windows_7?) && windows_version.core?

       windows_feature 'NetFx2-ServerCore' do
         action :install
       end
       windows_feature 'NetFx2-ServerCore-WOW64' do
         action :install
         only_if { node['kernel']['machine'] == 'x86_64' }
       end

     elsif windows_version.windows_server_2008? || windows_version.windows_server_2003_r2? ||
         windows_version.windows_server_2003? || windows_version.windows_xp?

       if windows_version.windows_server_2008?
         windows_feature 'NET-Framework-Core' do
           action :install
         end

       else
         windows_package 'Microsoft .NET Framework 2.0 Service Pack 2' do
           source node['ms_dotnet2']['url']
           checksum node['ms_dotnet2']['checksum']
           installer_type :custom
           options '/quiet /norestart'
           action :install
         end
       end
     else
       log '.NET Framework 2.0 is already enabled on this version of Windows' do
         level :warn
       end
     end
   else
     log '.NET Framework 2.0 cannot be installed on platforms other than Windows' do
       level :warn
     end
   end

The previous example is from the `ms_dotnet2 cookbook <https://github.com/juliandunn/ms_dotnet2>`_, created by community member ``juliandunn``.

.. end_tag
