<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

# Chef Client Doc Changes:

### --validator option for `knife client create`
Boolean value. If set to true, knife creates a validator client o.w. it creates a user client. Default is false.

###  --delete-validators for `knife client delete`
Option that is required to be specified if user is attempting to delete a validator client. No effect while deleting a user client.

###  --delete-validators for `knife client bulk delete`
Option that is required to be specified if user is attempting to delete a validator client. If not specified users cannot delete a client if it's validator client. If specified knife asks users for confirmation of deleting clients and validator clients seperately. Some examples for scripting:

To delete all non-validator clients:
`knife client bulk delete regexp --yes`

To delete all clients including validators:
`knife client bulk delete regexp --delete-validators --yes`

### -r / --runlist option for chef-client
Option similar to `-o` which sets or changes the run_list of a node permanently.

### knife bootstrap -V -V

Running ```knife bootstrap -V -V``` will run the initial chef-client with a log level of debug.

### knife cookbook test

```knife cookbook test``` respects chefignore files when selecting which files to test.

### OHAI 7 Upgrade
Unless there are major issues, 11.12.0 will include OHAI 7. We already have ohai 7 docs in place. We probably need to add some notes to ohai 6 notes that one should now use the newer version when possible.

### New knife command: `knife ssl check [URI]`

The `knife ssl check` command is used to check or troubleshoot SSL
configuration. When run without arguments, it tests whether chef/knife
can verify the Chef server's SSL certificate. Otherwise it connects to
the server specified by the given URL.

Examples:

* Check knife's configuration against the chef-server: `knife ssl check`
* Check chef-client's configuration: `knife ssl check -c /etc/chef/client.rb`
* Check whether an external server's SSL certificate can be verified:
  `knife ssl check https://www.getchef.com`

### New knife command: `knife ssl fetch [URI]`

The `knife ssl fetch` command is used to copy certificates from an HTTPS
server to the `trusted_certs_dir` of knife or `chef-client`. If the
certificates match the hostname of the remote server, this command is
all that is required for knife or chef-client to verify the remote
server in the future. WARNING: `knife` has no way to determine whether
the certificates were tampered with in transit. If that happens,
knife/chef-client will trust potentially forged/malicious certificates
until they are deleted from the `trusted_certs_dir`. Users are *VERY STRONGLY*
encouraged to verify the authenticity of the certificates downloaded
with `knife fetch` by some trustworthy means.

Examples:

* Fetch the chef server's certificates for use with knife:
  `knife ssl fetch`
* Fetch the chef server's certificates for use with chef-client:
  `knife ssl fetch -c /etc/chef/client.rb`
* Fetch the certificates from an arbitrary server:
  `knife ssl fetch https://www.getchef.com`

### OpenSUSE and SUSE differentiation

With the recent change in OHAI to differentiate between SUSE (or SLES - SUSE Enterprise Linux Server) and OpenSUSE we need to update our docs to reflect following (quoting btm):

* Platform SUSE should be changed to OpenSUSE everywhere that it previously meant OpenSUSE but said SUSE.
* Keeping SLES as platform SUSE is still a bit confusing, but that's the least horrible path we chose.
* It's all still very confusing. :)

This page is an example but we probably want to search for `suse` in our doc repo and see if there is anywhere else.

http://docs.opscode.com/dsl_recipe_method_platform_family.html

### Cron Resource

The weekday attribute now accepts the weekday as a symbol, e.g. :monday or :thursday.

The new time attribute takes special time values specified by cron as a symbol, such as :reboot or :monthly.

### SSL Verification Warnings

Chef 11.12 emits verbose warnings when configured to not verify SSL
certificates. Though not verifying certificates is currently the default
setting, this is unsecure and a future release of Chef will change the
default setting so that SSL certificates are verified.

Users are encouraged to resolve these warnings by adding the following
to their configuration files (client.rb or solo.rb):

`ssl_verify_mode :verify_peer`

This setting will check that the certificate presented by HTTPS servers
is signed by a trusted authority. By default, the on-premises Enterprise
Chef and Open Source Chef server use a self-signed certificate that
chef-client will not be able to verify, which will result in SSL errors
when connecting to the server. To check SSL connectivity with the
server, users can use the `knife ssl check` command. If the server is
configured to use an untrusted self-signed certificate, users can
configure chef-client to trust the remote server by copying the server's
certificate to the `trusted_certs_dir`. The `knife ssl fetch` command
can be used to automate this process; however, `knife` is not able to
determine whether certificates downloaded with `knife ssl fetch` have
been tampered with during the download, so users should verify the
authenticity of any certificates downloaded this way.

If a user absolutely cannot enable certificate verification and wishes
to suppress SSL warnings, they can use HTTP instead of HTTPS as a
workaround. This is highly discouraged. If some behavior of Chef
prevents a user from enabling SSL certificate verification, they are
encouraged to file a bug report.

### New Configuration Option: `local_key_generation`

Chef 11.x servers support client-side generation of keys when creating
new clients. Generating the keys on the client provides two benefits: 1)
the private key never travels over the network, which improves security;
2) the CPU load imposed by key creation is moved to the node and
distributed, which allows the server to handle more concurrent client
registrations.

For compatibility reasons, this feature is opt-in, but will likely be
the default or even only behavior in Chef 12.

To enable it, add this to client.rb before running chef-client on a node
for the first time:

```
local_key_generation true
```

The default value of this setting is `false`

*NOTE:* Chef servers that implement the 10.x API do not support this
feature. Enabling this on a client that connects to a 10.X API server
will cause client registration to silently fail. Don't do it.

### Windows Installer (MSI) Package Provider

The windows_package provider installs and removes Windows Installer (MSI) packages.
This provider utilizies the ProductCode extracted from the MSI package to determine
if the package is currently installed.

You may use the ```package``` resource to use this provider, and you must use the
```package``` resource if you are also using the windows cookbook, which contains
the windows_package LWRP.

#### Example

```
package "7zip" do
  action :install
  source 'C:\7z920.msi'
end
```

#### Actions
* :install
* :remove

#### Attributes
* source - The location of the package to install. Default value: the ```name``` of the resource.
* options - Additional options that are passed to msiexec.
* installer_type - The type of package being installed. Can be auto-detected. Currently only :msi is supported.
* timeout - The time in seconds allowed for the package to successfully be installed. Defaults to 600 seconds.
* returns - Return codes that signal a successful installation. Defaults to 0.
