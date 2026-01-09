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

describe Chef::Resource::ChefClientLaunchd do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::ChefClientLaunchd.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:enable) }
  let(:chef_habitat_binary_path) { "/hab/pkgs/chef/chef-infra-client/19.2.7/20250122151044/bin/chef-client" }

  before do
    # Stub the chef_binary_path property to return the Habitat path
    allow(resource).to receive(:chef_binary_path).and_return(chef_habitat_binary_path)
  end

  it "sets the default action as :enable" do
    expect(resource.action).to eql([:enable])
  end

  it "supports :enable and :disable actions" do
    expect { resource.action :enable }.not_to raise_error
    expect { resource.action :disable }.not_to raise_error
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

  it "builds a default value for chef_binary_path dist values" do
    expect(resource.chef_binary_path).to eql(chef_habitat_binary_path)
  end

  it "raises an error if interval is not a positive number" do
    expect { resource.interval("-10") }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "coerces interval to an Integer" do
    resource.interval "10"
    expect(resource.interval).to eql(10)
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

  describe "#client_command" do
    before do
      allow(provider).to receive(:splay_sleep_time).and_return("123")
    end

    let(:root_path) { windows? ? "C:\\chef/client.rb" : "/etc/chef/client.rb" }

    it "creates a valid command if using all default properties" do
      expect(provider.client_command).to eql(
        "/bin/sleep 123; #{chef_habitat_binary_path} -c #{root_path} -L /Library/Logs/Chef/client.log"
      )
    end

    it "adds custom daemon options from daemon_options property" do
      resource.daemon_options %w{foo bar}
      expect(provider.client_command).to eql(
        "/bin/sleep 123; #{chef_habitat_binary_path} foo bar -c #{root_path} -L /Library/Logs/Chef/client.log"
      )
    end

    it "adds license acceptance flags if the property is set" do
      resource.accept_chef_license true
      expect(provider.client_command).to eql(
        "/bin/sleep 123; #{chef_habitat_binary_path} -c #{root_path} -L /Library/Logs/Chef/client.log --chef-license accept"
      )
    end

    it "uses custom config dir if set" do
      resource.config_directory "/etc/some_other_dir"
      expect(provider.client_command).to eql(
        "/bin/sleep 123; #{chef_habitat_binary_path} -c /etc/some_other_dir/client.rb -L /Library/Logs/Chef/client.log"
      )
    end

    it "uses custom log files / paths if set" do
      resource.log_file_name "my-client.log"
      resource.log_directory "/var/log/my-chef/"
      expect(provider.client_command).to eql(
        "/bin/sleep 123; #{chef_habitat_binary_path} -c #{root_path} -L /var/log/my-chef/my-client.log"
      )
    end
  end
end
