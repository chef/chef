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

### `knife ssl check` will verify X509 properties of your trusted certificates

When you run `knife ssl check URL (options)` knife will verify if the certificate files, with extensions `*.crt` and `*.pem`
in your `:trusted_certs_dir` have valid X509 certificate properties. Knife will generate warnings for certificates that
do not meet X509 standards. OpenSSL **will not** use these certificates in verifying SSL connections.

#### Troubleshooting

For each certificate that does not meet X509 specifications, a message will be displayed indicating why the certificate
failed to meet these specifications. You may see output similar to

```
There are invalid certificates in your trusted_certs_dir.
OpenSSL will not use the following certificates when verifying SSL connections:

/path/to/your/invalid/certificate.crt: a message to help you debug
```

The documentation for resolving common issues with certificates is a work in progress. A few suggestions
are outlined in the following sections. If you would like to help expand this documentation, please
submit a pull request to [chef-docs](https://github.com/opscode/chef-docs) with your contribution.

##### Fetch the certificate again

If the certificate was generated by your chef server, you may want to try downloading the certificate again.
By default, the certificate is stored in the following location on the host where your chef-server runs:
`/var/opt/chef-server/nginx/ca/SERVER_HOSTNAME.crt`. Copy that file into your `:trusted_certs_dir` using SSH,
SCP, or some other secure method and run `knife ssl check URL (options)` again.

##### Generate a new certificate

You will need a 1024 bit RSA key. You can generate one using the `openssl` cli tool:
```
openssl genrsa -des3 -out privkey.key 1024
```
You will be prompted for a passphrase for your new private key.

Once you have private key, you can generate a Certificate Signing Request (CSR), which can either be sent to a
Certificate Authority (CA) for verification, or be self-signed. You can generate a CSR with
```
openssl req -new -key privkey.key -out mycsr.csr
```
When you create a CSR, you will be prompted for
information which is used to fill out the X509 attributes of the certificate. You will be asked to provide
a two-letter [Country Name](https://www.digicert.com/ssl-certificate-country-codes.htm), and a Common Name
which should be the FQDN of your server to be protected by SSL.

(Optional) You may want to remove the passphrase from the key, otherwise you will be prompted to
type in the passphrase after system reboot or crash. It is recommended that you make this key
readable only by root once you remove the passphrase.
```
cp privkey.key privkey.key.org
openssl rsa -in privkey.key.org -out privkey.key
```

(Optional) You can generate a self-signed certificate if you don't plan on having your certificate
signed by a CA, or as an interim certificate for testing while you wait for the CA to sign your
certificate. You can create a temporary certificate good for 365 days with the command
```
openssl x509 -req -days 365 -in mycsr.csr -signkey privkey.key -out mycert.crt
```

##### Generate a certificate with SubjectAltName

You will need an openssl configuration file which enables subject alternative names. This is usually
saved in your system as `openssl.cnf`, but you can create and use an alternative configuration file
if you find that easier. If you use an alternative configuration file, you will have to append the
command line option `-config CONFIG_FILE` to the commands shown below.

The `[req]` section of your configuration file tells openssl how to handle certificate requests (CSRs). There
should be a line beginning with `req_extensions`. This section of your configuration file should look like
```
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
```
`v3_req` tells openssl to include that section in CSRs. You should modify your `v3_req` section to include
`subjectAltName`. Your configuration file may look something like
```
[ v3_req ]
# Extensions to add to a certificate request
basicConstraints = CA:FALSE
subjectAltName = @alt_names

[alt_names]
DNS.1 = kb.example.com
DNS.2 = helpdesk.example.org
DNS.3 = systems.example.net
IP.1 = 192.168.1.1
IP.2 = 192.168.69.14
```
It is important to note that what gets entered here will appear on all CSRs generated from this point on. If you want to change
the SANs you will have to manually edit this file again.

Now you can follow the steps for generating a new certificate. Don't forget to append the `-config CONFIG_FILE` option
if your configuration file is not the default `openssl.cnf`
