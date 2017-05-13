=====================================================
Custom Resources
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/custom_resources.rst>`__

Chef 12.5 introduced custom resources, which are now the preferred method of writing your own resources in Chef. If you are using an older version of the chef-client, please use the version picker (in the top left of the navigation) to select your version, and then choose the same topic from the navigation tree ("Extend Chef > Custom Resources"). See also https://github.com/chef-cookbooks/compat_resource for using custom resources with chef-client 12.1 - 12.4.

As of Chef client 12.14, individual resource properties can be marked as `sensitive: true`, which suppresses the value of that property when exporting the resource's state.

.. tag custom_resources_summary

A custom resource:

* Is a simple extension of Chef that adds your own resources
* Is implemented and shipped as part of a cookbook
* Follows easy, repeatable syntax patterns
* Effectively leverages resources that are built into Chef and/or custom Ruby code
* Is reusable in the same way as resources that are built into Chef

For example, Chef includes built-in resources to manage files, packages, templates, and services, but it does not include a resource that manages websites.

.. end_tag

Syntax
=====================================================
.. tag custom_resources_syntax

A custom resource is defined as a Ruby file and is located in a cookbook's ``/resources`` directory. This file

* Declares the properties of the custom resource
* Loads current properties, if the resource already exists
* Defines each action the custom resource may take

The syntax for a custom resource is. For example:

.. code-block:: ruby

   property :name, RubyType, default: 'value'

   load_current_value do
     # some Ruby for loading the current state of the resource
   end

   action :name do
    # a mix of built-in Chef resources and Ruby
   end

   action :name do
    # a mix of built-in Chef resources and Ruby
   end

where the first action listed is the default action.

.. end_tag

Example
-----------------------------------------------------
.. tag custom_resources_syntax_example

This example ``site`` utilizes Chef's built in ``file``, ``service`` and ``package`` resources, and includes ``:create`` and ``:delete`` actions. Since it uses built in Chef resources, besides defining the property and actions, the code is very similar to that of a recipe.

.. code-block:: ruby

   property :homepage, String, default: '<h1>Hello world!</h1>'

   action :create do
     package 'httpd'

     service 'httpd' do
       action [:enable, :start]
     end

     file '/var/www/html/index.html' do
       content homepage
     end
   end

   action :delete do
     package 'httpd' do
       action :delete
     end
   end

where

* ``homepage`` is a property that sets the default HTML for the ``index.html`` file with a default value of ``'<h1>Hello world!</h1>'``
* the ``action`` block uses the built-in collection of resources to tell the chef-client how to install Apache, start the service, and then create the contents of the file located at ``/var/www/html/index.html``
* ``action :create`` is the default resource; ``action :delete`` must be called specifically (because it is not the default resource)

Once built, the custom resource may be used in a recipe just like the any of the resources that are built into Chef. The resource gets its name from the cookbook and from the file name in the ``/resources`` directory, with an underscore (``_``) separating them. For example, a cookbook named ``exampleco`` with a custom resource named ``site.rb`` is used in a recipe like this:

.. code-block:: ruby

   exampleco_site 'httpd' do
     homepage '<h1>Welcome to the Example Co. website!</h1>'
   end

and to delete the exampleco website, do the following:

.. code-block:: ruby

   exampleco_site 'httpd' do
     action :delete
   end

.. end_tag

resource_name
-----------------------------------------------------
.. note:: .. tag ruby_style_patterns_hyphens

          Cookbook and custom resource names should contain only alphanumeric characters. A hyphen (``-``) is a valid character and may be used in cookbook and custom resource names, but it is discouraged. The chef-client will return an error if a hyphen is not converted to an underscore (``_``) when referencing from a recipe the name of a custom resource in which a hyphen is located.

          .. end_tag

.. tag dsl_custom_resource_method_resource_name

Use the ``resource_name`` method at the top of a custom resource to declare a custom name for that resource. For example:

.. code-block:: ruby

   resource_name :custom_name

where ``:custom_name`` is the resource name as it may be used in a recipe. For example, a cookbook named ``website`` and a custom resource file named ``httpd`` is by default used in a recipe with ``website_httpd``. If ``:custom_name`` is ``web_httpd`` then it may be used like this:

.. code-block:: ruby

   web_httpd 'name' do
     # properties
   end

.. end_tag

.. tag dsl_custom_resource_method_resource_name_example

For example, the ``httpd.rb`` file in the ``website`` cookbook could be assigned a custom resource name like this:

.. code-block:: ruby

   resource_name :httpd

   property :homepage, String, default: '<h1>Hello world!</h1>'

   load_current_value do
     if ::File.exist?('/var/www/html/index.html')
       homepage IO.read('/var/www/html/index.html')
     end
   end

   action :create do
     package 'httpd'

     service 'httpd' do
       action [:enable, :start]
     end

     file '/var/www/html/index.html' do
       content homepage
     end
   end

and is then usable in a recipe like this:

.. code-block:: ruby

   httpd 'build website' do
     homepage '<h1>Welcome to the Example Co. website!</h1>'
     action :create
   end

.. end_tag

Scenario: website Resource
=====================================================
Create a resource that configures Apache httpd for Red Hat Enterprise Linux 7 and CentOS 7.

This scenario covers the following:

#. Defining a cookbook named ``website``
#. Defining two properties
#. Defining an action
#. For the action, defining the steps to configure the system using resources that are built into Chef
#. Creating two templates that support the custom resource
#. Adding the resource to a recipe

Create a Cookbook
-----------------------------------------------------
This article assumes that a cookbook directory named ``website`` exists in a chef-repo with (at least) the following directories:

.. code-block:: text

   /website
     /recipes
     /resources
     /templates

You may use a cookbook that already exists or you may create a new cookbook.

See /ctl_chef.html for more information about how to use the ``chef`` command-line tool that is packaged with the Chef development kit to build the chef-repo, plus related cookbook sub-directories.

Objectives
-----------------------------------------------------
Define a custom resource!

A custom resource typically contains:

* A list of defined custom properties (property values are specified in recipes)
* At least one action (actions tell the chef-client what to do)
* For each action, use a collection of resources that are built into Chef to define the steps required to complete the action

What is needed?
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This custom resource requires:

* Two template files
* Two properties
* An action that defines all of the steps necessary to create the website

Define Properties
-----------------------------------------------------
Custom properties are defined in the resource. This custom resource needs two:

* ``instance_name``
* ``port``

These properties are defined as variables in the ``httpd.conf.erb`` file. A **template** block in recipes will tell the chef-client how to apply these variables.

In the custom resource, add the following custom properties:

.. code-block:: ruby

   property :instance_name, String, name_property: true
   property :port, Integer, required: true

where

* ``String`` and ``Integer`` are Ruby types (all custom properties must have an assigned Ruby type)
* ``name_property: true`` allows the value for this property to be equal to the ``'name'`` of the resource block

The ``instance_name`` property is then used within the custom resource in many locations, including defining paths to configuration files, services, and virtual hosts.

Define Actions
-----------------------------------------------------
Each custom resource must have at least one action that is defined within an ``action`` block:

.. code-block:: ruby

   action :create do
     # the steps that define the action
   end

where ``:create`` is a value that may be assigned to the ``action`` property for when this resource is used in a recipe.

For example, the ``action`` appears as a property when this custom resource is used in a recipe:

.. code-block:: ruby

   custom_resource 'name' do
     # some properties
     action :create
   end

Define Resource
-----------------------------------------------------
Use the **package**, **template** (two times), **directory**, and **service** resources to define the ``website`` resource. Remember: order matters!

package
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the **package** resource to install httpd:

.. code-block:: ruby

   package 'httpd' do
     action :install
   end

template, httpd.service
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the **template** resource to create an ``httpd.service`` on the node based on the ``httpd.service.erb`` template located in the cookbook:

.. code-block:: ruby

   template "/lib/systemd/system/httpd-#{instance_name}.service" do
     source 'httpd.service.erb'
     variables(
       instance_name: instance_name
     )
     owner 'root'
     group 'root'
     mode '0644'
     action :create
   end

where

* ``source`` gets the ``httpd.service.erb`` template from this cookbook
* ``variables`` assigns the ``instance_name`` property to a variable in the template

template, httpd.conf
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the **template** resource to configure httpd on the node based on the ``httpd.conf.erb`` template located in the cookbook:

.. code-block:: ruby

   template "/etc/httpd/conf/httpd-#{instance_name}.conf" do
     source 'httpd.conf.erb'
     variables(
       instance_name: instance_name,
       port: port
     )
     owner 'root'
     group 'root'
     mode '0644'
     action :create
   end

where

* ``source`` gets the ``httpd.conf.erb`` template from this cookbook
* ``variables`` assigns the ``instance_name`` and ``port`` properties to variables in the template

directory
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the **directory** resource to create the ``/var/www/vhosts`` directory on the node:

.. code-block:: ruby

   directory "/var/www/vhosts/#{instance_name}" do
     recursive true
     owner 'root'
     group 'root'
     mode '0755'
     action :create
   end

service
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the **service** resource to enable, and then start the service:

.. code-block:: ruby

   service "httpd-#{instance_name}" do
     action [:enable, :start]
   end

Create Templates
-----------------------------------------------------
The ``/templates`` directory must contain two templates:

* ``httpd.conf.erb`` to configure Apache httpd
* ``httpd.service.erb`` to tell systemd how to start and stop the website

httpd.conf.erb
+++++++++++++++++++++++++++++++++++++++++++++++++++++
``httpd.conf.erb`` stores information about the website and is typically located under the ``/etc/httpd``:

.. code-block:: ruby

   ServerRoot "/etc/httpd"
   Listen <%= @port %>
   Include conf.modules.d/*.conf
   User apache
   Group apache
   <Directory />
     AllowOverride none
     Require all denied
   </Directory>
   DocumentRoot "/var/www/vhosts/<%= @instance_name %>"
   <IfModule mime_module>
     TypesConfig /etc/mime.types
   </IfModule>

Copy it as shown, add it under ``/templates``, and then name the file ``httpd.conf.erb``.

Template Variables
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The ``httpd.conf.erb`` template has two variables:

* ``<%= @instance_name %>``
* ``<%= @port %>``

They are:

* Declared as properties of the custom resource
* Defined as variables in a **template** resource block within the custom resource
* Tunable from a recipe when using ``port`` and ``instance_name`` as properties in that recipe
* ``instance_name`` defaults to the ``'name'`` of the custom resource if not specified as a property

httpd.service.erb
+++++++++++++++++++++++++++++++++++++++++++++++++++++
``httpd.service.erb`` tells systemd how to start and stop the website:

.. code-block:: none

   [Unit]
   Description=The Apache HTTP Server - instance <%= @instance_name %>
   After=network.target remote-fs.target nss-lookup.target

   [Service]
   Type=notify

   ExecStart=/usr/sbin/httpd -f /etc/httpd/conf/httpd-<%= @instance_name %>.conf -DFOREGROUND
   ExecReload=/usr/sbin/httpd -f /etc/httpd/conf/httpd-<%= @instance_name %>.conf -k graceful
   ExecStop=/bin/kill -WINCH ${MAINPID}

   KillSignal=SIGCONT
   PrivateTmp=true

   [Install]
   WantedBy=multi-user.target

Copy it as shown, add it under ``/templates``, and then name it ``httpd.service.erb``.

Final Resource
-----------------------------------------------------
.. code-block:: ruby

   property :instance_name, String, name_property: true
   property :port, Integer, required: true

   action :create do
     package 'httpd' do
       action :install
     end

     template "/lib/systemd/system/httpd-#{instance_name}.service" do
       source 'httpd.service.erb'
       variables(
         instance_name: instance_name
       )
       owner 'root'
       group 'root'
       mode '0644'
       action :create
     end

     template "/etc/httpd/conf/httpd-#{instance_name}.conf" do
       source 'httpd.conf.erb'
       variables(
         instance_name: instance_name,
         port: port
       )
       owner 'root'
       group 'root'
       mode '0644'
       action :create
     end

     directory "/var/www/vhosts/#{instance_name}" do
       recursive true
       owner 'root'
       group 'root'
       mode '0755'
       action :create
     end

     service "httpd-#{instance_name}" do
       action [:enable, :start]
     end

   end

Final Cookbook Directory
-----------------------------------------------------
When finished adding the templates and building the custom resource, the cookbook directory structure should look like this:

.. code-block:: text

   /website
     metadata.rb
     /recipes
       default.rb
     README.md
     /resources
       httpd.rb
     /templates
       httpd.conf.erb
       httpd.service.erb

Recipe
-----------------------------------------------------
The custom resource name is inferred from the name of the cookbook (``website``), the name of the resource file (``httpd``), and is separated by an underscore(``_``): ``website_httpd``.  The custom resource may be used in a recipe.

.. code-block:: ruby

   website_httpd 'httpd_site' do
     port 81
     action :create
   end

which does the following:

* Installs Apache httpd
* Assigns an instance name of ``httpd_site`` that uses port 81
* Configures httpd and systemd from a template
* Creates the virtual host for the website
* Starts the website using systemd

Custom Resource DSL
=====================================================
The following sections describe additional Custom Resource DSL methods that were not used in the preceding scenario:

action_class
-----------------------------------------------------
.. tag dsl_custom_resource_block_action_class

Use the ``action_class.class_eval`` block to make methods available to the actions in the custom resource. Modules with helper methods created as files in the cookbook library directory may be included. New action methods may also be defined directly in the ``action_class.class_eval`` block. Code in the ``action_class.class_eval`` block has access to the new_resource properties.

Assume a helper module has been created in the cookbook ``libraries/helper.rb`` file.

.. code-block:: ruby

   module Sample
     module Helper
       def helper_method
         # code
       end
     end
   end

Methods may be made available to the custom resource actions by using an ``action_class.class_eval`` block.

.. code-block:: ruby

   property file, String

   action :delete do
     helper_method
     FileUtils.rm(file) if file_ex
   end

   action_class.class_eval do

     def file_exist
       ::File.exist?(file)
     end

     def file_ex
       ::File.exist?(new_resource.file)
     end

     require 'fileutils'

     include Sample::Helper

   end

.. end_tag

converge_if_changed
-----------------------------------------------------
.. tag dsl_custom_resource_method_converge_if_changed

Use the ``converge_if_changed`` method inside an ``action`` block in a custom resource to compare the desired property values against the current property values (as loaded by the ``load_current_value`` method). Use the ``converge_if_changed`` method to ensure that updates only occur when property values on the system are not the desired property values and to otherwise prevent a resource from being converged.

To use the ``converge_if_changed`` method, wrap it around the part of a recipe or custom resource that should only be converged when the current state is not the desired state:

.. code-block:: ruby

   action :some_action do

     converge_if_changed do
       # some property
     end

   end

For example, a custom resource defines two properties (``content`` and ``path``) and a single action (``:create``). Use the ``load_current_value`` method to load the property value to be compared, and then use the ``converge_if_changed`` method to tell the chef-client what to do if that value is not the desired value:

.. code-block:: ruby

   property :content, String
   property :path, String, name_property: true

   load_current_value do
     if ::File.exist?(path)
       content IO.read(path)
     end
   end

   action :create do
     converge_if_changed do
       IO.write(path, content)
     end
   end

When the file does not exist, the ``IO.write(path, content)`` code is executed and the chef-client output will print something similar to:

.. code-block:: bash

   Recipe: recipe_name::block
     * resource_name[blah] action create
       - update my_file[blah]
       -   set content to "hola mundo" (was "hello world")

.. end_tag

Multiple Properties
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_custom_resource_method_converge_if_changed_multiple

The ``converge_if_changed`` method may be used multiple times. The following example shows how to use the ``converge_if_changed`` method to compare the multiple desired property values against the current property values (as loaded by the ``load_current_value`` method).

.. code-block:: ruby

   property :path, String, name_property: true
   property :content, String
   property :mode, String

   load_current_value do
     if ::File.exist?(path)
       content IO.read(path)
       mode ::File.stat(path).mode
     end
   end

   action :create do
     converge_if_changed :content do
       IO.write(path, content)
     end
     converge_if_changed :mode do
       ::File.chmod(mode, path)
     end
   end

where

* ``load_current_value`` loads the property values for both ``content`` and ``mode``
* A ``converge_if_changed`` block tests only ``content``
* A ``converge_if_changed`` block tests only ``mode``

The chef-client will only update the property values that require updates and will not make changes when the property values are already in the desired state

.. end_tag

default_action
-----------------------------------------------------
.. tag dsl_custom_resource_method_default_action

The default action in a custom resource is, by default, the first action listed in the custom resource. For example, action ``aaaaa`` is the default resource:

.. code-block:: ruby

   property :name, RubyType, default: 'value'

   ...

   action :aaaaa do
    # the first action listed in the custom resource
   end

   action :bbbbb do
    # the second action listed in the custom resource
   end

The ``default_action`` method may also be used to specify the default action. For example:

.. code-block:: ruby

   property :name, RubyType, default: 'value'

   default_action :aaaaa

   action :aaaaa do
    # the first action listed in the custom resource
   end

   action :bbbbb do
    # the second action listed in the custom resource
   end

defines action ``aaaaa`` as the default action. If ``default_action :bbbbb`` is specified, then action ``bbbbb`` is the default action. Use this method for clarity in custom resources, if deliberately stating the default resource is desired, or to specify a default action that is not listed first in the custom resource.

.. end_tag

load_current_value
-----------------------------------------------------
.. tag dsl_custom_resource_method_load_current_value

Use the ``load_current_value`` method to load the specified property values from the node, and then use those values when the resource is converged. This method may take a block argument.

Use the ``load_current_value`` method to guard against property values being replaced. For example:

.. code-block:: ruby

   action :some_action do

     load_current_value do
       if ::File.exist?('/var/www/html/index.html')
         homepage IO.read('/var/www/html/index.html')
       end
       if ::File.exist?('/var/www/html/404.html')
         page_not_found IO.read('/var/www/html/404.html')
       end
     end

   end

This ensures the values for ``homepage`` and ``page_not_found`` are not changed to the default values when the chef-client configures the node.

.. end_tag

new_resource.property
-----------------------------------------------------
.. tag dsl_custom_resource_method_new_resource

Custom resources are designed to use core resources that are built into Chef. In some cases, it may be necessary to specify a property in the custom resource that is the same as a property in a core resource, for the purpose of overriding that property when used with the custom resource. For example:

.. code-block:: ruby

   resource_name :node_execute

   property :command, String, name_property: true
   property :version, String

   # Useful properties from the `execute` resource
   property :cwd, String
   property :environment, Hash, default: {}
   property :user, [String, Integer]
   property :sensitive, [true, false], default: false

   prefix = '/opt/languages/node'

   load_current_value do
     current_value_does_not_exist! if node.run_state['nodejs'].nil?
     version node.run_state['nodejs'][:version]
   end

   action :run do
     execute 'execute-node' do
       cwd cwd
       environment environment
       user user
       sensitive sensitive
       # gsub replaces 10+ spaces at the beginning of the line with nothing
       command <<-CODE.gsub(/^ {10}/, '')
         #{prefix}/#{version}/#{command}
       CODE
     end
   end

where the ``property :cwd``, ``property :environment``, ``property :user``, and ``property :sensitive`` are identical to properties in the **execute** resource, embedded as part of the ``action :run`` action. Because both the custom properties and the **execute** properties are identical, this will result in an error message similar to:

.. code-block:: ruby

   ArgumentError
   -------------
   wrong number of arguments (0 for 1)

To prevent this behavior, use ``new_resource.`` to tell the chef-client to process the properties from the core resource instead of the properties in the custom resource. For example:

.. code-block:: ruby

   resource_name :node_execute

   property :command, String, name_property: true
   property :version, String

   # Useful properties from the `execute` resource
   property :cwd, String
   property :environment, Hash, default: {}
   property :user, [String, Integer]
   property :sensitive, [true, false], default: false

   prefix = '/opt/languages/node'

   load_current_value do
     current_value_does_not_exist! if node.run_state['nodejs'].nil?
     version node.run_state['nodejs'][:version]
   end

   action :run do
     execute 'execute-node' do
       cwd new_resource.cwd
       environment new_resource.environment
       user new_resource.user
       sensitive new_resource.sensitive
       # gsub replaces 10+ spaces at the beginning of the line with nothing
       command <<-CODE.gsub(/^ {10}/, '')
         #{prefix}/#{new_resource.version}/#{new_resource.command}
       CODE
     end
   end

where ``cwd new_resource.cwd``, ``environment new_resource.environment``, ``user new_resource.user``, and ``sensitive new_resource.sensitive`` correctly use the properties of the **execute** resource and not the identically-named override properties of the custom resource.

.. end_tag

property
-----------------------------------------------------
.. tag dsl_custom_resource_method_property

Use the ``property`` method to define properties for the custom resource. The syntax is:

.. code-block:: ruby

   property :name, ruby_type, default: 'value', parameter: 'value'

where

* ``:name`` is the name of the property
* ``ruby_type`` is the optional Ruby type or array of types, such as ``String``, ``Integer``, ``true``, or ``false``
* ``default: 'value'`` is the optional default value loaded into the resource
* ``parameter: 'value'`` optional parameters

For example, the following properties define ``username`` and ``password`` properties with no default values specified:

.. code-block:: ruby

   property :username, String
   property :password, String

.. end_tag

ruby_type
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_custom_resource_method_property_ruby_type

The property ruby_type is a positional parameter. Use to ensure a property value is of a particular ruby class, such as ``true``, ``false``, ``nil``, ``String``, ``Array``, ``Hash``, ``Integer``, ``Symbol``. Use an array of ruby classes to allow a value to be of more than one type. For example:

       .. code-block:: ruby

          property :name, String

       .. code-block:: ruby

          property :name, Integer

       .. code-block:: ruby

          property :name, Hash

       .. code-block:: ruby

          property :name, [true, false]

       .. code-block:: ruby

          property :name, [String, nil]

       .. code-block:: ruby

          property :name, [Class, String, Symbol]

       .. code-block:: ruby

          property :name, [Array, Hash]

.. end_tag

validators
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_custom_resource_method_property_validation_parameter

A validation parameter is used to add zero (or more) validation parameters to a property.

.. list-table::
   :widths: 150 450
   :header-rows: 1

   * - Parameter
     - Description
   * - ``:callbacks``
     - Use to define a collection of unique keys and values (a ruby hash) for which the key is the error message and the value is a lambda to validate the parameter. For example:

       .. code-block:: ruby

          callbacks: {
                       'should be a valid non-system port' => lambda {
                         |p| p > 1024 && p < 65535
                       }
                     }

   * - ``:default``
     - Use to specify the default value for a property. For example:

       .. code-block:: ruby

          default: 'a_string_value'

       .. code-block:: ruby

          default: 123456789

       .. code-block:: ruby

          default: []

       .. code-block:: ruby

          default: ()

       .. code-block:: ruby

          default: {}
   * - ``:equal_to``
     - Use to match a value with ``==``. Use an array of values to match any of those values with ``==``. For example:

       .. code-block:: ruby

          equal_to: [true, false]

       .. code-block:: ruby

          equal_to: ['php', 'perl']
   * - ``:regex``
     - Use to match a value to a regular expression. For example:

       .. code-block:: ruby

          regex: [ /^([a-z]|[A-Z]|[0-9]|_|-)+$/, /^\d+$/ ]
   * - ``:required``
     - Indicates that a property is required. For example:

       .. code-block:: ruby

          required: true
   * - ``:respond_to``
     - Use to ensure that a value has a given method. This can be a single method name or an array of method names. For example:

       .. code-block:: ruby

          respond_to: valid_encoding?

Some examples of combining validation parameters:

.. code-block:: ruby

   property :spool_name, String, regex: /$\w+/

.. code-block:: ruby

   property :enabled, equal_to: [true, false, 'true', 'false'], default: true

.. end_tag

desired_state
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_custom_resource_method_property_desired_state

Add ``desired_state:`` to get or set the list of desired state properties for a resource, which describe the desired state of the node, such as permissions on an existing file. This value may be ``true`` or ``false``.

* When ``true``, the state of the system will determine the value.
* When ``false``, the values defined by the recipe or custom resource will determine the value, i.e. "the desired state of this system includes setting the value defined in this custom resource or recipe"

For example, the following properties define the ``owner``, ``group``, and ``mode`` properties for a file that already exists on the node, and with ``desired_state`` set to ``false``:

.. code-block:: ruby

   property :owner, String, default: 'root', desired_state: false
   property :group, String, default: 'root', desired_state: false
   property :mode, String, default: '0755', desired_state: false

.. end_tag

identity
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_custom_resource_method_property_identity

Add ``identity:`` to set a resource to a particular set of properties. This value may be ``true`` or ``false``.

* When ``true``, data for that property is returned as part of the resource data set and may be available to external applications, such as reporting
* When ``false``, no data for that property is returned.

If no properties are marked ``true``, the property that defaults to the ``name`` of the resource is marked ``true``.

For example, the following properties define ``username`` and ``password`` properties with no default values specified, but with ``identity`` set to ``true`` for the user name:

.. code-block:: ruby

   property :username, String, identity: true
   property :password, String

.. end_tag

Block Arguments
-----------------------------------------------------
.. tag dsl_custom_resource_method_property_block_argument

Any properties that are marked ``identity: true`` or ``desired_state: false`` will be available from ``load_current_value``. If access to other properties of a resource is needed, use a block argument that contains all of the properties of the requested resource. For example:

.. code-block:: ruby

   resource_name :file

   load_current_value do |desired|
     puts "The user typed content = #{desired.content} in the resource"
   end

.. end_tag

property_is_set?
-----------------------------------------------------
.. tag dsl_custom_resource_method_property_is_set

Use the ``property_is_set?`` method to check if the value for a property is set. The syntax is:

.. code-block:: ruby

   property_is_set?(:property_name)

The ``property_is_set?`` method will return ``true`` if the property is set.

For example, the following custom resource creates and/or updates user properties, but not their password. The ``property_is_set?`` method checks if the user has specified a password and then tells the chef-client what to do if the password is not identical:

.. code-block:: ruby

   action :create do
     converge_if_changed do
       system("rabbitmqctl create_or_update_user #{username} --prop1 #{prop1} ... ")
     end

     if property_is_set?(:password)
       if system("rabbitmqctl authenticate_user #{username} #{password}") != 0 do
         converge_by "Updating password for user #{username} ..." do
       system("rabbitmqctl update_user #{username} --password #{password}")
     end
   end

.. end_tag

provides
-----------------------------------------------------
.. tag dsl_custom_resource_method_provides

Use the ``provides`` method to associate a custom resource with the Recipe DSL on different operating systems. When multiple custom resources use the same DSL, specificity rules are applied to determine the priority, from highest to lowest:

#. provides :resource_name, platform_version: ‘0.1.2’
#. provides :resource_name, platform: ‘platform_name’
#. provides :resource_name, platform_family: ‘platform_family’
#. provides :resource_name, os: ‘operating_system’
#. provides :resource_name

For example:

.. code-block:: ruby

    provides :my_custom_resource, platform: 'redhat' do |node|
      node['platform_version'].to_i >= 7
    end

    provides :my_custom_resource, platform: 'redhat'

    provides :my_custom_resource, platform_family: 'rhel'

    provides :my_custom_resource, os: 'linux'

    provides :my_custom_resource

This allows you to use multiple custom resources files that provide the same resource to the user, but for different operating systems or operation system versions. With this you can eliminate the need for platform or platform version logic within your resources.

.. end_tag

override
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_custom_resource_method_provides_override

Chef will warn you if the Recipe DSL is provided by another custom resource or built-in resource. For example:

.. code-block:: ruby

   class X < Chef::Resource
     provides :file
   end

   class Y < Chef::Resource
     provides :file
   end

This will emit a warning that ``Y`` is overriding ``X``. To disable this warning, use ``override: true``:

.. code-block:: ruby

   class X < Chef::Resource
     provides :file
   end

   class Y < Chef::Resource
     provides :file, override: true
   end

.. end_tag

reset_property
-----------------------------------------------------
.. tag dsl_custom_resource_method_reset_property

Use the ``reset_property`` method to clear the value for a property as if it had never been set, and then use the default value. For example, to clear the value for a property named ``password``:

.. code-block:: ruby

   reset_property(:password)

.. end_tag
