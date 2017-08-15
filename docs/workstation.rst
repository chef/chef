=====================================================
Workstations
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/workstation.rst>`__

.. tag workstation_summary

A workstation is a computer running the Chef Development Kit (ChefDK) that is used to author cookbooks, interact with the Chef server, and interact with nodes.

The workstation is the location from which most users do most of their work, including:

* Developing and testing cookbooks and recipes
* Testing Chef code
* Keeping the chef-repo synchronized with version source control
* Configuring organizational policy, including defining roles and environments, and ensuring that critical data is stored in data bags
* Interacting with nodes, as (or when) required, such as performing a bootstrap operation

.. end_tag

Some important components of workstations include:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Feature
     - Description
   * - :doc:`Knife </knife>`
     - .. tag knife_summary

       knife is a command-line tool that provides an interface between a local chef-repo and the Chef server. knife helps users to manage:

       * Nodes
       * Cookbooks and recipes
       * Roles, Environments, and Data Bags
       * Resources within various cloud environments
       * The installation of the chef-client onto nodes
       * Searching of indexed data on the Chef server

       .. end_tag

   * - :doc:`The chef-repo </chef_repo>`
     - .. tag chef_repo_summary

       The chef-repo is the repository structure in which cookbooks are authored, tested, and maintained:

       * Cookbooks contain recipes, attributes, custom resources, libraries, files, templates, tests, and metadata
       * The chef-repo should be synchronized with a version control system (such as git), and then managed as if it were source code

       .. end_tag

       .. tag chef_repo_structure

       The directory structure within the chef-repo varies. Some organizations prefer to keep all of their cookbooks in a single chef-repo, while other organizations prefer to use a chef-repo for every cookbook.

       .. end_tag

   * - :doc:`knife.rb </config_rb_knife>`
     - .. tag config_rb_knife_summary

       A knife.rb file is used to specify configuration details for knife.

       .. end_tag

Chef DK
=====================================================

.. tag chef_index

.. This page is used as the short overview on the index page at docs.chef.io

Chef is a systems and cloud infrastructure automation framework that makes it easy to deploy servers and applications to any physical, virtual, or cloud location, no matter the size of the infrastructure. Each organization is comprised of one (or more) workstations, a single server, and every node that will be configured and maintained by the chef-client. Cookbooks (and recipes) are used to tell the chef-client how each node in your organization should be configured. The chef-client (which is installed on every node) does the actual configuration.

.. end_tag

.. tag chef_dk

The Chef Development Kit is a package that contains everything that is needed to start using Chef:

* chef-client and ohai
* chef command line tool
* Testing tools such as Test Kitchen, ChefSpec, Cookstyle, and Foodcritic
* Chef provisioning
* Everything else needed to author cookbooks and upload them to the Chef server

.. end_tag

After :doc:`installing the ChefDK </install_dk>`, learn more about the tools that are packaged with the Chef development kit:

* :doc:`chef (executable) </ctl_chef>`
* :doc:`Berkshelf </berkshelf>`
* :doc:`chef-vault </chef_vault>`
* :doc:`ChefSpec </chefspec>`
* :doc:`Foodcritic </foodcritic>`
* :doc:`test-kitchen </kitchen>`
