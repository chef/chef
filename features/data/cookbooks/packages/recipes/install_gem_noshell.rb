#
# Cookbook Name:: packages
# Recipe:: gem_package
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

directory "#{node[:tmpdir]}/installed-gems/"

gem_package "chef-integration-test" do
  source "http://localhost:8000"
  version "0.1.0"
  options :install_dir => "#{node[:tmpdir]}/installed-gems/"
end
