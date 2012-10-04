#
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc
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

describe Chef::Resource::Mount do
  before(:each) do
    @resource = Chef::Resource::Mount.new("filesystem")
  end
  
  it "should create a new Chef::Resource::Mount" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::Mount)
  end

  it "should have a name" do
    @resource.name.should eql("filesystem")
  end

  it "should set mount_point to the name" do
    @resource.mount_point.should eql("filesystem")
  end
  
  it "should have a default action of mount" do
    @resource.action.should eql(:mount)
  end
  
  it "should accept mount, umount and remount as actions" do
    lambda { @resource.action :mount }.should_not raise_error(ArgumentError)
    lambda { @resource.action :umount }.should_not raise_error(ArgumentError)
    lambda { @resource.action :remount }.should_not raise_error(ArgumentError)
    lambda { @resource.action :brooklyn }.should raise_error(ArgumentError)
  end
  
  it "should allow you to set the device attribute" do
    @resource.device "/dev/sdb3"
    @resource.device.should eql("/dev/sdb3")
  end

  it "should allow you to set the fstype attribute" do
    @resource.fstype "nfs"
    @resource.fstype.should eql("nfs")
  end

  it "should allow you to set the dump attribute" do
    @resource.dump 1
    @resource.dump.should eql(1)
  end

  it "should allow you to set the pass attribute" do
    @resource.pass 1
    @resource.pass.should eql(1)
  end

  it "should set the options attribute to defaults" do
    @resource.options.should eql(["defaults"])
  end

  it "should allow options to be sent as a string, and convert to array" do
    @resource.options "rw,noexec"
    @resource.options.should be_a_kind_of(Array)
  end
  
  it "should allow options attribute as an array" do
    @resource.options ["ro", "nosuid"]
    @resource.options.should be_a_kind_of(Array)
  end

  it "should accept true for mounted" do
    @resource.mounted(true) 
    @resource.mounted.should eql(true)
  end

  it "should accept false for mounted" do
    @resource.mounted(false) 
    @resource.mounted.should eql(false)
  end

  it "should set mounted to false by default" do
    @resource.mounted.should eql(false)
  end

  it "should not accept a string for mounted" do
    lambda { @resource.mounted("poop") }.should raise_error(ArgumentError)
  end

  it "should accept true for enabled" do
    @resource.enabled(true) 
    @resource.enabled.should eql(true)
  end

  it "should accept false for enabled" do
    @resource.enabled(false) 
    @resource.enabled.should eql(false)
  end

  it "should set enabled to false by default" do
    @resource.enabled.should eql(false)
  end

  it "should not accept a string for enabled" do
    lambda { @resource.enabled("poop") }.should raise_error(ArgumentError)
  end

  it "should default all feature support to false" do
    support_hash = { :remount => false }
    @resource.supports.should == support_hash
  end

  it "should allow you to set feature support as an array" do
    support_array = [ :remount ]
    support_hash = { :remount => true }
    @resource.supports(support_array)
    @resource.supports.should == support_hash
  end

  it "should allow you to set feature support as a hash" do
    support_hash = { :remount => true }
    @resource.supports(support_hash)
    @resource.supports.should == support_hash
  end

  describe "when it has mount point, device type, and fstype" do
    before do 
      @resource.device("charmander")
      @resource.mount_point("123.456")
      @resource.device_type(:device)
      @resource.fstype("ranked")
    end

    it "describes its state" do
      state = @resource.state
      state[:mount_point].should == "123.456"
      state[:device_type].should eql(:device)
      state[:fstype].should == "ranked"
    end

    it "returns the device as its identity" do
      @resource.identity.should == "charmander"
    end
  end
end
