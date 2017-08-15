=======================================================
Deprecation: Verify File Expansion (CHEF-7)
=======================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_verify_file.rst>`__

.. tag deprecations_verify_file

The ``verify`` metaproperty allows the user to specify a ``{path}`` variable that is expanded to the path of the file to be verified. Previously, it was possible to use ``{file}`` as the variable, but that is now deprecated.

.. end_tag

The ``{file}`` expansion was deprecated in Chef 12.5, and will be removed in Chef 13.

Example
==========

.. code-block:: ruby

  file '/etc/nginx.conf' do
    verify 'nginx -t -c %{file}'
  end

Remediation
==============

Replace ``%{file}`` with ``%{path}``:

.. code-block:: ruby

  file '/etc/nginx.conf' do
    verify 'nginx -t -c %{path}'
  end
