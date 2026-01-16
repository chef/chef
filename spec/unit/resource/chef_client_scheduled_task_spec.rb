#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Chef::Resource::ChefClientScheduledTask do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::ChefClientScheduledTask.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:add) }
  let(:chef_habitat_binary_path) { "C:/hab/pkgs/chef/chef-infra-client/19.2.7/20250122151044/bin/chef-client" }

  before do
    # Stub the chef_binary_path property to return the Habitat path
    allow(resource).to receive(:chef_binary_path).and_return(chef_habitat_binary_path)
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("COMSPEC").and_return("C:\\Windows\\System32\\cmd.exe")
  end

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end

  it "coerces splay to an Integer" do
    resource.splay "10"
    expect(resource.splay).to eql(10)
  end

  it "raises an error if splay is not a positive number" do
    expect { resource.splay("-10") }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "set splay to 0" do
    resource.splay "0"
    expect(resource.splay).to eql(0)
  end

  it "coerces frequency_modifier to an Integer" do
    resource.frequency_modifier "10"
    expect(resource.frequency_modifier).to eql(10)
  end

  it "expects default frequency modifier to be 30 when frequency is set to 'minute'" do
    resource.frequency "minute"
    expect(resource.frequency_modifier).to eql(30)
  end

  it "expects default frequency modifier to be 1 when frequency is set to 'daily'" do
    resource.frequency "daily"
    expect(resource.frequency_modifier).to eql(1)
  end

  it "validates the start_time property input" do
    expect { resource.start_time("8:00 am") }.to raise_error(Chef::Exceptions::ValidationFailed)
    expect { resource.start_time("8:00") }.to raise_error(Chef::Exceptions::ValidationFailed)
    expect { resource.start_time("08:00") }.not_to raise_error
  end

  it "validates the start_date property input" do
    expect { resource.start_date("2/1/20") }.to raise_error(Chef::Exceptions::ValidationFailed)
    expect { resource.start_date("02/01/20") }.to raise_error(Chef::Exceptions::ValidationFailed)
    expect { resource.start_date("02/01/2020") }.not_to raise_error
  end

  it "raises an error if frequency_modifier is not a positive number" do
    expect { resource.frequency_modifier("-10") }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "builds a default value for chef_binary_path dist values" do
    expect(resource.chef_binary_path).to eql(chef_habitat_binary_path)
  end

  context "priority" do
    it "default value is 7" do
      expect(resource.priority).to eq(7)
    end

    it "raise error when priority value less than 0" do
      expect { resource.priority(-1) }.to raise_error(Chef::Exceptions::ValidationFailed, "Option priority's value -1 should be in range of 0 to 10!")
    end

    it "raise error when priority values is greater than 10" do
      expect { resource.priority 11 }.to raise_error(Chef::Exceptions::ValidationFailed, "Option priority's value 11 should be in range of 0 to 10!")
    end
  end

  it "supports :add and :remove actions" do
    expect { resource.action :add }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  it "expects use_consistent_splay to be true when set" do
    resource.use_consistent_splay = true
    expect(resource.use_consistent_splay).to eql(true)
  end

  context "when configured to use a consistent splay" do
    before do
      node.automatic_attrs[:shard_seed] = nil
      allow(node).to receive(:name).and_return("test_node")
      resource.config_directory = "C:/chef" # Allows local unit testing on nix flavors
      resource.use_consistent_splay = true
    end

    it "sleeps the same amount each time based on splay before running the task" do
      expect(provider.full_command).to eql("C:\\Windows\\System32\\cmd.exe /c \"C:/windows/system32/windowspowershell/v1.0/powershell.exe Start-Sleep -s 272 && #{chef_habitat_binary_path} -L C:/chef/log/client.log -c C:/chef/client.rb\"")
    end
  end

  describe "#consistent_splay_command" do
    context "when use_consistent_splay is false" do
      it "returns nil" do
        expect(provider.consistent_splay_command).to eql(nil)
      end
    end

    context "when use_consistent_splay is true" do
      before do
        resource.use_consistent_splay true
        allow(provider).to receive(:splay_sleep_time).and_return(222)
      end

      it "returns a powershell sleep command to be appended to the chef client run command" do
        expect(provider.consistent_splay_command).to eql("C:/windows/system32/windowspowershell/v1.0/powershell.exe Start-Sleep -s 222 && ")
      end
    end
  end

  describe "#splay_sleep_time" do
    it "uses shard_seed attribute if present" do
      node.automatic_attrs[:shard_seed] = "73399073"
      expect(provider.splay_sleep_time(300)).to satisfy { |v| v.between?(0, 300) }
    end

    it "uses a hex conversion of a md5 hash of the splay if present" do
      node.automatic_attrs[:shard_seed] = nil
      allow(node).to receive(:name).and_return("test_node")
      expect(provider.splay_sleep_time(300)).to satisfy { |v| v.between?(0, 300) }
    end
  end

  describe "#client_cmd" do
    it "creates a valid command if using all default properties" do
      expect(provider.client_cmd).to eql("#{chef_habitat_binary_path} -L /etc/chef/log/client.log -c /etc/chef/client.rb") | eql("#{chef_habitat_binary_path} -L C:\\chef/log/client.log -c C:\\chef/client.rb")
    end

    it "uses daemon_options if set" do
      resource.daemon_options ["--foo 1", "--bar 2"]
      expect(provider.client_cmd).to eql("#{chef_habitat_binary_path} -L /etc/chef/log/client.log -c /etc/chef/client.rb --foo 1 --bar 2") | eql("#{chef_habitat_binary_path} -L C:\\chef/log/client.log -c C:\\chef/client.rb --foo 1 --bar 2")
    end

    it "uses custom config dir if set" do
      resource.config_directory "C:/foo/bar"
      expect(provider.client_cmd).to eql("#{chef_habitat_binary_path} -L C:/foo/bar/log/client.log -c C:/foo/bar/client.rb")
    end

    it "uses custom log files / paths if set" do
      resource.log_file_name "my-client.log"
      resource.log_directory "C:/foo/bar"
      expect(provider.client_cmd).to eql("#{chef_habitat_binary_path} -L C:/foo/bar/my-client.log -c /etc/chef/client.rb") | eql("#{chef_habitat_binary_path} -L C:/foo/bar/my-client.log -c C:\\chef/client.rb")
    end

    it "uses custom chef-client binary if set" do
      # Temporarily override the stubbed value for this test
      allow(resource).to receive(:chef_binary_path).and_return("C:/foo/bar/chef-client")
      expect(provider.client_cmd).to eql("C:/foo/bar/chef-client -L /etc/chef/log/client.log -c /etc/chef/client.rb") | eql("C:/foo/bar/chef-client -L C:\\chef/log/client.log -c C:\\chef/client.rb")
    end

    it "sets the license acceptance flag if set" do
      resource.accept_chef_license true
      expect(provider.client_cmd).to eql("#{chef_habitat_binary_path} -L /etc/chef/log/client.log -c /etc/chef/client.rb --chef-license accept") | eql("#{chef_habitat_binary_path} -L C:\\chef/log/client.log -c C:\\chef/client.rb --chef-license accept")
    end
  end
end
