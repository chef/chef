# License Acceptance

Starting with Chef Client 15 users are required to accept the [Chef
EULA](https://www.chef.io/end-user-license-agreement/) to use the Chef Software distribution. This document aims to
explain how the `license-acceptance` gem and the `chef` gem interact.

The overall goal is that the license acceptance flow is invoked as early as possible in the binary (EG, `chef-client`)
execution. Failure to accept the license causes the binary to immediately exit with code `172`.

For an explanation of how this is achieved please see the [Ruby
README](https://github.com/chef/license-acceptance/tree/master/components/ruby) in the license-acceptance repo. For an
overall view of how the license-acceptance gem works, its specification, how marker files are stored, etc. please see
the [repo README](https://github.com/chef/license-acceptance).
