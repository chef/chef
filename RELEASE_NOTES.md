*This file holds "in progress" release notes for the current release under development and is intended for consumption by the Chef Documentation team.
Please see `https://docs.chef.io/release/<major>-<minor>/release_notes.html` for the official Chef release notes.*

# Chef Client Release Notes 12.11:

## Support for RFC 062-based exit codes

[Chef RFC 062](https://github.com/chef/chef-rfc/blob/master/rfc062-exit-status.md) identifies standard exit codes for Chef Client.  As of this release,  When Chef exits with a non-standard exit code, a deprecation warning will be printed.

Also introduced is a new configuration setting - `exit_status`.  

By default in this release, `exit_status` is `nil` and the default behavior will be to warn on the use of deprecated and non-standard exit codes.  `exit_status` can be set to `:enabled`, which will force chef-client to exit with the RFC defined exit codes and any non-standard exit statuses will be converted to `1` or GENERIC_FAILURE.  `exit_status` can also be set to `:disabled` which preserves the old behavior of non-standardized exit status and skips the deprecation warnings.

## New Data Collector functionality for run statistics

The Data Collector feature is new to Chef 12.11 and is detailed in [Chef RFC 077](https://github.com/chef/chef-rfc/blob/master/rfc077-mode-agnostic-data-collection.md). It provides a unified method for sharing statistics about your Chef runs in a webhook-like manner. The Data Collector supports Chef in all its modes: Chef Client, Chef Solo (commonly referred to as "Chef Client Local Mode"), and Chef Solo legacy mode.

To enable the Data Collector, specify the following settings in your client configuration file:

 * `data_collector.server_url`: Required. The URL to which the Chef Client will POST the Data Collector messages
 * `data_collector.token`: Optional. An token which will be sent in a `x-data-collector-token` HTTP header which can be used to authenticate the message.
 * `data_collector.mode`: The Chef mode in which the Data Collector should run. For example, this allows you to only enable Data Collector in Chef Solo but not Chef Client. Available options are `:solo`, `:client`, or `:both`. Default is `:both`.
 * `data_collector.raise_on_failure`: If enabled, Chef will raise an exception and fail to run if the Data Collector cannot be reached at the start of the Chef run. Defaults to `false`.
 * `data_collector.organization`: Optional. In Solo mode, the `organization` field in the messages will be set to this value. Default is `chef_solo`. This field does not apply to Chef Client mode.

## Replace chef-solo with chef-client local mode

The default operation of `chef-solo` is now the equivalent to `chef-client -z`, but allows for the old style `chef-solo` by uttering `chef-solo --legacy-mode`. As part of this effort, environment and role files written in ruby are now fully supported by `knife upload`.

## Added a `systemd_unit` resource

A new `systemd_unit` resource is now available. This resource supports the following properties:

* `enabled` - boolean
* `active` - boolean
* `masked` - boolean
* `static` - boolean
* `user` - String
* `content` - String or Hash
* `triggers_reload` - boolean

It has these possible actions:

* `:nothing` - default
* `:create`
* `:delete`
* `:enable`
* `:disable`
* `:mask`
* `:unmask`
* `:start`
* `:stop`
* `:restart`
* `:reload`
* `:try_restart`
* `:reload_or_restart`
* `:reload_or_try_restart`
