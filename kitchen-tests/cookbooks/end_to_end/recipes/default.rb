#
# Cookbook:: end_to_end
# Recipe:: default
#
# Copyright:: Copyright (c) Chef Software Inc.
#

include_recipe "::linux" if platform_family?("rhel", "debian")
include_recipe "::windows" if windows?
