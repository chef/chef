=====================================================
Deprecation: Deprecation of run_command (CHEF-14)
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_run_command.rst>`__

.. tag deprecations_run_command

The old run_command API has been replaced by shell_out (a wrapper around Mixlib::ShellOut).

.. end_tag

This deprecation warning was added in Chef 12.18.31, and run_command will be removed permanantly in Chef 13.

Example
=====================================================

Previously to run a command from chef-client code you might have written:

.. code-block:: ruby

  run_command(:command => "/sbin/ifconfig eth0")

Remediation
=====================================================

You now need to use shell_out! instead:

.. code-block:: ruby

  shell_out!("/sbin/ifconfig eth0")
