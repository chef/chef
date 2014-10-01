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

## Client and solo application changes

### Unforked interval chef-client runs are disabled
Unforked interval and daemonized chef-client runs are now explicitly prohibited. Runs configured with CLI options
`--interval SEC` or `--daemonize` paired with `--no-fork`, or the equivalent config options paired with
`client_fork false` will fail immediately with error.

### Sleep happens before converge
When configured to splay sleep or run at intervals, `chef-client` and `chef-solo` perform both splay and interval
sleeps before converging. In previous releases, chef would splay sleep then converge then interval sleep.

### Signal handling
When sent `SIGTERM` the thread or process will:
1. if chef is not converging, exit immediately with exitstatus 3 or
1. allow chef to finish converging then exit immediately with the converge's exitstatus.

To terminate immediately, send `SIGINT`.

# `knife ssl check` will verify X509 properties of your trusted certificates

When you run `knife ssl check URL (options)` knife will verify if the certificate files, with extensions `*.crt` and `*.pem`
in your `:trusted_certs_dir` have valid X509 certificate properties. Knife will generate warnings for certificates that
do not meet X509 standards. OpenSSL **will not** use these certificates in verifying SSL connections.

## Troubleshooting
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

### Fetch the certificate again
If the certificate was generated by your chef server, you may want to try downloading the certificate again.
By default, the certificate is stored in the following location on the host where your chef-server runs:
`/var/opt/chef-server/nginx/ca/SERVER_HOSTNAME.crt`. Copy that file into your `:trusted_certs_dir` using SSH,
SCP, or some other secure method and run `knife ssl check URL (options)` again.

### Generate a new certificate
If you control the trusted certificate and you suspect it is bad (e.g., you've fetched the certificate again,
but you're still getting warnings about it from `knife ssl check`), you might try generating a new certificate.

#### Generate a certificate signing request
If you used a certificate authority (CA) to authenticate your certificate, you'll need to generate
a certificate signing request (CSR) to fetch a new certificate.

If you don't have one already, you'll need to create an openssl configuration file. This example
configuration file is saved in our current working directory as openssl.cnf

```
#
# OpenSSL configuration file
# ./openssl.cnf
#

[ req ]
default_bits       = 1024       # Size of keys
default_keyfile    = key.pem    # name of generated keys
default_md         = md5        # message digest algorithm
string_mask        = nombstr    # permitted characters
distinguished_name = req_distinguished_name
req_extensions     = v3_req

[ req_distinguished_name ]
# Variable name          Prompt string
#---------------------   ----------------------------------
0.organizationName     = Organization Name (company)
organizationalUnitName = Organizational Unit Name (department, division)
emailAddress           = Email Address
emailAddress_max       = 40
localityName           = Locality Name (city, district)
stateOrProvinceName    = State or Province Name (full name)
countryName            = Country Name (2 letter code)
countryName_min        = 2
countryName_max        = 2
commonName             = Common Name (hostname, IP, or your name)
commonName_max         = 64

# Default values for the above, for consistency and less typing.
# Variable name               Value
#--------------------------   ------------------------------
0.organizationName_default  = My Company
localityName_default        = My Town
stateOrProvinceName_default = State or Providence
countryName_default         = US

[ v3_req ]
basicConstraints     = CA:FALSE   # This is NOT a CA certificate
subjectKeyIdentifier = hash
```

You can use `openssl` to create a certificate from an existing private key
```
$ openssl req -new -extensions v3_req -key KEYNAME.pem -out REQNAME.pem -config ./openssl.cnf
```
or `openssl` can create a new private key simultaneously
```
$ openssl req -new -extensions v3_req -keyout KEYNAME.pem -out REQNAME.pem -config ./openssl.cnf
```
where `KEYNAME` is the path to your private key and `REQNAME` is the path to your CSR.

You can verify your CSR was generated correctly
```
$ openssl req -noout -text -in REQNAME.pem
```

The final step is to submit your CSR to your certificate authority (CA) for signing.

### Generate a self-signed (root) certificate
You'll need to modify your openssl configuration file, or create a separate file, for
generating root certificates.

```
#
# OpenSSL configuration file
# ./openssl.cnf
#

dir = .

[ ca ]
default_ca = CA_default

[ CA_default ]
serial        = $dir/serial
database      = $dir/certindex.txt
new_certs_dir = $dir/certs
certificate   = $dir/cacert.pem
private_key   = $dir/private/cakey.pem
default_days  = 365
default_md    = md5
preserve      = no
email_in_dn   = no
nameopt       = default_ca
certopt       = default_ca
policy        = policy_match

[ policy_match ]
countryName            = match
stateOrProvinceName    = match
organizationName       = match
organizationalUnitName = optional
commonName             = supplied
emailAddress           = optional

[ v3_ca ]
basicConstraints       = CA:TRUE   # This is a CA certificate
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer:always
```

You can now create a root certificate. If you have a private key you would like
to use
```
$ openssl req -new -x509 -extensions v3_ca -key KEYNAME.pem -out CERTNAME.pem -config ./openssl.cnf
```
or `openssl` can create a new private key simultaneously
```
$ openssl req -new -x509 -extensions v3_ca -keyout KEYNAME.pem -out CERTNAME.pem -config ./openssl.cnf
```
where `KEYNAME` is the path to your private key and `REQNAME` is the path to your CSR.

At this point, you should add the generated certificate to your trusted certificates as well as
replace the old server certificate. Furthermore, you should regenerate any certificates that
were signed by the previous root certificate.

For more information and an example on how to set up your server to generate certificates
check out this post on [setting up OpenSSL to create certificates](http://www.flatmtn.com/article/setting-openssl-create-certificates).

#### Signing certificates
Use your root certificate to sign certificate requests sent to your server
```
$ openssl ca -out CERTNAME.pem -config ./openssl.cnf -infiles REQNAME.pem
```
This creates the certificate `CERTNAME.pem` generated from CSR `REQNAME.pem`. You
should send `CERTNAME.pem` back to the client who generated the CSR.

### Certificate attributes
When creating certificates and certificate signing requests, you will be prompted for
information via the command line. These are your certificate attributes.

RDN | Name | Explanation | Examples
:---: | :---: | --- | ---
CN | Common Name | You server's FQDN, or YOUR_SERVER Certificate Authority if root certificate | mail.domain.com, *.domain.com, MyServer Certificate Authority
OU | Organizational Unit | (Optional) Additional organization information. | mail server, R&D
O | Organization | The exact name of your organization. Do not abbreviate. | DevOpsRUs Inc.
L | Locality | The city where your organization is located | Seattle
S | State or Province | The state or province where your organization is located. Do not abbreviate. | Washington
C | Country Name | 2-letter ISO abbreviation for your country. | US
 | Email Address | How you or another maintainer can be reached. | maintainers@devopsr.us

If you examine the `policy_match` section in the openssl configuration file example from the section on generating
self signed certificates, you'll see specifications that CSRs need to match the countryName, stateOrProvinceName,
and the organizationName. CSRs whose CN, S, and O values do not match those of the root certificate will not be
signed by that root certificate. You can modify these requirements as desired.

### Key usage
A keyUsage field can be added to your `v3_req` and `v3_ca` sections of your configuration file.
Key usage extensions define the purpose of the public key contained in a certificate, limiting what
it can and cannot be used for.

Extension | Description
--- | ---
digitalSignature | Use when the public key is used with a digital signature mechanism to support security services other than non-repudiation, certificate signing, or CRL signing. A digital signature is often used for entity authentication and data origin authentication with integrity
nonRepudiation | Use when the public key is used to verify digital signatures used to provide a non-repudiation service. Non-repudiation protects against the signing entity falsely denying some action (excluding certificate or CRL signing).
keyEncipherment | Use when a certificate will be used with a protocol that encrypts keys.
dataEncipherment | Use when the public key is used for encrypting user data, other than cryptographic keys.
keyAgreement | Use when the sender and receiver of the public key need to derive the key without using encryption. This key can then can be used to encrypt messages between the sender and receiver. Key agreement is typically used with Diffie-Hellman ciphers.
certificateSigning | Use when the subject public key is used to verify a signature on certificates. This extension can be used only in CA certificates.
cRLSigning | Use when the subject public key is to verify a signature on revocation information, such as a CRL.
encipherOnly | Use only when key agreement is also enabled. This enables the public key to be used only for enciphering data while performing key agreement.
decipherOnly | Use only when key agreement is also enabled. This enables the public key to be used only for deciphering data while performing key agreement.
[Source](http://www-01.ibm.com/support/knowledgecenter/SSKTMJ_8.0.1/com.ibm.help.domino.admin.doc/DOC/H_KEY_USAGE_EXTENSIONS_FOR_INTERNET_CERTIFICATES_1521_OVER.html)

### Subject Alternative Names
Subject alternative names (SANs) allow you to list host names to protect with a single certificate.
To create a certificate using SANs, you'll need to add a `subjectAltName` field to your `v3_req` section
in your openssl configuration file

```
[ v3_req ]
basicConstraints     = CA:FALSE   # This is NOT a CA certificate
subjectKeyIdentifier = hash
subjectAltName       = @alt_names

[alt_names]
DNS.1 = kb.example.com
DNS.2 = helpdesk.example.org
DNS.3 = systems.example.net
IP.1  = 192.168.1.1
IP.2  = 192.168.69.14
```

### Reboot resource in core
The `reboot` resource will reboot the server, a necessary step in some installations, especially on Windows. If this resource is used with notifications, it must receive explicit `:immediate` notifications only: results of delayed notifications are undefined. Currently supported on Windows, Linux, and OS X; will work incidentally on some other Unixes.

There are three actions:

```ruby
reboot "app_requires_reboot" do
  action :request_reboot
  reason "Need to reboot when the run completes successfully."
  delay_mins 5
end

reboot "cancel_reboot_request" do
  action :cancel
  reason "Cancel a previous end-of-run reboot request."
end

reboot "now" do
  action :reboot_now
  reason "Cannot continue Chef run without a reboot."
  delay_mins 2
end

# the `:immediate` is required for results to be defined.
notifies :reboot_now, "reboot[now]", :immediate
```

### Escape sensitive characters before globbing
Some paths contain characters reserved by glob and must be escaped so that
glob operations perform as expected. One common example is Windows file paths
separated by `"\\"`. To ensure that your globs work correctly, it is recommended
that you apply `Chef::Util::PathHelper::escape_glob` before globbing file paths.

```ruby
path = "C:\\Users\\me\\chef-repo\\cookbooks"
Dir.exist?(path) # true
Dir.entries(path) # [".", "..", "apache2", "apt", ...]

Dir.glob(File.join(path, "*")) # []
Dir[File.join(path, "*")] # []

PathHelper = Chef::Util::PathHelper
Dir.glob(File.join(PathHelper.escape_glob(path), "*")) # ["#{path}\\apache2", "#{path}\\apt", ...]
Dir[PathHelper.escape_glob(path) + "/*"] # ["#{path}\\apache2", "#{path}\\apt", ...]
```
