#
# Cookbook Name:: mixlib-shellout_test
# Recipe:: default
#
# Copyright 2012, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

node.set['rvm']['user_installs'] = [
  { 'user'          => 'vagrant',
    'default_ruby'  => 'ruby-1.9.3-p327',
    'rubies'        => ['1.9.3']
  }
]

node.set['rvm']['gems'] = {
  "ruby-1.9.3-p327" => [
    { 'name' => 'bundler' }
  ]
}
include_recipe "rvm::user"
