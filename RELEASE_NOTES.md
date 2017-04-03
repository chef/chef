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
