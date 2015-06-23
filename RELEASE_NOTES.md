# Chef Client Release Notes 12.4.0:

## Knife Key Management Commands for Users and Clients

`knife user` and `knife client` now have a suite of subcommands that live under
the `key` subcommand. These subcommands allow you to list, show, create, delete
and edit keys for a given user or client. They can be used to implement
key rotation with multiple expiring keys for a single actor or just
for basic key management. See `knife user key` and `knife client key`
for a full list of subcommands and their usage.

## System Loggers

You can now have all Chef logs sent to a logging system of your choice.

### Syslog Logger

Syslog can be used by adding the following line to your chef config
file:

```ruby
log_location Chef::Log::Syslog.new("chef-client", ::Syslog::LOG_DAEMON)
```

THis will write to the `daemon` facility with the originator set as
`chef-client`.

### Windows Event Logger

The logger can be used by adding the following line to your chef config file:

```ruby
log_location Chef::Log::WinEvt.new
```

This will write to the Application log with the source set as Chef.

## RemoteFile resource supports UNC paths on Windows

You can now use UNC paths with `remote_file` on Windows machines. For
example, you can get `Foo.tar.gz` off of `fooshare` on `foohost` using
the following resource:

```ruby
remote_file 'C:\Foo.tar.gz' do
  source "\\\\foohost\\fooshare\\Foo.tar.gz"
end
```

## WindowsPackage resource supports URLs

The `windows_package` resource now allows specifying URLs for the source
attribute. For example, you could install 7zip with the following resource:

```ruby
windows_package '7zip' do
  source "http://www.7-zip.org/a/7z938-x64.msi"
end
```

Internally, this is done by using a `remote_file` resource to download the
contents at the specified url. If needed, you can modify the attributes of
the `remote_file` resource using the `remote_file_attributes` attribute. 
The `remote_file_attributes` accepts a hash of attributes that will be set
on the underlying remote_file. For example, the checksum of the contents can 
be verified using

```ruby
windows_package '7zip' do
  source "http://www.7-zip.org/a/7z938-x64.msi"
  remote_file_attributes {
    :path => "C:\\7zip.msi",
    :checksum => '7c8e873991c82ad9cfcdbdf45254ea6101e9a645e12977dcd518979e50fdedf3'
  }
end
```

To make the transition easier from the Windows cookbook, `windows_package` also 
accepts the `checksum` attribute, and the previous resource could be rewritten
as:

```ruby
windows_package '7zip' do
  source "http://www.7-zip.org/a/7z938-x64.msi"
  checksum '7c8e873991c82ad9cfcdbdf45254ea6101e9a645e12977dcd518979e50fdedf3'
end
```

## Powershell wrappers for command line tools

There is now an optional feature in the msi that you can enable during the
installation of Chef client that deploys a powershell module alongside the rest
of your installation (usually at `C:\opscode\chef\modules\`).  This location
will also be appended to your `PSModulePath` environment variable.  Since this
feature is experimental, it is not automatically enabled.  You may activate it
by running the following from any powershell session
```powershell
Import-Module chef
```
You can also add the above to your powershell profile at 
`~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`

The module exports a number of cmdlets that have the same name as the Chef
command line utilities that you already use - such as `chef-client`, `knife`
and `chef-apply`.  What they provide is the ability to cleanly pass quoted
argument strings from your powershell command line without the need for excessive
double-quoting.  See https://github.com/chef/chef/issues/3026 or 
https://github.com/chef/chef/issues/1687 for an examples.

Previously you would have needed
```powershell
knife exec -E 'puts ARGV' """&s0meth1ng"""
knife node run_list set test-node '''role[ssssssomething]'''
```

Now you only need
```powershell
knife exec -E 'puts ARGV' '&s0meth1ng'
knife node run_list set test-node 'role[ssssssomething]'
```

If you wish to no longer use the wrappers, run
```powershell
Remove-Module chef
```
