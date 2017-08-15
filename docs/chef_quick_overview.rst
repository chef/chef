=====================================================
A Quick Overview of Chef
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/chef_quick_overview.rst>`__

Welcome to Chef!

.. tag chef

Chef is a powerful automation platform that transforms infrastructure into code. Whether you’re operating in the cloud, on-premises, or in a hybrid environment, Chef automates how infrastructure is configured, deployed, and managed across your network, no matter its size.

This diagram shows how you develop, test, and deploy your Chef code.

.. image:: ../../images/start_chef.svg
   :width: 700px
   :align: center

.. end_tag

Chef Components
=====================================================
The following diagram shows the relationships between the various elements of a very simple organization, including the hosted Enterprise Chef server, a workstations, the chef-repo, and some simple nodes that exist either in VirtualBox or Amazon Web Services (AWS).

.. image:: ../../images/overview_chef_quick.png

The following sections discuss these elements in a bit more detail.

Nodes
=====================================================
.. tag node

A node is any machine---physical, virtual, cloud, network device, etc.---that is under management by Chef.

.. end_tag

Workstations
=====================================================
.. tag workstation_summary

A workstation is a computer running the Chef Development Kit (ChefDK) that is used to author cookbooks, interact with the Chef server, and interact with nodes.

The workstation is the location from which most users do most of their work, including:

* Developing and testing cookbooks and recipes
* Testing Chef code
* Keeping the chef-repo synchronized with version source control
* Configuring organizational policy, including defining roles and environments, and ensuring that critical data is stored in data bags
* Interacting with nodes, as (or when) required, such as performing a bootstrap operation

.. end_tag

Knife
-----------------------------------------------------
.. tag knife_summary

knife is a command-line tool that provides an interface between a local chef-repo and the Chef server. knife helps users to manage:

* Nodes
* Cookbooks and recipes
* Roles, Environments, and Data Bags
* Resources within various cloud environments
* The installation of the chef-client onto nodes
* Searching of indexed data on the Chef server

.. end_tag

Repository
-----------------------------------------------------
.. tag chef_repo_summary

The chef-repo is the repository structure in which cookbooks are authored, tested, and maintained:

* Cookbooks contain recipes, attributes, custom resources, libraries, files, templates, tests, and metadata
* The chef-repo should be synchronized with a version control system (such as git), and then managed as if it were source code

.. end_tag

git is the most commonly-used location to store a chef-repo that is used with a hosted Enterprise Chef account, but git is not required.

.. tag chef_repo_structure

The directory structure within the chef-repo varies. Some organizations prefer to keep all of their cookbooks in a single chef-repo, while other organizations prefer to use a chef-repo for every cookbook.

.. end_tag

The Hosted Chef Server
=====================================================
.. tag chef_server

The Chef server acts as a hub for configuration data. The Chef server stores cookbooks, the policies that are applied to nodes, and metadata that describes each registered node that is being managed by the chef-client. Nodes use the chef-client to ask the Chef server for configuration details, such as recipes, templates, and file distributions. The chef-client then does as much of the configuration work as possible on the nodes themselves (and not on the Chef server). This scalable approach distributes the configuration effort throughout the organization.

.. end_tag

The hosted Chef server is a version of the Chef server that is hosted by Chef. The hosted Chef server is cloud-based, scalable, and available (24x7/365), with resource-based access control. The hosted Chef server has the same automation capabilities of any Chef server, but without requiring it to be set up and managed from behind the firewall.

Cookbooks
-----------------------------------------------------
.. tag cookbooks_summary

A cookbook is the fundamental unit of configuration and policy distribution. A cookbook defines a scenario and contains everything that is required to support that scenario:

* Recipes that specify the resources to use and the order in which they are to be applied
* Attribute values
* File distributions
* Templates
* Extensions to Chef, such as custom resources and libraries

.. end_tag

The chef-client uses Ruby as its reference language for creating cookbooks and defining recipes, with an extended DSL for specific resources. The chef-client provides a reasonable set of resources, enough to support many of the most common infrastructure automation scenarios; however, this DSL can also be extended when additional resources and capabilities are required.

Conclusion
=====================================================
.. tag chef_about

Chef is a thin DSL (domain-specific language) built on top of Ruby. This approach allows Chef to provide just enough abstraction to make reasoning about your infrastructure easy. Chef includes a built-in taxonomy of all the basic resources one might configure on a system, plus a defined mechanism to extend that taxonomy using the full power of the Ruby language. Ruby was chosen because it provides the flexibility to use both the simple built-in taxonomy, as well as being able to handle any customization path your organization requires.

.. end_tag
