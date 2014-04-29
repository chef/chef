# Chef Client Changelog

## Unreleased
* Print nested LWRPs with indentation in doc formatter output
* Make local mode stable enough to run chef-pedant
* Catch HTTPServerException for 404 in remote_file retry (CHEF-5116)
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

## Last Release: 11.12.0 RC1 (03/31/2014)
* SIGTERM will once-more kill a non-daemonized chef-client (CHEF-5172)

http://www.getchef.com/blog/2014/03/31/release-candidates-chef-client-11-12-0-10-32-0/
