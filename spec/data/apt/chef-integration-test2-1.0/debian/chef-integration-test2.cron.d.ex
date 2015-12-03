#
# Regular cron jobs for the chef-integration-test2 package
#
0 4	* * *	root	[ -x /usr/bin/chef-integration-test2_maintenance ] && /usr/bin/chef-integration-test2_maintenance
