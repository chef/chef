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

describe Chef::Resource::Mdadm do

  before(:each) do
    @resource = Chef::Resource::Mdadm.new("fakey_fakerton")
  end

  it "should create a new Chef::Resource::Mdadm" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::Mdadm)
  end

  it "should have a resource name of :mdadm" do
    @resource.resource_name.should eql(:mdadm)
  end

  it "should have a default action of create" do
    @resource.action.should eql(:create)
  end

  it "should accept create, assemble, stop as actions" do
    lambda { @resource.action :create }.should_not raise_error(ArgumentError)
    lambda { @resource.action :assemble }.should_not raise_error(ArgumentError)
    lambda { @resource.action :stop }.should_not raise_error(ArgumentError)
  end

  it "should allow you to set the raid_device attribute" do
    @resource.raid_device "/dev/md3"
    @resource.raid_device.should eql("/dev/md3")
  end

  it "should allow you to set the chunk attribute" do
    @resource.chunk 256
    @resource.chunk.should eql(256)
  end

  it "should allow you to set the level attribute" do
    @resource.level 1
    @resource.level.should eql(1)
  end

  it "should allow you to set the metadata attribute" do
    @resource.metadata "1.2"
    @resource.metadata.should eql("1.2")
  end

  it "should allow you to set the bitmap attribute" do
    @resource.metadata "internal"
    @resource.metadata.should eql("internal")
  end

  it "should allow you to set the devices attribute" do
    @resource.devices ["/dev/sda", "/dev/sdb"]
    @resource.devices.should eql(["/dev/sda", "/dev/sdb"])
  end

  it "should allow you to set the exists attribute" do
    @resource.exists true
    @resource.exists.should eql(true)
  end

  describe "when it has devices, level, and chunk" do
    before do 
      @resource.raid_device("raider")
      @resource.devices(["device1", "device2"])
      @resource.level(1)
      @resource.chunk(42)
    end
    
    it "describes its state" do
      state = @resource.state
      state[:devices].should eql(["device1", "device2"])
      state[:level].should == 1
      state[:chunk].should == 42
    end

    it "returns the raid device as its identity" do
      @resource.identity.should == "raider"
    end
  end
  
end
