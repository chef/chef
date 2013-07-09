#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#

require "chef/provider/cron/unix"

# Just to create an alias so 'Chef::Provider::Cron::Solaris' is exposed and accessible to existing consumers of class.
Chef::Provider::Cron::Solaris = Chef::Provider::Cron::Unix