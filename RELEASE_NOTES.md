<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# Chef Client Release Notes:

#### `knife ssl check` and `knife ssl fetch` Commands

As part of our process to transition to verifying SSL certificates by
default, we've added knife commands to help you test (and fix, if
needed) your SSL configuration.

`knife ssl check` makes an SSL connection to your Chef server or any
other HTTPS server and tells you if the server presents a valid
certificate. If the certificate is not valid, knife will give further
information about the cause and some instructions on how to remedy the
issue. For example, if your Chef server uses an untrusted self-signed
certificate:

```
ERROR: The SSL certificate of chefserver.test could not be
verified
Certificate issuer data:
/C=US/ST=WA/L=Seattle/O=YouCorp/OU=Operations/CN=chefserver.test/emailAddress=you@example.com

Configuration Info:

OpenSSL Configuration:
* Version: OpenSSL 1.0.1e 11 Feb 2013
* Certificate file: /usr/local/etc/openssl/cert.pem
* Certificate directory: /usr/local/etc/openssl/certs
Chef SSL Configuration:
* ssl_ca_path: nil
* ssl_ca_file: nil
* trusted_certs_dir: "/Users/ddeleo/.chef/trusted_certs"

TO FIX THIS ERROR:

If the server you are connecting to uses a self-signed certificate, you
must
configure chef to trust that server's certificate.

By default, the certificate is stored in the following location on the
host
where your chef-server runs:

  /var/opt/chef-server/nginx/ca/SERVER_HOSTNAME.crt

Copy that file to you trusted_certs_dir (currently: /home/user/.chef/trusted_certs)
using SSH/SCP or some other secure method, then re-run this command to confirm
that the server's certificate is now trusted.
```

`knife ssl fetch` allows you to automatically fetch a server's
certificates to your trusted certs directory. This provides an easy way
to configure chef to trust your self-signed certificates. Note that
knife cannot verify that the certificates haven't been tampered with, so
you should verify their content after downloading.


#### Chef Solo Missing Dependency Warning ([CHEF-4367](https://tickets.opscode.com/browse/CHEF-4367))

Chef 11.0 introduced ordered evaluation of non-recipe files in
cookbooks, based on the dependencies specified in your cookbooks'
metadata. This was a huge improvement on the previous behavior for all
chef users, but it also introduced a problem for chef-solo users:
because of the way chef-solo works, it was possible to use
`include_recipe` to load a recipe from a cookbook without specifying the
dependency in the metadata. This would load the recipe without having
evaluated the associated attributes, libraries, LWRPs, etc. in that
recipe's cookbook, and the recipe would fail to load with errors that
did not suggest the actual cause of the failure.

We've added a check to `include_recipe` so that attempting to include a
recipe which is not a dependency of any cookbook specified in the run
list will now log a warning with a message describing the problem and
solution. In the future, this warning will become an error.

#### reboot_pending?  

We have added a ```reboot_pending?``` method to the recipe DSL. This method returns true or false if the operating system
has a rebooting pending due to updates and a reboot being necessary to complete the installation. It does not report if a reboot has been requested, e.g. if someone has scheduled a restart using shutdown. It currently supports Windows and Ubuntu Linux.

```
Chef::Log.warn "There is a pending reboot, which will affect this Chef run" if reboot_pending?

execute "Install Application" do
  command 'C:\application\setup.exe'
  not_if { reboot_pending? }
end
```

#### FileEdit

Chef::Util::FileEdit has been refactored into a Chef::Util::Editor class. The existing class continues to manage the files being edited while the new class handles the actual modification of the data.
Along with this refactor, #insert_line_if_no_match can now manipulate a file multiple times. FileEdit also now has a #file_edited? method that can be used to tell if changes were made to the file on disk.

#### DeepMerge sub-hash precedence bugfix ([CHEF-4918](https://tickets.opscode.com/browse/CHEF-4918))

We discovered a bug where Chef incorrectly merged override attribute sub-hashes that were at least three levels deep as normal attributes. 
This has been corrected, and is not expected to cause any behavior change
If you're an advanced user of attribute precedence, you may find some attributes were saved to your node object that you hadn't expected.

#### Miscellaneous

* The subversion resource will now mask plaintext passwords in error output.
* The debian pkg provider now supports epochs in the version string.
* When a cookbook upload is missing multiple dependencies, all of them are now listed.
* knife node run_list add now supports a --before option.

#### OHAI 7

After spending 3 months in the RC stage, OHAI 7 is now included in Chef Client 11.10.0. Note that Chef Client 10.32.0 still includes OHAI 6.

For more information about the changes in OHAI 7 please see our previous blog post [here](http://www.getchef.com/blog/2014/01/20/ohai-7-0-release-candidate/).

# Chef Client Breaking Changes:

None.
