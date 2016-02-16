# Chef Client Release Notes 12.8:

# Chef Client Release Notes 12.7:

## Updates to versioning strategy

We recently updated the [versioning specification](https://github.com/chef/chef-rfc/pull/175) in our [release process](https://github.com/chef/chef-rfc/commits/master/rfc047-release-process.md) to facilitate faster releases with lower risk between each release.  Soon an automated process will begin updating the "patch" version (the third number in the version).

For consumers of Chef this means that the first release of 12.7 you use may be 12.7.2 or 12.7.5 without earlier versions of 12.7 having been released first.  Those earlier versions may be available in the _current_ channel that you can access through the install.sh and install.ps1 scripts.

## Net-ssh updates

We updated the version of [net-ssh](https://github.com/net-ssh/net-ssh) in Chef from version 2.9 to 3.0 to take in an upstream bug fix.  The biggest change here is that they dropped support for Ruby 1.9 (which Chef already dropped support for).  Because this is such a low level dependency we found that many other projects had to be updated in lock-step (like Test Kitchen and Berkshelf) for the ChefDK packaging to succeed without dependency conflicts.

## Zypper Package Multipackage Support

On SuSE systems the `package` provider (aka `zypper_package` provider) now accepts arrays and will install them with a single zypper command together:

```ruby
package [ 'git', 'nmap' ]
```

Some additional code-cleanup was done to the provider and long-standing bugs may have been fixed.

## Chocolatey Package Provider

There is now a `chocolatey_package` provider in core chef.  It is named `chocolatey_package` instead of `chocolatey` in order to not conflict with the existing resource in the chocolatey cookbook and to
comply with existing naming standards for package resources in core chef.

The API for `chocolatey_package` conforms to the `package` API in core chef, rather than being a straight port of the cookbook version, and there are some API differences (e.g. it favors the `:remove`
action over the `:uninstall` action since that is the API standard for core chef package providers).  The `chocolatey_package` provider also supports multipackage installations and will execute them
in a single statement where possible:

```ruby
chocolatey_package [ 'googlechrome', 'flashplayerplugin', '7zip', 'git' ]
```

The `choco.exe` binary must be installed prior to using the resource, so the chocolatey cookbook recipe should still be used to install it.

## EMEA Customers and UTF-8 Support

EMEA customers in particular, and those customers who need reliable UTF-8 support, are highly encouraged to upgrade to the 12.7.0 release.  The 12.4.x/12.5.x/12.6.x releases of chef-client had an
extremely bad UTF-8 handling bug in them which corrupted all UTF-8 data in the node.  In 12.7.0 that bug was fixed, along with another fix to make resource and audit reporting more reliable when fed
non-UTF-8 (e.g. Latin-1/ISO-8859-1) characters.

## Chef Solo -r (--recipe-url) changes

The use of the `-r` option to chef-client result in setting the `--run-list`:

```
chef-client -r 'role[foo]'
```

Passing the same argument to chef-solo:

```
chef-solo -r 'role[foo]'
```

Instead invokes the `--recipe-url` code, which had the side effect of running an immediate unprompted `rm -rf *` in the current working directory of the user.   Due to this problem and other issues
around this `rm -rf *` behavior it has been removed from the `--recipe-url` code in chef-solo.  The use of `-r` in chef-solo to mean `--recipe-url` has also been deprecated.

The `rm -rf *` behavior has been moved to a `--delete-entire-chef-repo` option.  Users of chef-solo who want the old pre-12.7 behavior of `-r XXX` should therefore use `--recipe-url XXX --delete-entire-chef-repo`.

## Chef::REST

We recently completed moving our internal API calls from `Chef::REST` to
`Chef::ServerAPI`. As part of that move, `Chef::REST` is no longer globally
required, so if your code uses `Chef::REST`, you must ensure that you
require it correctly.

```ruby
require 'chef/rest'
```

We strongly encourage users to move away from using `Chef::REST`; if
your code is run inside `knife` or `chef` then consider using
`Chef::ServerAPI`, otherwise please investigate [ChefAPI](http://sethvargo.github.io/chef-api/).

## Nokogiri

The latest version of the nokogiri gem will now be included in all omnibus-chef builds.  See
[RFC 063](https://github.com/chef/chef-rfc/blob/master/rfc063-omnibus-chef-native-gems.md) and
[RFC 063 PR discussion](https://github.com/chef/chef-rfc/pull/162) for more information.
