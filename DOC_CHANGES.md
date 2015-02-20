<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->


### File-like resources now accept a `verify` attribute

The file, template, cookbook_file, and remote_file resources now all
accept a `verify` attribute.  This file accepts a string or a block,
similar to `only_if`.  A full specification can be found in RFC 027:

https://github.com/opscode/chef-rfc/blob/master/rfc027-file-content-verification.md

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

## Add compile_time option to chef_gem

This option defaults to true, which is deprecated, and setting this to false
will stop chef_gem from automatically installing at compile_time.  False is
the recommended setting as long as the gem is only used in provider code (a
best practice) and not used directly in recipe code.

## Yum Package provider now supports version requirements

A documented feature of the yum_package provider was the ability to specify a version requirement such as ` = 1.0.1.el5` in the resource name.
However, this did not actually work. It has now been fixed, and additionally version requirements are now supported in the `version` attribute
of yum_package as well.

## Validatorless bootstraps

Validation keys are now optional.   If the validation key is simply deleted and does not exist, then knife bootstrap will use the
user's key to create a client for the node and create the node object and bootstrap the host.  Validation keys can continue to be
used, particularly for autoscaling, but even for that use case a dedicated user for autoscaling would be preferable to the shared
validation key.

## Bootstrap will create chef-vault items

The --bootstrap-vault-item, --bootstrap-vault-json, and --bootstrap-vault-file arguments have been added to knife bootstrap providing
three alternative ways to set chef vault items when bootstrapping a host.
