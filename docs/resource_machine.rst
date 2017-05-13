=====================================================
machine
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_machine.rst>`__

.. tag resource_machine_summary

Use the **machine** resource to define one (or more) machines, and then converge entire clusters of machines. This allows clusters to be maintained in a version control system and to be defined using multi-machine orchestration scenarios. For example, spinning up small test clusters and using them for continuous integration and local testing, building clusters that auto-scale, moving a set of machines in one cluster to another, building images, and so on.

Each machine is declared as a separate application topology, defined using operating system- and provisioner-independent files. Recipes (defined in cookbooks) are used to manage them. The chef-client is used to converge the individual nodes (machines) within the cluster.

.. end_tag

.. warning:: .. tag notes_provisioning

             This functionality is available with Chef provisioning and is packaged in the Chef development kit. Chef provisioning is a framework that allows clusters to be managed by the chef-client and the Chef server in the same way nodes are managed: with recipes. Use Chef provisioning to describe, version, deploy, and manage clusters of any size and complexity using a common set of tools.

             .. end_tag

Syntax
=====================================================
.. tag resource_machine_syntax

The syntax for using the **machine** resource in a recipe is as follows:

.. code-block:: ruby

   machine 'name' do
     attribute 'value' # see properties section below
     ...
     action :action # see actions section below
   end

where

* ``machine`` tells the chef-client to use the ``Chef::Provider::Machine`` provider during the chef-client run
* ``name`` is the name of the resource block and also the name of the machine
* ``attribute`` is zero (or more) of the properties that are available for this resource
* ``action`` identifies which steps the chef-client will take to bring the node into the desired state

.. end_tag

Actions
=====================================================
.. tag resource_machine_actions

This resource has the following actions:

``:allocate``
   Use to create a machine, return its machine identifier, and then (depending on the provider) boot the machine to an image. This reserves the machine with the provider and subsequent ``:allocate`` actions against this machine no longer need to create the machine, just update it.

``:converge``
   Default. Use to create a machine, return its machine identifier, boot the machine to an image with the specified parameters and transport, install the chef-client, and then converge the machine.

``:converge_only``
   Use to converge a machine, but only if the machine is in a ready state.

``:destroy``
   Use to destroy a machine.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:ready``
   Use to create a machine, return its machine identifier, and then boot the machine to an image with the specified parameters and transport. This machine is in a ready state and may be connected to (via SSH or other transport).

``:setup``
   Use to create a machine, return its machine identifier, boot the machine to an image with the specified parameters and transport, and then install the chef-client. This machine is in a ready state, has the chef-client installed, and all of the configuration data required to apply the run-list to the machine.

``:stop``
   Use to stop a machine.

.. end_tag

In-Parallel Processing
-----------------------------------------------------
.. tag provisioning_parallel

In certain situations Chef provisioning will run multiple **machine** processes in-parallel, as long as each of the individual **machine** resources have the same declared action. The **machine_batch** resource is used to run in-parallel processes.

Chef provisioning will processes resources in-parallel automatically, unless:

* The recipe contains complex scripts, such as when a **file** resource sits in-between two **machine** resources in a single recipe. In this situation, the resources will be run sequentially
* The actions specified for each individual **machine** resource are not identical; for example, if resource A is set to ``:converge`` and resource B is set to ``:destroy``, then they may not be processed in-parallel

To disable in-parallel processing, add the ``auto_machine_batch`` setting to the client.rb file, and then set it to ``false``.

For example, a recipe that looks like:

.. code-block:: ruby

   machine 'a'
   machine 'b'
   machine 'c'

will show output similar to:

.. code-block:: bash

   $ CHEF_DRIVER=fog:AWS chef-apply cluster.rb
   ...
   Converging 1 resources
   Recipe: @recipe_files::/Users/jkeiser/oc/environments/metal-test-local/cluster.rb
     * machine_batch[default] action converge
       - [a] creating machine a on fog:AWS:862552916454
       - [a]   key_name: "metal_default"
       - [a]   tags: {"Name"=>"a", ...}
       - [a]   name: "a"
       - [b] creating machine b on fog:AWS:862552916454
       - [b]   key_name: "metal_default"
       - [b]   tags: {"Name"=>"b", ...}
       - [b]   name: "b"
       - [c] creating machine c on fog:AWS:862552916454
       - [c]   key_name: "metal_default"
       - [c]   tags: {"Name"=>"c", ...}
       - [c]   name: "c"
       - [b] machine b created as i-eb778fb9 on fog:AWS:862552916454
       - create node b at http://localhost:8889
       -   add normal.tags = nil
       -   add normal.metal = {"location"=>{"driver_url"=>"fog:AWS:862552916454", ...}}
       - [a] machine a created as i-e9778fbb on fog:AWS:862552916454
       - create node a at http://localhost:8889
       -   add normal.tags = nil
       -   add normal.metal = {"location"=>{"driver_url"=>"fog:AWS:862552916454", ...}}
       - [c] machine c created as i-816d95d3 on fog:AWS:862552916454
       - create node c at http://localhost:8889
       -   add normal.tags = nil
       -   add normal.metal = {"location"=>{"driver_url"=>"fog:AWS:862552916454", ...}}
       - [b] waiting for b (i-eb778fb9 on fog:AWS:862552916454) to be ready ...
       - [c] waiting for c (i-816d95d3 on fog:AWS:862552916454) to be ready ...
       - [a] waiting for a (i-e9778fbb on fog:AWS:862552916454) to be ready ...
   ...
           Running handlers:
           Running handlers complete

           Chef Client finished, 0/0 resources updated in 4.053363945 seconds
       - [c] run 'chef-client -l auto' on c

   Running handlers:
   Running handlers complete
   Chef Client finished, 1/1 resources updated in 59.64014 seconds

At the end, it shows ``1/1 resources updated``. The three **machine** resources are replaced with a single **machine_batch** resource, which then runs each of the individual **machine** processes in-parallel.

.. end_tag

Properties
=====================================================
.. tag resource_machine_attributes

This resource has the following properties:

``admin``
   **Ruby Types:** TrueClass, FalseClass

   Use to specify whether the chef-client is an API client.

``allow_overwrite_keys``
   **Ruby Types:** TrueClass, FalseClass

   Use to overwrite the key on a machine when it is different from the key specified by ``source_key``.

``attribute``
   Use to specify an attribute, and then modify that attribute with the specified value. The following patterns may be used to specify the value.

   .. code-block:: ruby

      attribute <name>, <value>

   .. code-block:: ruby

      attribute [<path>], <value>

   The following example will set attribute ``a`` to ``b``:

   .. code-block:: ruby

      attribute 'a', 'b'

   The following example will set attribute ``node['a']['b']['c']`` to ``d`` and will ignore attributes ``a.b.x``, ``a.b.y``, etc.:

   .. code-block:: ruby

      attribute %w[a b c], 'd'

   The following example is similar to ``%w[a b c], 'd'``:

   .. code-block:: ruby

      attribute 'a', { 'b' => { 'c' => 'd' } }

   Each modified attribute should be specified individually. This attribute should not be used in the same recipe as ``attributes``.

``attributes``
   Use to specify a Hash that contains all of the normal attributes to be applied to a machine. This attribute should not be used in the same recipe as ``attribute``.

``chef_config``
   **Ruby Type:** String

   Use to specify a string that contains extra configuration settings for a machine.

``chef_environment``
   The name of the environment.

``chef_server``
   **Ruby Type:** Hash

   The URL for the Chef server.

``complete``
   Use to specify if all of the normal attributes specified by this resource represent a complete specification of normal attributes for a machine. When ``true``, any attributes not specified will be reset to their default values. For example, if a **machine** resource is empty and sets ``complete`` to ``true``, all existing attributes will be reset:

   .. code-block:: ruby

      machine "foo" do
        complete "true"
      end

``converge``
   **Ruby Types:** TrueClass, FalseClass

   Use to manage convergence when used with the ``:create`` action. Set to ``false`` to prevent convergence. Set to ``true`` to force convergence. When ``nil``, the machine will converge only if something changes. Default value: ``nil``.

``driver``
   **Ruby Type:** Chef::Provisioning::Driver

   Use to specify the URL for the driver to be used for provisioning.

``files``
   **Ruby Type:** Hash

   A list of files to upload. Syntax: ``REMOTE_PATH => LOCAL_PATH_OR_HASH``.

   For example:

   .. code-block:: ruby

      files '/remote/path.txt' => '/local/path.txt'

   or:

   .. code-block:: ruby

      files '/remote/path.txt' => {
        :local_path => '/local/path.txt'
      }

   or:

   .. code-block:: ruby

      files '/remote/path.txt' => { :content => 'foo' }

``from_image``
   **Ruby Type:** String

   Use to specify an image created by the **machine_image** resource.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``machine_options``
   **Ruby Type:** Hash

   A Hash that is specifies driver options.

``name``
   **Ruby Type:** String

   The name of the machine.

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

``ohai_hints``
   **Ruby Type:** Hash

   An Ohai hint to be set on the target node. For example: ``'ec2' => { 'a' => 'b' } creates file ec2.json with json contents { 'a': 'b' }``.

``private_key_options``
   **Ruby Type:** Hash

   Use to generate a private key of the desired size, type, and so on.

``public_key_format``
   **Ruby Type:** String

   Use to specify the format of a public key. Possible values: ``pem`` and ``der``. Default value: ``pem``.

``public_key_path``
   **Ruby Type:** String

   The path to a public key.

``raw_json``
   The machine as JSON data. For example:

   .. code-block:: javascript

      {
        "name": "node1",
        "chef_environment": "_default",
        "json_class": "Chef::Node",
        "automatic": {
          "languages": {
            "ruby": {
              ...
            },
          ...
        ...
      }

``recipe``
   Use to add a recipe to the run-list for a machine. Use this property multiple times to add multiple recipes to a run-list. Use this property along with ``role`` to define a run-list. The order in which the ``recipe`` and ``role`` properties are specified will determine the order in which they are added to the run-list. This property should not be used in the same recipe as ``run_list``. For example:

   .. code-block:: ruby

      recipe 'foo'
      role 'bar'
      recipe 'baz'

``remove_recipe``
   Use to remove a recipe from the run-list for the machine.

``remove_role``
   Use to remove a role from the run-list for the machine.

``remove_tag``
   Use to remove a tag.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``role``
   Use to add a role to the run-list for the machine. Use this property multiple times to add multiple roles to a run-list. Use this property along with ``recipe`` to define a run-list. The order in which the ``recipe`` and ``role`` properties are specified will determine the order in which they are added to the run-list. This property should not be used in the same recipe as ``run_list``. For example:

   .. code-block:: ruby

      recipe 'foo'
      role 'bar'
      recipe 'baz'

``run_list``
   An array of strings that specifies the run-list to apply to a machine. This property should not be used in the same recipe as ``recipe`` and ``role``. For example:

   .. code-block:: ruby

      [ 'recipe[COOKBOOK::RECIPE]','COOKBOOK::RECIPE','role[NAME]' ]

``source_key``
   Use to copy a private key, but apply a different ``format`` and ``password``. Use in conjunction with ``source_key_pass_phrase``` and ``source_key_path``.

``source_key_pass_phrase``
   **Ruby Type:** String

   The pass phrase for the private key. Use in conjunction with ``source_key``` and ``source_key_path``.

``source_key_path``
   **Ruby Type:** String

   The path to the private key. Use in conjunction with ``source_key``` and ``source_key_pass_phrase``.

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

``tag``
   Use to add a tag.

``tags``
   Use to add one (or more) tags. This will remove any tag currently associated with the machine. For example: ``tags :a, :b, :c``.

``validator``
   **Ruby Types:** TrueClass, FalseClass

   Use to specify if the chef-client is a chef-validator.

.. end_tag

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Build machines dynamically**

.. tag resource_machines_build_machines_dynamically

.. To build machines dynamically:

.. code-block:: ruby

   machine 'mario' do
     recipe 'postgresql'
     recipe 'mydb'
     tag 'mydb_master'
   end

   num_webservers = 1

   1.upto(num_webservers) do |i|
     machine "luigi#{i}" do
       recipe 'apache'
       recipe 'mywebapp'
     end
   end

.. end_tag

**Get a remote file onto a new machine**

.. tag resource_machine_file_get_remote_file

A deployment process requires more than just setting up machines. For example, files may need to be copied to machines from remote locations. The following example shows how to use the **remote_file** resource to grab a tarball from a URL, create a machine, copy that tarball to the machine, and then get that machine running by using a recipe that installs and configures that tarball on the machine:

.. code-block:: ruby

   remote_file 'mytarball.tgz' do
     url 'https://myserver.com/mytarball.tgz'
   end

   machine 'x'
     action :allocate
   end

   machine_file '/tmp/mytarball.tgz' do
     machine 'x'
     local_path 'mytarball.tgz'
     action :upload
   end

   machine 'x' do
     recipe 'untarthatthing'
     action :converge
   end

.. end_tag

**Build machines that depend on each other**

.. tag resource_machines_codependent_servers

The following example shows how to create two identical machines, both of which cannot exist without the other. The first **machine** resource block creates the first machine by omitting the recipe that requires the other machine to be defined. The second resource block creates the second machine; because the first machine exists, both recipes can be run. The third resource block applies the second recipe to the first machine:

.. code-block:: ruby

   machine 'server_a' do
     recipe 'base_recipes'
   end

   machine 'server_b' do
     recipe 'base_recipes'
     recipe 'theserver'
   end

   machine 'server_a' do
     recipe 'theserver'
   end

.. end_tag

**Use a loop to build many machines**

.. tag resource_machines_use_a_loop_to_create_many_machines

.. To create multiple machines using a loop:

.. code-block:: ruby

   1.upto(10) do |i|
     machine "hadoop#{i}" do
       recipe 'hadoop'
     end
   end

.. end_tag

**Converge multiple machine types, in-parallel**

.. tag resource_machine_batch_multiple_machine_types

The **machine_batch** resource can be used to converge multiple machine types, in-parallel, even if each machine type has different drivers. For example:

.. code-block:: ruby

   machine_batch do
     machine 'db' do
       recipe 'mysql'
     end
     1.upto(50) do |i|
       machine "#{web}#{i}" do
         recipe 'apache'
       end
     end
   end

.. end_tag

**Define machine_options for a driver**

.. To define machine options:

.. code-block:: ruby

   require 'chef/provisioning_driver'

   machine 'wario' do
     recipe 'apache'

     machine_options :driver_options => {
      :base_image => {
        :name => 'ubuntu',
        :repository => 'ubuntu',
        :tag => '14.04'
        },

      :command => '/usr/sbin/httpd'
     }

   end

where ``provisioning_driver`` and ``:driver_options`` specify the actual ``driver`` that is being used to build the machine.

**Build a machine from a machine image**

.. tag resource_machine_image_add_apache_to_image

.. To add Apache to a machine image, and then build a machine:

.. code-block:: ruby

   machine_image 'web_image' do
     recipe 'apache2'
   end

   machine 'web_machine' do
    from_image 'web_image'
   end

.. end_tag

**Set up a VPC, route table, key pair, and machine for Amazon AWS**

.. tag resource_provisioning_aws_route_table_define_vpc_key_machine

.. To define a VPC, route table, key pair, and machine:

.. code-block:: ruby

   require 'chef/provisioning/aws_driver'

   with_driver 'aws::eu-west-1'

   aws_vpc 'test-vpc' do
     cidr_block '10.0.0.0/24'
     internet_gateway true
   end

   aws_route_table 'ref-public1' do
     vpc 'test-vpc'
     routes '0.0.0.0/0' => :internet_gateway
   end

   aws_key_pair 'ref-key-pair'

   m = machine 'test' do
     machine_options bootstrap_options: { key_name: 'ref-key-pair' }
   end

.. end_tag

