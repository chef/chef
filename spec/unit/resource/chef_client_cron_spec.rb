#
# Author:: Tim Smith (<tsmith@chef.io>)
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

require "spec_helper"

describe Chef::Resource::ChefClientCron do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::ChefClientCron.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:add) }

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end

  it "supports :add and :remove actions" do
    expect { resource.action :add }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  it "coerces splay to an Integer" do
    resource.splay "10"
    expect(resource.splay).to eql(10)
  end

  it "raises an error if splay is not a positive number" do
    expect { resource.splay("-10") }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "builds a default value for chef_binary_path dist values" do
    expect(resource.chef_binary_path).to eql("/opt/chef/bin/chef-client")
  end

  it "raises an error if nice is less than -20" do
    expect { resource.nice(-21) }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "raises an error if nice is greater than 19" do
    expect { resource.nice(20) }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "coerces nice to an Integer" do
    resource.nice "10"
    expect(resource.nice).to eql(10)
  end

  it "log_directory is /Library/Logs/Chef on macOS systems" do
    node.automatic_attrs[:platform_family] = "mac_os_x"
    node.automatic_attrs[:platform] = "mac_os_x"
    expect(resource.log_directory).to eql("/Library/Logs/Chef")
  end

  it "log_directory is /var/log/chef on non-macOS systems" do
    node.automatic_attrs[:platform_family] = "ubuntu"
    expect(resource.log_directory).to eql("/var/log/chef")
  end

  describe "#splay_sleep_time" do
    it "uses shard_seed attribute if present" do
      node.automatic_attrs[:shard_seed] = "73399073"
      expect(provider.splay_sleep_time(300)).to satisfy { |v| v >= 0 && v <= 300 }
    end

    it "uses a hex conversion of a md5 hash of the splay if present" do
      node.automatic_attrs[:shard_seed] = nil
      allow(node).to receive(:name).and_return("test_node")
      expect(provider.splay_sleep_time(300)).to satisfy { |v| v >= 0 && v <= 300 }
    end
  end

  describe "#client_command" do
    before do
      allow(provider).to receive(:splay_sleep_time).and_return("123")
    end

    let(:root_path) { windows? ? "C:\\chef/client.rb" : "/etc/chef/client.rb" }

    it "creates a valid command if using all default properties" do
      expect(provider.client_command).to eql(
        "/bin/sleep 123; /opt/chef/bin/chef-client -c #{root_path} >> /var/log/chef/client.log 2>&1"
      )
    end

    it "uses daemon_options if set" do
      resource.daemon_options ["--foo 1", "--bar 2"]
      expect(provider.client_command).to eql(
        "/bin/sleep 123; /opt/chef/bin/chef-client --foo 1 --bar 2 -c #{root_path} >> /var/log/chef/client.log 2>&1"
      )
    end

    it "uses custom config dir if set" do
      resource.config_directory "/etc/some_other_dir"
      expect(provider.client_command).to eql("/bin/sleep 123; /opt/chef/bin/chef-client -c /etc/some_other_dir/client.rb >> /var/log/chef/client.log 2>&1")
    end

    it "uses custom log files / paths if set" do
      resource.log_file_name "my-client.log"
      resource.log_directory "/var/log/my-chef/"
      expect(provider.client_command).to eql(
        "/bin/sleep 123; /opt/chef/bin/chef-client -c #{root_path} >> /var/log/my-chef/my-client.log 2>&1"
      )
    end

    it "uses mailto if set" do
      resource.mailto "bob@example.com"
      expect(provider.client_command).to eql(
        "/bin/sleep 123; /opt/chef/bin/chef-client -c #{root_path} >> /var/log/chef/client.log 2>&1 || echo \"Chef Infra Client execution failed\""
      )
    end

    it "uses custom chef-client binary if set" do
      resource.chef_binary_path "/usr/local/bin/chef-client"
      expect(provider.client_command).to eql(
        "/bin/sleep 123; /usr/local/bin/chef-client -c #{root_path} >> /var/log/chef/client.log 2>&1"
      )
    end

    it "appends to the log file appending if set to false" do
      resource.append_log_file false
      expect(provider.client_command).to eql(
        "/bin/sleep 123; /opt/chef/bin/chef-client -c #{root_path} > /var/log/chef/client.log 2>&1"
      )
    end

    it "sets the license acceptance flag if set" do
      resource.accept_chef_license true
      expect(provider.client_command).to eql(
        "/bin/sleep 123; /opt/chef/bin/chef-client -c #{root_path} --chef-license accept >> /var/log/chef/client.log 2>&1"
      )
    end

    it "uses nice if set" do
      allow(provider).to receive(:which).with("nice").and_return("/usr/bin/nice")
      resource.nice(-15)
      expect(provider.client_command).to eql(
        "/bin/sleep 123; /usr/bin/nice -n -15 /opt/chef/bin/chef-client -c #{root_path} >> /var/log/chef/client.log 2>&1"
      )
    end
  end
end
