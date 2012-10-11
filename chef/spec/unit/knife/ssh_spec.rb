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
    @knife.config.clear
    @knife.config[:attribute] = "fqdn"
    @node_foo = Chef::Node.new('foo')
    @node_foo[:fqdn] = "foo.example.org"
    @node_foo[:ipaddress] = "10.0.0.1"
    @node_bar = Chef::Node.new('bar')
    @node_bar[:fqdn] = "bar.example.org"
    @node_bar[:ipaddress] = "10.0.0.2"
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
          @node_foo[:cloud] = Mash.new
          @node_bar[:cloud] = Mash.new
          @node_foo[:cloud][:public_hostname] = "ec2-10-0-0-1.compute-1.amazonaws.com"
          @node_bar[:cloud][:public_hostname] = "ec2-10-0-0-2.compute-1.amazonaws.com"
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

end

