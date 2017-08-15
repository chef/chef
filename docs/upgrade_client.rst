=====================================================
chef-client Upgrades
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/upgrade_client.rst>`__

The following sections describe the upgrade process for chef-client 12.

Please :doc:`view the notes </upgrade_client_notes>` for more background on the upgrade process.

Upgrade via Command Line
=====================================================
To upgrade the chef-client on a node via the command line, run the  following command on each node to be upgraded:

.. code-block:: bash

   curl -L https://chef.io/chef/install.sh | sudo bash

Using the ``knife ssh`` subcommand is one way to do this.

Upgrade via Cookbook
=====================================================
The `chef_client_updater <https://supermarket.chef.io/cookbooks/chef_client_updater>`__ cookbook can be used to install or upgrade the chef-client package on a node.
