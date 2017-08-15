=====================================================
user
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_user.rst>`__

.. tag resource_user_summary

Use the **user** resource to add users, update existing users, remove users, and to lock/unlock user passwords.

.. note:: System attributes are collected by Ohai at the start of every chef-client run. By design, the actions available to the **user** resource are processed **after** the start of the chef-client run. This means that system attributes added or modified by the **user** resource during the chef-client run must be reloaded before they can be available to the chef-client. These system attributes can be reloaded in two ways: by picking up the values at the start of the (next) chef-client run or by using the :doc:`ohai resource </resource_ohai>` to reload the system attributes during the current chef-client run.

.. end_tag

Syntax
=====================================================
A **user** resource block manages users on a node:

.. code-block:: ruby

   user 'a user' do
     comment 'A random user'
     uid '1234'
     gid '1234'
     home '/home/random'
     shell '/bin/bash'
     password '$1$JJsvHslasdfjVEroftprNn4JHtDi'
   end

The full syntax for all of the properties that are available to the **user** resource is:

.. code-block:: ruby

   user 'name' do
     comment                    String
     force                      TrueClass, FalseClass # see description
     gid                        String, Integer
     home                       String
     iterations                 Integer
     manage_home                TrueClass, FalseClass
     non_unique                 TrueClass, FalseClass
     notifies                   # see description
     password                   String
     provider                   Chef::Provider::User
     salt                       String
     shell                      String
     subscribes                 # see description
     system                     TrueClass, FalseClass
     uid                        String, Integer
     username                   String # defaults to 'name' if not specified
     action                     Symbol # defaults to :create if not specified
   end

where

* ``user`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``comment``, ``force``, ``gid``, ``home``, ``iterations``, ``manage_home``, ``non_unique``, ``password``, ``provider``, ``salt``, ``shell``, ``system``, ``uid``, and ``username`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

Actions
=====================================================
This resource has the following actions:

``:create``
   Default. Create a user with given properties. If a user already exists (but does not match), update that user to match.

``:lock``
   Lock a user's password.

``:manage``
   Manage an existing user. This action does nothing if the user does not exist.

``:modify``
   Modify an existing user. This action raises an exception if the user does not exist.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:remove``
   Remove a user.

``:unlock``
   Unlock a user's password.

Properties
=====================================================
This resource has the following properties:

``comment``
   **Ruby Type:** String

   One (or more) comments about the user.

``force``
   **Ruby Types:** TrueClass, FalseClass

   Force the removal of a user. May be used only with the ``:remove`` action.

   .. warning:: Using this property may leave the system in an inconsistent state. For example, a user account will be removed even if the user is logged in. A user's home directory will be removed, even if that directory is shared by multiple users.

``gid``
   **Ruby Types:** String, Integer

   The identifier for the group.

``group``
   **Ruby Types:** String, Integer

   The ``group`` property is an alias of the ``gid`` property.

``home``
   **Ruby Type:** String

   The location of the home directory.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``iterations``
   **Ruby Type:** Integer

   macOS platform only, 10.8 (or higher). The number of iterations for a password with a SALTED-SHA512-PBKDF2 shadow hash.

   New in Chef Client 12.0.

``manage_home``
   **Ruby Types:** TrueClass, FalseClass

   Manage a user's home directory.

   With the ``:create`` action, a user's home directory is created based on ``HOME_DIR``. If the home directory is missing, it is created unless ``CREATE_HOME`` in ``/etc/login.defs`` is set to ``no``. When created, a skeleton set of files and sub-directories is also created in the home directory.

   With the ``:modify`` action, a user's home directory is moved to ``HOME_DIR``. If the home directory is missing, it is created unless ``CREATE_HOME`` in ``/etc/login.defs`` is set to ``no``. The contents of the user's home directory are moved to the new location.

``non_unique``
   **Ruby Types:** TrueClass, FalseClass

   Create a duplicate (non-unique) user account.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_notifies_syntax

   The syntax for ``notifies`` is:

   .. code-block:: ruby

      notifies :action, 'resource[name]', :timer

   .. end_tag

``password``
   **Ruby Type:** String

   The password shadow hash. This property requires that ``ruby-shadow`` be installed. This is part of the Debian package: ``libshadow-ruby1.8``.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider. See "Providers" section below for more information.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``salt``
   **Ruby Type:** String

   macOS platform only, 10.7 or higher. The salt value for a password shadow hash. macOS version 10.7 uses SALTED-SHA512 and version 10.8 (and higher) uses SALTED-SHA512-PBKDF2 to calculate password shadow hashes.

   New in Chef Client 12.0.

``shell``
   **Ruby Type:** String

   The login shell.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag resources_common_notification_timers

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

   ``:before``
      Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

   ``:delayed``
      Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

   .. tag resources_common_notification_subscribes_syntax

   The syntax for ``subscribes`` is:

   .. code-block:: ruby

      subscribes :action, 'resource[name]', :timer

   .. end_tag

``system``
   **Ruby Types:** TrueClass, FalseClass

   Create a system user. This property may be used with ``useradd`` as the provider to create a system user which passes the ``-r`` flag to ``useradd``.

``uid``
   **Ruby Types:** String, Integer

   The numeric user identifier.

``username``
   **Ruby Type:** String

   The name of the user. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

Password Shadow Hash
=====================================================
There are a number of encryption options and tools that can be used to create a password shadow hash. In general, using a strong encryption method like SHA-512 and the ``passwd`` command in the OpenSSL toolkit is a good approach, however the encryption options and tools that are available may be different from one distribution to another. The following examples show how the command line can be used to create a password shadow hash. When using the ``passwd`` command in the OpenSSL tool:

.. code-block:: bash

   openssl passwd -1 "theplaintextpassword"

When using ``mkpasswd``:

.. code-block:: bash

   mkpasswd -m sha-512

For more information:

* https://www.openssl.org/docs/manmaster/man1/passwd.html
* Check the local documentation or package repository for the distribution that is being used. For example, on Ubuntu 9.10-10.04, the ``mkpasswd`` package is required and on Ubuntu 10.10+ the ``whois`` package is required.

Providers
=====================================================
.. tag resources_common_provider

Where a resource represents a piece of the system (and its desired state), a provider defines the steps that are needed to bring that piece of the system from its current state into the desired state.

.. end_tag

.. tag resources_common_provider_attributes

The chef-client will determine the correct provider based on configuration data collected by Ohai at the start of the chef-client run. This configuration data is then mapped to a platform and an associated list of providers.

Generally, it's best to let the chef-client choose the provider, and this is (by far) the most common approach. However, in some cases, specifying a provider may be desirable. There are two approaches:

* Use a more specific short name---``yum_package "foo" do`` instead of ``package "foo" do``, ``script "foo" do`` instead of ``bash "foo" do``, and so on---when available
* Use the ``provider`` property within the resource block to specify the long name of the provider as a property of a resource. For example: ``provider Chef::Provider::Long::Name``

.. end_tag

This resource has the following providers:

``Chef::Provider::User::Useradd``, ``user``
   The default provider for the **user** resource.

``Chef::Provider::User::Pw``, ``user``
   The provider for the FreeBSD platform.

``Chef::Provider::User::Dscl``, ``user``
   The provider for the macOS platform.

``Chef::Provider::User::Windows``, ``user``
   The provider for all Microsoft Windows platforms.

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Create a user named "random"**

.. tag resource_user_create_random

.. To create a user named "random":

.. code-block:: ruby

   user 'random' do
     manage_home true
     comment 'User Random'
     uid '1234'
     gid '1234'
     home '/home/random'
     shell '/bin/bash'
     password '$1$JJsvHslV$szsCjVEroftprNn4JHtDi'
   end

.. end_tag

**Create a system user**

.. tag resource_user_create_system

.. To create a system user:

.. code-block:: ruby

   user 'systemguy' do
     comment 'system guy'
     system true
     shell '/bin/false'
   end

.. end_tag

**Create a system user with a variable**

.. tag resource_user_create_system_user_with_variable

The following example shows how to create a system user. In this instance, the ``home`` value is calculated and stored in a variable called ``user_home`` which sets the user's ``home`` attribute.

.. code-block:: ruby

   user_home = "/home/#{node['cookbook_name']['user']}"

   user node['cookbook_name']['user'] do
     gid node['cookbook_name']['group']
     shell '/bin/bash'
     home user_home
     system true
     action :create
   end

.. end_tag

**Use SALTED-SHA512 passwords**

.. tag resource_user_password_shadow_hash_salted_sha512

macOS 10.7 calculates the password shadow hash using SALTED-SHA512. The length of the shadow hash value is 68 bytes, the salt value is the first 4 bytes, with the remaining 64 being the shadow hash itself. The following code will calculate password shadow hashes for macOS 10.7:

.. code-block:: ruby

   password = 'my_awesome_password'
   salt = OpenSSL::Random.random_bytes(4)
   encoded_password = OpenSSL::Digest::SHA512.hexdigest(salt + password)
   shadow_hash = salt.unpack('H*').first + encoded_password

Use the calculated password shadow hash with the **user** resource:

.. code-block:: ruby

   user 'my_awesome_user' do
     password 'c9b3bd....d843'  # Length: 136
   end

.. end_tag

**Use SALTED-SHA512-PBKDF2 passwords**

.. tag resource_user_password_shadow_hash_salted_sha512_pbkdf2

macOS 10.8 (and higher) calculates the password shadow hash using SALTED-SHA512-PBKDF2. The length of the shadow hash value is 128 bytes, the salt value is 32 bytes, and an integer specifies the number of iterations. The following code will calculate password shadow hashes for macOS 10.8 (and higher):

.. code-block:: ruby

   password = 'my_awesome_password'
   salt = OpenSSL::Random.random_bytes(32)
   iterations = 25000 # Any value above 20k should be fine.

   shadow_hash = OpenSSL::PKCS5::pbkdf2_hmac(
     password,
     salt,
     iterations,
     128,
     OpenSSL::Digest::SHA512.new
   ).unpack('H*').first
   salt_value = salt.unpack('H*').first

Use the calculated password shadow hash with the **user** resource:

.. code-block:: ruby

   user 'my_awesome_user' do
     password 'cbd1a....fc843'  # Length: 256
     salt 'bd1a....fc83'        # Length: 64
     iterations 25000
   end

.. end_tag
