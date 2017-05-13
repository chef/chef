=====================================================
Release Notes: chef-client 12.0 - 13.0
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/release_notes.rst>`__

Chef client is released on a monthly schedule with new releases the first Wednesday of every month. Below are the major changes for each release. For a detailed list of changes see the `Chef CHANGELOG.md <https://github.com/chef/chef/blob/master/CHANGELOG.md>`__


What's New in 13.0
=====================================================

* **Blacklist attributes**
* **Rubygems sources**
* **Windows task**
* **Chef client will now exit using the rfc062 defined exit codes**
* **Backwards compatibility breaks**


It is now possible to blacklist node attributes
-----------------------------------------------------
Blacklist Attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
New in Chef Client 13.0

.. tag node_attribute_blacklist

.. warning:: When attribute blacklist settings are used, any attribute defined in a blacklist will not be saved and any attribute that is not defined in a blacklist will be saved. Each attribute type is blacklisted independently of the other attribute types. For example, if ``automatic_attribute_blacklist`` defines attributes that will not be saved, but ``normal_attribute_blacklist``, ``default_attribute_blacklist``, and ``override_attribute_blacklist`` are not defined, then all normal attributes, default attributes, and override attributes will be saved, as well as the automatic attributes that were not specifically excluded through blacklisting.

Attributes that should not be saved by a node may be blacklisted in the client.rb file. The blacklist is a Hash of keys that specify each attribute to be filtered out.

Attributes are blacklisted by attribute type, with each attribute type being blacklisted independently. Each attribute type---``automatic``, ``default``, ``normal``, and ``override``---may define blacklists by using the following settings in the client.rb file:

.. list-table::
   :widths: 200 300
   :header-rows: 1


   * - Setting
     - Description
   * - ``automatic_attribute_blacklist``
     - A hash that blacklists ``automatic`` attributes, preventing blacklisted attributes from being saved. For example: ``['network/interfaces/eth0']``. Default value: ``nil``, all attributes are saved. If the array is empty, all attributes are saved.
   * - ``default_attribute_blacklist``
     - A hash that blacklists ``default`` attributes, preventing blacklisted attributes from being saved. For example: ``['filesystem/dev/disk0s2/size']``. Default value: ``nil``, all attributes are saved. If the array is empty, all attributes are saved.
   * - ``normal_attribute_blacklist``
     - A hash that blacklists ``normal`` attributes, preventing blacklisted attributes from being saved. For example: ``['filesystem/dev/disk0s2/size']``. Default value: ``nil``, all attributes are saved. If the array is empty, all attributes are saved.
   * - ``override_attribute_blacklist``
     - A hash that blacklists ``override`` attributes, preventing blacklisted attributes from being saved. For example: ``['map - autohome/size']``. Default value: ``nil``, all attributes are saved. If the array is empty, all attributes are saved.

.. warning:: The recommended practice is to use only ``automatic_attribute_blacklist`` for blacklisting attributes. This is primarily because automatic attributes generate the most data, but also that normal, default, and override attributes are typically much more important attributes and are more likely to cause issues if they are blacklisted incorrectly.

For example, normal attribute data similar to:

.. code-block:: javascript

   {
     "filesystem" => {
       "/dev/disk0s2" => {
         "size" => "10mb"
       },
       "map - autohome" => {
         "size" => "10mb"
       }
     },
     "network" => {
       "interfaces" => {
         "eth0" => {...},
         "eth1" => {...},
       }
     }
   }

To blacklist the ``filesystem`` attributes and allow the other attributes to be saved, update the client.rb file:

.. code-block:: ruby

   normal_attribute_blacklist ['filesystem']

When a blacklist is defined, any attribute of that type that is not specified in that attribute blacklist **will** be saved. So based on the previous blacklist for normal attributes, the ``filesystem`` and ``map - autohome`` attributes will not be saved, but the ``network`` attributes will.

For attributes that contain slashes (``/``) within the attribute value, such as the ``filesystem`` attribute ``'/dev/diskos2'``, use an array. For example:

.. code-block:: ruby

   automatic_attribute_blacklist [['filesystem','/dev/diskos2']]

.. end_tag

Rubygems provider sources behavior changed.
-----------------------------------------------------
The behavior of ``gem_package`` and ``chef_gem`` is now to always apply the ``Chef::Config[:rubygems_uri]`` sources, which may be a string uri or an array of strings.  If additional sources are put on the resource with the ``source`` property those are added to the configured ``:rubygems_uri`` sources.

This should enable easier setup of rubygems mirrors particularly in "airgapped" environments through the use of the global config variable.  It also means that an admin may force all rubygems.org traffic to an internal mirror, while still being able to consume external cookbooks which have resources which add other mirrors unchanged (in a non-airgapped environment).

In the case where a resource must force the use of only the specified source(s), then the ``include_default_source`` property has been added -- setting it to false will remove the ``Chef::Config[:rubygems_url]`` setting from the list of sources for
that resource.

The behavior of the ``clear_sources`` property is now to only add ``--clear-sources`` and has no magic side effects on the source options.

Ruby version upgraded to 2.4.1
-----------------------------------------------------
We've upgraded to the latest stable release of the Ruby programming
language. See the Ruby [2.4.0 Release Notes](https://www.ruby-lang.org/en/news/2016/12/25/ruby-2-4-0-released/) for an overview of what's new in the language.

Resource can now declare a default name
-----------------------------------------------------
The core ``apt_update`` resource can now be declared without any name argument, no need for ``apt_update STING``.

This can be used by any other resource by just overriding the name property and supplying a default:

.. code-block:: ruby

  property :name, String, default: ""

Notifications to resources with empty strings as their name is also supported via either the bare resource name (``apt_update`` -- matches what the user types in the DSL) or with empty brackets (``apt_update[]``` -- matches the resource notification pattern).

The knife ssh command applies the same fuzzifier as knife search node
-------------------------------------------------------------------------
A bare name to knife search node will search for the name in ``tags``, ``roles``, ``fqdn``, ``addresses``, ``policy_name`` or ``policy_group`` fields and will match when given partial strings (available since Chef 11).
The ``knife ssh`` search term has been similarly extended so that the search API matches in both cases.  The node search fuzzifier has also been extracted out to a ``fuzz`` option to Chef::Search::Query for re-use
elsewhere.

Cookbook root aliases
-----------------------------------------------------
Rather than ``attributes/default.rb``, cookbooks can now use ``attributes.rb`` in the root of the cookbook. Similarly for a single default recipe, cookbooks can use ``recipe.rb`` in the root of the cookbook.

knife ssh connects gateways with ssh key authentication
----------------------------------------------------------
The new ``gateway_identity_file`` option allows the operator to specify the key to access ssh gateways with.

Windows Task resource added
-----------------------------------------------------
The ``windows_task`` resource has been ported from the windows cookbook.
Use the **windows_task** resource to create, delete or run a Windows scheduled task. Requires Windows Server 2008 due to API usage.

**Note**: ``:change`` action has been removed from ``windows_task`` resource. ``:create`` action can be used to update an existing task.

Solaris SMF services can now be started recursively
-----------------------------------------------------
It is now possible to load Solaris services recursively, by ensuring the new ``options`` property of the ``service`` resource contains ``-r``.

The guard interpreter for ``powershell_script`` is Powershell, again
------------------------------------------------------------------------------
When writing ``not_if`` or ``only_if`` statements, by default we now run those statements using powershell, rather than forcing the user to set ``guard_interpreter`` each time.

Zypper GPG checks by default
-----------------------------------------------------
Zypper now defaults to performing gpg checks of packages.

The InSpec gem is now shipped by default
-----------------------------------------------------
The ``inspec`` and ``train`` gems are shipped by default in the chef omnibus package, making it easier for users in airgapped environments to use InSpec.

Backwards Compatibility Breaks
-----------------------------------------------------
Resource Cloning has been removed
+++++++++++++++++++++++++++++++++++++++++++++++++++++
When Chef compiles resources, it will no longer attempt to merge the properties of previously compiled resources with the same name and type in to the new resource. See [the deprecation page](https://docs.chef.io/deprecations_resource_cloning.html) for further information.

It is an error to specify both ``default`` and ``name_property`` on a property
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Chef 12 made this work by picking the first option it found, but it was
always an error and has now been disallowed.

The path property of the execute resource has been removed
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
It was never implemented in the provider, so it was always a no-op to use it, the remediation is
to simply delete it.

Using the command property on any script resource (including bash, etc) is now a hard error
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
This was always a usage mistake.  The command property was used internally by the script resource and was not intended to be exposed to users.  Users should use the code property instead (or use the command property on an execute resource to execute a single command).

Omitting the code property on any script resource (including bash, etc) is now a hard error
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
It is possible that this was being used as a no-op resource, but the log resource is a better choice for that until we get a null resource added.  Omitting the code property or mixing up the code property with the command property are also common usage mistakes that we need to catch and error on.

The chef\_gem resource defaults to not run at compile time
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
The ``compile_time true`` flag may still be used to force compile time.

The Chef::Config[:chef\_gem\_compile\_time] config option has been removed
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
In order to for community cookbooks to behave consistently across all users this optional flag has been removed.

The ``supports[:manage_home]`` and ``supports[:non_unique]`` API has been removed
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
The remediation is to set the manage_home and non_unique properties directly.

``creates`` without ``cwd`` is a hard error
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Using relative paths in the ``creates`` property of an execute resource with specifying a ``cwd`` is now a hard error
Without a declared cwd the relative path was (most likely?) relative to wherever chef-client happened to be invoked which is not deterministic or easy to intuit behavior.

Chef::PolicyBuilder::ExpandNodeObject#load_node has been removed
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
This change is most likely to only affect internals of tooling like chefspec if it affects anything at all.

PolicyFile failback
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PolicyFile failback to create non-policyfile nodes on Chef Server < 12.3 has been removed
PolicyFile users on Chef-13 should be using Chef Server 12.3 or higher.

Cookbooks with self dependencies are no longer allowed
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
The remediation is removing the self-dependency ``depends`` line in the metadata.

Removed ``supports`` API from Chef::Resource
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Retained only for the service resource (where it makes some sense) and for the mount resource.

Removed retrying of non-StandardError exceptions for Chef::Resource
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Exceptions not decending from StandardError (e.g. LoadError, SecurityError, SystemExit) will no longer trigger a retry if they are raised during the executiong of a resources with a non-zero retries setting.

Removed deprecated ``method_missing`` access from the Chef::Node object
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Previously, the syntax ``node.foo.bar`` could be used to mean ``node["foo"]["bar"]``, but this API had sharp edges where methods collided with the core ruby Object class (e.g. ``node.class`) and where it collided with our own ability to extend the ``Chef::Node`` API.  This method access has been deprecated for some time, and has been removed in Chef-13.

Changed ``declare_resource`` API
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Dropped the ``create_if_missing`` parameter that was immediately supplanted by the ``edit_resource`` API (most likely nobody ever used this) and converted the ``created_at`` parameter from an optional positional parameter to a named parameter.  These changes are unlikely to affect any cookbook code.

Node deep-duping fixes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The ``node.to_hash`/`node.to_h`` and ``node.dup`` APIs have been fixed so that they correctly deep-dup the node data structure including every string value.  This results in a mutable copy of the immutable merged node structure.  This is correct behavior, but is now more expensive and may break some poor code (which would have been buggy and difficult to follow code with odd side effects before).

For example:

.. code-block:: ruby

node.default["foo"] = "fizz"
n = node.to_hash   # or node.dup
n["foo"] << "buzz"


before this would have mutated the original string in-place so that ``node["foo"]`` and ``node.default["foo"]`` would have changed to "fizzbuzz" while now they remain "fizz" and only the mutable ``n["foo"]`` copy is changed to "fizzbuzz".

Freezing immutable merged attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Since Chef 11 merged node attributes have been intended to be immutable but the merged strings have not been frozen.  In Chef 13, in the process of merging the node attributes strings and other simple objects are dup'd and frozen.  In order to get a mutable copy, you can now correctly use the ``node.dup`` or ``node.to_hash`` methods, or you should mutate the object correctly through its precedence level like `node.default["some_string"] << "appending_this"`.

The Chef::REST API has been removed
+++++++++++++++++++++++++++++++++++++++++++++++++++++
It has been fully replaced with ``Chef::ServerAPI`` in chef-client code.

Properties overriding methods now raise an error
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Defining a property that overrides methods defined on the base ruby ``Object`` or on ``Chef::Resource`` itself can cause large amounts of confusion.  A simple example is ``property :hash`` which overrides the Object#hash method which will confuse ruby when the Custom Resource is placed into the Chef::ResourceCollection which uses a hash internally which expects to call Object#hash to get a unique id for the object.  Attempting to create ``property :action`` would also override the Chef::Resource#action method which is unlikely to end well for the user.  Overriding inherited properties is still supported.

``chef-shell`` now supports solo and legacy solo modes
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Running ``chef-shell -s`` or ``chef-shell --solo`` will give you an experience consistent with ``chef-solo``. ``chef-shell --solo-legacy-mode` will give you an experience consistent with ``chef-solo --legacy-mode``.

Chef::Platform.set and related methods have been removed
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
The deprecated code has been removed.  All providers and resources should now be using Chef >= 12.0 ``provides`` syntax.

Remove ``sort`` option for the Search API
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This option has been unimplemented on the server side for years, so any use of it has been pointless.

Remove Chef::ShellOut
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This was deprecated and replaced a long time ago with mixlib-shellout and the shell_out mixin.

Remove ``method_missing`` from the Recipe DSL
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The core of chef hasn't used this to implement the Recipe DSL since 12.5.1 and its unlikely that any external code depended upon it.

Simplify Recipe DSL wiring
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Support for actions with spaces and hyphens in the action name has been dropped.  Resources and property names with spaces and hyphens most likely never worked in Chef-12.  UTF-8 characters have always been supported and still are.

``easy_install`` resource has been removed
+++++++++++++++++++++++++++++++++++++++++++++++++++++

The Python ``easy_install`` package installer has been deprecated for many years, so we have removed support for it. No specific replacement for ``pip`` is being included with Chef at this time, but a ``pip`-based ``python_package`` resource is available in the [`poise-python`](https://github.com/poise/poise-python) cookbooks.

Removal of run_command and popen4 APIs
+++++++++++++++++++++++++++++++++++++++++++++++++++++
All the APIs in chef/mixlib/command have been removed.  They were deprecated by mixlib-shellout and the shell_out mixin API.

Iconv has been removed from the ruby libraries and chef omnibus build
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
The ruby Iconv library was replaced by the Encoding library in ruby 1.9.x and since the deprecation of ruby 1.8.7 there has been no need for the Iconv library but we have carried it forwards as a dependency since removing it might break some chef code out there which used this library.  It has now been removed from the ruby build.  This also removes LGPLv3 code from the omnibus build and reduces build headaches from porting iconv to every platform we ship chef-client on.

This will also affect nokogiri, but that gem natively supports UTF-8, UTF-16LE/BE, ISO-8851-1(Latin-1), ASCII and "HTML" encodings.  Users who really need to write something like Shift-JIS inside of XML will need to either maintain their own nokogiri installs or will need to convert to using UTF-8.

Deprecated cookbook metadata has been removed
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The ``recommends``, ``suggests``, ``conflicts``, ``replaces`` and ``grouping`` metadata fields are no longer supported, and have been removed. Chef will ignore them in existing ``metadata.rb`` files, but we recommend that you remove them.

All unignored cookbook files will now be uploaded.
+++++++++++++++++++++++++++++++++++++++++++++++++++++
We now treat every file under a cookbook directory as belonging to a cookbook, unless that file is ignored with a ``chefignore`` file. This is a change from the previous behavior where only files in certain directories, such as ``recipes`` or ``templates``, were treated as special.
This change allows chef to support new classes of files, such as Ohai plugins or Inspec tests, without having to make changes to the cookbook format to support them.

DSL-based custom resources and providers no longer get module constants
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Up until now, creating a ``mycook/resources/thing.rb`` would create a ``Chef::Resources::MycookThing`` name to access the resource class object.
This const is no longer created for resources and providers. You can access resource classes through the resolver API like:

.. code-block:: ruby

Chef::Resource.resource_for_node(:mycook_thing, node)

Accessing a provider class is a bit more complex, as you need a resource against which to run a resolution like so:

.. code-block:: ruby

Chef::ProviderResolver.new(node, find_resource!("mycook_thing[name]"), :nothing).resolve


Default values for resource properties are frozen
+++++++++++++++++++++++++++++++++++++++++++++++++++++
A resource declaring something like:

.. code-block:: ruby

property :x, default: {}

will now see the default value set to be immutable. This prevents cases of modifying the default in one resource affecting others. If you want a per-resource mutable default value, define it inside a ``lazy{}`` helper like:

.. code-block:: ruby

property :x, default: lazy { {} }


ResourceCollection and notifications
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Resources which later modify their name during creation will have their name changed on the ResourceCollection and notifications

..code-block:: ruby

some_resource "name_one" do
  name "name_two"


The fix for sending notifications to multipackage resources involved changing the API so that it no longer directly takes the string that is typed into the DSL but reads the (possibly coerced) name off of the resource after it is built.
The end result is that the above resource will be named ``some_resource[name_two]`` instead of ``some_resource[name_one]``.  Note that setting the name (*not* the ``name_property``, but actually renaming the resource) is very uncommon.  The fix is to name the resource correctly in the first place (``some_resource name_two do``).

``use_inline_resources`` is always enabled
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The ``use_inline_resources`` provider mode is always enabled when using the ``action :name do `` syntax. You can remove the ``use_inline_resources`` line.

``knife cookbook site vendor`` has been removed
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Please use ``knife cookbook site install`` instead.

``knife cookbook create`` has been removed
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Please use ``chef generate cookbook`` from the ChefDK instead.

Verify commands no longer support "%{file}"
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Chef has always recommended ``%{path}``, and ``%{file}`` has now been removed.

The ``partial_search`` recipe method has been removed
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The ``partial_search`` method has been fully replaced by the ``filter_result`` argument to ``search``, and has now been removed.

The logger and formatter settings are more predictable
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
The default now is the formatter.  There is no more automatic switching to the logger when logging or when output is sent to a pipe.  The logger needs to be specifically requested with ``--force-logger`` or it will not show up.

The ``--force-formatter`` option does still exist, although it will probably be deprecated in the future.

If your logfiles switch to the formatter, you need to include ``--force-logger`` for your daemonized runs.

Redirecting output to a file with ``chef-client > /tmp/chef.out`` now captures the same output as invoking it directly on the command line with no redirection.

Path Sanity disabled by default and modified
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The chef client itself no long modifies its ``ENV['PATH']`` variable directly.  When using the ``shell_out`` API now, in addition to setting up LANG/LANGUAGE/LC_ALL variables that API will also inject certain system paths and the ruby bindir and gemdirs into the PATH (or Path on Windows).
The ``shell_out_with_systems_locale`` API still does not mangle any environment variables.  During the Chef-13 lifecycle changes will be made to prep Chef-14 to switch so that ``shell_out`` by default behaves like ``shell_out_with_systems_locale``. A new flag will get introduced to call ``shell_out(..., internal: [true|false])`` to either get the forced locale and path settings ("internal") or not.  When that is introduced in Chef 13.x the default will be ``true`` (backwards-compat with 13.0) and that default will change in 14.0 to ``false``.

The PATH changes have also been tweaked so that the ruby bindir and gemdir PATHS are prepended instead of appended to the PATH. Some system directories are still appended.

Some examples of changes:

** * ``which ruby`` in 12.x will return any system ruby and fall back to the embedded ruby if using omnibus
** * ``which ruby`` in 13.x will return any system ruby and will not find the embedded ruby if using omnibus
** * ``shell_out_with_systems_locale("which ruby")`` behaves the same as ``which ruby`` above
** * ``shell_out("which ruby")`` in 12.x will return any system ruby and fall back to the embedded ruby if using omnibus
** * ``shell_out("which ruby")`` in 13.x will always return the omnibus ruby first (but will find the system ruby if not using omnibus)

The PATH in ``shell_out`` can also be overridden:

** * ``shell_out("which ruby", env: { "PATH" => nil })`` - behaves like shell_out_with_systems_locale()
** * ``shell_out("which ruby", env: { "PATH" => [...include PATH string here...] })`` - set it arbitrarily however you need

Since most providers which launch custom user commands use ``shell_out_with_systems_locale`` (service, execute, script, etc) the behavior will be that those commands that used to be having embedded omnibus paths injected into them no longer will.
Generally this will fix more problems than it solves, but may causes issues for some use cases.

Default guard clauses (`not_if`/`only_if`) do not change the PATH or other env vars
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
The implementation switched to ``shell_out_with_systems_locale`` to match ``execute`` resource, etc.

Chef Client exits the RFC062 defined exit codes
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Chef Client will only exit with exit codes defined in RFC 062.  This allows other tooling to respond to how a Chef run completes.  Attempting to exit Chef Client with an unsupported exit code (either via ``Chef::Application.fatal!`` or ``Chef::Application.exit!``) will result in an exit code of 1 (GENERIC_FAILURE) and a warning in the event log.

When Chef Client is running as a forked process on unix systems, the standardized exit codes are used by the child process.  To actually have Chef Client return the standard exit code, ``client_fork false`` will need to be set in Chef Client's configuration file.

What's New in 12.20
=====================================================

The following items are new for chef-client 12.20 and/or are changes from previous versions:

Server Enforced Recipe
-----------------------------------------------------
This release adds support for Server Enforced Recipe, as described in `RFC 896 <https://github.com/chef/chef-rfc/blob/master/rfc089-server-enforced-recipe.md>`_ and implemented in Chef server 12.15. Full release documentation of this feature will be coming soon.

Bugfixes
-----------------------------------------------------
Fixes issue where :doc:`resource_apt_repository` couldn't identify key fingerprints when gnupg 2.1.x was used.


What's New in 12.19
=====================================================

The following items are new for chef-client 12.19 and/or are changes from previous versions. The short version:

* **Systemd unit files are now verified before being installed.**
* **Added support for windows alternate user identity in execute resources.**
* **Added ed25519 key support for for ssh connections.**

Windows alternate user identity execute support
-----------------------------------------------------

The ``execute`` resource and similar resources such as ``script``, ``batch``, and ``powershell_script`` now support the specification of credentials on Windows so that the resulting process is created with the security identity that corresponds to those credentials.

**Note**: When Chef is running as a service, this feature requires that the user that Chef runs as has 'SeAssignPrimaryTokenPrivilege' (aka 'SE_ASSIGNPRIMARYTOKEN_NAME') user right. By default only LocalSystem and NetworkService have this right when running as a service. This is necessary even if the user is an Administrator.

This right can be added and checked in a recipe using this example:

.. code-block:: ruby

   # Add 'SeAssignPrimaryTokenPrivilege' for the user
   Chef::ReservedNames::Win32::Security.add_account_right('<user>', 'SeAssignPrimaryTokenPrivilege')

   # Check if the user has 'SeAssignPrimaryTokenPrivilege' rights
   Chef::ReservedNames::Win32::Security.get_account_right('<user>').include?('SeAssignPrimaryTokenPrivilege')

Properties
-----------------------------------------------------

The following properties are new or updated for the ``execute``, ``script``, ``batch``, and ``powershell_script`` resources and any resources derived from them:

``user``
  **Ruby types:** String
  The user name of the user identity with which to launch the new process. Default value: ``nil``. The user name may optionally be specified with a domain, i.e. ``domain\user`` or ``user@my.dns.domain.com`` via Universal Principal Name (UPN) format. It can also be specified without a domain simply as ``user`` if the domain is instead specified using the ``domain`` attribute. On Windows only, if this property is specified, the ``password`` property **must** be specified.

``password``
  **Ruby types** String
  _Windows only:_ The password of the user specified by the ``user`` property. Default value: ``nil``. This property is mandatory if ``user`` is specified on Windows and may only be specified if ``user`` is specified. The ``sensitive`` property for this resource will automatically be set to ``true`` if ``password`` is specified.

``domain``
  **Ruby types** String
  _Windows only:_ The domain of the user user specified by the ``user`` property. Default value: ``nil``. If not specified, the user name and password specified by the ``user`` and ``password`` properties will be used to resolve that user against the domain in which the system running Chef client is joined, or if that system is not joined to a domain it will resolve the user as a local account on that system. An alternative way to specify the domain is to leave this property unspecified and specify the domain as part of the ``user`` property.

Usage
-----------------------------------------------------

The following examples explain how alternate user identity properties can be used in the execute resources:

.. code-block:: ruby

   powershell_script 'create powershell-test file' do
     code <<-EOH
     $stream = [System.IO.StreamWriter] "#{Chef::Config[:file_cache_path]}/powershell-test.txt"
     $stream.WriteLine("In #{Chef::Config[:file_cache_path]}...word.")
     $stream.close()
     EOH
     user 'username'
     password 'password'
   end

   execute 'mkdir test_dir' do
     cwd Chef::Config[:file_cache_path]
     domain "domain-name"
     user "user"
     password "password"
   end

   script 'create test_dir' do
     interpreter "bash"
     code  "mkdir test_dir"
     cwd Chef::Config[:file_cache_path]
     user "domain-name\\username"
     password "password"
   end

   batch 'create test_dir' do
     code "mkdir test_dir"
     cwd Chef::Config[:file_cache_path]
     user "username@domain-name"
     password "password"
   end

Highlighted bug fixes for this release:
-----------------------------------------------------

* **Ensure that the Windows Administrator group can access the chef-solo nodes directory**
* **When loading a cookbook in Chef Solo, use ``metadata.json`` in preference to ``metadata.rb``.**


What's New in 12.18
=====================================================

The following items are new for chef-client 12.18 and/or are changes from previous versions. The short version:

* **Can now specify the acceptable return codes from the chocolatey_package resource using the returns property**
* **Can now enable chef-client to run as a scheduled task directly from the client MSI on Windows hosts**
* **Package provider now supports DNF packages for Fedora and upcoming RHEL releases**

New deprecations included in this release
-----------------------------------------------------
* :doc:`Chef::Platform helper methods </deprecations_chef_platform_methods>`
* :doc:`run_command helper method </deprecations_run_command>`
* :doc:`DNF package allow_downgrade property </deprecations_dnf_package_allow_downgrade>`


What's New in 12.17
=====================================================

The following items are new for chef-client 12.17 and/or are changes from previous versions. The short version:

* **Added msu_package resource and provider**
* **Added alias unmount to umount action for mount resource**
* **Can now delete multiple nodes/clients in knife**
* **Haskell language plugin added to Ohai**

msu_package resource
-----------------------------------------------------

The **msu_package** resource installs or removes Microsoft Update(MSU) packages on Microsoft Windows machines. Here are some examples:

.. tag msu_package_examples

**Using local path in source**

.. code-block:: ruby

   msu_package 'Install Windows 2012R2 Update KB2959977' do
     source 'C:\Users\xyz\AppData\Local\Temp\Windows8.1-KB2959977-x64.msu'
     action :install
   end

.. code-block:: ruby

   msu_package 'Remove Windows 2012R2 Update KB2959977' do
     source 'C:\Users\xyz\AppData\Local\Temp\Windows8.1-KB2959977-x64.msu'
     action :remove
   end

**Using URL in source**

.. code-block:: ruby

   msu_package 'Install Windows 2012R2 Update KB2959977' do
     source 'https://s3.amazonaws.com/my_bucket/Windows8.1-KB2959977-x64.msu'
     action :install
   end

.. code-block:: ruby

   msu_package 'Remove Windows 2012R2 Update KB2959977' do
     source 'https://s3.amazonaws.com/my_bucket/Windows8.1-KB2959977-x64.msu'
     action :remove
   end

.. end_tag

``unmount`` alias for ``umount`` action
-----------------------------------------------------

Now you can use ``action :unmount`` to unmout a mount point through the mount resource. For example:

.. code-block:: ruby

   mount '/mount/tmp' do
     action :unmount
   end

Multiple client/node deletion in knife
-----------------------------------------------------

You can now pass multiple nodes/clients to ``knife node delete`` or ``knife client delete`` subcommands.

.. code-block:: bash

    $ knife client delete client1,client2,client3

Ohai Enhancements
-----------------------------------------------------

**Haskell Language plugin**

Haskell is now detected in a new haskell language plugin:

.. code-block:: javascript

  "languages": {
    "haskell": {
      "stack": {
        "version": "1.2.0",
        "description": "Version 1.2.0 x86_64 hpack-0.14.0"
      }
    }
  }


**LSB Release Detection**

The lsb_release command line tool is now preferred to the contents of ``/etc/lsb-release`` for release detection. This resolves an issue where a distro can be upgraded, but ``/etc/lsb-release`` is not upgraded to reflect the change.


What's New in 12.16
=====================================================

The following items are new for chef-client 12.16 and/or are changes from previous versions. The short version:

* **Added new attribute_changed event hook**
* **Automatic connection to Chef Automate's data collector through Chef server**
* **Added new --field-separator flag to knife show commands**

``attribute_changed`` event hook
-----------------------------------------------------

In a cookbook library file, you can add this in order to print out all attribute changes in cookbooks:

.. code-block:: ruby

   Chef.event_handler do
     on :attribute_changed do |precedence, key, value|
       puts "setting attribute #{precedence}#{key.map {|n| "[\"#{n}\"]" }.join} = #{value}"
     end
   end

If you want to setup a policy that override attributes should never be used:

.. code-block:: ruby

   Chef.event_handler do
     on :attribute_changed do |precedence, key, value|
       raise "override policy violation" if precedence == :override
     end
   end

Automatic connection to Chef Automate's data collector with supported Chef server
----------------------------------------------------------------------------------
Chef client will automatically attempt to connect to the Chef server authenticated data collector proxy. If you have a supported version of Chef
server with this feature enabled, Chef client run data will automatically be forwarded to Chef Automate without additional Chef
client configuration. If you do not have Chef Automate, or the feature is disabled on the Chef server, Chef client will detect this and disable data collection.

.. note:: Chef Server 12.11.0 or newer is required for this feature.

RFC018 Partially Implemented: Specify ``--field-separator`` for attribute filtering
------------------------------------------------------------------------------------

If you have periods (``.``) in your Chef Node attribute keys, you can now pass the ``--field-separator`` (or ``-S``) flag along with your ``--attribute`` (or ``-a``)
flag to specify a custom nesting character other than ``.``.

In a situation where the *webapp* node has the following node data:

.. code-block:: javascript

   {
     "foo.bar": "baz",
     "alpha": {
       "beta": "omega"
     }
   }

Running ``knife node show`` with the default field separator (``.``) won't show us the data we're expecting for the ``foo.bar`` attribute because of the period:

.. code-block:: bash

   $ knife node show webapp -a foo.bar
   webapp:
     foo.bar:

   $ knife node show webapp -a alpha.beta
   webapp:
     alpha.beta: omega

However, by specifying a field separator other than ``.`` we are now able to show the data.

.. code-block:: bash

   $ knife node show webapp -S: -a foo.bar
   webapp:
     foo.bar: baz

   $ knife node show webapp -S: -a alpha:beta
   webapp:
     alpha:beta: omega

Package locking for Apt, Yum, and Zypper
-----------------------------------------------------

To allow for more fine grain control of package installation the ``apt_package``, ``yum_package``, and ``zypper_package`` resources now support the ``:lock`` and ``:unlock`` actions.

.. code-block:: ruby

   package "httpd" do
     action :lock
   end

   package "httpd" do
     action :unlock
   end

What's New in 12.15
=====================================================
The following items are new for chef-client 12.15 and/or are changes from previous versions. The short version:

* **Omnibus packages are now available for Ubuntu 16.04**
* **New cab_package resource** Supports the installation of cabinet packages on Microsoft Windows.
* **Added new Chef client exit code (213)** New exit code when Chef client exits during upgrade.
* **Default for gpgcheck on yum_repository resource is set to true**
* **Allow deletion of registry_key without the need for users to pass data key in values hash**
* **If provided, knife ssh will pass the -P option on the command line as the sudo password and will bypass prompting**

cab_package
-----------------------------------------------------
Supports the installation of cabinet packages on Microsoft Windows. For example:

.. code-block:: ruby

   cab_package 'Install .NET 3.5 sp1 via KB958488' do
     source 'C:\Users\xyz\AppData\Local\Temp\Windows6.1-KB958488-x64.cab'
     action :install
   end

.. code-block:: ruby

   cab_package 'Remove .NET 3.5 sp1 via KB958488' do
     source 'C:\Users\xyz\AppData\Local\Temp\Windows6.1-KB958488-x64.cab'
     action :remove
   end

.. note:: The ``cab_package`` resource does not support URL strings in the source property.

exit code 213
-----------------------------------------------------
This new exit code signals Chef has exited during a client upgrade. This allows for easier testing of chef client upgrades in Test Kitchen.
See `Chef Killing <https://github.com/chef-cookbooks/omnibus_updater#chef-killing>`__ in the omnibus_updater cookbook for more information.

What's New in 12.14
=====================================================
The following items are new for chef-client 12.14 and/or are changes from previous versions. The short version:

* **Upgraded Ruby version from 2.1.9 to 2.3.1** Adds several performance and functionality enhancements.
* **Now support for Chef client runs on Windows Nano Server** A small patch to Ruby 2.3.1 and improvements to the Ohai network plugin now allow you to do chef client runs on Windows Nano Server.
* **New yum_repository resource** Use the **yum_repository** resource to manage a yum repository configuration file.
* **Added the ability to mark a property of a custom resource as sensitive** This will suppress the property's value when it's used in other outputs, such as messages used by the data collector.

yum_repository
-----------------------------------------------------
.. tag resource_yum_repository_summary

Use the **yum_repository** resource to manage a Yum repository configuration file located at ``/etc/yum.repos.d/repositoryid.repo`` on the local machine. This configuration file specifies which repositories to reference, how to handle cached data, etc.

.. end_tag

For syntax, a list of properties and actions, see :doc:`yum_repository </resource_yum_repository>`.

sensitive: true
-----------------------------------------------------
Some properties in custom resources may include sensitive data, such as a password for a database server. When the resource's state is built for use by data collector or a similar auditing tool,
a hash is built of all state properties for that resource and their values. This leads to sensitive data being transmitted and potentially stored in the clear.

Individual properties can now be marked as sensitive and then have the value of that property suppressed when exporting the resource's state. To do this, add ``sensitive: true`` when definine the property, such as in the following example:

.. code-block:: ruby

   property :db_password, String, sensitive: true

What's New in 12.13
=====================================================
The following items are new for chef-client 12.13 and/or are changes from previous versions. The short version:

* **Ohai 8.18 includes new plugin for gathering available user shells** Other additions include a new hardware plugin for macOS that gathers system information and detection of VMWare and VirtualBox installations.
* **New Chef client option to override any config key/value pair** Use ``chef-client --config-option`` to override any config setting from the command line.

--config-option
-----------------------------------------------------
Use the ``--config-option`` option to override a single configuration option when calling a command on ``chef-client``. To override multiple configuration options, simply add additional ``--config-option`` options like in the following example:

.. code-block:: bash

   $ chef-client --config-option chef_server_url=http://example --config-option policy_name=web"

Updated Dependencies
-----------------------------------------------------
* ruby - 2.1.9 (from 2.1.8)

Updated Gems
+++++++++++++++++++++++++++++++++++++++++++++++++++++
* chef-zero - 4.8.0 (from 4.7.0)
* cheffish - 2.0.5 (from 2.0.4)
* compat_resource - 12.10.7 (from 12.10.6)
* ffi - 1.9.14 (from 1.9.10)
* ffi-yajl - 2.3.0 (from 2.2.3)
* fuzzyurl - 0.9.0 (from 0.8.0)
* mixlib-cli - 1.7.0 (from 1.6.0)
* mixlib-log - 1.7.0 (from 1.6.0)
* ohai - 8.18.0 (from 8.17.1)
* pry - 0.10.4 (from 0.10.3)
* rspec - 3.5.0 (from 3.4.0)
* rspec-core - 3.5.2 (from 3.4.4)
* rspec-expectations - 3.5.0 (from 3.4.0)
* rspec-mocks - 3.5.0 (from 3.4.1)
* rspec-support - 3.5.0 (from 3.4.1)
* simplecov - 0.12.0 (from 0.11.2)
* specinfra - 2.60.3 (from 2.59.4)
* mixlib-archive - 0.2.0 (added to package)

What's New in 12.12
=====================================================
The following items are new for chef-client 12.12 and/or are changes from previous versions. The short version:

* **New node attribute APIs** Common set of methods to read, write, delete, and check if node attributes exist.
* **Data collector updates** Minor enhancements to data that the data collector reports on.
* **knife cookbook create has been deprecated** You should use `chef generate cookbook </ctl_chef.html#chef-generate-cookbook>`_ instead.

New node attribute read, write, unlink, and exist? APIs
-----------------------------------------------------------
The four methods ``read``, ``write``, ``unlink``, and ``exist?`` (and their corresponding unsafe versions) can be used on node objects to set, retrieve, delete, and validate existance of attributes.

read/read!
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the ``read`` method to retrieve an attribute value on a node object. It is a safe, non-autovivifying reader that returns ``nil`` if the attribute does not exist.

``node.read("foo", "bar", "baz")`` is equivalent to ``node["foo"]["bar"]["baz"]`` but returns ``nil`` instead of raising an exception when no value is set.

The ``read!`` method is a non-autovivifying reader that also retrieves an attribute value on a node object; however, it will throw a NoMethodError exception if the attribute does not exist.

On the node level, ``node.default.read/read!("foo")`` behaves similarly to ``node.read("foo")``, but only on the default level.

write/write!
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the ``write`` method set an attribute value on a node object. It is a safe, autovivifying writer that replaces intermediate non-hash objects.

``node.write(:default, "foo", "bar", "baz")`` is equivalent to ``node.default["foo"]["bar"] = "baz"``.

The ``write!`` method is also an autovivifying method to set an attribute value on a node object; however, it will throw an NoSuchAttribute exception if there is a non-hash on an intermediate key.

.. note:: There is currently no non-autovivifying writer method for attributes.

On the node level, ``node.default.write/write!("foo", "bar")`` is equivalent to ``node.write/write!(:default, "foo", "bar")``.

unlink/unlink!
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the ``unlink`` method to delete an attribute on a node object. ``nil`` will be returned if the value is not a valid Hash or Array.

The ``unlink!`` method also deletes an attribute on a node object; however, it will throw a NoSuchAttribute exception if the attribute does not exist.

On the node level, ``node.default.unlink/unlink!("foo")`` is equivalent to ``node.unlink/unlink!(:default, "foo")``.

exist?
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the ``exist?`` method to check whether the attribute exists. For example, ``node.exist?("foo", "bar")`` can be used to see if ``node["foo"]["bar"]`` exists.

On the node level, ``node.default.exist?("foo", "bar")`` can be used to see if ``node.default["foo"]["bar"]`` exists.

Depreciated node attribute methods
--------------------------------------------------------
The following methods have been deprecated in this release:

* ``node.set``
* ``node.set_unless``

data_collector updates
-----------------------------------------------------
* Adds ``node`` to the data_collector message.
* ``data_collector`` reports on all resources and not just those that have been processed.

What's New in 12.11
=====================================================
The following items are new for chef-client 12.11 and/or are changes from previous versions. The short version:

* **Support for standard exit codes in Chef client** Standard exit codes are now used by Chef client and should be identical across all OS platforms. New configuration setting ``exit_status`` has been added to specify how Chef client reports non-standard exit codes.
* **New data collector functionality for run statistics** New feature that provides a unified method for sharing statistics about your Chef runs in webhook-like manner.
* **Default chef-solo behavior is equivalent to chef-client local mode** chef-solo now uses chef-client local mode. To use the previous ``chef-solo`` behavior, run in ``chef-solo --legacy-mode``.
* **New systemd_unit resource** Use the **systemd_unit** to manage systemd units.

exit_status
-----------------------------------------------------
When set to ``:enabled``, chef-client will use |url exit codes| for Chef client run status, and any non-standard exit codes will be converted to ``1`` or ``GENERIC_FAILURE``. This setting can also be set to ``:disabled`` which preserves the old behavior of using non-standardized exit codes and skips the deprecation warnings. Default value: ``nil``.

   .. note:: The behavior with the default value consists of a warning on the use of deprecated and non-standard exit codes. In a future release of Chef client, using standardized exit codes will be the default behavior.

Data collector
-----------------------------------------------------
The data collector feature is new to Chef 12.11. It provides a unified method for sharing statistics about your Chef runs in a webhook-like manner. The data collector supports Chef in all its modes: Chef client, Chef solo (commonly referred to as "Chef client local mode"), and Chef solo legacy mode.

To enable the data collector, specify the following settings in your client configuration file:

* ``data_collector.server_url``: Required. The URL to which the Chef client will POST the data collector messages
* ``data_collector.token``: Optional. An token which will be sent in a x-data-collector-token HTTP header which can be used to authenticate the message.
* ``data_collector.mode``: The Chef mode in which the data collector should run. Chef client mode is chef client configured to use Chef server to provide Chef client its resources and artifacts. Chef solo mode is Chef client configured to use a local Chef zero server (``chef-client --local-mode``). This setting also allows you to only enable data collector in Chef solo mode but not Chef client mode. Available options are ``:solo``, ``:client``, or ``:both``. Default is ``:both``.
* ``data_collector.raise_on_failure``: If enabled, Chef will raise an exception and fail to run if the data collector cannot be reached at the start of the Chef run. Defaults to false.
* ``data_collector.organization``: Optional. In Chef solo mode, the organization field in the messages will be set to this value. Default is ``chef_solo``. This field does not apply to Chef client mode.

Replace previous Chef-solo behavior with Chef client local mode
----------------------------------------------------------------
The default operation of chef-solo is now the equivalent to ``chef-client -z`` or ``chef-client --local-mode``, but you can use the previous chef-solo behavior by running in ``chef-solo --legacy-mode``.
As part of this change, environment and role files written in ruby are now fully supported by ``knife upload``.

systemd_unit
------------------------------------------------------
Use the **systemd_unit** resource to create, manage, and run `systemd units <https://www.freedesktop.org/software/systemd/man/systemd.html#Concepts>`_.

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++

A **systemd_unit** resource describes the configuration behavior for systemd units. For example:

.. code-block:: ruby

   systemd_unit 'sysstat-collect.timer' do
     content({
       'Unit' => {
         'Description' => 'Run system activity accounting tool every 10 minutes'
       },
       'Timer' => {
         'OnCalendar' => '*:00/10'
       },
       'Install' => {
         'WantedBy' => 'sysstat.service'
       }
     })
     action [:create, :enable, :start]
   end

The full syntax for all of the properties that are available to the **systemd_unit** resource is:

.. code-block:: ruby

   systemd_unit 'name' do
     user                   String
     content                String or Hash
     triggers_reload        Boolean
   end

where

* ``name`` is the name of the unit
* ``user`` is the user account that systemd units run under. If not specified, systemd units will run under the system account.
* ``content`` describes the behavior of the unit
* ``triggers_reload`` controls if a `daemon-reload` is executed to load the unit

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_systemd_unit_actions

This resource has the following actions:

``:create``
   Create a unit file, if it does not already exist.

``:delete``
   Delete a unit file, if it exists.

``:enable``
   Ensure the unit will be started after the next system boot.

``:disable``
   Ensure the unit will not be started after the next system boot.

``:nothing``
   Default. Do nothing with the unit.

``:mask``
   Ensure the unit will not start, even to satisfy dependencies.

``:unmask``
   Stop the unit from being masked and cause it to start as specified.

``:start``
   Start a unit based in its systemd unit file.

``:stop``
   Stop a running unit.

``:restart``
   Restart a unit.

``:reload``
   Reload the configuration file for a unit.

``:try_restart``
   Try to restart a unit if the unit is running.

``:reload_or_restart``
   For units that are services, this action reloads the configuration of the service without restarting, if possible; otherwise, it will restart the service so the new configuration is applied.

``:reload_or_try_restart``
   For units that are services, this action reloads the configuration of the service without restarting, if possible; otherwise, it will try to restart the service so the new configuration is applied.

.. end_tag

Properties
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_systemd_unit_attributes

This resource has the following properties:

``user``
   **Ruby Type:** String

   The user account that the systemd unit process is run under. The path to the unit for that user would be something like
   ``/etc/systemd/user/sshd.service``. If no user account is specified, the systemd unit will run under a ``system`` account, with the path to the unit being something like ``/etc/systemd/system/sshd.service``.

``content``
   **Ruby Type:** String, Hash

   A string or hash that contains a systemd `unit file <https://www.freedesktop.org/software/systemd/man/systemd.unit.html>`_ definition that describes the properties of systemd-managed entities, such as services, sockets, devices, and so on.

``triggers_reload``
   **Ruby Type:** TrueClass, FalseClass

   Specifies whether to trigger a daemon reload when creating or deleting a unit. Default is true.

``verify``
   **Ruby Type:** TrueClass, FalseClass

   Specifies if the unit will be verified before installation. Systemd can be overly strict when verifying units, so in certain cases it is preferable not to verify the unit. Defaults to true.

.. end_tag

What's New in 12.10
=====================================================
The following items are new for chef-client 12.10 and/or are changes from previous versions. The short version:

* **New layout property for mdadm resource** Use the ``layout`` property to set the RAID5 parity algorithm. Possible values: ``left-asymmetric`` (or ``la``), ``left-symmetric`` (or ``ls``), ``right-asymmetric`` (or ``ra``), or ``right-symmetric`` (or ``rs``).
* **New with_run_context for the Recipe DSL** Use ``with_run_context`` to run resource blocks as part of the root or parent run context.
* **New Recipe DSL methods for declaring, deleting, editing, and finding resources** Use the ``declare_resource``, ``delete_resource``, ``edit_resource``, and ``find_resource`` methods to interact with resources in the resource collection. Use the ``delete_resource!``, ``edit_resource!``, or ``find_resource!`` methods to trigger an exception when the resource is not found in the collection.

with_run_context
-----------------------------------------------------
.. tag dsl_recipe_method_with_run_context

Use the ``with_run_context`` method to define a block that has a pointer to a location in the ``run_context`` hierarchy. Resources in recipes always run at the root of the ``run_context`` hierarchy, whereas custom resources and notification blocks always build a child ``run_context`` which contains their sub-resources.

The syntax for the ``with_run_context`` method is as follows:

.. code-block:: ruby

   with_run_context :type do
     # some arbitrary pure Ruby stuff goes here
   end

where ``:type`` may be one of the following:

* ``:root`` runs the block as part of the root ``run_context`` hierarchy
* ``:parent`` runs the block as part of the parent process in the ``run_context`` hierarchy

For example:

.. code-block:: ruby

   action :run do
     with_run_context :root do
       edit_resource(:my_thing, "accumulated state") do
         action :nothing
         my_array_property << accumulate_some_stuff
       end
     end
     log "kick it off" do
       notifies :run, "my_thing[accumulated state], :delayed
     end
   end

.. end_tag

declare_resource
-----------------------------------------------------
.. tag dsl_recipe_method_declare_resource

Use the ``declare_resource`` method to instantiate a resource and then add it to the resource collection.

The syntax for the ``declare_resource`` method is as follows:

.. code-block:: ruby

   declare_resource(:resource_type, 'resource_name', resource_attrs_block)

where:

* ``:resource_type`` is the resource type, such as ``:file ``(for the **file** resource), ``:template`` (for the **template** resource), and so on. Any resource available to Chef may be declared.
* ``resource_name`` the property that is the default name of the resource, typically the string that appears in the ``resource 'name' do`` block of a resource (but not always); see the Syntax section for the resource to be declared to verify the default name property.
* ``resource_attrs_block`` is a block in which properties of the instantiated resource are declared.

For example:

.. code-block:: ruby

   declare_resource(:file, '/x/y.txy', caller[0]) do
     action :delete
   end

is equivalent to:

.. code-block:: ruby

   file '/x/y.txt' do
     action :delete
   end

New in Chef Client 12.10.

.. end_tag

delete_resource
-----------------------------------------------------
.. tag dsl_recipe_method_delete_resource

Use the ``delete_resource`` method to find a resource in the resource collection, and then delete it.

The syntax for the ``delete_resource`` method is as follows:

.. code-block:: ruby

   delete_resource(:resource_type, 'resource_name')

where:

* ``:resource_type`` is the resource type, such as ``:file ``(for the **file** resource), ``:template`` (for the **template** resource), and so on. Any resource available to Chef may be declared.
* ``resource_name`` the property that is the default name of the resource, typically the string that appears in the ``resource 'name' do`` block of a resource (but not always); see the Syntax section for the resource to be declared to verify the default name property.

For example:

.. code-block:: ruby

   delete_resource(:template, '/x/y.erb')

New in Chef Client 12.10.

.. end_tag

delete_resource!
-----------------------------------------------------
.. tag dsl_recipe_method_delete_resource_bang

Use the ``delete_resource!`` method to find a resource in the resource collection, and then delete it. If the resource is not found, an exception is returned.

The syntax for the ``delete_resource!`` method is as follows:

.. code-block:: ruby

delete_resource!(:resource_type, 'resource_name')

where:

* ``:resource_type`` is the resource type, such as ``:file ``(for the **file** resource), ``:template`` (for the **template** resource), and so on. Any resource available to Chef may be declared.
* ``resource_name`` the property that is the default name of the resource, typically the string that appears in the ``resource 'name' do`` block of a resource (but not always); see the Syntax section for the resource to be declared to verify the default name property.

For example:

.. code-block:: ruby

   delete_resource!(:file, '/x/file.txt')

New in Chef Client 12.10.

.. end_tag

edit_resource
-----------------------------------------------------
.. tag dsl_recipe_method_edit_resource

Use the ``edit_resource`` method to:

* Find a resource in the resource collection, and then edit it.
* Define a resource block. If a resource block with the same name exists in the resource collection, it will be updated with the contents of the resource block defined by the ``edit_resource`` method. If a resource block does not exist in the resource collection, it will be created.

The syntax for the ``edit_resource`` method is as follows:

.. code-block:: ruby

   edit_resource(:resource_type, 'resource_name', resource_attrs_block)

where:

* ``:resource_type`` is the resource type, such as ``:file`` (for the **file** resource), ``:template`` (for the **template** resource), and so on. Any resource available to Chef may be declared.
* ``resource_name`` the property that is the default name of the resource, typically the string that appears in the ``resource 'name' do`` block of a resource (but not always); see the Syntax section for the resource to be declared to verify the default name property.
* ``resource_attrs_block`` is a block in which properties of the instantiated resource are declared.

For example:

.. code-block:: ruby

   edit_resource(:template, '/x/y.txy') do
     cookbook_name: cookbook_name
   end

and a resource block:

.. code-block:: ruby

   edit_resource(:template, '/etc/aliases') do
     source 'aliases.erb'
     cookbook 'aliases'
     variables({:aliases => {} })
     notifies :run, 'execute[newaliases]'
   end

New in Chef Client 12.10.

.. end_tag

edit_resource!
-----------------------------------------------------
.. tag dsl_recipe_method_edit_resource_bang

Use the ``edit_resource!`` method to:

* Find a resource in the resource collection, and then edit it.
* Define a resource block. If a resource with the same name exists in the resource collection, its properties will be updated with the contents of the resource block defined by the ``edit_resource`` method.

In both cases, if the resource is not found, an exception is returned.

The syntax for the ``edit_resource!`` method is as follows:

.. code-block:: ruby

   edit_resource!(:resource_type, 'resource_name')

where:

* ``:resource_type`` is the resource type, such as ``:file ``(for the **file** resource), ``:template`` (for the **template** resource), and so on. Any resource available to Chef may be declared.
* ``resource_name`` the property that is the default name of the resource, typically the string that appears in the ``resource 'name' do`` block of a resource (but not always); see the Syntax section for the resource to be declared to verify the default name property.
* ``resource_attrs_block`` is a block in which properties of the instantiated resource are declared.

For example:

.. code-block:: ruby

   edit_resource!(:file, '/x/y.rst')

New in Chef Client 12.10.

.. end_tag

find_resource
-----------------------------------------------------
.. tag dsl_recipe_method_find_resource

Use the ``find_resource`` method to:

* Find a resource in the resource collection.
* Define a resource block. If a resource block with the same name exists in the resource collection, it will be returned. If a resource block does not exist in the resource collection, it will be created.

The syntax for the ``find_resource`` method is as follows:

.. code-block:: ruby

   find_resource(:resource_type, 'resource_name')

where:

* ``:resource_type`` is the resource type, such as ``:file ``(for the **file** resource), ``:template`` (for the **template** resource), and so on. Any resource available to Chef may be declared.
* ``resource_name`` the property that is the default name of the resource, typically the string that appears in the ``resource 'name' do`` block of a resource (but not always); see the Syntax section for the resource to be declared to verify the default name property.

For example:

.. code-block:: ruby

   find_resource(:template, '/x/y.txy')

and a resource block:

.. code-block:: ruby

   find_resource(:template, '/etc/seapower') do
     source 'seapower.erb'
     cookbook 'seapower'
     variables({:seapower => {} })
     notifies :run, 'execute[newseapower]'
   end

New in Chef Client 12.10.

.. end_tag

find_resource!
-----------------------------------------------------
.. tag dsl_recipe_method_find_resource_bang

Use the ``find_resource!`` method to find a resource in the resource collection. If the resource is not found, an exception is returned.

The syntax for the ``find_resource!`` method is as follows:

.. code-block:: ruby

   find_resource!(:resource_type, 'resource_name')

where:

* ``:resource_type`` is the resource type, such as ``:file ``(for the **file** resource), ``:template`` (for the **template** resource), and so on. Any resource available to Chef may be declared.
* ``resource_name`` the property that is the default name of the resource, typically the string that appears in the ``resource 'name' do`` block of a resource (but not always); see the Syntax section for the resource to be declared to verify the default name property.

For example:

.. code-block:: ruby

   find_resource!(:template, '/x/y.erb')

New in Chef Client 12.10.

.. end_tag

What's New in 12.9
=====================================================
The following items are new for chef-client 12.9 and/or are changes from previous versions. The short version:

* **New apt_repository resource**
* **64-bit chef-client for Microsoft Windows** Starting with chef-client 12.9, 64-bit
* **New property for the mdadm resource** Use the ``mdadm_defaults`` property to set the default values for ``chunk`` and ``metadata`` to ``nil``, which allows mdadm to apply its own default values.
* **File redirection in Windows for 32-bit applications** Files on Microsoft Windows that are managed by the **file** and **directory** resources are subject to file redirection, depending if the chef-client is 64-bit or 32-bit.
* **Registry key redirection in Windows for 32-bit applications** Registry keys on Microsoft Windows that are managed by the **registry_key** resource are subject to key redirection, depending if the chef-client is 64-bit or 32-bit.
* **New values for log_location** Use ``:win_evt`` to write log output to the (Windows Event Logger and ``:syslog`` to write log output to the syslog daemon facility with the originator set as ``chef-client``.
* **New timeout setting for knife ssh** Set the ``--ssh-timeout`` setting to an integer (in seconds) as part of a ``knife ssh`` command. The ``ssh_timeout`` setting may also be configured (as seconds) in the knife.rb file.
* **New "seconds to wait before first chef-client run" setting** The ``-daemonized`` option for the chef-client now allows the seconds to wait before starting the chef-client run to be specified. For example, if ``--daemonize 10`` is specified, the chef-client will wait ten seconds.

apt_repository resource
-----------------------------------------------------

The apt_repository resource, previously available in the apt cookbook, is now included in chef-client. With this change you will no longer need to depend on the apt cookbook to use the apt_repository resource.

64-bit chef-client
-----------------------------------------------------
The chef-client now runs on 64-bit Microsoft Windows operating systems.

* Support for file redirection
* Support for key redirection

File Redirection
+++++++++++++++++++++++++++++++++++++++++++++++++++++
64-bit versions of Microsoft Windows have a 32-bit compatibility layer that redirects attempts by 32-bit application to access the ``System32`` directory to a different location. Starting with chef-client version 12.9, the 32-bit version of the chef-client is subject to the file redirection policy.

For example, consider the following script:

.. code-block:: ruby

   process_type = ENV['PROCESSOR_ARCHITECTURE'] == 'AMD64' ? '64-bit' : '32-bit'
   system32_dir = ::File.join(ENV['SYSTEMROOT'], 'system32')
   test_dir = ::File.join(system32_dir, 'cheftest')
   test_file = ::File.join(test_dir, 'chef_architecture.txt')

   directory test_dir do
     # some directory
   end

   file test_file do
     content "Chef made me, I come from a #{process_type} process."
   end

When running a 32-bit version of chef-client, the script will write the ``chef_architecture`` file to the ``C:\Windows\SysWow64`` directory. However, when running a native 64-bit version of the chef-client, the script will write a file to the ``C:\Windows\System32`` directory, as expected.

For more information, see: |url msdn_file_redirection|.

Key Redirection
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag notes_registry_key_redirection

64-bit versions of Microsoft Windows have a 32-bit compatibility layer in the registry that reflects and redirects certain keys (and their values) into specific locations (or logical views) of the registry hive.

The chef-client can access any reflected or redirected registry key. The machine architecture of the system on which the chef-client is running is used as the default (non-redirected) location. Access to the ``SysWow64`` location is redirected must be specified. Typically, this is only necessary to ensure compatibility with 32-bit applications that are running on a 64-bit operating system.

32-bit versions of the chef-client (12.8 and earlier) and 64-bit versions of the chef-client (12.9 and later) generally behave the same in this situation, with one exception: it is only possible to read and write from a redirected registry location using chef-client version 12.9 (and later).

For more information, see: |url msdn_registry_key|.

.. end_tag

What's New in 12.8
=====================================================
The following items are new for chef-client 12.8 and/or are changes from previous versions. The short version:

* **Support for OpenSSL validation of FIPS** The chef-client can be configured to allow OpenSSL to enforce FIPS-validated security during a chef-client run.
* **Support for multiple configuration files** The chef-client supports reading multiple configuration files by putting them inside a ``.d`` configuration directory.
* **New launchd resource** Use the **launchd** resource to manage system-wide services (daemons) and per-user services (agents) on the macOS platform.
* **chef-zero support for Chef Server API endpoints** chef-zero now supports using all Chef server API version 12 endpoints, with the exception of ``/universe``.
* **Updated support for OpenSSL** OpenSSL is updated to version 1.0.1.
* **Ohai auto-detects hosts for Azure instances** Ohai will auto-detect hosts for instances that are hosted by Microsoft Azure.
* **gem attribute added to metadata.rb** Specify a gem dependency to be installed via the **chef_gem** resource after all cookbooks are synchronized, but before any other cookbook loading is done.

FIPS Mode
-----------------------------------------------------
.. tag fips_intro_client

Federal Information Processing Standards (FIPS) is a United States government computer security standard that specifies security requirements for cryptography. The current version of the standard is FIPS 140-2. The chef-client can be configured to allow OpenSSL to enforce FIPS-validated security during a chef-client run. This will disable cryptography that is explicitly disallowed in FIPS-validated software, including certain ciphers and hashing algorithms. Any attempt to use any disallowed cryptography will cause the chef-client to throw an exception during a chef-client run.

.. note:: Chef uses MD5 hashes to uniquely identify files that are stored on the Chef server. MD5 is used only to generate a unique hash identifier and is not used for any cryptographic purpose.

Notes about FIPS:

* May be enabled for nodes running on Microsoft Windows and Enterprise Linux platforms
* Should only be enabled for environments that require FIPS 140-2 compliance
* May not be enabled for any version of the chef-client earlier than 12.8

Changed in Chef server 12.13 to expose FIPS runtime flag on RHEL. New in Chef Client 12.8, support for OpenSSL validation of FIPS.

.. end_tag

Enable FIPS Mode
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Allowing OpenSSL to enforce FIPS-validated security may be enabled by using any of the following ways:

* Set the ``fips`` configuration setting to ``true`` in the client.rb or knife.rb files
* Set the ``--fips`` command-line option when running any knife command or the chef-client executable
* Set the ``--fips`` command-line option when bootstrapping a node using the ``knife bootstrap`` command

Command Option
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following command-line option may be used to with a knife or chef-client executable command:

``--[no-]fips``
  Allows OpenSSL to enforce FIPS-validated security during the chef-client run.

**Bootstrap a node using FIPS**

.. tag knife_bootstrap_node_fips

.. To bootstrap a node:

.. code-block:: bash

   $ knife bootstrap 12.34.56.789 -P vanilla -x root -r 'recipe[apt],recipe[xfs],recipe[vim]' --fips

which shows something similar to:

.. code-block:: none

   OpenSSL FIPS 140 mode enabled
   ...
   12.34.56.789 Chef Client finished, 12/12 resources updated in 78.942455583 seconds

.. end_tag

Configuration Setting
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following configuration setting may be set in the knife.rb, client.rb, or config.rb files:

``fips``
  Allows OpenSSL to enforce FIPS-validated security during the chef-client run. Set to ``true`` to enable FIPS-validated security.

.d Directories
-----------------------------------------------------
.. tag config_rb_client_dot_d_directories

The chef-client supports reading multiple configuration files by putting them inside a ``.d`` configuration directory. For example: ``/etc/chef/client.d``. All files that end in ``.rb`` in the ``.d`` directory are loaded; other non-``.rb`` files are ignored.

``.d`` directories may exist in any location where the ``client.rb``, ``config.rb``, or ``solo.rb`` files are present, such as:

* ``/etc/chef/client.d``
* ``/etc/chef/config.d``
* ``~/chef/solo.d``

(There is no support for a ``knife.d`` directory; use ``config.d`` instead.)

For example, when using knife, the following configuration files would be loaded:

* ``~/.chef/config.rb``
* ``~/.chef/config.d/company_settings.rb``
* ``~/.chef/config.d/ec2_configuration.rb``
* ``~/.chef/config.d/old_settings.rb.bak``

The ``old_settings.rb.bak`` file is ignored because it's not a configuration file. The ``config.rb``, ``company_settings.rb``, and ``ec2_configuration`` files are merged together as if they are a single configuration file.

.. note:: If multiple configuration files exists in a ``.d`` directory, ensure that the same setting has the same value in all files.

New in Chef Client 12.8.

.. end_tag

launchd
-----------------------------------------------------
.. tag resource_launchd_summary

Use the **launchd** resource to manage system-wide services (daemons) and per-user services (agents) on the macOS platform.

.. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_launchd_syntax_12_8

A **launchd** resource manages system-wide services (daemons) and per-user services (agents) on the macOS platform:

.. code-block:: ruby

   launchd 'call.mom.weekly' do
     program '/Library/scripts/call_mom.sh'
     start_calendar_interval 'Weekday' => 7, 'Hourly' => 10
     time_out 300
   end

The full syntax for all of the properties that are available to the **launchd** resource is:

.. code-block:: ruby

   launchd 'name' do
     abandon_process_group      TrueClass, FalseClass
     backup                     Integer, FalseClass
     cookbook                   String
     debug                      TrueClass, FalseClass
     disabled                   TrueClass, FalseClass
     enable_globbing            TrueClass, FalseClass
     enable_transactions        TrueClass, FalseClass
     environment_variables      Hash
     exit_timeout               Integer
     group                      String, Integer
     hard_resource_limits       Hash
     hash                       Hash
     ignore_failure             TrueClass, FalseClass
     inetd_compatibility        Hash
     init_groups                TrueClass, FalseClass
     keep_alive                 TrueClass, FalseClass
     label                      String
     launch_only_once           TrueClass, FalseClass
     limit_load_from_hosts      Array
     limit_load_to_hosts        Array
     limit_load_to_session_type String
     low_priority_io            TrueClass, FalseClass
     mach_services              Hash
     mode                       Integer, String
     nice                       Integer
     notifies                   # see description
     on_demand                  TrueClass, FalseClass
     owner                      Integer, String
     path                       String
     process_type               String
     program                    String
     program_arguments          Array
     provider                   Chef::Provider::Launchd
     queue_directories          Array
     retries                    Integer
     retry_delay                Integer
     root_directory             String
     run_at_load                TrueClass, FalseClass
     sockets                    Hash
     soft_resource_limits       Array
     standard_error_path        String
     standard_in_path           String
     standard_out_path          String
     start_calendar_interval    Hash
     start_interval             Integer
     start_on_mount             TrueClass, FalseClass
     subscribes                 # see description
     throttle_interval          Integer
     time_out                   Integer
     type                       String
     umask                      Integer
     username                   String
     wait_for_debugger          TrueClass, FalseClass
     watch_paths                Array
     working_directory          String
     action                     Symbol # defaults to :create if not specified
   end

where

* ``launchd`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``abandon_process_group``, ``backup``, ``cookbook``, ``debug``, ``disabled``, ``enable_globbing``, ``enable_transactions``, ``environment_variables``, ``exit_timeout``, ``group``, ``hard_resource_limits``, ``hash``, ``inetd_compatibility``, ``init_groups``, ``keep_alive``, ``label``, ``launch_only_once``, ``limit_load_from_hosts``, ``limit_load_to_hosts``, ``limit_load_to_session_type``, ``low_priority_io``, ``mach_services``, ``mode``, ``nice``, ``on_demand``, ``owner``, ``path``, ``process_type``, ``program``, ``program_arguments``, ``queue_directories``, ``retries``, ``retry_delay``, ``root_directory``, ``run_at_load``, ``sockets``, ``soft_resource_limits``, ``standard_error_path``, ``standard_in_path``, ``standard_out_path``, ``start_calendar_interval``, ``start_interval``, ``start_on_mount``, ``throttle_interval``, ``time_out``, ``type``, ``umask``, ``username``, ``wait_for_debugger``, ``watch_paths``, and ``working_directory`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_launchd_actions

This resource has the following actions:

``:create``
   Default. Create a launchd property list.

``:create_if_missing``
   Create a launchd property list, if it does not already exist.

``:delete``
   Delete a launchd property list. This will unload a daemon or agent, if loaded.

``:disable``
   Disable a launchd property list.

``:enable``
   Create a launchd property list, and then ensure that it is enabled. If a launchd property list already exists, but does not match, updates the property list to match, and then restarts the daemon or agent.

``:restart``
   Restart a launchd managed daemon or agent.

.. end_tag

Properties
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_launchd_attributes_12_8

This resource has the following properties:

``backup``
   **Ruby Types:** Integer, FalseClass

   The number of backups to be kept in ``/var/chef/backup``. Set to ``false`` to prevent backups from being kept.

``cookbook``
   **Ruby Type:** String

   The name of the cookbook in which the source files are located.

``group``
   **Ruby Types:** String, Integer

   When launchd is run as the root user, the group to run the job as. If the ``username`` property is specified and this property is not, this value is set to the default group for the user.

``hash``
   **Ruby Type:** Hash

   A Hash of key value pairs used to create the launchd property list.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``label``
   **Ruby Type:** String

   The unique identifier for the job.

``mode``
   **Ruby Types:** Integer, String

   A quoted 3-5 character string that defines the octal mode. For example: ``'755'``, ``'0755'``, or ``00755``. If ``mode`` is not specified and if the directory already exists, the existing mode on the directory is used. If ``mode`` is not specified, the directory does not exist, and the ``:create`` action is specified, the chef-client assumes a mask value of ``'0777'``, and then applies the umask for the system on which the directory is to be created to the ``mask`` value. For example, if the umask on a system is ``'022'``, the chef-client uses the default value of ``'0755'``.

   The behavior is different depending on the platform.

   UNIX- and Linux-based systems: A quoted 3-5 character string that defines the octal mode that is passed to chmod. For example: ``'755'``, ``'0755'``, or ``00755``. If the value is specified as a quoted string, it works exactly as if the ``chmod`` command was passed. If the value is specified as an integer, prepend a zero (``0``) to the value to ensure that it is interpreted as an octal number. For example, to assign read, write, and execute rights for all users, use ``'0777'`` or ``'777'``; for the same rights, plus the sticky bit, use ``01777`` or ``'1777'``.

   Microsoft Windows: A quoted 3-5 character string that defines the octal mode that is translated into rights for Microsoft Windows security. For example: ``'755'``, ``'0755'``, or ``00755``. Values up to ``'0777'`` are allowed (no sticky bits) and mean the same in Microsoft Windows as they do in UNIX, where ``4`` equals ``GENERIC_READ``, ``2`` equals ``GENERIC_WRITE``, and ``1`` equals ``GENERIC_EXECUTE``. This property cannot be used to set ``:full_control``. This property has no effect if not specified, but when it and ``rights`` are both specified, the effects are cumulative.

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

``owner``
   **Ruby Types:** Integer, String

   A string or ID that identifies the group owner by user name, including fully qualified user names such as ``domain\user`` or ``user@domain``. If this value is not specified, existing owners remain unchanged and new owner assignments use the current user (when necessary).

``path``
   **Ruby Type:** String

   The path to the directory. Using a fully qualified path is recommended, but is not always required. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``provider``
   **Ruby Type:** Chef::Provider::Launchd

   Optional. Explicitly specifies a provider. See "Providers" section below for more information.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``session_type``
   **Ruby Type:** String

   The type of launchd plist to be created. Possible values: ``system`` (default) or ``user``.

``source``
   **Ruby Type:** String

   The path to the launchd property list.

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

``supports``
   **Ruby Type:** Array

   An array of options for supported mount features. Default value: ``{ :remount => false }``.

``type``
   **Ruby Type:** String

   The type of resource. Possible values: ``daemon`` (default), ``agent``.

The following resource properties may be used to define keys in the XML property list for a daemon or agent. Please refer to the Apple man page documentation for launchd for more information about these keys:

``abandon_process_group``
   **Ruby Types:** TrueClass, FalseClass

   If a job dies, all remaining processes with the same process ID may be kept running. Set to ``true`` to kill all remaining processes.

``debug``
   **Ruby Types:** TrueClass, FalseClass

   Sets the log mask to ``LOG_DEBUG`` for this job.

``disabled``
   **Ruby Types:** TrueClass, FalseClass

   Hints to ``launchctl`` to not submit this job to launchd. Default value: ``false``.

``enable_globbing``
   **Ruby Types:** TrueClass, FalseClass

   Update program arguments before invocation.

``enable_transactions``
   **Ruby Types:** TrueClass, FalseClass

   Track in-progress transactions; if none, then send the ``SIGKILL`` signal.

``environment_variables``
   **Ruby Type:** Hash

   Additional environment variables to set before running a job.

``exit_timeout``
   **Ruby Type:** Integer

   The amount of time (in seconds) launchd waits before sending a ``SIGKILL`` signal. Default value: ``20``.

``hard_resource_limits``
   **Ruby Type:** Hash

   A Hash of resource limits to be imposed on a job.

``inetd_compatibility``
   **Ruby Type:** Hash

   Specifies if a daemon expects to be run as if it were launched from ``inetd``. Set to ``wait => true`` to pass standard input, output, and error file descriptors. Set to ``wait => false`` to call the ``accept`` system call on behalf of the job, and then pass standard input, output, and error file descriptors.

``init_groups``
   **Ruby Types:** TrueClass, FalseClass

   Specify if ``initgroups`` is called before running a job. Default value: ``true`` (starting with macOS 10.5).

``keep_alive``
   **Ruby Types:** TrueClass, FalseClass, Hash

   Keep a job running continuously (``true``) or allow demand and conditions on the node to determine if the job keeps running (``false``). Default value: ``false``.

   Hash type was added in Chef client 12.14.

``launch_only_once``
   **Ruby Types:** TrueClass, FalseClass

   Specify if a job can be run only one time. Set this value to ``true`` if a job cannot be restarted without a full machine reboot.

``limit_load_from_hosts``
   **Ruby Type:** Array

   An array of hosts to which this configuration file does not apply, i.e. "apply this configuration file to all hosts not specified in this array".

``limit_load_to_hosts``
   **Ruby Type:** Array

   An array of hosts to which this configuration file applies.

``limit_load_to_session_type``
   **Ruby Type:** String

   The session type to which this configuration file applies.

``low_priority_io``
   **Ruby Types:** TrueClass, FalseClass

   Specify if the kernel on the node should consider this daemon to be low priority during file system I/O.

``mach_services``
   **Ruby Type:** Hash

   Specify services to be registered with the bootstrap subsystem.

``nice``
   **Ruby Type:** Integer

   The program scheduling priority value in the range ``-20`` to ``20``.

``on_demand``
   **Ruby Types:** TrueClass, FalseClass

   Keep a job alive. Only applies to macOS version 10.4 (and earlier); use ``keep_alive`` instead for newer versions.

``process_type``
   **Ruby Type:** String

   The intended purpose of the job: ``Adaptive``, ``Background``, ``Interactive``, or ``Standard``.

``program``
   **Ruby Type:** String

   The first argument of ``execvp``, typically the file name associated with the file to be executed. This value must be specified if ``program_arguments`` is not specified, and vice-versa.

``program_arguments``
   **Ruby Type:** Array

   The second argument of ``execvp``. If ``program`` is not specified, this property must be specified and will be handled as if it were the first argument.

``queue_directories``
   **Ruby Type:** Array

   An array of non-empty directories which, if any are modified, will cause a job to be started.

``root_directory``
   **Ruby Type:** String

   ``chroot`` to this directory, and then run the job.

``run_at_load``
   **Ruby Types:** TrueClass, FalseClass

   Launch a job once (at the time it is loaded). Default value: ``false``.

``sockets``
   **Ruby Type:** Hash

   A Hash of on-demand sockets that notify launchd when a job should be run.

``soft_resource_limits``
   **Ruby Type:** Array

   A Hash of resource limits to be imposed on a job.
``standard_error_path``
   **Ruby Type:** String

   The file to which standard error (``stderr``) is sent.

``standard_in_path``
   **Ruby Type:** String

   The file to which standard input (``stdin``) is sent.

``standard_out_path``
   **Ruby Type:** String

   The file to which standard output (``stdout``) is sent.

``start_calendar_interval``
   **Ruby Type:** Hash

   A Hash (similar to ``crontab``) that defines the calendar frequency at which a job is started. For example: ``{ Minute => "0", Hour => "20", Day => "*", Weekday => "1-5", Month => "*" }`` will run a job at 8:00 PM every day, Monday through Friday, every month of the year.

``start_interval``
   **Ruby Type:** Integer

   The frequency (in seconds) at which a job is started.

``start_on_mount``
   **Ruby Types:** TrueClass, FalseClass

   Start a job every time a file system is mounted.

``throttle_interval``
   **Ruby Type:** Integer

   The frequency (in seconds) at which jobs are allowed to spawn. Default value: ``10``.

``time_out``
   **Ruby Type:** Integer

   The amount of time (in seconds) a job may be idle before it times out. If no value is specified, the default timeout value for launchd will be used.

``umask``
   **Ruby Type:** Integer

   A decimal value to pass to ``umask`` before running a job.

``username``
   **Ruby Type:** String

   When launchd is run as the root user, the user to run the job as.

``wait_for_debugger``
   **Ruby Types:** TrueClass, FalseClass

   Specify if launchd has a job wait for a debugger to attach before executing code.

``watch_paths``
   **Ruby Type:** Array

   An array of paths which, if any are modified, will cause a job to be started.

``working_directory``
   **Ruby Type:** String

   ``chdir`` to this directory, and then run the job.

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**Create a Launch Daemon from a cookbook file**

.. tag resource_launchd_create_from_cookbook

.. Create a Launch Daemon from a cookbook file:

.. code-block:: ruby

   launchd 'com.chef.every15' do
     source 'com.chef.every15.plist'
   end

.. end_tag

**Create a Launch Daemon using keys**

.. tag resource_launchd_create_using_keys

.. Create a Launch Daemon using keys**

.. code-block:: ruby

   launchd 'call.mom.weekly' do
     program '/Library/scripts/call_mom.sh'
     start_calendar_interval 'Weekday' => 7, 'Hourly' => 10
     time_out 300
   end

.. end_tag

**Remove a Launch Daemon**

.. tag resource_launchd_remove

.. Remove a Launch Daemon:

.. code-block:: ruby

   launchd 'com.chef.every15' do
     action :delete
   end

.. end_tag

gem, metadata.rb
-----------------------------------------------------
.. tag config_rb_metadata_settings_gem

Specifies a gem dependency to be installed via the **chef_gem** resource after all cookbooks are synchronized, but before any other cookbook loading is done. Use this attribute once per gem dependency. For example:

.. code-block:: ruby

   gem "poise"
   gem "chef-sugar"
   gem "chef-provisioning"

New in Chef Client 12.8.

.. end_tag

What's New in 12.7
=====================================================
The following items are new for chef-client 12.7 and/or are changes from previous versions. The short version:

* **Chef::REST => require 'chef/rest'** Internal API calls are moved from ``Chef::REST`` to ``Chef::ServerAPI``. Any code that uses ``Chef::REST`` must use ``require 'chef/rest'``.
* **New chocolatey_package resource** Use the **chocolatey_package** resource to manage packages using Chocolatey for the Microsoft Windows platform.
* **New osx_profile resource** Use the **osx_profile** resource to manage configuration profiles (``.mobileconfig`` files) on the macOS platform.
* **New apt_update resource** Use the **apt_update** resource to manage Apt repository updates on Debian and Ubuntu platforms.
* **Improved support for UTF-8** The chef-client 12.7 release fixes a UTF-8 handling bug present in chef-client versions 12.4, 12.5, and 12.6.
* **New options for the chef-client** The chef-client has a new option: ``--delete-entire-chef-repo``.
* **Multi-package support for Chocolatey and Zypper** A resource may specify multiple packages and/or versions for platforms that use Zypper or Chocolatey package managers (in addition to the edtaxisting support for specifying multiple packages for Yum and Apt packages).

Chef::REST => require 'chef/rest'
-----------------------------------------------------
Internal API calls are moved from ``Chef::REST`` to ``Chef::ServerAPI``. As a result of this move, ``Chef::REST`` is no longer globally required. Any code that uses ``Chef::REST`` must be required as follows:

.. code-block:: ruby

   require 'chef/rest'

For code that is run using knife or chef command line interfaces, consider using ``Chef::ServerAPI`` instead.

chocolatey_package
-----------------------------------------------------
.. tag resource_package_chocolatey

Use the **chocolatey_package** resource to manage packages using Chocolatey for the Microsoft Windows platform.

.. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_chocolatey_syntax_12_7

A **chocolatey_package** resource block manages packages using Chocolatey for the Microsoft Windows platform. The simplest use of the **chocolatey_package** resource is:

.. code-block:: ruby

   chocolatey_package 'package_name'

which will install the named package using all of the default options and the default action (``:install``).

The full syntax for all of the properties that are available to the **chocolatey_package** resource is:

.. code-block:: ruby

   chocolatey_package 'name' do
     notifies                   # see description
     options                    String
     package_name               String, Array # defaults to 'name' if not specified
     provider                   Chef::Provider::Package::Chocolatey
     source                     String
     subscribes                 # see description
     timeout                    String, Integer
     version                    String, Array
     action                     Symbol # defaults to :install if not specified
   end

where

* ``chocolatey_package`` tells the chef-client to manage a package
* ``'name'`` is the name of the package
* ``action`` identifies which steps the chef-client will take to bring the node into the desired state
* ``options``, ``package_name``, ``provider``, ``source``, ``timeout``, and ``version`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_chocolatey_actions

This resource has the following actions:

``:install``
   Default. Install a package. If a version is specified, install the specified version of the package.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:purge``
   Purge a package. This action typically removes the configuration files as well as the package.

``:reconfig``
   Reconfigure a package. This action requires a response file.

``:remove``
   Remove a package.

``:uninstall``
   Uninstall a package.

``:upgrade``
   Install a package and/or ensure that a package is the latest version.

.. end_tag

Properties
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_chocolatey_attributes_12_7

This resource has the following properties:

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

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

``options``
   **Ruby Type:** String

   One (or more) additional options that are passed to the command.

``package_name``
   **Ruby Types:** String, Array

   The name of the package. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider. See "Providers" section below for more information.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``source``
   **Ruby Type:** String

   Optional. The path to a package in the local file system.

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

``timeout``
   **Ruby Types:** String, Integer

   The amount of time (in seconds) to wait before timing out.

``version``
   **Ruby Types:** String, Array

   The version of a package to be installed or upgraded.

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**Install a package**

.. tag resource_chocolatey_package_install

.. To install a package:

.. code-block:: ruby

   chocolatey_package 'name of package' do
     action :install
   end

.. end_tag

osx_profile
-----------------------------------------------------
.. tag resource_osx_profile_summary

Use the **osx_profile** resource to manage configuration profiles (``.mobileconfig`` files) on the macOS platform. The **osx_profile** resource installs profiles by using the ``uuidgen`` library to generate a unique ``ProfileUUID``, and then using the ``profiles`` command to install the profile on the system.

.. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_osx_profile_syntax

A **osx_profile** resource block manages configuration profiles on the macOS platform:

.. code-block:: ruby

   osx_profile 'Install screensaver profile' do
     profile 'com.company.screensaver.mobileconfig'
   end

The full syntax for all of the properties that are available to the **osx_profile** resource is:

.. code-block:: ruby

   osx_profile 'name' do
     path                       # set automatically
     profile                    String, Hash
     profile_name               String # defaults to 'name' if not specified
     identifier                 String
     action                     Symbol # defaults to :install if not specified
   end

where

* ``osx_profile`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``profile``, ``profile_name``, and ``identifier`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_osx_profile_actions

This resource has the following actions:

``:install``
   Default. Install the specified configuration profile.

``:nothing``
   Default. .. tag resources_common_actions_nothing

            Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

            .. end_tag

``:remove``
   Remove the specified configuration profile.

.. end_tag

Properties
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_osx_profile_attributes

This resource has the following properties:

``identifier``
   **Ruby Type:** String

   Use to specify the identifier for the profile, such as ``com.company.screensaver``.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

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

``profile``
   **Ruby Types:** String, Hash

   Use to specify a profile. This may be the name of a profile contained in a cookbook or a Hash that contains the contents of the profile.

``profile_name``
   **Ruby Type:** String

   Use to specify the name of the profile, if different from the name of the resource block.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider.

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

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**One liner to install profile from cookbook file**

.. tag resource_osx_profile_install_file_oneline

The ``profiles`` command will be used to install the specified configuration profile.

.. code-block:: ruby

   osx_profile 'com.company.screensaver.mobileconfig'

.. end_tag

**Install profile from cookbook file**

.. tag resource_osx_profile_install_file

The ``profiles`` command will be used to install the specified configuration profile. It can be in sub-directory within a cookbook.

.. code-block:: ruby

   osx_profile 'Install screensaver profile' do
     profile 'screensaver/com.company.screensaver.mobileconfig'
   end

.. end_tag

**Install profile from a hash**

.. tag resource_osx_profile_install_hash

The ``profiles`` command will be used to install the configuration profile, which is provided as a hash.

.. code-block:: ruby

   profile_hash = {
     'PayloadIdentifier' => 'com.company.screensaver',
     'PayloadRemovalDisallowed' => false,
     'PayloadScope' => 'System',
     'PayloadType' => 'Configuration',
     'PayloadUUID' => '1781fbec-3325-565f-9022-8aa28135c3cc',
     'PayloadOrganization' => 'Chef',
     'PayloadVersion' => 1,
     'PayloadDisplayName' => 'Screensaver Settings',
     'PayloadContent'=> [
       {
         'PayloadType' => 'com.apple.ManagedClient.preferences',
         'PayloadVersion' => 1,
         'PayloadIdentifier' => 'com.company.screensaver',
         'PayloadUUID' => '73fc30e0-1e57-0131-c32d-000c2944c108',
         'PayloadEnabled' => true,
         'PayloadDisplayName' => 'com.apple.screensaver',
         'PayloadContent' => {
           'com.apple.screensaver' => {
             'Forced' => [
               {
                 'mcx_preference_settings' => {
                   'idleTime' => 0,
                 }
               }
             ]
           }
         }
       }
     ]
   }

   osx_profile 'Install screensaver profile' do
     profile profile_hash
   end

.. end_tag

**Remove profile using identifier in resource name**

.. tag resource_osx_profile_remove_by_name

The ``profiles`` command will be used to remove the configuration profile specified by the provided ``identifier`` property.

.. code-block:: ruby

   osx_profile 'com.company.screensaver' do
     action :remove
   end

.. end_tag

**Remove profile by identifier and user friendly resource name**

.. tag resource_osx_profile_remove_by_identifier

The ``profiles`` command will be used to remove the configuration profile specified by the provided ``identifier`` property.

.. code-block:: ruby

   osx_profile 'Remove screensaver profile' do
     identifier 'com.company.screensaver'
     action :remove
   end

.. end_tag

apt_update
-----------------------------------------------------

.. tag resource_apt_update_summary

Use the **apt_update** resource to manage Apt repository updates on Debian and Ubuntu platforms.

.. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_apt_update_syntax

A **apt_update** resource block defines the update frequency for Apt repositories:

.. code-block:: ruby

   apt_update 'name' do
     frequency                  Integer
     action                     Symbol # defaults to :periodic if not specified
   end

where

* ``apt_update`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``frequency`` is a property of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_apt_update_actions

This resource has the following actions:

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:periodic``
   Update the Apt repository at the interval specified by the ``frequency`` property.

``:update``
   Update the Apt repository at the start of the chef-client run.

.. end_tag

Properties
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_apt_update_attributes

This resource has the following properties:

``frequency``
   **Ruby Type:** Integer

   The frequency at which Apt repository updates are made. Use this property when the ``:periodic`` action is specified. Default value: ``86400``.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

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

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**Update the Apt repository at a specified interval**

.. tag resource_apt_update_periodic

.. To update the Apt repository at a specified interval:

.. code-block:: ruby

   apt_update 'all platforms' do
     frequency 86400
     action :periodic
   end

.. end_tag

**Update the Apt repository at the start of a chef-client run**

.. tag resource_apt_update_at_start_of_client_run

.. To update the Apt repository at the start of a chef-client run:

.. code-block:: ruby

   apt_update 'update' do
     action :update
   end

.. end_tag

New chef-client options
-----------------------------------------------------
The chef-client has the following new options:

``--delete-entire-chef-repo``
   Delete the entire chef-repo. This option may only be used when running the chef-client in local mode (``--local-mode``) mode. This options requires ``--recipe-url`` to be specified.

What's New in 12.6
=====================================================
The following items are new for chef-client 12.6 and/or are changes from previous versions. The short version:

* **New timer for resource notifications** Use the ``:before`` timer with the ``notifies`` and ``subscribes`` properties to specify that the action on a notified resource should be run before processing the resource block in which the notification is located.
* **New ksh resource** The **ksh** resource is added and is based on the **script** resource.
* **New metadata.rb settings** The metadata.rb file has settings for ``chef_version`` and ``ohai_version`` that allow ranges to be specified that declare the supported versions of the chef-client and Ohai.
* **dsc_resource supports reboots** The **dsc_resource** resource supports immediate and queued reboots. This uses the **reboot** resource and its ``:reboot_now`` or ``:request_reboot`` actions.
* **New and changed knife bootstrap options** The ``--identify-file`` option for the ``knife bootstrap`` subcommand is renamed to ``--ssh-identity-file``; the ``--sudo-preserve-home`` is new.
* **New installer types for the windows_package resource** The **windows_package** resource now supports the following installer types: ``:custom``, Inno Setup (``:inno``), InstallShield (``:installshield``), Microsoft Installer Package (MSI) (``:msi``), Nullsoft Scriptable Install System (NSIS) (``:nsis``), Wise (``:wise``). Prior versions of Chef supported only ``:msi``.
* **dsc_resource resource may be run in non-disabled refresh mode** The latest version of Windows Management Framework (WMF) 5 has relaxed the limitation that prevented the chef-client from running in non-disabled refresh mode. Requires Windows PowerShell 5.0.10586.0 or higher.
* **dsc_script and dsc_resource resources may be in the same run-list** The latest version of Windows Management Framework (WMF) 5 has relaxed the limitation that prevented the chef-client from running in non-disabled refresh mode, which allows the Local Configuration Manager to be set to ``Push``. Requires Windows PowerShell 5.0.10586.0 or higher.
* **New --profile-ruby option** Use the ``--profile-ruby`` option to dump a (large) profiling graph into ``/var/chef/cache/graph_profile.out``.
* **New live_stream property for the execute resource** Set the ``live_stream`` property to ``true`` to send the output of a command run by the **execute** resource to the chef-client event stream.

Notification Timers
-----------------------------------------------------
.. tag resources_common_notification_timers

A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

``:before``
   Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

``:delayed``
   Default. Specifies that a notification should be queued up, and then executed at the very end of the chef-client run.

``:immediate``, ``:immediately``
   Specifies that a notification should be run immediately, per resource notified.

.. end_tag

ksh
-----------------------------------------------------
.. tag resource_script_ksh

Use the **ksh** resource to execute scripts using the Korn shell (ksh) interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use ``not_if`` and ``only_if`` to guard this resource for idempotence. New in Chef Client 12.6.

.. note:: The **ksh** script resource (which is based on the **script** resource) is different from the **ruby_block** resource because Ruby code that is run with this resource is created as a temporary file and executed like other script resources, rather than run inline.

.. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_script_ksh_syntax

A **ksh** resource block executes scripts using ksh:

.. code-block:: ruby

   ksh 'hello world' do
     code <<-EOH
       echo "Hello world!"
       echo "Current directory: " $cwd
       EOH
   end

where

* ``code`` specifies the command to run

The full syntax for all of the properties that are available to the **ksh** resource is:

.. code-block:: ruby

   ksh 'name' do
     code                       String
     creates                    String
     cwd                        String
     environment                Hash
     flags                      String
     group                      String, Integer
     notifies                   # see description
     path                       Array
     provider                   Chef::Provider::Script::Ksh
     returns                    Integer, Array
     subscribes                 # see description
     timeout                    Integer, Float
     user                       String, Integer
     umask                      String, Integer
     action                     Symbol # defaults to :run if not specified
   end

where

* ``ksh`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``code``, ``creates``, ``cwd``, ``environment``, ``flags``, ``group``, ``path``, ``provider``, ``returns``, ``timeout``, ``user``, and ``umask`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_script_ksh_actions

This resource has the following actions:

``:nothing``
   Prevent a command from running. This action is used to specify that a command is run only when another resource notifies it.

``:run``
   Default. Run a script.

.. end_tag

Properties
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_script_ksh_attributes

This resource has the following properties:

``code``
   **Ruby Type:** String

   A quoted (" ") string of code to be executed.

``creates``
   **Ruby Type:** String

   Prevent a command from creating a file when that file already exists.

``cwd``
   **Ruby Type:** String

   The current working directory.

``environment``
   **Ruby Type:** Hash

   A Hash of environment variables in the form of ``({"ENV_VARIABLE" => "VALUE"})``. (These variables must exist for a command to be run successfully.)

``flags``
   **Ruby Type:** String

   One or more command line flags that are passed to the interpreter when a command is invoked.

``group``
   **Ruby Types:** String, Integer

   The group name or group ID that must be changed before running a command.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

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

``path``
   **Ruby Type:** Array

   An array of paths to use when searching for a command. These paths are not added to the command's environment $PATH. The default value uses the system path.

   .. warning:: .. tag resources_common_resource_execute_attribute_path

                The ``path`` property has been deprecated and will throw an exception in Chef Client 12 or later. We recommend you use the ``environment`` property instead.

                .. end_tag

      For example:

      .. code-block:: ruby

         ksh 'mycommand' do
           environment 'PATH' => "/my/path/to/bin:#{ENV['PATH']}"
         end

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider. See "Providers" section below for more information.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``returns``
   **Ruby Types:** Integer, Array

   The return value for a command. This may be an array of accepted values. An exception is raised when the return value(s) do not match. Default value: ``0``.

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

``timeout``
   **Ruby Types:** Integer, Float

   The amount of time (in seconds) a command is to wait before timing out. Default value: ``3600``.

``user``
   **Ruby Types:** String, Integer

   The user name or user ID that should be changed before running a command.

``umask``
   **Ruby Types:** String, Integer

   The file mode creation mask, or umask.

.. end_tag

Changes for PowerShell 5.0.10586.0
-----------------------------------------------------
.. tag resource_dsc_resource_requirements

Using the **dsc_resource** has the following requirements:

* Windows Management Framework (WMF) 5.0 February Preview (or higher), which includes Windows PowerShell 5.0.10018.0 (or higher).
* The ``RefreshMode`` configuration setting in the Local Configuration Manager must be set to ``Disabled``.

  **NOTE:** Starting with the chef-client 12.6 release, this requirement applies only for versions of Windows PowerShell earlier than 5.0.10586.0. The latest version of Windows Management Framework (WMF) 5 has relaxed the limitation that prevented the chef-client from running in non-disabled refresh mode.

* The **dsc_script** resource  may not be used in the same run-list with the **dsc_resource**. This is because the **dsc_script** resource requires that ``RefreshMode`` in the Local Configuration Manager be set to ``Push``, whereas the **dsc_resource** resource requires it to be set to ``Disabled``.

  **NOTE:** Starting with the chef-client 12.6 release, this requirement applies only for versions of Windows PowerShell earlier than 5.0.10586.0. The latest version of Windows Management Framework (WMF) 5 has relaxed the limitation that prevented the chef-client from running in non-disabled refresh mode, which allows the Local Configuration Manager to be set to ``Push``.

* The **dsc_resource** resource can only use binary- or script-based resources. Composite DSC resources may not be used.

  This is because composite resources aren't "real" resources from the perspective of the the Local Configuration Manager (LCM). Composite resources are used by the "configuration" keyword from the ``PSDesiredStateConfiguration`` module, and then evaluated in that context. When using DSC to create the configuration document (the Managed Object Framework (MOF) file) from the configuration command, the composite resource is evaluated. Any individual resources from that composite resource are written into the Managed Object Framework (MOF) document. As far as the Local Configuration Manager (LCM) is concerned, there is no such thing as a composite resource. Unless that changes, the **dsc_resource** resource and/or ``Invoke-DscResource`` command cannot directly use them.

.. end_tag

New metadata.rb Settings
-----------------------------------------------------
The following settings are new for metadata.rb:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Setting
     - Description
   * - ``chef_version``
     - A range of chef-client versions that are supported by this cookbook.

       .. tag config_rb_metadata_settings_example_chef_version

       For example, to match any 12.x version of the chef-client, but not 11.x or 13.x:

       .. code-block:: ruby

          chef_version '~> 12'

       .. end_tag

   * - ``ohai_version``
     - A range of chef-client versions that are supported by this cookbook.

       .. tag config_rb_metadata_settings_example_ohai_version

       For example, to match any 8.x version of Ohai, but not 7.x or 9.x:

       .. code-block:: ruby

          ohai_version "~> 8"

       .. end_tag

.. note:: These settings are not visible in Chef Supermarket.

knife bootstrap Options
-----------------------------------------------------
The following option is new for ``knife bootstrap``:

``--sudo-preserve-home``
   Use to preserve the non-root user's ``HOME`` environment.

The ``--identify-file`` option is now ``--ssh-identify-file``.

--profile-ruby Option
-----------------------------------------------------
.. tag ctl_chef_client_profile_ruby

Use the ``--profile-ruby`` option to dump a (large) profiling graph into ``/var/chef/cache/graph_profile.out``. Use the graph output to help identify, and then resolve performance bottlenecks in a chef-client run. This option:

* Generates a large amount of data about the chef-client run.
* Has a dependency on the ``ruby-prof`` gem, which is packaged as part of Chef and the Chef development kit.
* Increases the amount of time required to complete the chef-client run.
* Should not be used in a production environment.

New in Chef Client 12.6.

.. end_tag

What's New in 12.5
=====================================================
The following items are new for chef-client 12.5 and/or are changes from previous versions. The short version:

* **New way to build custom resources** The process for extending the collection of resources that are built into Chef has been simplified. It is defined only in the ``/resources`` directory using a simplified syntax that easily leverages the built-in collection of resources. (All of the ways you used to build custom resources still work.)
* **"resource attributes" are now known as "resource properties"** In previous releases of Chef, resource properties are referred to as attributes, but this is confusing for users because nodes also have attributes. Starting with chef-client 12.5 release---and retroactively updated for all previous releases of the documentation---"resource attributes" are now referred to as "resource properties" and the word "attribute" now refers specifically to "node attributes".
* **ps_credential helper to embed usernames and passwords** Use the ``ps_credential`` helper on Microsoft Windows to create a ``PSCredential`` object---security credentials, such as a user name or password---that can be used in the **dsc_script** resource.
* **New Handler DSL** A new DSL exists to make it easier to use events that occur during the chef-client run from recipes. The ``on`` method is easily associated with events. The action the chef-client takes as a result of that event (when it occurs) is up to you.
* **The -j / --json-attributes supports policy revisions and environments** The JSON file used by the ``--json-attributes`` option for the chef-client may now contain the policy name and policy group associated with a policy revision or may contain the name of the environment to which the node is associated.
* **verify property now uses path, not file** The ``verify`` property, used by file-based resources such as **remote_file** and **file**, runs user-defined correctness checks against the proposed new file before making the change. For versions of the chef-client prior to 12.5, the name of the temporary file was stored as ``file``; starting with chef-client 12.5, use ``path``. This change is documented as a warning across all versions in any topic in which the ``version`` attribute is documented.
* **depth property added to deploy resource** The ``depth`` property allows the depth of a git repository to be truncated to the specified number of versions.
* **The knife ssl check subcommand supports SNI** Support for Server Name Indication (SNI) is added to the ``knife ssl check`` subcommand.
* **Chef Policy group and name can now be part of the node object** Chef policy is a beta feature of the chef-client that will eventually replace roles, environments or manually specifying the run_list. Policy group and name can now be stored as part of the node object rather than in the client.rb file. A recent version of the Chef server, such as 12.2.0 or higher, is needed to fully utilize this feature.

Custom Resources
-----------------------------------------------------
.. tag custom_resources_summary

A custom resource:

* Is a simple extension of Chef that adds your own resources
* Is implemented and shipped as part of a cookbook
* Follows easy, repeatable syntax patterns
* Effectively leverages resources that are built into Chef and/or custom Ruby code
* Is reusable in the same way as resources that are built into Chef

For example, Chef includes built-in resources to manage files, packages, templates, and services, but it does not include a resource that manages websites.

.. end_tag

.. note:: See /custom_resources.html for more information about custom resources, including a scenario that shows how to build a ``website`` resource.

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag custom_resources_syntax

A custom resource is defined as a Ruby file and is located in a cookbook's ``/resources`` directory. This file

* Declares the properties of the custom resource
* Loads current properties, if the resource already exists
* Defines each action the custom resource may take

The syntax for a custom resource is. For example:

.. code-block:: ruby

   property :name, RubyType, default: 'value'

   load_current_value do
     # some Ruby for loading the current state of the resource
   end

   action :name do
    # a mix of built-in Chef resources and Ruby
   end

   action :name do
    # a mix of built-in Chef resources and Ruby
   end

where the first action listed is the default action.

.. end_tag

.. tag custom_resources_syntax_example

This example ``site`` utilizes Chef's built in ``file``, ``service`` and ``package`` resources, and includes ``:create`` and ``:delete`` actions. Since it uses built in Chef resources, besides defining the property and actions, the code is very similar to that of a recipe.

.. code-block:: ruby

   property :homepage, String, default: '<h1>Hello world!</h1>'

   action :create do
     package 'httpd'

     service 'httpd' do
       action [:enable, :start]
     end

     file '/var/www/html/index.html' do
       content homepage
     end
   end

   action :delete do
     package 'httpd' do
       action :delete
     end
   end

where

* ``homepage`` is a property that sets the default HTML for the ``index.html`` file with a default value of ``'<h1>Hello world!</h1>'``
* the ``action`` block uses the built-in collection of resources to tell the chef-client how to install Apache, start the service, and then create the contents of the file located at ``/var/www/html/index.html``
* ``action :create`` is the default resource; ``action :delete`` must be called specifically (because it is not the default resource)

Once built, the custom resource may be used in a recipe just like the any of the resources that are built into Chef. The resource gets its name from the cookbook and from the file name in the ``/resources`` directory, with an underscore (``_``) separating them. For example, a cookbook named ``exampleco`` with a custom resource named ``site.rb`` is used in a recipe like this:

.. code-block:: ruby

   exampleco_site 'httpd' do
     homepage '<h1>Welcome to the Example Co. website!</h1>'
   end

and to delete the exampleco website, do the following:

.. code-block:: ruby

   exampleco_site 'httpd' do
     action :delete
   end

.. end_tag

Custom Resource DSL
-----------------------------------------------------
.. tag dsl_custom_resource_summary

Use the Custom Resource DSL to define property behaviors within custom resources, such as:

* Loading the value of a specific property
* Comparing the current property value against a desired property value
* Telling the chef-client when and how to make changes

.. end_tag

action_class
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_custom_resource_block_action_class

Use the ``action_class.class_eval`` block to make methods available to the actions in the custom resource. Modules with helper methods created as files in the cookbook library directory may be included. New action methods may also be defined directly in the ``action_class.class_eval`` block. Code in the ``action_class.class_eval`` block has access to the new_resource properties.

Assume a helper module has been created in the cookbook ``libraries/helper.rb`` file.

.. code-block:: ruby

   module Sample
     module Helper
       def helper_method
         # code
       end
     end
   end

Methods may be made available to the custom resource actions by using an ``action_class.class_eval`` block.

.. code-block:: ruby

   property file, String

   action :delete do
     helper_method
     FileUtils.rm(file) if file_ex
   end

   action_class.class_eval do

     def file_exist
       ::File.exist?(file)
     end

     def file_ex
       ::File.exist?(new_resource.file)
     end

     require 'fileutils'

     include Sample::Helper

   end

.. end_tag

converge_if_changed
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_custom_resource_method_converge_if_changed

Use the ``converge_if_changed`` method inside an ``action`` block in a custom resource to compare the desired property values against the current property values (as loaded by the ``load_current_value`` method). Use the ``converge_if_changed`` method to ensure that updates only occur when property values on the system are not the desired property values and to otherwise prevent a resource from being converged.

To use the ``converge_if_changed`` method, wrap it around the part of a recipe or custom resource that should only be converged when the current state is not the desired state:

.. code-block:: ruby

   action :some_action do

     converge_if_changed do
       # some property
     end

   end

For example, a custom resource defines two properties (``content`` and ``path``) and a single action (``:create``). Use the ``load_current_value`` method to load the property value to be compared, and then use the ``converge_if_changed`` method to tell the chef-client what to do if that value is not the desired value:

.. code-block:: ruby

   property :content, String
   property :path, String, name_property: true

   load_current_value do
     if ::File.exist?(path)
       content IO.read(path)
     end
   end

   action :create do
     converge_if_changed do
       IO.write(path, content)
     end
   end

When the file does not exist, the ``IO.write(path, content)`` code is executed and the chef-client output will print something similar to:

.. code-block:: bash

   Recipe: recipe_name::block
     * resource_name[blah] action create
       - update my_file[blah]
       -   set content to "hola mundo" (was "hello world")

.. end_tag

Multiple Properties
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag dsl_custom_resource_method_converge_if_changed_multiple

The ``converge_if_changed`` method may be used multiple times. The following example shows how to use the ``converge_if_changed`` method to compare the multiple desired property values against the current property values (as loaded by the ``load_current_value`` method).

.. code-block:: ruby

   property :path, String, name_property: true
   property :content, String
   property :mode, String

   load_current_value do
     if ::File.exist?(path)
       content IO.read(path)
       mode ::File.stat(path).mode
     end
   end

   action :create do
     converge_if_changed :content do
       IO.write(path, content)
     end
     converge_if_changed :mode do
       ::File.chmod(mode, path)
     end
   end

where

* ``load_current_value`` loads the property values for both ``content`` and ``mode``
* A ``converge_if_changed`` block tests only ``content``
* A ``converge_if_changed`` block tests only ``mode``

The chef-client will only update the property values that require updates and will not make changes when the property values are already in the desired state

.. end_tag

default_action
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_custom_resource_method_default_action

The default action in a custom resource is, by default, the first action listed in the custom resource. For example, action ``aaaaa`` is the default resource:

.. code-block:: ruby

   property :name, RubyType, default: 'value'

   ...

   action :aaaaa do
    # the first action listed in the custom resource
   end

   action :bbbbb do
    # the second action listed in the custom resource
   end

The ``default_action`` method may also be used to specify the default action. For example:

.. code-block:: ruby

   property :name, RubyType, default: 'value'

   default_action :aaaaa

   action :aaaaa do
    # the first action listed in the custom resource
   end

   action :bbbbb do
    # the second action listed in the custom resource
   end

defines action ``aaaaa`` as the default action. If ``default_action :bbbbb`` is specified, then action ``bbbbb`` is the default action. Use this method for clarity in custom resources, if deliberately stating the default resource is desired, or to specify a default action that is not listed first in the custom resource.

.. end_tag

load_current_value
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_custom_resource_method_load_current_value

Use the ``load_current_value`` method to load the specified property values from the node, and then use those values when the resource is converged. This method may take a block argument.

Use the ``load_current_value`` method to guard against property values being replaced. For example:

.. code-block:: ruby

   action :some_action do

     load_current_value do
       if ::File.exist?('/var/www/html/index.html')
         homepage IO.read('/var/www/html/index.html')
       end
       if ::File.exist?('/var/www/html/404.html')
         page_not_found IO.read('/var/www/html/404.html')
       end
     end

   end

This ensures the values for ``homepage`` and ``page_not_found`` are not changed to the default values when the chef-client configures the node.

.. end_tag

new_resource.property
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_custom_resource_method_new_resource

Custom resources are designed to use core resources that are built into Chef. In some cases, it may be necessary to specify a property in the custom resource that is the same as a property in a core resource, for the purpose of overriding that property when used with the custom resource. For example:

.. code-block:: ruby

   resource_name :node_execute

   property :command, String, name_property: true
   property :version, String

   # Useful properties from the `execute` resource
   property :cwd, String
   property :environment, Hash, default: {}
   property :user, [String, Integer]
   property :sensitive, [true, false], default: false

   prefix = '/opt/languages/node'

   load_current_value do
     current_value_does_not_exist! if node.run_state['nodejs'].nil?
     version node.run_state['nodejs'][:version]
   end

   action :run do
     execute 'execute-node' do
       cwd cwd
       environment environment
       user user
       sensitive sensitive
       # gsub replaces 10+ spaces at the beginning of the line with nothing
       command <<-CODE.gsub(/^ {10}/, '')
         #{prefix}/#{version}/#{command}
       CODE
     end
   end

where the ``property :cwd``, ``property :environment``, ``property :user``, and ``property :sensitive`` are identical to properties in the **execute** resource, embedded as part of the ``action :run`` action. Because both the custom properties and the **execute** properties are identical, this will result in an error message similar to:

.. code-block:: ruby

   ArgumentError
   -------------
   wrong number of arguments (0 for 1)

To prevent this behavior, use ``new_resource.`` to tell the chef-client to process the properties from the core resource instead of the properties in the custom resource. For example:

.. code-block:: ruby

   resource_name :node_execute

   property :command, String, name_property: true
   property :version, String

   # Useful properties from the `execute` resource
   property :cwd, String
   property :environment, Hash, default: {}
   property :user, [String, Integer]
   property :sensitive, [true, false], default: false

   prefix = '/opt/languages/node'

   load_current_value do
     current_value_does_not_exist! if node.run_state['nodejs'].nil?
     version node.run_state['nodejs'][:version]
   end

   action :run do
     execute 'execute-node' do
       cwd new_resource.cwd
       environment new_resource.environment
       user new_resource.user
       sensitive new_resource.sensitive
       # gsub replaces 10+ spaces at the beginning of the line with nothing
       command <<-CODE.gsub(/^ {10}/, '')
         #{prefix}/#{new_resource.version}/#{new_resource.command}
       CODE
     end
   end

where ``cwd new_resource.cwd``, ``environment new_resource.environment``, ``user new_resource.user``, and ``sensitive new_resource.sensitive`` correctly use the properties of the **execute** resource and not the identically-named override properties of the custom resource.

.. end_tag

property
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_custom_resource_method_property

Use the ``property`` method to define properties for the custom resource. The syntax is:

.. code-block:: ruby

   property :name, ruby_type, default: 'value', parameter: 'value'

where

* ``:name`` is the name of the property
* ``ruby_type`` is the optional Ruby type or array of types, such as ``String``, ``Integer``, ``true``, or ``false``
* ``default: 'value'`` is the optional default value loaded into the resource
* ``parameter: 'value'`` optional parameters

For example, the following properties define ``username`` and ``password`` properties with no default values specified:

.. code-block:: ruby

   property :username, String
   property :password, String

.. end_tag

ruby_type
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag dsl_custom_resource_method_property_ruby_type

The property ruby_type is a positional parameter. Use to ensure a property value is of a particular ruby class, such as ``true``, ``false``, ``nil``, ``String``, ``Array``, ``Hash``, ``Integer``, ``Symbol``. Use an array of ruby classes to allow a value to be of more than one type. For example:

       .. code-block:: ruby

          property :name, String

       .. code-block:: ruby

          property :name, Integer

       .. code-block:: ruby

          property :name, Hash

       .. code-block:: ruby

          property :name, [true, false]

       .. code-block:: ruby

          property :name, [String, nil]

       .. code-block:: ruby

          property :name, [Class, String, Symbol]

       .. code-block:: ruby

          property :name, [Array, Hash]

.. end_tag

validators
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag dsl_custom_resource_method_property_validation_parameter

A validation parameter is used to add zero (or more) validation parameters to a property.

.. list-table::
   :widths: 150 450
   :header-rows: 1

   * - Parameter
     - Description
   * - ``:callbacks``
     - Use to define a collection of unique keys and values (a ruby hash) for which the key is the error message and the value is a lambda to validate the parameter. For example:

       .. code-block:: ruby

          callbacks: {
                       'should be a valid non-system port' => lambda {
                         |p| p > 1024 && p < 65535
                       }
                     }

   * - ``:default``
     - Use to specify the default value for a property. For example:

       .. code-block:: ruby

          default: 'a_string_value'

       .. code-block:: ruby

          default: 123456789

       .. code-block:: ruby

          default: []

       .. code-block:: ruby

          default: ()

       .. code-block:: ruby

          default: {}
   * - ``:equal_to``
     - Use to match a value with ``==``. Use an array of values to match any of those values with ``==``. For example:

       .. code-block:: ruby

          equal_to: [true, false]

       .. code-block:: ruby

          equal_to: ['php', 'perl']
   * - ``:regex``
     - Use to match a value to a regular expression. For example:

       .. code-block:: ruby

          regex: [ /^([a-z]|[A-Z]|[0-9]|_|-)+$/, /^\d+$/ ]
   * - ``:required``
     - Indicates that a property is required. For example:

       .. code-block:: ruby

          required: true
   * - ``:respond_to``
     - Use to ensure that a value has a given method. This can be a single method name or an array of method names. For example:

       .. code-block:: ruby

          respond_to: valid_encoding?

Some examples of combining validation parameters:

.. code-block:: ruby

   property :spool_name, String, regex: /$\w+/

.. code-block:: ruby

   property :enabled, equal_to: [true, false, 'true', 'false'], default: true

.. end_tag

desired_state
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag dsl_custom_resource_method_property_desired_state

Add ``desired_state:`` to get or set the list of desired state properties for a resource, which describe the desired state of the node, such as permissions on an existing file. This value may be ``true`` or ``false``.

* When ``true``, the state of the system will determine the value.
* When ``false``, the values defined by the recipe or custom resource will determine the value, i.e. "the desired state of this system includes setting the value defined in this custom resource or recipe"

For example, the following properties define the ``owner``, ``group``, and ``mode`` properties for a file that already exists on the node, and with ``desired_state`` set to ``false``:

.. code-block:: ruby

   property :owner, String, default: 'root', desired_state: false
   property :group, String, default: 'root', desired_state: false
   property :mode, String, default: '0755', desired_state: false

.. end_tag

identity
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag dsl_custom_resource_method_property_identity

Add ``identity:`` to set a resource to a particular set of properties. This value may be ``true`` or ``false``.

* When ``true``, data for that property is returned as part of the resource data set and may be available to external applications, such as reporting
* When ``false``, no data for that property is returned.

If no properties are marked ``true``, the property that defaults to the ``name`` of the resource is marked ``true``.

For example, the following properties define ``username`` and ``password`` properties with no default values specified, but with ``identity`` set to ``true`` for the user name:

.. code-block:: ruby

   property :username, String, identity: true
   property :password, String

.. end_tag

Block Arguments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag dsl_custom_resource_method_property_block_argument

Any properties that are marked ``identity: true`` or ``desired_state: false`` will be available from ``load_current_value``. If access to other properties of a resource is needed, use a block argument that contains all of the properties of the requested resource. For example:

.. code-block:: ruby

   resource_name :file

   load_current_value do |desired|
     puts "The user typed content = #{desired.content} in the resource"
   end

.. end_tag

property_is_set?
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_custom_resource_method_property_is_set

Use the ``property_is_set?`` method to check if the value for a property is set. The syntax is:

.. code-block:: ruby

   property_is_set?(:property_name)

The ``property_is_set?`` method will return ``true`` if the property is set.

For example, the following custom resource creates and/or updates user properties, but not their password. The ``property_is_set?`` method checks if the user has specified a password and then tells the chef-client what to do if the password is not identical:

.. code-block:: ruby

   action :create do
     converge_if_changed do
       system("rabbitmqctl create_or_update_user #{username} --prop1 #{prop1} ... ")
     end

     if property_is_set?(:password)
       if system("rabbitmqctl authenticate_user #{username} #{password}") != 0 do
         converge_by "Updating password for user #{username} ..." do
       system("rabbitmqctl update_user #{username} --password #{password}")
     end
   end

.. end_tag

provides
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_custom_resource_method_provides

Use the ``provides`` method to associate a custom resource with the Recipe DSL on different operating systems. When multiple custom resources use the same DSL, specificity rules are applied to determine the priority, from highest to lowest:

#. provides :resource_name, platform_version: ‘0.1.2’
#. provides :resource_name, platform: ‘platform_name’
#. provides :resource_name, platform_family: ‘platform_family’
#. provides :resource_name, os: ‘operating_system’
#. provides :resource_name

For example:

.. code-block:: ruby

    provides :my_custom_resource, platform: 'redhat' do |node|
      node['platform_version'].to_i >= 7
    end

    provides :my_custom_resource, platform: 'redhat'

    provides :my_custom_resource, platform_family: 'rhel'

    provides :my_custom_resource, os: 'linux'

    provides :my_custom_resource

This allows you to use multiple custom resources files that provide the same resource to the user, but for different operating systems or operation system versions. With this you can eliminate the need for platform or platform version logic within your resources.

.. end_tag

override
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag dsl_custom_resource_method_provides_override

Chef will warn you if the Recipe DSL is provided by another custom resource or built-in resource. For example:

.. code-block:: ruby

   class X < Chef::Resource
     provides :file
   end

   class Y < Chef::Resource
     provides :file
   end

This will emit a warning that ``Y`` is overriding ``X``. To disable this warning, use ``override: true``:

.. code-block:: ruby

   class X < Chef::Resource
     provides :file
   end

   class Y < Chef::Resource
     provides :file, override: true
   end

.. end_tag

reset_property
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_custom_resource_method_reset_property

Use the ``reset_property`` method to clear the value for a property as if it had never been set, and then use the default value. For example, to clear the value for a property named ``password``:

.. code-block:: ruby

   reset_property(:password)

.. end_tag

Definition vs. Resource
-----------------------------------------------------
.. tag definition_example

The following examples show:

#. A definition
#. The same definition rewritten as a custom resource
#. The same definition, rewritten again to use a :doc:`common resource property </resource_common>`

.. end_tag

As a Definition
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag definition_example_as_definition

The following definition processes unique hostnames and ports, passed on as parameters:

.. code-block:: ruby

   define :host_porter, :port => 4000, :hostname => nil do
     params[:hostname] ||= params[:name]

     directory '/etc/#{params[:hostname]}' do
       recursive true
     end

     file '/etc/#{params[:hostname]}/#{params[:port]}' do
       content 'some content'
     end
   end

.. end_tag

As a Resource
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag definition_example_as_resource

The definition is improved by rewriting it as a custom resource:

.. code-block:: ruby

   property :port, Integer, default: 4000
   property :hostname, String, name_property: true

   action :create do

     directory "/etc/#{hostname}" do
       recursive true
     end

     file "/etc/#{hostname}/#{port}" do
       content 'some content'
     end

   end

Once built, the custom resource may be used in a recipe just like the any of the resources that are built into Chef. The resource gets its name from the cookbook and from the file name in the ``/resources`` directory, with an underscore (``_``) separating them. For example, a cookbook named ``host`` with a custom resource in the ``/resources`` directory named ``porter.rb``. Use it in a recipe like this:

.. code-block:: ruby

   host_porter node['hostname'] do
     port 4000
   end

or:

.. code-block:: ruby

   host_porter 'www1' do
     port 4001
   end

.. end_tag

Common Properties
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag definition_example_as_resource_with_common_properties

Unlike definitions, custom resources are able to use :doc:`common resource properties </resource_common>`. For example, ``only_if``:

.. code-block:: ruby

   host_porter 'www1' do
     port 4001
     only_if '{ node['hostname'] == 'foo.bar.com' }'
   end

.. end_tag

ps_credential Helper
-----------------------------------------------------
.. tag resource_dsc_script_helper_ps_credential

Use the ``ps_credential`` helper to embed a ``PSCredential`` object---`a set of security credentials, such as a user name or password <https://technet.microsoft.com/en-us/magazine/ff714574.aspx>`__---within a script, which allows that script to be run using security credentials.

For example, assuming the ``CertificateID`` is configured in the local configuration manager, the ``SeaPower1@3`` object is created and embedded within the ``seapower-user`` script:

.. code-block:: ruby

   dsc_script 'seapower-user' do
     code <<-EOH
       User AlbertAtom
       {
         UserName = 'AlbertAtom'
         Password = #{ps_credential('SeaPower1@3')}
       }
    EOH
    configuration_data <<-EOH
      @{
        AllNodes = @(
          @{
            NodeName = "localhost";
            CertificateID = 'A8D1234559F349F7EF19104678908F701D4167'
          }
        )
      }
    EOH
  end

.. end_tag

Handler DSL
-----------------------------------------------------
.. tag dsl_handler_summary

Use the Handler DSL to attach a callback to an event. If the event occurs during the chef-client run, the associated callback is executed. For example:

* Sending email if a chef-client run fails
* Sending a notification to chat application if an audit run fails
* Aggregating statistics about resources updated during a chef-client runs to StatsD

.. end_tag

on Method
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_handler_method_on

Use the ``on`` method to associate an event type with a callback. The callback defines what steps are taken if the event occurs during the chef-client run and is defined using arbitrary Ruby code. The syntax is as follows:

.. code-block:: ruby

   Chef.event_handler do
     on :event_type do
       # some Ruby
     end
   end

where

* ``Chef.event_handler`` declares a block of code within a recipe that is processed when the named event occurs during a chef-client run
* ``on`` defines the block of code that will tell the chef-client how to handle the event
* ``:event_type`` is a valid exception event type, such as ``:run_start``, ``:run_failed``, ``:converge_failed``, ``:resource_failed``, or ``:recipe_not_found``

For example:

.. code-block:: bash

   Chef.event_handler do
     on :converge_start do
       puts "Ohai! I have started a converge."
     end
   end

.. end_tag

Example: Send Email
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_handler_slide_send_email

Use the ``on`` method to create an event handler that sends email when the chef-client run fails. This will require:

* A way to tell the chef-client how to send email
* An event handler that describes what to do when the ``:run_failed`` event is triggered
* A way to trigger the exception and test the behavior of the event handler

.. end_tag

.. note:: See /dsl_handler.html for more information about using event handlers in recipes.

**Define How Email is Sent**

.. tag dsl_handler_slide_send_email_library

Use a library to define the code that sends email when a chef-client run fails. Name the file ``helper.rb`` and add it to a cookbook's ``/libraries`` directory:

.. code-block:: ruby

   require 'net/smtp'

   module HandlerSendEmail
     class Helper

       def send_email_on_run_failure(node_name)

         message = "From: Chef <chef@chef.io>\n"
         message << "To: Grant <grantmc@chef.io>\n"
         message << "Subject: Chef run failed\n"
         message << "Date: #{Time.now.rfc2822}\n\n"
         message << "Chef run failed on #{node_name}\n"
         Net::SMTP.start('localhost', 25) do |smtp|
           smtp.send_message message, 'chef@chef.io', 'grantmc@chef.io'
         end
       end
     end
   end

.. end_tag

**Add the Handler**

.. tag dsl_handler_slide_send_email_handler

Invoke the library helper in a recipe:

.. code-block:: ruby

   Chef.event_handler do
     on :run_failed do
       HandlerSendEmail::Helper.new.send_email_on_run_failure(
         Chef.run_context.node.name
       )
     end
   end

* Use ``Chef.event_handler`` to define the event handler
* Use the ``on`` method to specify the event type

Within the ``on`` block, tell the chef-client how to handle the event when it's triggered.

.. end_tag

**Test the Handler**

.. tag dsl_handler_slide_send_email_test

Use the following code block to trigger the exception and have the chef-client send email to the specified email address:

.. code-block:: ruby

   ruby_block 'fail the run' do
     block do
       fail 'deliberately fail the run'
     end
   end

.. end_tag

New Resource Properties
-----------------------------------------------------
The following property is new for the **deploy** resource:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Property
     - Description
   * - ``depth``
     - **Ruby Type:** Integer

       The depth of a git repository, truncated to the specified number of revisions.

Specify Policy Revision
-----------------------------------------------------
Use the following command to specify a policy revision:

.. code-block:: bash

   $ chef client -j JSON

where the JSON file is similar to:

.. code-block:: javascript

   {
     "policy_name": "appserver",
     "policy_group": "staging"
   }

Or use the following settings to specify a policy revision in the client.rb file:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Setting
     - Description
   * - ``policy_group``
     - The name of a policy, as identified by the ``name`` setting in a Policyfile.rb file.
   * - ``policy_name``
     - The name of a policy group that exists on the Chef server.

New Configuration Settings
-----------------------------------------------------
The following settings are new for the client.rb file and enable the use of policy files:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Setting
     - Description
   * - ``named_run_list``
     - The run-list associated with a policy file.
   * - ``policy_group``
     - The name of a policy, as identified by the ``name`` setting in a Policyfile.rb file. (See "Specify Policy Revision" in this readme for more information.)
   * - ``policy_name``
     - The name of a policy group that exists on the Chef server. (See "Specify Policy Revision" in this readme for more information.)

chef-client Options
-----------------------------------------------------
The following options are new or updated for the chef-client executable and enable the use of policy files:

``-n NAME``, ``--named-run-list NAME``
   The run-list associated with a policy file.

``-j PATH``, ``--json-attributes PATH``
   This option now supports using a JSON file to associate a policy revision.

   .. tag policy_ctl_run_list

   Use this option to use policy files by specifying a JSON file that contains the following settings:

   .. list-table::
      :widths: 200 300
      :header-rows: 1

      * - Setting
        - Description
      * - ``policy_group``
        - The name of a policy, as identified by the ``name`` setting in a Policyfile.rb file.
      * - ``policy_name``
        - The name of a policy group that exists on the Chef server.

   For example:

   .. code-block:: javascript

      {
        "policy_name": "appserver",
        "policy_group": "staging"
      }

   .. end_tag

   This option also supports using a JSON file to associate an environment:

   .. tag ctl_chef_client_environment

   Use this option to set the ``chef_environment`` value for a node.

   .. note:: Any environment specified for ``chef_environment`` by a JSON file will take precedence over an environment specified by the ``--environment`` option when both options are part of the same command.

   For example, run the following:

   .. code-block:: bash

      $ chef-client -j /path/to/file.json

   where ``/path/to/file.json`` is similar to:

   .. code-block:: javascript

      {
        "chef_environment": "pre-production"
      }

   This will set the environment for the node to ``pre-production``.

   .. end_tag

What's New in 12.4
=====================================================
The following items are new for chef-client 12.4 and/or are changes from previous versions. The short version:

* **Validatorless bootstrap now requires the node name** Use of the ``-N node_name`` option with a validatorless bootstrap is now required.
* **remote_file resource supports Windows UNC paths for source location** A Microsoft Windows UNC path may be used to specify the location of a remote file.
* **Run PowerShell commands without excessive quoting** Use the ``Import-Module chef`` module to run Windows PowerShell commands without excessive quotation.
* **Logging may use the Windows Event Logger** Log files may be sent to the Windows Event Logger. Set the ``log_location`` setting in the client.rb file to ``Chef::Log::WinEvt.new``.
* **Logging may be configured to use daemon facility available to the chef-client** Log files may be sent to the syslog available to the chef-client. Set the ``log_location`` setting in the client.rb file to ``Chef::Log::Syslog.new("chef-client", ::Syslog::LOG_DAEMON)``.
* **Package locations on the Windows platform may be specified using a URL** The location of a package may be at URL when using the **windows_package** resource.
* **Package locations on the Windows platform may be specified by passing attributes to the remote_file resource** Use the ``remote_file_attributes`` attribute to pass a Hash of attributes that modifies the **remote_file** resource.
* **Public key management for users and clients** The ``knife client`` and ``knife user`` subcommands may now create, delete, edit, list, and show public keys.
* **knife client create and knife user create options have changed** With the new key management subcommands, the options for ``knife client create`` and ``knife user create`` have changed.
* **chef-client audit-mode is no longer marked as "experimental"** The recommended version of audit-mode is chef-client 12.4, where it is no longer marked as experimental. The chef-client will report audit failures independently of converge failures.

UNC paths, **remote_file**
-----------------------------------------------------
When using the **remote_file** resource, the location of a source file may be specified using a Microsoft Windows UNC. For example:

.. code-block:: ruby

   source "\\\\path\\to\\img\\sketch.png"

Import-Module chef
-----------------------------------------------------
.. tag knife_common_windows_quotes_module

The chef-client version 12.4 release adds an optional feature to the Microsoft Installer Package (MSI) for Chef. This feature enables the ability to pass quoted strings from the Windows PowerShell command line without the need for triple single quotes (``''' '''``). This feature installs a Windows PowerShell module (typically in ``C:\opscode\chef\modules``) that is also appended to the ``PSModulePath`` environment variable. This feature is not enabled by default. To activate this feature, run the following command from within Windows PowerShell:

.. code-block:: bash

   $ Import-Module chef

or add ``Import-Module chef`` to the profile for Windows PowerShell located at:

.. code-block:: bash

   ~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1

This module exports cmdlets that have the same name as the command-line tools---chef-client, knife, chef-apply---that are built into Chef.

For example:

.. code-block:: bash

   $ knife exec -E 'puts ARGV' """&s0meth1ng"""

is now:

.. code-block:: bash

   $ knife exec -E 'puts ARGV' '&s0meth1ng'

and:

.. code-block:: bash

   $ knife node run_list set test-node '''role[ssssssomething]'''

is now:

.. code-block:: bash

   $ knife node run_list set test-node 'role[ssssssomething]'

To remove this feature, run the following command from within Windows PowerShell:

.. code-block:: bash

   $ Remove-Module chef

.. end_tag

client.rb Settings
-----------------------------------------------------
The following settings have changed:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Setting
     - Description
   * - ``log_location``
     - The location of the log file. Possible values: ``/path/to/log_location``, ``STDOUT``, ``STDERR``, ``Chef::Log::WinEvt.new`` (Windows Event Logger), or ``Chef::Log::Syslog.new("chef-client", ::Syslog::LOG_DAEMON)`` (writes to the syslog daemon facility with the originator set as ``chef-client``). The application log will specify the source as ``Chef``. Default value: ``STDOUT``.

**windows_package** Updates
-----------------------------------------------------
The **windows_package** resource has two new attributes (``checksum`` and ``remote_file_attributes``) and the ``source`` attribute now supports using a URL:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Attribute
     - Description
   * - ``checksum``
     - The SHA-256 checksum of the file. Use to prevent a file from being re-downloaded. When the local file matches the checksum, the chef-client does not download it. Use when a URL is specified by the ``source`` attribute.
   * - ``remote_file_attributes``
     - A package at a remote location define as a Hash of properties that modifes the properties of the **remote_file** resource.
   * - ``source``
     - Optional. The path to a package in the local file system. The location of the package may be at a URL. Default value: the ``name`` of the resource block. See "Syntax" section above for more information.

Examples:

**Specify a URL for the source attribute**

.. tag resource_package_windows_source_url

.. To install a package using a URL for the source:

.. code-block:: ruby

   windows_package '7zip' do
     source 'http://www.7-zip.org/a/7z938-x64.msi'
   end

.. end_tag

**Specify path and checksum**

.. tag resource_package_windows_source_url_checksum

.. To install a package using a URL for the source and specifying a checksum:

.. code-block:: ruby

   windows_package '7zip' do
     source 'http://www.7-zip.org/a/7z938-x64.msi'
     checksum '7c8e873991c82ad9cfc123415254ea6101e9a645e12977dcd518979e50fdedf3'
   end

.. end_tag

**Modify remote_file resource attributes**

.. tag resource_package_windows_source_remote_file_attributes

The **windows_package** resource may specify a package at a remote location using the ``remote_file_attributes`` property. This uses the **remote_file** resource to download the contents at the specified URL and passes in a Hash that modifes the properties of the :doc:`remote_file resource </resource_remote_file>`.

For example:

.. code-block:: ruby

   windows_package '7zip' do
     source 'http://www.7-zip.org/a/7z938-x64.msi'
     remote_file_attributes ({
       :path => 'C:\\7zip.msi',
       :checksum => '7c8e873991c82ad9cfc123415254ea6101e9a645e12977dcd518979e50fdedf3'
     })
   end

.. end_tag

knife client key
-----------------------------------------------------
.. tag knife_client_summary

The ``knife client`` subcommand is used to manage an API client list and their associated RSA public key-pairs. This allows authentication requests to be made to the Chef server by any entity that uses the Chef server API, such as the chef-client and knife.

.. end_tag

key create
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag knife_client_key_create

Use the ``key create`` argument to create a public key.

.. end_tag

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_client_key_create_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife client key create CLIENT_NAME (options)

.. end_tag

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_client_key_create_options

This argument has the following options:

``-e DATE``, ``--expiration-date DATE``
   The expiration date for the public key, specified as an ISO 8601 formatted string: ``YYYY-MM-DDTHH:MM:SSZ``. If this option is not specified, the public key will not have an expiration date. For example: ``2013-12-24T21:00:00Z``.

``-f FILE``, ``--file FILE``
   Save a private key to the specified file name. If the ``--public-key`` option is not specified the Chef server will generate a private key.

``-k NAME``, ``--key-name NAME``
   The name of the public key.

``-p FILE_NAME``, ``--public-key FILE_NAME``
   The path to a file that contains the public key. If this option is not specified, and only if ``--key-name`` is specified, the Chef server will generate a public/private key pair.

.. end_tag

key delete
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag knife_client_key_delete

Use the ``key delete`` argument to delete a public key.

.. end_tag

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_client_key_delete_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife client key delete CLIENT_NAME KEY_NAME

.. end_tag

key edit
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag knife_client_key_edit

Use the ``key edit`` argument to modify or rename a public key.

.. end_tag

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_client_key_edit_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife client key edit CLIENT_NAME KEY_NAME (options)

.. end_tag

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_client_key_edit_options

This argument has the following options:

``-c``, ``--create-key``
   Generate a new public/private key pair and replace an existing public key with the newly-generated public key. To replace the public key with an existing public key, use ``--public-key`` instead.

``-e DATE``, ``--expiration-date DATE``
   The expiration date for the public key, specified as an ISO 8601 formatted string: ``YYYY-MM-DDTHH:MM:SSZ``. If this option is not specified, the public key will not have an expiration date. For example: ``2013-12-24T21:00:00Z``.

``-f FILE``, ``--file FILE``
   Save a private key to the specified file name. If the ``--public-key`` option is not specified the Chef server will generate a private key.

``-k NAME``, ``--key-name NAME``
   The name of the public key.

``-p FILE_NAME``, ``--public-key FILE_NAME``
   The path to a file that contains the public key. If this option is not specified, and only if ``--key-name`` is specified, the Chef server will generate a public/private key pair.

.. end_tag

key list
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag knife_client_key_list

Use the ``key list`` argument to view a list of public keys for the named client.

.. end_tag

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_client_key_list_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife client key list CLIENT_NAME (options)

.. end_tag

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_client_key_list_options

This argument has the following options:

``-e``, ``--only-expired``
   Show a list of public keys that have expired.

``-n``, ``--only-non-expired``
   Show a list of public keys that have not expired.

``-w``, ``--with-details``
   Show a list of public keys, including URIs and expiration status.

.. end_tag

key show
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag knife_client_key_show

Use the ``key show`` argument to view details for a specific public key.

.. end_tag

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_client_key_show_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife client key show CLIENT_NAME KEY_NAME

.. end_tag

knife user key
-----------------------------------------------------
.. tag knife_user_summary

The ``knife user`` subcommand is used to manage the list of users and their associated RSA public key-pairs.

.. end_tag

key create
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag knife_user_key_create

Use the ``key create`` argument to create a public key.

.. end_tag

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_user_key_create_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife user key create USER_NAME (options)

.. end_tag

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_user_key_create_options

This argument has the following options:

``-e DATE``, ``--expiration-date DATE``
   The expiration date for the public key, specified as an ISO 8601 formatted string: ``YYYY-MM-DDTHH:MM:SSZ``. If this option is not specified, the public key will not have an expiration date. For example: ``2013-12-24T21:00:00Z``.

``-f FILE``, ``--file FILE``
   Save a private key to the specified file name.

``-k NAME``, ``--key-name NAME``
   The name of the public key.

``-p FILE_NAME``, ``--public-key FILE_NAME``
   The path to a file that contains the public key. If this option is not specified, and only if ``--key-name`` is specified, the Chef server will generate a public/private key pair.

.. end_tag

key delete
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag knife_user_key_delete

Use the ``key delete`` argument to delete a public key.

.. end_tag

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_user_key_delete_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife user key delete USER_NAME KEY_NAME

.. end_tag

key edit
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag knife_user_key_edit

Use the ``key edit`` argument to modify or rename a public key.

.. end_tag

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_user_key_edit_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife user key edit USER_NAME KEY_NAME (options)

.. end_tag

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_user_key_edit_options

This argument has the following options:

``-c``, ``--create-key``
   Generate a new public/private key pair and replace an existing public key with the newly-generated public key. To replace the public key with an existing public key, use ``--public-key`` instead.

``-e DATE``, ``--expiration-date DATE``
   The expiration date for the public key, specified as an ISO 8601 formatted string: ``YYYY-MM-DDTHH:MM:SSZ``. If this option is not specified, the public key will not have an expiration date. For example: ``2013-12-24T21:00:00Z``.

``-f FILE``, ``--file FILE``
   Save a private key to the specified file name. If the ``--public-key`` option is not specified the Chef server will generate a private key.

``-k NAME``, ``--key-name NAME``
   The name of the public key.

``-p FILE_NAME``, ``--public-key FILE_NAME``
   The path to a file that contains the public key. If this option is not specified, and only if ``--key-name`` is specified, the Chef server will generate a public/private key pair.

.. end_tag

key list
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag knife_user_key_list

Use the ``key list`` argument to view a list of public keys for the named user.

.. end_tag

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_user_key_list_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife user key list USER_NAME (options)

.. end_tag

Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_user_key_list_options

This argument has the following options:

``-e``, ``--only-expired``
   Show a list of public keys that have expired.

``-n``, ``--only-non-expired``
   Show a list of public keys that have not expired.

``-w``, ``--with-details``
   Show a list of public keys, including URIs and expiration status.

.. end_tag

key show
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag knife_user_key_show

Use the ``key show`` argument to view details for a specific public key.

.. end_tag

Syntax
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag knife_user_key_show_syntax

This argument has the following syntax:

.. code-block:: bash

   $ knife user key show USER_NAME KEY_NAME

.. end_tag

Updated knife Options
-----------------------------------------------------
With the new key management subcommands, the options for ``knife client create`` and ``knife user create`` have changed.

knife client create
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag knife_client_create_options

This argument has the following options:

``-a``, ``--admin``
   Create a client as an admin client. This is required for any user to access Open Source Chef as an administrator.  This option only works when used with the open source Chef server and will have no effect when used with Enterprise Chef or Chef server 12.x.

``-f FILE``, ``--file FILE``
   Save a private key to the specified file name.

``-k``, ``--prevent-keygen``
   Create a user without a public key. This key may be managed later by using the ``knife user key`` subcommands.

   .. note:: .. tag notes_knife_prevent_keygen

             This option is valid only with Chef server API, version 1.0, which was released with Chef server 12.1. If this option or the ``--user-key`` option are not passed in the command, the Chef server will create a user with a public key named ``default`` and will return the private key. For the Chef server versions earlier than 12.1, this option will not work; a public key is always generated unless ``--user-key`` is passed in the command.

             .. end_tag

``-p FILE``, ``--public-key FILE``
   The path to a file that contains the public key. This option may not be passed in the same command with ``--prevent-keygen``. When using Open Source Chef a default key is generated if this option is not passed in the command. For Chef server version 12.x, see the ``--prevent-keygen`` option.

``--validator``
   Create the client as the chef-validator. Default value: ``true``.

.. end_tag

knife user create
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This argument has the following options:

``-a``, ``--admin``
   Create a client as an admin client. This is required for any user to access Open Source Chef as an administrator. This option only works when used with the open source Chef server and will have no effect when used with Enterprise Chef or Chef server 12.x.

``-f FILE_NAME``, ``--file FILE_NAME``
   Save a private key to the specified file name.

``-k``, ``--prevent-keygen``
   Create a user without a public key. This key may be managed later by using the ``knife user key`` subcommands.

   .. note:: .. tag notes_knife_prevent_keygen

             This option is valid only with Chef server API, version 1.0, which was released with Chef server 12.1. If this option or the ``--user-key`` option are not passed in the command, the Chef server will create a user with a public key named ``default`` and will return the private key. For the Chef server versions earlier than 12.1, this option will not work; a public key is always generated unless ``--user-key`` is passed in the command.

             .. end_tag

``-p PASSWORD``, ``--password PASSWORD``
   The user password. This option only works when used with the open source Chef server and will have no effect when used with Enterprise Chef or Chef server 12.x.

``--user-key FILE_NAME``
   The path to a file that contains the public key. When using Open Source Chef a default key is generated if this option is not passed in the command. For Chef server version 12.x, see the ``--prevent-keygen`` option.

What's New in 12.3
=====================================================
The following items are new for chef-client 12.3 and/or are changes from previous versions. The short version:

* **Socketless local mode with chef-zero** Port binding and HTTP requests on localhost may be disabled in favor of socketless mode.
* **Minimal Ohai plugins** Run only the plugins required for name resolution and resource/provider detection.
* **Dynamic resource and provider resolution** Four helper methods may be used in a library file to get resource and/or provider mapping details, and then set them per-resource or provider.
* **New clear_soruces attribute for the chef_gem and gem_package resources** Set to ``true`` to download a gem from the path specified by the ``source`` property (and not from RubyGems).

Socketless Local Mode
-----------------------------------------------------
The chef-client may disable port binding and HTTP requests on localhost by making a socketless request to chef-zero. This may be done from the command line or with a configuration setting.

Use the following command-line option:

``--[no-]listen``
   Run chef-zero in socketless mode. Use ``--no-listen`` to disable port binding and HTTP requests on localhost.

Or add the following setting to the client.rb file:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Setting
     - Description
   * - ``listen``
     - Run chef-zero in socketless mode. Set to ``false`` to disable port binding and HTTP requests on localhost.

Minimal Ohai
-----------------------------------------------------
The following option may be used with chef-client, chef-solo, and chef-apply to speed up testing intervals:

``--minimal-ohai``
   Run the Ohai plugins for name detection and resource/provider selection and no other Ohai plugins. Set to ``true`` during integration testing to speed up test cycles.

This setting may be configured using the ``minimal_ohai`` setting in the client.rb file.

Dynamic Resolution
-----------------------------------------------------
.. tag libraries_dynamic_resolution

Resources and providers are resolved dynamically and can handle multiple ``provides`` lines for a specific platform. When multiple ``provides`` lines exist, such as ``Homebrew`` and ``MacPorts`` packages for the macOS platform, then one is selected based on resource priority mapping performed by the chef-client during the chef-client run.

Use the following helpers in a library file to get and/or set resource and/or provider priority mapping before any recipes are compiled:

``Chef.get_provider_priority_array(resource_name)``
   Get the priority mapping for a provider.

``Chef.get_resource_priority_array(resource_name)``
   Get the priority mapping for a resource.

``Chef.set_provider_priority_array(resource_name, Array<Class>, *filter)``
   Set the priority mapping for a provider.

``Chef.set_resource_priority_array(resource_name, Array<Class>, *filter)``
   Set the priority mapping for a resource.

For example:

.. code-block:: ruby

   Chef.set_resource_priority_array(:package, [ Chef::Resource::MacportsPackage ], os: 'darwin')

.. end_tag

What's New in 12.2
=====================================================
The following items are new for chef-client 12.2 and/or are changes from previous versions. The short version:

* **New dsc_resource** Use the **dsc_resource** resource to use any DSC resource in a Chef recipe.
* **New --exit-on-error option for knife-ssh** Use the ``--exit-on-error`` option to have the ``knife ssh`` subcommand exit on any error.

dsc_resource
-----------------------------------------------------

.. tag resources_common_powershell

Windows PowerShell is a task-based command-line shell and scripting language developed by Microsoft. Windows PowerShell uses a document-oriented approach for managing Microsoft Windows-based machines, similar to the approach that is used for managing UNIX- and Linux-based machines. Windows PowerShell is `a tool-agnostic platform <http://technet.microsoft.com/en-us/library/bb978526.aspx>`_ that supports using Chef for configuration management.

.. end_tag

.. tag resources_common_powershell_dsc

Desired State Configuration (DSC) is a feature of Windows PowerShell that provides `a set of language extensions, cmdlets, and resources <http://technet.microsoft.com/en-us/library/dn249912.aspx>`_ that can be used to declaratively configure software. DSC is similar to Chef, in that both tools are idempotent, take similar approaches to the concept of resources, describe the configuration of a system, and then take the steps required to do that configuration. The most important difference between Chef and DSC is that Chef uses Ruby and DSC is exposed as configuration data from within Windows PowerShell.

.. end_tag

.. tag resource_dsc_resource_summary

The **dsc_resource** resource allows any DSC resource to be used in a Chef recipe, as well as any custom resources that have been added to your Windows PowerShell environment. Microsoft `frequently adds new resources <https://github.com/powershell/DscResources>`_ to the DSC resource collection.

.. end_tag

.. warning:: .. tag resource_dsc_resource_requirements

             Using the **dsc_resource** has the following requirements:

             * Windows Management Framework (WMF) 5.0 February Preview (or higher), which includes Windows PowerShell 5.0.10018.0 (or higher).
             * The ``RefreshMode`` configuration setting in the Local Configuration Manager must be set to ``Disabled``.

               **NOTE:** Starting with the chef-client 12.6 release, this requirement applies only for versions of Windows PowerShell earlier than 5.0.10586.0. The latest version of Windows Management Framework (WMF) 5 has relaxed the limitation that prevented the chef-client from running in non-disabled refresh mode.

             * The **dsc_script** resource  may not be used in the same run-list with the **dsc_resource**. This is because the **dsc_script** resource requires that ``RefreshMode`` in the Local Configuration Manager be set to ``Push``, whereas the **dsc_resource** resource requires it to be set to ``Disabled``.

               **NOTE:** Starting with the chef-client 12.6 release, this requirement applies only for versions of Windows PowerShell earlier than 5.0.10586.0. The latest version of Windows Management Framework (WMF) 5 has relaxed the limitation that prevented the chef-client from running in non-disabled refresh mode, which allows the Local Configuration Manager to be set to ``Push``.

             * The **dsc_resource** resource can only use binary- or script-based resources. Composite DSC resources may not be used.

               This is because composite resources aren't "real" resources from the perspective of the the Local Configuration Manager (LCM). Composite resources are used by the "configuration" keyword from the ``PSDesiredStateConfiguration`` module, and then evaluated in that context. When using DSC to create the configuration document (the Managed Object Framework (MOF) file) from the configuration command, the composite resource is evaluated. Any individual resources from that composite resource are written into the Managed Object Framework (MOF) document. As far as the Local Configuration Manager (LCM) is concerned, there is no such thing as a composite resource. Unless that changes, the **dsc_resource** resource and/or ``Invoke-DscResource`` command cannot directly use them.

             .. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_dsc_resource_syntax_12_2

A **dsc_resource** resource block allows DSC resourcs to be used in a Chef recipe. For example, the DSC ``Archive`` resource:

.. code-block:: powershell

   Archive ExampleArchive {
     Ensure = "Present"
     Path = "C:\Users\Public\Documents\example.zip"
     Destination = "C:\Users\Public\Documents\ExtractionPath"
   }

and then the same **dsc_resource** with Chef:

.. code-block:: ruby

   dsc_resource 'example' do
      resource :archive
      property :ensure, 'Present'
      property :path, "C:\Users\Public\Documents\example.zip"
      property :destination, "C:\Users\Public\Documents\ExtractionPath"
    end

The full syntax for all of the properties that are available to the **dsc_resource** resource is:

.. code-block:: ruby

   dsc_resource 'name' do
     module_name                String
     notifies                   # see description
     property                   Symbol
     resource                   String
     subscribes                 # see description
   end

where

* ``dsc_resource`` is the resource
* ``name`` is the name of the resource block
* ``property`` is zero (or more) properties in the DSC resource, where each property is entered on a separate line, ``:dsc_property_name`` is the case-insensitive name of that property, and ``"property_value"`` is a Ruby value to be applied by the chef-client
* ``module_name``, ``property``, and ``resource`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This resource has the following properties:

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``module_name``
   **Ruby Type:** String

   The name of the module from which a DSC resource originates. If this property is not specified, it will be inferred.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag 5

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

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

``property``
   **Ruby Type:** Symbol

   A property from a Desired State Configuration (DSC) resource. Use this property multiple times, one for each property in the Desired State Configuration (DSC) resource. The format for this property must follow ``property :dsc_property_name, "property_value"`` for each DSC property added to the resource block.

   The ``:dsc_property_name`` must be a symbol.

   .. tag resource_dsc_resource_ruby_types

   Use the following Ruby types to define ``property_value``:

   .. list-table::
      :widths: 250 250
      :header-rows: 1

      * - Ruby
        - Windows PowerShell
      * - ``Array``
        - ``Object[]``
      * - ``Chef::Util::Powershell:PSCredential``
        - ``PSCredential``
      * - ``FalseClass``
        - ``bool($false)``
      * - ``Fixnum``
        - ``Integer``
      * - ``Float``
        - ``Double``
      * - ``Hash``
        - ``Hashtable``
      * - ``TrueClass``
        - ``bool($true)``

   These are converted into the corresponding Windows PowerShell type during the chef-client run.

   .. end_tag

``resource``
   **Ruby Type:** String

   The name of the DSC resource. This value is case-insensitive and must be a symbol that matches the name of the DSC resource.

   .. tag resource_dsc_resource_features

   For built-in DSC resources, use the following values:

   .. list-table::
      :widths: 250 250
      :header-rows: 1

      * - Value
        - Description
      * - ``:archive``
        - Use to to `unpack archive (.zip) files <https://msdn.microsoft.com/en-us/powershell/dsc/archiveresource>`_.
      * - ``:environment``
        - Use to to `manage system environment variables <https://msdn.microsoft.com/en-us/powershell/dsc/environmentresource>`_.
      * - ``:file``
        - Use to to `manage files and directories <https://msdn.microsoft.com/en-us/powershell/dsc/fileresource>`_.
      * - ``:group``
        - Use to to `manage local groups <https://msdn.microsoft.com/en-us/powershell/dsc/groupresource>`_.
      * - ``:log``
        - Use to to `log configuration messages <https://msdn.microsoft.com/en-us/powershell/dsc/logresource>`_.
      * - ``:package``
        - Use to to `install and manage packages <https://msdn.microsoft.com/en-us/powershell/dsc/packageresource>`_.
      * - ``:registry``
        - Use to to `manage registry keys and registry key values <https://msdn.microsoft.com/en-us/powershell/dsc/registryresource>`_.
      * - ``:script``
        - Use to to `run Powershell script blocks <https://msdn.microsoft.com/en-us/powershell/dsc/scriptresource>`_.
      * - ``:service``
        - Use to to `manage services <https://msdn.microsoft.com/en-us/powershell/dsc/serviceresource>`_.
      * - ``:user``
        - Use to to `manage local user accounts <https://msdn.microsoft.com/en-us/powershell/dsc/userresource>`_.
      * - ``:windowsfeature``
        - Use to to `add or remove Windows features and roles <https://msdn.microsoft.com/en-us/powershell/dsc/windowsfeatureresource>`_.
      * - ``:windowsoptionalfeature``
        - Use to configure Microsoft Windows optional features.
      * - ``:windowsprocess``
        - Use to to `configure Windows processes <https://msdn.microsoft.com/en-us/powershell/dsc/windowsprocessresource>`_.

   Any DSC resource may be used in a Chef recipe. For example, the DSC Resource Kit contains resources for `configuring Active Directory components <http://www.powershellgallery.com/packages/xActiveDirectory/2.8.0.0>`_, such as ``xADDomain``, ``xADDomainController``, and ``xADUser``. Assuming that these resources are available to the chef-client, the corresponding values for the ``resource`` attribute would be: ``:xADDomain``, ``:xADDomainController``, and ``xADUser``.

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

   .. tag 5

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

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

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**Open a Zip file**

.. tag resource_dsc_resource_zip_file

.. To use a zip file:

.. code-block:: ruby

   dsc_resource 'example' do
      resource :archive
      property :ensure, 'Present'
      property :path, 'C:\Users\Public\Documents\example.zip'
      property :destination, 'C:\Users\Public\Documents\ExtractionPath'
    end

.. end_tag

**Manage users and groups**

.. tag resource_dsc_resource_manage_users

.. To manage users and groups

.. code-block:: ruby

   dsc_resource 'demogroupadd' do
     resource :group
     property :groupname, 'demo1'
     property :ensure, 'present'
   end

   dsc_resource 'useradd' do
     resource :user
     property :username, 'Foobar1'
     property :fullname, 'Foobar1'
     property :password, ps_credential('P@assword!')
     property :ensure, 'present'
   end

   dsc_resource 'AddFoobar1ToUsers' do
     resource :Group
     property :GroupName, 'demo1'
     property :MembersToInclude, ['Foobar1']
   end

.. end_tag

What's New in 12.1
=====================================================
The following items are new for chef-client 12.1 and/or are changes from previous versions. The short version:

* **chef-client may be run in audit-mode** Use audit-mode to run audit tests against a node.
* **control method added to Recipe DSL** Use the ``control`` method to define specific tests that match directories, files, packages, ports, and services. A ``control`` method must be contained within a ``control_group`` block.
* **control_group method added to Recipe DSL** Use the ``control_group`` method to group one (or more) ``control`` methods into a single audit.
* **Bootstrap nodes without using the ORGANIZATION-validator.key file** A node may now be bootstrapped using the USER.pem file, instead of the ORGANIZATION-validator.pem file. Also known as a "validatorless bootstrap".
* **New options for knife-bootstrap** Use the ``--bootstrap-vault-file``, ``--bootstrap-vault-item``, and ``--bootstrap-vault-json`` options with ``knife bootstrap`` to specify items that are stored in chef-vault.
* **New verify attribute for cookbook_file, file, remote_file, and template resources** Use the ``verify`` attribute to test a file using a block of code or a string.
* **New imports attribute for dsc_script resource** Use the ``imports`` attribute to import DSC resources from modules.
* **New attribute for chef_gem resource** Use the ``compile_time`` attribute to disable compile-time installation of gems.
* **New openbsd_package resource** Use the **openbsd_package** resource to install packages on the OpenBSD platform.
* **New --proxy-auth option for knife raw subcommand** Enable proxy authentication to the Chef server web user interface..
* **New watchdog_timeout setting for the Windows platform** Use the ``windows_service.watchdog_timeout`` setting in the client.rb file to specify the maximum amount of time allowed for a chef-client run on the Microsoft Windows platform.
* **Support for multiple packages and versions** Multiple packages and versions may be specified for platforms that use Yum or Apt.
* **New attributes for windows_service resource** Use the ``run_as_user`` and ``run_as_password`` attributes to specify the user under which a Microsoft Windows service should run.

chef-client, audit-mode
-----------------------------------------------------
.. tag chef_client_audit_mode

The chef-client may be run in audit-mode. Use audit-mode to evaluate custom rules---also referred to as audits---that are defined in recipes. audit-mode may be run in the following ways:

* By itself (i.e. a chef-client run that does not build the resource collection or converge the node)
* As part of the chef-client run, where audit-mode runs after all resources have been converged on the node

Each audit is authored within a recipe using the ``control_group`` and ``control`` methods that are part of the Recipe DSL. Recipes that contain audits are added to the run-list, after which they can be processed by the chef-client. Output will appear in the same location as the regular chef-client run (as specified by the ``log_location`` setting in the client.rb file).

Finished audits are reported back to the Chef server. From there, audits are sent to the Chef Analytics platform for further analysis, such as rules processing and visibility from the actions web user interface.

.. end_tag

Use following option to run the chef-client in audit-mode mode:

``--audit-mode MODE``
   Enable audit-mode. Set to ``audit-only`` to skip the converge phase of the chef-client run and only perform audits. Possible values: ``audit-only``, ``disabled``, and ``enabled``. Default value: ``disabled``.

The Audit Run
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following diagram shows the stages of the audit-mode phase of the chef-client run, and then the list below the diagram describes in greater detail each of those stages.

.. image:: ../../images/audit_run.png

When the chef-client is run in audit-mode, the following happens:

.. list-table::
   :widths: 150 450
   :header-rows: 1

   * - Stages
     - Description
   * - **chef-client Run ID**
     - The chef-client run identifier is associated with each audit.
   * - **Configure the Node**
     - If audit-mode is run as part of the full chef-client run, audit-mode occurs after the chef-client has finished converging all resources in the resource collection.
   * - **Audit node based on controls in cookbooks**
     - Each ``control_group`` and ``control`` block found in any recipe that was part of the run-list of for the node is evaluated, with each expression in each ``control`` block verified against the state of the node.
   * - **Upload audit data to the Chef server**
     - When audit-mode mode is complete, the data is uploaded to the Chef server.
   * - **Send to Chef Analytics**
     - Most of this data is passed to the Chef Analytics platform for further analysis, such as rules processing (for notification events triggered by expected or unexpected audit outcomes) and visibility from the actions web user interface.

control
-----------------------------------------------------
A control is an automated test that is built into a cookbook, and then used to test the state of the system for compliance. Compliance can be many things. For example, ensuring that file and directory management meets specific internal IT policies---"Does the file exist?", "Do the correct users or groups have access to this directory?". Compliance may also be complex, such as helping to ensure goals defined by large-scale compliance frameworks such as PCI, HIPAA, and Sarbanes-Oxley can be met.

.. tag dsl_recipe_method_control

Use the ``control`` method to define a specific series of tests that comprise an individual audit. A ``control`` method MUST be contained within a ``control_group`` block. A ``control_group`` block may contain multiple ``control`` methods.

.. end_tag

.. tag dsl_recipe_method_control_syntax

The syntax for the ``control`` method is as follows:

.. code-block:: ruby

   control_group 'audit name' do
     control 'name' do
       it 'should do something' do
         expect(something).to/.to_not be_something
       end
     end
   end

where:

* ``control_group`` groups one (or more) ``control`` blocks
* ``control 'name' do`` defines an individual audit
* Each ``control`` block must define at least one validation
* Each ``it`` statement defines a single validation. ``it`` statements are processed individually when the chef-client is run in audit-mode
* An ``expect(something).to/.to_not be_something`` is a statement that represents the individual test. In other words, this statement tests if something is expected to be (or not be) something. For example, a test that expects the PostgreSQL pacakge to not be installed would be similar to ``expect(package('postgresql')).to_not be_installed`` and a test that ensures a service is enabled would be similar to ``expect(service('init')).to be_enabled``
* An ``it`` statement may contain multiple ``expect`` statements

.. end_tag

directory Matcher
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_control_matcher_directory

Matchers are available for directories. Use this matcher to define audits for directories that test if the directory exists, is mounted, and if it is linked to. This matcher uses the same matching syntax---``expect(file('foo'))``---as the files. The following matchers are available for directories:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Matcher
     - Description, Example
   * - ``be_directory``
     - Use to test if directory exists. For example:

       .. code-block:: ruby

          it 'should be a directory' do
            expect(file('/var/directory')).to be_directory
          end

   * - ``be_linked_to``
     - Use to test if a subject is linked to the named directory. For example:

       .. code-block:: ruby

          it 'should be linked to the named directory' do
            expect(file('/etc/directory')).to be_linked_to('/etc/some/other/directory')
          end

   * - ``be_mounted``
     - Use to test if a directory is mounted. For example:

       .. code-block:: ruby

          it 'should be mounted' do
            expect(file('/')).to be_mounted
          end

       For directories with a single attribute that requires testing:

       .. code-block:: ruby

          it 'should be mounted with an ext4 partition' do
            expect(file('/')).to be_mounted.with( :type => 'ext4' )
          end

       For directories with multiple attributes that require testing:

       .. code-block:: ruby

          it 'should be mounted only with certain attributes' do
            expect(file('/')).to be_mounted.only_with(
              :attribute => 'value',
              :attribute => 'value',
          )
          end

.. end_tag

file Matcher
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_control_matcher_file

Matchers are available for files and directories. Use this matcher to define audits for files that test if the file exists, its version, if it is is executable, writable, or readable, who owns it, verify checksums (both MD5 and SHA-256) and so on. The following matchers are available for files:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Matcher
     - Description, Example
   * - ``be_executable``
     - Use to test if a file is executable. For example:

       .. code-block:: ruby

          it 'should be executable' do
            expect(file('/etc/file')).to be_executable
          end

       For a file that is executable by its owner:

       .. code-block:: ruby

          it 'should be executable by owner' do
            expect(file('/etc/file')).to be_executable.by('owner')
          end

       For a file that is executable by a group:

       .. code-block:: ruby

          it 'should be executable by group members' do
            expect(file('/etc/file')).to be_executable.by('group')
          end

       For a file that is executable by a specific user:

       .. code-block:: ruby

          it 'should be executable by user foo' do
            expect(file('/etc/file')).to be_executable.by_user('foo')
          end

   * - ``be_file``
     - Use to test if a file exists. For example:

       .. code-block:: ruby

          it 'should be a file' do
            expect(file('/etc/file')).to be_file
          end

   * - ``be_grouped_into``
     - Use to test if a file is grouped into the named group. For example:

       .. code-block:: ruby

          it 'should be grouped into foo' do
            expect(file('/etc/file')).to be_grouped_into('foo')
          end

   * - ``be_linked_to``
     - Use to test if a subject is linked to the named file. For example:

       .. code-block:: ruby

          it 'should be linked to the named file' do
            expect(file('/etc/file')).to be_linked_to('/etc/some/other/file')
          end

   * - ``be_mode``
     - Use to test if a file is set to the specified mode. For example:

       .. code-block:: ruby

          it 'should be mode 440' do
            expect(file('/etc/file')).to be_mode(440)
          end

   * - ``be_owned_by``
     - Use to test if a file is owned by the named owner. For example:

       .. code-block:: ruby

          it 'should be owned by the root user' do
            expect(file('/etc/sudoers')).to be_owned_by('root')
          end

   * - ``be_readable``
     - Use to test if a file is readable. For example:

       .. code-block:: ruby

          it 'should be readable' do
            expect(file('/etc/file')).to be_readable
          end

       For a file that is readable by its owner:

       .. code-block:: ruby

          it 'should be readable by owner' do
            expect(file('/etc/file')).to be_readable.by('owner')
          end

       For a file that is readable by a group:

       .. code-block:: ruby

          it 'should be readable by group members' do
            expect(file('/etc/file')).to be_readable.by('group')
          end

       For a file that is readable by a specific user:

       .. code-block:: ruby

          it 'should be readable by user foo' do
            expect(file('/etc/file')).to be_readable.by_user('foo')
          end

   * - ``be_socket``
     - Use to test if a file exists as a socket. For example:

       .. code-block:: ruby

          it 'should be a socket' do
            expect(file('/var/file.sock')).to be_socket
          end

   * - ``be_symlink``
     - Use to test if a file exists as a symbolic link. For example:

       .. code-block:: ruby

          it 'should be a symlink' do
            expect(file('/etc/file')).to be_symlink
          end

   * - ``be_version``
     - Microsoft Windows only. Use to test if a file is the specified version. For example:

       .. code-block:: ruby

          it 'should be version 1.2' do
            expect(file('C:\\Windows\\path\\to\\file')).to be_version('1.2')
          end

   * - ``be_writable``
     - Use to test if a file is writable. For example:

       .. code-block:: ruby

          it 'should be writable' do
            expect(file('/etc/file')).to be_writable
          end

       For a file that is writable by its owner:

       .. code-block:: ruby

          it 'should be writable by owner' do
            expect(file('/etc/file')).to be_writable.by('owner')
          end

       For a file that is writable by a group:

       .. code-block:: ruby

          it 'should be writable by group members' do
            expect(file('/etc/file')).to be_writable.by('group')
          end

       For a file that is writable by a specific user:

       .. code-block:: ruby

          it 'should be writable by user foo' do
            expect(file('/etc/file')).to be_writable.by_user('foo')
          end

   * - ``contain``
     - Use to test if a file contains specific contents. For example:

       .. code-block:: ruby

          it 'should contain docs.chef.io' do
            expect(file('/etc/file')).to contain('docs.chef.io')
          end

.. end_tag

package Matcher
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_control_matcher_package

Matchers are available for packages and may be used to define audits that test if a package or a package version is installed. The following matchers are available:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Matcher
     - Description, Example
   * - ``be_installed``
     - Use to test if the named package is installed. For example:

       .. code-block:: ruby

          it 'should be installed' do
            expect(package('httpd')).to be_installed
          end

       For a specific package version:

       .. code-block:: ruby

          it 'should be installed' do
            expect(package('httpd')).to be_installed.with_version('0.1.2')
          end

.. end_tag

port Matcher
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_control_matcher_port

Matchers are available for ports and may be used to define audits that test if a port is listening. The following matchers are available:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Matcher
     - Description, Example
   * - ``be_listening``
     - Use to test if the named port is listening. For example:

       .. code-block:: ruby

          it 'should be listening' do
            expect(port(23)).to be_listening
          end

       For a named port that is not listening:

       .. code-block:: ruby

          it 'should not be listening' do
            expect(port(23)).to_not be_listening
          end

       For a specific port type use ``.with('port_type')``. For example, UDP:

       .. code-block:: ruby

          it 'should be listening with UDP' do
            expect(port(23)).to_not be_listening.with('udp')
          end

       For UDP, version 6:

       .. code-block:: ruby

          it 'should be listening with UDP6' do
            expect(port(23)).to_not be_listening.with('udp6')
          end

       For TCP/IP:

       .. code-block:: ruby

          it 'should be listening with TCP' do
            expect(port(23)).to_not be_listening.with('tcp')
          end

       For TCP/IP, version 6:

       .. code-block:: ruby

          it 'should be listening with TCP6' do
            expect(port(23)).to_not be_listening.with('tcp6')
          end

.. end_tag

service Matcher
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_control_matcher_service

Matchers are available for services and may be used to define audits that test for conditions related to services, such as if they are enabled, running, have the correct startup mode, and so on. The following matchers are available:

.. list-table::
   :widths: 60 420
   :header-rows: 1

   * - Matcher
     - Description, Example
   * - ``be_enabled``
     - Use to test if the named service is enabled (i.e. will start up automatically). For example:

       .. code-block:: ruby

          it 'should be enabled' do
            expect(service('ntpd')).to be_enabled
          end

       For a service that is enabled at a given run level:

       .. code-block:: ruby

          it 'should be enabled at the specified run level' do
            expect(service('ntpd')).to be_enabled.with_level(3)
          end

   * - ``be_installed``
     - Microsoft Windows only. Use to test if the named service is installed on the Microsoft Windows platform. For example:

       .. code-block:: ruby

          it 'should be installed' do
            expect(service('DNS Client')).to be_installed
          end

   * - ``be_running``
     - Use to test if the named service is running. For example:

       .. code-block:: ruby

          it 'should be running' do
            expect(service('ntpd')).to be_running
          end

       For a service that is running under supervisor:

       .. code-block:: ruby

          it 'should be running under supervisor' do
            expect(service('ntpd')).to be_running.under('supervisor')
          end

       or daemontools:

       .. code-block:: ruby

          it 'should be running under daemontools' do
            expect(service('ntpd')).to be_running.under('daemontools')
          end

       or Upstart:

       .. code-block:: ruby

          it 'should be running under upstart' do
            expect(service('ntpd')).to be_running.under('upstart')
          end

   * - ``be_monitored_by``
     - Use to test if the named service is being monitored by the named monitoring application. For example:

       .. code-block:: ruby

          it 'should be monitored by' do
            expect(service('ntpd')).to be_monitored_by('monit')
          end

   * - ``have_start_mode``
     - Microsoft Windows only. Use to test if the named service's startup mode is correct on the Microsoft Windows platform. For example:

       .. code-block:: ruby

          it 'should start manually' do
            expect(service('DNS Client')).to have_start_mode.Manual
          end

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**A package is installed**

.. tag dsl_recipe_control_matcher_package_installed

For example, a package is installed:

.. code-block:: ruby

   control_group 'audit name' do
     control 'mysql package' do
       it 'should be installed' do
         expect(package('mysql')).to be_installed
       end
     end
   end

The ``control_group`` block is processed when the chef-client run is run in audit-mode. If the audit was successful, the chef-client will return output similar to:

.. code-block:: bash

   Audit Mode
     mysql package
       should be installed

If an audit was unsuccessful, the chef-client will return output similar to:

.. code-block:: bash

   Starting audit phase

   Audit Mode
     mysql package
     should be installed (FAILED - 1)

   Failures:

   1) Audit Mode mysql package should be installed
     Failure/Error: expect(package('mysql')).to be_installed.with_version('5.6')
       expected Package 'mysql' to be installed
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:22:in 'block (3 levels) in from_file'

   Finished in 0.5745 seconds (files took 0.46481 seconds to load)
   1 examples, 1 failures

   Failed examples:

   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:21 # Audit Mode mysql package should be installed

.. end_tag

**A package version is installed**

.. tag dsl_recipe_control_matcher_package_installed_version

A package that is installed with a specific version:

.. code-block:: ruby

   control_group 'audit name' do
     control 'mysql package' do
       it 'should be installed' do
         expect(package('mysql')).to be_installed.with_version('5.6')
       end
     end
   end

.. end_tag

**A package is not installed**

.. tag dsl_recipe_control_matcher_package_not_installed

A package that is not installed:

.. code-block:: ruby

   control_group 'audit name' do
     control 'postgres package' do
       it 'should not be installed' do
         expect(package('postgresql')).to_not be_installed
       end
     end
   end

If the audit was successful, the chef-client will return output similar to:

.. code-block:: bash

   Audit Mode
     postgres audit
       postgres package
         is not installed

.. end_tag

**A service is enabled**

.. tag dsl_recipe_control_matcher_service_enabled

A service that is enabled and running:

.. code-block:: ruby

   control_group 'audit name' do
     control 'mysql service' do
       let(:mysql_service) { service('mysql') }
       it 'should be enabled' do
         expect(mysql_service).to be_enabled
       end
       it 'should be running' do
         expect(mysql_service).to be_running
       end
     end
   end

If the audit was successful, the chef-client will return output similar to:

.. code-block:: bash

   Audit Mode
     mysql service audit
       mysql service
         is enabled
         is running

.. end_tag

**A configuration file contains specific settings**

.. tag dsl_recipe_control_matcher_file_sshd_configuration

The following example shows how to verify ``sshd`` configration, including whether it's installed, what the permissions are, and how it can be accessed:

.. code-block:: ruby

   control_group 'check sshd configuration' do

     control 'sshd package' do
       it 'should be installed' do
         expect(package('openssh-server')).to be_installed
       end
     end

     control 'sshd configuration' do
       let(:config_file) { file('/etc/ssh/sshd_config') }
       it 'should exist with the right permissions' do
         expect(config_file).to be_file
         expect(config_file).to be_mode(644)
         expect(config_file).to be_owned_by('root')
         expect(config_file).to be_grouped_into('root')
       end
       it 'should not permit RootLogin' do
         expect(config_file.content).to_not match(/^PermitRootLogin yes/)
       end
       it 'should explicitly not permit PasswordAuthentication' do
         expect(config_file.content).to match(/^PasswordAuthentication no/)
       end
       it 'should force privilege separation' do
         expect(config_file.content).to match(/^UsePrivilegeSeparation sandbox/)
       end
     end
   end

where

* ``let(:config_file) { file('/etc/ssh/sshd_config') }`` uses the ``file`` matcher to test specific settings within the ``sshd`` configuration file

.. end_tag

**A file contains desired permissions and contents**

.. tag dsl_recipe_control_matcher_file_permissions

The following example shows how to verify that a file has the desired permissions and contents:

.. code-block:: ruby

   controls 'mysql config' do
     control 'mysql config file' do
       let(:config_file) { file('/etc/mysql/my.cnf') }
       it 'exists with correct permissions' do
         expect(config_file).to be_file
         expect(config_file).to be_mode(0400)
       end
       it 'contains required configuration' do
         expect(its('contents')).to match(/default-time-zone='UTC'/)
       end
     end
   end

If the audit was successful, the chef-client will return output similar to:

.. code-block:: bash

   Audit Mode
     mysql config
       mysql config file
         exists with correct permissions
         contains required configuration

.. end_tag

control_group
-----------------------------------------------------
.. tag dsl_recipe_method_control_group

Use the ``control_group`` method to define a group of ``control`` methods that comprise a single audit. The name of each ``control_group`` must be unique within the organization.

.. end_tag

.. tag dsl_recipe_method_control_group_syntax

The syntax for the ``control_group`` method is as follows:

.. code-block:: ruby

   control_group 'name' do
     control 'name' do
       it 'should do something' do
         expect(something).to/.to_not be_something
       end
     end
     control 'name' do
       ...
     end
     ...
   end

where:

* ``control_group`` groups one (or more) ``control`` blocks
* ``'name'`` is the unique name for the ``control_group``; the chef-client will raise an exception if duplicate ``control_group`` names are present
* ``control`` defines each individual audit within the ``control_group`` block. There is no limit to the number of ``control`` blocks that may defined within a ``control_group`` block

.. end_tag

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**control_group block with multiple control blocks**

.. tag dsl_recipe_control_group_many_controls

The following ``control_group`` ensures that MySQL is installed, that PostgreSQL is not installed, and that the services and configuration files associated with MySQL are configured correctly:

.. code-block:: ruby

   control_group 'Audit Mode' do

     control 'mysql package' do
       it 'should be installed' do
         expect(package('mysql')).to be_installed.with_version('5.6')
       end
     end

     control 'postgres package' do
       it 'should not be installed' do
         expect(package('postgresql')).to_not be_installed
       end
     end

     control 'mysql service' do
       let(:mysql_service) { service('mysql') }
       it 'should be enabled' do
         expect(mysql_service).to be_enabled
       end
       it 'should be running' do
         expect(mysql_service).to be_running
       end
     end

     control 'mysql config directory' do
       let(:config_dir) { file('/etc/mysql') }
       it 'should exist with correct permissions' do
         expect(config_dir).to be_directory
         expect(config_dir).to be_mode(0700)
       end
       it 'should be owned by the db user' do
         expect(config_dir).to be_owned_by('db_service_user')
       end
     end

     control 'mysql config file' do
       let(:config_file) { file('/etc/mysql/my.cnf') }
       it 'should exist with correct permissions' do
         expect(config_file).to be_file
         expect(config_file).to be_mode(0400)
       end
       it 'should contain required configuration' do
         expect(config_file.content).to match(/default-time-zone='UTC'/)
       end
     end

   end

The ``control_group`` block is processed when the chef-client is run in audit-mode. If the chef-client run was successful, the chef-client will return output similar to:

.. code-block:: bash

   Audit Mode
     mysql package
       should be installed
     postgres package
       should not be installed
     mysql service
       should be enabled
       should be running
     mysql config directory
       should exist with correct permissions
       should be owned by the db user
     mysql config file
       should exist with correct permissions
       should contain required configuration

If an audit was unsuccessful, the chef-client will return output similar to:

.. code-block:: bash

   Starting audit phase

   Audit Mode
     mysql package
     should be installed (FAILED - 1)
   postgres package
     should not be installed
   mysql service
     should be enabled (FAILED - 2)
     should be running (FAILED - 3)
   mysql config directory
     should exist with correct permissions (FAILED - 4)
     should be owned by the db user (FAILED - 5)
   mysql config file
     should exist with correct permissions (FAILED - 6)
     should contain required configuration (FAILED - 7)

   Failures:

   1) Audit Mode mysql package should be installed
     Failure/Error: expect(package('mysql')).to be_installed.with_version('5.6')
       expected Package 'mysql' to be installed
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:22:in 'block (3 levels) in from_file'

   2) Audit Mode mysql service should be enabled
     Failure/Error: expect(mysql_service).to be_enabled
       expected Service 'mysql' to be enabled
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:35:in 'block (3 levels) in from_file'

   3) Audit Mode mysql service should be running
      Failure/Error: expect(mysql_service).to be_running
       expected Service 'mysql' to be running
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:38:in 'block (3 levels) in from_file'

   4) Audit Mode mysql config directory should exist with correct permissions
     Failure/Error: expect(config_dir).to be_directory
       expected `File '/etc/mysql'.directory?` to return true, got false
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:45:in 'block (3 levels) in from_file'

   5) Audit Mode mysql config directory should be owned by the db user
     Failure/Error: expect(config_dir).to be_owned_by('db_service_user')
       expected `File '/etc/mysql'.owned_by?('db_service_user')` to return true, got false
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:49:in 'block (3 levels) in from_file'

   6) Audit Mode mysql config file should exist with correct permissions
     Failure/Error: expect(config_file).to be_file
       expected `File '/etc/mysql/my.cnf'.file?` to return true, got false
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:56:in 'block (3 levels) in from_file'

   7) Audit Mode mysql config file should contain required configuration
     Failure/Error: expect(config_file.content).to match(/default-time-zone='UTC'/)
       expected '-n\n' to match /default-time-zone='UTC'/
       Diff:
       @@ -1,2 +1,2 @@
       -/default-time-zone='UTC'/
       +-n
     # /var/chef/cache/cookbooks/grantmc/recipes/default.rb:60:in 'block (3 levels) in from_file'

   Finished in 0.5745 seconds (files took 0.46481 seconds to load)
   8 examples, 7 failures

   Failed examples:

   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:21 # Audit Mode mysql package should be installed
   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:34 # Audit Mode mysql service should be enabled
   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:37 # Audit Mode mysql service should be running
   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:44 # Audit Mode mysql config directory should exist with correct permissions
   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:48 # Audit Mode mysql config directory should be owned by the db user
   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:55 # Audit Mode mysql config file should exist with correct permissions
   rspec /var/chef/cache/cookbooks/grantmc/recipes/default.rb:59 # Audit Mode mysql config file should contain required configuration
   Auditing complete

.. end_tag

**Duplicate control_group names**

.. tag dsl_recipe_control_group_duplicate_names

If two ``control_group`` blocks have the same name, the chef-client will raise an exception. For example, the following ``control_group`` blocks exist in different cookbooks:

.. code-block:: ruby

   control_group 'basic control group' do
     it 'should pass' do
       expect(2 - 2).to eq(0)
     end
   end

.. code-block:: ruby

   control_group 'basic control group' do
     it 'should pass' do
       expect(3 - 2).to eq(1)
     end
   end

Because the two ``control_group`` block names are identical, the chef-client will return an exception similar to:

.. code-block:: ruby

   Synchronizing Cookbooks:
     - audit_test
   Compiling Cookbooks...

   ================================================================================
   Recipe Compile Error in /Users/grantmc/.cache/chef/cache/cookbooks
                           /audit_test/recipes/error_duplicate_control_groups.rb
   ================================================================================

   Chef::Exceptions::AuditControlGroupDuplicate
   --------------------------------------------
   Audit control group with name 'basic control group' has already been defined

   Cookbook Trace:
   ---------------
   /Users/grantmc/.cache/chef/cache/cookbooks
   /audit_test/recipes/error_duplicate_control_groups.rb:13:in 'from_file'

   Relevant File Content:
   ----------------------
   /Users/grantmc/.cache/chef/cache/cookbooks/audit_test/recipes/error_duplicate_control_groups.rb:

   control_group 'basic control group' do
     it 'should pass' do
       expect(2 - 2).to eq(0)
     end
   end

   control_group 'basic control group' do
     it 'should pass' do
       expect(3 - 2).to eq(1)
     end
   end

   Running handlers:
   [2015-01-15T09:36:14-08:00] ERROR: Running exception handlers
   Running handlers complete

.. end_tag

**Verify a package is installed**

.. tag dsl_recipe_control_group_simple_recipe

The following ``control_group`` verifies that the ``git`` package has been installed:

.. code-block:: ruby

   package 'git' do
     action :install
   end

   execute 'list packages' do
     command 'dpkg -l'
   end

   execute 'list directory' do
     command 'ls -R ~'
   end

   control_group 'my audits' do
     control 'check git' do
       it 'should be installed' do
         expect(package('git')).to be_installed
       end
     end
   end

.. end_tag

Validatorless Bootstrap
-----------------------------------------------------
.. tag knife_bootstrap_no_validator

The ORGANIZATION-validator.pem is typically added to the .chef directory on the workstation. When a node is bootstrapped from that workstation, the ORGANIZATION-validator.pem is used to authenticate the newly-created node to the Chef server during the initial chef-client run. Starting with Chef client 12.1, it is possible to bootstrap a node using the USER.pem file instead of the ORGANIZATION-validator.pem file. This is known as a "validatorless bootstrap".

To create a node via the USER.pem file, simply delete the ORGANIZATION-validator.pem file on the workstation. For example:

.. code-block:: bash

   $ rm -f /home/lamont/.chef/myorg-validator.pem

and then make the following changes in the knife.rb file:

* Remove the ``validation_client_name`` setting
* Edit the ``validation_key`` setting to be something that isn't a path to an existent ORGANIZATION-validator.pem file. For example: ``/nonexist``.

As long as a USER.pem is also present on the workstation from which the validatorless bootstrap operation will be initiated, the bootstrap operation will run and will use the USER.pem file instead of the ORGANIZATION-validator.pem file.

When running a validatorless ``knife bootstrap`` operation, the output is similar to:

.. code-block:: bash

   desktop% knife bootstrap 10.1.1.1 -N foo01.acme.org \
     -E dev -r 'role[base]' -j '{ "foo": "bar" }' \
     --ssh-user vagrant --sudo
   Node foo01.acme.org exists, overwrite it? (Y/N)
   Client foo01.acme.org exists, overwrite it? (Y/N)
   Creating new client for foo01.acme.org
   Creating new node for foo01.acme.org
   Connecting to 10.1.1.1
   10.1.1.1 Starting first Chef Client run...
   [....etc...]

.. end_tag

knife bootstrap Options
+++++++++++++++++++++++++++++++++++++++++++++++++++++
Use the following options to specify items that are stored in chef-vault:

``--bootstrap-vault-file VAULT_FILE``
   The path to a JSON file that contains a list of vaults and items to be updated.

``--bootstrap-vault-item VAULT_ITEM``
   A single vault and item to update as ``vault:item``.

``--bootstrap-vault-json VAULT_JSON``
   A JSON string that contains a list of vaults and items to be updated.

   .. tag knife_bootstrap_vault_json

   For example:

   .. code-block:: none

      --bootstrap-vault-json '{ "vault1": ["item1", "item2"], "vault2": "item2" }'

   .. end_tag

New Resource Attributes
-----------------------------------------------------
The following attributes are new for chef-client 12.1.

verify
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The ``verify`` attribute may be used with the **cookbook_file**, **file**, **remote_file**, and **template** resources.

``verify``
   A block or a string that returns ``true`` or ``false``. A string, when ``true`` is executed as a system command.

   The following examples show how the ``verify`` attribute is used with the **template** resource. The same approach (but with different resource names) is true for the **cookbook_file**, **file**, and **remote_file** resources:

   .. tag resource_template_attributes_verify

   A block is arbitrary Ruby defined within the resource block by using the ``verify`` property. When a block is ``true``, the chef-client will continue to update the file as appropriate.

   For example, this should return ``true``:

   .. code-block:: ruby

      template '/tmp/baz' do
        verify { 1 == 1 }
      end

   This should return ``true``:

   .. code-block:: ruby

      template '/etc/nginx.conf' do
        verify 'nginx -t -c %{path}'
      end

   .. warning:: For releases of the chef-client prior to 12.5 (chef-client 12.4 and earlier) the correct syntax is:

      .. code-block:: ruby

         template '/etc/nginx.conf' do
           verify 'nginx -t -c %{file}'
         end

      See GitHub issues https://github.com/chef/chef/issues/3232 and https://github.com/chef/chef/pull/3693 for more information about these differences.

   This should return ``true``:

   .. code-block:: ruby

      template '/tmp/bar' do
        verify { 1 == 1}
      end

   And this should return ``true``:

   .. code-block:: ruby

      template '/tmp/foo' do
        verify do |path|
          true
        end
      end

   Whereas, this should return ``false``:

   .. code-block:: ruby

      template '/tmp/turtle' do
        verify '/usr/bin/false'
      end

   If a string or a block return ``false``, the chef-client run will stop and an error is returned.

   .. end_tag

imports
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following attribute is new for the **dsc_script** resource:

``imports``
   Use to import DSC resources from a module. To import all resources from a module, specify only the module name:

   .. code-block:: ruby

      imports "module_name"

   To import specific resources, specify the module name and then the name for each resource in that module to import:

   .. code-block:: ruby

      imports "module_name", "resource_name_a", "resource_name_b", ...

   For example, to import all resources from a module named ``cRDPEnabled``:

   .. code-block:: ruby

      imports "cRDPEnabled"

   And to import only the ``PSHOrg_cRDPEnabled`` resource:

   .. code-block:: ruby

      imports "cRDPEnabled", "PSHOrg_cRDPEnabled"

compile_time
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following attribute is new for the **chef_gem** resource:

``compile_time``
   Controls the phase during which a gem is installed on a node. Set to ``true`` to install a gem while the resource collection is being built (the "compile phase"). Set to ``false`` to install a gem while the chef-client is configuring the node (the "converge phase"). Possible values: ``nil`` (for verbose warnings), ``true`` (to warn once per chef-client run), or ``false`` (to remove all warnings). Recommended value: ``false``.

   .. tag resource_package_chef_gem_attribute_compile_time

   .. This topic is hooked into client.rb topics, starting with 12.1, in addition to the resource reference pages.

   To suppress warnings for cookbooks authored prior to chef-client 12.1, use a ``respond_to?`` check to ensure backward compatibility. For example:

   .. code-block:: ruby

      chef_gem 'aws-sdk' do
        compile_time false if respond_to?(:compile_time)
      end

   .. end_tag

run_as_
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The following attributes are new for the **windows_service** resource:

``run_as_password``
   The password for the user specified by ``run_as_user``.

``run_as_user``
   The user under which a Microsoft Windows service runs.

paludis_package
-----------------------------------------------------
.. tag resource_package_paludis

Use the **paludis_package** resource to manage packages for the Paludis platform.

.. end_tag

.. note:: In many cases, it is better to use the package resource instead of this one. This is because when the package resource is used in a recipe, the chef-client will use details that are collected by Ohai at the start of the chef-client run to determine the correct package application. Using the package resource allows a recipe to be authored in a way that allows it to be used across many platforms.

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_paludis_syntax

A **paludis_package** resource block manages a package on a node, typically by installing it. The simplest use of the **paludis_package** resource is:

.. code-block:: ruby

   paludis_package 'package_name'

which will install the named package using all of the default options and the default action (``:install``).

The full syntax for all of the properties that are available to the **paludis_package** resource is:

.. code-block:: ruby

   paludis_package 'name' do
     notifies                   # see description
     options                    String
     package_name               String, Array # defaults to 'name' if not specified
     provider                   Chef::Provider::Package::Paludis
     source                     String
     subscribes                 # see description
     timeout                    String, Integer
     version                    String, Array
     action                     Symbol # defaults to :install if not specified
   end

where

* ``paludis_package`` tells the chef-client to manage a package
* ``'name'`` is the name of the package
* ``action`` identifies which steps the chef-client will take to bring the node into the desired state
* ``options``, ``package_name``, ``provider``, ``source``, ``recursive``, ``timeout``, and ``version`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_paludis_actions

This resource has the following actions:

``:install``
   Default. Install a package. If a version is specified, install the specified version of the package.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:remove``
   Remove a package.

``:upgrade``
   Install a package and/or ensure that a package is the latest version.

.. end_tag

Attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This resource has the following properties:

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag 5

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

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

``options``
   **Ruby Type:** String

   One (or more) additional options that are passed to the command.

``package_name``
   **Ruby Types:** String, Array

   The name of the package. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider. See "Providers" section below for more information.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``source``
   **Ruby Type:** String

   Optional. The path to a package in the local file system.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag 5

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

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

``timeout``
   **Ruby Types:** String, Integer

   The amount of time (in seconds) to wait before timing out.

``version``
   **Ruby Types:** String, Array

   The version of a package to be installed or upgraded.

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**Install a package**

.. tag resource_paludis_package_install

.. To install a package:

.. code-block:: ruby

   paludis_package 'name of package' do
     action :install
   end

.. end_tag

openbsd_package
-----------------------------------------------------
.. tag resource_package_openbsd

Use the **openbsd_package** resource to manage packages for the OpenBSD platform.

.. end_tag

.. note:: In many cases, it is better to use the package resource instead of this one. This is because when the package resource is used in a recipe, the chef-client will use details that are collected by Ohai at the start of the chef-client run to determine the correct package application. Using the package resource allows a recipe to be authored in a way that allows it to be used across many platforms.

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_openbsd_syntax

A **openbsd_package** resource block manages a package on a node, typically by installing it. The simplest use of the **openbsd_package** resource is:

.. code-block:: ruby

   openbsd_package 'package_name'

which will install the named package using all of the default options and the default action (``:install``).

The full syntax for all of the properties that are available to the **openbsd_package** resource is:

.. code-block:: ruby

   openbsd_package 'name' do
     notifies                   # see description
     options                    String
     package_name               String, Array # defaults to 'name' if not specified
     provider                   Chef::Provider::Package::Openbsd
     source                     String
     subscribes                 # see description
     timeout                    String, Integer
     version                    String, Array
     action                     Symbol # defaults to :install if not specified
   end

where

* ``openbsd_package`` tells the chef-client to manage a package
* ``'name'`` is the name of the package
* ``action`` identifies which steps the chef-client will take to bring the node into the desired state
* ``options``, ``package_name``, ``provider``, ``source``, ``timeout``, and ``version`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_openbsd_actions

This resource has the following actions:

``:install``
   Default. Install a package. If a version is specified, install the specified version of the package.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:remove``
   Remove a package.

.. end_tag

Attributes
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This resource has the following properties:

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag 5

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

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

``options``
   **Ruby Type:** String

   One (or more) additional options that are passed to the command.

``package_name``
   **Ruby Types:** String, Array

   The name of the package. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider. See "Providers" section below for more information.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``source``
   **Ruby Type:** String

   Optional. The path to a package in the local file system.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag 5

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

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

``timeout``
   **Ruby Types:** String, Integer

   The amount of time (in seconds) to wait before timing out.

``version``
   **Ruby Types:** String, Array

   The version of a package to be installed or upgraded.

Examples
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**Install a package**

.. tag resource_openbsd_package_install

.. To install a package:

.. code-block:: ruby

   openbsd_package 'name of package' do
     action :install
   end

.. end_tag

New client.rb Settings
-----------------------------------------------------
The following client.rb settings are new:

``chef_gem_compile_time``
   Controls the phase during which a gem is installed on a node. Set to ``true`` to install a gem while the resource collection is being built (the "compile phase"). Set to ``false`` to install a gem while the chef-client is configuring the node (the "converge phase"). Recommended value: ``false``.

   .. note:: .. tag resource_package_chef_gem_attribute_compile_time

             .. This topic is hooked into client.rb topics, starting with 12.1, in addition to the resource reference pages.

             To suppress warnings for cookbooks authored prior to chef-client 12.1, use a ``respond_to?`` check to ensure backward compatibility. For example:

             .. code-block:: ruby

                chef_gem 'aws-sdk' do
                  compile_time false if respond_to?(:compile_time)
                end

             .. end_tag

``windows_service.watchdog_timeout``
   The maximum amount of time (in seconds) available to the chef-client run when the chef-client is run as a service on the Microsoft Windows platform. If the chef-client run does not complete within the specified timeframe, the chef-client run is terminated. Default value: ``2 * (60 * 60)``.

Multiple Packages and Versions
-----------------------------------------------------
.. tag resources_common_multiple_packages

A resource may specify multiple packages and/or versions for platforms that use Yum, Apt, Zypper, or Chocolatey package managers. Specifing multiple packages and/or versions allows a single transaction to:

* Download the specified packages and versions via a single HTTP transaction
* Update or install multiple packages with a single resource during the chef-client run

For example, installing multiple packages:

.. code-block:: ruby

   package ['package1', 'package2']

Installing multiple packages with versions:

.. code-block:: ruby

   package ['package1', 'package2'] do
     version [ '1.3.4-2', '4.3.6-1']
   end

Upgrading multiple packages:

.. code-block:: ruby

   package ['package1', 'package2']  do
     action :upgrade
   end

Removing multiple packages:

.. code-block:: ruby

   package ['package1', 'package2']  do
     action :remove
   end

Purging multiple packages:

.. code-block:: ruby

   package ['package1', 'package2']  do
     action :purge
   end

Notifications, via an implicit name:

.. code-block:: ruby

   package ['package1', 'package2']  do
     action :nothing
   end

   log 'call a notification' do
     notifies :install, 'package[package1, package2]', :immediately
   end

.. note:: Notifications and subscriptions do not need to be updated when packages and versions are added or removed from the ``package_name`` or ``version`` properties.

.. end_tag

What's New in 12.0
=====================================================
The following items are new for chef-client 12.0 and/or are changes from previous versions. The short version:

* **Changing attributes** Attributes may be modified for named precedence levels, all precedence levels, and be fully assigned. These changes were `based on RFC-23 <https://github.com/chef/chef-rfc/blob/master/rfc023-chef-12-attributes-changes.md>`_.
* **Ruby 2.0 (or higher) for Windows; and Ruby 2.1 (or higher) for Unix/Linux** Ruby versions 1.8.7, 1.9.1, 1.9.2, and 1.9.3 are no longer supported. See `this blog post <https://www.chef.io/blog/2014/11/25/ruby-1-9-3-eol-and-chef-12/>`_ for more info.
* **The number of changes between Ruby 1.9 and 2.0 is small** Please review the `Ruby 2.0 release notes <https://github.com/ruby/ruby/blob/v2_0_0_0/NEWS>`_ or `Ruby 2.1 release notes <https://github.com/ruby/ruby/blob/v2_1_0/NEWS>`_ for the full list of changes.
* **provides method for building custom resources** Use the ``provides`` method to associate a custom resource with a built-in chef-client resource and to specify platforms on which the custom resource may be used.
* **The chef-client supports the AIX platform** The chef-client may now be used to configure nodes that are running on the AIX platform, versions 6.1 (TL6 or higher, recommended) and 7.1 (TL0 SP3 or higher, recommended). The **service** resource supports starting, stopping, and restarting services that are managed by System Resource Controller (SRC), as well as managing all service states with BSD-based init systems.
* **New bff_package resource** Use the **bff_package** resource to install packages on the AIX platform.
* **New homebrew_package resource** Use the **homebrew_package** resource to install packages on the macOS platform. The **homebrew_package** resource also replaces the **macports_package** resource as the default package installer on the macOS platform.
* **New reboot resource** Use the **reboot** resource to reboot a node during or at the end of a chef-client run.
* **New windows_service resource** Use the **windows_service** resource to manage services on the Microsoft Windows platform.
* **New --bootstrap-template option** Use the ``--bootstrap-template`` option to install the chef-client with a bootstrap template. Specify the name of a template, such as ``chef-full``, or specify the path to a custom bootstrap template. This option deprecates the ``--distro`` and ``--template-file`` options.
* **New SSL options for bootstrap operations** The ``knife bootstrap`` subcommand has new options that support SSL with bootstrap operations. Use the ``--[no-]node-verify-api-cert`` option to to perform SSL validation of the connection to the Chef server. Use the ``--node-ssl-verify-mode`` option to validate SSL certificates.
* **New format options for knife status** Use the ``--medium`` and ``--long`` options to include attributes in the output and to format that output as JSON.
* **New fsck_device property for mount resource** The **mount** resource supports fsck devices for the Solaris platform with the ``fsck_device`` property.
* **New settings for metadata.rb** The metadata.rb file has two new settings: ``issues_url`` and ``source_url``. These settings are used to capture the source location and issues tracking location for a cookbook. These settings are also used with Chef Supermarket. In addition, the ``name`` setting is now **required**.
* **The http_request GET and HEAD requests drop the hard-coded query string** The ``:get`` and ``:head`` actions appended a hard-coded query string---``?message=resource_name``---that cannot be overridden. This hard-coded string is deprecated in the chef-client 12.0 release. Cookbooks that rely on this string need to be updated to manually add it to the URL as it is passed to the resource.
* **New Recipe DSL methods** The Recipe DSL has three new methods: ``shell_out``, ``shell_out!``, and ``shell_out_with_systems_locale``.
* **File specificity updates** File specificity for the **template** and **cookbook_file** resources now supports using the ``source`` attribute to define an explicit lookup path as an array.
* **Improved user password security for the user resource, macOS platform** The **user** resource now supports salted password hashes for macOS 10.7 (and higher). Use the ``iterations`` and ``salt`` attributes to calculate SALTED-SHA512 password shadow hashes for macOS version 10.7 and SALTED-SHA512-PBKDF2 password shadow hashes for version 10.8 (and higher).
* **data_bag_item method in the Recipe DSL supports encrypted data bag items** Use ``data_bag_item(bag_name, item, secret)`` to specify the secret to use for an encrypted data bag item. If ``secret`` is not specified, the chef-client looks for a secret at the path specified by the ``encrypted_data_bag_secret`` setting in the client.rb file.
* **value_for_platform method in the Recipe DSL supports version constraints** Version constraints---``>``, ``<``, ``>=``, ``<=``, ``~>``---may be used when specifying a version. An exception is raised if two version constraints match. An exact match will always take precedence over a match made from a version constraint.
* **knife cookbook site share supports --dry-run** Use the ``--dry-run`` option with the ``knife cookbook site`` to take no action and only print out results.
* **chef-client configuration setting updates** The chef-client now supports running an override run-list (via the ``--override-runlist`` option) without clearing the cookbook cache on the node. In addition, the ``--chef-zero-port`` option allows specifying a range of ports.
* **Unforked interval runs are no longer allowed** The ``--[no-]fork`` option may no longer be used in the same command with the ``--daemonize`` and ``--interval`` options.
* **Splay and interval values are applied before the chef-client run** The ``--interval`` and ``--splay`` values are applied before the chef-client run when using the chef-client and chef-solo executables.
* **All files and templates in a cookbook are synchronized at the start of the chef-client run** The ``no_lazy_load`` configuration setting in the client.rb file now defaults to ``true``. This avoids issues where time-sensitive URLs in a cookbook manifest timeout before the **cookbook_file** or **template** resources converged.
* **File staging now defaults to the destination directory by default** Staging into a system's temporary directory---typically ``/tmp`` or ``/var/tmp``---as opposed to the destination directory may cause issues with permissions, available space, or cross-device renames. Files are now staged to the destination directory by default.
* **Partial search updates** Use ``:filter_result`` to build search results into a Hash. This replaces the previous functionality that was provided by the ``partial_search`` cookbook, albeit with a different API. Use the ``--filter-result`` option to return only attributes that match the specified filter. For example: ``\"ServerName=name, Kernel=kernel.version\"``.
* **Client-side key generation is enabled by default** When a new chef-client is created using the validation client account, the Chef server allows the chef-client to generate a key-pair locally, and then send the public key to the Chef server. This behavior is controlled by the ``local_key_generation`` attribute in the client.rb file and now defaults to ``true``.
* **New guard_interpreter property defaults** The ``guard_interpreter`` property now defaults to ``:batch`` for the **batch** resource and ``:powershell_script`` for the **powershell_script** resource.
* **Events are sent to the Application event log on the Windows platform by default** Events are sent to the Microsoft Windows "Application" event log at the start and end of a chef-client run, and also if a chef-client run fails. Set the ``disable_event_logger`` configuration setting in the client.rb file to ``true`` to disable event logging.
* **The installer_type property for the windows_package resource uses a symbol instead of a string** Previous versions of the chef-client (starting with version 11.8) used a string.
* **The path property is deprecated for the execute resource** Use the ``environment`` property instead.
* **SSL certificate validation improvements** The default settings for SSL certificate validation now default in favor of validation. In addition, using the ``knife ssl fetch`` subcommand is now an important part of setting up your workstation.
* **New property for git resource** The **git** resource has a new property: ``environment``, which takes a Hash of environment variables in the form of ``{"ENV_VARIABLE" => "VALUE"}``.

Please :doc:`view the notes </upgrade_client_notes>` for more background on the upgrade process from chef-client 11 to chef-client 12.

Change Attributes
-----------------------------------------------------
.. tag node_attribute_change

Starting with chef-client 12.0, attribute precedence levels may be

* Removed for a specific, named attribute precedence level
* Removed for all attribute precedence levels
* Fully assigned attributes

.. end_tag

Remove Precedence Level
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag node_attribute_change_remove_level

A specific attribute precedence level for default, normal, and override attributes may be removed by using one of the following syntax patterns.

For default attributes:

* ``node.rm_default('foo', 'bar')``

For normal attributes:

* ``node.rm_normal('foo', 'bar')``

For override attributes:

* ``node.rm_override('foo', 'bar')``

These patterns return the computed value of the key being deleted for the specified precedence level.

.. end_tag

Examples
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag node_attribute_change_remove_level_examples

The following examples show how to remove a specific, named attribute precedence level.

**Delete a default value when only default values exist**

Given the following code structure under ``'foo'``:

.. code-block:: ruby

   node.default['foo'] = {
     'bar' => {
       'baz' => 52,
       'thing' => 'stuff',
     },
     'bat' => {
       'things' => [5, 6],
     },
   }

And some role attributes:

.. code-block:: ruby

   # Please don't ever do this in real code :)
   node.role_default['foo']['bar']['thing'] = 'otherstuff'

And a force attribute:

.. code-block:: ruby

   node.force_default['foo']['bar']['thing'] = 'allthestuff'

When the default attribute precedence ``node['foo']['bar']`` is removed:

.. code-block:: ruby

   node.rm_default('foo', 'bar') #=> {'baz' => 52, 'thing' => 'allthestuff'}

What is left under ``'foo'`` is only ``'bat'``:

.. code-block:: ruby

   node.attributes.combined_default['foo'] #=> {'bat' => { 'things' => [5,6] } }

**Delete default without touching higher precedence attributes**

Given the following code structure:

.. code-block:: ruby

   node.default['foo'] = {
     'bar' => {
       'baz' => 52,
       'thing' => 'stuff',
     },
     'bat' => {
       'things' => [5, 6],
     },
   }

And some role attributes:

.. code-block:: ruby

   # Please don't ever do this in real code :)
   node.role_default['foo']['bar']['thing'] = 'otherstuff'

And a force attribute:

.. code-block:: ruby

   node.force_default['foo']['bar']['thing'] = 'allthestuff'

And also some override attributes:

.. code-block:: ruby

   node.override['foo']['bar']['baz'] = 99

Same delete as before:

.. code-block:: ruby

   node.rm_default('foo', 'bar') #=> { 'baz' => 52, 'thing' => 'allthestuff' }

The other attribute precedence levels are unaffected:

.. code-block:: ruby

   node.attributes.combined_override['foo'] #=> { 'bar' => {'baz' => 99} }
   node['foo'] #=> { 'bar' => {'baz' => 99}, 'bat' => { 'things' => [5,6] }

**Delete override without touching lower precedence attributes**

Given the following code structure, which has an override attribute:

.. code-block:: ruby

   node.override['foo'] = {
     'bar' => {
       'baz' => 52,
       'thing' => 'stuff',
     },
     'bat' => {
       'things' => [5, 6],
     },
   }

with a single default value:

.. code-block:: ruby

   node.default['foo']['bar']['baz'] = 11

and a force at each attribute precedence:

.. code-block:: ruby

   node.force_default['foo']['bar']['baz'] = 55
   node.force_override['foo']['bar']['baz'] = 99

Delete the override:

.. code-block:: ruby

   node.rm_override('foo', 'bar') #=> { 'baz' => 99, 'thing' => 'stuff' }

The other attribute precedence levels are unaffected:

.. code-block:: ruby

   node.attributes.combined_default['foo'] #=> { 'bar' => {'baz' => 55} }

**Non-existent key deletes return nil**

.. code-block:: ruby

   node.rm_default("no", "such", "thing") #=> nil

.. end_tag

Remove All Levels
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag node_attribute_change_remove_all

All attribute precedence levels may be removed by using the following syntax pattern:

* ``node.rm('foo', 'bar')``

.. note:: Using ``node['foo'].delete('bar')`` will throw an exception that points to the new API.

.. end_tag

Examples
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag node_attribute_change_remove_all_examples

The following examples show how to remove all attribute precedence levels.

**Delete all attribute precedence levels**

Given the following code structure:

.. code-block:: ruby

   node.default['foo'] = {
     'bar' => {
       'baz' => 52,
       'thing' => 'stuff',
     },
     'bat' => {
       'things' => [5, 6],
     },
   }

With override attributes:

.. code-block:: ruby

   node.override['foo']['bar']['baz'] = 999

Removing the ``'bar'`` key returns the computed value:

.. code-block:: ruby

   node.rm('foo', 'bar') #=> {'baz' => 999, 'thing' => 'stuff'}

Looking at ``'foo'``, all that's left is the ``'bat'`` entry:

.. code-block:: ruby

   node['foo'] #=> {'bat' => { 'things' => [5,6] } }

**Non-existent key deletes return nil**

.. code-block:: ruby

   node.rm_default("no", "such", "thing") #=> nil

.. end_tag

Full Assignment
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag node_attribute_change_full_assignment

Use ``!`` to clear out the key for the named attribute precedence level, and then complete the write by using one of the following syntax patterns:

* ``node.default!['foo']['bar'] = {...}``
* ``node.force_default!['foo']['bar'] = {...}``
* ``node.normal!['foo']['bar'] = {...}``
* ``node.override!['foo']['bar'] = {...}``
* ``node.force_override!['foo']['bar'] = {...}``

.. end_tag

Examples
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. tag node_attribute_change_full_assignment_examples

The following examples show how to remove all attribute precedence levels.

**Just one component**

Given the following code structure:

.. code-block:: ruby

   node.default['foo']['bar'] = {'a' => 'b'}
   node.default!['foo']['bar'] = {'c' => 'd'}

The ``'!'`` caused the entire 'bar' key to be overwritten:
.. code-block:: ruby

   node['foo'] #=> {'bar' => {'c' => 'd'}

**Multiple components; one "after"**

Given the following code structure:

.. code-block:: ruby

   node.default['foo']['bar'] = {'a' => 'b'}
   # Please don't ever do this in real code :)
   node.role_default['foo']['bar'] = {'c' => 'd'}
   node.default!['foo']['bar'] = {'d' => 'e'}

The ``'!'`` write overwrote the "cookbook-default" value of ``'bar'``, but since role data is later in the resolution list, it was unaffected:

.. code-block:: ruby

   node['foo'] #=> {'bar' => {'c' => 'd', 'd' => 'e'}

**Multiple components; all "before"**

Given the following code structure:

.. code-block:: ruby

   node.default['foo']['bar'] = {'a' => 'b'}
   # Please don't ever do this in real code :)
   node.role_default['foo']['bar'] = {'c' => 'd'}
   node.force_default!['foo']['bar'] = {'d' => 'e'}

With ``force_default!`` there is no other data under ``'bar'``:

.. code-block:: ruby

   node['foo'] #=> {'bar' => {'d' => 'e'}

**Multiple precedence levels**

Given the following code structure:

.. code-block:: ruby

   node.default['foo'] = {
     'bar' => {
       'baz' => 52,
       'thing' => 'stuff',
     },
     'bat' => {
      'things' => [5, 6],
     },
   }

And some attributes:

.. code-block:: ruby

   # Please don't ever do this in real code :)
   node.role_default['foo']['bar']['baz'] = 55
   node.force_default['foo']['bar']['baz'] = 66

And other precedence levels:

.. code-block:: ruby

   node.normal['foo']['bar']['baz'] = 88
   node.override['foo']['bar']['baz'] = 99

With a full assignment:

.. code-block:: ruby

   node.default!['foo']['bar'] = {}

Role default and force default are left in default, plus other precedence levels:

.. code-block:: ruby

   node.attributes.combined_default['foo'] #=> {'bar' => {'baz' => 66}, 'bat'=>{'things'=>[5, 6]}}
   node.attributes.normal['foo'] #=> {'bar' => {'baz' => 88}}
   node.attributes.combined_override['foo'] #=> {'bar' => {'baz' => 99}}
   node['foo']['bar'] #=> {'baz' => 99}

If ``force_default!`` is written:

.. code-block:: ruby

   node.force_default!['foo']['bar'] = {}

the difference is:

.. code-block:: ruby

   node.attributes.combined_default['foo'] #=> {'bat'=>{'things'=>[5, 6]}, 'bar' => {}}
   node.attributes.normal['foo'] #=> {'bar' => {'baz' => 88}}
   node.attributes.combined_override['foo'] #=> {'bar' => {'baz' => 99}}
   node['foo']['bar'] #=> {'baz' => 99}

.. end_tag

provides Method
-----------------------------------------------------
Use the ``provides`` method to map a custom resource/provider to an existing resource/provider, and then to also specify the platform(s) on which the behavior of the custom resource/provider will be applied. This method enables scenarios like:

* Building a custom resource that is based on an existing resource
* Defining platform mapping specific to a custom resource
* Handling situations where a resource on a particular platform may have more than one provider, such as the behavior on the Ubuntu platform where both SysVInit and systemd are present
* Allowing the custom resource to declare what platforms are supported, enabling the creator of the custom resource to use arbitrary criteria if desired
* Not using the previous naming convention---``#{cookbook_name}_#{provider_filename}``

.. warning:: The ``provides`` method must be defined in both the custom resource and custom provider files and both files must have identical ``provides`` statement(s).

The syntax for the ``provides`` method is as follows:

.. code-block:: ruby

   provides :resource_name, os: [ 'platform', 'platform', ...], platform_family: 'family'

where:

* ``:resource_name`` is a chef-client resource: ``:cookbook_file``, ``:package``, ``:rpm_package``, and so on
* ``'platform'`` is a comma-separated list of platforms: ``'windows'``, ``'solaris2'``, ``'linux'``, and so on
* ``platform_family`` is optional and may specify the same parameters as the ``platform_family?`` method in the Recipe DSL; ``platform`` is optional and also supported (and is the same as the ``platform?`` method in the Recipe DSL)

A custom resource/provider may be mapped to more than one existing resource/provider. Multiple platform associations may be made. For example, to completely map a custom resource/provider to an existing custom resource/provider, only specificy the resource name:

.. code-block:: ruby

   provides :cookbook_file

The same mapping, but only for the Linux platform:

.. code-block:: ruby

   provides :cookbook_file, os: 'linux'

A similar mapping, but also for packages on the Microsoft Windows platform:

.. code-block:: ruby

   provides :cookbook_file
   provides :package, os: 'windows'

Use multiple ``provides`` statements to define multiple conditions: Use an array to match any of the platforms within the array:

.. code-block:: ruby

   provides :cookbook_file
   provides :package, os: 'windows'
   provides :rpm_package, os: [ 'linux', 'aix' ]

Use an array to match any of the platforms within the array:

.. code-block:: ruby

   provides :package, os: 'solaris2', platform_family: 'solaris2' do |node|
     node[:platform_version].to_f <= 5.10
   end

AIX Platform Support
-----------------------------------------------------
.. tag ctl_chef_client_aix

The chef-client may now be used to configure nodes that are running on the AIX platform, versions 6.1 (TL6 or higher, recommended) and 7.1 (TL0 SP3 or higher, recommended). The **service** resource supports starting, stopping, and restarting services that are managed by System Resource Controller (SRC), as well as managing all service states with BSD-based init systems.

.. end_tag

**System Requirements**

.. tag ctl_chef_client_aix_requirements

The chef-client has the `same system requirements </chef_system_requirements.html#chef-client>`_ on the AIX platform as any other platform, with the following notes:

* Expand the file system on the AIX platform using ``chfs`` or by passing the ``-X`` flag to ``installp`` to automatically expand the logical partition (LPAR)
* The EN_US (UTF-8) character set should be installed on the logical partition prior to installing the chef-client

.. end_tag

**Install the chef-client on the AIX platform**

.. tag ctl_chef_client_aix_setup

The chef-client is distributed as a Backup File Format (BFF) binary and is installed on the AIX platform using the following command run as a root user:

.. code-block:: text

   # installp -aYgd chef-12.0.0-1.powerpc.bff all

.. end_tag

**Increase system process limits**

.. tag ctl_chef_client_aix_system_process_limits

The out-of-the-box system process limits for maximum process memory size (RSS) and number of open files are typically too low to run the chef-client on a logical partition (LPAR). When the system process limits are too low, the chef-client will not be able to create threads. To increase the system process limits:

#. Validate that the system process limits have not already been increased.
#. If they have not been increased, run the following commands as a root user:

   .. code-block:: bash

      $ chsec -f /etc/security/limits -s default -a "rss=-1"

   and then:

   .. code-block:: bash

      $ chsec -f /etc/security/limits -s default -a "data=-1"

   and then:

   .. code-block:: bash

      $ chsec -f /etc/security/limits -s default -a "nofiles=50000"

   .. note:: The previous commands may be run against the root user, instead of default. For example:

      .. code-block:: bash

         $ chsec -f /etc/security/limits -s root_user -a "rss=-1"

#. Reboot the logical partition (LPAR) to apply the updated system process limits.

When the system process limits are too low, an error is returned similar to:

.. code-block:: none

   Error Syncing Cookbooks:
   ==================================================================

   Unexpected Error:
   -----------------
   ThreadError: can't create Thread: Resource temporarily unavailable

.. end_tag

**Install the UTF-8 character set**

.. tag install_chef_client_aix_en_us

The chef-client uses the EN_US (UTF-8) character set. By default, the AIX base operating system does not include the EN_US (UTF-8) character set and it must be installed prior to installing the chef-client. The EN_US (UTF-8) character set may be installed from the first disc in the AIX media or may be copied from ``/installp/ppc/*EN_US*`` to a location on the logical partition (LPAR). This topic assumes this location to be ``/tmp/rte``.

Use ``smit`` to install the EN_US (UTF-8) character set. This ensures that any workload partitions (WPARs) also have UTF-8 applied.

Remember to point ``INPUT device/directory`` to ``/tmp/rte`` when not installing from CD.

#. From a root shell type:

   .. code-block:: text

      # smit lang

   A screen similar to the following is returned:

   .. code-block:: bash

                             Manage Language Environment

      Move cursor to desired item and press Enter.

        Change/Show Primary Language Environment
        Add Additional Language Environments
        Remove Language Environments
        Change/Show Language Hierarchy
        Set User Languages
        Change/Show Applications for a Language
        Convert System Messages and Flat Files

      F1=Help             F2=Refresh          F3=Cancel           F8=Image
      F9=Shell            F10=Exit            Enter=Do

#. Select ``Add Additional Language Environments`` and press ``Enter``. A screen similar to the following is returned:

   .. code-block:: bash

                         Add Additional Language Environments

      Type or select values in entry fields.
      Press Enter AFTER making all desired changes.

                                                              [Entry Fields]
        CULTURAL convention to install                                             +
        LANGUAGE translation to install                                            +
      * INPUT device/directory for software                [/dev/cd0]              +
        EXTEND file systems if space needed?                yes                    +

        WPAR Management
            Perform Operation in Global Environment         yes                    +
            Perform Operation on Detached WPARs             no                     +
                Detached WPAR Names                        [_all_wpars]            +
            Remount Installation Device in WPARs            yes                    +
            Alternate WPAR Installation Device             []

      F1=Help             F2=Refresh          F3=Cancel           F4=List
      F5=Reset            F6=Command          F7=Edit             F8=Image
      F9=Shell            F10=Exit            Enter=Do

#. Cursor over the first two entries---``CULTURAL convention to install`` and ``LANGUAGE translation to install``---and use ``F4`` to navigate through the list until ``UTF-8 English (United States) [EN_US]`` is selected. (EN_US is in capital letters!)

#. Press ``Enter`` to apply and install the language set.

.. end_tag

**New providers**

.. tag ctl_chef_client_aix_providers

The **service** resource has the following providers to support the AIX platform:

.. list-table::
   :widths: 150 80 320
   :header-rows: 1

   * - Long name
     - Short name
     - Notes
   * - ``Chef::Provider::Service::Aix``
     - ``service``
     - The provider that is used with the AIX platforms. Use the ``service`` short name to start, stop, and restart services with System Resource Controller (SRC).
   * - ``Chef::Provider::Service::AixInit``
     - ``service``
     -  The provider that is used to manage BSD-based init services on AIX.

.. end_tag

**Enable a service on AIX using the mkitab command**

.. tag resource_service_aix_mkitab

The **service** resource does not support using the ``:enable`` and ``:disable`` actions with resources that are managed using System Resource Controller (SRC). This is because System Resource Controller (SRC) does not have a standard mechanism for enabling and disabling services on system boot.

One approach for enabling or disabling services that are managed by System Resource Controller (SRC) is to use the **execute** resource to invoke ``mkitab``, and then use that command to enable or disable the service.

The following example shows how to install a service:

.. code-block:: ruby

   execute "install #{node['chef_client']['svc_name']} in SRC" do
     command "mkssys -s #{node['chef_client']['svc_name']}
                     -p #{node['chef_client']['bin']}
                     -u root
                     -S
                     -n 15
                     -f 9
                     -o #{node['chef_client']['log_dir']}/client.log
                     -e #{node['chef_client']['log_dir']}/client.log -a '
                     -i #{node['chef_client']['interval']}
                     -s #{node['chef_client']['splay']}'"
     not_if "lssrc -s #{node['chef_client']['svc_name']}"
     action :run
   end

and then enable it using the ``mkitab`` command:

.. code-block:: ruby

   execute "enable #{node['chef_client']['svc_name']}" do
     command "mkitab '#{node['chef_client']['svc_name']}:2:once:/usr/bin/startsrc
                     -s #{node['chef_client']['svc_name']} > /dev/console 2>&1'"
     not_if "lsitab #{node['chef_client']['svc_name']}"
   end

.. end_tag

Recipe DSL, Encrypted Data Bags
-----------------------------------------------------
.. tag data_bag_recipes_load_using_recipe_dsl

The Recipe DSL provides access to data bags and data bag items (including encrypted data bag items) with the following methods:

* ``data_bag(bag)``, where ``bag`` is the name of the data bag.
* ``data_bag_item('bag_name', 'item', 'secret')``, where ``bag`` is the name of the data bag and ``item`` is the name of the data bag item. If ``'secret'`` is not specified, the chef-client will look for a secret at the path specified by the ``encrypted_data_bag_secret`` setting in the client.rb file.

The ``data_bag`` method returns an array with a key for each of the data bag items that are found in the data bag.

Some examples:

To load the secret from a file:

.. code-block:: ruby

   data_bag_item('bag', 'item', IO.read('secret_file'))

To load a single data bag item named ``admins``:

.. code-block:: ruby

   data_bag('admins')

The contents of a data bag item named ``justin``:

.. code-block:: ruby

   data_bag_item('admins', 'justin')

will return something similar to:

.. code-block:: ruby

   # => {'comment'=>'Justin Currie', 'gid'=>1005, 'id'=>'justin', 'uid'=>1005, 'shell'=>'/bin/zsh'}

If ``item`` is encrypted, ``data_bag_item`` will automatically decrypt it using the key specified above, or (if none is specified) by the ``Chef::Config[:encrypted_data_bag_secret]`` method, which defaults to ``/etc/chef/encrypted_data_bag_secret``.

.. end_tag

bff_package
-----------------------------------------------------
.. tag resource_package_bff

Use the **bff_package** resource to manage packages for the AIX platform using the installp utility. When a package is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources. New in Chef Client 12.0.

.. note:: A Backup File Format (BFF) package may not have a ``.bff`` file extension. The chef-client will still identify the correct provider to use based on the platform, regardless of the file extension.

.. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_bff_syntax

A **bff_package** resource block manages a package on a node, typically by installing it. The simplest use of the **bff_package** resource is:

.. code-block:: ruby

   bff_package 'package_name'

which will install the named package using all of the default options and the default action (``:install``).

The full syntax for all of the properties that are available to the **bff_package** resource is:

.. code-block:: ruby

   bff_package 'name' do
     notifies                   # see description
     options                    String
     package_name               String, Array # defaults to 'name' if not specified
     provider                   Chef::Provider::Package::Aix
     source                     String
     subscribes                 # see description
     timeout                    String, Integer
     version                    String, Array
     action                     Symbol # defaults to :install if not specified
   end

where

* ``bff_package`` tells the chef-client to manage a package
* ``'name'`` is the name of the package
* ``action`` identifies which steps the chef-client will take to bring the node into the desired state
* ``options``, ``package_name``, ``provider``, ``source``, ``timeout``, and ``version`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_bff_actions

This resource has the following actions:

``:install``
   Default. Install a package. If a version is specified, install the specified version of the package.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:purge``
   Purge a package. This action typically removes the configuration files as well as the package.

``:remove``
   Remove a package.

.. end_tag

Properties
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This resource has the following properties:

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag 5

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

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

``options``
   **Ruby Type:** String

   One (or more) additional options that are passed to the command.

``package_name``
   **Ruby Types:** String, Array

   The name of the package. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider. See "Providers" section below for more information.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``source``
   **Ruby Type:** String

   Required. The path to a package in the local file system. The AIX platform requires ``source`` to be a local file system path because ``installp`` does not retrieve packages using HTTP or FTP.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag 5

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

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

``timeout``
   **Ruby Types:** String, Integer

   The amount of time (in seconds) to wait before timing out.

``version``
   **Ruby Types:** String, Array

   The version of a package to be installed or upgraded.

Providers
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_bff_providers

This resource has the following providers:

``Chef::Provider::Package``, ``package``
   When this short name is used, the chef-client will attempt to determine the correct provider during the chef-client run.

``Chef::Provider::Package::Aix``, ``bff_package``
   The provider for the AIX platform. Can be used with the ``options`` attribute.

.. end_tag

Example
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**Install a package**

.. tag resource_bff_package_install

.. To install a package:

The **bff_package** resource is the default package provider on the AIX platform. The base **package** resource may be used, and then when the platform is AIX, the chef-client will identify the correct package provider. The following examples show how to install part of the IBM XL C/C++ compiler.

Using the base **package** resource:

.. code-block:: ruby

   package 'xlccmp.13.1.0' do
     source '/var/tmp/IBM_XL_C_13.1.0/usr/sys/inst.images/xlccmp.13.1.0'
     action :install
   end

Using the **bff_package** resource:

.. code-block:: ruby

   bff_package 'xlccmp.13.1.0' do
     source '/var/tmp/IBM_XL_C_13.1.0/usr/sys/inst.images/xlccmp.13.1.0'
     action :install
   end

.. end_tag

homebrew_package
-----------------------------------------------------
.. tag resource_package_homebrew

Use the **homebrew_package** resource to manage packages for the macOS platform.

.. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_homebrew_syntax

A **homebrew_package** resource block manages a package on a node, typically by installing it. The simplest use of the **homebrew_package** resource is:

.. code-block:: ruby

   homebrew_package 'package_name'

which will install the named package using all of the default options and the default action (``:install``).

The full syntax for all of the properties that are available to the **homebrew_package** resource is:

.. code-block:: ruby

   homebrew_package 'name' do
     homebrew_user              String, Integer
     notifies                   # see description
     options                    String
     package_name               String, Array # defaults to 'name' if not specified
     provider                   Chef::Provider::Package::Homebrew
     source                     String
     subscribes                 # see description
     timeout                    String, Integer
     version                    String, Array
     action                     Symbol # defaults to :install if not specified
   end

where

* ``homebrew_package`` tells the chef-client to manage a package
* ``'name'`` is the name of the package
* ``action`` identifies which steps the chef-client will take to bring the node into the desired state
* ``homebrew_user``, ``options``, ``package_name``, ``provider``, ``source``, ``timeout``, and ``version`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_homebrew_actions

This resource has the following actions:

``:install``
   Default. Install a package. If a version is specified, install the specified version of the package.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:purge``
   Purge a package. This action typically removes the configuration files as well as the package.

``:remove``
   Remove a package.

``:upgrade``
   Install a package and/or ensure that a package is the latest version.

.. end_tag

Properties
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This resource has the following properties:

``homebrew_user``
   **Ruby Types:** String, Integer

   The name of the Homebrew owner to be used by the chef-client when executing a command.

   .. tag resource_package_homebrew_user

   The chef-client, by default, will attempt to execute a Homebrew command as the owner of ``/usr/local/bin/brew``. If that executable does not exist, the chef-client will attempt to find the user by executing ``which brew``. If that executable cannot be found, the chef-client will print an error message: ``Could not find the "brew" executable in /usr/local/bin or anywhere on the path.``. Use the ``homebrew_user`` attribute to specify the Homebrew owner for situations where the chef-client cannot automatically detect the correct owner.

   .. end_tag

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag 5

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

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

``options``
   **Ruby Type:** String

   One (or more) additional options that are passed to the command.

``package_name``
   **Ruby Types:** String, Array

   The name of the package. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider. See "Providers" section below for more information.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``source``
   **Ruby Type:** String

   Optional. The path to a package in the local file system.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag 5

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

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

``timeout``
   **Ruby Types:** String, Integer

   The amount of time (in seconds) to wait before timing out.

``version``
   **Ruby Types:** String, Array

   The version of a package to be installed or upgraded.

Providers
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_package_homebrew_providers

This resource has the following providers:

``Chef::Provider::Package``, ``package``
   When this short name is used, the chef-client will attempt to determine the correct provider during the chef-client run.

``Chef::Provider::Package::Homebrew``, ``homebrew_package``
   The provider for the macOS platform.

.. end_tag

Example
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**Install a package**

.. tag resource_homebrew_package_install

.. To install a package:

.. code-block:: ruby

   homebrew_package 'name of package' do
     action :install
   end

.. end_tag

**Specify the Homebrew user with a UUID**

.. tag resource_homebrew_package_homebrew_user_as_uuid

.. To specify the Homebrew user as a UUID:

.. code-block:: ruby

   homebrew_package 'emacs' do
     homebrew_user 1001
   end

.. end_tag

**Specify the Homebrew user with a string**

.. tag resource_homebrew_package_homebrew_user_as_string

.. To specify the Homebrew user as a string:

.. code-block:: ruby

   homebrew_package 'vim' do
     homebrew_user 'user1'
   end

.. end_tag

reboot
-----------------------------------------------------
.. tag resource_service_reboot

Use the **reboot** resource to reboot a node, a necessary step with some installations on certain platforms. This resource is supported for use on the Microsoft Windows, macOS, and Linux platforms.  New in Chef Client 12.0.

.. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_service_reboot_syntax

A **reboot** resource block reboots a node:

.. code-block:: ruby

   reboot 'app_requires_reboot' do
     action :request_reboot
     reason 'Need to reboot when the run completes successfully.'
     delay_mins 5
   end

The full syntax for all of the properties that are available to the **reboot** resource is:

.. code-block:: ruby

   reboot 'name' do
     delay_mins                 Fixnum
     notifies                   # see description
     reason                     String
     subscribes                 # see description
     action                     Symbol
   end

where

* ``reboot`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``delay_mins`` and ``reason`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_service_reboot_actions

This resource has the following actions:

``:cancel``
   Cancel a reboot request.

``:nothing``
   .. tag resources_common_actions_nothing

   Define this resource block to do nothing until notified by another resource to take action. When this resource is notified, this resource block is either run immediately or it is queued up to be run at the end of the chef-client run.

   .. end_tag

``:reboot_now``
   Reboot a node so that the chef-client may continue the installation process.

``:request_reboot``
   Reboot a node at the end of a chef-client run.

.. end_tag

Properties
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This resource has the following properties:

``delay_mins``
   **Ruby Type:** Fixnum

   The amount of time (in minutes) to delay a reboot request.

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag resources_common_notification_timers_reboot

   A timer specifies the point during the chef-client run at which a notification is run. The following timer is available:

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

``reason``
   **Ruby Type:** String

   A string that describes the reboot action.

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

   .. tag resources_common_notification_timers_reboot

   A timer specifies the point during the chef-client run at which a notification is run. The following timer is available:

   ``:immediate``, ``:immediately``
      Specifies that a notification should be run immediately, per resource notified.

   .. end_tag

Providers
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This resource has the following providers:

``Chef::Provider::Reboot``, ``reboot``
   The provider that is used to reboot a node.

Example
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**Reboot a node immediately**

.. tag resource_service_reboot_immediately

.. To reboot immediately:

.. code-block:: ruby

   reboot 'now' do
     action :nothing
     reason 'Cannot continue Chef run without a reboot.'
     delay_mins 2
   end

   execute 'foo' do
     command '...'
     notifies :reboot_now, 'reboot[now]', :immediately
   end

.. end_tag

**Reboot a node at the end of a chef-client run**

.. tag resource_service_reboot_request

.. To reboot a node at the end of the chef-client run:

.. code-block:: ruby

   reboot 'app_requires_reboot' do
     action :request_reboot
     reason 'Need to reboot when the run completes successfully.'
     delay_mins 5
   end

.. end_tag

**Cancel a reboot**

.. tag resource_service_reboot_cancel

.. To cancel a reboot request:

.. code-block:: ruby

   reboot 'cancel_reboot_request' do
     action :cancel
     reason 'Cancel a previous end-of-run reboot request.'
   end

.. end_tag

windows_service
-----------------------------------------------------
.. tag resource_service_windows

Use the **windows_service** resource to manage a service on the Microsoft Windows platform. New in Chef Client 12.0.

.. end_tag

Syntax
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_service_windows_syntax

A **windows_service** resource block manages the state of a service on a machine that is running Microsoft Windows. For example:

.. code-block:: ruby

   windows_service 'BITS' do
     action :configure_startup
     startup_type :manual
   end

The full syntax for all of the properties that are available to the **windows_service** resource is:

.. code-block:: ruby

   windows_service 'name' do
     init_command               String
     notifies                   # see description
     pattern                    String
     provider                   Chef::Provider::Service::Windows
     reload_command             String
     restart_command            String
     run_as_password            String
     run_as_user                String
     service_name               String # defaults to 'name' if not specified
     start_command              String
     startup_type               Symbol
     status_command             String
     stop_command               String
     subscribes                 # see description
     supports                   Hash
     timeout                    Integer
     action                     Symbol # defaults to :nothing if not specified
   end

where

* ``windows_service`` is the resource
* ``name`` is the name of the resource block
* ``action`` identifies the steps the chef-client will take to bring the node into the desired state
* ``init_command``, ``pattern``, ``provider``, ``reload_command``, ``restart_command``, ``run_as_password``, ``run_as_user``, ``service_name``, ``start_command``, ``startup_type``, ``status_command``, ``stop_command``, ``supports``, and ``timeout`` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all of the properties that may be used with this resource.

.. end_tag

Actions
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag resource_service_windows_actions

This resource has the following actions:

``:configure_startup``
   Configure a service based on the value of the ``startup_type`` property.

``:disable``
   Disable a service. This action is equivalent to a ``Disabled`` startup type on the Microsoft Windows platform.

``:enable``
   Enable a service at boot. This action is equivalent to an ``Automatic`` startup type on the Microsoft Windows platform.

``:nothing``
   Default. Do nothing with a service.

``:reload``
   Reload the configuration for this service.

``:restart``
   Restart a service.

``:start``
   Start a service, and keep it running until stopped or disabled.

``:stop``
   Stop a service.

.. end_tag

Properties
+++++++++++++++++++++++++++++++++++++++++++++++++++++
This resource has the following properties:

``ignore_failure``
   **Ruby Types:** TrueClass, FalseClass

   Continue running a recipe if a resource fails for any reason. Default value: ``false``.

``init_command``
   **Ruby Type:** String

   The path to the init script that is associated with the service. This is typically ``/etc/init.d/SERVICE_NAME``. The ``init_command`` property can be used to prevent the need to specify  overrides for the ``start_command``, ``stop_command``, and ``restart_command`` attributes. Default value: ``nil``.

``notifies``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_notifies

   A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notifiy more than one resource; use a ``notifies`` statement for each resource to be notified.

   .. end_tag

   .. tag 5

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

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

``pattern``
   **Ruby Type:** String

   The pattern to look for in the process table. Default value: ``service_name``.

``provider``
   **Ruby Type:** Chef Class

   Optional. Explicitly specifies a provider.

``reload_command``
   **Ruby Type:** String

   The command used to tell a service to reload its configuration.

``restart_command``
   **Ruby Type:** String

   The command used to restart a service.

``retries``
   **Ruby Type:** Integer

   The number of times to catch exceptions and retry the resource. Default value: ``0``.

``retry_delay``
   **Ruby Type:** Integer

   The retry delay (in seconds). Default value: ``2``.

``run_as_password``
   **Ruby Type:** String

   The password for the user specified by ``run_as_user``.

``run_as_user``
   **Ruby Type:** String

   The user under which a Microsoft Windows service runs.

``service_name``
   **Ruby Type:** String

   The name of the service. Default value: the ``name`` of the resource block See "Syntax" section above for more information.

``start_command``
   **Ruby Type:** String

   The command used to start a service.

``startup_type``
   **Ruby Type:** Symbol

   Use to specify the startup type for a Microsoft Windows service. Possible values: ``:automatic``, ``:disabled``, or ``:manual``. Default value: ``:automatic``.

``status_command``
   **Ruby Type:** String

   The command used to check the run status for a service.

``stop_command``
   **Ruby Type:** String

   The command used to stop a service.

``subscribes``
   **Ruby Type:** Symbol, 'Chef::Resource[String]'

   .. tag resources_common_notification_subscribes

   A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

   .. end_tag

   .. tag 5

   A timer specifies the point during the chef-client run at which a notification is run. The following timers are available:

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

``supports``
   **Ruby Type:** Hash

   A list of properties that controls how the chef-client is to attempt to manage a service: ``:restart``, ``:reload``, ``:status``. For ``:restart``, the init script or other service provider can use a restart command; if ``:restart`` is not specified, the chef-client attempts to stop and then start a service. For ``:reload``, the init script or other service provider can use a reload command. For ``:status``, the init script or other service provider can use a status command to determine if the service is running; if ``:status`` is not specified, the chef-client attempts to match the ``service_name`` against the process table as a regular expression, unless a pattern is specified as a parameter property. Default value: ``{ :restart => false, :reload => false, :status => false }`` for all platforms (except for the Red Hat platform family, which defaults to ``{ :restart => false, :reload => false, :status => true }``.)

``timeout``
   **Ruby Type:** Integer

   The amount of time (in seconds) to wait before timing out. Default value: ``60``.

Providers
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The **windows_service** resource does not have service-specific short names. This is because the chef-client identifies the platform at the start of every chef-client run based on data collected by Ohai. The chef-client looks up the platform, and then determines the correct provider for that platform. In certain situations, such as when more than one init system is available on a node, a specific provider may need to be identified by using the ``provider`` attribute and the long name for that provider.

This resource has the following providers:

``Chef::Provider::Service::Windows``, ``windows_service``
   The provider that is used with the Microsoft Windows platform.

Example
+++++++++++++++++++++++++++++++++++++++++++++++++++++

**Start a service manually**

.. tag resource_service_windows_manual_start

.. To install a package:

.. code-block:: ruby

   windows_service 'BITS' do
     action :configure_startup
     startup_type :manual
   end

.. end_tag

knife bootstrap Settings
-----------------------------------------------------
The following options are new:

``--[no-]node-verify-api-cert``
   Verify the SSL certificate on the Chef server. When ``true``, the chef-client always verifies the SSL certificate. When ``false``, the chef-client uses the value of ``ssl_verify_mode`` to determine if the SSL certificate requires verification. If this option is not specified, the setting for ``verify_api_cert`` in the configuration file is applied.

``--node-ssl-verify-mode PEER_OR_NONE``
   Set the verify mode for HTTPS requests.

   Use ``none`` to do no validation of SSL certificates.

   Use ``peer`` to do validation of all SSL certificates, including the Chef server connections, S3 connections, and any HTTPS **remote_file** resource URLs used in the chef-client run. This is the recommended setting.

``-t TEMPLATE``, ``--bootstrap-template TEMPLATE``
   The bootstrap template to use. This may be the name of a bootstrap template---``chef-full``, for example---or it may be the full path to an Embedded Ruby (ERB) template that defines a custom bootstrap. Default value: ``chef-full``, which installs the chef-client using the omnibus installer on all supported platforms.

   .. note:: The ``--distro`` and ``--template-file`` options are deprecated.

knife status Settings
-----------------------------------------------------
The following options are new:

``-l``, ``--long``
   Display all attributes in the output and show the output as JSON.

``-m``, ``--medium``
   Display normal attributes in the output and to show the output as JSON.

fsck_device Property
-----------------------------------------------------
The following property is new for the **mount** resource:

.. list-table::
   :widths: 150 450
   :header-rows: 1

   * - Property
     - Description
   * - ``fsck_device``
     - The fsck device on the Solaris platform. Default value: ``-``.

metadata.rb Settings
-----------------------------------------------------
The following settings are new:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Setting
     - Description
   * - ``issues_url``
     - The URL for the location in which a cookbook's issue tracking is maintained. This setting is also used by Chef Supermarket. For example:

       .. code-block:: ruby

          source_url "https://github.com/chef-cookbooks/chef-client/issues"

   * - ``source_url``
     - The URL for the location in which a cookbook's source code is maintained. This setting is also used by Chef Supermarket. For example:

       .. code-block:: ruby

          source_url "https://github.com/chef-cookbooks/chef-client"

.. warning:: The ``name`` attribute is now a required setting in the metadata.rb file.

http_request Actions
-----------------------------------------------------
The ``:get`` and ``:head`` actions appended a hard-coded query string---``?message=resource_name``---that cannot be overridden. This hard-coded string is deprecated in the chef-client 12.0 release. Cookbooks that rely on this string need to be updated to manually add it to the URL as it is passed to the resource.

Recipe DSL
-----------------------------------------------------
The following methods have been added to the Recipe DSL: ``shell_out``, ``shell_out!``, and ``shell_out_with_systems_locale``.

shell_out
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_shell_out

The ``shell_out`` method can be used to run a command against the node, and then display the output to the console when the log level is set to ``debug``.

The syntax for the ``shell_out`` method is as follows:

.. code-block:: ruby

   shell_out(command_args)

where ``command_args`` is the command that is run against the node.

.. end_tag

shell_out!
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_shell_out_bang

The ``shell_out!`` method can be used to run a command against the node, display the output to the console when the log level is set to ``debug``, and then raise an error when the method returns ``false``.

The syntax for the ``shell_out!`` method is as follows:

.. code-block:: ruby

   shell_out!(command_args)

where ``command_args`` is the command that is run against the node. This method will return ``true`` or ``false``.

.. end_tag

shell_out_with_systems_locale
+++++++++++++++++++++++++++++++++++++++++++++++++++++
.. tag dsl_recipe_method_shell_out_with_systems_locale

The ``shell_out_with_systems_locale`` method can be used to run a command against the node (via the ``shell_out`` method), but using the ``LC_ALL`` environment variable.

The syntax for the ``shell_out_with_systems_locale`` method is as follows:

.. code-block:: ruby

   shell_out_with_systems_locale(command_args)

where ``command_args`` is the command that is run against the node.

.. end_tag

value_for_platform
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The ``value_for_platform`` helper may use version constraints, such as ``>=`` and ``~>`` to help resolve situations where version numbers look like ``7.0.<buildnumber>``. For example:

.. code-block:: ruby

   value_for_platform(
     "redhat" => {
       "~> 7.0" => "version 7.x.y"
       ">= 8.0" => "version 8.0.0 and greater"
     }
   }

.. note:: When two version constraints match it is considered ambiguous and will raise an exception. An exact match, however, will always take precedence over a version constraint.

File Specificity
-----------------------------------------------------
The pattern for file specificity depends on two things: the lookup path and the source attribute. The first pattern that matches is used:

#. /host-$fqdn/$source
#. /$platform-$platform_version/$source
#. /$platform/$source
#. /default/$source
#. /$source

Use an array with the ``source`` attribute to define an explicit lookup path. For example:

.. code-block:: ruby

   file '/conf.py' do
     source ["#{node.chef_environment}.py", 'conf.py']
   end

or:

.. code-block:: ruby

   template '/test' do
     source ["#{node.chef_environment}.erb", 'default.erb']
   end

macOS, Passwords
-----------------------------------------------------
The following properties are new for the **user** resource:

.. list-table::
   :widths: 150 450
   :header-rows: 1

   * - Property
     - Description
   * - ``iterations``
     - The number of iterations for a password with a SALTED-SHA512-PBKDF2 shadow hash.
   * - ``salt``
     - The salt value for a password shadow hash. macOS version 10.7 uses SALTED-SHA512 and version 10.8 (and higher) uses SALTED-SHA512-PBKDF2 to calculate password shadow hashes.

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

chef-client Options
-----------------------------------------------------
The following options are updated for the chef-client executable:

``--chef-zero-port PORT``
   The port on which chef-zero listens. If a port is not specified---individually or as range of ports from within the command---the chef-client will scan for ports between 8889-9999 and will pick the first port that is available. This port or port range may also be specified using the ``chef_zero.port`` setting in the client.rb file.

``-o RUN_LIST_ITEM``, ``--override-runlist RUN_LIST_ITEM``
   Replace the current run-list with the specified items. This option will not clear the list of cookbooks (and related files) that is cached on the node.

The following configuration settings are updated for the client.rb file and now default to ``true``:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Setting
     - Description
   * - ``disable_event_logger``
     - Enable or disable sending events to the Microsoft Windows "Application" event log. When ``false``, events are sent to the Microsoft Windows "Application" event log at the start and end of a chef-client run, and also if a chef-client run fails. Set to ``true`` to disable event logging. Default value: ``true``.
   * - ``no_lazy_load``
     - Download all cookbook files and templates at the beginning of the chef-client run. Default value: ``true``.
   * - ``file_staging_uses_destdir``
     - How file staging (via temporary files) is done. When ``true``, temporary files are created in the directory in which files will reside. When ``false``, temporary files are created under ``ENV['TMP']``. Default value: ``true``.
   * - ``local_key_generation``
     - Use to specify whether the Chef server or chef-client will generate the private/public key pair. When ``true``, the chef-client will generate the key pair, and then send the public key to the Chef server. Default value: ``true``.

Filter Search Results
-----------------------------------------------------
.. tag dsl_recipe_method_search_filter_result

Use ``:filter_result`` as part of a search query to filter the search output based on the pattern specified by a Hash. Only attributes in the Hash will be returned.

.. note:: .. tag notes_filter_search_vs_partial_search

          Prior to chef-client 12.0, this functionality was available from the ``partial_search`` cookbook and was referred to as "partial search".

          .. end_tag

The syntax for the ``search`` method that uses ``:filter_result`` is as follows:

.. code-block:: ruby

   search(:index, 'query',
     :filter_result => { 'foo' => [ 'abc' ],
                         'bar' => [ '123' ],
                         'baz' => [ 'sea', 'power' ]
                       }
         ).each do |result|
     puts result['foo']
     puts result['bar']
     puts result['baz']
   end

where:

* ``:index`` is of name of the index on the Chef server against which the search query will run: ``:client``, ``:data_bag_name``, ``:environment``, ``:node``, and ``:role``
* ``'query'`` is a valid search query against an object on the Chef server
* ``:filter_result`` defines a Hash of values to be returned

For example:

.. code-block:: ruby

   search(:node, 'role:web',
     :filter_result => { 'name' => [ 'name' ],
                         'ip' => [ 'ipaddress' ],
                         'kernel_version' => [ 'kernel', 'version' ]
                       }
         ).each do |result|
     puts result['name']
     puts result['ip']
     puts result['kernel_version']
   end

.. end_tag

knife search
+++++++++++++++++++++++++++++++++++++++++++++++++++++
The ``knife search`` subcommand allows filtering search results with a new option:

``-f FILTER``, ``--filter-result FILTER``
   Use to return only attributes that match the specified ``FILTER``. For example: ``\"ServerName=name, Kernel=kernel.version\"``.

**execute** Resource, ``path`` Property
-----------------------------------------------------
.. tag resources_common_resource_execute_attribute_path

The ``path`` property has been deprecated and will throw an exception in Chef Client 12 or later. We recommend you use the ``environment`` property instead.

.. end_tag

**git** Property
-----------------------------------------------------
The following property is new for the **git** resource:

.. list-table::
   :widths: 200 300
   :header-rows: 1

   * - Property
     - Description
   * - ``environment``
     - A Hash of environment variables in the form of ``({"ENV_VARIABLE" => "VALUE"})``. (These variables must exist for a command to be run successfully.)

       .. note:: The **git** provider automatically sets the ``ENV['HOME']`` and ``ENV['GIT_SSH']`` environment variables. To override this behavior and provide different values, add ``ENV['HOME']`` and/or ``ENV['GIT_SSH']`` to the ``environment`` Hash.

Chef::Provider, Custom Resources
-----------------------------------------------------
.. tag 16_method_updated_by_last_action_example

If a custom resource was created in the ``/libraries`` directory of a cookbook that also uses a core resource from the chef-client within the custom resource, the base class that is associated with that custom resource must be updated. In previous versions of the chef-client, the ``Chef::Provider`` class was all that was necessary because the Recipe DSL was included in the ``Chef::Provider`` base class.

For example, the ``lvm_logical_volume`` custom resource from the `lvm cookbook <https://github.com/chef-cookbooks/lvm/blob/master/libraries/provider_lvm_logical_volume.rb>`_ uses the **directory** and **mount** resources:

.. code-block:: ruby

   class Chef
     class Provider
       class LvmLogicalVolume < Chef::Provider
         include Chef::Mixin::ShellOut

         ...
         if new_resource.mount_point
           if new_resource.mount_point.is_a?(String)
             mount_spec = { :location => new_resource.mount_point }
           else
             mount_spec = new_resource.mount_point
           end

           dir_resource = directory mount_spec[:location] do
             mode '0755'
             owner 'root'
             group 'root'
             recursive true
             action :nothing
             not_if { Pathname.new(mount_spec[:location]).mountpoint? }
           end
           dir_resource.run_action(:create)
           updates << dir_resource.updated?

           mount_resource = mount mount_spec[:location] do
             options mount_spec[:options]
             dump mount_spec[:dump]
             pass mount_spec[:pass]
             device device_name
             fstype fs_type
             action :nothing
           end
           mount_resource.run_action(:mount)
           mount_resource.run_action(:enable)
           updates << mount_resource.updated?
         end
         new_resource.updated_by_last_action(updates.any?)
       end

Starting with chef-client 12, the Recipe DSL is removed from the ``Chef::Provider`` base class and is only available by using ``LWRPBase``. Cookbooks that contain custom resources authored for the chef-client 11 version should be inspected and updated.

.. end_tag

.. tag dsl_provider_method_updated_by_last_action_example

Cookbooks that contain custom resources in the ``/libraries`` directory of a cookbook should:

* Be inspected for instances of a) the ``Chef::Provider`` base class, and then b) for the presence of any core resources from the chef-client
* Be updated to use the ``LWRPBase`` base class

For example:

.. code-block:: ruby

   class Chef
     class Provider
       class LvmLogicalVolume < Chef::Provider::LWRPBase
         include Chef::Mixin::ShellOut

         ...
         if new_resource.mount_point
           if new_resource.mount_point.is_a?(String)
             mount_spec = { :location => new_resource.mount_point }
           else
             mount_spec = new_resource.mount_point
           end

           dir_resource = directory mount_spec[:location] do
             mode 0755
             owner 'root'
             group 'root'
             recursive true
             action :nothing
             not_if { Pathname.new(mount_spec[:location]).mountpoint? }
           end
           dir_resource.run_action(:create)
           updates << dir_resource.updated?

           mount_resource = mount mount_spec[:location] do
             options mount_spec[:options]
             dump mount_spec[:dump]
             pass mount_spec[:pass]
             device device_name
             fstype fs_type
             action :nothing
           end
           mount_resource.run_action(:mount)
           mount_resource.run_action(:enable)
           updates << mount_resource.updated?
         end
         new_resource.updated_by_last_action(updates.any?)
       end

.. end_tag

SSL Certificates
-----------------------------------------------------
.. tag server_security_ssl_cert_client

Chef server 12 enables SSL verification by default for all requests made to the server, such as those made by knife and the chef-client. The certificate that is generated during the installation of the Chef server is self-signed, which means the certificate is not signed by a trusted certificate authority (CA) that ships with the chef-client. The certificate generated by the Chef server must be downloaded to any machine from which knife and/or the chef-client will make requests to the Chef server.

For example, without downloading the SSL certificate, the following knife command:

.. code-block:: bash

   $ knife client list

responds with an error similar to:

.. code-block:: bash

   ERROR: SSL Validation failure connecting to host: chef-server.example.com ...
   ERROR: OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 state=SSLv3 ...

This is by design and will occur until a verifiable certificate is added to the machine from which the request is sent.

.. end_tag

See `SSL Certificates </chef_client_security.html#ssl-certificates>`__ for more information about how knife and the chef-client use SSL certificates generated by the Chef server.

Changelog
=====================================================
https://github.com/chef/chef/blob/master/CHANGELOG.md
