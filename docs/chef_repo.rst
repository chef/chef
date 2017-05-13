=====================================================
About the chef-repo
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/chef_repo.rst>`__

.. note:: For information about the accessing the source code implementation of Chef (the Chef repo on GitHub), see :doc:`Community Contributions </community_contributions>`. 

.. tag chef_repo_description

The chef-repo is a directory on your workstation that stores:

* Cookbooks (including recipes, attributes, custom resources, libraries, and templates)
* Roles
* Data bags
* Environments

The chef-repo directory should be synchronized with a version control system, such as git. All of the data in the chef-repo should be treated like source code.

knife is used to upload data to the Chef server from the chef-repo directory. Once uploaded, that data is used by the chef-client to manage all of the nodes that are registered with the Chef server and to ensure that the correct cookbooks, environments, roles, and other settings are applied to nodes correctly.

.. end_tag

Directory Structure
=====================================================
The chef-repo contains several directories, each with a README file that describes what it is for and how to use that directory when managing systems.

.. note:: This document describes the default directory that is present in most instances of the chef-repo.

The sub-directories in the chef-repo are:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Directory
     - Description
   * - ``.chef/``
     - A hidden directory that is used to store validation key files and the knife.rb file.
   * - ``cookbooks/``
     - Contains cookbooks that have been downloaded from the |url supermarket| or created locally.
   * - ``data_bags/``
     - Stores data bags (and data bag items) in JSON (.json).
   * - ``environments/``
     - Stores environment in Ruby (.rb) or JSON (.json).
   * - ``roles/``
     - Stores roles in Ruby (.rb) or JSON (.json).

.chef/
-----------------------------------------------------
.. tag all_directory_chef

The .chef directory is a hidden directory that is used to store validation key files and the knife.rb file.

.. end_tag

cookbooks/
-----------------------------------------------------
The ``cookbooks/`` directory is used to store the cookbooks that are used by the chef-client when configuring the various systems in the organization. This directory contains the cookbooks that are used to configure systems in the infrastructure. Each cookbook can be configured to contain cookbook-specific copyright, email, and license data.

data_bags/
-----------------------------------------------------
The ``data_bags/`` directory is used to store all of the data bags that exist for an organization. Each sub-directory corresponds to a single data bag on the Chef server and contains a JSON file for each data bag item. If a sub-directory does not exist, then create it using SSL commands. After a data bag item is created, it can then be uploaded to the Chef server.

environments/
-----------------------------------------------------
The ``environments/`` directory is used to store the files that define the environments that are available to the Chef server. The environments files can be Ruby DSL files (.rb) or they can be JSON files (.json). Use knife to install environment files to the Chef server.

roles/
-----------------------------------------------------
The ``roles/`` directory is used to store the files that define the roles that are available to the Chef server. The roles files can be Ruby DSL files (.rb) or they can be JSON files (.json). Use knife to install role files to the Chef server.

chefignore Files
=====================================================
The chefignore file is used to tell knife which cookbook files in the chef-repo should be ignored when uploading data to the Chef server. The type of data that should be ignored includes swap files, version control data, build output data, and so on. The chefignore file uses the ``File.fnmatch`` Ruby syntax to define the ignore patterns using ``*``, ``**``, and ``?`` wildcards.

* A pattern is relative to the cookbook root
* A pattern may contain relative directory names
* A pattern may match all files in a directory

The chefignore file can be located in any subdirectory of a chef-repo: ``/``, ``/cookbooks``, ``/cookbooks/COOKBOOK_NAME/``, ``roles``, etc. It should contain sections similar to the following:

.. code-block:: none

   # section
   *ignore_pattern

   # section
   ignore_pattern*

   # section
   **ignore_pattern

   # section
   ignore_pattern**

   # section
   ?ignore_pattern

   # section
   ignore_pattern?

Examples
-----------------------------------------------------
The following examples show how to add entries to the ``chefignore`` file.

**Ignore editor swap files**

Many text editors leave files behind. To prevent these files from being uploaded to the Chef server, add an entry to the chefignore file. For Emacs, do something like:

.. code-block:: none

   *~

and for vim, do something like:

.. code-block:: none

   *.sw[a-z]

**Ignore top-level Subversion data**

If Subversion is being used as the version source control application, it is important not to upload certain files that Subversion uses to maintain the version history of each file. This is because the chef-client will never use it while configuring nodes, plus the amount of data in an upload that includes top-level Subversion data could be significant.

To prevent the upload of top-level Subversion data, add something like the following to the chefignore file:

.. code-block:: none

   */.svn/*

To verify that the top-level Subversion data is not being uploaded to the Chef server, use knife and run a command similar to:

.. code-block:: bash

   $ knife cookbook show name_of_cookbook cookbook_version | grep .svn

**Ignore all files in a directory**

The chefignore file can be used to ignore all of the files in a directory. For example:

.. code-block:: none

   files/default/subdirectory/*

or:

.. code-block:: none

   files/default/subdirectory/**

Many Users, Same Repo
=====================================================
.. tag chef_repo_many_users_same_repo

It is possible for multiple users to access the Chef server using the same knife.rb file. (A user can even access multiple organizations if, for example, each instance of the chef-repo contained the same copy of the knife.rb file.) This can be done by adding the knife.rb file to the chef-repo, and then using environment variables to handle the user-specific credential details and/or sensitive values. For example:

.. code-block:: none

   current_dir = File.dirname(__FILE__)
     user = ENV['OPSCODE_USER'] || ENV['USER']
     node_name                user
     client_key               "#{ENV['HOME']}/chef-repo/.chef/#{user}.pem"
     validation_client_name   "#{ENV['ORGNAME']}-validator"
     validation_key           "#{ENV['HOME']}/chef-repo/.chef/#{ENV['ORGNAME']}-validator.pem"
     chef_server_url          "https://api.opscode.com/organizations/#{ENV['ORGNAME']}"
     syntax_check_cache_path  "#{ENV['HOME']}/chef-repo/.chef/syntax_check_cache"
     cookbook_path            ["#{current_dir}/../cookbooks"]
     cookbook_copyright       "Your Company, Inc."
     cookbook_license         "apachev2"
     cookbook_email           "cookbooks@yourcompany.com"

     # Amazon AWS
     knife[:aws_access_key_id] = ENV['AWS_ACCESS_KEY_ID']
     knife[:aws_secret_access_key] = ENV['AWS_SECRET_ACCESS_KEY']

     # Rackspace Cloud
     knife[:rackspace_api_username] = ENV['RACKSPACE_USERNAME']
     knife[:rackspace_api_key] = ENV['RACKSPACE_API_KEY']

.. end_tag

Create the chef-repo
=====================================================
There are two ways to create a chef-repo when using the Chef boilerplate repository as a base:

* Clone the chef-repo from GitHub
* Download the chef-repo as a tar.gz file and place it into local version source control.

.. note:: Chef strongly recommends using some type of version control tool to manage the source code in the chef-repo. Chef uses git for everything, including for cookbooks. git and/or GitHub is not required to use Chef. If another version source control system is preferred over git (such as Subversion, Mercurial, or Bazaar) that is just fine.

Generate
-----------------------------------------------------
To create a chef-repo, run the following command:

.. code-block:: bash

   $ chef generate repo REPO_NAME

This command uses the ``chef`` command-line tool that is packaged as part of the Chef development kit to create a chef-repo.

