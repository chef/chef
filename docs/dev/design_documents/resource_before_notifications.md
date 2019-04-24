# Before Notifications

Let users trigger another resource prior to an action happening.

## Motivation

    As a Chef user,
    I want to make one resource action a precondition for another,
    So that when two resources depend on each other, I can make an update succeed.

    As a Chef user,
    I want this action only to happen if the other resource *does* update,
    So that I don't unnecessarily run my preconditions on every single Chef run.

    As a Chef user,
    I want Chef to run an action if a resource updates,
    So that I don't have to implement the resource test logic in my recipe.

## Specification

We add a new `:before` timing which causes a notification to happen
*before* the resource actually updates. If the resource will not actually update,
this event does not fire.

The events you can specify would become:

- `:before` - before the resource updates, but *only* if an update will occur.
- `:immediately` - after the resource updates, but *only* if an update occurred.
- `:delayed` - after the resource updates, at the end of the run.

```ruby
package "foo" do
  action :upgrade
  # The package upgrade will fail if we try to upgrade while it runs!!!
  notifies :stop, "service[blah]", :before
end

service "blah" do
end
```

This will work for both `subscribes` and `notifies`.

### Backwards Compatibility

This will only affect resources, which have `:before` on them, and will
not modify any existing resources or recipes.

### Implementation

There is a tricky implementation detail here, because both the test part -- "is my
package version lower than the latest?" -- and the set part -- "call rpm and update the
package"-- of a resource are both part of the action. Chef only runs one
action to run at a time, and it seems ill-advised to change that without a lot
of extra thinking.

To get around this without breaking the model, we propose that resources with an
`:before` action run a why-run test of the action and trigger off of
that, before running the action for real. The flow of this resource:

```ruby
package "foo" do
  action :upgrade
  notifies :stop, "service[blah]", :before
end
```

The execution of the package upgrade looks like this:

1. If `:before` events are on the resource:
   a. raise an error if the resource does not support `why-run`.
   b. Turn on `why-run` temporarily.
   c. Run the action.
   d. Send the notification if `updated_by_last_action?` is true.
   e. Turn off `why-run`.
2. Run the action (for real!).
3. Send `:immediate` or `:delayed` notifications if `updated_by_last_action?` is true.
