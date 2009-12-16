#
# Cookbook Name:: search
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

# We have to sleep at least 10 seconds to confirm that the data has made it 
# into the index.  We can only rely on this because we are in a test environment
# in real-land Chef, the index is only eventually consistent.. and may take a
# variable amount of time.


sleep 10
objects = search(:users, "*:*")

objects.each do |entry|
  file "#{node[:tmpdir]}/#{entry["id"]}"
end

