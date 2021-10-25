#
# Cookbook:: end_to_end
# Recipe:: chef_gem
#
# Copyright:: Copyright (c) Chef Software Inc.
#

# make sure customers can install knife back into the client for now
# and also make sure chef_gem works in general
gem_name = rhel6? ? "community_cookbook_releaser" : "knife"

chef_gem gem_name do
  action :install
  compile_time false
end