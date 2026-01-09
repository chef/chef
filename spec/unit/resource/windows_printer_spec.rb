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

describe Chef::Resource::WindowsPrinter do
  let(:resource) { Chef::Resource::WindowsPrinter.new("fakey_fakerton") }

  it "sets resource name as :windows_printer" do
    expect(resource.resource_name).to eql(:windows_printer)
  end

  it "the device_id property is the name_property" do
    expect(resource.device_id).to eql("fakey_fakerton")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :delete actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end

  it "default property defaults to false" do
    expect(resource.default).to eql(false)
  end

  it "shared property defaults to false" do
    expect(resource.shared).to eql(false)
  end

  it "raises an error if ipv4_address isn't in X.X.X.X format" do
    expect { resource.ipv4_address "63.192.209.236" }.not_to raise_error
    expect { resource.ipv4_address "a.b.c.d" }.to raise_error(ArgumentError)
  end
end
