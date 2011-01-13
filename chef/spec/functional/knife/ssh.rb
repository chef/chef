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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'tiny_server'

describe Chef::Knife::Ssh do

  before(:all) do
    Thin::Logging.silent = true
    @server = TinyServer::Manager.new
    @server.start
  end

  after(:all) do
    @server.stop
  end

  context "when knife[:ssh_attribute] is set" do
    before do
      setup_knife(['*:*', 'uptime'])
      Chef::Config[:knife][:ssh_attribute] = "ec2.public_hostname"
    end

    it "uses the ssh_attribute" do
      @knife.run
      @knife.config[:attribute].should == "ec2.public_hostname"
    end
  end

  context "When knife[:ssh_attribte] is not provided]" do
    before do
      setup_knife(['*:*', 'uptime'])
      Chef::Config[:knife][:ssh_attribute] = nil
    end

    it "uses the default" do
      @knife.run
      @knife.config[:attribute].should == "fqdn"
    end
  end

  context "When -a ec2.public_ipv4 is provided" do
    before do
      setup_knife(['-a ec2.public_hostname', '*:*', 'uptime'])
      Chef::Config[:knife][:ssh_attribute] = nil
    end

    it "should use the value on the command line" do
      @knife.run
      @knife.config[:attribute].should == "ec2.public_hostname"
    end

    it "should override what is set in knife.rb" do
      Chef::Config[:knife][:ssh_attribute] = "fqdn"
      @knife.run
      @knife.config[:attribute].should == "ec2.public_hostname"
    end
  end

  def setup_knife(params=[])
    @knife = Chef::Knife::Ssh.new(params)
    @knife.stub!(:ssh_command).and_return { [] }
    @api = TinyServer::API.instance
    @api.clear

    Chef::Config[:node_name] = false
    Chef::Config[:client_key] = false
    Chef::Config[:chef_server_url] = 'http://localhost:9000'

    @api.get("/search/node?q=*:*&sort=X_CHEF_id_CHEF_X%20asc&start=0&rows=1000", 200) { 
      %({"total":1, "start":0, "rows":[{"name":"i-xxxxxxxx", "json_class":"Chef::Node", "automatic":{"fqdn":"the.fqdn", "ec2":{"public_hostname":"the_public_hostname"}},"recipes":[]}]})
    }
  end

end
