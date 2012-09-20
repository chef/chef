#
# Author:: Joe Williams (<joe@joetify.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
# Copyright:: Copyright (c) 2009 Joe Williams
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

describe Chef::Resource::ErlCall do

  before(:each) do
    @resource = Chef::Resource::ErlCall.new("fakey_fakerton")
  end

  it "should create a new Chef::Resource::ErlCall" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::ErlCall)
  end

  it "should have a resource name of :erl_call" do
    @resource.resource_name.should eql(:erl_call)
  end

  it "should have a default action of run" do
    @resource.action.should eql("run")
  end

  it "should accept run as an action" do
    lambda { @resource.action :run }.should_not raise_error(ArgumentError)
  end

  it "should allow you to set the code attribute" do
    @resource.code "q()."
    @resource.code.should eql("q().")
  end

  it "should allow you to set the cookie attribute" do
    @resource.cookie "nomnomnom"
    @resource.cookie.should eql("nomnomnom")
  end

  it "should allow you to set the distributed attribute" do
    @resource.distributed true
    @resource.distributed.should eql(true)
  end

  it "should allow you to set the name_type attribute" do
    @resource.name_type "sname"
    @resource.name_type.should eql("sname")
  end

  it "should allow you to set the node_name attribute" do
    @resource.node_name "chef@erlang"
    @resource.node_name.should eql("chef@erlang")
  end

  describe "when it has cookie and node_name" do
    before do 
      @resource.code("erl-call:function()")
      @resource.cookie("cookie")
      @resource.node_name("raster")
    end

    it "returns the code as its identity" do
      @resource.identity.should == "erl-call:function()"
    end
  end
end
