# Chef Client Release Notes 12.1.0:

# Internal API Changes in this Release

## Experimental Audit Mode Feature

This is a new feature intended to provide _infrastructure audits_.  Chef already allows you to configure your infrastructure
with code, but there are some use cases that are not covered by resource convergence.  What if you want to check that
the application Chef just installed is functioning correctly?  If it provides a status page an audit can check this
and validate that the application has database connectivity.

Audits are performed by leveraging [Serverspec](http://serverspec.org/) and [RSpec](https://relishapp.com/rspec) on the
node.  As such the syntax is very similar to a normal RSpec spec.

### Syntax

```ruby
control_group "Database Audit" do

  control "postgres package" do
    it "should not be installed" do
      expect(package("postgresql")).to_not be_installed
    end
  end

  let(:p) { port(111) }
  control p do
    it "has nothing listening" do
      expect(p).to_not be_listening
    end
  end

end
```

Using the example above I will break down the components of an Audit:

* `control_group` - This named block contains all the audits to be performed during the audit phase.  During Chef convergence
 the audits will be collected and ran in a separate phase at the end of the Chef run.  Any `control_group` block defined in
 a recipe that is ran on the node will be performed.
* `control` - This keyword describes a section of audits to perform.  The name here should either be a string describing
the system under test, or a [Serverspec resource](http://serverspec.org/resource_types.html).
* `it` - Inside this block you can use [RSpec expectations](https://relishapp.com/rspec/rspec-expectations/docs) to
write the audits.  You can use the Serverspec resources here or regular ruby code.  Any raised errors will fail the
audit.

### Output and error handling

Output from the audit run will appear in your `Chef::Config[:log_location]`.  If an audit fails then Chef will raise
an error and exit with a non-zero status.

### Further reading

More information about the audit mode can be found in its
[RFC](https://github.com/opscode/chef-rfc/blob/master/rfc035-audit-mode.md)

# End-User Changes

## OpenBSD Package provider was added

The package resource on OpenBSD is wired up to use the new OpenBSD package provider to install via pkg_add on OpenBSD systems.

## Case Insensitive URI Handling

Previously, when a URI scheme contained all uppercase letters, Chef
would reject the URI as invalid. In compliance with RFC3986, Chef now
treats URI schemes in a case insensitive manner.

## File Content Verification (RFC 027)

Per RFC 027, the file and file-like resources now accept a `verify`
attribute.  This attribute accepts a string(shell command) or a ruby
block (similar to `only_if`) which can be used to verify the contents
of a rendered template before deploying it to disk.

## Drop SSL Warnings
Now that the default for SSL checking is on, no more warning is emitted when SSL
checking is off.

## Multi-package Support
The `package` provider has been extended to support multiple packages. This
support is new and and not all subproviders yet support it. Full support for
`apt` and `yum` has been implemented.

## chef_gem deprecation of installation at compile time

A `compile_time` flag has been added to the chef_gem resource to control if it is installed at compile_time or not.  The prior behavior has been that this
resource forces itself to install at compile_time which is problematic since if the gem is native it forces build_essentials and other dependent libraries
to have to be installed at compile_time in an escalating war of forcing compile time execution.  This default was engineered before it was understood that a better
approach was to lazily require gems inside of provider code which only ran at converge time and that requiring gems in recipe code was bad practice.

The default behavior has not changed, but every chef_gem resource will now emit out a warning:

```
[2015-02-06T13:13:48-08:00] WARN: chef_gem[aws-sdk] chef_gem compile_time installation is deprecated
[2015-02-06T13:13:48-08:00] WARN: chef_gem[aws-sdk] Please set `compile_time false` on the resource to use the new behavior.
[2015-02-06T13:13:48-08:00] WARN: chef_gem[aws-sdk] or set `compile_time true` on the resource if compile_time behavior is required.
```

The preferred way to fix this is to make every chef_gem resource explicit about compile_time installation (keeping in mind the best-practice to default to false
unless there is a reason):

```ruby
chef_gem 'aws-sdk' do
  compile_time false
end
```

There is also a Chef::Config[:chef_gem_compile_time] flag which has been added.  If this is set to true (not recommended) then chef will only emit a single
warning at the top of the chef-client run:

```
[2015-02-06T13:27:35-08:00] WARN: setting chef_gem_compile_time to true is deprecated
```

It will behave like Chef 10 and Chef 11 and will default chef_gem to compile_time installations and will suppress
subsequent warnings in the chef-client run.

If this setting is changed to 'false' then it will adopt Chef-13 style behavior and will default all chef_gem installs to not run at compile_time by default.  This
may break existing cookbooks.

* All existing cookbooks which require compile_time true MUST be updated to be explicit about this setting.
* To be considered high quality, cookbooks which require compile_time true MUST be rewritten to avoid this setting.
* All existing cookbooks which do not require compile_time true SHOULD be updated to be explicit about this setting.

For cookbooks that need to maintain backwards compatibility a `respond_to?` check should be used:

```
chef_gem 'aws-sdk' do
  compile_time false if respond_to?(:compile_time)
end
```

## Knife Bootstrap Validatorless Bootstraps and Chef Vault integration

The knife bootstrap command now supports validatorless bootstraps.  This can be enabled via deleting the validation key.
When the validation key is not present, knife bootstrap will use the user key in order to create a client for the node
being bootstrapped.  It will also then create a node object and set the environment, run_list, initial attributes, etc (avoiding
the problem of the first chef-client failing and not saving the node's run_list correctly).

Also knife vault integration has been added so that knife bootstrap can use the client key to add chef vault items to
the node, reducing the number of steps necessary to bootstrap a node with chef vault.

There is no support for validatorless bootstraps when the node object has been precreated by the user beforehand, as part
of the process any old node or client will be deleted when doing validatorless bootstraps.  The old process with the validation
key still works for this use case.  The setting of the run_list, environment and json attributes first via knife bootstrap
should mitigate some of the need to precreate the node object by hand first.
