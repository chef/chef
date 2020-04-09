#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: 2020, Chef Software Inc.
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

describe Chef::Resource::ChefClientSystemdTimer do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::ChefClientSystemdTimer.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:add) }

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end

  it "user defaults to root" do
    expect(resource.user).to eql("root")
  end

  it "builds a default value for chef_binary_path dist values" do
    expect(resource.chef_binary_path).to eql("/opt/chef/bin/chef-client")
  end

  it "supports :add and :remove actions" do
    expect { resource.action :add }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  describe "#chef_client_cmd" do
    it "creates a valid command if using all default properties" do
      expect(provider.chef_client_cmd).to eql("/opt/chef/bin/chef-client -c /etc/chef/client.rb")
    end

    it "uses daemon_options if set" do
      resource.daemon_options ["--foo 1", "--bar 2"]
      expect(provider.chef_client_cmd).to eql("/opt/chef/bin/chef-client --foo 1 --bar 2 -c /etc/chef/client.rb")
    end

    it "uses custom config dir if set" do
      resource.config_directory "/etc/some_other_dir"
      expect(provider.chef_client_cmd).to eql("/opt/chef/bin/chef-client -c /etc/some_other_dir/client.rb")
    end

    it "uses custom chef-client binary if set" do
      resource.chef_binary_path "/usr/local/bin/chef-client"
      expect(provider.chef_client_cmd).to eql("/usr/local/bin/chef-client -c /etc/chef/client.rb")
    end

    it "sets the license acceptance flag if set" do
      resource.accept_chef_license true
      expect(provider.chef_client_cmd).to eql("/opt/chef/bin/chef-client --chef-license accept -c /etc/chef/client.rb")
    end
  end
end
