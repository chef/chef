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
  let(:resource) { Chef::Resource::WindowsFeaturePowershell.new(%w{SNMP DHCP}) }

  it "sets resource name as :windows_feature_powershell" do
    expect(resource.resource_name).to eql(:windows_feature_powershell)
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "sets the feature_name property as its name_property" do
    expect(resource.feature_name).to eql(%w{SNMP DHCP})
  end

  it "coerces comma separated lists of features to arrays" do
    resource.feature_name "SNMP, DHCP"
    expect(resource.feature_name).to eql(%w{SNMP DHCP})
  end

  it "coerces a single feature as a String into an array" do
    resource.feature_name "SNMP"
    expect(resource.feature_name).to eql(["SNMP"])
  end

  it "supports :install, :remove, and :delete actions" do
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :update }.to raise_error(ArgumentError)
  end
end
