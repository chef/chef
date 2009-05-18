#
# Cookbook Name:: change_remote_file_perms_trickery
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

# The "trickery" comes from the fact that chef waits until all Resources are defined before actually

r = remote_file "#{node[:tmpdir]}/transfer_a_file_from_a_cookbook.txt" do
  source "transfer_a_file_from_a_cookbook.txt"
  mode 0600
  action :nothing
end
# This creates the file out-of-band ()
r.run_action(:create)

remote_file "#{node[:tmpdir]}/transfer_a_file_from_a_cookbook.txt" do
  source "transfer_a_file_from_a_cookbook.txt"
  mode 0644
end
