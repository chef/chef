<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

## Doc changes for Chef 12.11

### RFC 062 Exit Status Support

Starting with Chef Client 12.11, there is support for the consistent, standard exit codes as defined in [Chef RFC 062](https://github.com/chef/chef-rfc/blob/master/rfc062-exit-status.md).

With no additional configuration when Chef Client exits with a non-standard exit code a deprecation warning will be issued advising users of the upcoming change in behavior.

To enable the standardized exit code behavior, there is a new setting in client.rb.  The `exit_status` setting, when set to `:enabled` will enforce standarized exit codes.  In a future release, this will become the default behavior.

If you need to maintain the previous exit code behavior to support your current workflow, you can disable this (and the deprecation warnings) by setting `exit_status` to `:disabled`.

