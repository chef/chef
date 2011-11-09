#
# Cookbook Name:: delayed_notifications
# Recipe:: notify_a_resource_from_a_single_source
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

file "#{node[:tmpdir]}/notified_file.txt" do
  action :nothing
end

execute "echo foo" do
  notifies :create, resources("file[#{node[:tmpdir]}/notified_file.txt]"), :delayed
end
