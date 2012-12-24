#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'tmpdir'
require 'fileutils'
require 'chef_zero/server'
require 'support/shared/integration/knife_support'
require 'spec_helper'

require 'chef/knife/delete'
require 'chef/knife/deps'
require 'chef/knife/diff'
require 'chef/knife/download'
require 'chef/knife/list'
require 'chef/knife/raw'
require 'chef/knife/show'
require 'chef/knife/upload'

module IntegrationSupport
  def when_the_repository(description, contents, &block)
    context "When the local repository #{description}" do
      before :each do
        raise "Can only create one directory per test" if @repository_dir
        @repository_dir = Dir.mktmpdir('chef_repo')
        create_child_files(@repository_dir, contents)
        Chef::Config.chef_repo_path = @repository_dir
      end

      after :each do
        if @repository_dir
          FileUtils.remove_directory_secure(@repository_dir)
          @repository_dir = nil
        end
      end

      instance_eval(&block)
    end
  end

  def when_the_chef_server(description, &block)
    context "When the Chef server #{description}" do
      before :each do
        raise "Attempt to create multiple servers in one test" if @server
        # Set up configuration so that clients will point to the server
        Thin::Logging.silent = true
        @server = ChefZero::Server.new(:port => 8889)
        Chef::Config.chef_server_url = @server.url
        Chef::Config.node_name = 'admin'
        Chef::Config.client_key = File.join(File.dirname(__FILE__), 'stickywicket.pem')

        # Start the server
        @server.start_background
      end

      def self.client(name, client)
        before(:each) { @server.load_data({ 'clients' => { name => client }}) }
      end

      def self.cookbook(name, version, cookbook)
        before(:each) { @server.load_data({ 'cookbooks' => { "#{name}-#{version}" => cookbook }}) }
      end

      def self.data_bag(name, data_bag)
        before(:each) { @server.load_data({ 'data' => { name => data_bag }}) }
      end

      def self.environment(name, environment)
        before(:each) { @server.load_data({ 'environments' => { name => environment }}) }
      end

      def self.node(name, node)
        before(:each) { @server.load_data({ 'nodes' => { name => node }}) }
      end

      def self.role(name, role)
        before(:each) { @server.load_data({ 'roles' => { name => role }}) }
      end

      def self.user(name, user)
        before(:each) { @server.load_data({ 'users' => { name => user }}) }
      end

      after :each do
        if @server
          @server.stop
          @server = nil
        end
      end

      instance_eval(&block)
    end
  end

  private

  def create_child_files(real_dir, contents)
    contents.each_pair do |entry_name, entry_contents|
      entry_path = File.join(real_dir, entry_name)
      if entry_contents.is_a? Hash
        Dir.mkdir(entry_path)
        create_child_files(entry_path, entry_contents)
      else
        File.open(entry_path, "w") do |file|
          file.write(entry_contents)
        end
      end
    end
  end
end
