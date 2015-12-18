# nil values and validation

`nil` setters and property defaults are a big snarl with our system because of
this conflict:

1. People who don't specify a default value for their property expect the
   default to be `nil`.
2. Some people want `nil` to be an invalid value for their property so that they
   can simplify their code by not having to handle it.
3. Copying a property from one resource to another is a common thing, and the
   combination of the above rules currently causes `property :x, String` to
   have an invalid default value, meaning it can't be copied. This is bad.

In coming up with solutions, there are a number of things around default values
and validation that have to be considered. I've written down these things (the
things I think we want to be true) here, and enumerated all of the solutions
I've heard so far, along with which rules they violate and surprises they
create.

## Rules

Things we want to be true:

1. A property with no default value successfully returns `nil` as its default,
   regardless of validation.

   This is the crux of the issue, the exception that means we have to do
   *something* special.

   - `property :x, String` has `nil` as its default value.
   - `property :x` has `nil` as its default value.

2. The default value of a property must be settable (the copy rule).

   Corollary: Setters and default values are validated, so nothing can get *into*
   the property unless it is valid.

   - `x("10")` for `property :x, Integer` is INVALID.
   - `property :x, Integer, default: "10"` is INVALID.
   - `property :x, Integer, default: lazy { "10" }` is INVALID.

3. Properties must never return invalid values.

   This is a general rule: we're trying to make properties that don't return
   unexpected values (this is why coercion is so powerful, for example). This
   rule can be satisfied by making `nil` an expected value, but it *still* needs
   to be spelled out.

4. Anything you can pass to a setter, you can put in a default.

   Corollary: default values (and lazy default values) are coerced.

   - `property :x, Integer, coerce: proc { |v| v.to_i }, default: "10"` is VALID.
   - `property :x, Integer, coerce: proc { |v| v.to_i }, default: lazy { "10" }` is VALID.

5. Copying a property value from A to B always works.

   Corollary, if a getter can successfully return a value, then the setter must
   allow it to be set.

   Combined with the above, this means:

   - `x(nil)` with `property :x, String` is VALID.
   - `x(nil)` with `property :x` is VALID.

6. Properties with valid non-nil default values should not accept `nil`.

   - `x(nil)` with `property :x, Symbol, default: :foo` is INVALID.

7. Lazy values must validate the same as non-lazy values.

   Particularly, this means we can't say `nil` is valid for `default: nil`
   but *not* valid for `default: lazy { nil }` (or more likely,
   `default: lazy { other_property_that_could_be_nil }`).

## Possible Solutions

The possible solutions I can come up with are below. I think the one that meets
all our criteria with the least complexity is "Properties with no default or
`default: nil` are valid", with "Properties with no default are valid" running
a close second for increased parsimony.

### `nil` is always validated

`nil` will fail validation if you don't allow it. This passes all our rules
except #1, which means this common construction would simply be invalid.

```
# This would throw ValidationError when you define the property
property :x, String
```

### `nil` is always valid

By declaring `nil` as always valid, we violate the spirit but not the letter of #2,
and allow `property :x, String` to work. However, we completely violate #5,
making `nil` unnecessarily valid for this property:

```
property :x, Symbol, default: :foo
```

Or for this more complex but still important case:

```
property :path, String, default: "/opt/chefdk"
property :config_path, String, default: lazy { "#{path}/default_config.ini" }
```

### Properties with no default treat `nil` as valid

This is tied with the next one for my favorite.

This passes all of the rules, and is simple. If the default is not specified,
then we are giving you a default, and we should take our own steps to make sure
it is a valid one.

The only issue is that these two would NOT be equivalent:

```
property :x, String
property :x, String, default: nil # ValidationError when declaring this
```

This is not intuitive. It's not terrible in my opinion, as the failure of
intuition would be revealed immediately on declaration with a clear error
message.

### Properties with no default or `default: nil` are valid

This is tied with the previous one for my favorite.

In this, we solve the above problem by treating `default: nil` as valid (but no
other construct). I don't think any other problems remain. This is arguably a
bit more complex than the previous one, but it's also less surprising.

### Default values are always valid

In this, we allow the user to specify your default value and always treat it as
valid. This solves the previous problem of `default: nil` being different from not
specifying a default, but brings with it a host of other problems. Some issues:

- There is no way to tell the range of values of a lazy default, so we have to
either treat those differently from constant defaults (validating them), make
the values inside valid for setters (violating the copy rule), or turn off
validation altogether for properties with lazy defaults (nobody wants that :).

- Coercion becomes an issue: either you have to turn it off when the user specifies
  the default value, or disallow users from doing validation in their coercion
  methods (which they will often do due to convenience: it turns out you are
  switching on the type in these methods a lot of the time anyway).

The question comes up of whether coercion could be used for default values, then:
many users will use coercion methods as a method of validation, as well, because
they are already often switching on the type of the input in coercion methods.

We can pass off the violation of rules like "properties should never
return invalid values" as Your Own Fault, but the more difficult implications
come with coercion: default values and setters no longer accept the same values
at all.  Consider properties like this:

```
property :connection, Chef::HTTPClient, proc { |v| }
```

### `nil` is valid for properties with lazy or `nil` defaults

This solution can work, but violates #6 (properties with non-nil defaults must
not accept nil). This case in particular will sadly accept `nil` for `config_path`:

```
property :path, String, default: "/opt/chefdk"
property :config_path, String, default: lazy { "#{path}/default_config.ini" }
```

This is also arguably the most complex of the rules.

The rule we really are after here is "`nil` is valid for properties whose
default can be `nil`", but I can't think of any other viable implementations,
since you can't inspect lazy values to see if they can return `nil` or not.
