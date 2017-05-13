=====================================================
About Definitions
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/definitions.rst>`__

.. warning:: Starting with chef-client 12.5, it is recommended to :doc:`build custom resources </custom_resources>` instead of definitions. While the use of definitions is not deprecated---all existing definitions will continue to work---it is recommended to also migrate existing definitions to the new custom resource patterns. This topic introduces definitions as they once were (and still can be, if desired), but deprecates all but one example of using them in favor of showing how to migrate an existing definition to the new custom resource pattern.

A definition behaves like a compile-time macro that is reusable across recipes. A definition is typically created by wrapping arbitrary code around resources that are declared as if they were in a recipe. A definition is then used in one (or more) actual recipes as if the definition were a resource.

Though a definition looks like a resource, and at first glance seems like it could be used interchangeably, some important differences exist. A definition:

* Is not a resource or a custom resource
* Is processed while the resource collection is compiled (whereas resources are processed while a node is converged)
* Does not support common resource properties, such as ``notifies``, ``subscribes``, ``only_if``, and ``not_if``
* Is defined from within the ``/definitions`` directory of a cookbook
* Does not support why-run mode

Syntax
=====================================================
A definition has four components:

* A resource name
* Zero or more arguments that define parameters their default values; if a default value is not specified, it is assumed to be ``nil``
* A hash that can be used within a definition's body to provide access to parameters and their values
* The body of the definition

The basic syntax of a definition is:

.. code-block:: ruby

   define :resource_name do
     body
   end

More commonly, the usage incorporates arguments to the definition:

.. code-block:: ruby

   define :resource_name, :parameter => :argument, :parameter => :argument do
     body (likely referencing the params hash)
   end

The following simplistic example shows a definition with no arguments (a parameterless macro in the truest sense):

.. code-block:: ruby

   define :prime_myfile do
     file '/etc/myfile' do
       content 'some content'
     end
   end

An example showing the use of parameters, with a parameter named ``port`` that defaults to ``4000`` rendered into a **template** resource, would look like:

 .. code-block:: ruby

   define :prime_myfile, port: 4000 do
     template '/etc/myfile' do
       source 'myfile.erb'
       variables({
         port: params[:port],
       })
     end
   end

Or the following definition, which looks like a resource when used in a recipe, but also contains **directory** and **file** resources that are repeated, but with slightly different parameters:

.. code-block:: ruby

   define :host_porter, :port => 4000, :hostname => nil do
     params[:hostname] ||= params[:name]

     directory '/etc/#{params[:hostname]}' do
       recursive true
     end

     file '/etc/#{params[:hostname]}/#{params[:port]}' do
       content 'some content'
     end
   end

which is then used in a recipe like this:

.. code-block:: ruby

   host_porter node['hostname'] do
    port 4000
   end

   host_porter 'www1' do
     port 4001
   end

Examples
=====================================================
The following examples show how to use cookbook definitions.

Many Recipes, One Definition
-----------------------------------------------------
.. warning:: With the improved custom resource pattern available starting with chef-client 12.5, the need to use definitions is greatly minimized. In every case when considering to use a definition, first evaluate whether that defintion is better represented as a custom resource.

Data can be passed to a definition from more than one recipe. Use a definition to create a compile-time macro that can be referenced by resources during the converge phase. For example, when both ``/etc/aliases`` and ``/etc/sudoers`` require updates from multiple recipes during a single chef-client run.

A definition that reopens resources would look something like:

.. code-block:: ruby

   define :email_alias, :recipients => [] do
     name       = params[:name]
     recipients = params[:recipients]

     find_resource(:execute, 'newaliases') do
       action :nothing
     end

     t = find_resource(:template, '/etc/aliases') do
       source 'aliases.erb'
       cookbook 'aliases'
       variables({:aliases => {} })
       notifies :run, 'execute[newaliases]'
     end

     aliases = t.variables[:aliases]

     if !aliases.has_key?(name)
       aliases[name] = []
     end
     aliases[name].concat(recipients)
   end

Definition vs. Resource
=====================================================
.. tag definition_example

The following examples show:

#. A definition
#. The same definition rewritten as a custom resource
#. The same definition, rewritten again to use a :doc:`common resource property </resource_common>`

.. end_tag

As a Definition
-----------------------------------------------------
.. tag definition_example_as_definition

The following definition processes unique hostnames and ports, passed on as parameters:

.. code-block:: ruby

   define :host_porter, :port => 4000, :hostname => nil do
     params[:hostname] ||= params[:name]

     directory '/etc/#{params[:hostname]}' do
       recursive true
     end

     file '/etc/#{params[:hostname]}/#{params[:port]}' do
       content 'some content'
     end
   end

.. end_tag

As a Resource
-----------------------------------------------------
.. tag definition_example_as_resource

The definition is improved by rewriting it as a custom resource:

.. code-block:: ruby

   property :port, Integer, default: 4000
   property :hostname, String, name_property: true

   action :create do

     directory "/etc/#{hostname}" do
       recursive true
     end

     file "/etc/#{hostname}/#{port}" do
       content 'some content'
     end

   end

Once built, the custom resource may be used in a recipe just like the any of the resources that are built into Chef. The resource gets its name from the cookbook and from the file name in the ``/resources`` directory, with an underscore (``_``) separating them. For example, a cookbook named ``host`` with a custom resource in the ``/resources`` directory named ``porter.rb``. Use it in a recipe like this:

.. code-block:: ruby

   host_porter node['hostname'] do
     port 4000
   end

or:

.. code-block:: ruby

   host_porter 'www1' do
     port 4001
   end

.. end_tag

Use Common Properties
-----------------------------------------------------
.. tag definition_example_as_resource_with_common_properties

Unlike definitions, custom resources are able to use :doc:`common resource properties </resource_common>`. For example, ``only_if``:

.. code-block:: ruby

   host_porter 'www1' do
     port 4001
     only_if '{ node['hostname'] == 'foo.bar.com' }'
   end

.. end_tag
