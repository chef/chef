*This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team.
Please see `https://docs.chef.io/release/<major>-<minor>/release_notes.html` for the official Chef release notes.*

# Chef Client Release Notes 12.11:

## Support for RFC 062-based exit codes

[Chef RFC 062](https://github.com/chef/chef-rfc/blob/master/rfc062-exit-status.md) identifies standard exit codes for Chef Client.  As of this release,  When Chef exits with a non-standard exit code, a deprecation warning will be printed.

Also introduced is a new configuration setting - `exit_status`.  

By default in this release, `exit_status` is `nil` and the default behavior will be to warn on the use of deprecated and non-standard exit codes.  `exit_status` can be set to `:enabled`, which will force chef-client to exit with then RFC defined exit codes and any non-standard exit statuses will be converted to `1` or GENERIC_FAILURE.  `exit_status` can also be set to `:disabled` which preserves the old behavior of non-standardized exit status and skips the deprecation warnings.
