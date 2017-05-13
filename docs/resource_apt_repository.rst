==========================================
apt_repository
==========================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_apt_repository.rst>`__

Use the **apt_repository** resource to additional APT repositories. Adding a new repository will update apt package cache immediately.

*New in Chef Client 12.9.*

Syntax
==========================================
An **apt_repository** resource specifies APT repository information and adds an additional APT repository to the existing list of repositories:

.. code-block:: ruby

   apt_repository 'zenoss' do
     uri        'http://dev.zenoss.org/deb'
     components ['main', 'stable']
   end

where

* ``apt_repository`` is the resource
* ``name`` is the name of the resource block
* ``uri`` is a base URI for the distribution where the apt packages are located at
* ``components`` is an array of package groupings in the repository

The full syntax for all of the properties that are available to the **apt_repository** resource is:

.. code-block:: ruby

   apt_repository 'name' do
      repo_name             String
      uri                   String
      distribution          String
      components            Array
      arch                  String
      trusted               TrueClass, FalseClass
      deb_src               TrueClass, FalseClass
      keyserver             String
      key                   String
      key_proxy             String
      cookbook              String
      cache_rebuild         TrueClass, FalseClass
      sensitive             TrueClass, FalseClass
   end

where

* ``apt_repository`` is the resource
* ``name`` is the name of the resource block
* ``repo_name``, ``uri``, ``distribution``, ``components``, ``arch``, ``trusted``, ``deb_src``, ``keyserver``, ``key``, ``key_proxy``, ``cookbook``, ``cache_rebuild``, and ``sensitive`` are properties of this resource, with the Ruby type shown. See “Properties” section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

:add
   Default. Creates a repository file at ``/etc/apt/sources.list.d/`` and builds the repository listing.

:remove
   Removes the repository listing.

Properties
=====================================================
This resource has the following properties:

repo_name
   **Ruby Type:** String

   The name of the channel to discover.

uri
   **Ruby Type:** String

   The base of the Debian distribution.

distribution
   **Ruby Type:** String

   Usually a codename, such as something like karmic, lucid or maverick.

components
   **Ruby Type:** Array

   Package groupings, such as 'main' and 'stable'. Default value: empty array.

arch
   **Ruby Type:** String

   Constrain packages to a particular CPU architecture such as ``'i386'`` or ``'amd64'``. Default value: ``nil``.

trusted
   **Ruby Type:** TrueClass, FalseClass

   Determines whether you should treat all packages from this repository as authenticated regardless of signature. Default value: ``false``.

deb_src
   **Ruby Type:** TrueClass, FalseClass

   Determines whether or not to add the repository as a source repo as well. Default value: ``false``.

keyserver
   **Ruby Type:** String

   The GPG keyserver where the key for the repo should be retrieved. Default value: "keyserver.ubuntu.com".

key
   **Ruby Type:** String

   If a keyserver is provided, this is assumed to be the fingerprint; otherwise it can be either the URI to the GPG key for the repo, or a cookbook_file. Default value: ``nil``.

key_proxy
   **Ruby Type:** String

   If set, a specified proxy is passed to GPG via ``http-proxy=``. Default value: ``nil``.

cookbook
   **Ruby Type:** String

   If ``key`` should be a cookbook_file, specify a cookbook where the key is located for files/default. Default value is ``nil``, so it will use the cookbook where the resource is used.

cache_rebuild
   **Ruby Type:** TrueClass, FalseClass

   Determines whether to rebuild the apt package cache. Default value: ``true``.

sensitive
   **Ruby Type:** TrueClass, FalseClass

   Determines whether sensitive resource data (such as key information) is not logged by the chef-client. Default value: ``false``.

Providers
=====================================================

This resource has the following provider:

``Chef::Provider::AptRepository``, ``apt_repository``
   The default provider for all platforms.

Examples
=====================================================

**Add repository with basic settings**

.. code-block:: ruby

   apt_repository 'zenoss' do
     uri        'http://dev.zenoss.org/deb'
     components ['main', 'stable']
   end

**Enable Ubuntu multiverse repositories**

.. code-block:: ruby

   apt_repository 'security-ubuntu-multiverse' do
     uri          'http://security.ubuntu.com/ubuntu'
     distribution 'trusty-security'
     components   ['multiverse']
     deb_src      true
   end

**Add the Nginx PPA, autodetect the key and repository url**

.. code-block:: ruby

   apt_repository 'nginx-php' do
     uri          'ppa:nginx/stable'
     distribution node['lsb']['codename']
   end

**Add the JuJu PPA, grab the key from the keyserver, and add source repo**

.. code-block:: ruby

   apt_repository 'juju' do
     uri 'http://ppa.launchpad.net/juju/stable/ubuntu'
     components ['main']
     distribution 'trusty'
     key 'C8068B11'
     keyserver 'keyserver.ubuntu.com'
     action :add
     deb_src true
   end

**Add the Cloudera Repo of CDH4 packages for Ubuntu 12.04 on AMD64**

.. code-block:: ruby

   apt_repository 'cloudera' do
     uri          'http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh'
     arch         'amd64'
     distribution 'precise-cdh4'
     components   ['contrib']
     key          'http://archive.cloudera.com/debian/archive.key'
   end

**Remove a repository from the list**

.. code-block:: ruby

   apt_repository 'zenoss' do
     action :remove
   end
