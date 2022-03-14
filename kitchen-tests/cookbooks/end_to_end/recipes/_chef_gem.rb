#
# Cookbook:: end_to_end
# Recipe:: chef_gem
#
# Copyright:: Copyright (c) Chef Software Inc.
#

# make sure customers can install knife back into the client for now
# and also make sure chef_gem works in general
# ===== knife test has to be disabled until chef 17.10 is released ====
# gem_name = rhel6? ? "community_cookbook_releaser" : "knife"
gem_name = "community_cookbook_releaser"

chef_gem gem_name do
  action :install
  compile_time false
end
