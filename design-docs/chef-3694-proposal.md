# CHEF-3694 Proposal

## Background Reading

* [Jira Ticket](http://tickets.opscode.com/browse/CHEF-3694)
* [Solution Space Discussion Gist](https://gist.github.com/danielsdeleo/30a8719901eca6545488)

## Issue Summary

The core of the problem is that users can input two resources with the
same type and name in recipes, for example:

    log "danger" do
      message "deleting all the backups!"
    end

    log "danger" do
      message "restarting a service, you might get paged"
    end

There is an assumption in Chef's syntax that the name and type together
form a compound natural key for resource lookup. This is most prominent
in the syntax for notifications:

    file "/tmp/whatever" do
      content rand.to_s
      notifies :write, "log[danger]"
    end

Chef currently does the following when encountering a resource
declaration with a type/name pair that already exist in the resource
collection:

* Create a selective shallow clone of the existing resource. The
  "selective" shallow clone involves applying a blacklist to ignore some
  instance variables when cloning. In particular, `not_if` and `only_if`
  guards are not cloned.
* Evaluate the block passed to the resource declaration call in the
  context of the newly cloned resource (as normally happens when
  creating resources).
* Add the cloned and modified resource to the resource collection. (As
  with normal resource creation).

Note that this violates the implicit assumption of type+name uniqueness,
as there are now two resources with the same type and name in the
collection.

More info:
* code: https://github.com/opscode/chef/blob/c7e99e50b1b9bba72b3fd907e1fb3748b901eeee/lib/chef/resource.rb#L283-300
* Jira ticket: http://tickets.opscode.com/browse/CHEF-26

## Why Do Users Create "Duplicate" Resources?

### Unintentionally

There are several situations in which users create resources with
duplicate type+name pairs. The most common case we've seen in bug
reports is unintentional duplication:

    files = %w(one.txt two.txt)
    files.each do |filename|
      execute "touch_file" do
        command "touch /tmp/#{filename}"

        not_if "ls /tmp/#{filename}"
      end
    end

The two execute resources here are orthogonal, and the user does not
expect these to be linked in any way.

The repro case for each of these bugs involves unintentional resource
duplication:

* http://tickets.opscode.com/browse/CHEF-2812
* http://tickets.opscode.com/browse/CHEF-894
* http://tickets.opscode.com/browse/CHEF-2892

### Conflicting Community Cookbook Case

Similar to the above, but more difficult to fix, is a case where two
cookbooks conflict. Since resources are members of a single global
collection, it is possible for resources from different cookbooks to use
the same type, name pair.

I have personally not seen this in the wild, but it is a case users are
concerned about.

### Insert a Resource Into the Resource Collection at a Different Position

The original use case for the current behavior is to be able to add an
existing resource to the resource collection with a different action.
For example, if the user desires to install MySQL from a system package
but use a non-default filesystem location for the database files, a
recipe may do this:

    service "mysql" do
      # Uses runit:
      start_command "sv mysql start"
      stop_command "sv mysql start"

      action :stop
    end

    execute "mv /var/lib/mysql /mnt/mysql"

    service "mysql" do
      # This will use the start command from above because of resource
      # cloning:
      action :start
    end

## Proposed Behavior Changes

Some of these behavior changes are breaking. They should be implemented
in an optional way with the default being the present behavior until
Chef 12.

We will split the responsibilities of the current resource collection
into a _resource set_ and an _action list_. The resource set will be an
unordered collection of resources with type,name tuple keys, and no
duplicate keys. The action list will be an ordered collection of
resource, action tuples, with no uniqueness constraints. Though not
strictly required to solve CHEF-3694, this provides flexibility in how
chef alters contexts for other features and user-defined extensions.
(See below)

We will add the following to the recipe DSL:

    # TODO: NAME? Signature?
    trigger(:service, "apache2").to(:start)

    # ALSO: NAME?
    edit(:service, "apache2") do
      start_command "sv apache2 start"
      # etc.
    end

    # For Completeness:
    declare_resource(:service, "apache2") do
    end

The current recipe DSL syntax will just be a shortcut for composing the
above primitives:

    # This:
    service "apache2" do
      start_command "sv apache2 start"
      action :start
    end

    # Is a shorter way of doing this:
    declare_resource(:service, "apache2") do
      start_command "sv apache2 start"
    end

    # TODO: make consistent with above
    trigger(:service, "apache2") do
      action :start
    end

These primitives provide enough functionality to 

### Splitting Resource Collection

To be clear: this will be done in a backwards compatible manner, such
that `run_context.resource_collection` returns an object with the same
API as currently.

It may be possible to use some ugly workarounds to fix this issue
without splitting the resource collection's responsibilities; however, I
think that a look at our two fundamental requirements makes it clear
that we should use different data structures to implement them:

* Resources should be unique by {type, name}
* The same resource can have different actions at arbitrary places in
  the convergence order

This change also makes it possible to fix some inconsistencies in our
current model:

* Resources with `action :nothing` require a special case to be skipped
when iterating over the resource collection. If we instead add these
resources to the resource set, but don't place them in the action list,
the special casing goes away.
* There are use cases for LWRPs where the user would like to notify a
resource outside the LWRP, but otherwise run resources "inline". This
can be accomplished quite easily if LWRPs run with a separate action
list, but use the global resource set.

Finally, we can't anticipate every way that people will need to control,
mangle, or otherwise abuse Chef's reprogrammability to modify execution
order of resources, but with the changes proposed here, we have a stable
interface where we can give users total control over execution ordering
without monkey patching or digging into internals.

