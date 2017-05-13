=====================================================
registry_key
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_registry_key.rst>`__

.. tag resource_registry_key_summary

Use the **registry_key** resource to create and delete registry keys in Microsoft Windows.

.. end_tag

.. note:: .. tag notes_registry_key_redirection

          64-bit versions of Microsoft Windows have a 32-bit compatibility layer in the registry that reflects and redirects certain keys (and their values) into specific locations (or logical views) of the registry hive.

          The chef-client can access any reflected or redirected registry key. The machine architecture of the system on which the chef-client is running is used as the default (non-redirected) location. Access to the ``SysWow64`` location is redirected must be specified. Typically, this is only necessary to ensure compatibility with 32-bit applications that are running on a 64-bit operating system.

          32-bit versions of the chef-client (12.8 and earlier) and 64-bit versions of the chef-client (12.9 and later) generally behave the same in this situation, with one exception: it is only possible to read and write from a redirected registry location using chef-client version 12.9 (and later).

          For more information, see: |url msdn_registry_key|.

          .. end_tag

Syntax
=====================================================
.. tag resource_registry_key_syntax

A **registry_key** resource block creates and deletes registry keys in Microsoft Windows:

.. code-block:: ruby

   registry_key "HKEY_LOCAL_MACHINE\\...\\System" do
     values [{
       :name => "NewRegistryKeyValue",
       :type => :multi_string,
       :data => ['foo\0bar\0\0']
     }]
     action :create
   end

Use multiple registry key entries with key values that are based on node attributes:

.. code-block:: ruby

   registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\name_of_registry_key' do
     values [{:name => 'key_name', :type => :string, :data => 'C:\Windows\System32\file_name.bmp'},
             {:name => 'key_name', :type => :string, :data => node['node_name']['attribute']['value']},
             {:name => 'key_name', :type => :string, :data => node['node_name']['attribute']['value']}
            ]
     action :create
   end

The full syntax for all of the properties that are available to the **registry_key** resource is:

.. code-block:: ruby

   registry_key 'name' do
     architecture               Symbol
     key                        String # defaults to 'name' if not specified
     notifies                   # see description
     provider                   Chef::Provider::Windows::Registry
     recursive                  TrueClass, FalseClass
     subscribes                 # see description
     values                     Hash, Array
     action                     Symbol # defaults to :create if not specified
   end

where

* ``registry_key`` is the resource
* ``name`` is the name of the resource block
* ``values`` is a hash that contains at least one registry key to be created or deleted. Each registry key in the hash is grouped by brackets in which the ``:name``, ``:type``, and ``:data`` values for that registry key are specified.
* ``:type`` represents the values available for registry keys in Microsoft Windows. Use ``:binary`` for REG_BINARY, ``:string`` for REG_SZ, ``:multi_string`` for REG_MULTI_SZ, ``:expand_string`` for REG_EXPAND_SZ, ``:dword`` for REG_DWORD, ``:dword_big_endian`` for REG_DWORD_BIG_ENDIAN, or ``:qword`` for REG_QWORD.

  .. warning:: ``:multi_string`` must be an array, even if there is only a single string.
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``architecture``, ``key``, ``provider``, ``recursive`` and ``values`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Registry Key Path Separators
-----------------------------------------------------
.. tag windows_registry_key_backslashes

A Microsoft Windows registry key can be used as a string in Ruby code, such as when a registry key is used as the name of a recipe. In Ruby, when a registry key is enclosed in a double-quoted string (``" "``), the same backslash character (``\``) that is used to define the registry key path separator is also used in Ruby to define an escape character. Therefore, the registry key path separators must be escaped when they are enclosed in a double-quoted string. For example, the following registry key:

.. code-block:: ruby

   HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Themes

may be encloused in a single-quoted string with a single backslash:

.. code-block:: ruby

   'HKCU\SOFTWARE\path\to\key\Themes'

or may be enclosed in a double-quoted string with an extra backslash as an escape character:

.. code-block:: ruby

   "HKCU\\SOFTWARE\\path\\to\\key\\Themes"

.. end_tag

Recipe DSL Methods
-----------------------------------------------------
.. tag dsl_recipe_method_windows_methods

Six methods are present in the Recipe DSL to help verify the registry during a chef-client run on the Microsoft Windows platform---``registry_data_exists?``, ``registry_get_subkeys``, ``registry_get_values``, ``registry_has_subkeys?``, ``registry_key_exists?``, and ``registry_value_exists?``---these helpers ensure the **powershell_script** resource is idempotent.

.. end_tag

.. tag notes_dsl_recipe_order_for_windows_methods

The recommended order in which registry key-specific methods should be used within a recipe is: ``key_exists?``, ``value_exists?``, ``data_exists?``, ``get_values``, ``has_subkeys?``, and then ``get_subkeys``.

.. end_tag

registry_data_exists?
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_registry_data_exists

Use the ``registry_data_exists?`` method to find out if a Microsoft Windows registry key contains the specified data of the specified type under the value.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_data_exists?`` method is as follows:

.. code-block:: ruby

   registry_data_exists?(
     KEY_PATH,
     { :name => 'NAME', :type => TYPE, :data => DATA },
     ARCHITECTURE
   )

where:

* ``KEY_PATH`` is the path to the registry key value. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``{ :name => 'NAME', :type => TYPE, :data => DATA }`` is a hash that contains the expected name, type, and data of the registry key value
* ``:type`` represents the values available for registry keys in Microsoft Windows. Use ``:binary`` for REG_BINARY, ``:string`` for REG_SZ, ``:multi_string`` for REG_MULTI_SZ, ``:expand_string`` for REG_EXPAND_SZ, ``:dword`` for REG_DWORD, ``:dword_big_endian`` for REG_DWORD_BIG_ENDIAN, or ``:qword`` for REG_QWORD.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_get_subkeys
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_registry_get_subkeys

Use the ``registry_get_subkeys`` method to get a list of registry key values that are present for a Microsoft Windows registry key.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_get_subkeys`` method is as follows:

.. code-block:: ruby

   subkey_array = registry_get_subkeys(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This returns an array of registry key values.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_get_values
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_registry_get_values

Use the ``registry_get_values`` method to get the registry key values (name, type, and data) for a Microsoft Windows registry key.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_get_values`` method is as follows:

.. code-block:: ruby

   subkey_array = registry_get_values(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This returns an array of registry key values.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_has_subkeys?
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_registry_has_subkeys

Use the ``registry_has_subkeys?`` method to find out if a Microsoft Windows registry key has one (or more) values.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_has_subkeys?`` method is as follows:

.. code-block:: ruby

   registry_has_subkeys?(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_key_exists?
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_registry_key_exists

Use the ``registry_key_exists?`` method to find out if a Microsoft Windows registry key exists at the specified path.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_key_exists?`` method is as follows:

.. code-block:: ruby

   registry_key_exists?(KEY_PATH, ARCHITECTURE)

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``. (Any registry key values that are associated with this registry key are ignored.)

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

registry_value_exists?
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_registry_value_exists

Use the ``registry_value_exists?`` method to find out if a registry key value exists. Use ``registry_data_exists?`` to test for the type and data of a registry key value.

.. note:: .. tag notes_registry_key_not_if_only_if

          This method can be used in recipes and from within the ``not_if`` and ``only_if`` blocks in resources. This method is not designed to create or modify a registry key. If a registry key needs to be modified, use the **registry_key** resource.

          .. end_tag

The syntax for the ``registry_value_exists?`` method is as follows:

.. code-block:: ruby

   registry_value_exists?(
     KEY_PATH,
     { :name => 'NAME' },
     ARCHITECTURE
   )

where:

* ``KEY_PATH`` is the path to the registry key. The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.
* ``{ :name => 'NAME' }`` is a hash that contains the name of the registry key value; if either ``:type`` or ``:value`` are specified in the hash, they are ignored
* ``:type`` represents the values available for registry keys in Microsoft Windows. Use ``:binary`` for REG_BINARY, ``:string`` for REG_SZ, ``:multi_string`` for REG_MULTI_SZ, ``:expand_string`` for REG_EXPAND_SZ, ``:dword`` for REG_DWORD, ``:dword_big_endian`` for REG_DWORD_BIG_ENDIAN, or ``:qword`` for REG_QWORD.
* ``ARCHITECTURE`` is one of the following values: ``:x86_64``, ``:i386``, or ``:machine``. In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

This method will return ``true`` or ``false``.

.. note:: .. tag notes_registry_key_architecture

          The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

          .. end_tag

.. end_tag

Actions
=====================================================
.. tag resource_registry_key_actions

This resource has the following actions:

``:create``
   Default. Create a registry key. If a registry key already exists (but does not match), update that registry key to match.

``:create_if_missing``
   Create a registry key if it does not exist. Also, create a registry key value if it does not exist.

``:delete``
   Delete the specified values for a registry key.

``:delete_key``
   Delete the specified registry key and all of its subkeys.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

.. note:: .. tag notes_registry_key_resource_recursive

          Be careful when using the ``:delete_key`` action with the ``recursive`` attribute. This will delete the registry key, all of its values and all of the names, types, and data associated with them. This cannot be undone by the chef-client.

          .. end_tag

.. end_tag

Properties
=====================================================
.. tag resource_registry_key_attributes

This resource has the following properties:

``architecture``
   **Ruby Type:** Symbol

   The architecture of the node for which keys are to be created or deleted. Possible values: ``:i386`` (for nodes with a 32-bit registry), ``:x86_64`` (for nodes with a 64-bit registry), and ``:machine`` (to have the chef-client determine the architecture during the chef-client run). Default value: ``:machine``.

   In order to read or write 32-bit registry keys on 64-bit machines running Microsoft Windows, the ``architecture`` property must be set to ``:i386``. The ``:x86_64`` value can be used to force writing to a 64-bit registry location, but this value is less useful than the default (``:machine``) because the chef-client returns an exception if ``:x86_64`` is used and the machine turns out to be a 32-bit machine (whereas with ``:machine``, the chef-client is able to access the registry key on the 32-bit machine).

   .. note:: .. tag notes_registry_key_architecture

             The ``ARCHITECTURE`` attribute should only specify ``:x86_64`` or ``:i386`` when it is necessary to write 32-bit (``:i386``) or 64-bit (``:x86_64``) values on a 64-bit machine. ``ARCHITECTURE`` will default to ``:machine`` unless a specific value is given.

             .. end_tag

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``key``
   **Ruby Type:** String

   The path to the location in which a registry key is to be created or from which a registry key is to be deleted. Default value: the ``name`` of the resource block See "Syntax" section above for more information.
   The path must include the registry hive, which can be specified either as its full name or as the 3- or 4-letter abbreviation. For example, both ``HKLM\SECURITY`` and ``HKEY_LOCAL_MACHINE\SECURITY`` are both valid and equivalent. The following hives are valid: ``HKEY_LOCAL_MACHINE``, ``HKLM``, ``HKEY_CURRENT_CONFIG``, ``HKCC``, ``HKEY_CLASSES_ROOT``, ``HKCR``, ``HKEY_USERS``, ``HKU``, ``HKEY_CURRENT_USER``, and ``HKCU``.

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

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider.

``recursive``
   **Ruby Types:** TrueClass, FalseClass

   When creating a key, this value specifies that the required keys for the specified path are to be created. When using the ``:delete_key`` action in a recipe, and if the registry key has subkeys, then set the value for this property to ``true``.

   .. note:: .. tag notes_registry_key_resource_recursive

             Be careful when using the ``:delete_key`` action with the ``recursive`` attribute. This will delete the registry key, all of its values and all of the names, types, and data associated with them. This cannot be undone by the chef-client.

             .. end_tag

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

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

``values``
   **Ruby Types:** Hash, Array

   An array of hashes, where each Hash contains the values that are to be set under a registry key. Each Hash must contain ``:name``, ``:type``, and ``:data`` (and must contain no other key values).

   ``:type`` represents the values available for registry keys in Microsoft Windows. Use ``:binary`` for REG_BINARY, ``:string`` for REG_SZ, ``:multi_string`` for REG_MULTI_SZ, ``:expand_string`` for REG_EXPAND_SZ, ``:dword`` for REG_DWORD, ``:dword_big_endian`` for REG_DWORD_BIG_ENDIAN, or ``:qword`` for REG_QWORD.

   .. warning:: ``:multi_string`` must be an array, even if there is only a single string.

.. end_tag

Examples
=====================================================
The following examples demonstrate various approaches for using resources in recipes. If you want to see examples of how Chef uses resources in recipes, take a closer look at the cookbooks that Chef authors and maintains: https://github.com/chef-cookbooks.

**Create a registry key**

.. tag resource_registry_key_create

.. To disable a registry key:

Use a double-quoted string:

.. code-block:: ruby

   registry_key "HKEY_LOCAL_MACHINE\\path-to-key\\Policies\\System" do
     values [{
       :name => 'EnableLUA',
       :type => :dword,
       :data => 0
     }]
     action :create
   end

or a single-quoted string:

.. code-block:: ruby

   registry_key 'HKEY_LOCAL_MACHINE\path-to-key\Policies\System' do
     values [{
       :name => 'EnableLUA',
       :type => :dword,
       :data => 0
     }]
     action :create
   end

.. end_tag

**Delete a registry key value**

.. tag resource_registry_key_delete_value

.. To delete a registry key:

Use a double-quoted string:

.. code-block:: ruby

   registry_key "HKEY_LOCAL_MACHINE\\SOFTWARE\\path\\to\\key\\AU" do
     values [{
       :name => 'NoAutoRebootWithLoggedOnUsers',
       :type => :dword,
       :data => ''
       }]
     action :delete
   end

or a single-quoted string:

.. code-block:: ruby

   registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\path\to\key\AU' do
     values [{
       :name => 'NoAutoRebootWithLoggedOnUsers',
       :type => :dword,
       :data => ''
       }]
     action :delete
   end

.. note:: If ``:data`` is not specified, you get an error: ``Missing data key in RegistryKey values hash``

.. end_tag

**Delete a registry key and its subkeys, recursively**

.. tag resource_registry_key_delete_recursively

.. To delete a registry key and all of its subkeys recursively:

Use a double-quoted string:

.. code-block:: ruby

   registry_key "HKCU\\SOFTWARE\\Policies\\path\\to\\key\\Themes" do
     recursive true
     action :delete_key
   end

or a single-quoted string:

.. code-block:: ruby

   registry_key 'HKCU\SOFTWARE\Policies\path\to\key\Themes' do
     recursive true
     action :delete_key
   end

.. note:: .. tag notes_registry_key_resource_recursive

          Be careful when using the ``:delete_key`` action with the ``recursive`` attribute. This will delete the registry key, all of its values and all of the names, types, and data associated with them. This cannot be undone by the chef-client.

          .. end_tag

.. end_tag

**Use re-directed keys**

.. tag resource_registry_key_redirect

In 64-bit versions of Microsoft Windows, ``HKEY_LOCAL_MACHINE\SOFTWARE\Example`` is a re-directed key. In the following examples, because ``HKEY_LOCAL_MACHINE\SOFTWARE\Example`` is a 32-bit key, the output will be "Found 32-bit key" if they are run on a version of Microsoft Windows that is 64-bit:

.. code-block:: ruby

   registry_key "HKEY_LOCAL_MACHINE\\SOFTWARE\\Example" do
     architecture :i386
     recursive true
     action :create
   end

or:

.. code-block:: ruby

   registry_key "HKEY_LOCAL_MACHINE\\SOFTWARE\\Example" do
     architecture :x86_64
     recursive true
     action :delete_key
   end

or:

.. code-block:: ruby

   ruby_block 'check 32-bit' do
     block do
       puts 'Found 32-bit key'
     end
     only_if {
       registry_key_exists?("HKEY_LOCAL_MACHINE\SOFTWARE\\Example",
       :i386)
     }
   end

or:

.. code-block:: ruby

   ruby_block 'check 64-bit' do
     block do
       puts 'Found 64-bit key'
     end
     only_if {
       registry_key_exists?("HKEY_LOCAL_MACHINE\\SOFTWARE\\Example",
       :x86_64)
     }
   end

.. end_tag

**Set proxy settings to be the same as those used by the chef-client**

.. tag resource_registry_key_set_proxy_settings_to_same_as_chef_client

.. To set system proxy settings to be the same as used by the chef-client:

Use a double-quoted string:

.. code-block:: ruby

   proxy = URI.parse(Chef::Config[:http_proxy])
   registry_key "HKCU\Software\Microsoft\path\to\key\Internet Settings" do
     values [{:name => 'ProxyEnable', :type => :reg_dword, :data => 1},
             {:name => 'ProxyServer', :data => "#{proxy.host}:#{proxy.port}"},
             {:name => 'ProxyOverride', :type => :reg_string, :data => <local>},
            ]
     action :create
   end

or a single-quoted string:

.. code-block:: ruby

   proxy = URI.parse(Chef::Config[:http_proxy])
   registry_key 'HKCU\Software\Microsoft\path\to\key\Internet Settings' do
     values [{:name => 'ProxyEnable', :type => :reg_dword, :data => 1},
             {:name => 'ProxyServer', :data => "#{proxy.host}:#{proxy.port}"},
             {:name => 'ProxyOverride', :type => :reg_string, :data => <local>},
            ]
     action :create
   end

.. end_tag

**Set the name of a registry key to "(Default)"**

.. tag resource_registry_key_set_default

.. To set the "(Default)" name of a registry key:

Use a double-quoted string:

.. code-block:: ruby

   registry_key 'Set (Default) value' do
     action :create
     key "HKLM\\Software\\Test\\Key\\Path"
     values [
       {:name => '', :type => :string, :data => 'test'},
     ]
   end

or a single-quoted string:

.. code-block:: ruby

   registry_key 'Set (Default) value' do
     action :create
     key 'HKLM\Software\Test\Key\Path'
     values [
       {:name => '', :type => :string, :data => 'test'},
     ]
   end

where ``:name => ''`` contains an empty string, which will set the name of the registry key to ``(Default)``.

.. end_tag
