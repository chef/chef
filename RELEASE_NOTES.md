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
