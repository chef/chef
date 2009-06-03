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

%w{chef chef-server chef-server-slice}.each do |inc_dir|
  $: << File.join(File.dirname(__FILE__), '..', '..', inc_dir, 'lib')
end

require 'rubygems'
require 'spec'
require 'chef'
require 'chef/config'
require 'chef/client'
require 'tmpdir'
require 'merb-core'
require 'merb_cucumber/world/webrat'

def Spec.run? ; true; end

Chef::Config.from_file(File.join(File.dirname(__FILE__), '..', 'data', 'config', 'server.rb'))
Chef::Config[:log_level] = :error
Ohai::Config[:log_level] = :error

if ENV['DEBUG'] = 'true'
  Merb.logger.set_log(STDOUT, :debug) if ENV['DEBUG'] = 'true'
else
  Merb.logger.set_log(STDOUT, :error)
end

Merb.start_environment(
  :merb_root => File.join(File.dirname(__FILE__), "..", "..", "chef-server"), 
  :testing => true, 
  :adapter => 'runner',
  :environment => ENV['MERB_ENV'] || 'test',
  :session_store => 'memory'
)

Spec::Runner.configure do |config|
  config.include(Merb::Test::ViewHelper)
  config.include(Merb::Test::RouteHelper)
  config.include(Merb::Test::ControllerHelper)
end

module ChefWorld

  attr_accessor :recipe, :cookbook, :response, :inflated_response, :log_level, :chef_args, :config_file, :stdout, :stderr, :status, :exception

  def client
    @client ||= Chef::Client.new
  end

  def rest
    @rest ||= Chef::REST.new('http://localhost:4000')
  end

  def tmpdir
    @tmpdir ||= File.join(Dir.tmpdir, "chef_integration")
  end
  
  def datadir
    @datadir ||= File.join(File.dirname(__FILE__), "..", "data")
  end

  def cleanup_files
    @cleanup_files ||= Array.new
  end

  def cleanup_dirs
    @cleanup_dirs ||= Array.new
  end

  def stash
    @stash ||= Hash.new
  end
  
end

World(ChefWorld)

After do
  cleanup_files.each do |file|
    system("rm #{file}")
  end
  cleanup_dirs.each do |dir|
    system("rm -rf #{dir}")
  end
  cj = Chef::REST::CookieJar.instance
  cj.keys.each do |key|
    cj.delete(key)
  end
  data_tmp = File.join(File.dirname(__FILE__), "..", "data", "tmp")
  system("rm -rf #{data_tmp}/*")
end

