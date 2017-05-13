=====================================================
Working with Knife
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_using.rst>`__

knife runs from a management workstation and sits in-between a Chef server and an organization's infrastructure. knife interacts with a Chef server by using the same REST API that is used by a chef-client. Role-based authentication controls (RBAC) can be used to authorize changes when knife is run with the Chef server. knife is configured during workstation setup, but subsequent modifications can be made using the knife.rb configuration file.

JSON Data Format
=====================================================
Most data is entered using a text editor in JSON format, unless the ``--disable-editing`` option is entered as part of a command. (Encrypted data bags use YAML, which is a superset of JSON.) JSON is a common, language-independent data format that provides a simple text representation of arbitrary data structures. For more information about JSON, see http://www.json.org/ or http://en.wikipedia.org/wiki/JSON.

Set the Text Editor
-----------------------------------------------------
.. tag knife_common_set_editor

Some knife commands, such as ``knife data bag edit``, require that information be edited as JSON data using a text editor. For example, the following command:

.. code-block:: bash

   $ knife data bag edit admins admin_name

will open up the text editor with data similar to:

.. code-block:: javascript

   {
     "id": "admin_name"
   }

Changes to that file can then be made:

.. code-block:: javascript

   {
     "id": "Justin C."
     "description": "I am passing the time by letting time pass over me ..."
   }

The type of text editor that is used by knife can be configured by adding an entry to the knife.rb file or by setting an ``EDITOR`` environment variable. For example, to configure the text editor to always open with vim, add the following to the knife.rb file:

.. code-block:: ruby

   knife[:editor] = "/usr/bin/vim"

When a Microsoft Windows file path is enclosed in a double-quoted string (" "), the same backslash character (``\``) that is used to define the file path separator is also used in Ruby to define an escape character. The knife.rb file is a Ruby file; therefore, file path separators must be escaped. In addition, spaces in the file path must be replaced with ``~1`` so that the length of each section within the file path is not more than 8 characters. For example, if EditPad Pro is the text editor of choice and is located at the following path::

   C:\\Program Files (x86)\EditPad Pro\EditPad.exe

the setting in the knife.rb file would be similar to:

.. code-block:: ruby

   knife[:editor] = "C:\\Progra~1\\EditPa~1\\EditPad.exe"

One approach to working around the double- vs. single-quote issue is to put the single-quotes outside of the double-quotes. For example, for Notepad++:

.. code-block:: ruby

   knife[:editor] = '"C:\Program Files (x86)\Notepad++\notepad++.exe" -nosession -multiInst'

for Sublime Text:

.. code-block:: ruby

   knife[:editor] = '"C:\Program Files\Sublime Text 2\sublime_text.exe" --wait'

for TextPad:

.. code-block:: ruby

   knife[:editor] = '"C:\Program Files (x86)\TextPad 7\TextPad.exe"'

and for vim:

.. code-block:: ruby

   knife[:editor] = '"C:\Program Files (x86)\vim\vim74\gvim.exe"'

.. end_tag

Using Quotes
=====================================================
Values can be entered with double quotes (" ") or single quotes (' '), but this should be done consistently.

Subcommands
=====================================================
knife comes with a collection of built in subcommands that work together to provide all of the functionality required to take specific actions against any object in an organization, including cookbooks, nodes, roles, data bags, environments, and users. A knife plugin extends the functionality beyond built-in subcommands.

knife has the following subcommands: ``bootstrap``, ``client``, ``configure``, ``cookbook``, ``cookbook site``, ``data bag``, ``delete``, ``deps``, ``diff``, ``download``, ``edit``, ``environment``, ``exec``, ``index rebuild``, ``list``, ``node``, ``recipe list``, ``role``, ``search``, ``show``, ``ssh``, ``status``, ``tag``, ``upload``, ``user``, and ``xargs``.

.. note:: The following subcommands run only against the open source Chef server: ``index rebuild`` and ``user``.

Verb Subcommands
=====================================================
knife includes a set of subcommands that are built around common verbs: ``delete``, ``deps``, ``diff``, ``download``, ``edit``, ``list``, ``show``, ``upload``, ``xargs``. These subcommands allow knife to issue commands that interact with any object stored in the chef-repo or stored on the Chef server. Some important principles behind this group of subcommands includes:

* A command that works with each object in the chef-repo. The subcommands specify the desired action (the "verb"), and then directory in which that object resides (``clients``, ``cookbooks/``, ``data_bags/``, ``environments/``, ``nodes``, ``roles/``, and ``users``). For example: ``download cookbooks/``
* A command that works with certain objects in the Chef server, including ``acls``, ``groups``, and ``containers``
* Uses the Chef server as if it were a file system, allowing the chef-repo on the Chef server to behave like a mirror of the chef-repo on the workstation. The Chef server will have the same objects as the local chef-repo. To make changes to the files on the Chef server, just download files from the Chef server or upload files from the chef-repo
* The context from which a command is run matters. For example, when working in the ``roles/`` directory, knife will know what is being worked with. Enter ``knife show base.json`` and knife will return the base role from the Chef server. From the chef-repo root, enter ``knife show roles/base.json`` to get the same result
* Parallel requests can be made to the Chef server and are configurable on a per-command basis

Wildcard Search
-----------------------------------------------------
A wildcard matching pattern can be used for substring matches that replace zero (or more) characters. There are two types of wildcard patterns:

* A question mark ("?") can be used to replace exactly one character (as long as that character is not the first character)
* An asterisk ("*") can be used to replace any number of characters (including zero)

Wildcard patterns must be escaped (using a backslash) so that the wildcard itself can reach the Chef server. If they are not escaped, the wildcard is expanded into the actual filenames and knife will not know the wildcard was intended to be used. For example, if the Chef server has data bags named ``aardvarks``, ``anagrams``, and ``arp_tables``, but the local file system only has ``aardvarks`` and ``anagrams``, escaping vs. not escaping the wildcard pattern will yield different results:

.. code-block:: bash

   $ knife list data_bags/a\*

asks the Chef server for everything starting with the letter "a" and will return:

.. code-block:: bash

   $ aardvarks/ anagrams/ arp_tables/

But, the following:

.. code-block:: bash

   $ knife list data_bags/a*

will return:

.. code-block:: bash

   $ aardvarks/ anagrams/

Which is the same as entering:

.. code-block:: bash

   $ knife list data_bags/aardvarks data_bags/anagrams

to return:

.. code-block:: bash

   $ aardvarks/ anagrams/

Plug-ins
=====================================================
Chef provides the following plugins, which work the same as built-in subcommands (including common options), but must be installed separately (using RubyGems): ``knife azure``, ``knife bluebox``, ``knife ec2``, ``knife eucalyptus``, ``knife google``, ``knife linode``, ``knife openstack``, ``knife rackspace``, ``knife terremark``, ``knife vcloud``, and ``knife windows``.

The community provides many other plugins for knife: http://community.opscode.com/.

Syntax
=====================================================
All knife subcommands have the following syntax:

   knife subcommand [ARGUMENT] (options)

Each subcommand has its own set of arguments and options.

.. note:: All syntax examples in this document show variables in ALL_CAPS. For example ``-u PORT_LIST`` (where PORT_LIST is a comma-separated list of local and public UDP ports) or ``-F FORMAT`` (where FORMAT determines the output format, either ``summary``, ``text``, ``json``, ``yaml``, or ``pp``). These variables often require specific values that are unique to each organization.

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

Authenticated API Requests
=====================================================
.. tag plugin_knife_summary

A knife plugin is a set of one (or more) subcommands that can be added to knife to support additional functionality that is not built-in to the base set of knife subcommands. Many of the knife plugins are built by members of the Chef community and several of them are built and maintained by Chef. A knife plugin is installed to the ``~/.chef/plugins/knife/`` directory, from where it can be run just like any other knife subcommand.

.. end_tag

.. tag plugin_knife_using_authenticated_requests

A knife plugin can be used to make authenticated API requests to the Chef server using the following methods:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Method
     - Description
   * - ``rest.delete_rest``
     - Use to delete an object from the Chef server.
   * - ``rest.get_rest``
     - Use to get the details of an object on the Chef server.
   * - ``rest.post_rest``
     - Use to add an object to the Chef server.
   * - ``rest.put_rest``
     - Use to update an object on the Chef server.

For example:

.. code-block:: ruby

   module MyCommands
     class MyNodeDelete < Chef::Knife
       #An implementation of knife node delete
       banner 'knife my node delete [NODE_NAME]'

     def run
       if name_args.length < 1
         show_usage
         ui.fatal("You must specify a node name.")
         exit 1
       end
       nodename = name_args[0]
          api_endpoint = "nodes/#{nodename}"
          # Again, we could just call rest.delete_rest
          nodey = rest.get_rest(api_endpoint)
          ui.confirm("Do you really want to delete #{nodey}")
          nodey.destroy
        end
      end
   end

.. end_tag

Configuring a Proxy Server
=====================================================
See the :doc:`proxies </proxies>` documentation for information on how to configure Knife to use a proxy server.
