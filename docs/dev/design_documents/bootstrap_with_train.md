# Bootstrap with Train

Update `knife bootstrap` to use `train` as its backend via `chef-core`, and integrate Windows bootstrap support.

## Motivation

    As a Chef User,
    I want to be able to bootstrap a system without logging secure data on that system
    so that chef-client's keys are not exposed to anyone who can read the logs.

    As a Chef User who adminsters Windows nodes,
    I want to be able to bootstrap a system using the core Chef package
    so that I don't have extra things to download first.

    As a Chef Developer who works on bootstrap,
    I want to be able to maintain one copy of the bootstrap logic
    so that I don't have to spend time keeping a second copy in sync.

## Summary

The Windows bootstrap process has lived outside of core Chef for a long time.
Switching to Train as the supporting back-end gives us the opportunity to merge
the `knife-windows` bootstrap behavior into core knife.  This will reduce the maintenance burden
of maintaining what is a mostly-complete copy of bootstrap behaviors in `knife-windows`.

This also addresses [CVE-2015-8559](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-8559), in which
the bootstrap mechanism runs the full bootstrap script as an inline argument to bash/cmd.exe, resulting
in sensitive data potentially getting logged on the remote system.  Train provides a back-end that knows how to
do file management and command execution over supported protocols. This allows us to upload the
bootstrap script and execute it in a remote shell without exposing the contents in a way that could result
in capturing them in system logs.

## Anatomy of a Bootstrap

Bootstrap follows this general flow:

* validate CLI options are proper
* register the new client if not using org validation key to create it
* determine connection properties based on protocol
* connect to the remote host
* generate and upload the bootstrap script
* remotely run the bootstrap script

This change focuses on configuring the connection
and executing the bootstrap script.  The underlying bootstrap behavior itself
remains largely unchanged.

## Implementation

### Remove Unsupported Behaviors

We will also remove the following obsolete or unsupported behaviors:

* `--prelease` flag - Chef hasn't been pre-released in quite some time.
* `--install-as-service` - For many years we have suggested users not run chef-client as a service due to memory leaks in long running Ruby processes.
* `--kerberos-keytab-file` - this is not implemented in the WinRM gem we use, and so was
passed through to no effect.
* remove explicit support for versions of Chef older than 12.8. Versions older than the supported
  Chef client distributions will continue to be use at your own risk.
* Remove support for Windows 2003 in the Windows bootstrap template as Chef does not support EOL Windows 2003 installs.

### CLI Flag Changes

As part of this change, CLI options from `knife bootstrap windows winrm` and `knife bootstrap`
need to be merged.  The majority will be untouched, but we'll also take this opportunity
to make flag names more accurately describe what they're doing, and updating several options that are
protocol-specific to be prefixed with the protocol (e.g. `--ssl-peer-fingerprint` to `--winrm-ssl-peer-fingerprint`)
When a direct mapping exists, the original names will continue to work with backward
compatibility and a deprecation warning if they have changed.

#### New CLI Flags

| Flag | Description |
|-----:|:------------|
| --max-wait SECONDS | Maximum time to wait for initial connection to be established. |
| --winrm-basic-auth-only | Perform only Basic Authentication to the target WinRM node. |
| --connection-protocol PROTOCOL|Connection protocol to use. Valid values are 'winrm' and 'ssh'. Default is 'ssh'. |
| --connection-user | user to authenticate as, regardless of protocol |
| --connection-password| Password to authenticate as, regardless of protocol |
| --connection-port | port to connect to, regardless of protocol |

`--connection-user`, `--connection-port`, and `--connection-password` replace their protocol-specific counterparts, since
these are applicable to all supported transports.  Their original knife config keys (`ssh\_user`, `ssh\_password`, etc.) remain
available for use.

Note that auth-related configuration may see further changes as work proceeds on credential set support for train.

### Changed CLI Flags

| Flag | New Option | Notes |
|-----:|:-----------|:------|
| --[no-]host-key-verify |--[no-]ssh-verify-host-key| |
| --forward-agent | --ssh-forward-agent| |
| --session-timeout MINUTES | --session-timeout SECONDS|New for ssh, existing for winrm. The unit has changed from MINUTES to SECONDS for consistency with other timeouts.|
| --ssh-password | --connection-password | |
| --ssh-port | --connection-port | `knife[:ssh_port]` config setting remains available.
| --ssh-user | --connection-user | `knife[:ssh_user]` config setting remains available.
| --ssl-peer-fingerprint | --winrm-ssl-peer-fingerprint | |
| --winrm-authentication-protocol=PROTO | --winrm-auth-method=AUTH-METHOD | Valid values: plaintext, kerberos, ssl, _negotiate_|
| --winrm-password| --connection-password | |
| --winrm-port| --connection-port | `knife[:winrm_port]` config setting remains available.|
| --winrm-ssl-verify-mode MODE | --winrm-no-verify-cert | [1] Mode is not accepted. When flag is present, SSL cert will not be verified. Same as original mode of 'verify_none'. |
| --winrm-transport TRANSPORT | --winrm-ssl | [1] Use this flag if the target host is accepts WinRM connections over SSL.
| --winrm-user | --connection-user | `knife[:winrm_user]` config setting remains available.|

1. These flags do not have an automatic mapping of old flag -> new flag. The
   new flag must be used.

### Removed Flags

| Flag | Notes |
|-----:|:------|
|--kerberos-keytab-file| This option existed but was not implemented.|
|--winrm-codepage| This was used under `knife-windows` because bootstrapping was performed over a `cmd` shell. It is now invoked from `powershell`, so this option is no longer required.|
|--winrm-shell| This option was ignored for bootstrap.|
|--prerelease|Prerelease Chef hasn't existed for some time.|
|--install-as-service|Installing Chef client as a service is not supported|

### Conversion to ChefCore and Train

CLI and knife options will be mapped to their train counterparts, and passed through to `TargetHost` to establish a connection.
The TargetHost instance will be used for all upload and execution operations.

Tests must ensure that options resolve correctly from the CLI, knife configuration, and defaults; and that they map to the corresponding
`train` options.

#### Validation

Existing windows bootstrap validation checks should be preserved, unless they are superceded by related
validations for ssh bootstrap.

#### Context

`WindowsBootstrapContext` will be moved into knife, with updates for namespacing as needed.

#### Template

`knife-windows/lib/chef/knife/bootstrap/templates/windows-chef-client-msi.erb` will be moved into
knife's bootstrap templates.

### Future Improvements

Because there are only two supported protocols for the near-term future,
it does not add much benefit to split out the bootstrap CLI behavior based on
protocol, so both are handled within the bootstrap command directly.

If we want to support additional protocols, it will become unwieldy to continue with protocol `if`
checks, and would be advisable to separate out protocol-specific behaviors
into classes determined at runtime based on protocol.

