#
# Cookbook Name:: global-onlyif
# Recipe:: default
#
# Copyright 2008, Example Com
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

file "/tmp/neverhappen" do
  only_if do false; end
end

file "/tmp/stillnothappening" do
  not_if do true; end
end

file "/tmp/seriouslynothappening" do
  only_if "false"
end

file "/tmp/yepstillnot" do
  not_if "true"
end

file "/tmp/shouldhappen" do
  only_if do true; end
  action [:create, :delete]
end

file "/tmp/shouldhappen" do
  only_if "true"
  action [:create, :delete]
end

file "/tmp/shouldhappen" do
  not_if do false; end
  action [:create, :delete]
end

file "/tmp/shouldhappen" do
  not_if "false"
  action [:create, :delete]
end

