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

### Windows `remote_file` resource with alternate credentials

The `remote_file` resource now supports the use of credentials on Windows when accessing
a remote UNC path on Windows such as `\\myserver\myshare\mydirectory\myfile.txt`. This
allows access to the file at that path location  even if the Chef client process identity does
not have permission to access the file. The new properties `remote_user`,
`remote_domain`, and `remote_user_password` may be used to specify credentials
with access to the remote file so that it may be read.

#### Properties

The following properties are new for the `remote_file` resource:

*   `remote_user`</br>
    **Ruby types:** String</br>
    *Windows only:* The user name of a user with access to the remote file specified
    by the `source` property. Default value: `nil`. The user name may optionally be specifed
    with a domain, i.e. `domain\user` or `user@my.dns.domain.com` via Universal Principal Name (UPN)
    format. It can also be specified without a domain simply as `user` if the domain is
    instead specified using the `remote_user_domain` attribute. Note that this property is ignored
    if `source` is not a UNC path. If this property is specified, the `remote_user_password`
    property **must** be specified.

*   `remote_user_password`</br>
    **Ruby types** String</br>
    *Windows only:* The password of the user specified by the `remote_user` property.
    Default value: `nil`. This property is mandatory if `remote_user` is specified and may only
    be specified if `remote_user` is specified. The `sensitive` property for this resource will
    automatically be set to `true` if `remote_user_password` is specified.

*   `remote_user_domain`</br>
    **Ruby types** String</br>
    *Windows only:* The domain of the user user specified by the `remote_user` property.
    Default value: `nil`. If not specified, the user and password properties specified
    by the `remote_user` and `remote_user_password` properties will be used to authenticate
    that user against the domain in which the system hosting the UNC path specified via `source`
    is joined, or if that system is not joined to a domain it will authenticate the user
    as a local account on that system. An alternative way to specify the domain is to leave
    this property unspecified and specify the domain as part of the `remote_user` property.

