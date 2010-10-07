#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

require 'chef/run_context'
require 'chef/rest'

describe Chef::Client do
  before do
    # Node/Ohai data
    @hostname = "hostname"
    @fqdn = "hostname.example.org"
    Chef::Config[:node_name] = @fqdn
    ohai_data = { :fqdn             => @fqdn,
                  :hostname         => @hostname,
                  :platform         => 'example-platform',
                  :platform_version => 'example-platform',
                  :data             => {} }
    ohai_data.stub!(:all_plugins).and_return(true)
    ohai_data.stub!(:data).and_return(ohai_data[:data])
    Ohai::System.stub!(:new).and_return(ohai_data)

    @node = Chef::Node.new(@hostname)
    @node.name(@fqdn)
    @node[:platform] = "example-platform"
    @node[:platform_version] = "example-platform-1.0"

    @client = Chef::Client.new
    @client.node = @node
  end

  describe "run" do
    it "should identify the node and run ohai, then register the client" do

      mock_chef_rest_for_node = OpenStruct.new({ })
      mock_chef_rest_for_client = OpenStruct.new({ })
      mock_couchdb = OpenStruct.new({ })

      Chef::CouchDB.stub(:new).and_return(mock_couchdb)

      # --Client.register
      #   Use a filename we're sure doesn't exist, so that the registration
      #   code creates a new client.
      temp_client_key_file = Tempfile.new("chef_client_spec__client_key")
      temp_client_key_file.close
      FileUtils.rm(temp_client_key_file.path)
      Chef::Config[:client_key] = temp_client_key_file.path

      #   Client.register will register with the validation client name.
      Chef::REST.should_receive(:new).with(Chef::Config[:chef_server_url]).at_least(1).times.and_return(mock_chef_rest_for_node)
      Chef::REST.should_receive(:new).with(Chef::Config[:client_url], Chef::Config[:validation_client_name], Chef::Config[:validation_key]).and_return(mock_chef_rest_for_client)
      mock_chef_rest_for_client.should_receive(:register).with(@fqdn, Chef::Config[:client_key]).and_return(true)
      #   Client.register will then turn around create another
      #   Chef::REST object, this time with the client key it got from the
      #   previous step.
      Chef::REST.should_receive(:new).with(Chef::Config[:chef_server_url], @fqdn, Chef::Config[:client_key]).and_return(mock_chef_rest_for_node)

      # --Client.build_node
      #   looks up the node, which we will return, then later saves it.
      mock_chef_rest_for_node.should_receive(:get_rest).with("nodes/#{@fqdn}").and_return(@node)
      mock_chef_rest_for_node.should_receive(:put_rest).with("nodes/#{@fqdn}", @node).exactly(2).times.and_return(@node)

      # --Client.sync_cookbooks -- downloads the list of cookbooks to sync
      #

      # after run, check proper mutation of node
      # e.g., node.automatic_attrs[:platform], node.automatic_attrs[:platform_version]
      Chef::Config.node_path(File.expand_path(File.join(CHEF_SPEC_DATA, "run_context", "nodes")))
      Chef::Config.cookbook_path(File.expand_path(File.join(CHEF_SPEC_DATA, "run_context", "cookbooks")))

      @client.stub!(:sync_cookbooks).and_return({})
      @client.run


      # check that node has been filled in correctly
      @node.automatic_attrs[:platform].should == "example-platform"
      @node.automatic_attrs[:platform_version].should == "example-platform-1.0"
    end

    describe "when notifying other objects of the status of the chef run" do
      before do
        Chef::Client.clear_notifications
        Chef::Node.stub!(:find_or_create).and_return(@node)
        @node.stub!(:save)
        @client.build_node
      end

      it "notifies observers that the run has started" do
        notified = false
        Chef::Client.when_run_starts do |run_status|
          run_status.node.should == @node
          notified = true
        end

        @client.run_started
        notified.should be_true
      end

      it "notifies observers that the run has completed successfully" do
        notified = false
        Chef::Client.when_run_completes_successfully do |run_status|
          run_status.node.should == @node
          notified = true
        end

        @client.run_completed_successfully
        notified.should be_true
      end

      it "notifies observers that the run failed" do
        notified = false
        Chef::Client.when_run_fails do |run_status|
          run_status.node.should == @node
          notified = true
        end

        @client.run_failed
        notified.should be_true
      end
    end
  end

  describe "build_node" do
    it "should expand the roles and recipes for the node" do
      Chef::Node.should_receive(:find_or_create).and_return(@node)
      @node.should_receive(:save).and_return(true)

      @node[:roles].should be_nil
      @node[:recipes].should be_nil
      @client.build_node
      @node[:roles].should_not be_nil
      @node[:recipes].should_not be_nil
    end
  end
end
