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
  before(:each) do
    Chef::Config[:client_key] = CHEF_SPEC_DATA + "/ssl/private_key.pem"
  end

  before do
    @knife = Chef::Knife::Ssh.new
    @knife.merge_configs
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
        allow(@query).to receive(:search).and_return([node_array])
        allow(Chef::Search::Query).to receive(:new).and_return(@query)
      end

      def self.should_return_specified_attributes
        it "returns an array of the attributes specified on the command line OR config file, if only one is set" do
          @knife.config[:attribute] = "ipaddress"
          @knife.config[:attribute_from_cli] = "ipaddress"
          configure_query([@node_foo, @node_bar])
          expect(@knife).to receive(:session_from_list).with([['10.0.0.1', nil], ['10.0.0.2', nil]])
          @knife.configure_session
        end

        it "returns an array of the attributes specified on the command line even when a config value is set" do
          @knife.config[:attribute] = "config_file" # this value will be the config file
          @knife.config[:attribute_from_cli] = "ipaddress" # this is the value of the command line via #configure_attribute
          configure_query([@node_foo, @node_bar])
          expect(@knife).to receive(:session_from_list).with([['10.0.0.1', nil], ['10.0.0.2', nil]])
          @knife.configure_session
        end
      end

      it "searchs for and returns an array of fqdns" do
        configure_query([@node_foo, @node_bar])
        expect(@knife).to receive(:session_from_list).with([
          ['foo.example.org', nil],
          ['bar.example.org', nil]
        ])
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
          expect(@knife).to receive(:session_from_list).with([
            ['ec2-10-0-0-1.compute-1.amazonaws.com', nil],
            ['ec2-10-0-0-2.compute-1.amazonaws.com', nil]
          ])
          @knife.configure_session
        end

        should_return_specified_attributes
      end

      context "when cloud hostnames are available but empty" do
        before do
          @node_foo.automatic_attrs[:cloud][:public_hostname] = ''
          @node_bar.automatic_attrs[:cloud][:public_hostname] = ''
        end

        it "returns an array of fqdns" do
          configure_query([@node_foo, @node_bar])
          expect(@knife).to receive(:session_from_list).with([
            ['foo.example.org', nil],
            ['bar.example.org', nil]
          ])
          @knife.configure_session
        end

        should_return_specified_attributes
      end

      it "should raise an error if no host are found" do
          configure_query([ ])
          expect(@knife.ui).to receive(:fatal)
          expect(@knife).to receive(:exit).with(10)
          @knife.configure_session
      end

      context "when there are some hosts found but they do not have an attribute to connect with" do
        before do
          allow(@query).to receive(:search).and_return([[@node_foo, @node_bar]])
          @node_foo.automatic_attrs[:fqdn] = nil
          @node_bar.automatic_attrs[:fqdn] = nil
          allow(Chef::Search::Query).to receive(:new).and_return(@query)
        end

        it "should raise a specific error (CHEF-3402)" do
          expect(@knife.ui).to receive(:fatal).with(/^2 nodes found/)
          expect(@knife).to receive(:exit).with(10)
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
        expect(@knife).to receive(:session_from_list).with(['foo.example.org', 'bar.example.org'])
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
      expect(@knife.config[:attribute]).to eq("fqdn")
    end

    it "should return the value set in the configuration file" do
      Chef::Config[:knife][:ssh_attribute] = "config_file"
      @knife.configure_attribute
      expect(@knife.config[:attribute]).to eq("config_file")
    end

    it "should return the value set on the command line" do
      @knife.config[:attribute] = "command_line"
      @knife.configure_attribute
      expect(@knife.config[:attribute]).to eq("command_line")
    end

    it "should set attribute_from_cli to the value of attribute from the command line" do
      @knife.config[:attribute] = "command_line"
      @knife.configure_attribute
      expect(@knife.config[:attribute]).to eq("command_line")
      expect(@knife.config[:attribute_from_cli]).to eq("command_line")
    end

    it "should prefer the command line over the config file for the value of attribute_from_cli" do
      Chef::Config[:knife][:ssh_attribute] = "config_file"
      @knife.config[:attribute] = "command_line"
      @knife.configure_attribute
      expect(@knife.config[:attribute]).to eq("command_line")
      expect(@knife.config[:attribute_from_cli]).to eq("command_line")
    end
  end

  describe "#session_from_list" do
    before :each do
      @knife.instance_variable_set(:@longest, 0)
      ssh_config = {:timeout => 50, :user => "locutus", :port => 23 }
      allow(Net::SSH).to receive(:configuration_for).with('the.b.org').and_return(ssh_config)
    end

    it "uses the port from an ssh config file" do
      @knife.session_from_list([['the.b.org', nil]])
      expect(@knife.session.servers[0].port).to eq(23)
    end

    it "uses the port from a cloud attr" do
      @knife.session_from_list([['the.b.org', 123]])
      expect(@knife.session.servers[0].port).to eq(123)
    end

    it "uses the user from an ssh config file" do
      @knife.session_from_list([['the.b.org', 123]])
      expect(@knife.session.servers[0].user).to eq("locutus")
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
      expect(execution_channel).
        to receive(:on_request).
        and_yield(nil, double(:data_stream, :read_long => exit_status))

      expect(session_channel).
        to receive(:exec).
        with(command).
        and_yield(execution_channel, true)

      expect(execution_channel2).
        to receive(:on_request).
        and_yield(nil, double(:data_stream, :read_long => exit_status2))

      expect(session_channel2).
        to receive(:exec).
        with(command).
        and_yield(execution_channel2, true)

      expect(session).
        to receive(:open_channel).
        and_yield(session_channel).
        and_yield(session_channel2)
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

  describe "#run" do
    before do
      @query = Chef::Search::Query.new
      expect(@query).to receive(:search).and_return([[@node_foo]])
      allow(Chef::Search::Query).to receive(:new).and_return(@query)
      allow(@knife).to receive(:ssh_command).and_return(exit_code)
      @knife.name_args = ['*:*', 'false']
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

  describe "#configure_password" do
    before do
      @knife.config.delete(:ssh_password_ng)
      @knife.config.delete(:ssh_password)
    end

    context "when setting ssh_password_ng from knife ssh" do
      # in this case ssh_password_ng exists, but ssh_password does not
      it "should prompt for a password when ssh_passsword_ng is nil"  do
        @knife.config[:ssh_password_ng] = nil
        expect(@knife).to receive(:get_password).and_return("mysekretpassw0rd")
        @knife.configure_password
        expect(@knife.config[:ssh_password]).to eq("mysekretpassw0rd")
      end

      it "should set ssh_password to false if ssh_password_ng is false"  do
        @knife.config[:ssh_password_ng] = false
        expect(@knife).not_to receive(:get_password)
        @knife.configure_password
        expect(@knife.config[:ssh_password]).to be_falsey
      end

      it "should set ssh_password to ssh_password_ng if we set a password" do
        @knife.config[:ssh_password_ng] = "mysekretpassw0rd"
        expect(@knife).not_to receive(:get_password)
        @knife.configure_password
        expect(@knife.config[:ssh_password]).to eq("mysekretpassw0rd")
      end
    end

    context "when setting ssh_password from knife bootstrap / knife * server create" do
      # in this case ssh_password exists, but ssh_password_ng does not
      it "should set ssh_password to nil when ssh_password is nil" do
        @knife.config[:ssh_password] = nil
        expect(@knife).not_to receive(:get_password)
        @knife.configure_password
        expect(@knife.config[:ssh_password]).to be_nil
      end

      it "should set ssh_password to false when ssh_password is false" do
        @knife.config[:ssh_password] = false
        expect(@knife).not_to receive(:get_password)
        @knife.configure_password
        expect(@knife.config[:ssh_password]).to be_falsey
      end

      it "should set ssh_password to ssh_password if we set a password" do
        @knife.config[:ssh_password] = "mysekretpassw0rd"
        expect(@knife).not_to receive(:get_password)
        @knife.configure_password
        expect(@knife.config[:ssh_password]).to eq("mysekretpassw0rd")
      end
    end
    context "when setting ssh_password in the config variable" do
      before(:each) do
        Chef::Config[:knife][:ssh_password] = "my_knife_passw0rd"
      end
      context "when setting ssh_password_ng from knife ssh" do
        # in this case ssh_password_ng exists, but ssh_password does not
        it "should prompt for a password when ssh_passsword_ng is nil"  do
          @knife.config[:ssh_password_ng] = nil
          expect(@knife).to receive(:get_password).and_return("mysekretpassw0rd")
          @knife.configure_password
          expect(@knife.config[:ssh_password]).to eq("mysekretpassw0rd")
        end

        it "should set ssh_password to the configured knife.rb value if ssh_password_ng is false"  do
          @knife.config[:ssh_password_ng] = false
          expect(@knife).not_to receive(:get_password)
          @knife.configure_password
          expect(@knife.config[:ssh_password]).to eq("my_knife_passw0rd")
        end

        it "should set ssh_password to ssh_password_ng if we set a password" do
          @knife.config[:ssh_password_ng] = "mysekretpassw0rd"
          expect(@knife).not_to receive(:get_password)
          @knife.configure_password
          expect(@knife.config[:ssh_password]).to eq("mysekretpassw0rd")
        end
      end

      context "when setting ssh_password from knife bootstrap / knife * server create" do
        # in this case ssh_password exists, but ssh_password_ng does not
        it "should set ssh_password to the configured knife.rb value when ssh_password is nil" do
          @knife.config[:ssh_password] = nil
          expect(@knife).not_to receive(:get_password)
          @knife.configure_password
          expect(@knife.config[:ssh_password]).to eq("my_knife_passw0rd")
        end

        it "should set ssh_password to the configured knife.rb value when ssh_password is false" do
          @knife.config[:ssh_password] = false
          expect(@knife).not_to receive(:get_password)
          @knife.configure_password
          expect(@knife.config[:ssh_password]).to eq("my_knife_passw0rd")
        end

        it "should set ssh_password to ssh_password if we set a password" do
          @knife.config[:ssh_password] = "mysekretpassw0rd"
          expect(@knife).not_to receive(:get_password)
          @knife.configure_password
          expect(@knife.config[:ssh_password]).to eq("mysekretpassw0rd")
        end
      end
    end
  end
end
