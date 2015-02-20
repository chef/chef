=====================================================
knife bootstrap 
=====================================================

.. include:: ../../includes_chef/includes_chef_bootstrap.rst

.. include:: ../../includes_knife/includes_knife_bootstrap.rst

.. note:: To bootstrap the |chef client| on |windows| machines, the `knife-windows <http://docs.opscode.com/plugin_knife_windows.html>`_ plugins is required, which includes the necessary bootstrap scripts that are used to do the actual installation.

Syntax
=====================================================
.. include:: ../../includes_knife/includes_knife_bootstrap_syntax.rst

Options
=====================================================
.. note:: Review the list of :doc:`common options </knife_common_options>` available to this (and all) |knife| subcommands and plugins.

.. include:: ../../release_chef_12-0/includes_knife_bootstrap_options.rst

Custom Templates
=====================================================
The ``chef-full`` distribution uses the |omnibus installer|. For most bootstrap operations, regardless of the platform on which the target node is running, using the ``chef-full`` distribution is the best approach for installing the |chef client| on a target node. In some situations, using another supported distribution is necessary. And in some situations, a custom template may be required. For example, the default bootstrap operation relies on an Internet connection to get the distribution to the target node. If a target node cannot access the Internet, then a custom template can be used to define a specific location for the distribution so that the target node may access it during the bootstrap operation.

A custom bootstrap template file (``template_filename.erb``) must be located in a ``bootstrap/`` directory. Use the ``--distro`` option with the ``knife bootstrap`` subcommand to specify the bootstrap template file. For example, a bootstrap template file named "british_sea_power.erb":

.. code-block:: bash

   $ knife bootstrap 123.456.7.8 -x username -P password --sudo --distro "british_sea_power.erb"

The following examples show how a bootstrap template file can be customized for various platforms.

Ubuntu 12.04
-----------------------------------------------------
.. include:: ../../includes_knife/includes_knife_bootstrap_example_ubuntu.rst

Debian and Apt
-----------------------------------------------------
.. include:: ../../includes_knife/includes_knife_bootstrap_example_debian.rst

Microsoft Windows
-----------------------------------------------------
.. include:: ../../includes_knife/includes_knife_bootstrap_example_windows.rst

Examples
=====================================================
The following examples show how to use this |knife| subcommand:

**Use an SSH password**

.. include:: ../../step_knife/step_knife_bootstrap_use_ssh_password.rst

**Use a file that contains a private key**

.. include:: ../../step_knife/step_knife_bootstrap_use_file_with_private_key.rst

