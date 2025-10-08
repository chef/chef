#
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

describe Chef::Resource::WindowsDnsZone do
  let(:resource) { Chef::Resource::WindowsDnsZone.new("fakey_fakerton") }

  it "sets resource name as :windows_dns_zone" do
    expect(resource.resource_name).to eql(:windows_dns_zone)
  end

  it "the zone_name property is the name_property" do
    expect(resource.zone_name).to eql("fakey_fakerton")
  end

  it "the server_type property accepts 'Standalone'" do
    expect { resource.server_type "Standalone" }.not_to raise_error
  end

  it "the server_type property accepts 'Domain'" do
    expect { resource.server_type "Domain" }.not_to raise_error
  end

  it "the resource raises an ArgumentError if invalid server_type is set" do
    expect { resource.server_type "NOPE" }.to raise_error(ArgumentError)
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create and :delete actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end
end
