=====================================================
Chef Style Guide
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/ruby.rst>`__

.. tag ruby_summary

Ruby is a simple programming language:

* Chef uses Ruby as its reference language to define the patterns that are found in resources, recipes, and cookbooks
* Use these patterns to configure, deploy, and manage nodes across the network

Ruby is also a powerful and complete programming language:

* Use the Ruby programming language to make decisions about what should happen to specific resources and recipes
* Extend Chef in any manner that your organization requires

.. end_tag

Changed in Chef Client 12.14 to recommend Ruby 2.3.1; 12.13 recommended Ruby 2.1.9; 12.0 recommended Ruby 2.0.

As of Chef Client 12.0, Chef does not support Ruby versions prior to 2.0.

Ruby Basics
=====================================================
This section covers the basics of Ruby.

Verify Syntax
-----------------------------------------------------
Many people who are new to Ruby often find that it doesn't take very long to get up to speed with the basics. For example, it's useful to know how to check the syntax of a Ruby file, such as the contents of a cookbook named ``my_cookbook.rb``:

.. code-block:: bash

   $ ruby -c my_cookbook_file.rb

to return:

.. code-block:: bash

   Syntax OK

Comments
-----------------------------------------------------
Use a comment to explain code that exists in a cookbook or recipe. Anything after a ``#`` is a comment.

.. code-block:: ruby

   # This is a comment.

Local Variables
-----------------------------------------------------
Assign a local variable:

.. code-block:: ruby

   x = 1

Math
-----------------------------------------------------
Do some basic arithmetic:

.. code-block:: ruby

   1 + 2           # => 3
   2 * 7           # => 14
   5 / 2           # => 2   (because both arguments are whole numbers)
   5 / 2.0         # => 2.5 (because one of the numbers had a decimal place)
   1 + (2 * 3)     # => 7   (you can use parens to group expressions)

Strings
-----------------------------------------------------
Work with strings:

.. code-block:: ruby

   'single quoted'   # => "single quoted"
   "double quoted"   # => "double quoted"
   'It\'s alive!'    # => "It's alive!" (the \ is an escape character)
   '1 + 2 = 5'       # => "1 + 2 = 5" (numbers surrounded by quotes behave like strings)

Convert a string to uppercase or lowercase. For example, a hostname named "Foo":

.. code-block:: ruby

   node['hostname'].downcase    # => "foo"
   node['hostname'].upcase      # => "FOO"

Ruby in Strings
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Embed Ruby in a string:

.. code-block:: ruby

   x = 'Bob'
   "Hi, #{x}"      # => "Hi, Bob"
   'Hello, #{x}'   # => "Hello, \#{x}" Notice that single quotes don't work with #{}

Escape Character
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the backslash character (``\``) as an escape character when quotes must appear within strings. However, you do not need to escape single quotes inside double quotes. For example:

.. code-block:: ruby

   'It\'s alive!'                        # => "It's alive!"
   "Won\'t you read Grant\'s book?"      # => "Won't you read Grant's book?"

Interpolation
+++++++++++++++++++++++++++++++++++++++++++++++++++++
When strings have quotes within quotes, use double quotes (``" "``) on the outer quotes, and then single quotes (``' '``) for the inner quotes. For example:

.. code-block:: ruby

   Chef::Log.info("Loaded from aws[#{aws['id']}]")

.. code-block:: ruby

   "node['mysql']['secretpath']"

.. code-block:: ruby

   "#{ENV['HOME']}/chef.txt"

.. code-block:: ruby

   antarctica_hint = hint?('antarctica')
   if antarctica_hint['snow']
     "There are #{antarctica_hint['penguins']} penguins here."
   else
     'There is no snow here, and penguins like snow.'
   end

Truths
-----------------------------------------------------
Work with basic truths:

.. code-block:: ruby

   true            # => true
   false           # => false
   nil             # => nil
   0               # => true ( the only false values in Ruby are false
                   #    and nil; in other words: if it exists in Ruby,
                   #    even if it exists as zero, then it is true.)
   1 == 1          # => true ( == tests for equality )
   1 == true       # => false ( == tests for equality )

Untruths
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Work with basic untruths (``!`` means not!):

.. code-block:: ruby

   !true           # => false
   !false          # => true
   !nil            # => true
   1 != 2          # => true (1 is not equal to 2)
   1 != 1          # => false (1 is not not equal to itself)

Convert Truths
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Convert something to either true or false (``!!`` means not not!!):

.. code-block:: ruby

   !!true          # => true
   !!false         # => false
   !!nil           # => false (when pressed, nil is false)
   !!0             # => true (zero is NOT false).

Arrays
-----------------------------------------------------
Create lists using arrays:

.. code-block:: ruby

   x = ['a', 'b', 'c']   # => ["a", "b", "c"]
   x[0]                  # => "a" (zero is the first index)
   x.first               # => "a" (see?)
   x.last                # => "c"
   x + ['d']             # => ["a", "b", "c", "d"]
   x                     # => ["a", "b", "c"] ( x is unchanged)
   x = x + ['d']         # => ["a", "b", "c", "d"]
   x                     # => ["a", "b", "c", "d"]

.. whitespace arrays assumes you understand what Array#include? is
.. introduce `[ "foo", "bar", "baz" ].each do |thing|` first, then introduce `%w{foo bar baz}.each do |thing|`
.. or just use #first or #last, since they are sort of introduced already
.. %w{debian ubuntu}.first  # => "debian"

Whitespace Arrays
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag ruby_style_basics_array_shortcut

The ``%w`` syntax is a Ruby shortcut for creating an array without requiring quotes and commas around the elements.

For example:

.. code-block:: ruby

   if %w(debian ubuntu).include?(node['platform'])
     # do debian/ubuntu things with the Ruby array %w() shortcut
   end

.. end_tag

.. tag ruby_style_patterns_string_quoting_vs_whitespace_array

When ``%w`` syntax uses a variable, such as ``|foo|``, double quoted strings should be used.

Right:

.. code-block:: ruby

   %w(openssl.cnf pkitool vars Rakefile).each do |foo|
     template "/etc/openvpn/easy-rsa/#{foo}" do
       source "#{foo}.erb"
       ...
     end
   end

Wrong:

.. code-block:: ruby

   %w(openssl.cnf pkitool vars Rakefile).each do |foo|
     template '/etc/openvpn/easy-rsa/#{foo}' do
       source '#{foo}.erb'
       ...
     end
   end

.. end_tag

**Example**

WiX includes serveral tools -- such as ``candle`` (preprocesses and compiles source files into object files), ``light`` (links and binds object files to an installer database), and ``heat`` (harvests files from various input formats). The following example uses a whitespace array and the InSpec ``file`` audit resource to verify if these three tools are present:

.. code-block:: ruby

   %w(
     candle.exe
     heat.exe
     light.exe
   ).each do |utility|
     describe file("C:/wix/#{utility}") do
       it { should be_file }
     end
   end

Hash
-----------------------------------------------------
A Hash is a list with keys and values. Sometimes hashes don't have a set order:

.. code-block:: ruby

   h = {
     'first_name' => 'Bob',
     'last_name'  => 'Jones'
   }

And sometimes they do. For example, first name then last name:

.. code-block:: ruby

   h.keys              # => ["first_name", "last_name"]
   h['first_name']     # => "Bob"
   h['last_name']      # => "Jones"
   h['age'] = 23
   h.keys              # => ["first_name", "age", "last_name"]
   h.values            # => ["Jones", "Bob", 23]

Regular Expressions
-----------------------------------------------------
Use Perl-style regular expressions:

.. code-block:: ruby

   'I believe'  =~ /I/                       # => 0 (matches at the first character)
   'I believe'  =~ /lie/                     # => 4 (matches at the 5th character)
   'I am human' =~ /bacon/                   # => nil (no match - bacon comes from pigs)
   'I am human' !~ /bacon/                   # => true (correct, no bacon here)
   /give me a ([0-9]+)/ =~ 'give me a 7'     # => 0 (matched)

Statements
-----------------------------------------------------
Use conditions! For example, an ``if`` statement

.. code-block:: ruby

   if false
     # this won't happen
   elsif nil
     # this won't either
   else
     # code here will run though
   end

or a ``case`` statement:

.. code-block:: ruby

   x = 'dog'
   case x
   when 'fish'
    # this won't happen
   when 'dog', 'cat', 'monkey'
     # this will run
   else
     # the else is an optional catch-all
   end

if
+++++++++++++++++++++++++++++++++++++++++++++++++++++
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

case
+++++++++++++++++++++++++++++++++++++++++++++++++++++
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

Call a Method
-----------------------------------------------------
Call a method on something with ``.method_name()``:

.. code-block:: ruby

   x = 'My String'
   x.split(' ')            # => ["My", "String"]
   x.split(' ').join(', ') # => "My, String"

Define a Method
-----------------------------------------------------
Define a method (or a function, if you like):

.. code-block:: ruby

   def do_something_useless( first_argument, second_argument)
     puts "You gave me #{first_argument} and #{second_argument}"
   end

   do_something_useless( 'apple', 'banana')
   # => "You gave me apple and banana"
   do_something_useless 1, 2
   # => "You gave me 1 and 2"
   # see how the parens are optional if there's no confusion about what to do

Ruby Class
-----------------------------------------------------
Use the Ruby ``File`` class in a recipe. Because Chef has the **file** resource, use ``File`` to use the Ruby ``File`` class. For example:

.. code-block:: ruby

   execute 'apt-get-update' do
     command 'apt-get update'
     ignore_failure true
     only_if { apt_installed? }
     not_if { File.exist?('/var/lib/apt/periodic/update-success-stamp') }
   end

Include a Class
-----------------------------------------------------
Use ``:include`` to include another Ruby class. For example:

.. code-block:: ruby

   ::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

In non-Chef Ruby, the syntax is ``include`` (without the ``:`` prefix), but without the ``:`` prefix the chef-client will try to find a provider named ``include``. Using the ``:`` prefix tells the chef-client to look for the specified class that follows.

Include a Parameter
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

Log Entries
-----------------------------------------------------
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

The following examples show using ``Chef::Log`` entries in a recipe.

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

Patterns to Follow
=====================================================
This section covers best practices for cookbook and recipe authoring.

git Etiquette
-----------------------------------------------------
Although not strictly a Chef style thing, please always ensure your ``user.name`` and ``user.email`` are set properly in your ``.gitconfig`` file.

* ``user.name`` should be your given name (e.g., "Julian Dunn")
* ``user.email`` should be an actual, working e-mail address

This will prevent commit log entries similar to ``"guestuser <login@Bobs-Macbook-Pro.local>"``, which are unhelpful.

Use of Hyphens
-----------------------------------------------------
.. tag ruby_style_patterns_hyphens

Cookbook and custom resource names should contain only alphanumeric characters. A hyphen (``-``) is a valid character and may be used in cookbook and custom resource names, but it is discouraged. The chef-client will return an error if a hyphen is not converted to an underscore (``_``) when referencing from a recipe the name of a custom resource in which a hyphen is located.

.. end_tag

Cookbook Naming
-----------------------------------------------------
Use a short organizational prefix for application cookbooks that are part of your organization. For example, if your organization is named SecondMarket, use ``sm`` as a prefix: ``sm_postgresql`` or ``sm_httpd``.

Cookbook Versioning
-----------------------------------------------------
* Use semantic versioning when numbering cookbooks.
* Only upload stable cookbooks from master.
* Only upload unstable cookbooks from the dev branch. Merge to master and bump the version when stable.
* Always update CHANGELOG.md with any changes, with the JIRA ticket and a brief description.

Cookbook Patterns
-----------------------------------------------------
Good cookbook examples:

* https://github.com/chef-cookbooks/tomcat
* https://github.com/chef-cookbooks/apparmor
* https://github.com/chef-cookbooks/mysql
* https://github.com/chef-cookbooks/httpd

Naming
-----------------------------------------------------
Name things uniformly for their system and component. For example:

* attributes: ``node['foo']['bar']``
* recipe: ``foo::bar``
* role: ``foo-bar``
* directories: ``foo/bar`` (if specific to component), ``foo`` (if not). For example: ``/var/log/foo/bar``.

Name attributes after the recipe in which they are primarily used. e.g. ``node['postgresql']['server']``.

Parameter Order
-----------------------------------------------------
Follow this order for information in each resource declaration:

* Source
* Cookbook
* Resource ownership
* Permissions
* Notifications
* Action

For example:

.. code-block:: ruby

   template '/tmp/foobar.txt' do
     source 'foobar.txt.erb'
     owner  'someuser'
     group  'somegroup'
     mode   '0644'
     variables(
       foo: 'bar'
     )
     notifies :reload, 'service[whatever]'
     action :create
   end

File Modes
-----------------------------------------------------
Always specify the file mode with a quoted 3-5 character string that defines the octal mode:

.. code-block:: ruby

   mode '755'

.. code-block:: ruby

   mode '0755'

Wrong:

.. code-block:: ruby

   mode 755

Specify Resource Action?
-----------------------------------------------------
A resource declaration does not require the action to be specified because the chef-client will apply the default action for a resource automatically if it's not specified within the resource block. For example:

.. code-block:: ruby

   package 'monit'

will install the ``monit`` package because the ``:install`` action is the default action for the **package** resource.

However, if readability of code is desired, such as ensuring that a reader understands what the default action is for a custom resource or stating the action for a resource whose default may not be immediately obvious to the reader, specifying the default action is recommended:

.. code-block:: ruby

   ohai 'apache_modules' do
     action :reload
   end

Symbols or Strings?
-----------------------------------------------------
Prefer strings over symbols, because they're easier to read and you don't need to explain to non-Rubyists what a symbol is. Please retrofit old cookbooks as you come across them.

Right:

.. code-block:: ruby

   default['foo']['bar'] = 'baz'

Wrong:

.. code-block:: ruby

   default[:foo][:bar] = 'baz'

String Quoting
-----------------------------------------------------
Use single-quoted strings in all situations where the string doesn't need interpolation.

Whitespace Arrays
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag ruby_style_patterns_string_quoting_vs_whitespace_array

When ``%w`` syntax uses a variable, such as ``|foo|``, double quoted strings should be used.

Right:

.. code-block:: ruby

   %w(openssl.cnf pkitool vars Rakefile).each do |foo|
     template "/etc/openvpn/easy-rsa/#{foo}" do
       source "#{foo}.erb"
       ...
     end
   end

Wrong:

.. code-block:: ruby

   %w(openssl.cnf pkitool vars Rakefile).each do |foo|
     template '/etc/openvpn/easy-rsa/#{foo}' do
       source '#{foo}.erb'
       ...
     end
   end

.. end_tag

Shelling Out
-----------------------------------------------------
Always use ``mixlib-shellout`` to shell out. Never use backticks, Process.spawn, popen4, or anything else!

The `mixlib-shellout module <https://github.com/chef/mixlib-shellout/blob/master/README.md>`__ provides a simplified interface to shelling out while still collecting both standard out and standard error and providing full control over environment, working directory, uid, gid, etc.

New in Chef Client 12.0 you can use the ``shell_out``, ``shell_out!`` and ``shell_out_with_system_locale`` :doc:`Recipe DSL methods </dsl_recipe>` to interface directly with ``mixlib-shellout``.

Constructs to Avoid
-----------------------------------------------------
Avoid the following patterns:

* ``node.set`` / ``normal_attributes`` - Avoid using attributes at normal precedence since they are set directly on the node object itself, rather than implied (computed) at runtime.
* ``node.set_unless`` - Can lead to weird behavior if the node object had something set. Avoid unless altogether necessary (one example where it's necessary is in ``node['postgresql']['server']['password']``)
* if ``node.run_list.include?('foo')`` i.e. branching in recipes based on what's in the node's run-list. Better and more readable to use a feature flag and set its precedence appropriately.
* ``node['foo']['bar']`` i.e. setting normal attributes without specifying precedence. This is deprecated in Chef 11, so either use ``node.set['foo']['bar']`` to replace its precedence in-place or choose the precedence to suit.

Recipes
-----------------------------------------------------
A recipe should be clean and well-commented. For example:

.. code-block:: ruby

   ###########
   # variables
   ###########

   connection_info = {
     host: '127.0.0.1',
     port: '3306',
     username: 'root',
     password: 'm3y3sqlr00t'
   }

   #################
   # Mysql resources
   #################

   mysql_service 'default' do
     port '3306'
     initial_root_password 'm3y3sqlr00t'
     action [:create, :start]
   end

   mysql_database 'wordpress_demo' do
     connection connection_info
     action :create
   end

   mysql_database_user 'wordpress_user' do
     connection connection_info
     database_name 'wordpress_demo'
     password 'w0rdpr3ssdem0'
     privileges [:create, :delete, :select, :update, :insert]
     action :grant
   end

   ##################
   # Apache resources
   ##################

   httpd_service 'default' do
     listen_ports %w(80)
     mpm 'prefork'
     action [:create, :start]
   end

   httpd_module 'php' do
     notifies :restart, 'httpd_service[default]'
     action :create
   end

   ###############
   # Php resources
   ###############

   package 'php-gd' do
     action :install
   end

   package 'php-mysql' do
     action :install
   end

   directory '/etc/php.d' do
     action :create
   end

   template '/etc/php.d/mysql.ini' do
     source 'mysql.ini.erb'
     action :create
   end

   httpd_config 'php' do
     source 'php.conf.erb'
     notifies :restart, 'httpd_service[default]'
     action :create
   end

   #####################
   # wordpress resources
   #####################

   directory '/srv/wordpress_demo' do
     user 'apache'
     recursive true
     action :create
   end

   tar_extract 'https://wordpress.org/wordpress-4.1.tar.gz' do
     target_dir '/srv/wordpress_demo'
     tar_flags ['--strip-components 1']
     user 'apache'
     creates '/srv/wordpress_demo/index.php'
     action :extract
   end

   directory '/srv/wordpress_demo/wp-content' do
     user 'apache'
     action :create
   end

   httpd_config 'wordpress' do
     source 'wordpress.conf.erb'
     variables(
       servername: 'wordpress',
       server_aliases: %w(computers.biz www.computers.biz),
       document_root: '/srv/wordpress_demo'
       )
     notifies :restart, 'httpd_service[default]'
     action :create
   end

   template '/srv/wordpress_demo/wp-config.php' do
     source 'wp-config.php.erb'
     owner 'apache'
     variables(
       db_name: 'wordpress_demo',
       db_user: 'wordpress_user',
       db_password: 'w0rdpr3ssdem0',
       db_host: '127.0.0.1',
       db_prefix: 'wp_',
       db_charset: 'utf8',
       auth_key: 'You should probably use randomly',
       secure_auth_key: 'generated strings. These can be hard',
       logged_in_key: 'coded, pulled from encrypted databags,',
       nonce_key: 'or a ruby function that accessed an',
       auth_salt: 'arbitrary data source, such as a password',
       secure_auth_salt: 'vault. Node attributes could work',
       logged_in_salt: 'as well, but you take special care',
       nonce_salt: 'so they are not saved to your chef-server.',
       allow_multisite: 'false'
       )
     action :create
   end

Patterns to Avoid
=====================================================
This section covers things that should be avoided when authoring cookbooks and recipes.

node.set
-----------------------------------------------------
Use ``node.default`` (or maybe ``node.override``) instead of ``node.set`` because ``node.set`` is an alias for ``node.normal``. Normal data is persisted on the node object. Therefore, using ``node.set`` will persist data in the node object. If the code that uses ``node.set`` is later removed, if that data has already been set on the node, it will remain.

Default and override attributes are cleared at the start of the chef-client run, and are then rebuilt as part of the run based on the code in the cookbooks and recipes at that time.

``node.set`` (and ``node.normal``) should only be used to do something like generate a password for a database on the first chef-client run, after which it's remembered (instead of persisted). Even this case should be avoided, as using a data bag is the recommended way to store this type of data.

Cookbook Linting with ChefDK Tools
=====================================================
ChefDK includes Foodcritic for linting the Chef specific portion of your cookbook code, and Cookstyle for linting the Ruby specific portion of your code.

Foodcritic Linting
-----------------------------------------------------
All cookbooks should pass Foodcritic rules before being uploaded.

.. code-block:: bash

   $ foodcritic -P -f all your-cookbook

should return nothing.

Cookstyle Linting
-----------------------------------------------------
All cookbooks should pass Cookstyle rules before being uploaded.

.. code-block:: bash

   $ cookstyle your-cookbook

should return ``no offenses detected``

More about Ruby
=====================================================
To learn more about Ruby, see the following:

* |url ruby_lang_org|
* |url ruby_power_of_chef|
* |url codeacademy|
* |url ruby_doc_org|
