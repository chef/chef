#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright (c) 2011-2012 Opscode, Inc.
#

bootstrap_status_file = "/var/opt/chef-server/bootstrapped"
erchef_dir = "/opt/chef-server/embedded/service/erchef"

# TODO: add a check to curl -skf http://localhost:8000/_status
execute "boostrap-chef-server" do
  command "bin/bootstrap-chef-server"
  cwd erchef_dir
  not_if { File.exists?(bootstrap_status_file) }
end

file bootstrap_status_file do
  owner "root"
  group "root"
  mode "0600"
  content "You're bootstraps are belong to Chef"
end
