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

describe Chef::Knife::Ssh do

  before(:all) do
    Chef::Knife::Ssh.load_deps
    @server = TinyServer::Manager.new
    @server.start
  end

  after(:all) do
    @server.stop
  end

  describe "identity file" do
    context "when knife[:ssh_identity_file] is set" do
      before do
        setup_knife(['*:*', 'uptime'])
        Chef::Config[:knife][:ssh_identity_file] = "~/.ssh/aws.rsa"
      end

      it "uses the ssh_identity_file" do
        @knife.run
        @knife.config[:identity_file].should == "~/.ssh/aws.rsa"
      end
    end

    context "when knife[:ssh_identity_file] is set and frozen" do
      before do
        setup_knife(['*:*', 'uptime'])
        Chef::Config[:knife][:ssh_identity_file] = "~/.ssh/aws.rsa".freeze
      end

      it "uses the ssh_identity_file" do
        @knife.run
        @knife.config[:identity_file].should == "~/.ssh/aws.rsa"
      end
    end

    context "when -i is provided" do
      before do
        setup_knife(['-i ~/.ssh/aws.rsa', '*:*', 'uptime'])
        Chef::Config[:knife][:ssh_identity_file] = nil
      end

      it "should use the value on the command line" do
        @knife.run
        @knife.config[:identity_file].should == "~/.ssh/aws.rsa"
      end

      it "should override what is set in knife.rb" do
        Chef::Config[:knife][:ssh_identity_file] = "~/.ssh/other.rsa"
        @knife.run
        @knife.config[:identity_file].should == "~/.ssh/aws.rsa"
      end
    end

    context "when knife[:ssh_identity_file] is not provided]" do
      before do
        setup_knife(['*:*', 'uptime'])
        Chef::Config[:knife][:ssh_identity_file] = nil
      end

      it "uses the default" do
        @knife.run
        @knife.config[:identity_file].should == nil
      end
    end
  end

  describe "port" do
    context "when -p 31337 is provided" do
      before do
        setup_knife(['-p 31337', '*:*', 'uptime'])
      end

      it "uses the ssh_port" do
        @knife.run
        @knife.config[:ssh_port].should == "31337"
      end
    end
  end

  describe "user" do
    context "when knife[:ssh_user] is set" do
      before do
        setup_knife(['*:*', 'uptime'])
        Chef::Config[:knife][:ssh_user] = "ubuntu"
      end

      it "uses the ssh_user" do
        @knife.run
        @knife.config[:ssh_user].should == "ubuntu"
      end
    end

    context "when knife[:ssh_user] is set and frozen" do
      before do
        setup_knife(['*:*', 'uptime'])
        Chef::Config[:knife][:ssh_user] = "ubuntu".freeze
      end

      it "uses the ssh_user" do
        @knife.run
        @knife.config[:ssh_user].should == "ubuntu"
      end
    end

    context "when -x is provided" do
      before do
        setup_knife(['-x ubuntu', '*:*', 'uptime'])
        Chef::Config[:knife][:ssh_user] = nil
      end

      it "should use the value on the command line" do
        @knife.run
        @knife.config[:ssh_user].should == "ubuntu"
      end

      it "should override what is set in knife.rb" do
        Chef::Config[:knife][:ssh_user] = "root"
        @knife.run
        @knife.config[:ssh_user].should == "ubuntu"
      end
    end

    context "when knife[:ssh_user] is not provided]" do
      before do
        setup_knife(['*:*', 'uptime'])
        Chef::Config[:knife][:ssh_user] = nil
      end

      it "uses the default (current user)" do
        @knife.run
        @knife.config[:ssh_user].should == nil
      end
    end
  end

  describe "attribute" do
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

    context "when knife[:ssh_attribute] is not provided]" do
      before do
        setup_knife(['*:*', 'uptime'])
        Chef::Config[:knife][:ssh_attribute] = nil
      end

      it "uses the default" do
        @knife.run
        @knife.config[:attribute].should == "fqdn"
      end
    end

    context "when -a ec2.public_ipv4 is provided" do
      before do
        setup_knife(['-a ec2.public_hostname', '*:*', 'uptime'])
        Chef::Config[:knife][:ssh_attribute] = nil
      end

      it "should use the value on the command line" do
        @knife.run
        @knife.config[:attribute].should == "ec2.public_hostname"
      end

      it "should override what is set in knife.rb" do
        # This is the setting imported from knife.rb
        Chef::Config[:knife][:ssh_attribute] = "fqdn"
        # Then we run knife with the -a flag, which sets the above variable
        setup_knife(['-a ec2.public_hostname', '*:*', 'uptime'])
        @knife.run
        @knife.config[:attribute].should == "ec2.public_hostname"
      end
    end
  end

  describe "gateway" do
    context "when knife[:ssh_gateway] is set" do
      before do
        setup_knife(['*:*', 'uptime'])
        Chef::Config[:knife][:ssh_gateway] = "user@ec2.public_hostname"
      end

      it "uses the ssh_gateway" do
        @knife.session.should_receive(:via).with("ec2.public_hostname", "user", {})
        @knife.run
        @knife.config[:ssh_gateway].should == "user@ec2.public_hostname"
      end
    end

    context "when -G user@ec2.public_hostname is provided" do
      before do
        setup_knife(['-G user@ec2.public_hostname', '*:*', 'uptime'])
        Chef::Config[:knife][:ssh_gateway] = nil
      end

      it "uses the ssh_gateway" do
        @knife.session.should_receive(:via).with("ec2.public_hostname", "user", {})
        @knife.run
        @knife.config[:ssh_gateway].should == "user@ec2.public_hostname"
      end
    end

    context "when the gateway requires a password" do
      before do
        setup_knife(['-G user@ec2.public_hostname', '*:*', 'uptime'])
        Chef::Config[:knife][:ssh_gateway] = nil
        @knife.session.stub(:via) do |host, user, options|
          raise Net::SSH::AuthenticationFailed unless options[:password]
        end
      end

      it "should prompt the user for a password" do
        @knife.ui.should_receive(:ask).with("Enter the password for user@ec2.public_hostname: ").and_return("password")
        @knife.run
      end
    end
  end

  def setup_knife(params=[])
    @knife = Chef::Knife::Ssh.new(params)
    # We explicitly avoid running #configure_chef, which would read a knife.rb
    # if available, but #merge_configs (which is called by #configure_chef) is
    # necessary to have default options merged in.
    @knife.merge_configs
    @knife.stub!(:ssh_command).and_return { 0 }
    @api = TinyServer::API.instance
    @api.clear

    Chef::Config[:node_name] = nil
    Chef::Config[:client_key] = nil
    Chef::Config[:chef_server_url] = 'http://localhost:9000'

    @api.get("/search/node?q=*:*&sort=X_CHEF_id_CHEF_X%20asc&start=0&rows=1000", 200) {
      %({"total":1, "start":0, "rows":[{"name":"i-xxxxxxxx", "json_class":"Chef::Node", "automatic":{"fqdn":"the.fqdn", "ec2":{"public_hostname":"the_public_hostname"}},"recipes":[]}]})
    }
  end

end
