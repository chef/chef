=====================================================
knife cookbook site
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_cookbook_site.rst>`__

.. tag supermarket_api_summary

The Supermarket API is used to provide access to cookbooks, tools, and users on the Chef Supermarket at |url supermarket_cookbooks|. All of the cookbooks, tools, and users on the Supermarket are accessible through a RESTful API located at |url supermarket_api| by using any of the supported endpoints. In most cases, using knife is the best way to interact with the Supermarket; in some cases, using the Supermarket API directly is necessary.

.. end_tag

.. tag knife_site_cookbook

The ``knife cookbook site`` subcommand is used to interact with cookbooks that are located at |url supermarket|. A user account is required for any community actions that write data to this site. The following arguments do not require a user account: ``download``, ``search``, ``install``, and ``list``.

.. end_tag

.. warning:: .. tag notes_knife_cookbook_site_use_devkit_berkshelf

             Please consider managing community cookbooks using the version of Berkshelf that ships with the Chef development kit. For more information about the Chef development kit, see /about_chefdk.html.

             .. end_tag

.. note:: .. tag knife_common_see_common_options_link

          Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

          .. end_tag

download
=====================================================
Use the ``download`` argument to download a cookbook from the community website. A cookbook will be downloaded as a tar.gz archive and placed in the current working directory. If a cookbook (or cookbook version) has been deprecated and the ``--force`` option is not used, knife will alert the user that the cookbook is deprecated and then will provide the name of the most recent non-deprecated version of that cookbook.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife cookbook site download COOKBOOK_NAME [COOKBOOK_VERSION] (options)

Options
-----------------------------------------------------
This argument has the following options:

``COOKBOOK_VERSION``
   The version of a cookbook to be downloaded. If a cookbook has only one version, this option does not need to be specified. If a cookbook has more than one version and this option is not specified, the most recent version of the cookbook is downloaded.

``-f FILE``, ``--file FILE``
   The file to which a cookbook download is written.

``--force``
   Overwrite an existing directory.

``-m SUPERMARKET_SITE``, ``--supermarket-site SUPERMARKET_SITE``
   The URL at which the Chef Supermarket is located. Default value: https://supermarket.chef.io.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Download a cookbook**

To download the cookbook ``getting-started``, enter:

.. code-block:: bash

   $ knife cookbook site download getting-started

to return something like:

.. code-block:: bash

   Downloading getting-started from the cookbooks site at version 1.2.3 to
     /Users/grantmc/chef-support/getting-started-1.2.3.tar.gz
   Cookbook saved: /Users/grantmc/chef-support/getting-started-1.2.3.tar.gz

install
=====================================================
Use the ``install`` argument to install a cookbook that has been downloaded from the community site to a local git repository . This action uses the git version control system in conjunction with the |url supermarket_cookbooks| site to install community-contributed cookbooks to the local chef-repo. Using this argument does the following:

  #. A new "pristine copy" branch is created in git for tracking the upstream.
  #. All existing versions of a cookbook are removed from the branch.
  #. The cookbook is downloaded from |url supermarket_cookbooks| in the tar.gz format.
  #. The downloaded cookbook is untarred and its contents are committed to git and a tag is created.
  #. The "pristine copy" branch is merged into the master branch.

This process allows the upstream cookbook in the master branch to be modified while letting git maintain changes as a separate patch. When an updated upstream version becomes available, those changes can be merged while maintaining any local modifications.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife cookbook site install COOKBOOK_NAME [COOKBOOK_VERSION] (options)

Options
-----------------------------------------------------
This argument has the following options:

``-b``, ``--use-current-branch``
   Ensure that the current branch is used.

``-B BRANCH``, ``--branch BRANCH``
   The name of the default branch. This defaults to the master branch.

``COOKBOOK_VERSION``
   The version of the cookbook to be installed. If a version is not specified, the most recent version of the cookbook is installed.

``-D``, ``--skip-dependencies``
   Ensure that all cookbooks to which the installed cookbook has a dependency are not installed.

``-m SUPERMARKET_SITE``, ``--supermarket-site SUPERMARKET_SITE``
   The URL at which the Chef Supermarket is located. Default value: https://supermarket.chef.io.

``-o PATH:PATH``, ``--cookbook-path PATH:PATH``
   The directory in which cookbooks are created. This can be a colon-separated path.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Install a cookbook**

To install the cookbook ``getting-started``, enter:

.. code-block:: bash

   $ knife cookbook site install getting-started

to return something like:

.. code-block:: bash

   Installing getting-started to /Users/grantmc/chef-support/.chef/../cookbooks
   Checking out the master branch.
   Creating pristine copy branch chef-vendor-getting-started
   Downloading getting-started from the cookbooks site at version 1.2.3 to
     /Users/grantmc/chef-support/.chef/../cookbooks/getting-started.tar.gz
   Cookbook saved: /Users/grantmc/chef-support/.chef/../cookbooks/getting-started.tar.gz
   Removing pre-existing version.
   Uncompressing getting-started version /Users/grantmc/chef-support/.chef/../cookbooks.
   removing downloaded tarball
   1 files updated, committing changes
   Creating tag cookbook-site-imported-getting-started-1.2.3
   Checking out the master branch.
   Updating 4d44b5b..b4c32f2
   Fast-forward
    cookbooks/getting-started/README.rdoc              |    4 +++
    cookbooks/getting-started/attributes/default.rb    |    1 +
    cookbooks/getting-started/metadata.json            |   29 ++++++++++++++++++++
    cookbooks/getting-started/metadata.rb              |    6 ++++
    cookbooks/getting-started/recipes/default.rb       |   23 +++++++++++++++
    .../templates/default/chef-getting-started.txt.erb |    5 +++
    6 files changed, 68 insertions(+), 0 deletions(-)
    create mode 100644 cookbooks/getting-started/README.rdoc
    create mode 100644 cookbooks/getting-started/attributes/default.rb
    create mode 100644 cookbooks/getting-started/metadata.json
    create mode 100644 cookbooks/getting-started/metadata.rb
    create mode 100644 cookbooks/getting-started/recipes/default.rb
    create mode 100644 cookbooks/getting-started/templates/default/chef-getting-started.txt.erb
   Cookbook getting-started version 1.2.3 successfully installed

list
=====================================================
Use the ``list`` argument to view a list of cookbooks that are currently available at |url supermarket_cookbooks|.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife cookbook site list

Options
-----------------------------------------------------
This argument has the following options:

``-m SUPERMARKET_SITE``, ``--supermarket-site SUPERMARKET_SITE``
   The URL at which the Chef Supermarket is located. Default value: https://supermarket.chef.io.

``-w``, ``--with-uri``
   Show the corresponding URIs.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**View a list of cookbooks**

To view a list of cookbooks at |url supermarket_cookbooks| server, enter:

.. code-block:: bash

   $ knife cookbook site list

to return a list similar to:

.. code-block:: bash

   1password             homesick              rabbitmq
   7-zip                 hostname              rabbitmq-management
   AmazonEC2Tag          hosts                 rabbitmq_chef
   R                     hosts-awareness       rackspaceknife
   accounts              htop                  radiant
   ack-grep              hudson                rails
   activemq              icinga                rails_enterprise
   ad                    id3lib                redis-package
   ad-likewise           iftop                 redis2
   ant                   iis                   redmine
   [...truncated...]

search
=====================================================
Use the ``search`` argument to search for a cookbook at |url supermarket_cookbooks|. A search query is used to return a list of cookbooks at |url supermarket_cookbooks| and uses the same syntax as the ``knife search`` subcommand.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife cookbook site search SEARCH_QUERY (options)

Options
-----------------------------------------------------
This argument has the following options:

``-m SUPERMARKET_SITE``, ``--supermarket-site SUPERMARKET_SITE``
   The URL at which the Chef Supermarket is located. Default value: https://supermarket.chef.io.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Search for cookbooks**

To search for all of the cookbooks that can be used with Apache, enter:

.. code-block:: bash

   $ knife cookbook site search apache*

to return something like:

.. code-block:: bash

   apache2:
     cookbook:              https://supermarket.chef.io/api/v1/cookbooks/apache2
     cookbook_description:  Installs and configures apache2 using Debian symlinks
                            with helper definitions
     cookbook_maintainer:   chef
     cookbook_name:         apache2
   instiki:
     cookbook:              https://supermarket.chef.io/api/v1/cookbooks/instiki
     cookbook_description:  Installs instiki, a Ruby on Rails wiki server under
                            passenger+Apache2.
     cookbook_maintainer:   jtimberman
     cookbook_name:         instiki
   kickstart:
     cookbook:              https://supermarket.chef.io/api/v1/cookbooks/kickstart
     cookbook_description:  Creates apache2 vhost and serves a kickstart file.
     cookbook_maintainer:   chef
     cookbook_name:         kickstart
   [...truncated...]

share
=====================================================
Use the ``share`` argument to add a cookbook to |url supermarket_cookbooks|. This action will require a user account and a certificate for |url supermarket|. By default, knife will use the user name and API key that is identified in the configuration file used during the upload; otherwise these values must be specified on the command line or in an alternate configuration file. If a cookbook already exists on |url supermarket_cookbooks|, then only an owner or maintainer of that cookbook can make updates.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife cookbook site share COOKBOOK_NAME CATEGORY (options)

Options
-----------------------------------------------------
This argument has the following options:

``CATEGORY``
   The cookbook category: ``"Databases"``, ``"Web Servers"``, ``"Process Management"``, ``"Monitoring & Trending"``, ``"Programming Languages"``, ``"Package Management"``, ``"Applications"``, ``"Networking"``, ``"Operating Systems & Virtualization"``, ``"Utilities"``, or ``"Other"``.

``-m SUPERMARKET_SITE``, ``--supermarket-site SUPERMARKET_SITE``
   The URL at which the Chef Supermarket is located. Default value: https://supermarket.chef.io.

``-n``, ``--dry-run``
   Take no action and only print out results. Default: ``false``.

   New in Chef Client 12.0.

``-o PATH:PATH``, ``--cookbook-path PATH:PATH``
   The directory in which cookbooks are created. This can be a colon-separated path.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Share a cookbook**

To share a cookbook named ``apache2``:

.. code-block:: bash

   $ knife cookbook site share "apache2" "Web Servers"

show
=====================================================
Use the ``show`` argument to view information about a cookbook on |url supermarket_cookbooks|.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife cookbook site show COOKBOOK_NAME [COOKBOOK_VERSION]

Options
-----------------------------------------------------
This argument has the following options:

``COOKBOOK_VERSION``
   The version of a cookbook to be shown. If a cookbook has only one version, this option does not need to be specified. If a cookbook has more than one version and this option is not specified, a list of cookbook versions is returned.

``-m SUPERMARKET_SITE``, ``--supermarket-site SUPERMARKET_SITE``
   The URL at which the Chef Supermarket is located. Default value: https://supermarket.chef.io.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Show cookbook data**

To show the details for a cookbook named ``haproxy``:

.. code-block:: bash

   $ knife cookbook site show haproxy

to return something like:

.. code-block:: bash

   average_rating:
   category:        Networking
   created_at:      2009-10-25T23:51:07Z
   description:     Installs and configures haproxy
   external_url:
   latest_version:  https://supermarket.chef.io/api/v1/cookbooks/haproxy/versions/1_0_3
   maintainer:      opscode
   name:            haproxy
   updated_at:      2011-06-30T21:53:25Z
   versions:
     https://supermarket.chef.io/api/v1/cookbooks/haproxy/versions/1_0_3
     https://supermarket.chef.io/api/v1/cookbooks/haproxy/versions/1_0_2
     https://supermarket.chef.io/api/v1/cookbooks/haproxy/versions/1_0_1
     https://supermarket.chef.io/api/v1/cookbooks/haproxy/versions/1_0_0
     https://supermarket.chef.io/api/v1/cookbooks/haproxy/versions/0_8_1
     https://supermarket.chef.io/api/v1/cookbooks/haproxy/versions/0_8_0
     https://supermarket.chef.io/api/v1/cookbooks/haproxy/versions/0_7_0

**Show cookbook data as JSON**

To view information in JSON format, use the ``-F`` common option as part of the command like this:

.. code-block:: bash

   $ knife cookbook site show devops -F json

Other formats available include ``text``, ``yaml``, and ``pp``.

unshare
=====================================================
Use the ``unshare`` argument to stop the sharing of a cookbook at |url supermarket_cookbooks|. Only the maintainer of a cookbook may perform this action.

.. note:: Unsharing a cookbook will break a cookbook that has set a dependency on that cookbook or cookbook version.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife cookbook site unshare COOKBOOK_NAME/versions/VERSION

Options
-----------------------------------------------------
This argument has the following options:

``-m SUPERMARKET_SITE``, ``--supermarket-site SUPERMARKET_SITE``
   The URL at which the Chef Supermarket is located. Default value: https://supermarket.chef.io.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Unshare a cookbook**

To unshare a cookbook named ``getting-started``, enter:

.. code-block:: bash

   $ knife cookbook site unshare "getting-started"

**Unshare a cookbook version**

To unshare cookbook version ``0.10.0`` for the ``getting-started`` cookbook, enter:

.. code-block:: bash

   $ knife cookbook site unshare "getting-started/versions/0.10.0"
