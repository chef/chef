# Chef Client Release Notes <unreleased>:

## Knife Key Management Commands for Users and Clients

`knife user` and `knife client` now have a suite of subcommands that live under
the `key` subcommand. These subcommands allow you to list, show, create, delete
and edit keys for a given user or client. They can be used to implement
key rotation with multiple expiring keys for a single actor or just
for basic key management. See `knife user key` and `knife client key`
for a full list of subcommands and their usage.

## System Loggers

### Windows Event Logger

You can now have all Chef logs sent to the Windows Event Logger. The logger can be
used by adding the following line to your chef config file:

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
