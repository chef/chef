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

describe Chef::Resource::WindowsPrinterPort do
  let(:resource) { Chef::Resource::WindowsPrinterPort.new("63.192.209.236") }

  it "sets resource name as :windows_printer_port" do
    expect(resource.resource_name).to eql(:windows_printer_port)
  end

  it "the ipv4_address property is the name_property" do
    expect(resource.ipv4_address).to eql("63.192.209.236")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :delete actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end

  it "port_number property defaults to 9100" do
    expect(resource.port_number).to eql(9100)
  end

  it "snmp_enabled property defaults to false" do
    expect(resource.snmp_enabled).to eql(false)
  end

  it "port_protocol property defaults to 1" do
    expect(resource.port_protocol).to eql(1)
  end

  it "raises an error if port_protocol isn't in 1 or 2" do
    expect { resource.port_protocol 1 }.not_to raise_error
    expect { resource.port_protocol 2 }.not_to raise_error
    expect { resource.port_protocol 3 }.to raise_error(ArgumentError)
  end

  it "raises an error if ipv4_address isn't in X.X.X.X format" do
    expect { resource.ipv4_address "63.192.209.236" }.not_to raise_error
    expect { resource.ipv4_address "a.b.c.d" }.to raise_error(ArgumentError)
  end
end
