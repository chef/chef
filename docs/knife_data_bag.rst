=====================================================
knife data bag
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_data_bag.rst>`__

.. tag data_bag

A data bag is a global variable that is stored as JSON data and is accessible from a Chef server. A data bag is indexed for searching and can be loaded by a recipe or accessed during a search.

.. end_tag

.. tag data_bag_encryption

A data bag item may be encrypted using `shared secret encryption <https://en.wikipedia.org/wiki/Symmetric-key_algorithm>`_. This allows each data bag item to store confidential information (such as a database password) or to be managed in a source control system (without plain-text data appearing in revision history). Each data bag item may be encrypted individually; if a data bag contains multiple encrypted data bag items, these data bag items are not required to share the same encryption keys.

.. note:: Because the contents of encrypted data bag items are not visible to the chef-server, search queries against data bags with encrypted items will not return any results.

.. end_tag

.. tag knife_data_bag_summary

The ``knife data bag`` subcommand is used to manage arbitrary stores of globally available JSON data.

.. end_tag

.. note:: .. tag knife_common_see_common_options_link

          Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

          .. end_tag

create
=====================================================
Use the ``create`` argument to add a data bag to the Chef server.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife data bag create DATA_BAG_NAME [DATA_BAG_ITEM] (options)

Options
-----------------------------------------------------
This argument has the following options:

``DATA_BAG_ITEM``
   The name of a specific item within a data bag.

``--secret SECRET``
   The encryption key that is used for values contained within a data bag item. If ``secret`` is not specified, the chef-client looks for a secret at the path specified by the ``encrypted_data_bag_secret`` setting in the client.rb file.

``--secret-file FILE``
   The path to the file that contains the encryption key.

.. note:: For encrypted data bag items, use *either* ``--secret`` or ``--secret-file``, not both.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Create a data bag**

To create a data bag named "admins", enter:

.. code-block:: bash

   $ knife data bag create admins

to return:

.. code-block:: none

   Created data_bag[admins]

delete
=====================================================
Use the ``delete`` argument to delete a data bag or a data bag item from a Chef server.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife data bag delete DATA_BAG_NAME [DATA_BAG_ITEM] (options)

Options
-----------------------------------------------------
This argument has the following options:

``DATA_BAG_ITEM``
   The name of a specific item within a data bag.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Delete a data bag**

.. To a data bag named "admins", enter:

.. code-block:: bash

   $ knife data bag delete data_bag_name

**Delete a data bag item**

To delete an item named "charlie", enter:

.. code-block:: bash

   $ knife data bag delete admins charlie

Type ``Y`` to confirm a deletion.

edit
=====================================================
.. tag knife_data_bag_edit

Use the ``edit`` argument to edit the data contained in a data bag. If encryption is being used, the data bag will be decrypted, the data will be made available in the $EDITOR, and then encrypted again before saving it to the Chef server.

.. end_tag

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife data bag edit DATA_BAG_NAME [DATA_BAG_ITEM] (options)

Options
-----------------------------------------------------
This argument has the following options:

``DATA_BAG_ITEM``
   The name of a specific item within a data bag.

``--secret SECRET``
   The encryption key that is used for values contained within a data bag item. If ``secret`` is not specified, the chef-client looks for a secret at the path specified by the ``encrypted_data_bag_secret`` setting in the client.rb file.

``--secret-file FILE``
   The path to the file that contains the encryption key.

.. note::  For encrypted data bag items, use *either* ``--secret`` or ``--secret-file``, not both.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Edit a data bag**

To edit the contents of a data bag, enter:

.. code-block:: bash

   $ knife data bag edit dogs tibetanspaniel

where ``dogs`` is the name of the data bag and ``tibetanspaniel`` is the name of the data bag item. This will return something similar to the following in the knife editor:

.. code-block:: javascript

   {
     "name":"data_bag_item_dogs_tibetanspaniel",
     "json_class":"Chef::DataBagItem",
     "chef_type":"data_bag_item",
     "data_bag":"dogs",
     "raw_data":
       {
         "description":"small dog that likes to sit in windows",
         "id":"tibetanspaniel"
       }
   }

Make the necessary changes to the key-value pairs under ``raw_data`` and save them.

**Edit a data bag item**

.. tag knife_data_bag_edit_item

To edit an item named "charlie" that is contained in a data bag named "admins", enter:

.. code-block:: bash

   $ knife data bag edit admins charlie

to open the $EDITOR. Once opened, you can update the data before saving it to the Chef server. For example, by changing:

.. code-block:: javascript

   {
      "id": "charlie"
   }

to:

.. code-block:: javascript

   {
      "id": "charlie",
      "uid": 1005,
      "gid": "ops",
      "shell": "/bin/zsh",
      "comment": "Crazy Charlie"
   }

.. end_tag

from file
=====================================================
Use the ``from file`` argument to:

* Add a data bag item to a data bag
* Update the contents of an existing data bag item

The data bag itself must already exist on the Chef server and must be specified as part of the command. The contents of the data bag item are specified using a JSON file. This JSON file may be located at a relative or absolute path; its location must be specified as part of the command. The JSON file that defines the contents of the data bag item must at least contain the name of the data bag item---``"id": "name"``.

.. warning:: A chef-client must be version 11.6 (or higher) when using the ``knife data bag from file`` argument with the Enterprise Chef or Open Source Chef version 11 servers.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife data bag from file DATA_BAG_NAME_or_PATH JSON_FILE

Options
-----------------------------------------------------
This argument has the following options:

``-a``, ``--all``
   Upload all data bags found at the specified path.

``--secret SECRET``
   The encryption key that is used for values contained within a data bag item. If ``secret`` is not specified, the chef-client looks for a secret at the path specified by the ``encrypted_data_bag_secret`` setting in the client.rb file.

``--secret-file FILE``
   The path to the file that contains the encryption key.

.. note::  For encrypted data bag items, use *either* ``--secret`` or ``--secret-file``, not both.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Create a data bag from a file**

To create a data bag on the Chef server from a file:

.. code-block:: bash

   $ knife data bag from file "path to JSON file"

**Create an encrypted data bag from a file**

To create a data bag named "devops_data" that contains encrypted data, enter:

.. code-block:: bash

   $ knife data bag from file devops_data --secret-file "path to decryption file"

**Create an encrypted data bag for use with chef-client local mode**

.. tag knife_data_bag_from_file_create_encrypted_local_mode

To generate an encrypted data bag item in a JSON file for use when the chef-client is run in local mode (via the ``--local-mode`` option), enter:

.. code-block:: bash

   $ knife data bag from file my_data_bag /path/to/data_bag_item.json -z --secret-file /path/to/encrypted_data_bag_secret

this will create an encrypted JSON file in::

   data_bags/my_data_bag/data_bag_item.json

.. end_tag

list
=====================================================
Use the ``list`` argument to view a list of data bags that are currently available on the Chef server.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife data bag list

Options
-----------------------------------------------------
This argument has the following options:

``-w``, ``--with-uri``
   Show the corresponding URIs.

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**View a list of data bags**

.. To view a list of data bags on the Chef server, enter:

.. code-block:: bash

   $ knife data bag list

show
=====================================================
Use the ``show`` argument to view the contents of a data bag.

Syntax
-----------------------------------------------------
This argument has the following syntax:

.. code-block:: bash

   $ knife data bag show DATA_BAG_NAME (options)

Options
-----------------------------------------------------
This argument has the following options:

``DATA_BAG_ITEM``
   The name of a specific item within a data bag.

``--secret SECRET``
   The encryption key that is used for values contained within a data bag item. If ``secret`` is not specified, the chef-client looks for a secret at the path specified by the ``encrypted_data_bag_secret`` setting in the client.rb file.

``--secret-file FILE``
   The path to the file that contains the encryption key.

.. note::  For encrypted data bag items, use *either* ``--secret`` or ``--secret-file``, not both.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
-----------------------------------------------------
The following examples show how to use this knife subcommand:

**Show a data bag**

.. To show the contents of a data bag, enter:

.. code-block:: bash

   $ knife data bag show admins

to return something like:

.. code-block:: none

   charlie

**Show a data bag item**

To show the contents of a specific item within data bag, enter:

.. code-block:: bash

   $ knife data bag show admins charlie

to return:

.. code-block:: none

   comment:  Crazy Charlie
   gid:      ops
   id:       charlie
   shell:    /bin/zsh
   uid:      1005

**Show a data bag, encrypted**

To show the contents of a data bag named ``passwords`` with an item that contains encrypted data named ``mysql``, enter:

.. code-block:: bash

   $ knife data bag show passwords mysql

to return:

.. code-block:: javascript

   {
     "id": "mysql",
     "pass": "trywgFA6R70NO28PNhMpGhEvKBZuxouemnbnAUQsUyo=\n",
     "user": "e/p+8WJYVHY9fHcEgAAReg==\n"
   }

**Show a data bag, decrypted**

To show the decrypted contents of the same data bag, enter:

.. code-block:: bash

   $ knife data bag show --secret-file /path/to/decryption/file passwords mysql

to return:

.. code-block:: javascript

   {
     "id": "mysql",
     "pass": "thesecret123",
     "user": "fred"
   }

**Show a data bag as JSON**

To view information in JSON format, use the ``-F`` common option as part of the command like this:

.. code-block:: bash

   $ knife data bag show admins -F json

Other formats available include ``text``, ``yaml``, and ``pp``.

