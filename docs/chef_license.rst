=====================================================
About Chef Licenses
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/chef_license.rst>`__

.. tag chef_license_summary

All Chef products have a license that governs the entire product and includes links to license files for any third-party software included in Chef packages. The ``/opt/<PRODUCT-NAME>/LICENSES`` directory contains individual copies of all referenced licenses.

.. end_tag

Apache 2.0
=====================================================
.. tag chef_license_apache

.. no swaps used for the "such as ..." section to ensure the correct legal name and not the names for these products as otherwise used globally in the documentation.

All open source Chef products---such as the Chef client, the Chef server, or InSpec---are governed by the Apache 2.0 license.

.. end_tag

Chef MLSA
=====================================================
.. no swaps used for the "such as ..." section to ensure the correct legal name and not the names for these products as otherwise used globally in the documentation.

Proprietary Chef products---such as Chef Automate and the Chef Management Console---are governed by the Chef Master License and Services Agreement (Chef MLSA), which must be accepted as part of any install or upgrade process.

Accept the Chef MLSA
-----------------------------------------------------
There are three ways to accept the Chef MLSA:

#. When running ``chef-<PRODUCT-NAME>-ctl reconfigure`` the Chef MLSA is printed. Type ``yes`` to accept it. Anything other than typing ``yes`` rejects the Chef MLSA and the upgrade process will exit. Typing ``yes`` adds a ``.license.accepted`` file to the ``/var/opt/<PRODUCT-NAME>/`` directory. As long as this file exists in this directory, the Chef MLSA is accepted and the reconfigure process will not prompt for ``yes``.

#. Run the ``chef-<PRODUCT-NAME>-ctl reconfigure`` command using the ``--accept-license`` option. This automatically types ``yes`` and skips printing the Chef MLSA.

#. Add a ``.license.accepted`` file to the ``/var/opt/<PRODUCT-NAME>/`` directory. The contents of this file do not matter. As long as this file exists in this directory, the Chef MLSA is accepted and the reconfigure process will not prompt for ``yes``.
