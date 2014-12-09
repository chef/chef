<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

### Chef Why Run Mode Ignores Audit Phase

Because most users enable `why_run` mode to determine what resources convergence will update on their system, the audit
phase is not executed.  There is no way to get both `why_run` output and audit output in 1 single command.  To get
audit output without performing convergence use the `--audit-mode` flag.

#### Editors note 1

The `--audit-mode` flag should be a link to the documentation for that flag

#### Editors node 2

This probably only needs to be a bullet point added to http://docs.getchef.com/nodes.html#about-why-run-mode under the
`certain assumptions` section
