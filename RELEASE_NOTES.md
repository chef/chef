*This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team.
Please see `https://docs.chef.io/release/<major>-<minor>/release_notes.html` for the official Chef release notes.*

# Chef Client Release Notes 12.12:

## Attribute read/write/unlink/exist? APIs

On the node object:

- `node.read("foo", "bar", "baz")` equals `node["foo"]["bar"]["baz"] `but with safety (nil instead of exception)
- `node.read!("foo", "bar", "baz")` equals `node["foo"]["bar"]["baz"]` and does raises NoMethodError

- `node.write(:default, "foo", "bar", "baz")` equals `node.default["foo"]["bar"] = "baz"` and autovivifies and replaces intermediate non-hash objects (very safe) 
- `node.write!(:default, "foo", "bar", "baz")` equals `node.default["foo"]["bar"] = "baz"` and while it autovivifies it can raise if you hit a non-hash on an intermediate key (NoMethodError)
- there is still no non-autovivifying writer, and i don't think anyone really wants one.
- `node.exist?("foo", "bar")` can be used to see if `node["foo"]["bar"]` exists

On node levels:

- `node.default.read/read!("foo")` operates similarly to `node.read("foo")` but only on default level
- `node.default.write/write!("foo", "bar")` is `node.write/write!(:default, "foo", "bar")`
- `node.default.unlink/unlink!("foo")` is `node.unlink/unlink!(:default, "foo")`
- `node.default.exist?("foo", "bar")` can be used to see if `node.default["foo"]["bar"]` exists

Deprecations:

- node.set is deprecated
- node.set_unless is deprecated

## `data_collector` enhancements

- Adds `node` to the `data_collector` message
- `data_collector` reports on all resources and not just those that have been processed

## `knife cookbook create` is deprecated. Use the chef-dk's `chef generate cookbook` instead.