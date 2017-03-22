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

  before(:each) do
    @resource = Chef::Resource::Route.new("10.0.0.10")
  end

  it "should create a new Chef::Resource::Route" do
    expect(@resource).to be_a_kind_of(Chef::Resource)
    expect(@resource).to be_a_kind_of(Chef::Resource::Route)
  end

  it "should have a name" do
    expect(@resource.name).to eql("10.0.0.10")
  end

  it "should have a default action of 'add'" do
    expect(@resource.action).to eql([:add])
  end

  it "should accept add or delete for action" do
    expect { @resource.action :add }.not_to raise_error
    expect { @resource.action :delete }.not_to raise_error
    expect { @resource.action :lolcat }.to raise_error(ArgumentError)
  end

  it "should use the object name as the target by default" do
    expect(@resource.target).to eql("10.0.0.10")
  end

  it "should allow you to specify the netmask" do
    @resource.netmask "255.255.255.0"
    expect(@resource.netmask).to eql("255.255.255.0")
  end

  it "should allow you to specify the gateway" do
    @resource.gateway "10.0.0.1"
    expect(@resource.gateway).to eql("10.0.0.1")
  end

  it "should allow you to specify the metric" do
    @resource.metric 10
    expect(@resource.metric).to eql(10)
  end

  it "should allow you to specify the device" do
    @resource.device "eth0"
    expect(@resource.device).to eql("eth0")
  end

  it "should allow you to specify the route type" do
    @resource.route_type "host"
    expect(@resource.route_type).to eql(:host)
  end

  it "should default to a host route type" do
    expect(@resource.route_type).to eql(:host)
  end

  it "should accept a net route type" do
    @resource.route_type :net
    expect(@resource.route_type).to eql(:net)
  end

  it "should reject any other route_type but :host and :net" do
    expect { @resource.route_type "lolcat" }.to raise_error(ArgumentError)
  end

  describe "when it has netmask, gateway, and device" do
    before do
      @resource.target("charmander")
      @resource.netmask("lemask")
      @resource.gateway("111.111.111")
      @resource.device("forcefield")
    end

    it "describes its state" do
      state = @resource.state_for_resource_reporter
      expect(state[:netmask]).to eq("lemask")
      expect(state[:gateway]).to eq("111.111.111")
    end

    it "returns the target  as its identity" do
      expect(@resource.identity).to eq("charmander")
    end
  end
end
