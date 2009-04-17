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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::User, "initialize" do

  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group",
      :null_object => true,
      :group_name => "staff",
      :gid => 20,
      :members => [ "root", "aj"]
    )
    @provider = Chef::Provider::Group.new(@node, @new_resource)
  end
  
  it "should return a Chef::Provider::Group" do
    @provider.should be_a_kind_of(Chef::Provider::Group)
  end
  
  it "should assume the group exists by default" do
    @provider.group_exists.should be_true
  end
  
end

describe Chef::Provider::User, "load_current_resource" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group",
      :null_object => true,
      :group_name => "aj",
      :gid => 500,
      :members => [ "aj"]
    )
    @current_resource = mock("Chef::Resource::Group",
      :null_object => true,
      :group_name => "aj",
      :gid => 500,
      :members => [ "aj"]
    )
    Chef::Resource::Group.stub!(:new).and_return(@current_resource)
    @pw_group = mock("Struct::Group",
      :null_object => true,
      :name => "staff",
      :gid => 20,
      :mem => [ "root", "aj" ]
      )
    Etc.stub!(:getgrnam).and_return(@pw_group)
    @provider = Chef::Provider::Group.new(@node, @new_resource)
  end
  
  it "should create a current resource with the same group_name as the new resource" do
    Chef::Resource::Group.should_receive(:new).with(@new_resource.name).and_return(@current_resource)
    @provider.load_current_resource    
  end
  
  it "should set the group name of the current resource to the group name of the new resource" do
    @current_resource.should_receive(:group_name).with(@new_resource.group_name)
    @provider.load_current_resource
  end
  
  it "should look up the group in /etc/group with getgrnam" do
    Etc.should_receive(:getgrnam).with(@new_resource.group_name).and_return(@pw_group)
    @provider.load_current_resource
  end
  
  it "should flip the value of exists if it cannot be found in /etc/group" do
    Etc.stub!(:getgrnam).and_raise(ArgumentError)
    @provider.load_current_resource
    @provider.group_exists.should be_false
  end
  
  { :gid => :gid,
    :members => :mem
  }.each do |group_attrib, getgrname_attrib|
    it "should set the current resources #{group_attrib} based on getgrnam #{getgrname_attrib}" do
      @current_resource.should_receive(group_attrib).with(@pw_group.send(getgrname_attrib))
      @provider.load_current_resource      
    end
  end
  
  it "should return the current resource" do
    @provider.load_current_resource.should eql(@current_resource)    
  end
end

describe Chef::Provider::Group, "compare_group" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group",
      :null_object => true,
      :group_name => "aj",
      :gid => 50,
      :members => [ "root", "aj"],
      :append => false
    )
    @current_resource = mock("Chef::Resource::Group",
      :null_object => true,
      :group_name => "aj",
      :gid => 50,
      :members => [ "root", "aj"]
    )
    @provider = Chef::Provider::Group.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end
  
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

describe Chef::Provider::Group, "action_create" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group",
      :null_object => true,
      :group_name => "aj",
      :gid => 50,
      :members => [ "root", "aj"]
    )
    @current_resource = mock("Chef::Resource::Group",
      :null_object => true,
      :group_name => "aj",
      :gid => 50,
      :members => [ "root", "aj"]
    )
    @provider = Chef::Provider::Group.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.group_exists = false
    @provider.stub!(:create_group).and_return(true)
    @provider.stub!(:manage_group).and_return(true)
  end
  
  it "should call create_group if the group does not exist" do
    @provider.should_receive(:create_group).and_return(true)
    @provider.action_create
  end
  
  it "should set the the new_resources updated flag when it creates the group" do
    @new_resource.should_receive(:updated=).with(true).and_return(true)
    @provider.action_create
  end
  
  it "should check to see if the group has mismatched attributes if the group exists" do
    @provider.group_exists = true
    @provider.should_receive(:compare_group).and_return(false)
    @provider.action_create
  end
  
  it "should call manage_group if the group exists and has mismatched attributes" do
    @provider.group_exists = true
    @provider.stub!(:compare_group).and_return(true)
    @provider.should_receive(:manage_group).and_return(true)
    @provider.action_create
  end
  
  it "should set the the new_resources updated flag when it creates the group if we call manage_group" do
    @provider.group_exists = true
    @provider.stub!(:compare_group).and_return(true)
    @provider.stub!(:manage_group).and_return(true)
    @new_resource.should_receive(:updated=).with(true).and_return(true)
    @provider.action_create
  end
end

describe Chef::Provider::Group, "action_remove" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group", 
      :null_object => true
    )
    @current_resource = mock("Chef::Resource::Group", 
      :null_object => true
    )
    @provider = Chef::Provider::Group.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.group_exists = false
    @provider.stub!(:remove_group).and_return(true)
  end
  
  it "should not call remove_group if the group does not exist" do
    @provider.should_not_receive(:remove_group) 
    @provider.action_remove
  end
  
  it "should call remove_group if the group exists" do
    @provider.group_exists = true
    @provider.should_receive(:remove_group)
    @provider.action_remove
  end
  
  it "should set the new_resources updated flag to true if the group is removed" do
    @provider.group_exists = true
    @new_resource.should_receive(:updated=).with(true).and_return(true)
    @provider.action_remove
  end
end

describe Chef::Provider::Group, "action_manage" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group", 
      :null_object => true
    )
    @current_resource = mock("Chef::Resource::Group", 
      :null_object => true
    )
    @provider = Chef::Provider::Group.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.group_exists = true
    @provider.stub!(:manage_group).and_return(true)
  end
 
  it "should run manage_group if the group exists and has mismatched attributes" do
    @provider.should_receive(:compare_group).and_return(true)
    @provider.should_receive(:manage_group).and_return(true)
    @provider.action_manage
  end
  
  it "should set the new resources updated flag to true if manage_group is called" do
    @provider.stub!(:compare_group).and_return(true)
    @provider.stub!(:manage_group).and_return(true)
    @new_resource.should_receive(:updated=).with(true).and_return(true)
    @provider.action_manage
  end
  
  it "should not run manage_group if the group does not exist" do
    @provider.group_exists = false
    @provider.should_not_receive(:manage_group)
    @provider.action_manage
  end
  
  it "should not run manage_group if the group exists but has no differing attributes" do
    @provider.should_receive(:compare_group).and_return(false)
    @provider.should_not_receive(:manage_group)
    @provider.action_manage
  end
end

describe Chef::Provider::Group, "action_modify" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group", 
      :null_object => true
    )
    @current_resource = mock("Chef::Resource::Group", 
      :null_object => true
    )
    @provider = Chef::Provider::Group.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.group_exists = true
    @provider.stub!(:manage_group).and_return(true)
  end
 
  it "should run manage_group if the group exists and has mismatched attributes" do
    @provider.should_receive(:compare_group).and_return(true)
    @provider.should_receive(:manage_group).and_return(true)
    @provider.action_modify
  end
  
  it "should set the new resources updated flag to true if manage_group is called" do
    @provider.stub!(:compare_group).and_return(true)
    @provider.stub!(:manage_group).and_return(true)
    @new_resource.should_receive(:updated=).with(true).and_return(true)
    @provider.action_modify
  end
  
  it "should not run manage_group if the group exists but has no differing attributes" do
    @provider.should_receive(:compare_group).and_return(false)
    @provider.should_not_receive(:manage_group)
    @provider.action_modify
  end
  
  it "should raise a Chef::Exceptions::Group if the group doesn't exist" do
    @provider.group_exists = false
    lambda { @provider.action_modify }.should raise_error(Chef::Exceptions::Group)
  end
end
