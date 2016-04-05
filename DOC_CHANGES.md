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

### Windows alternate user identity execute support

The `execute` resource and simliar resources such as `script`, `batch`, and `powershell_script`
now support the specification of credentials on Windows so that the resulting process
is created with the security identity that corresponds to those credentials.

#### Properties

The following properties are new or updated for the `execute`, `script`, `batch`, and
`powershell_script` resources and any resources derived from them:

*   `user`</br>
    **Ruby types:** String</br>
    The user name of the user identity with which to launch the new process.
    Default value: `nil`. The user name may optionally be specifed
    with a domain, i.e. `domain\user` or `user@my.dns.domain.com` via Universal Principal Name (UPN)
    format. It can also be specified without a domain simply as `user` if the domain is
    instead specified using the `domain` attribute. On Windows only, if this property is specified, the `password`
    property **must** be specified.

*   `password`</br>
    **Ruby types** String</br>
    *Windows only:* The password of the user specified by the `user` property.
    Default value: `nil`. This property is mandatory if `user` is specified on Windows and may only
    be specified if `user` is specified. The `sensitive` property for this resource will
    automatically be set to `true` if `password` is specified.

*   `domain`</br>
    **Ruby types** String</br>
    *Windows only:* The domain of the user user specified by the `user` property.
    Default value: `nil`. If not specified, the user name and password specified
    by the `user` and `password` properties will be used to resolve
    that user against the domain in which the system running Chef client
    is joined, or if that system is not joined to a domain it will resolve the user
    as a local account on that system. An alternative way to specify the domain is to leave
    this property unspecified and specify the domain as part of the `user` property.

