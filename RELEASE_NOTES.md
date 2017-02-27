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

