# Chef Client 10.x Changelog

## Unreleased

* [**Phil Dibowitz**](https://github.com/jaymzh):
  Fix 'dscl' provider for "user" resource to handle dscl caching properly


## 10.34.0

* [**Phil Dibowitz**](https://github.com/jaymzh):
  'group' provider on OSX properly uses 'dscl' to determine existing groups
* `options` attribute of mount resource now supports lazy evaluation. (CHEF-5163)
* Fix OS X service provider actions that don't require the service label
  to work when there is no plist. (backport CHEF-5223)
* Set Net::HTTP open_timeout. (backport Chef-1585)
* Fix RPM package version detection (backport Issue 1554)
* Support for single letter environments.
* Add password setting support for Mac 10.7, 10.8 and 10.9 to the dscl user provider.


## 10.32.2

* [**Phil Dibowitz**](https://github.com/jaymzh):
  Service Provider for MacOSX now supports `enable` and `disable`
* [**Phil Dibowitz**](https://github.com/jaymzh):
  Chef now gracefully handles corrupted cache files.
* [**Phil Dibowitz**](https://github.com/jaymzh):
  SIGTERM will once-more kill a non-daemonized chef-client (CHEF-5172)
* [**Phil Dibowitz**](https://github.com/jaymzh):
  bump up upper limit on json gem to 1.8.1 (CHEF-4632)
* [**Ryan Cragun**](https://github.com/ryancragun):
  Don't detect package name as version when the RPM isn't installed.

* pin sdoc to 0.3.0 due to solaris packaging issues.

## Last Release: 10.30.4 (02/18/2014)

http://www.getchef.com/blog/2014/02/18/chef-client-release-11-10-2-10-30-4/
