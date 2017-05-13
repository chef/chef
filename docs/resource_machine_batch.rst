=====================================================
machine_batch
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_machine_batch.rst>`__

.. tag resource_machine_batch_summary

Use the **machine_batch** resource to explicitly declare a parallel process when building machines.

.. end_tag

.. warning:: .. tag notes_provisioning

             This functionality is available with Chef provisioning and is packaged in the Chef development kit. Chef provisioning is a framework that allows clusters to be managed by the chef-client and the Chef server in the same way nodes are managed: with recipes. Use Chef provisioning to describe, version, deploy, and manage clusters of any size and complexity using a common set of tools.

             .. end_tag

Syntax
=====================================================
.. tag resource_machine_batch_syntax

The syntax for using the **machine_batch** resource in a recipe is as follows:

.. code-block:: ruby

   machine_batch 'name' do
     attribute 'value' # see properties section below
     ...
     action :action # see actions section below
   end

where

* ``machine_batch`` tells the chef-client to use the ``Chef::Provider::MachineBatch`` provider during the chef-client run
* ``name`` is the name of the resource block
* ``attribute`` is zero (or more) of the properties that are available for this resource
* ``action`` identifies which steps the chef-client will take to bring the node into the desired state

.. end_tag

Actions
=====================================================
.. tag resource_machine_batch_actions

This resource has the following actions:

``:allocate``

``:converge``
   Default.

``:converge_only``

``:destroy``

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:ready``

``:setup``

``:stop``

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
.. tag resource_machine_batch_attributes

This resource has the following attributes:

``chef_server``
   **Ruby Type:** Hash

   The URL for the Chef server.

``driver``
   **Ruby Type:** Chef::Provisioning::Driver

   Use to specify the driver to be used for provisioning.

``files``
   ...

``from_recipe``
   ...

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``machine_options``
   ...

``machines``
   ...

``max_simultaneous``
   ...

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

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

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

.. end_tag

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Set up multiple machines, in-parallel**

.. tag resource_machine_batch_setup_n_machines

.. To setup multiple machines in-parallel:

.. code-block:: ruby

   machine_batch do
     action :setup
     machines 'a', 'b', 'c', 'd', 'e'
   end

.. end_tag

**Converge multiple machines, in-parallel**

.. tag resource_machine_batch_converge_n_machines

.. To converge multiple machines in-parallel:

.. code-block:: ruby

   machine_batch do
     action :converge
     machines 'a', 'b', 'c', 'd', 'e'
   end

.. end_tag

**Stop multiple machines, in-parallel**

.. tag resource_machine_batch_stop_n_machines

.. To stop multiple machines in-parallel:

.. code-block:: ruby

   machine_batch do
     action :stop
     machines 'a', 'b', 'c', 'd', 'e'
   end

.. end_tag

**Destroy multiple machines, in-parallel**

.. tag resource_machine_batch_destroy_n_machines

.. To delete multiple machines in-parallel:

.. code-block:: ruby

   machine_batch do
     action :delete
     machines 'a', 'b', 'c', 'd', 'e'
   end

.. end_tag

**Destroy all machines**

.. To delete all machines:

.. code-block:: ruby

   machine_batch do
     machines search(:node, '*:*').map { |n| n.name }
     action :destroy
   end

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

**Set up primary and secondary machines for high availability**

.. To setup primary and secondary machines:

.. code-block:: ruby

   machine_batch do
     machines %w(primary secondary web1 web2)
   end

   machine_batch do
     machine 'primary' do
       recipe 'initial_ha_setup'
     end
   end

   machine_batch do
     machine 'secondary' do
       recipe 'initial_ha_setup'
     end
   end

   machine_batch do
     %w(primary secondary).each do |name|
       machine name do
         recipe 'rest_of_setup'
       end
     end
   end

**Destroy EBS volumes for batch of machines, along with keys**

.. tag resource_provisioning_aws_ebs_volume_delete_machine_and_keys

.. To destroy a named group of machines along with keys:

The following example destroys an Amazon Elastic Block Store (EBS) volume for the specified batch of machines, along with any associated public and/or private keys:

.. code-block:: ruby

   ['ref-volume-ebs', 'ref-volume-ebs-2'].each { |volume|
     aws_ebs_volume volume do
       action :destroy
     end
   }

   machine_batch do
     machines 'ref-machine-1', 'ref-machine-2'
     action :destroy
   end

   aws_key_pair 'ref-key-pair-ebs' do
     action :destroy
   end

.. end_tag

**Define subnets for a batch of machines on Amazon AWS**

.. tag resource_provisioning_aws_security_group_machine_batch

.. To define a VPC, subnets, and security group for a batch of machines:

.. code-block:: ruby

   require 'chef/provisioning/aws_driver'

   with_driver 'aws::eu-west-1'
     aws_vpc 'provisioning-vpc' do
       cidr_block '10.0.0.0/24'
       internet_gateway true
       main_routes '0.0.0.0/0' => :internet_gateway
     end

     aws_subnet 'provisioning-vpc-subnet-a' do
       vpc 'provisioning-vpc'
       cidr_block '10.0.0.0/26'
       availability_zone 'eu-west-1a'
       map_public_ip_on_launch true
     end

     aws_subnet 'provisioning-vpc-subnet-b' do
       vpc 'provisioning-vpc'
       cidr_block '10.0.0.128/26'
       availability_zone 'eu-west-1a'
       map_public_ip_on_launch true
     end

   machine_batch do
     machines %w(mario-a mario-b)
     action :destroy
   end

   machine_batch do
     machine 'mario-a' do
       machine_options bootstrap_options: { subnet: 'provisioning-vpc-subnet-a' }
     end

     machine 'mario-b' do
       machine_options bootstrap_options: { subnet: 'provisioning-vpc-subnet-b' }
     end
   end

   aws_security_group 'provisioning-vpc-security-group' do
     inbound_rules [
       {:port => 2223, :protocol => :tcp, :sources => ['10.0.0.0/24'] },
       {:port => 80..100, :protocol => :udp, :sources => ['1.1.1.0/24'] }
     ]
     outbound_rules [
       {:port => 2223, :protocol => :tcp, :destinations => ['1.1.1.0/16'] },
       {:port => 8080, :protocol => :tcp, :destinations => ['2.2.2.0/24'] }
     ]
     vpc 'provisioning-vpc'
   end

.. end_tag

