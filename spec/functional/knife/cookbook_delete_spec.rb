#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'spec_helper'
require 'tiny_server'

describe Chef::Knife::CookbookDelete do
  before(:all) do
    @original_config = Chef::Config.hash_dup

    @server = TinyServer::Manager.new
    @server.start
  end

  before(:each) do
    @knife = Chef::Knife::CookbookDelete.new
    @api = TinyServer::API.instance
    @api.clear

    Chef::Config[:node_name] = nil
    Chef::Config[:client_key] = nil
    Chef::Config[:chef_server_url] = 'http://localhost:9000'
  end

  after(:all) do
    Chef::Config.configuration = @original_config
    @server.stop
  end

  context "when the the cookbook doesn't exist" do
    before do
      @log_output = StringIO.new

      Chef::Log.logger = Logger.new(@log_output)
      Chef::Log.level = :debug

      @knife.name_args = %w{no-such-cookbook}
      @api.get("/cookbooks/no-such-cookbook", 404, {'error'=>'dear Tim, no. -Sent from my iPad'}.to_json)
    end

    it "logs an error and exits" do
      @knife.ui.stub!(:stderr).and_return(@log_output)
      lambda {@knife.run}.should raise_error(SystemExit)
      @log_output.string.should match(/Cannot find a cookbook named no-such-cookbook to delete/)
    end

  end

  context "when there is only one version of a cookbook" do
    before do
      @knife.name_args = %w{obsolete-cookbook}
      @cookbook_list = {'obsolete-cookbook' => { 'versions' => ['version' => '1.0.0']} }
      @api.get("/cookbooks/obsolete-cookbook", 200, @cookbook_list.to_json)
    end

    it "asks for confirmation, then deletes the cookbook" do
      stdin, stdout = StringIO.new("y\n"), StringIO.new
      @knife.ui.stub!(:stdin).and_return(stdin)
      @knife.ui.stub!(:stdout).and_return(stdout)

      cb100_deleted = false
      @api.delete("/cookbooks/obsolete-cookbook/1.0.0", 200) { cb100_deleted = true; "[\"true\"]" }

      @knife.run

      stdout.string.should match(/#{Regexp.escape('Do you really want to delete obsolete-cookbook version 1.0.0? (Y/N)')}/)
      cb100_deleted.should be_true
    end

    it "asks for confirmation before purging" do
      @knife.config[:purge] = true

      stdin, stdout = StringIO.new("y\ny\n"), StringIO.new
      @knife.ui.stub!(:stdin).and_return(stdin)
      @knife.ui.stub!(:stdout).and_return(stdout)

      cb100_deleted = false
      @api.delete("/cookbooks/obsolete-cookbook/1.0.0?purge=true", 200) { cb100_deleted = true; "[\"true\"]" }

      @knife.run

      stdout.string.should match(/#{Regexp.escape('Are you sure you want to purge files')}/)
      stdout.string.should match(/#{Regexp.escape('Do you really want to delete obsolete-cookbook version 1.0.0? (Y/N)')}/)
      cb100_deleted.should be_true
      
    end

  end

  context "when there are several versions of a cookbook" do
    before do
      @knife.name_args = %w{obsolete-cookbook}
      versions = ['1.0.0', '1.1.0', '1.2.0']
      with_version = lambda { |version| { 'version' => version } }
      @cookbook_list = {'obsolete-cookbook' => { 'versions' => versions.map(&with_version) } }
      @api.get("/cookbooks/obsolete-cookbook", 200, @cookbook_list.to_json)
    end

    it "deletes all versions of a cookbook when given the '-a' flag" do
      @knife.config[:all] = true
      @knife.config[:yes] = true
      cb100_deleted = cb110_deleted = cb120_deleted = nil
      @api.delete("/cookbooks/obsolete-cookbook/1.0.0", 200) { cb100_deleted = true; "[\"true\"]" }
      @api.delete("/cookbooks/obsolete-cookbook/1.1.0", 200) { cb110_deleted = true; "[\"true\"]" }
      @api.delete("/cookbooks/obsolete-cookbook/1.2.0", 200) { cb120_deleted = true; "[\"true\"]" }
      @knife.run

      cb100_deleted.should be_true
      cb110_deleted.should be_true
      cb120_deleted.should be_true
    end

    it "asks which version to delete and deletes that when not given the -a flag" do
      cb100_deleted = cb110_deleted = cb120_deleted = nil
      @api.delete("/cookbooks/obsolete-cookbook/1.0.0", 200) { cb100_deleted = true; "[\"true\"]" }
      stdin, stdout = StringIO.new, StringIO.new
      @knife.ui.stub!(:stdin).and_return(stdin)
      @knife.ui.stub!(:stdout).and_return(stdout)
      stdin << "1\n"
      stdin.rewind
      @knife.run
      cb100_deleted.should be_true
      stdout.string.should match(/Which version\(s\) do you want to delete\?/)
    end

    it "deletes all versions of the cookbook when not given the -a flag and the user chooses to delete all" do
      cb100_deleted = cb110_deleted = cb120_deleted = nil
      @api.delete("/cookbooks/obsolete-cookbook/1.0.0", 200) { cb100_deleted = true; "[\"true\"]" }
      @api.delete("/cookbooks/obsolete-cookbook/1.1.0", 200) { cb110_deleted = true; "[\"true\"]" }
      @api.delete("/cookbooks/obsolete-cookbook/1.2.0", 200) { cb120_deleted = true; "[\"true\"]" }

      stdin, stdout = StringIO.new("4\n"), StringIO.new
      @knife.ui.stub!(:stdin).and_return(stdin)
      @knife.ui.stub!(:stdout).and_return(stdout)

      @knife.run

      cb100_deleted.should be_true
      cb110_deleted.should be_true
      cb120_deleted.should be_true
    end

  end

end
