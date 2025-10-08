# Resource Validation Messaging

Custom resources provide multiple property validators, allowing authors to control property input beyond just simple data types. Authors can expect strings to match predefined strings, match a regex, or return true from a callback method. This gives the author great control over the input data, but doesn't provide the consumer with much information when the validator fails. This RFC provides the author with the ability to control the error text when the validator fails.

## Motivation

    As an author of custom resources,
    I want to control property inputs while providing useful error messaging on failure,
    so that users can easily understand why input data is not acceptable

    As a consumer of custom resources,
    I want detailed errors when I pass incorrect data to a resource,
    so that I quickly resolve failed chef-client runs.

## Specification

This design specifies a `validation_message` option for properties, which accepts a string. This message will be shown on failure in place of a generic failure message.

### Example

in resources/example.rb

```ruby
property :version,
          kind_of: String,
          default: '8.0.35'
          regex: [/^(?:(\d+)\.)?(?:(\d+)\.)?(\*|\d+)$/]
          validation_message: 'Version must be a X.Y.Z format String type'
```