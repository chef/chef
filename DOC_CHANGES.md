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
