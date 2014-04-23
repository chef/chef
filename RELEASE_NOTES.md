<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# Chef Client Release Notes 11.12.0:

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


#### Unsecure SSL Verification Mode Now Triggers a Warning

When `ssl_verify_mode` is set to `:verify_none`, Chef will print a
warning. Use `knife ssl check` to test SSL connectivity and then add
`ssl_verify_mode :verify_peer` to your configuration file to fix the
warning. Though `:verify_none` is currently the default, this will be
changed in a future release, so users are encouraged to be proactive in
testing and updating their SSL configuration.

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

#### Windows MSI Package Provider

The first windows package provider has been added to core Chef. It supports Windows Installer (MSI) files only,
and maintains idempotency by using the ProductCode from inside the MSI to determine if the products installation state.

```
package "install 7zip" do
  action :install
  source 'c:\downloads\7zip.msi'
end
```

You can continue to use the windows_package LWRP from the windows cookbook alongside this provider.

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

#### Cron Resource

The weekday attribute now accepts the weekday as a symbol, e.g. :monday or :thursday.
There is a new attribute named ```time``` that takes special cron time values as a symbol, such as :reboot or :monthly.

#### `guard_interpreter` attribute

All Chef resources now support the `guard_interpreter` attribute, which
enables you to use a Chef `script` such as `bash`, `powershell_script`,
`perl`, etc., to evaluate the string command passed to a
guard (i.e. `not_if` or `only_if` attribute). This addresses the related ticket
[CHEF-4553](https://tickets.opscode.com/browse/CHEF-4453) which is concerned
with the usability of the `powershell_script` resource, but also benefits
users of resources like `python`, `bash`, etc:

    # See CHEF-4553 -- let powershell_script execute the guard
    powershell_script 'make_logshare' do
      guard_interpreter :powershell_script
      code 'new-smbshare logshare $env:systemdrive\\logs'
      not_if 'get-smbshare logshare'
    end

#### `convert_boolean_return` attribute for `powershell_script`

When set to `true`, the `convert_boolean_return` attribute will allow any script executed by
`powershell_script` that exits with a PowerShell boolean data type to convert
PowerShell boolean `$true` to exit status 0 and `$false` to exit status 1.

The new attribute defaults to `false` except when the `powershell_script` resource is executing script passed to a guard attribute
via the `guard_interpreter` attribute in which case it is `true` by default.

#### knife bootstrap log_level

Running ```knife bootstrap -V -V``` will run the initial chef-client with a log level of debug.

#### knife cookbook test

Knife cookbook test now respects [chefignore files](http://docs.opscode.com/essentials_repository.html#chefignore-files), allowing you to exclude unrelated ruby code such as unit tests.

#### Miscellaneous

* The subversion resource will now mask plaintext passwords in error output.
* The debian pkg provider now supports epochs in the version string.
* When a cookbook upload is missing multiple dependencies, all of them are now listed.
* knife node run_list add now supports a --before option.

#### OHAI 7

After spending 3 months in the RC stage, OHAI 7 is now included in Chef Client 11.10.0. Note that Chef Client 10.32.0 still includes OHAI 6.

For more information about the changes in OHAI 7 please see our previous blog post [here](http://www.getchef.com/blog/2014/01/20/ohai-7-0-release-candidate/).

# Chef Client Breaking Changes:

#### OpenSuse and Suse Differentiation

The Ohai version currently included in Chef reports both SUSE and OpenSUSE platforms as "suse" and the way to differentiate between these two platforms has been to use the version numbers. But since SUSE version numbers have caught up with OpenSUSE, it's not possible to differentiate between these platforms anymore.

This issue is being resolved in Ohai 7 that is included in the current release of Chef Client by reporting these two platforms separately. This resolves the overall problem however it's a breaking change in the sense that OpenSUSE platforms will be reported as "opensuse" as the platform.

Normally Chef would require a major version bump for this change but since the original scenario is currently broken we've decided to include this change without a major version bump in Chef.

If you need to differentiate between OpenSUSE and SUSE in your cookbooks, please make sure the differentiation logic is updated to use the new :platform attribute values rather than the :platform_version in your cookbooks before upgrading to this version.

#### CHEF-5223 OS X Service provider regression.

This commit: https://github.com/opscode/chef/commit/024b1e3e4de523d3c1ebbb42883a2bef3f9f415c
introduced a requirement that a service have a plist file for any
action, but a service that is being created will not have a plist file
yet. Chef now only requires that a service have a plist for the enable
and disable actions.

#### Signal Regression Fix

CHEF-1761 introduced a regression for signal handling when not in daemon mode
(see CHEF-5172). Chef will now, once again, exit immediately on SIGTERM if it
is not in daemon mode, otherwise it will complete it's current run before
existing.

#### Disabling plugins with Ohai 7

Ohai 7 is backwards compatible with Ohai 6 plugins. However the code to disable plugins have changed slightly.

Previously the code to disable plugins:

```
Ohai::Config[:disabled_plugins] = ["passwd","dmi"]
```

should change to

```
Ohai::Config[:disabled_plugins] = [:Passwd,:Dmi]

```

if you want to disable custom Ohai 6 plugins in addition to Ohai 7 plugins you can do:

```
Ohai::Config[:disabled_plugins] = [:Passwd,:Dmi,"my_plugin"]

```
