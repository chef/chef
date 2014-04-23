# Chef Client Changelog

## Unreleased
* Make local mode stable enough to run chef-pedant
* Catch HTTPServerException for 404 in remote_file retry (CHEF-5116)
* Wrap code in block context when syntax checking so `return` is valid
  (CHEF-5199)
* Quote git resource rev\_pattern to prevent glob matching files (CHEF-4940)
* chef-service-manager now runs as a non-interactive service (CHEF-5150)
* Fix remote\_file support for file:// URI on windows (CHEF-4472)
* Fix OS X service provider actions that don't require the service label
  to work when there is no plist. (CHEF-5223)

## Last Release: 11.12.0 RC1 (03/31/2014)
* SIGTERM will once-more kill a non-daemonized chef-client (CHEF-5172)

http://www.getchef.com/blog/2014/03/31/release-candidates-chef-client-11-12-0-10-32-0/
