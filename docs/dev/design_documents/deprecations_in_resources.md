# Deprecation Warnings Within Custom Resources

In Chef 12, we introduced deprecation warnings within the chef-client. This allowed us to communicate future breaking changes to users. The warnings and integration within Test Kitchen have become a powerful tool, allowing users to future-proof their cookbooks and ease chef-client migration projects.

This design extends the deprecation functionality to custom resources, allowing authors to warn consumers of future breaking changes to their resources.

## Motivation

    As an author of custom resources,
    I want to warn resource consumers of future breaking changes to resources,
    so that they can update their wrapper cookbooks before my next release.

	As an author of custom resources,
    I want to provide immediate backwards compatibility in property names while still warning users,
    so that they can update their wrapper cookbooks before my next release.

	As an author of custom resources,
    I want to entirely deprecate a resource that users are consuming,
    so that they can update their wrapper cookbooks before my next release.

	As a consumer of custom resources,
    I want to be warned when I use deprecated functionality,
    so that I can update my wrapper cookbooks.

## Specification

### deprecated method for resources

This new method will let authors communicate to consumers that a resource is going away in the future. Right now, we rely on readme or changelog entries, which are not a very effective way to communicate to consumers. This method will accept a string, which becomes the warning message.

#### Example

in resources/example.rb

```ruby
deprecated 'This resource will be removed in the 3.0 release of the example cookbook in April 2018. You should use example_ng instead. See the readme for additional information.'
```

### deprecated method for properties

This new option for properties will let authors communicate to consumers that an individual property is going away in the future. Right now, we rely on readme or changelog entries, which are not a very effective way to communicate to consumers. This method will accept a string, which becomes the warning message.

#### Example

in resources/example.rb

```ruby
property :destroy_everything,
         kind_of: [true, false],
         default: true,
         deprecated: 'Turns out destroying everything was a bad idea. This property will be removed in the 3.0 release of this cookbook in April 2018 and will throw an error if set at that time.'
```

### deprecated_property_alias

Currently if a resource author decides to change the name of a property, they have two options:
    - Use `alias_method`, which silently routes old properties to the new names, or
    - Define both properties in the resource, and include functionality to set the new value while using the old value and warning the user.

`alias_method` doesn't alert cookbook consumers to the change, and writing your own code to perform deprecation warnings is cumbersome and rarely done. A new `deprecated_property_alias` would behave similar to a `alias_method`, but throw deprecation warnings while providing backwards compatibility. It would accept and optional `String` value that would be used in place of a generic deprecation message.

#### Example

in resources/example.rb

```ruby
deprecated_property_alias :set, :set_impact, 'The set property has been renamed to set_impact. Set will be removed from this cookbook in the next release in April 2018.'
```
