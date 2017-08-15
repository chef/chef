===============================================================
Publish Cookbooks to Multiple Chef Servers
===============================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/publish_cookbooks_multiple_servers.rst>`__

.. tag chef_automate_mark

.. image:: ../../images/chef_automate_full.png
   :width: 40px
   :height: 17px

.. end_tag

The ``delivery-sugar`` cookbook exposes some libraries and a resource that you can use to
publish a cookbook (or multiple cookbooks) to multiple Chef servers or organizations. The following examples show how to publish to both a single Chef server and how to extend that methodology to publish to multiple Chef servers.

Prerequisites 
===============================================================

Before you begin, you must copy the ``knife.rb`` file 
and the client key .pem file (referenced as ``client_key`` in ``knife.rb``) to the build nodes/runners that you will use in the build-cookbook. This can 
be done manually by logging in to the build nodes/runners and copying the files or automated through the use of a secure copy tool like ``scp``. 

The following is an example of a ``knife.rb`` file for a ``test`` user that points to the Chef server 
``chef-test-server.example.com`` and the organization ``your_org``. The ``test.pem`` file is the value specified in the ``client_key`` setting.

.. code-block:: ruby

   current_dir = File.dirname(__FILE__)
   log_location      STDOUT
   node_name         'test'
   client_key        "#{current_dir}/test.pem"
   trusted_certs_dir '/etc/chef/trusted_certs'
   chef_server_url   'https://chef-test-server.example.com/organizations/your_org'

Publish a cookbook to a single Chef server
===============================================================

To publish a cookbook to a Chef server, use the ``delivery_chef_cookbook`` resource and reference the ``knife.rb`` file that you copied to your build node/runner.

This example shows how to publish a cookbook called ``rally`` to a single Chef server. 

.. code-block:: ruby

   knife_rb = '/path/to/the/knife_rb/file/in/the/build-node/knife.rb'

   delivery_chef_cookbook 'rally' do
     path '/path/to/the/cookbook/in/the/build-node/rally'
     chef_server DeliverySugar::ChefServer.new(knife_rb) 
   end

.. note:: The default action for ``delivery_chef_cookbook`` is ``:upload``, so you do not need to explicitly include that in your ``delivery_chef_cookbook`` implementation.

Publish Cookbook to Multiple Chef servers
===============================================================

Publishing to multiple servers uses the delivery_chef_cookbook in much the same way as publishing to a single Chef server except you reference multiple Chef server objects through an array.

In the following example, imagine you have two Chef servers, one in San Francisco and another one in New York. Also, assume you have copied the correct ``knife.rb`` and ``client_key`` files to the build nodes/runners for each Chef server.

For this particular example, you want the cookbook uploaded at the very end of the workflow pipeline, in the **Functional** phase of the **Delivered** Stage.
This requires that you modify the **Functional** recipe (``recipes/functional.rb``) of the ``build-cookbook`` within your project, as shown below.

.. code-block:: ruby

   # Run it only in Delivered::Functional
   #
   # This helper is coming from delivery-sugar
   # => https://github.com/chef-cookbooks/delivery-sugar/blob/master/libraries/delivery_dsl.rb#L105,L113
   if delivery_environment.eql?('delivered')

     # Previously generated knife.rb files
     ny_knife_rb = '/var/opt/delivery/workspace/chef_servers/ny/knife.rb'
     sf_knife_rb = '/var/opt/delivery/workspace/chef_servers/sf/knife.rb'
     
     # ChefServer Objects
     chef_server_ny = DeliverySugar::ChefServer.new(ny_knife_rb) 
     chef_server_sf = DeliverySugar::ChefServer.new(sf_knife_rb) 
     
     delivery_chef_cookbook delivery_project do
       path delivery_workspace_repo
       chef_server [chef_server_ny, chef_server_sf]
     end
   end
