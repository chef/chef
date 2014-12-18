<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

### Experimental Audit Mode Feature

There is a new command_line flag provided for `chef-client`: `--audit-mode`.  This accepts 1 of 3 arguments:

* disabled (default) - Audits are disabled and the phase is skipped.  This is the default while Audit mode is an
experimental feature.
* enabled - Audits are enabled and will be performed after the converge phase.
* audit_only - Audits are enabled and convergence is disabled.  Only audits will be performed.

### Chef Why Run Mode Ignores Audit Phase

Because most users enable `why_run` mode to determine what resources convergence will update on their system, the audit
phase is not executed.  There is no way to get both `why_run` output and audit output in 1 single command.  To get
audit output without performing convergence use the `--audit-mode` flag.

#### Editors note 1

The `--audit-mode` flag should be a link to the documentation for that flag

#### Editors node 2

This probably only needs to be a bullet point added to http://docs.getchef.com/nodes.html#about-why-run-mode under the
`certain assumptions` section
