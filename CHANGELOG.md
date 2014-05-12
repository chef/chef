# Chef Client Changelog

## Unreleased
* Print nested LWRPs with indentation in doc formatter output
* Make local mode stable enough to run chef-pedant
* Catch HTTPServerException for 404 in remote\_file retry (CHEF-5116)
* Wrap code in block context when syntax checking so `return` is valid
  (CHEF-5199)
* Quote git resource rev\_pattern to prevent glob matching files (CHEF-4940)
* chef-service-manager now runs as a non-interactive service (CHEF-5150)
* Fix remote\_file support for file:// URI on windows (CHEF-4472)
* Fix OS X service provider actions that don't require the service label
  to work when there is no plist. (CHEF-5223)
* User resource now only prints the name during why-run runs. (CHEF-5180)
* Providers are now set correctly on CloudLinux. (CHEF-5182)
* -E option now works with single lettered environments (CHEF-3075)
* Set --run-lock-timeout to wait/bail if another client has the runlock (CHEF-5074)
* A node's environment can now be set with 'knife node environment set NODE ENVIRONMENT' (CHEF-1910)
* remote\_file's source attribute does not support DelayedEvaluators (CHEF-5162)
* `option` attribute of mount resource now supports lazy evaluation. (CHEF-5163)
* `force_unlink` now only unlinks if the file already exists. (CHEF-5015)
* bootstrap no reports authentication failures. (CHEF-5161)
* `chef_gem` resource now uses omnibus gem binary. (CHEF-5092)
* `freebsd_package` resource now uses the brand new "pkgng" package manager when available. (CHEF-4637)
* chef-full template gets knife options to override install script url, add wget/curl cli options, and custom install commands (CHEF-4697)
* knife now bootstraps node with the latest current version of chef-client. (CHEF-4911)

## Last Release: 11.12.0 RC1 (03/31/2014)
* SIGTERM will once-more kill a non-daemonized chef-client (CHEF-5172)

http://www.getchef.com/blog/2014/03/31/release-candidates-chef-client-11-12-0-10-32-0/
