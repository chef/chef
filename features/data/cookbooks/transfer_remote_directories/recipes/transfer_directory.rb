#
# Cookbook Name:: transfer_remote_directories
# Recipe:: transfer_directory
#
# Copyright 2009, Daniel DeLeo
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

remote_directory "#{node[:tmpdir]}/transfer_directory" do
  source "transfer_directory_feature"
  files_backup 10
  files_owner "root"
  files_group "staff"
  files_mode "0644"
  owner "nobody"
  group "nogroup"
  mode "0755"
end
