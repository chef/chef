<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

### Knife now prefers to use `config.rb` rather than `knife.rb`

Knife will now look for `config.rb` in preference to `knife.rb` for its
configuration file. The syntax and configuration options available in
`config.rb` are identical to `knife.rb`. Also, the search path for
configuration files is unchanged.

At this time, it is _recommended_ that users use `config.rb` instead of
`knife.rb`, but `knife.rb` is not deprecated; no warning will be emitted
when using `knife.rb`. Once third-party application developers have had
sufficient time to adapt to the change, `knife.rb` will become
deprecated and config.rb will be preferred.

### value_for_platform Method

- where <code>"platform"</code> can be a comma-separated list, each specifying a platform, such as Red Hat, openSUSE, or Fedora, <code>version</code> specifies the version of that platform, and <code>value</code> specifies the value that will be used if the node's platform matches the <code>value_for_platform</code> method. If each value only has a single platform, then the syntax is like the following:
+ where <code>platform</code> can be a comma-separated list, each specifying a platform, such as Red Hat, openSUSE, or Fedora, <code>version</code> specifies either the exact version of that platform, or a constraint to match the platform's version against. The following rules apply to constraint matches:

+ *  Exact matches take precedence no matter what, and should never throw exceptions.
+ *  Matching multiple constraints raises a <code>RuntimeError</code>.
+ *  The following constraints are allowed: <code><,<=,>,>=,~></code>.
+
+ The following is an example of using the method with constraints:
+
+ ```ruby
+ value_for_platform(
+   "os1" => {
+     "< 1.0" => "less than 1.0",
+     "~> 2.0" => "version 2.x",
+     ">= 3.0" => "version 3.0",
+     "3.0.1" => "3.0.1 will always use this value" }
+ )
+ ```

+ If each value only has a single platform, then the syntax is like the following:

### environment attribute to git provider

Similar to other environment options:

```
environment     Hash of environment variables in the form of {"ENV_VARIABLE" => "VALUE"}.
```

Also the `user` attribute should mention the setting of the HOME env var:

```
user      The system user that is responsible for the checked-out code.  The HOME environment variable will automatically be
set to the home directory of this user when using this option.
```

### Metadata `name` Attribute is Required.

Current documentation states:

> The name of the cookbook. This field is inferred unless specified.

This is no longer correct as of 12.0. The `name` field is required; if
it is not specified, an error will be raised if it is not specified.

### chef-zero port ranges

- to avoid crashes, by default, Chef will now scan a port range and take the first available port from 8889-9999.
- to change this behavior, you can pass --chef-zero-port=PORT_RANGE (for example, 10,20,30 or 10000-20000) or modify Chef::Config.chef_zero.port to be a po
rt string, an enumerable of ports, or a single port number.

### Encrypted Data Bags Version 3

Encrypted Data Bag version 3 uses [GCM](http://en.wikipedia.org/wiki/Galois/Counter_Mode) internally. Ruby 2 and OpenSSL version 1.0.1 or higher are required to use it.

### New windows_service resource

The windows_service resource inherits from the service resource and has all the same options but adds an action and attribute.

action :configure_startup - sets the startup type on the resource to the value of the `startup_type` attribute
attribute startup_type - the value as a symbol that the startup type should be set to on the service, valid options :automatic, :manual, :disabled

Note that the service resource will also continue to set the startup type to automatic or disabled, respectively, when the enabled or disabled actions are used.

### Fetch encrypted data bag items with dsl method
DSL method `data_bag_item` now takes an optional String parameter `secret`, which is used to interact with encrypted data bag items.
If the data bag item being fetched is encrypted and no `secret` is provided, Chef looks for a secret at `Chef::Config[:encrypted_data_bag_secret]`.
If `secret` is provided, but the data bag item is not encrypted, then a regular data bag item is returned (no decryption is attempted).

### Encrypted data bag UX
The user can now provide a secret for data bags in 4 ways.  They are, in order of descending preference:
1. Provide the secret on the command line of `knife data bag` and `knife bootstrap` commands with `--secret`
1. Provide the location of a file containing the secret on the command line of `knife data bag` and `knife bootstrap` commands with `--secret-file`
1. Add the secret to your workstation config with `knife[:secret] = ...`
1. Add the location of a file containing the secret to your workstation config with `knife[:secret-file] = ...`

When adding the secret information to your workstation config, it will not be used for writeable operations unless `--encrypt` is also passed on the command line.
Data bag read-only operations (`knife data bag show` and `knife bootstrap`) do not require `--encrypt` to be passed, and will attempt to use an available secret for decryption.
Unencrypted data bags will not attempt to be unencrypted, even if a secret is provided.
Trying to view an encrypted data bag without providing a secret will issue a warning and show the encrypted contents.
Trying to edit or create an encrypted data bag without providing a secret will fail.

Here are some example scenarios:

```
# Providing `knife[:secret_file] = ...` in knife.rb will create and encrypt the data bag
knife data bag create BAG_NAME ITEM_NAME --encrypt

# The same command ran with --secret will use the command line secret instead of the knife.rb secret
knife data bag create ANOTHER_BAG ITEM_NAME --encrypt --secret 'ANOTHER_SECRET'

# The next two commands will fail, because they are using the wrong secret
knife data bag edit BAG_NAME --secret 'ANOTHER_SECRET'
knife data bag edit ANOTHER_BAG --encrypt

# The next command will unencrypt the data and show it using the `knife[:secret_file]` without passing the --encrypt flag
knife data bag show BAG_NAME

# To create an unencrypted data bag, simply do not provide `--secret`, `--secret-file` or `--encrypt`
knife data bag create UNENCRYPTED_BAG

# If a secret is available from any of the 4 possible entries, it will be copied to a bootstrapped node, even if `--encrypt` is not present
knife bootstrap FQDN
```

### Enhanced search functionality: result filtering
#### Use in recipes
`Chef::Search::Query#search` can take an optional `:filter_result` argument which returns search data in the form of the Hash specified. Suppose your data looks like
```json
{"languages": {
  "c": {
    "gcc": {
      "version": "4.6.3",
      "description": "gcc version 4.6.3 (Ubuntu/Linaro 4.6.3-1ubuntu5) "
    }
  },
  "ruby": {
    "platform": "x86_64-linux",
    "version": "1.9.3",
    "release_date": "2013-11-22"
  },
  "perl": {
    "version": "5.14.2",
    "archname": "x86_64-linux-gnu-thread-multi"
  },
  "python": {
    "version": "2.7.3",
    "builddate": "Feb 27 2014, 19:58:35"
  }
}}
```
for a node running Ubuntu named `node01`, and you want to get back only information on which versions of c and ruby you have. In a recipe you would write
```ruby
search(:node, "platform:ubuntu", :filter_result => {"c_version" => ["languages", "c", "gcc", "version"],
                                                    "ruby_version" => ["languages", "ruby", "version"]})
```
and receive
```ruby
[
  {"url" => "https://api.opscode.com/organization/YOUR_ORG/nodes/node01",
   "data" => {"c_version" => "4.6.3", "ruby_version" => "1.9.3"},
  # snip other Ubuntu nodes
]
```
If instead you wanted all the languages data (remember, `"languages"` is only one tiny piece of information the Chef Server stores about your node), you would have `:filter_result => {"languages" => ["laguages"]}` in your search query.

For backwards compatibility, a `partial_search` method has been added to `Chef::Search::Query` which can be used in the same way as the `partial_search` method from the [partial_search cookbook](https://supermarket.getchef.com/cookbooks/partial_search). Note that this method has been deprecated and will be removed in future versions of Chef.

#### Use in knife
Search results can likewise be filtered by adding the `--filter-result` (or `-f`) option. Considering the node data above, you can use `knife search` with filtering to extract the c and ruby versions on your Ubuntu platforms:
```bash
$ knife search node "platform:ubuntu" --filter-result "c_version:languages.c.gcc.version, ruby_version:languages.ruby.version"
1 items found

:
  c_version: 4.6.3
  ruby_version: 1.9.3

$
```
