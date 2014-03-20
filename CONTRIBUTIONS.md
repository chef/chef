<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Contribution:
* **kalistec**: Improved file resource greatly.
-->
# Chef Client Contributions:

* **jonlives**: Changed the order of recipe and cookbook name setting. Fixes CHEF-5052.
* **jaymzh**: Added support for `enable` and `disable` to MacOSX service provider.
* **bossmc**: Made formatters more resilient to nil exception messages.
* **valodzka**: Fixed the convergence message in deploy provider.
* **linkfanel**: Made attribute arrays able to handle non-dupable elements while being duped.
* **linkfanel**: Removed ruby-shadow installation on cygwin platform.
* **lbragstad**: Add IBM PowerKVM to platform map.
* **slantview**: Allow boolean and numerics in cookbook metadata.
* **jeffmendoza**: Made knife to use cloud attribute for port when available.
* **ryotarai**: Added a method to capture IO for live stream.
* **sawanoboly**: Fixed service provider to be aware of maintenance state on Solaris.
* **cbandy**: Refactored Chef::Util::FileEdit.
* **cbandy**: Fixed insert_line_if_no_match to run multiple times.
* **pavelbrylov**: Modified subversion resource to hide password from error messages.
* **eherot**: Add support for epoch versions to the dpkg package provider.
* **jdmurphy**: Display all missing dependencies when uploading cookbooks.
* **nkrinner**: Add a public file_edited? method to Chef::Util::FileEdit.
* **ccope**: Made package provider to use IPS provider in Solaris 5.11+
* **josephholsten**: Changed Chef::REST to be able to handle frozen options.
* **andreasrs**: Changed service provider to use Systemd on ArchLinux.
* **eherot**: Add support for epoch versions to the dpkg package provider
* **jdmurphy**: Display all missing dependencies when uploading cookbooks
* **nkrinner**: Add a public file_edited? method to Chef::Util::FileEdit
* **jjasghar**: Output correct host name in knife ssh error message
