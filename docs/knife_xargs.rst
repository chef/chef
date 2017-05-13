=====================================================
knife xargs
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/knife_xargs.rst>`__

.. tag knife_xargs_summary

Use the ``knife xargs`` subcommand to take patterns from standard input, download as JSON, run a command against the downloaded JSON, and then upload any changes.

.. end_tag

Syntax
=====================================================
This subcommand has the following syntax:

.. code-block:: bash

   $ knife xargs [PATTERN...] (options)

Options
=====================================================
.. note:: .. tag knife_common_see_common_options_link

          Review the list of :doc:`common options </knife_common_options>` available to this (and all) knife subcommands and plugins.

          .. end_tag

This subcommand has the following options:

``-0``
   |use null_character| Default: ``false``.

``--chef-repo-path PATH``
   The path to the chef-repo. This setting will override the default path to the chef-repo. Default: same value as specified by ``chef_repo_path`` in client.rb.

``--concurrency``
   The number of allowed concurrent connections. Default: ``10``.

``--[no-]diff``
   Show a diff when a file changes. Default: ``--diff``.

``--dry-run``
   Prevent changes from being uploaded to the Chef server. Default: ``false``.

   New in Chef Client 12.0.

``--[no-]force``
   Force the upload of files even if they haven't been changed. Default: ``--no-force``.

``-I REPLACE_STRING``, ``--replace REPLACE_STRING``
   Define a string that is to be used to replace all occurrences of a file name. Default: ``nil``.

``-J REPLACE_STRING``, ``--replace-first REPLACE_STRING``
   Define a string that is to be used to replace the first occurrence of a file name. Default: ``nil``.

``--local``
   Build or execute a command line against a local file. Set to ``false`` to build or execute against a remote file. Default: ``false``.

``-n MAX_ARGS``, ``--max-args MAX_ARGS``
   The maximum number of arguments per command line. Default: ``nil``.

``-p [PATTERN...]``, ``--pattern [PATTERN...]``
   One (or more) patterns for a command line. If this option is not specified, a list of patterns may be expected on standard input. Default: ``nil``.

``--repo-mode MODE``
   The layout of the local chef-repo. Possible values: ``static``, ``everything``, or ``hosted_everything``. Use ``static`` for just roles, environments, cookbooks, and data bags. By default, ``everything`` and ``hosted_everything`` are dynamically selected depending on the server type. Default value: ``default``.

``-s LENGTH``, ``--max-chars LENGTH``
   The maximum size (in characters) for a command line. Default: ``nil``.

``-t``
   Run the print command on the command line. Default: ``nil``.

.. note:: .. tag knife_common_see_all_config_options

          See :doc:`knife.rb </config_rb_knife_optional_settings>` for more information about how to add certain knife options as settings in the knife.rb file.

          .. end_tag

Examples
=====================================================
The following examples show how to use this knife subcommand:

**Find, and then replace data**

The following example will go through all nodes on the server, and then replace the word ``foobar`` with ``baz``:

.. code-block:: bash

   $ knife xargs --pattern /nodes/* "perl -i -pe 's/foobar/baz'"

**Use output of knife list and Perl**

The following examples show various ways of listing all nodes on the server, and then using Perl to replace ``grantmc`` with ``gmc``:

.. code-block:: bash

   $ knife list 'nodes/*' | knife xargs "perl -i -pe 's/grantmc/gmc'"

or without quotes and the backslash escaped:

.. code-block:: bash

   $ knife list /nodes/\* | knife xargs "perl -i -pe 's/grantmc/gmc'"

or by using the ``--pattern`` option:

.. code-block:: bash

   $ knife xargs --pattern '/nodes.*' "perl -i -pe 's/grantmc/gmc'"

**View security groups data**

The following example shows how to display the content of all groups on the server:

.. code-block:: bash

   $ knife xargs --pattern '/groups/*' cat

and will return something like:

.. code-block:: javascript

   {
     "name": "4bd14db60aasdfb10f525400cdde21",
     "users": [
       "grantmc"
     ]
   }{
     "name": "62c4e268e15fasdasc525400cd944b",
     "users": [
       "robertf"
     ]
   }{
     "name": "admins",
     "users": [
       "grantmc",
       "robertf"
     ]
   }{
     "name": "billing-admins",
     "users": [
       "dtek"
     ]
   }{
     "name": "clients",
     "clients": [
       "12345",
       "67890",
     ]
   }{
     "name": "users",
     "users": [
       "grantmc"
       "robertf"
       "dtek"
     ],
     "groups": [
       "4bd14db60aasdfb10f525400cdde21",
       "62c4e268e15fasdasc525400cd944b"
     ]
   }
