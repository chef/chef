=====================================================
knife supermarket
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/plugin_knife_supermarket.rst>`__

.. warning:: Only use knife supermarket if you are using a Chef 12.12 or earlier. If you are using Chef 12.13 or later, you should use the :doc:`knife cookbook site </knife_cookbook_site>` commands.

.. tag supermarket_api_summary

The Supermarket API is used to provide access to cookbooks, tools, and users on the Chef Supermarket at |url supermarket_cookbooks|. All of the cookbooks, tools, and users on the Supermarket are accessible through a RESTful API located at |url supermarket_api| by using any of the supported endpoints. In most cases, using knife is the best way to interact with the Supermarket; in some cases, using the Supermarket API directly is necessary.

.. end_tag

The ``knife supermarket`` subcommand is used to interact with cookbooks that are located in private Chef Supermarket configured inside the firewall. A user account is required for any community actions that write data to the Chef Supermarket; however, the following arguments do not require a user account: ``download``, ``search``, ``install``, and ``list``.

.. note:: If you are interested in uploading to the supermarket as a company you might be interested
          in looking at the `Chef Partner Cookbook Program <https://www.chef.io/partners/cookbooks/>`__
          which can help validate and verify your company cookbook. A selection of Certified Partner Cookbooks can
          be found `here <https://supermarket.chef.io/cookbooks?utf8=✓&q=&badges%5B%5D=partner&platforms%5B%5D=>`__.

.. note:: .. tag notes_knife_cookbook_site_use_devkit_berkshelf

          Please consider managing community cookbooks using the version of Berkshelf that ships with the Chef development kit. For more information about the Chef development kit, see /about_chefdk.html.

          .. end_tag

.. note:: Review the list of `common options </knife_common_options>`_ available to this (and all) knife subcommands and plugins.

download
=====================================================
Use the ``download`` argument to download a cookbook from Chef Supermarket. A cookbook will be downloaded as a tar.gz archive and placed in the current working directory. If a cookbook (or cookbook version) has been deprecated and the ``--force`` option is not used, knife will alert the user that the cookbook is deprecated and then will provide the name of the most recent non-deprecated version of that cookbook.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife supermarket download COOKBOOK_NAME [COOKBOOK_VERSION] (options)

Options
-----------------------------------------------------
This argument has the following options:

``COOKBOOK_VERSION``
   The version of a cookbook to be downloaded. If a cookbook has only one version, this option does not need to be specified. If a cookbook has more than one version and this option is not specified, the most recent version of the cookbook is downloaded.

``-f FILE``, ``--file FILE``
   The file to which a cookbook download is written.

``--force``
   Overwrite an existing directory.

``-m``, ``--supermarket-site``
   The URL at which the Chef Supermarket is located. Default value: ``https://supermarket.chef.io``.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Download a cookbook**

To download the cookbook ``mysql``, enter:

.. code-block:: bash

   $ knife supermarket download mysql

install
=====================================================
Use the ``install`` argument to install a cookbook that has been downloaded from Chef Supermarket to a local git repository . This action uses the git version control system in conjunction with Chef Supermarket site to install community-contributed cookbooks to the local chef-repo. Using this argument does the following:

  #. A new "pristine copy" branch is created in git for tracking the upstream.
  #. All existing versions of a cookbook are removed from the branch.
  #. The cookbook is downloaded from Chef Supermarket in the tar.gz format.
  #. The downloaded cookbook is untarred and its contents are committed to git and a tag is created.
  #. The "pristine copy" branch is merged into the master branch.

This process allows the upstream cookbook in the master branch to be modified while letting git maintain changes as a separate patch. When an updated upstream version becomes available, those changes can be merged while maintaining any local modifications.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife supermarket install COOKBOOK_NAME [COOKBOOK_VERSION] (options)

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

``-m``, ``--supermarket-site``
   The URL at which the Chef Supermarket is located. Default value: ``https://supermarket.chef.io``.

``-o PATH:PATH``, ``--cookbook-path PATH:PATH``
   The directory in which cookbooks are created. This can be a colon-separated path.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Install a cookbook**

To install the cookbook ``mysql``, enter:

.. code-block:: bash

   $ knife supermarket install mysql

list
=====================================================
Use the ``list`` argument to view a list of cookbooks that are currently available at Chef Supermarket.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife supermarket list (options)

Options
-----------------------------------------------------
This argument has the following options:

``-m``, ``--supermarket-site``
   The URL at which the Chef Supermarket is located. Default value: ``https://supermarket.chef.io``.

``-w``, ``--with-uri``
   Show the corresponding URIs.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**View a list of cookbooks**

To view a list of cookbooks at |url supermarket_cookbooks| server, enter:

.. code-block:: bash

   $ knife supermarket list

to return a list similar to:

.. code-block:: bash

   1password                            minecraft
   301                                  mineos
   7-zip                                minidlna
   AWS_see_spots_run                    minitest
   AmazonEC2Tag                         minitest-handler
   Appfirst-Cookbook                    mirage
   CVE-2014-3566-poodle                 mlocate
   CVE-2015-0235                        mod_security
   Obfsproxy                            mod_security2
   R                                    modcloth-hubot
   Rstats                               modcloth-nad
   SysinternalsBginfo                   modman
   VRTSralus                            modules
   abiquo                               mogilefs
   acadock                              mongodb
   accel-ppp                            mongodb-10gen
   accounts                             mongodb-agents
   accumulator                          monit
   ...

search
=====================================================
Use the ``search`` argument to search for a cookbooks located at Chef Supermarket. A search query is used to return a list of these cookbooks and uses the same syntax as the ``knife search`` subcommand.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife supermarket search SEARCH_QUERY (options)

Options
-----------------------------------------------------
This argument has the following options:

``-m``, ``--supermarket-site``
   The URL at which the Chef Supermarket is located. Default value: ``https://supermarket.chef.io``.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Search for cookbooks**

To search for a cookbook, use a command similar to:

.. code-block:: bash

   $ knife supermarket search mysql

where ``mysql`` is the search term. This will return something similar to:

   mysql:
     cookbook:             http://cookbooks.opscode.com/api/v1/cookbooks/mysql
     cookbook_description: Provides mysql_service, mysql_config, and mysql_client resources
     cookbook_maintainer:  chef
     cookbook_name:        mysql
   mysql-apt-config:
     cookbook:             http://cookbooks.opscode.com/api/v1/cookbooks/mysql-apt-config
     cookbook_description: Installs/Configures mysql-apt-config
     cookbook_maintainer:  tata
     cookbook_name:        mysql-apt-config
   mysql-multi:
     cookbook:             http://cookbooks.opscode.com/api/v1/cookbooks/mysql-multi
     cookbook_description: MySQL replication wrapper cookbook
     cookbook_maintainer:  rackops
     cookbook_name:        mysql-multi

share
=====================================================
Use the ``share`` argument to add a cookbook to Chef Supermarket. This action will require a user account and a certificate for |url supermarket|. By default, knife will use the user name and API key that is identified in the configuration file used during the upload; otherwise these values must be specified on the command line or in an alternate configuration file. If a cookbook already exists in Chef Supermarket, then only an owner or maintainer of that cookbook can make updates.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife supermarket share COOKBOOK_NAME CATEGORY (options)

Options
-----------------------------------------------------
This argument has the following options:

``CATEGORY``
   The cookbook category: ``"Databases"``, ``"Web Servers"``, ``"Process Management"``, ``"Monitoring & Trending"``, ``"Programming Languages"``, ``"Package Management"``, ``"Applications"``, ``"Networking"``, ``"Operating Systems & Virtualization"``, ``"Utilities"``, or ``"Other"``.

``-m``, ``--supermarket-site``
   The URL at which the Chef Supermarket is located. Default value: ``https://supermarket.chef.io``.

``-o PATH:PATH``, ``--cookbook-path PATH:PATH``
   The directory in which cookbooks are created. This can be a colon-separated path.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Share a cookbook**

To share a cookbook named ``my_apache2_cookbook`` and add it to the ``Web Servers`` category in Chef Supermarket:

.. code-block:: bash

   $ knife supermarket share "my_apache2_cookbook" "Web Servers"

show
=====================================================
Use the ``show`` argument to view information about a cookbook located at Chef Supermarket.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife supermarket show COOKBOOK_NAME [COOKBOOK_VERSION] (options)

Options
-----------------------------------------------------
This argument has the following options:

``COOKBOOK_VERSION``
   The version of a cookbook to be shown. If a cookbook has only one version, this option does not need to be specified. If a cookbook has more than one version and this option is not specified, a list of cookbook versions is returned.

``-m``, ``--supermarket-site``
   The URL at which the Chef Supermarket is located. Default value: ``https://supermarket.chef.io``.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Show cookbook data**

To show the details for a cookbook named ``mysql``:

.. code-block:: bash

   $ knife supermarket show mysql

to return something similar to:

.. code-block:: bash

   average_rating:
   category:           Other
   created_at:         2009-10-28T19:16:54.000Z
   deprecated:         false
   description:        Provides mysql_service, mysql_config, and mysql_client resources
   external_url:       https://github.com/chef-cookbooks/mysql
   foodcritic_failure: true
   issues_url:
   latest_version:     http://cookbooks.opscode.com/api/v1/cookbooks/mysql/versions/6.0.15
   maintainer:         chef
   metrics:
     downloads:
       total:    79275449
     versions:
       0.10.0: 927561
       0.15.0: 927536
       0.20.0: 927321
       0.21.0: 927298
       0.21.1: 927311
       0.21.2: 927424
       0.21.3: 927441
       0.21.5: 927326
       0.22.0: 927297
       0.23.0: 927353
       0.23.1: 927862
       0.24.0: 927316

**Show cookbook version data**

To show the details for a cookbook version, run a command similar to:

.. code-block:: bash

   $ knife supermarket show mysql 0.10.0

where ``mysql`` is the cookbook and ``0.10.0`` is the cookbook version. This will return something similar to:

.. code-block:: bash

   average_rating:
   cookbook:          http://cookbooks.opscode.com/api/v1/cookbooks/mysql
   file:              http://cookbooks.opscode.com/api/v1/cookbooks/mysql/versions/0.10.0/download
   license:           Apache 2.0
   tarball_file_size: 7010
   version:           0.10.0

unshare
=====================================================
Use the ``unshare`` argument to stop the sharing of a cookbook located at Chef Supermarket. Only the maintainer of a cookbook may perform this action.

.. note:: Unsharing a cookbook will break a cookbook that has set a dependency on that cookbook or cookbook version.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife supermarket unshare COOKBOOK_NAME/versions/VERSION (options)

Options
-----------------------------------------------------
This argument has the following options:

``-m``, ``--supermarket-site``
   The URL at which the Chef Supermarket is located. Default value: ``https://supermarket.chef.io``.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Unshare a cookbook**

To unshare a cookbook named ``my_apache2_cookbook``, enter:

.. code-block:: bash

   $ knife supermarket unshare "my_apache2_cookbook" "Web Servers"

**Unshare a cookbook version**

To unshare cookbook version ``0.10.0`` for the ``my_apache2_cookbook`` cookbook, enter:

.. code-block:: bash

   $ knife supermarket unshare "my_apache2_cookbook/versions/0.10.0"
