#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright 2008-2010 Opscode, Inc.
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
    Chef::Log.logger = Logger.new(StringIO.new)

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
    @node.chef_environment("_default")
    @node[:platform] = "example-platform"
    @node[:platform_version] = "example-platform-1.0"

    @client = Chef::Client.new
    @client.node = @node
  end

  describe "when enforcing path sanity" do
    before do
      Chef::Config[:enforce_path_sanity] = true
    end

    it "adds all useful PATHs that are not yet in PATH to PATH" do
      env = {"PATH" => ""}
      @client.enforce_path_sanity(env)
      env["PATH"].should == "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    end

    it "does not re-add paths that already exist in PATH" do
      env = {"PATH" => "/usr/bin:/sbin:/bin"}
      @client.enforce_path_sanity(env)
      env["PATH"].should == "/usr/bin:/sbin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin"
    end
  end

  describe "run" do
    it "should identify the node and run ohai, then register the client" do
      mock_chef_rest_for_node = mock("Chef::REST (node)")
      mock_chef_rest_for_client = mock("Chef::REST (client)")
      mock_chef_rest_for_node_save = mock("Chef::REST (node save)")
      mock_chef_runner = mock("Chef::Runner")

      # --Client.register
      #   Make sure Client#register thinks the client key doesn't
      #   exist, so it tries to register and create one.
      File.should_receive(:exists?).with(Chef::Config[:client_key]).exactly(1).times.and_return(false)

      #   Client.register will register with the validation client name.
      Chef::REST.should_receive(:new).with(Chef::Config[:client_url], Chef::Config[:validation_client_name], Chef::Config[:validation_key]).and_return(mock_chef_rest_for_client)
      mock_chef_rest_for_client.should_receive(:register).with(@fqdn, Chef::Config[:client_key]).and_return(true)
      #   Client.register will then turn around create another
      #   Chef::REST object, this time with the client key it got from the
      #   previous step.
      Chef::REST.should_receive(:new).with(Chef::Config[:chef_server_url], @fqdn, Chef::Config[:client_key]).and_return(mock_chef_rest_for_node)

      # --Client.build_node
      #   looks up the node, which we will return, then later saves it.
      Chef::Node.should_receive(:find_or_create).with(@fqdn).and_return(@node)

      # --Client.setup_run_context
      # ---Client.sync_cookbooks -- downloads the list of cookbooks to sync
      #
      # FIXME: Ideally, we might prefer to mock at a lower level, but
      #        this at least avoids the spec test from trying to
      #        delete files out of Chef::Config[:file_cache_path] (/var/chef/cache)
      Chef::CookbookVersion.should_receive(:clear_obsoleted_cookbooks).with({}).and_return(true)
      mock_chef_rest_for_node.should_receive(:post_rest).with("environments/_default/cookbook_versions", {:run_list => []}).and_return({})

      # --Client.converge
      Chef::Runner.should_receive(:new).and_return(mock_chef_runner)
      mock_chef_runner.should_receive(:converge).and_return(true)

      # --Client.save_updated_node
      Chef::REST.should_receive(:new).with(Chef::Config[:chef_server_url]).and_return(mock_chef_rest_for_node_save)
      mock_chef_rest_for_node_save.should_receive(:put_rest).with("nodes/#{@fqdn}", @node).and_return(true)

      @client.should_receive(:run_started)
      @client.should_receive(:run_completed_successfully)


      # This is what we're testing.
      @client.run


      # Post conditions: check that node has been filled in correctly
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
      @node.run_list << "role[role_containing_cookbook1]"
      role_containing_cookbook1 = Chef::Role.new
      role_containing_cookbook1.name("role_containing_cookbook1")
      role_containing_cookbook1.run_list << "cookbook1"

      Chef::Node.should_receive(:find_or_create).and_return(@node)
      #@node.should_receive(:expand!).with('server').and_return(RunListExpansionFromDisk.new(RunListItem.new("cookbook1")))

      # build_node will call Node#expand! with server, which will
      # eventually hit the server to expand the included role.
      mock_chef_rest = mock("Chef::REST")
      mock_chef_rest.should_receive(:get_rest).with("roles/role_containing_cookbook1").and_return(role_containing_cookbook1)
      Chef::REST.should_receive(:new).and_return(mock_chef_rest)

      # check pre-conditions.
      @node[:roles].should be_nil
      @node[:recipes].should be_nil

      @client.build_node

      # check post-conditions.
      @node[:roles].should_not be_nil
      @node[:roles].length.should == 1
      @node[:roles].should include("role_containing_cookbook1")
      @node[:recipes].should_not be_nil
      @node[:recipes].length.should == 1
      @node[:recipes].should include("cookbook1")
    end
  end
end
