===========================================================
Deprecation: DNF Package allow_downgrade Property (CHEF-10)
===========================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_dnf_package_allow_downgrade.rst>`__

.. tag deprecations_dnf_package_allow_downgrade

The DNF package provider in the O/S does not require ``--allow-downgrade`` like yum did, and neither does the Chef ``dnf_package`` resource.  This property has no effect on the
``dnf_resource`` property.

.. end_tag

Remediation
===============

Remove the ``allow_downgrade`` property on the ``dnf_package`` resource.

