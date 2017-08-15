=======================================================
Deprecation: Old Exit Codes (CHEF-2)
=======================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_exit_code.rst>`__

.. tag deprecations_exit_code

In older versions of Chef, it was not possible to discern why a chef run exited simply by examining the error code.
This makes it very tricky for tools such as Test Kitchen to reason about the status of a Chef client run.
Starting in Chef 12.11, there are now well defined exit codes that the Chef client can use to communicate the status of the run.

.. end_tag

This deprecation was added in Chef 12.11. In Chef 13, only the extended set of exit codes will be supported. For further information on the list of defined error codes,
please see `RFC 62, which defines them <https://github.com/chef/chef-rfc/blob/master/rfc062-exit-status.md>`__.

Remediation
================

If you have built automation that is dependent on the old behaviour of Chef, we strongly recommend updating it to support the extended set of exit codes. However, it's still possible to enable the old behaviour.
Add the setting

.. code-block:: ruby

  exit_status :disabled

to the Chef config file. 
