#
# Author:: Bryan McLellan <btm@chef.io>
# Copyright:: Copyright (c) Chef Software Inc.
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

require "knife_spec_helper"
require "net/ssh"
require "net/ssh/multi"

describe Chef::Knife::Ssh do
  let(:query_result) { double("chef search results") }

  before do
    Chef::Config[:client_key] = CHEF_SPEC_DATA + "/ssl/private_key.pem"
    @knife = Chef::Knife::Ssh.new
    @knife.merge_configs
    @node_foo = {}
    @node_foo["fqdn"] = "foo.example.org"
    @node_foo["ipaddress"] = "10.0.0.1"
    @node_foo["cloud"] = {}

    @node_bar = {}
    @node_bar["fqdn"] = "bar.example.org"
    @node_bar["ipaddress"] = "10.0.0.2"
    @node_bar["cloud"] = {}

  end

  describe "#configure_session" do
    context "manual is set to false (default)" do
      before do
        @knife.config[:manual] = false
        allow(query_result).to receive(:search).with(any_args).and_yield(@node_foo).and_yield(@node_bar)
        allow(Chef::Search::Query).to receive(:new).and_return(query_result)
      end

      def self.should_return_specified_attributes
        it "returns an array of the attributes specified on the command line OR config file, if only one is set" do
          @node_bar["target"] = "10.0.0.2"
          @node_foo["target"] = "10.0.0.1"
          @node_bar["prefix"] = "bar"
          @node_foo["prefix"] = "foo"
          @knife.config[:ssh_attribute] = "ipaddress"
          @knife.config[:prefix_attribute] = "name"
          Chef::Config[:knife][:ssh_attribute] = "ipaddress" # this value will be in the config file
          Chef::Config[:knife][:prefix_attribute] = "name" # this value will be in the config file
          expect(@knife).to receive(:session_from_list).with([["10.0.0.1", nil, "foo"], ["10.0.0.2", nil, "bar"]])
          @knife.configure_session
        end

        it "returns an array of the attributes specified on the command line even when a config value is set" do
          @node_bar["target"] = "10.0.0.2"
          @node_foo["target"] = "10.0.0.1"
          @node_bar["prefix"] = "bar"
          @node_foo["prefix"] = "foo"
          Chef::Config[:knife][:ssh_attribute] = "config_file" # this value will be in the config file
          Chef::Config[:knife][:prefix_attribute] = "config_file" # this value will be in the config file
          @knife.config[:ssh_attribute] = "ipaddress" # this is the value of the command line via #configure_attribute
          @knife.config[:prefix_attribute] = "name" # this is the value of the command line via #configure_attribute
          expect(@knife).to receive(:session_from_list).with([["10.0.0.1", nil, "foo"], ["10.0.0.2", nil, "bar"]])
          @knife.configure_session
        end
      end

      it "searches for and returns an array of fqdns" do
        expect(@knife).to receive(:session_from_list).with([
          ["foo.example.org", nil, nil],
          ["bar.example.org", nil, nil],
        ])
        @knife.configure_session
      end

      should_return_specified_attributes

      context "when cloud hostnames are available" do
        before do
          @node_foo["cloud"]["public_hostname"] = "ec2-10-0-0-1.compute-1.amazonaws.com"
          @node_bar["cloud"]["public_hostname"] = "ec2-10-0-0-2.compute-1.amazonaws.com"
        end
        it "returns an array of cloud public hostnames" do
          expect(@knife).to receive(:session_from_list).with([
            ["ec2-10-0-0-1.compute-1.amazonaws.com", nil, nil],
            ["ec2-10-0-0-2.compute-1.amazonaws.com", nil, nil],
          ])
          @knife.configure_session
        end

        should_return_specified_attributes
      end

      context "when cloud hostnames are available but empty" do
        before do
          @node_foo["cloud"]["public_hostname"] = ""
          @node_bar["cloud"]["public_hostname"] = ""
        end

        it "returns an array of fqdns" do
          expect(@knife).to receive(:session_from_list).with([
            ["foo.example.org", nil, nil],
            ["bar.example.org", nil, nil],
          ])
          @knife.configure_session
        end

        should_return_specified_attributes
      end

      it "should raise an error if no host are found" do
        allow(query_result).to receive(:search).with(any_args)
        expect(@knife.ui).to receive(:fatal)
        expect(@knife).to receive(:exit).with(10)
        @knife.configure_session
      end

      context "when there are some hosts found but they do not have an attribute to connect with" do
        before do
          @node_foo["fqdn"] = nil
          @node_bar["fqdn"] = nil
        end

        it "should raise a specific error (CHEF-3402)" do
          expect(@knife.ui).to receive(:fatal).with(/^2 nodes found/)
          expect(@knife).to receive(:exit).with(10)
          @knife.configure_session
        end
      end

      context "when there are some hosts found but IPs duplicated if duplicated_fqdns option sets :fatal" do
        before do
          @knife.config[:duplicated_fqdns] = :fatal
          @node_foo["fqdn"] = "foo.example.org"
          @node_bar["fqdn"] = "foo.example.org"
        end

        it "should raise a specific error" do
          expect(@knife.ui).to receive(:fatal).with(/^SSH node is duplicated: foo\.example\.org/)
          expect(@knife).to receive(:exit).with(10)
          expect(@knife).to receive(:session_from_list).with([
            ["foo.example.org", nil, nil],
            ["foo.example.org", nil, nil],
          ])
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
        expect(@knife).to receive(:session_from_list).with(["foo.example.org", "bar.example.org"])
        @knife.configure_session
      end
    end
  end

  describe "#get_prefix_attribute" do
    # Order of precedence for prefix
    # 1) config value (cli or knife config)
    # 2) nil
    before do
      Chef::Config[:knife][:prefix_attribute] = nil
      @knife.config[:prefix_attribute] = nil
      @node_foo["cloud"]["public_hostname"] = "ec2-10-0-0-1.compute-1.amazonaws.com"
      @node_bar["cloud"]["public_hostname"] = ""
    end

    it "should return nil by default" do
      expect(@knife.get_prefix_attribute({})).to eq(nil)
    end

    it "should favor config over nil" do
      @node_foo["prefix"] = "config"
      expect( @knife.get_prefix_attribute(@node_foo)).to eq("config")
    end
  end

  describe "#get_ssh_attribute" do
    # Order of precedence for ssh target
    # 1) config value (cli or knife config)
    # 2) cloud attribute
    # 3) fqdn
    before do
      Chef::Config[:knife][:ssh_attribute] = nil
      @knife.config[:ssh_attribute] = nil
      @node_foo["cloud"]["public_hostname"] = "ec2-10-0-0-1.compute-1.amazonaws.com"
      @node_bar["cloud"]["public_hostname"] = ""
    end

    it "should return fqdn by default" do
      expect(@knife.get_ssh_attribute({ "fqdn" => "fqdn" })).to eq("fqdn")
    end

    it "should return cloud.public_hostname attribute if available" do
      expect(@knife.get_ssh_attribute(@node_foo)).to eq("ec2-10-0-0-1.compute-1.amazonaws.com")
    end

    it "should favor config over cloud and default" do
      @node_foo["target"] = "config"
      expect( @knife.get_ssh_attribute(@node_foo)).to eq("config")
    end

    it "should return fqdn if cloud.hostname is empty" do
      expect( @knife.get_ssh_attribute(@node_bar)).to eq("bar.example.org")
    end
  end

  describe "#session_from_list" do
    before :each do
      @knife.instance_variable_set(:@longest, 0)
      ssh_config = { timeout: 50, user: "locutus", port: 23, keepalive: true, keepalive_interval: 60 }
      allow(Net::SSH).to receive(:configuration_for).with("the.b.org", true).and_return(ssh_config)
    end

    it "uses the port from an ssh config file" do
      @knife.session_from_list([["the.b.org", nil, nil]])
      expect(@knife.session.servers[0].port).to eq(23)
    end

    it "uses the port from a cloud attr" do
      @knife.session_from_list([["the.b.org", 123, nil]])
      expect(@knife.session.servers[0].port).to eq(123)
    end

    it "uses the prefix from list" do
      @knife.session_from_list([["the.b.org", nil, "b-team"]])
      expect(@knife.session.servers[0][:prefix]).to eq("b-team")
    end

    it "defaults to a prefix of host" do
      @knife.session_from_list([["the.b.org", nil, nil]])
      expect(@knife.session.servers[0][:prefix]).to eq("the.b.org")
    end

    it "defaults to a timeout of 120 seconds" do
      @knife.session_from_list([["the.b.org", nil, nil]])
      expect(@knife.session.servers[0].options[:timeout]).to eq(120)
    end

    it "uses the timeout from the CLI" do
      @knife.config = {}
      Chef::Config[:knife][:ssh_timeout] = nil
      @knife.config[:ssh_timeout] = 5
      @knife.session_from_list([["the.b.org", nil, nil]])
      @knife.merge_configs
      expect(@knife.session.servers[0].options[:timeout]).to eq(5)
    end

    it "uses the timeout from knife config" do
      @knife.config = {}
      Chef::Config[:knife][:ssh_timeout] = 6
      @knife.merge_configs
      @knife.session_from_list([["the.b.org", nil, nil]])
      expect(@knife.session.servers[0].options[:timeout]).to eq(6)
    end

    it "uses the user from an ssh config file" do
      @knife.session_from_list([["the.b.org", 123, nil]])
      expect(@knife.session.servers[0].user).to eq("locutus")
    end

    it "uses keepalive settings from an ssh config file" do
      @knife.session_from_list([["the.b.org", 123, nil]])
      expect(@knife.session.servers[0].options[:keepalive]).to be true
      expect(@knife.session.servers[0].options[:keepalive_interval]).to eq 60
    end
  end

  describe "#ssh_command" do
    let(:execution_channel) { double(:execution_channel, on_data: nil, on_extended_data: nil) }
    let(:session_channel) { double(:session_channel, request_pty: nil) }

    let(:execution_channel2) { double(:execution_channel, on_data: nil, on_extended_data: nil) }
    let(:session_channel2) { double(:session_channel, request_pty: nil) }

    let(:session) { double(:session, loop: nil) }

    let(:command) { "false" }

    before do
      expect(execution_channel)
        .to receive(:on_request)
        .and_yield(nil, double(:data_stream, read_long: exit_status))

      expect(session_channel)
        .to receive(:exec)
        .with(command)
        .and_yield(execution_channel, true)

      expect(execution_channel2)
        .to receive(:on_request)
        .and_yield(nil, double(:data_stream, read_long: exit_status2))

      expect(session_channel2)
        .to receive(:exec)
        .with(command)
        .and_yield(execution_channel2, true)

      expect(session)
        .to receive(:open_channel)
        .and_yield(session_channel)
        .and_yield(session_channel2)
    end

    context "both connections return 0" do
      let(:exit_status) { 0 }
      let(:exit_status2) { 0 }

      it "returns a 0 exit code" do
        expect(@knife.ssh_command(command, session)).to eq(0)
      end
    end

    context "the first connection returns 1 and the second returns 0" do
      let(:exit_status) { 1 }
      let(:exit_status2) { 0 }

      it "returns a non-zero exit code" do
        expect(@knife.ssh_command(command, session)).to eq(1)
      end
    end

    context "the first connection returns 1 and the second returns 2" do
      let(:exit_status) { 1 }
      let(:exit_status2) { 2 }

      it "returns a non-zero exit code" do
        expect(@knife.ssh_command(command, session)).to eq(2)
      end
    end
  end

  describe "#tmux" do
    before do
      ssh_config = { timeout: 50, user: "locutus", port: 23, keepalive: true, keepalive_interval: 60 }
      allow(Net::SSH).to receive(:configuration_for).with("foo.example.org", true).and_return(ssh_config)
      @query = Chef::Search::Query.new
      expect(@query).to receive(:search).and_yield(@node_foo)
      allow(Chef::Search::Query).to receive(:new).and_return(@query)
      allow(@knife).to receive(:exec).and_return(0)
    end

    it "filters out invalid characters from tmux session name" do
      @knife.name_args = ["name:foo.example.org", "tmux"]
      expect(@knife).to receive(:shell_out!).with("tmux new-session -d -s 'knife ssh name=foo-example-org' -n 'foo.example.org' 'ssh locutus@foo.example.org' ")
      @knife.run
    end
  end

  describe "#run" do

    it "should print usage and exit when a SEARCH QUERY is not provided" do
      @knife.name_args = []
      expect(@knife).to receive(:show_usage)
      expect(@knife.ui).to receive(:fatal).with(/You must specify the SEARCH QUERY./)
      expect { @knife.run }.to raise_error(SystemExit)
    end

    context "exit" do
      before do
        @query = Chef::Search::Query.new
        expect(@query).to receive(:search).and_yield(@node_foo)
        allow(Chef::Search::Query).to receive(:new).and_return(@query)
        allow(@knife).to receive(:ssh_command).and_return(exit_code)
        @knife.name_args = ["*:*", "false"]
      end

      context "with an error" do
        let(:exit_code) { 1 }

        it "should exit with a non-zero exit code" do
          expect(@knife).to receive(:exit).with(exit_code)
          @knife.run
        end
      end

      context "with no error" do
        let(:exit_code) { 0 }

        it "should not exit" do
          expect(@knife).not_to receive(:exit)
          @knife.run
        end
      end
    end
  end
end
