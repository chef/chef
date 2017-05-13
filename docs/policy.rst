=====================================================
About Policy
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/policy.rst>`__

.. tag policy_summary

Policy maps business and operational requirements, process, and workflow to settings and objects stored on the Chef server:

* Roles define server types, such as "web server" or "database server"
* Environments define process, such as "dev", "staging", or "production"
* Certain types of data---passwords, user account data, and other sensitive items---can be placed in data bags, which are located in a secure sub-area on the Chef server that can only be accessed by nodes that authenticate to the Chef server with the correct SSL certificates
* The cookbooks (and cookbook versions) in which organization-specific configuration policies are maintained

.. end_tag

Cookbook Versions
=====================================================
.. tag cookbooks_version

A cookbook version represents a set of functionality that is different from the cookbook on which it is based. A version may exist for many reasons, such as ensuring the correct use of a third-party component, updating a bug fix, or adding an improvement. A cookbook version is defined using syntax and operators, may be associated with environments, cookbook metadata, and/or run-lists, and may be frozen (to prevent unwanted updates from being made).

A cookbook version is maintained just like a cookbook, with regard to source control, uploading it to the Chef server, and how the chef-client applies that cookbook when configuring nodes.

.. end_tag

.. note:: For more information about cookbook versions, see :doc:`About Cookbook Versions </cookbook_versions>`

Data Bags (Secrets)
=====================================================
.. tag data_bag

A data bag is a global variable that is stored as JSON data and is accessible from a Chef server. A data bag is indexed for searching and can be loaded by a recipe or accessed during a search.

.. end_tag

.. note:: For more information about data bags, see :doc:`About Data Bags </data_bags>`

Environments
=====================================================
.. tag environment

An environment is a way to map an organization's real-life workflow to what can be configured and managed when using Chef server. Every organization begins with a single environment called the ``_default`` environment, which cannot be modified (or deleted). Additional environments can be created to reflect each organization's patterns and workflow. For example, creating ``production``, ``staging``, ``testing``, and ``development`` environments. Generally, an environment is also associated with one (or more) cookbook versions.

.. end_tag

.. note:: For more information about environments, see :doc:`About Environments </environments>`

Roles
=====================================================
.. tag role

A role is a way to define certain patterns and processes that exist across nodes in an organization as belonging to a single job function. Each role consists of zero (or more) attributes and a run-list. Each node can have zero (or more) roles assigned to it. When a role is run against a node, the configuration details of that node are compared against the attributes of the role, and then the contents of that role's run-list are applied to the node's configuration details. When a chef-client runs, it merges its own attributes and run-lists with those contained within each assigned role.

.. end_tag

.. note:: For more information about roles, see :doc:`About Roles </roles>`

Policyfile
=====================================================
.. tag policyfile_summary

.. note:: Policyfile file is an optional way to manage role, environment, and community cookbook data.

Policyfile is a single document that is uploaded to the Chef server. It is associated with a group of nodes, cookbooks, and settings. When these nodes run, they run the recipes specified in the Policyfile run-list.

.. warning:: Policyfile is not integrated with Chef Automate and is not supported as part of a Chef Automate workflow.

.. end_tag

.. note:: For more information about Policyfile, see :doc:`About Policyfile </policyfile>`
