# Chef Client Release Notes 12.5.0:
* OSX 10.11 support (support for SIP and service changes)

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

