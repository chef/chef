#
# Cookbook:: windows_service
# Recipe:: _windows_service.rb
#
# Copyright:: Copyright (c) Chef Software Inc.
#

windows_service "bits" do
  action :start
  service_name "BITS"
  description "Test description #{SecureRandom.hex(16)}"
  startup_type :manual
end
