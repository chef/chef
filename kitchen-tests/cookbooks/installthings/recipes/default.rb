#
# Cookbook Name:: installthings
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
#

# Do a source install
pushy_package_location = ::File.join('/tmp/', ::File.basename(node['installthings']['push_client_url']))

remote_file 'push jobs client download' do
  source node['installthings']['push_client_url']
  path pushy_package_location
end

package 'push jobs client install' do
  source pushy_package_location
end
