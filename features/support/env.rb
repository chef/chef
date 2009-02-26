#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
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

%w{chef chef-server}.each do |inc_dir|
  $: << File.join(File.dirname(__FILE__), '..', '..', inc_dir, 'lib')
end

require 'spec/expectations'
require 'chef'
require 'chef/config'
require 'chef/client'
require 'tmpdir'

Chef::Config.from_file(File.join(File.dirname(__FILE__), '..', 'data', 'config', 'client.rb'))
Ohai::Config[:log_level] = :error

class ChefWorld
  attr_accessor :client, :tmpdir
  
  def initialize
    @client = Chef::Client.new
    @tmpdir = File.join(Dir.tmpdir, "chef_integration")
    @cleanup_files = Array.new
    @cleanup_dirs = Array.new
    @recipe = nil
  end
end

World do
  ChefWorld.new
end

After do
  @cleanup_files.each do |file|
    system("rm #{file}")
  end
  @cleanup_dirs.each do |dir|
    system("rm -rf #{dir}")
  end
end

