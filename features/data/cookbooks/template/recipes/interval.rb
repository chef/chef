#
# Cookbook Name:: template
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

# can no longer set chef to run repeatedly in the foreground
# without some hackery like this:
Chef::Config[:interval] = 1

$run_count ||= %w{one two}
exit!(108) if $run_count.empty?

Chef::Log.info("run count: #{$run_count}")

vars = {:value => $run_count.shift}

Chef::Log.error(:vars => vars.inspect, :RUN_COUNT => $run_count.inspect)

template "#{node[:tmpdir]}/template.txt" do
  source "template.txt.erb"
  variables(vars)
end

