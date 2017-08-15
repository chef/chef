===================================================================
Deprecation: run_command and popen4 helper method removal (OHAI-3)
===================================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_ohai_run_command_helpers.rst>`__

Ohai ships a command mixin for use by plugin authors in shelling out to external commands. This mixin originally included ``run_command`` and ``popen4`` methods, which were deprecated in Ohai 8.11.1 (Chef 12.8.1) in favor of the more robust ``mixlib-shellout`` gem functionality. In Chef 13 these deprecated methods will be removed, breaking any Ohai plugins authored using the deprecated methods.

Remediation
=============

Plugins should be updated to use mixlib-shellout instead of the run_command.

Deprecated run_command based code:

.. code-block:: ruby

  status, stdout, stderr = run_command(:command => "myapp --version")
  if status == 0
    version = stdout
  end

Updated code for mixlib shellout:

.. code-block:: ruby

  so = shell_out("myapp --version")
  if so.exitstatus == 0
    version = so.stdout
  end


See the `mixlib-shellout repo <https://github.com/chef/mixlib-shellout>`__ for additional usage information.
