#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2016, Bryan McLellan
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

describe Chef::Resource::Route do

  let(:resource) { Chef::Resource::Route.new("10.0.0.10") }

  it "the target property is the name_property" do
    expect(resource.target).to eql("10.0.0.10")
  end

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end

  it "supports :add, :delete actions" do
    expect { resource.action :add }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end

  it "allows you to specify the netmask" do
    resource.netmask "255.255.255.0"
    expect(resource.netmask).to eql("255.255.255.0")
  end

  it "allows you to specify the gateway" do
    resource.gateway "10.0.0.1"
    expect(resource.gateway).to eql("10.0.0.1")
  end

  it "allows you to specify the metric" do
    resource.metric 10
    expect(resource.metric).to eql(10)
  end

  it "allows you to specify the device" do
    resource.device "eth0"
    expect(resource.device).to eql("eth0")
  end

  it "allows you to specify the route type as a symbol" do
    resource.route_type :host
    expect(resource.route_type).to eql(:host)
  end

  it "allows you to specify the route type as a string" do
    resource.route_type :host
    expect(resource.route_type).to eql(:host)
  end

  it "defaults to a host route type" do
    expect(resource.route_type).to eql(:host)
  end

  it "accepts a net route type" do
    resource.route_type :net
    expect(resource.route_type).to eql(:net)
  end

  it "rejects any other route_type but :host and :net" do
    expect { resource.route_type "lolcat" }.to raise_error(ArgumentError)
  end

  describe "when it has netmask, gateway, and device" do
    before do
      resource.target("charmander")
      resource.netmask("lemask")
      resource.gateway("111.111.111")
      resource.device("forcefield")
    end

    it "describes its state" do
      state = resource.state_for_resource_reporter
      expect(state[:netmask]).to eq("lemask")
      expect(state[:gateway]).to eq("111.111.111")
    end

    it "returns the target  as its identity" do
      expect(resource.identity).to eq("charmander")
    end
  end
end
