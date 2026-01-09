#
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

describe Chef::Resource::WindowsFeaturePowershell do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::WindowsFeaturePowershell.new(%w{SNMP DHCP}, run_context) }
  let(:provider) { resource.provider_for_action(:install) }

  it "sets resource name as :windows_feature_powershell" do
    expect(resource.resource_name).to eql(:windows_feature_powershell)
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "the feature_name property is the name_property" do
    expect(resource.feature_name).to eql(%w{snmp dhcp})
  end

  it "supports :delete, :install, :remove actions" do
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  it "coerces comma separated lists of features to a lowercase array" do
    resource.feature_name "SNMP, DHCP"
    expect(resource.feature_name).to eql(%w{snmp dhcp})
  end

  it "coerces a single feature as a String to a lowercase array" do
    resource.feature_name "SNMP"
    expect(resource.feature_name).to eql(["snmp"])
  end

  it "install a single feature" do
    resource.feature_name "snmp"
    expect { resource.action :install }.not_to raise_error
  end

  it "install multi feature" do
    resource.feature_name "SNMP, DHCP"
    expect { resource.action :install }.not_to raise_error
  end

  it "does not attempt to install features that have been removed" do
    node.default["powershell_features_cache"] ||= {}
    node.default["powershell_features_cache"]["disabled"] = ["dhcp"]
    node.default["powershell_features_cache"]["removed"] = ["snmp"]
    resource.feature_name "dhcp, snmp"

    expect(provider.features_to_install).to eq(["dhcp"])
  end

  it "attempts to install features that have been removed when source is set" do
    node.default["powershell_features_cache"] ||= {}
    node.default["powershell_features_cache"]["disabled"] = ["dhcp"]
    node.default["powershell_features_cache"]["removed"] = ["snmp"]
    resource.feature_name "dhcp, snmp"
    resource.source "D:\\sources\\sxs"

    expect(provider.features_to_install).to eq(%w{dhcp snmp})
  end
end
