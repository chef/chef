=============================================
Deprecation: Chef::Platform methods (CHEF-13)
=============================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_chef_platform_methods.rst>`__

.. tag deprecations_chef_platform_methods

Several methods under ``Chef::Platform`` that were previously public APIs to control resolution of provider classes were replaced by the dynamic
``Chef::ProviderResolver`` work and the ``provides`` keyword.

.. end_tag

This deprecation warning was added in Chef 12.18.x, and using these APIs will become a hard error in Chef 13.

Remediation
================

Code which used to use ``Chef::Platform.provider_for_resource`` or ``Chef::Platform.find_provider`` to create providers for a resource:

.. code-block:: ruby

   resource = Chef::Resource::File.new("/tmp/foo.xyz", run_context)
   provider = Chef::Platform.provider_for_resource(resource, :create)

   resource = Chef::Resource::File.new("/tmp/foo.xyz", run_context)
   provider = Chef::Platform.find_provider("ubuntu", "16.04", resource)

   resource = Chef::Resource::File.new("/tmp/foo.xyz", run_context)
   provider = Chef::Platform.find_provider_for_node(node, resource)

Should instead use the ``Chef::Resource#provider_for_action`` API on the instance of the resource:

.. code-block:: ruby

   resource = Chef::Resource::File.new("/tmp/foo.xyz", run_context)
   provider = resource.provider_for_action(:create)

As the internal resources and providers in core chef have been ported over to use the ``Chef::ProviderResolver`` dynamic resolution the use
of the old Chef::Platform class methods have actually been broken.  Tools like ``chefspec`` and ``chef-minitest-handler`` were ported over to
the new APIs in Chef 12.0.  The ``Chef::Resource#provider_for_action`` API dates back to before Chef 11.0.0 and is fully backwards compatible,
any remaining code using the old APIs should be exceedingly buggy at this point.

Also, code which used to use ``Chef::Platform.set`` to register providers for a platform/platform_version should use the ``provides`` keyword
on the provider instead:

.. code-block:: ruby

   Chef::Platform.set platform: :fedora, version: '>= 19', resource: :mysql_service, provider: Chef::Provider::MysqlServiceSystemd

Should be replaced by:

.. code-block:: ruby

   class Chef::Provider::MysqlSserviceSystemd
   provides :mysql_service, platform: "fedora", platform_version: ">= 19"

This can also be directly sent to the provider class in library code, although this form is less encouraged (which does not mean the
same thing as discouraged -- but you gain better code organizatino with the prior code):

.. code-block:: ruby

   Chef::Provider::MysqlSserviceSystemd.provides :mysql_service, platform: "fedora", platform_version: ">= 19"

The ``provides`` API on providers is only supported in Chef 12.0 or later.  This change will create a hard backwards compatibility break
between Chef 13 and Chef 11 without the cookbook doing the work to check the Chef::VERSION and switch between these APIs.  This API is
supported back to Chef 12.0, although some more advanced forms of the ``provides`` syntax were only introduced in Chef 12.5.1.

Also you may have found this web page due to deprecation of library-based resources and providers that do not declare provides in
which case your chef-client run is likely full of a compliation of warnings and deprecations:

.. code-block:: none

   * foo[it] action doit[2016-12-07T14:28:59-08:00] WARN: Class Chef::Provider::Foo does not declare 'provides :foo'.
     [2016-12-07T14:28:59-08:00] WARN: This will no longer work in Chef 13: you must use 'provides' to use the resource's DSL.
     (up to date)

   Running handlers:
   Running handlers complete

   Deprecated features used!
   Class.find_provider_for_node is deprecated at 1 location:
   - /Users/lamont/.rvm/rubies/ruby-2.3.1/lib/ruby/2.3.0/forwardable.rb:189:in 'execute_each_resource'
     See /deprecations_chef_platform_methods.html for further details.
   Class.find_provider is deprecated at 1 location:
   - /Users/lamont/.rvm/rubies/ruby-2.3.1/lib/ruby/2.3.0/forwardable.rb:189:in 'execute_each_resource'
     See /deprecations_chef_platform_methods.html for further details.
   Class.find is deprecated at 1 location:
   - /Users/lamont/.rvm/rubies/ruby-2.3.1/lib/ruby/2.3.0/forwardable.rb:189:in 'execute_each_resource'
     See /deprecations_chef_platform_methods.html for further details.

In this case, the initial warning that ``Class Chef::Provider::Foo does not declare 'provides :foo'`` is accurate and gives the remediation.

Code that looks like this:

.. code-block:: ruby

   class Chef::Provider::Foo < Chef::Provider::LWRPBase
     use_inline_resources

     action :doit do
       [ ... stuff ... ]
     end
   end

Must be changed to explictly declare the resource it provides:

.. code-block:: ruby

   class Chef::Provider::Foo < Chef::Provider::LWRPBase
     provides :foo

     use_inline_resources

     action :doit do
       [ ... stuff ... ]
     end
   end

The use of custom resources over library class providers that inherit from LWRPBase is also encouraged.

