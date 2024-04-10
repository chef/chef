#
# Cookbook:: windows_service
# Recipe:: _windows_service.rb
#
# Copyright:: Copyright (c) Chef Software Inc.
#

windows_service "chef-client" do
  action :create
  binary_path_name "c:/opscode/chef/bin"
  description "Test description 2"
  startup_type :manual
end
