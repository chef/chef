#
# Author:: AJ Christensen (<aj@chef.io>)
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

    @pw_group = double("Struct::Group",
      name: "wheel",
      gid: 20,
      mem: %w{root aj})
    allow(Etc).to receive(:getgrnam).with("wheel").and_return(@pw_group)
  end

  it "assumes the group exists by default" do
    expect(@provider.group_exists).to be_truthy
  end

  describe "when establishing the current state of the group" do

    it "sets the group name of the current resource to the group name of the new resource" do
      @provider.load_current_resource
      expect(@provider.current_resource.group_name).to eq("wheel")
    end

    it "does not modify the desired gid if set" do
      @provider.load_current_resource
      expect(@new_resource.gid).to eq(500)
    end

    it "sets the desired gid to the current gid if none is set" do
      @new_resource.instance_variable_set(:@gid, nil)
      @provider.load_current_resource
      expect(@new_resource.gid).to eq(20)
    end

    it "looks up the group in /etc/group with getgrnam" do
      expect(Etc).to receive(:getgrnam).with(@new_resource.group_name).and_return(@pw_group)
      @provider.load_current_resource
      expect(@provider.current_resource.gid).to eq(20)
      expect(@provider.current_resource.members).to eq(%w{root aj})
    end

    it "should flip the value of exists if it cannot be found in /etc/group" do
      allow(Etc).to receive(:getgrnam).and_raise(ArgumentError)
      @provider.load_current_resource
      expect(@provider.group_exists).to be_falsey
    end

    it "should return the current resource" do
      expect(@provider.load_current_resource).to equal(@provider.current_resource)
    end
  end

  describe "when determining if the system is already in the target state" do
    %i{gid members}.each do |property|
      it "should return true if #{property} doesn't match" do
        allow(@current_resource).to receive(property).and_return("looooooooooooooooooool")
        expect(@provider.compare_group).to be_truthy
      end
    end

    it "should return false if gid and members are equal" do
      expect(@provider.compare_group).to be_falsey
    end

    it "should coerce an integer to a string for comparison" do
      allow(@current_resource).to receive(:gid).and_return("500")
      expect(@provider.compare_group).to be_falsey
    end

    it "should return false if append is true and the group member(s) already exists" do
      @current_resource.members << "extra_user"
      @new_resource.append(true)
      expect(@provider.compare_group).to be_falsey
    end

    it "should return true if append is true and the group member(s) do not already exist" do
      @new_resource.members << "extra_user"
      @new_resource.append(true)
      expect(@provider.compare_group).to be_truthy
    end

    it "should return false if append is true and excluded_members include a non existing member" do
      @new_resource.excluded_members << "extra_user"
      @new_resource.append(true)
      expect(@provider.compare_group).to be_falsey
    end

    it "should return true if the append is true and excluded_members include an existing user" do
      @new_resource.excluded_members += @new_resource.members
      @new_resource.members.clear
      @new_resource.append(true)
      expect(@provider.compare_group).to be_truthy
    end

  end

  describe "when creating a group" do
    it "should call create_group if the group does not exist" do
      @provider.group_exists = false
      expect(@provider).to receive(:create_group).and_return(true)
      @provider.run_action(:create)
    end

    it "should set the new_resources updated flag when it creates the group" do
      @provider.group_exists = false
      allow(@provider).to receive(:create_group)
      @provider.run_action(:create)
      expect(@provider.new_resource).to be_updated
    end

    it "should check to see if the group has mismatched properties if the group exists" do
      @provider.group_exists = true
      allow(@provider).to receive(:compare_group).and_return(false)
      allow(@provider).to receive(:change_desc).and_return([ ])
      @provider.run_action(:create)
      expect(@provider.new_resource).not_to be_updated
    end

    it "should call manage_group if the group exists and has mismatched properties" do
      @provider.group_exists = true
      allow(@provider).to receive(:compare_group).and_return(true)
      allow(@provider).to receive(:change_desc).and_return([ ])
      expect(@provider).to receive(:manage_group).and_return(true)
      @provider.run_action(:create)
    end

    it "should set the new_resources updated flag when it creates the group if we call manage_group" do
      @provider.group_exists = true
      allow(@provider).to receive(:compare_group).and_return(true)
      allow(@provider).to receive(:change_desc).and_return(["Some changes are going to be done."])
      allow(@provider).to receive(:manage_group).and_return(true)
      @provider.run_action(:create)
      expect(@new_resource).to be_updated
    end
  end

  describe "when removing a group" do

    it "should not call remove_group if the group does not exist" do
      @provider.group_exists = false
      expect(@provider).not_to receive(:remove_group)
      @provider.run_action(:remove)
      expect(@provider.new_resource).not_to be_updated
    end

    it "should call remove_group if the group exists" do
      @provider.group_exists = true
      expect(@provider).to receive(:remove_group)
      @provider.run_action(:remove)
      expect(@provider.new_resource).to be_updated
    end
  end

  describe "when updating a group" do
    before(:each) do
      @provider.group_exists = true
      allow(@provider).to receive(:manage_group).and_return(true)
    end

    it "should run manage_group if the group exists and has mismatched properties" do
      expect(@provider).to receive(:compare_group).and_return(true)
      allow(@provider).to receive(:change_desc).and_return(["Some changes are going to be done."])
      expect(@provider).to receive(:manage_group).and_return(true)
      @provider.run_action(:manage)
    end

    it "should set the new resources updated flag to true if manage_group is called" do
      allow(@provider).to receive(:compare_group).and_return(true)
      allow(@provider).to receive(:change_desc).and_return(["Some changes are going to be done."])
      allow(@provider).to receive(:manage_group).and_return(true)
      @provider.run_action(:manage)
      expect(@new_resource).to be_updated
    end

    it "should not run manage_group if the group does not exist" do
      @provider.group_exists = false
      expect(@provider).not_to receive(:manage_group)
      @provider.run_action(:manage)
    end

    it "should not run manage_group if the group exists but has no differing properties" do
      expect(@provider).to receive(:compare_group).and_return(false)
      allow(@provider).to receive(:change_desc).and_return(["Some changes are going to be done."])
      expect(@provider).not_to receive(:manage_group)
      @provider.run_action(:manage)
    end
  end

  describe "when modifying the group" do
    before(:each) do
      @provider.group_exists = true
      allow(@provider).to receive(:manage_group).and_return(true)
    end

    it "should run manage_group if the group exists and has mismatched properties" do
      expect(@provider).to receive(:compare_group).and_return(true)
      allow(@provider).to receive(:change_desc).and_return(["Some changes are going to be done."])
      expect(@provider).to receive(:manage_group).and_return(true)
      @provider.run_action(:modify)
    end

    it "should set the new resources updated flag to true if manage_group is called" do
      allow(@provider).to receive(:compare_group).and_return(true)
      allow(@provider).to receive(:change_desc).and_return(["Some changes are going to be done."])
      allow(@provider).to receive(:manage_group).and_return(true)
      @provider.run_action(:modify)
      expect(@new_resource).to be_updated
    end

    it "should not run manage_group if the group exists but has no differing properties" do
      expect(@provider).to receive(:compare_group).and_return(false)
      allow(@provider).to receive(:change_desc).and_return(["Some changes are going to be done."])
      expect(@provider).not_to receive(:manage_group)
      @provider.run_action(:modify)
    end

    it "should raise a Chef::Exceptions::Group if the group doesn't exist" do
      @provider.group_exists = false
      expect { @provider.run_action(:modify) }.to raise_error(Chef::Exceptions::Group)
    end
  end

  describe "when determining the reason for a change" do
    it "should report which group members are missing if members are missing and appending to the group" do
      @new_resource.members << "user1"
      @new_resource.members << "user2"
      allow(@new_resource).to receive(:append).and_return true
      expect(@provider.compare_group).to be_truthy
      expect(@provider.change_desc).to eq([ "add missing member(s): user1, user2" ])
    end

    it "should report that the group members will be overwritten if not appending" do
      @new_resource.members << "user1"
      allow(@new_resource).to receive(:append).and_return false
      expect(@provider.compare_group).to be_truthy
      expect(@provider.change_desc).to eq([ "replace group members with new list of members: aj, user1" ])
    end

    it "should report the gid will be changed when it does not match" do
      allow(@current_resource).to receive(:gid).and_return("BADF00D")
      expect(@provider.compare_group).to be_truthy
      expect(@provider.change_desc).to eq([ "change gid #{@current_resource.gid} to #{@new_resource.gid}" ])

    end

    it "should report no change reason when no change is required" do
      expect(@provider.compare_group).to be_falsey
      expect(@provider.change_desc).to eq([ ])
    end
  end

end
