_This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team. Please see <https://docs.chef.io/release_notes.html> for the official Chef release notes._

# Chef Client Release Notes 13.0:

## Back Compat Breaks

### The path property of the execute resource has been removed

It was never implemented in the provider, so it was always a no-op to use it, the remediation is
to simply delete it.

### Using the command property on any script resource (including bash, etc) is now a hard error

This was always a usage mistake.  The command property was used internally by the script resource and was not intended to be exposed
to users.  Users should use the code property instead (or use the command property on an execute resource to execute a single command).

### Omitting the code property on any script resource (including bash, etc) is now a hard error

It is possible that this was being used as a no-op resource, but the log resource is a better choice for that until we get a null
resource added.  Omitting the code property or mixing up the code property with the command property are also common usage mistakes
that we need to catch and error on.

### The chef_gem resource defaults to not run at compile time

The `compile_time true` flag may still be used to force compile time.

### The Chef::Config[:chef_gem_compile_time] config option has been removed

In order to for community cookbooks to behave consistently across all users this optional flag has been removed.

### The `supports[:manage_home]` and `supports[:non_unique]` API has been removed from all user providers

The remediation is to set the manage_home and non_unique properties directly.

### Using relative paths in the `creates` property of an execute resource with specifying a `cwd` is now a hard error

Without a declared cwd the relative path was (most likely?) relative to wherever chef-client happened to be invoked which is
not deterministic or easy to intuit behavior.

### Chef::PolicyBuilder::ExpandNodeObject#load_node has been removed

This change is most likely to only affect internals of tooling like chefspec if it affects anything at all.

### PolicyFile failback to create non-policyfile nodes on Chef Server < 12.3 has been removed

PolicyFile users on Chef-13 should be using Chef Server 12.3 or higher.

### Cookbooks with self dependencies are no longer allowed

The remediation is removing the self-dependency `depends` line in the metadata.

### Removed `supports` API from Chef::Resource

Retained only for the service resource (where it makes some sense) and for the mount resource.

### Removed retrying of non-StandardError exceptions for Chef::Resource

Exceptions not decending from StandardError (e.g. LoadError, SecurityError, SystemExit) will no longer trigger a retry if they are raised during the executiong of a resources with a non-zero retries setting.

### Removed deprecated `method_missing` access from the Chef::Node object

Previously, the syntax `node.foo.bar` could be used to mean `node["foo"]["bar"]`, but this API had sharp edges where methods collided
with the core ruby Object class (e.g. `node.class`) and where it collided with our own ability to extend the `Chef::Node` API.  This
method access has been deprecated for some time, and has been removed in Chef-13.

### Changed `declare_resource` API

Dropped the `create_if_missing` parameter that was immediately supplanted by the `edit_resource` API (most likely nobody ever used
this) and converted the `created_at` parameter from an optional positional parameter to a named parameter.  These changes are unlikely
to affect any cookbook code.

### Node deep-duping fixes

The `node.to_hash`/`node.to_h` and `node.dup` APIs have been fixed so that they correctly deep-dup the node data structure including every
string value.  This results in a mutable copy of the immutable merged node structure.  This is correct behavior, but is now more expensive
and may break some poor code (which would have been buggy and difficult to follow code with odd side effects before).

For example:

```
node.default["foo"] = "fizz"
n = node.to_hash   # or node.dup
n["foo"] << "buzz"
```

before this would have mutated the original string in-place so that `node["foo"]` and `node.default["foo"]` would have changed to "fizzbuzz"
while now they remain "fizz" and only the mutable `n["foo"]` copy is changed to "fizzbuzz".

### Freezing immutable merged attributes

Since Chef 11 merged node attributes have been intended to be immutable but the merged strings have not been frozen.  In Chef 13, in the
process of merging the node attributes strings and other simple objects are dup'd and frozen.  In order to get a mutable copy, you can
now correctly use the `node.dup` or `node.to_hash` methods, or you should mutate the object correctly through its precedence level like
`node.default["some_string"] << "appending_this"`.

### The Chef::REST API has been removed

It has been fully replaced with `Chef::ServerAPI` in chef-client code.

### Properties overriding methods now raise an error

Defining a property that overrides methods defined on the base ruby `Object` or on `Chef::Resource` itself can cause large amounts of
confusion.  A simple example is `property :hash` which overrides the Object#hash method which will confuse ruby when the Custom Resource
is placed into the Chef::ResourceCollection which uses a Hash internally which expects to call Object#hash to get a unique id for the
object.  Attempting to create `property :action` would also override the Chef::Resource#action method which is unlikely to end well for
the user.  Overriding inherited properties is still supported.

### `chef-shell` now supports solo and legacy solo modes

Running `chef-shell -s` or `chef-shell --solo` will give you an experience consistent with `chef-solo`. `chef-shell --solo-legacy-mode`
will give you an experience consistent with `chef-solo --legacy-mode`.

### Chef::Platform.set and related methods have been removed

The deprecated code has been removed.  All providers and resources should now be using Chef >= 12.0 `provides` syntax.

### Remove `sort` option for the Search API

This option has been unimplemented on the server side for years, so any use of it has been pointless.

### Remove Chef::ShellOut

This was deprecated and replaced a long time ago with mixlib-shellout and the shell_out mixin.

### Remove `method_missing` from the Recipe DSL

The core of chef hasn't used this to implement the Recipe DSL since 12.5.1 and its unlikely that any external code depended upon it.

### Simplify Recipe DSL wiring

Support for actions with spaces and hyphens in the action name has been dropped.  Resources and property names with spaces and hyphens
most likely never worked in Chef-12.  UTF-8 characters have always been supported and still are.

### `easy_install` resource has been removed

The Python `easy_install` package installer has been deprecated for many years,
so we have removed support for it. No specific replacement for `pip` is being
included with Chef at this time, but a `pip`-based `python_package` resource is
available in the [`poise-python`](https://github.com/poise/poise-python) cookbooks.

### Ruby version upgraded to 2.4.1

We've upgraded to the latest stable release of the Ruby programming
language.

### Resource can now declare a default name

The core `apt_update` resource can now be declared without any name argument, no need for `apt_update "this string doesn't matter but
why do i have to type it?"`.

This can be used by any other resource by just overriding the name property and supplying a default:

```ruby
  property :name, String, default: ""
```

Notifications to resources with empty strings as their name is also supported via either the bare resource name (`apt_update` --
matches what the user types in the DSL) or with empty brackets (`apt_update[]` -- matches the resource notification pattern).

### The knife ssh command applies the same fuzzifier as knife search node

A bare name to knife search node will search for the name in `tags`, `roles`, `fqdn`, `addresses`, `policy_name` or `policy_group` fields and will
match when given partial strings (available since Chef 11).  The `knife ssh` search term has been similarly extended so that the
search API matches in both cases.  The node search fuzzifier has also been extracted out to a `fuzz` option to Chef::Search::Query for re-use
elsewhere.

### Resources which later modify their name during creation will have their name changed on the ResourceCollection and notifications

```ruby
some_resource "name_one" do
  name "name_two"
end
```

The fix for sending notifications to multipackage resources involved changing the API which inserts resources into the resource collection slightly
so that it no longer directly takes the string which is typed into the DSL but reads the (possibly coerced) name off of the resource after it is
built.  The end result is that the above resource will be named `some_resource[name_two]` instead of `some_resource[name_one]`.  Note that setting
the name (*not* the `name_property`, but actually renaming the resource) is very uncommon.  The fix is to simply name the resource correctly in
the first place (`some_resource "name_two" do ...`)

### Removal of run_command and popen4 APIs

All the APIs in chef/mixlib/command have been removed.  They were deprecated by mixlib-shellout and the shell_out mixin API.

### Iconv has been removed from the ruby libraries and chef omnibus build

The ruby Iconv library was replaced by the Encoding library in ruby 1.9.x and since the deprecation of ruby 1.8.7 there has been no need
for the Iconv library but we have carried it forwards as a dependency since removing it might break some chef code out there which used
this library.  It has now been removed from the ruby build.  This also removes LGPLv3 code from the omnibus build and reduces build
headaches from porting iconv to every platform we ship chef-client on.

This will also affect nokogiri, but that gem natively supports UTF-8, UTF-16LE/BE, ISO-8851-1(Latin-1), ASCII and "HTML" encodings.  Users
who really need to write something like Shift-JIS inside of XML will need to either maintain their own nokogiri installs or will need to
convert to using UTF-8.

### Deprecated cookbook metadata has been removed

The `recommends`, `suggests`, `conflicts`, `replaces` and `grouping`
metadata fields are no longer supported, and have been removed, since
they were never used. Chef will ignore them in existing `metadata.rb`
files, but we recommend that you remove them. This was proposed in RFC 85.

### All unignored cookbook files will now be uploaded.

We now treat every file under a cookbook directory as belonging to a
cookbook, unless that file is ignored with a `chefignore` file. This is
a change from the previous behaviour where only files in certain
directories, such as `recipes` or `templates`, were treated as special.
This change allows chef to support new classes of files, such as Ohai
plugins or Inspec tests, without having to make changes to the cookbook
format to support them.

### DSL-based custom resources and providers no longer get module constants

Up until now, creating a `mycook/resources/thing.rb` would create a `Chef::Resources::MycookThing` name to access the resource class object.
This const is no longer created for resources and providers. You can access resource classes through the resolver API like:

```ruby
Chef::Resource.resource_for_node(:mycook_thing, node)
```

Accessing a provider class is a bit more complex, as you need a resource against which to run a resolution like so:

```ruby
Chef::ProviderResolver.new(node, find_resource!("mycook_thing[name]"), :nothing).resolve
```

### Default values for resource properties are frozen

A resource declaring something like:

```ruby
property :x, default: {}
```

will now see the default value set to be immutable. This prevents cases of
modifying the default in one resource affecting others. If you want a per-resource
mutable default value, define it inside a `lazy{}` helper like:

```ruby
property :x, default: lazy { {} }
```

### Rubygems provider sources behavior changed.

The behavior of `gem_package` and `chef_gem` is now to always apply the `Chef::Config[:rubygems_uri]` sources, which may be a
String uri or an Array of Strings.  If additional sources are put on the resource with the `source` property those are added
to the configured `:rubygems_uri` sources.

This should enable easier setup of rubygems mirrors particularly in "airgapped" environments through the use of the global config
variable.  It also means that an admin may force all rubygems.org traffic to an internal mirror, while still being able to
consume external cookbooks which have resources which add other mirrors unchanged (in a non-airgapped environment).

In the case where a resource must force the use of only the specified source(s), then the `include_default_source` property
has been added -- setting it to false will remove the `Chef::Config[:rubygems_url]` setting from the list of sources for
that resource.

The behavior of the `clear_sources` property is now to only add `--clear-sources` and has no magic side effects on the source options.

### `knife cookbook site vendor` has been removed

Please use `knife cookbook site install` instead.

### Cookbook root aliases

Rather than `attributes/default.rb`, cookbooks can now use `attributes.rb` in
the root of the cookbook. Similarly for a single default recipe, cookbooks can
use `recipe.rb` in the root of the cookbook.

### `use_inline_resources` is always enabled

The `use_inline_resources` provider mode is always enabled when using the
`action :name do ... end` syntax. You can remove the `use_inline_resources`
line.

### The logger and formatter settings are more predictable

The default now is the formatter.  There is no more automatic switching to the logger when logging or when output
is sent to a pipe.  The logger needs to be specifically requested with `--force-logger` or it will not show up.

The `--force-formatter` option does still exist, although it will probably be deprecated in the future.

Setting the `log_location` in the config.rb now applies to both daemonized and command-line invocation and there is
no magic which dups the logger in order to log to STDOUT on the command line in that case.

Setting logger settings in config.rb is most likely no longer appropriate and those settings should be changed to
command line flags on the config script or cronjob that invokes chef-client daemonized.  In other words:

```
chef-client -d -L /var/log/client.rb --force-logger
```

If your logfiles switch to the formatter, you need to include `--force-logger` for your daemonized runs.

If your command line invocations have no output, delete the config.rb setting for the log_location and move that
to the command line that invokes your daemon process.

Redirecting output to a file with `chef-client > /tmp/chef.out` now captures the same output as invoking it directly on the command
line with no redirection.

### Path Sanity disabled by default and modified

The chef client itself no long modifies its `ENV['PATH']` variable directly.  When using the `shell_out` API now, in addition to
setting up LANG/LANGUAGE/LC_ALL variables that API will also inject certain system paths and the ruby bindir and gemdirs into
the PATH (or Path on Windows).  The `shell_out_with_systems_locale` API still does not mangle any environment variables.  During
the Chef-13 lifecycle changes will be made to prep Chef-14 to switch so that `shell_out` by default behaves like
`shell_out_with_systems_locale`.  A new flag will get introduced to call `shell_out(..., internal: [true|false])` to either
get the forced locale and path settings ("internal") or not.  When that is introduced in Chef 13.x the default will be `true`
(backwards-compat with 13.0) and that default will change in 14.0 to 'false'.

The PATH changes have also been tweaked so that the ruby bindir and gemdir PATHS are prepended instead of appended to the PATH.
Some system directories are still appended.

Some examples of changes:

* `which ruby` in 12.x will return any system ruby and fall back to the embedded ruby if using omnibus
* `which ruby` in 13.x will return any system ruby and will not find the embedded ruby if using omnibus
* `shell_out_with_systems_locale("which ruby")` behaves the same as `which ruby` above
* `shell_out("which ruby")` in 12.x will return any system ruby and fall back to the embedded ruby if using omnibus
* `shell_out("which ruby")` in 13.x will always return the omnibus ruby first (but will find the system ruby if not using omnibus)

The PATH in `shell_out` can also be overridden:

* `shell_out("which ruby", env: { "PATH" => nil })` - behaves like shell_out_with_systems_locale()
* `shell_out("which ruby", env: { "PATH" => [...include PATH string here...] })` - set it arbitrarily however you need

Since most providers which launch custom user commands use `shell_out_with_systems_locale` (service, execute, script, etc) the behavior
will be that those commands that used to be having embedded omnibus paths injected into them no longer will.  Generally this will
fix more problems than it solves, but may causes issues for some use cases.

### Default guard clauses (`not_if`/`only_if`) do not change the PATH or other env vars

The implementation switched to `shell_out_with_systems_locale` to match `execute` resource, etc.

