#
# Cookbook Name:: CHEF-37
# Recipe:: default
#
# Copyright 2009, Opscode
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

cookbook_dir = "/var/chef/cookbooks/CHEF-37"

file_dir_list = {
  :fqdn             => File.expand_path(File.join(cookbook_dir, "files", "host-#{node[:fqdn]}")),
  :default          => File.expand_path(File.join(cookbook_dir, "files", "default")),
  :platform         => File.expand_path(File.join(cookbook_dir, "files", node[:platform])),
  :platform_version => File.expand_path(File.join(cookbook_dir, "files", "#{node[:platform]}-#{node[:platform_version]}")) 
}

template_dir_list = {
  :fqdn             => File.expand_path(File.join(cookbook_dir, "templates", "host-#{node[:fqdn]}")),
  :default          => File.expand_path(File.join(cookbook_dir, "templates", "default")),
  :platform         => File.expand_path(File.join(cookbook_dir, "templates", node[:platform])),
  :platform_version => File.expand_path(File.join(cookbook_dir, "templates", "#{node[:platform]}-#{node[:platform_version]}")) 
}

contents = "Frozen in the place I hide, not afraid to paint my sky with some who say I have lost my mind"
template_contents = '<%= @who %> sky with some who say I have lost my mind'

# Create the directory and every version of the file
[ :fqdn, :default, :platform, :platform_version ].each do |dirname|
  directory file_dir_list[dirname] do
    action :create
  end
  
  execute "create-#{dirname}-chef-37.txt" do
    command "echo '#{dirname}: #{contents}' > #{file_dir_list[dirname]}/chef-37.txt"
  end
  
  directory template_dir_list[dirname] do
    action :create
  end
  
  execute "create-template-#{dirname}-chef-37.txt" do
    command "echo '#{dirname}: #{template_contents}' > #{template_dir_list[dirname]}/chef-37-#{dirname}.txt.erb"
  end
end

# Then work down - fetch the file, should be the most specific one.
# Then delete that one from the cookbooks on the server, since we don't want it to 
# interfere with our next test.
[ :fqdn, :platform_version, :platform, :default ].each do |dirname|
  remote_file "/tmp/chef-37-#{dirname}.txt" do
    source "chef-37.txt"
    action :create
  end
  
  file "#{file_dir_list[dirname]}/chef-37.txt" do
    action :delete
  end
  
  template "/tmp/chef-template-37-#{dirname}.txt" do
    source "chef-37-#{dirname}.txt.erb"
    variables({
      :who => "paint my"
    })
    action :create
  end
  
  file "#{template_dir_list[dirname]}/chef-37-#{dirname}.txt.erb" do
    action :delete
  end
end
