#
# Author:: Bryan McLellan <btm@opscode.com>
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

require 'spec_helper'
require 'net/ssh'
require 'net/ssh/multi'

describe Chef::Knife::Ssh do
  before(:all) do
    @original_config = Chef::Config.hash_dup
    @original_knife_config = Chef::Config[:knife].dup
    Chef::Config[:client_key] = CHEF_SPEC_DATA + "/ssl/private_key.pem"
  end

  after(:all) do
    Chef::Config.configuration = @original_config
    Chef::Config[:knife] = @original_knife_config
  end

  before do
    @knife = Chef::Knife::Ssh.new
    @knife.config[:attribute] = "fqdn"
    @node_foo = Chef::Node.new
    @node_foo.automatic_attrs[:fqdn] = "foo.example.org"
    @node_foo.automatic_attrs[:ipaddress] = "10.0.0.1"
    @node_bar = Chef::Node.new
    @node_bar.automatic_attrs[:fqdn] = "bar.example.org"
    @node_bar.automatic_attrs[:ipaddress] = "10.0.0.2"
  end

  describe "#configure_session" do
    context "manual is set to false (default)" do
      before do
        @knife.config[:manual] = false
        @query = Chef::Search::Query.new
      end

      def configure_query(node_array)
        @query.stub!(:search).and_return([node_array])
        Chef::Search::Query.stub!(:new).and_return(@query)
      end

      def self.should_return_specified_attributes
        it "returns an array of the attributes specified on the command line OR config file, if only one is set" do
          @knife.config[:attribute] = "ipaddress"
          @knife.config[:override_attribute] = "ipaddress"
          configure_query([@node_foo, @node_bar])
          @knife.should_receive(:session_from_list).with(['10.0.0.1', '10.0.0.2'])
          @knife.configure_session
        end

        it "returns an array of the attributes specified on the command line even when a config value is set" do
          @knife.config[:attribute] = "config_file" # this value will be the config file
          @knife.config[:override_attribute] = "ipaddress" # this is the value of the command line via #configure_attribute
          configure_query([@node_foo, @node_bar])
          @knife.should_receive(:session_from_list).with(['10.0.0.1', '10.0.0.2'])
          @knife.configure_session
        end
      end

      it "searchs for and returns an array of fqdns" do
        configure_query([@node_foo, @node_bar])
        @knife.should_receive(:session_from_list).with(['foo.example.org', 'bar.example.org'])
        @knife.configure_session
      end

      should_return_specified_attributes

      context "when cloud hostnames are available" do
        before do
          @node_foo.automatic_attrs[:cloud][:public_hostname] = "ec2-10-0-0-1.compute-1.amazonaws.com"
          @node_bar.automatic_attrs[:cloud][:public_hostname] = "ec2-10-0-0-2.compute-1.amazonaws.com"
        end

        it "returns an array of cloud public hostnames" do
          configure_query([@node_foo, @node_bar])
          @knife.should_receive(:session_from_list).with(['ec2-10-0-0-1.compute-1.amazonaws.com', 'ec2-10-0-0-2.compute-1.amazonaws.com'])
          @knife.configure_session
        end

        should_return_specified_attributes
      end

      it "should raise an error if no host are found" do
          configure_query([ ])
          @knife.ui.should_receive(:fatal)
          @knife.should_receive(:exit).with(10)
          @knife.configure_session
      end

      context "when there are some hosts found but they do not have an attribute to connect with" do
        before do
          @query.stub!(:search).and_return([[@node_foo, @node_bar]])
          @node_foo.automatic_attrs[:fqdn] = nil
          @node_bar.automatic_attrs[:fqdn] = nil
          Chef::Search::Query.stub!(:new).and_return(@query)
        end

        it "should raise a specific error (CHEF-3402)" do
          @knife.ui.should_receive(:fatal).with(/^2 nodes found/)
          @knife.should_receive(:exit).with(10)
          @knife.configure_session
        end
      end
    end

    context "manual is set to true" do
      before do
        @knife.config[:manual] = true
      end

      it "returns an array of provided values" do
        @knife.instance_variable_set(:@name_args, ["foo.example.org bar.example.org"])
        @knife.should_receive(:session_from_list).with(['foo.example.org', 'bar.example.org'])
        @knife.configure_session
      end
    end
  end

  describe "#configure_attribute" do
    before do
      Chef::Config[:knife][:ssh_attribute] = nil
      @knife.config[:attribute] = nil
    end

    it "should return fqdn by default" do
      @knife.configure_attribute
      @knife.config[:attribute].should == "fqdn"
    end

    it "should return the value set in the configuration file" do
      Chef::Config[:knife][:ssh_attribute] = "config_file"
      @knife.configure_attribute
      @knife.config[:attribute].should == "config_file"
    end

    it "should return the value set on the command line" do
      @knife.config[:attribute] = "command_line"
      @knife.configure_attribute
      @knife.config[:attribute].should == "command_line"
    end

    it "should set override_attribute to the value of attribute from the command line" do
      @knife.config[:attribute] = "command_line"
      @knife.configure_attribute
      @knife.config[:attribute].should == "command_line"
      @knife.config[:override_attribute].should == "command_line"
    end

    it "should set override_attribute to the value of attribute from the config file" do
      Chef::Config[:knife][:ssh_attribute] = "config_file"
      @knife.configure_attribute
      @knife.config[:attribute].should == "config_file"
      @knife.config[:override_attribute].should == "config_file"
    end

    it "should prefer the command line over the config file for the value of override_attribute" do
      Chef::Config[:knife][:ssh_attribute] = "config_file"
      @knife.config[:attribute] = "command_line"
      @knife.configure_attribute
      @knife.config[:override_attribute].should == "command_line"
    end
  end

  describe "#session_from_list" do
    before :each do
      @knife.instance_variable_set(:@longest, 0)
      ssh_config = {:timeout => 50, :user => "locutus", :port => 23 }
      Net::SSH.stub!(:configuration_for).with('the.b.org').and_return(ssh_config)
    end

    it "uses the port from an ssh config file" do
      @knife.session_from_list(['the.b.org'])
      @knife.session.servers[0].port.should == 23
    end

    it "uses the user from an ssh config file" do
      @knife.session_from_list(['the.b.org'])
      @knife.session.servers[0].user.should == "locutus"
    end
  end

  describe "#ssh_command" do
    let(:execution_channel) { double(:execution_channel, :on_data => nil) }
    let(:session_channel) { double(:session_channel, :request_pty => nil)}

    let(:execution_channel2) { double(:execution_channel, :on_data => nil) }
    let(:session_channel2) { double(:session_channel, :request_pty => nil)}

    let(:session) { double(:session, :loop => nil) }

    let(:command) { "false" }

    before do
      execution_channel.
        should_receive(:on_request).
        and_yield(nil, double(:data_stream, :read_long => exit_status))

      session_channel.
        should_receive(:exec).
        with(command).
        and_yield(execution_channel, true)

      execution_channel2.
        should_receive(:on_request).
        and_yield(nil, double(:data_stream, :read_long => exit_status2))

      session_channel2.
        should_receive(:exec).
        with(command).
        and_yield(execution_channel2, true)

      session.
        should_receive(:open_channel).
        and_yield(session_channel).
        and_yield(session_channel2)
    end

    context "both connections return 0" do
      let(:exit_status) { 0 }
      let(:exit_status2) { 0 }

      it "returns a 0 exit code" do
        @knife.ssh_command(command, session).should == 0
      end
    end

    context "the first connection returns 1 and the second returns 0" do
      let(:exit_status) { 1 }
      let(:exit_status2) { 0 }

      it "returns a non-zero exit code" do
        @knife.ssh_command(command, session).should == 1
      end
    end

    context "the first connection returns 1 and the second returns 2" do
      let(:exit_status) { 1 }
      let(:exit_status2) { 2 }

      it "returns a non-zero exit code" do
        @knife.ssh_command(command, session).should == 2
      end
    end
  end

  describe "#run" do
    before do
      @query = Chef::Search::Query.new
      @query.should_receive(:search).and_return([[@node_foo]])
      Chef::Search::Query.stub!(:new).and_return(@query)
      @knife.stub(:ssh_command).and_return(exit_code)
      @knife.name_args = ['*:*', 'false']
    end

    context "with an error" do
      let(:exit_code) { 1 }

      it "should exit with a non-zero exit code" do
        @knife.should_receive(:exit).with(exit_code)
        @knife.run
      end
    end

    context "with no error" do
      let(:exit_code) { 0 }

      it "should not exit" do
        @knife.should_not_receive(:exit)
        @knife.run
      end
    end
  end
end
