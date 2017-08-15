===========================================================
Deprecation: Windows CPU plugin attribute changes. (OHAI-5)
===========================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/deprecations_ohai_windows_cpu.rst>`__

The Windows Ohai plugin has been updated to correctly return CPU information. Previously the CPU plugin reported a ``model_name`` value, which was actually the CPU's description and not the actual model name. Ohai now reports the proper name value for ``model_name`` and provides ``description`` with the previous description value. This behavior aligns CPU plugin behavior between \*nix and Windows hosts in Chef.

Remediation
=============

If you rely on the format of a CPU model_name value such as ``node['cpu'['0']['model_name']`` you will need to update your cookbook code to reference ``node['cpu']['0']['description']`` instead.
