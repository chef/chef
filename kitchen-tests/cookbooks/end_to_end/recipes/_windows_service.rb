#
# Cookbook:: windows_service
# Recipe:: _windows_service.rb
#
# Copyright:: Copyright (c) Chef Software Inc.
#

windows_service "chef-client" do
  action :create
  binary_path_name "c:/opscode/chef/bin"
  service_name "chef-client"
  description "Test description #{SecureRandom.hex(16)}"
  startup_type :manual
end
