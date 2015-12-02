<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

### `chef_version` and `ohai_version`

see: https://docs.chef.io/release/12-6/release_notes.html#new-metadata-rb-settings

The metadata.rb DSL is extended to support `chef_version` and `ohai_version` to establish ranges
of chef and ohai versions that the cookbook supports.

When the running chef or ohai version does not match, then the chef-client run will abort with an
exception immediately after cookbooks have been synchronized before any cookbook contents are
parsed.

The format of the dependencies is based on rubygems (and implemented with rubygems code).  Pessimistic
version constraints, floor and ceiling constraints, and specifying multiple constraints are all valid.

Examples:

```
# matches any 12.x version, but not 11.x or 13.x
chef_version "~> 12"
```

```
# matches any 12.x, 13.x, etc version
chef_version ">= 12"
```

```
# matches any chef 12 version >= 12.5.1 or any chef 13 version
chef_version ">= 12.5.1", "< 14.0"
```

```
# matches chef 11 >= 11.18.4 or chef 12 >= 12.5.1 (i.e. depends on a backported bugfix)
chef_version ">= 11.18.12", "< 12.0"
chef_version ">= 12.5.1", "< 13.0"
```

As seen in the last example multiple constraints are OR'd.

There is currently no support in supermarket for making this metadata visible in /universe to
depsolvers, or support in Berksfile/PolicyFile for automatically pruning cookbooks that fail
to match.

### `ksh` resources

Use the ksh resource to execute scripts using the Korn shell (ksh) interpreter.
This resource may also use any of the actions and properties that are available
to the execute resource.

Example:
```ruby
ksh 'hello world' do
  code <<-EOH
    echo "Hello world!"
    echo "Current directory: " $cwd
    EOH
end
```

See https://docs.chef.io/release/12-6/resource_ksh.html for more info.

### `dsc_resource` resource

Added reboot_action attribute to dsc_resource.

If the DSC resource indicates that it requires a reboot, reboot_action can use the reboot resource to
either reboot immediately (:reboot_now) or queue a reboot (:request_reboot).  The default value of reboot_action is :nothing.

### `knife bootstrap --ssh-identity-file`

The --identity-file option to `knife bootstrap` has been deprecated in favor of `knife bootstrap --ssh-identity-file`
to better align with other ssh related options.
