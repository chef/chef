#
# Copyright:: Copyright 2018, Chef Software, Inc.
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

describe Chef::Resource::WindowsFeaturePowershell do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::WindowsFeaturePowershell.new(%w{SNMP DHCP}, run_context) }

  it "sets resource name as :windows_feature_powershell" do
    expect(resource.resource_name).to eql(:windows_feature_powershell)
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "the feature_name property is the name_property" do
    node.automatic[:platform_version] = "6.2.9200"
    expect(resource.feature_name).to eql(%w{snmp dhcp})
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "supports :delete, :install, :remove actions" do
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  it "coerces comma separated lists of features to a lowercase array on 2012+" do
    node.automatic[:platform_version] = "6.2.9200"
    resource.feature_name "SNMP, DHCP"
    expect(resource.feature_name).to eql(%w{snmp dhcp})
  end

  it "coerces a single feature as a String to a lowercase array on 2012+" do
    node.automatic[:platform_version] = "6.2.9200"
    resource.feature_name "SNMP"
    expect(resource.feature_name).to eql(["snmp"])
  end

  it "coerces comma separated lists of features to an array, but preserves case on < 2012" do
    node.automatic[:platform_version] = "6.1.7601"
    resource.feature_name "SNMP, DHCP"
    expect(resource.feature_name).to eql(%w{SNMP DHCP})
  end

  it "coerces a single feature as a String to an array, but preserves case on < 2012" do
    node.automatic[:platform_version] = "6.1.7601"
    resource.feature_name "SNMP"
    expect(resource.feature_name).to eql(["SNMP"])
  end
end
