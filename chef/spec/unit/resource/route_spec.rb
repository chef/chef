#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Author:: Tyler Cloke (<tyler@opscode.com>)
# Copyright:: Copyright (c) 2008 Bryan McLellan
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

require 'spec_helper'

describe Chef::Resource::Route do

  before(:each) do
    @resource = Chef::Resource::Route.new("10.0.0.10")
  end  

  it "should create a new Chef::Resource::Route" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::Route)
  end
  
  it "should have a name" do
    @resource.name.should eql("10.0.0.10")
  end
  
  it "should have a default action of 'add'" do
    @resource.action.should eql(:add)
  end
  
  it "should accept add or delete for action" do
    lambda { @resource.action :add }.should_not raise_error(ArgumentError)
    lambda { @resource.action :delete }.should_not raise_error(ArgumentError)
    lambda { @resource.action :lolcat }.should raise_error(ArgumentError)
  end
    
  it "should use the object name as the target by default" do
    @resource.target.should eql("10.0.0.10")
  end
  
  it "should allow you to specify the netmask" do
    @resource.netmask "255.255.255.0"
    @resource.netmask.should eql("255.255.255.0")
  end

  it "should allow you to specify the gateway" do
    @resource.gateway "10.0.0.1"
    @resource.gateway.should eql("10.0.0.1")
  end

  it "should allow you to specify the metric" do
    @resource.metric 10
    @resource.metric.should eql(10)
  end

  it "should allow you to specify the device" do
    @resource.device "eth0"
    @resource.device.should eql("eth0")
  end

  it "should allow you to specify the route type" do
    @resource.route_type "host"
    @resource.route_type.should eql(:host)
  end
  
  it "should default to a host route type" do
    @resource.route_type.should eql(:host)
  end
  
  it "should accept a net route type" do
    @resource.route_type :net
    @resource.route_type.should eql(:net)
  end
  
  it "should reject any other route_type but :host and :net" do
    lambda { @resource.route_type "lolcat" }.should raise_error(ArgumentError)
  end
  
  describe "when it has netmask, gateway, and device" do
    before do 
      @resource.target("charmander")
      @resource.netmask("lemask")
      @resource.gateway("111.111.111")
      @resource.device("forcefield")
    end

    it "describes its state" do
      state = @resource.state
      state[:netmask].should == "lemask"
      state[:gateway].should == "111.111.111"
    end

    it "returns the target  as its identity" do
      @resource.identity.should == "charmander"
    end
  end
end
