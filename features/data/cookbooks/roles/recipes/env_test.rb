#
# Cookbook Name:: roles
# Recipe:: env_test
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

Chef::Log.debug(node.override.inspect)
Chef::Log.debug(node.default.inspect)
execute "echo #{node.reason} > #{File.join(node.tmpdir, "role_env_test_reason.txt")}"
execute "echo #{node.ossining} > #{File.join(node.tmpdir, "role_env_test_ossining.txt")}"
execute "echo #{node["languages"]["ruby"]["version"]} > #{File.join(node.tmpdir, "role_env_test_ruby_version.txt")}"

