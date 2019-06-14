---
title: Upgrading From Chef 12
---

# Deprecations

In order to see all deprecation warnings, users must upgrade through every major version and must run the
last version of chef-client for each major version.

That means that a user on Chef Infra 12.11.18 must first upgrade to Chef Infra 12.21.31, then to Chef Infra 13.12.14, then
(as of this writing) to Chef Infra 14.13.11 before upgrading to the latest Chef Infra 15.

It is always the rule that the prior minor version of Chef Infra Client has all the deprecation warnings that are necessary
to be addressed for the next major version.  Once we begin development on the next major version of the Client we delete
all the code and all the deprecation warnings.  Old cookbook code can no longer receive warnings, it will simply wind up
on new code paths and fail hard.  The old Chef Infra Client code which issued the deprecation warning has necessarily been
removed as part of cleaning up and changing to the new behavior.  This makes it impossible to skip versions from
Chef Infra Client 12 directly to 14 and still address all the deprecations.

It is not necessary to upgrade the entire production environment to those versions of Chef Infra Client, but
test-kitchen must be run on those versions of Chef Infra Client, and the deprecations must be fixed in all the
cookbooks.

The `treat_deprecation_warnings_as_errors` flag to the test-kitchen provisioner may be useful to accomplish this:

```
provisioner:
  name: chef_zero
    client.rb:
      treat_deprecation_warnings_as_errors: true
```

# CHEF-3694 Deprecation Warnings

An very notable exception to the above rule that all deprecation warnings must be addressed is the old CHEF-3694
deprecation warnings.

Not all of these warnings must be fixed.  It was not possible to determine in code which of them were important to fix
and which of them could be ignored.  In actual fact most of them can be ignored without any impact.

The only way to test which ones need fixing, though, is to run the cookbooks through Chef Infra 13 or later and test
the behavior.  If the cookbooks work, then the warnings can be ignored.  All the deprecation warnings do in this case
are warn that there might some risk of behavior change on upgrade.

The technical details of the issue is that with resource cloning the properties of resources that are declared multiple
times is that the properties of the prior research are merged with the newly declared properties and that becomes
the resource.  That accumulated state goes away when upgrading from Chef Infra 12.  The problem is that determining if
that state was important or not to the specific resource being merged requires knowledge of the semantic meaning of
the properties being merged.  They may be important or they may not, and it requires the user to make that
determination.  In most cases the merged resources are fairly trivial and the merged properties do not substantially
change any behavior that is meaningful and the cookbooks will still work correctly.

To ignore these errors while still treating deprecations as error you can use the `silence_deprecation_warnings` config
in test-kitchen:

```
provisioner:
  name: chef_zero
    client.rb:
      treat_deprecation_warnings_as_errors: true
      silence_deprecation_warnings:
        - chef-3694
```

# Notifications From Custom Resources

A behavior change which occurred in Chef Infra 12.21.3 which later was recognized to potentially be breaking is that custom
resources now have their own delayed notification phase.  If it is necessary to create a resource, like a service resource,
in a custom resource and then send a delayed notification to it which is executed at the end of the entire chef client
run (and not at the end of the execution of the custom resource's action) then the resource needs to be declared in
the outer "root" or "recipe" run context.

This code in Chef Infra before 12.21.3 would restart the service at the end of the run:

```ruby
use_inline_resources

action :doit do
  # this creates the service resource in the run_context of the custom resource
  service "whateverd" do
    action :nothing
  end

  # under Chef-12 this will send a delayed notification which will run at the end of the chef-client run
  file "/etc/whatever.d/whatever.conf" do
    contents "something"
    notifies :restart, "service[whateverd]", :delayed
  end
end
```

To preserve this exact behavior in version of Chef Infra Client of 12.21.3 or later:

```ruby
use_inline_resources

action :doit do
  # this creates the resource in the outermost run_context using find_resource's API which is
  # is "find-or-create" (use edit_resource with a block to get "create-or-update" semantics).
  with_run_context :root do
    find_resource(:service, "whateverd") do
      action :nothing
    end
  end

  # this will now send a notification to the outer run context and will restart the service
  # at the very end of the chef client run
  file "/etc/whatever.d/whatever.conf" do
    contents "something"
    notifies :restart, "service[whateverd]", :delayed
  end
end
```

This behavior is not backwards compatible, and the code which executes properly on 12.21.3 will not run properly on
version before that, and vice versa.  There are no deprecation warnings for this behavior, it was not anticipated at
the time that this would produce any backwards incompatibility and by the time it was understood there was no way
to retroactively change behavior or add any warnings. It is not a common issue.  The new behavior is more typically
preferable since it asserts that the once the configuration for the service is updated that the service is restarted
by the delayed action which occurs at the end of the custom resource's action and then future recipes can rely on
the service being in a correctly running state.

