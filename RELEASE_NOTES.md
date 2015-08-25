# Chef Client Release Notes 12.5.0:
* OSX 10.11 support (support for SIP and service changes)

## PSCredential support for the `dsc_script` resource

The `dsc_script` resource now supports the use of the `ps_credential`
helper method. This method generates a Ruby object which can be described
as a Powershell PSCredential object. For example, if you wanted to created
a user using DSC, previously you would have had to do something like:

```ruby
dsc_script 'create-foo-user' do
  code <<-EOH
     $username = "placeholder"
     $password = "#{FooBarBaz1!}" | ConvertTo-SecureString -asPlainText -Force
     $cred = New-Object System.Management.Automation.PSCredential($username, $password)
     User FooUser00
     {
       Ensure = "Present"
       UserName = 'FooUser00'
       Password = $cred
     }
  EOH
  configuration_data_script "path/to/config/data.psd1"
end
```

This can now be replaced with

```ruby
dsc_script 'create-foo-user' do
  code <<-EOH
     User FooUser00
     {
       Ensure = "Present"
       UserName = 'FooUser00'
       Password = #{ps_credential("FooBarBaz1!")}
     }
  EOH
  configuration_data_script "path/to/config/data.psd1"
end
```

## New `knife rehash` for faster command loading

The new `knife rehash` command speeds up day-to-day knife usage by
caching information about installed plugins and available commands.
Initial testing has shown substantial improvements in `knife` startup
times for users with a large number of Gems installed and Windows
users.

To use this feature, simply run `knife rehash` and continue using
`knife`.  When you install or remove gems that provide knife plugins,
run `knife rehash` again to keep the cache up to date.

## Support for `/usr/bin/yum-deprecated` in the yum provider

In Fedora 22 yum has been deprecated in favor of DNF.  Unfortunately, while DNF tries to be backwards
compatible with yum, the yum provider in Chef is not compatible with DNF.  Until a proper `dnf_package`
resource and associated provider is written and merged into core, 12.5.0 has been patched so that the
`yum_package` resource takes a property named `yum_binary` which can be set to point at the yum binary
to run for all its commands.  The `yum_binary` will also default to `yum-deprecated` if the 
`/usr/bin/yum-deprecated` command is found on the system.  This means that Fedora 22 users can run
something like this early in their chef-client run:

```ruby
if File.exist?("/usr/bin/dnf")
  execute "dnf install -y yum" do
    not_if { File.exist?("/usr/bin/yum-deprecated") }
  end
end
```

After which the yum-deprecated binary will exist, and the yum provider will find it and should operate
normally and successfully.

