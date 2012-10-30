#
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

describe Chef::Provider::User do

  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Group.new("wheel", @run_context)
    @new_resource.gid 500
    @new_resource.members "aj"

    @provider = Chef::Provider::Group.new(@new_resource, @run_context)

    @current_resource = Chef::Resource::Group.new("aj", @run_context)
    @current_resource.gid 500
    @current_resource.members "aj"
    
    @provider.current_resource = @current_resource

    @pw_group = mock("Struct::Group",
      :name => "wheel",
      :gid => 20,
      :mem => [ "root", "aj" ]
      )
    Etc.stub!(:getgrnam).with('wheel').and_return(@pw_group)
  end
  
  it "assumes the group exists by default" do
    @provider.group_exists.should be_true
  end

  describe "when establishing the current state of the group" do
  
    it "sets the group name of the current resource to the group name of the new resource" do
      @provider.load_current_resource
      @provider.current_resource.group_name.should == 'wheel'
    end

    it "does not modify the desired gid if set" do
      @provider.load_current_resource
      @new_resource.gid.should == 500
    end

    it "sets the desired gid to the current gid if none is set" do
      @new_resource.instance_variable_set(:@gid, nil)
      @provider.load_current_resource
      @new_resource.gid.should == 20
    end
  
    it "looks up the group in /etc/group with getgrnam" do
      Etc.should_receive(:getgrnam).with(@new_resource.group_name).and_return(@pw_group)
      @provider.load_current_resource
      @provider.current_resource.gid.should == 20
      @provider.current_resource.members.should == %w{root aj}
    end
  
    it "should flip the value of exists if it cannot be found in /etc/group" do
      Etc.stub!(:getgrnam).and_raise(ArgumentError)
      @provider.load_current_resource
      @provider.group_exists.should be_false
    end
  
    it "should return the current resource" do
      @provider.load_current_resource.should equal(@provider.current_resource)    
    end
  end

  describe "when determining if the system is already in the target state" do
    [ :gid, :members ].each do |attribute|
      it "should return true if #{attribute} doesn't match" do
        @current_resource.stub!(attribute).and_return("looooooooooooooooooool")
        @provider.compare_group.should be_true
      end
    end
  
    it "should return false if gid and members are equal" do
      @provider.compare_group.should be_false
    end

    it "should return false if append is true and the group member(s) already exists" do
      @current_resource.members << "extra_user"
      @new_resource.stub!(:append).and_return(true)
      @provider.compare_group.should be_false
    end

    it "should return true if append is true and the group member(s) do not already exist" do
      @new_resource.members << "extra_user"
      @new_resource.stub!(:append).and_return(true)
      @provider.compare_group.should be_true
    end

  end

  describe "when creating a group" do
    it "should call create_group if the group does not exist" do
      @provider.group_exists = false
      @provider.should_receive(:create_group).and_return(true)
      @provider.run_action(:create)
    end
  
    it "should set the the new_resources updated flag when it creates the group" do
      @provider.group_exists = false
      @provider.stub!(:create_group)
      @provider.run_action(:create)
      @provider.new_resource.should be_updated
    end
  
    it "should check to see if the group has mismatched attributes if the group exists" do
      @provider.group_exists = true
      @provider.stub!(:compare_group).and_return(false)
      @provider.run_action(:create)
      @provider.new_resource.should_not be_updated
    end
  
    it "should call manage_group if the group exists and has mismatched attributes" do
      @provider.group_exists = true
      @provider.stub!(:compare_group).and_return(true)
      @provider.should_receive(:manage_group).and_return(true)
      @provider.run_action(:create)
    end
  
    it "should set the the new_resources updated flag when it creates the group if we call manage_group" do
      @provider.group_exists = true
      @provider.stub!(:compare_group).and_return(true)
      @provider.stub!(:manage_group).and_return(true)
      @provider.run_action(:create)
      @new_resource.should be_updated
    end
  end

  describe "when removing a group" do
  
    it "should not call remove_group if the group does not exist" do
      @provider.group_exists = false
      @provider.should_not_receive(:remove_group) 
      @provider.run_action(:remove)
      @provider.new_resource.should_not be_updated
    end
  
    it "should call remove_group if the group exists" do
      @provider.group_exists = true
      @provider.should_receive(:remove_group)
      @provider.run_action(:remove)
      @provider.new_resource.should be_updated
    end
  end

  describe "when updating a group" do
    before(:each) do
      @provider.group_exists = true
      @provider.stub!(:manage_group).and_return(true)
    end
 
    it "should run manage_group if the group exists and has mismatched attributes" do
      @provider.should_receive(:compare_group).and_return(true)
      @provider.should_receive(:manage_group).and_return(true)
      @provider.run_action(:manage)
    end
  
    it "should set the new resources updated flag to true if manage_group is called" do
      @provider.stub!(:compare_group).and_return(true)
      @provider.stub!(:manage_group).and_return(true)
      @provider.run_action(:manage)
      @new_resource.should be_updated
    end
  
    it "should not run manage_group if the group does not exist" do
      @provider.group_exists = false
      @provider.should_not_receive(:manage_group)
      @provider.run_action(:manage)
    end
    
    it "should not run manage_group if the group exists but has no differing attributes" do
      @provider.should_receive(:compare_group).and_return(false)
      @provider.should_not_receive(:manage_group)
      @provider.run_action(:manage)
    end
  end

  describe "when modifying the group" do
    before(:each) do
      @provider.group_exists = true
      @provider.stub!(:manage_group).and_return(true)
    end
 
    it "should run manage_group if the group exists and has mismatched attributes" do
      @provider.should_receive(:compare_group).and_return(true)
      @provider.should_receive(:manage_group).and_return(true)
      @provider.run_action(:modify)
    end
  
    it "should set the new resources updated flag to true if manage_group is called" do
      @provider.stub!(:compare_group).and_return(true)
      @provider.stub!(:manage_group).and_return(true)
      @provider.run_action(:modify)
      @new_resource.should be_updated
    end
  
    it "should not run manage_group if the group exists but has no differing attributes" do
      @provider.should_receive(:compare_group).and_return(false)
      @provider.should_not_receive(:manage_group)
      @provider.run_action(:modify)
    end
  
    it "should raise a Chef::Exceptions::Group if the group doesn't exist" do
      @provider.group_exists = false
      lambda { @provider.run_action(:modify) }.should raise_error(Chef::Exceptions::Group)
    end
  end

  describe "when determining the reason for a change" do
    it "should report which group members are missing if members are missing and appending to the group" do
       @new_resource.members << "user1"
       @new_resource.members << "user2" 
       @new_resource.stub!(:append).and_return true
       @provider.compare_group.should be_true
       @provider.change_desc.should == "add missing member(s): user1, user2"
    end

    it "should report that the group members will be overwritten if not appending" do
       @new_resource.members << "user1"
       @new_resource.stub!(:append).and_return false 
       @provider.compare_group.should be_true
       @provider.change_desc.should == "replace group members with new list of members"
    end

    it "should report the gid will be changed when it does not match" do
      @current_resource.stub!(:gid).and_return("BADF00D")
      @provider.compare_group.should be_true
      @provider.change_desc.should == "change gid #{@current_resource.gid} to #{@new_resource.gid}"

    end

    it "should report no change reason when no change is required" do
      @provider.compare_group.should be_false
      @provider.change_desc.should == nil
    end
  end

end
