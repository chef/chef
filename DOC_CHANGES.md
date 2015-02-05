<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

### Chef now handles URI Schemes in a case insensitive manner

Previously, when a URI scheme contained all uppercase letters, Chef would reject the URI as invalid. In compliance with RFC3986, Chef now treats URI schemes in a case insensitive manner. This applies to all resources which accept URIs such as remote_file etc.

### Experimental Audit Mode Feature

There is a new command_line flag provided for `chef-client`: `--audit-mode`.  This accepts 1 of 3 arguments:

* `disabled` (default) - Audits are disabled and the phase is skipped.  This is the default while Audit mode is an
experimental feature.
* `enabled` - Audits are enabled and will be performed after the converge phase.
* `audit-only` - Audits are enabled and convergence is disabled.  Only audits will be performed.

This can also be configured in your node's client.rb with the key `audit_mode` and a value of `:disabled`, `:enabled` or `:audit_only`.

### Chef Why Run Mode Ignores Audit Phase

Because most users enable `why_run` mode to determine what resources convergence will update on their system, the audit
phase is not executed.  There is no way to get both `why_run` output and audit output in 1 single command.  To get
audit output without performing convergence use the `--audit-mode` flag.

#### Editors note 1

The `--audit-mode` flag should be a link to the documentation for that flag

#### Editors node 2

This probably only needs to be a bullet point added to http://docs.getchef.com/nodes.html#about-why-run-mode under the
`certain assumptions` section

## Drop SSL Warnings
Now that the default for SSL checking is on, no more warning is emitted when SSL
checking is off.

## Multi-package Support
The `package` provider has been extended to support multiple packages. This
support is new and and not all subproviders yet support it. Full support for
`apt` and `yum` has been implemented.
