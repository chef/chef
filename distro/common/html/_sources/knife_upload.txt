=====================================================
knife upload
=====================================================

.. include:: ../../includes_knife/includes_knife_upload.rst

Syntax
=====================================================
.. include:: ../../includes_knife/includes_knife_upload_syntax.rst

Options
=====================================================
.. note:: Review the list of :doc:`common options </knife_common_options>` available to this (and all) |knife| subcommands and plugins.

.. include:: ../../includes_knife/includes_knife_upload_options.rst

knife.rb Settings
-----------------------------------------------------
.. note:: See :doc:`knife.rb </config_rb_knife>` for more information about how to add optional settings to the |knife rb| file.

.. include:: ../../includes_knife/includes_knife_upload_settings.rst

Examples
=====================================================
The following examples show how to use this |knife| subcommand:

**Upload the entire chef-repo**

.. include:: ../../step_knife/step_knife_upload_repository.rst

**Upload the /cookbooks directory**

.. include:: ../../step_knife/step_knife_upload_directory_cookbooks.rst

**Upload the /environments directory**

.. include:: ../../step_knife/step_knife_upload_directory_environments.rst

**Upload a single environment**

.. include:: ../../step_knife/step_knife_upload_directory_environment.rst

**Upload the /roles directory**

.. include:: ../../step_knife/step_knife_upload_directory_roles.rst

**Upload cookbooks and roles**

.. include:: ../../step_knife/step_knife_upload_directory_cookbooks_and_role.rst

**Use output of knife deps to pass command to knife upload**

.. include:: ../../step_knife/step_knife_upload_pass_to_knife_deps.rst


