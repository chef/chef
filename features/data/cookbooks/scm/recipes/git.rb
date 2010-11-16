#
# Cookbook Name:: scm
# Recipe:: git
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
# If the features are not being run from a git clone, you're out of luck.
git "the chef repo" do
  repository "#{node[:tmpdir]}/test_git_repo"
  reference "HEAD"
  destination "#{node[:tmpdir]}/gitchef"
  action :sync
end
