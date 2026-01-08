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

describe Chef::Resource::ChefClientSystemdTimer do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::ChefClientSystemdTimer.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:add) }
  let(:chef_habitat_binary_path) { "/hab/pkgs/chef/chef-infra-client/19.2.7/20250122151044/bin/chef-client" }

  before do
    # Stub the chef_binary_path property to return the Habitat path
    allow(resource).to receive(:chef_binary_path).and_return(chef_habitat_binary_path)
  end

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end

  it "user defaults to root" do
    expect(resource.user).to eql("root")
  end

  it "validates the cpu_quota property input" do
    expect { resource.cpu_quota(0) }.to raise_error(Chef::Exceptions::ValidationFailed)
    expect { resource.cpu_quota(50) }.not_to raise_error
    expect { resource.cpu_quota(101) }.not_to raise_error
  end

  it "builds a default value for chef_binary_path dist values" do
    expect(resource.chef_binary_path).to eql(chef_habitat_binary_path)
  end

  it "supports :add and :remove actions" do
    expect { resource.action :add }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  describe "#chef_client_cmd" do

    let(:root_path) { windows? ? "C:\\chef/client.rb" : "/etc/chef/client.rb" }

    it "creates a valid command if using all default properties" do
      expect(provider.chef_client_cmd).to eql("#{chef_habitat_binary_path} -c #{root_path}")
    end

    it "uses daemon_options if set" do
      resource.daemon_options ["--foo 1", "--bar 2"]
      expect(provider.chef_client_cmd).to eql("#{chef_habitat_binary_path} --foo 1 --bar 2 -c #{root_path}")
    end

    it "uses custom config dir if set" do
      resource.config_directory "/etc/some_other_dir"
      expect(provider.chef_client_cmd).to eql("#{chef_habitat_binary_path} -c /etc/some_other_dir/client.rb")
    end

    it "uses custom chef-client binary if set" do
      # Temporarily override the stubbed value for this test
      allow(resource).to receive(:chef_binary_path).and_return("/usr/local/bin/chef-client")
      expect(provider.chef_client_cmd).to eql("/usr/local/bin/chef-client -c #{root_path}")
    end

    it "sets the license acceptance flag if set" do
      resource.accept_chef_license true
      expect(provider.chef_client_cmd).to eql("#{chef_habitat_binary_path} --chef-license accept -c #{root_path}")
    end
  end

  describe "#service_content" do
    it "does not set ConditionACPower if run_on_battery property is set to true (the default)" do
      expect(provider.service_content["Service"]).not_to have_key("ConditionACPower")
    end

    it "sets ConditionACPower if run_on_battery property is set to false" do
      resource.run_on_battery false
      expect(provider.service_content["Service"]["ConditionACPower"]).to eq("true")
    end

    it "does not set Environment if environment property is empty" do
      expect(provider.service_content["Service"]).not_to have_key("Environment")
    end

    it "sets Environment if environment property is set" do
      resource.environment({ "foo" => "bar" })
      expect(provider.service_content["Service"]["Environment"]).to eq(["\"foo=bar\""])
    end

    it "does not set CPUQuota if cpu_quota property is not set" do
      expect(provider.service_content["Service"]).not_to have_key("CPUQuota")
    end

    it "sets CPUQuota if cpu_quota property is set" do
      resource.cpu_quota 50
      expect(provider.service_content["Service"]["CPUQuota"]).to eq("50%")
    end
  end
end
