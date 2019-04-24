# Easy Resource Load And Converge Methods

With the introduction of `action` on resources, it becomes useful to have a
blessed way to get the actual value of the resource. This proposal adds
`load_current_value` and `converge_if_changed` to help with this purpose, enabling:

- Low-ceremony load methods (as easy to write as we can make it)
- A super easy converge model that automatically compares current vs. desired
  values and prints green text

## Motivation

    As a Chef resource writer,
    I want to be able to read the current value of my resource at converge time,
    so that it is easy to tell the difference between current and desired value.

    As a Chef resource writer,
    I want a converge model that compares current and desired values for me,
    So that the easiest converge to write is the most correct one.

## Specification

### `load_current_value`: in-place resource load

When using `action`, one needs a way to load the *actual* system value of the resource, so that it can be compared to the desired value, and a decision made as to whether to change anything.

When the resource writer defines `load_current_value` on the resource class, it can be called to load the real system value into the resource. Before any action runs, this will be used by `load_current_resource` to load the resource. `action` will do some important work before calling the new method:

1. Create a new instance of the resource with the same name.
2. Copy all non-desired-state values from the desired resource into the new instance.
3. Call `load_current_value` on the new instance.


```ruby
class File < Chef::Resource
  property :path, name_attribute: true
  property :mode, default: 0666
  property :content

  load_current_value do
    current_value_does_not_exist! unless File.exist?(path)
    mode File.stat(path).mode
    content IO.read(path)
  end

  action :create do
    converge_if_changed do
      File.chmod(mode, path)
      IO.write(path, content)
    end
  end
end

file '/x.txt' do
  # Before the change, the above code would have modified `mode` to be `0666`.
  # After, it leaves `mode` alone.
  content 'Hello World'
end
```

#### Non-existence

To appropriately handle actual value loading, the user needs a way to specify that the actual value legitimately does not exist, rather than simply not filling in the object and getting `nil`s in it. If `load_current_value` raises `Chef::Exceptions::ActualValueDoesNotExist`, the new resource will be discarded and `current_resource` becomes `nil`. The `current_value_does_not_exist!` method can be called to raise this.

NOTE: The alternative was to have users return `false` if the resource does not exist, but I didn't want users to be forced into the ceremony of a trailing `true` line.

```ruby
  load_current_value do
    # Check for existence before doing anything else.
    current_value_does_not_exist! if !File.exist?(path)

    # Set "mode" on the resource.
    mode File.stat(path).mode
  end
```

The block will also be passed the original (desired) resource as a parameter, in case it is needed.

#### Inheritance

`super` in `load_current_value!` will call the superclass's `load_current_value!` method.

#### Handling Multi-Key Resources

The new resource is created with all properties copied over *except* desired state properties (properties in `ResourceClass.state_properties`). This means `name`, and properties with `identity: true` or `desired_state: false` are copied over.  Normal `property` and `attribute` are not.

```ruby
class DataBagItem < Chef::Resource
  # Copied
  attribute :item_name, name_attribute: true
  attribute :data_bag_name, identity: true
  attribute :recursively_delete, desired_state: false
  # Not copied:
  attribute :data
  def load_current_value!
    data Chef::DataBagItem.new(data_bag_name, item_name).data
  end
end
```

### `converge_if_changed`: automatic test-and-set

The new `converge_if_changed do ... end` syntax is added to actions, which enables a *lot* of help for resource writers to make safe, effective resources.  It performs several key tasks common to nearly every resource (which are often not done correctly):

- Goes through all attributes on the resource and checks whether the desired
  value is different from the current value.
- If any attributes are different, prints appropriate green text.
- Honors why-run (and does not call the `converge_if_changed` block if why-run is enabled).

```ruby
class File < Chef::Resource
  property :path, name_attribute: true
  property :content

  load_current_value do
    current_value_does_not_exist! unless File.exist?(path)
    content IO.read(path)
  end

  action :create do
    converge_if_changed do
      IO.write(path, content)
    end
  end
end
```

#### Side-by-side: new and old

Here is a sample `converge_if_changed` statement from a hypothetical FooBarBaz resource with properties `foo`, `bar` and `baz`:

```ruby
converge_if_changed do
  if current_resource
    FooBarBaz.update(new_resource.id, new_resource.foo, new_resource.bar, new_resource.baz)
  else
    FooBarBaz.create(new_resource.id, new_resource.foo, new_resource.bar, new_resource.baz)
  end
end
```

This is what you would have to write to do the equivalent:

```ruby
if current_resource
  # We're updating; look for properties that the user wants to change (do the "test" part of test-and-set)
  differences = []
  if (new_resource.property_is_set?(:foo) && new_resource.foo != current_resource.foo)
    differences << "foo = #{new_resource.foo}"
  end
  if (new_resource.property_is_set?(:bar) && new_resource.bar != current_resource.bar)
    differences << "bar = #{new_resource.bar}"
  end
  if (new_resource.property_is_set?(:baz) && new_resource.baz != current_resource.baz)
    differences << "baz = #{new_resource.baz}"
  end

  if !differences.empty?
    converge_by "updating FooBarBaz #{new_resource.id}, setting #{differences.join(", ")}" do
      FooBarBaz.create(new_resource.id, new_resource.foo, new_resource.bar, new_resource.baz)
    end
  end

else
  # If the current resource doesn't exist, we're definitely creating it
  converge_by "creating FooBarBaz #{new_resource.id} with foo = #{new_resource.foo}, bar = #{new_resource.bar}, baz = #{new_resource.baz}" do
    FooBarBaz.update(new_resource.id, new_resource.foo, new_resource.bar, new_resource.baz)
  end
end
```

#### Desired value = actual value

> The easiest way to write a resource must be the most correct one.

There is a subtle pitfall when updating a resource, where the user has set *some* values, but not all. One can easily end up writing a resource, which will overwrite perfectly good system properties with their defaults, and can cause instability. If the user does not specify a property, it is generally preferable to preserve its existing value rather than overwrite it.

To prevent this, referencing the bare property in an `action` will now yield the *actual* value if load_current_value succeeded, and the *default* value if we are creating a new resource (if `load_current_value` raised `ActualValueDoesNotExist`).

```ruby
class File < Chef::Resource
  property :path, name_attribute: true
  property :mode, default: 0666
  property :content

  load_current_value do
    current_value_does_not_exist! unless File.exist?(path)
    mode File.stat(path).mode
    content IO.read(path)
  end

  action :create do
    converge_if_changed do
      File.chmod(mode, path)
      IO.write(path, content)
    end
  end
end

file '/x.txt' do
  # Before the change, the above code would have modified `mode` to be `0666`.
  # After, it leaves `mode` alone.
  content 'Hello World'
end
```

There will be times when the old behavior of overwriting with defaults is desired. The resource writer can still find out whether `mode` was set with `property_is_set?(:mode)`, and can still access the default value with `new_resource.mode` if it is not set.

There are no backwards-compatibility issues with this because it only applies to `action`, which has not been released yet.

#### Compound Resource Convergence

Some resources perform several different (possibly expensive) operations, depending on what is set. `converge_if_changed :attribute1, :attribute2, ... do` allows the user to target different groups of changes based on exactly which attributes have changed:

```ruby
class File < Chef::Resource
  property :path, name_attribute: true
  property :mode
  property :content

  load_current_value do
    current_value_does_not_exist! unless File.exist?(path)
    mode File.stat(path).mode
    content IO.read(path)
  end

  action :create do
    converge_if_changed :mode do
      File.chmod(mode, path)
    end
    converge_if_changed :content do
      IO.write(path, content)
    end
  end
end
```