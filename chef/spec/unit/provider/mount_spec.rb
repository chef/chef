#
# Author:: Joshua Timberman (<joshua@opscode.com>)
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

describe Chef::Provider::Mount, "initialize" do
  
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource", :null_object => true)
  end
  
  it "should return a Chef::Provider::Mount object" do
    provider = Chef::Provider::Mount.new(@node, @new_resource)
    provider.should be_a_kind_of(Chef::Provider::Mount)
  end
  
end

describe Chef::Provider::Mount, "action_mount" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Mount", 
      :null_object => true,
      :name => "chef",
      :mount_point => "chef"
    )
    @current_resource = mock("Chef::Resource::Mount",
      :null_object => true,
      :name => "chef",
      :mount_point => "chef"
    )
    @provider = Chef::Provider::Mount.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:mount_fs).and_return(true)
  end
  
  it "should execute the mount command" do
    @current_resource.stub!(:mounted).and_return(false)
    @provider.should_receive(:mount_fs).with.and_return(true)
    @provider.action_mount
  end
end

describe Chef::Provider::Mount, "action_umount" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Mount", 
      :null_object => true,
      :name => "chef",
      :mount_point => "chef"
    )
    @current_resource = mock("Chef::Resource::Mount",
      :null_object => true,
      :name => "chef",
      :mount_point => "chef"
    )
    @provider = Chef::Provider::Mount.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:umount_fs).and_return(true)
  end
  
  it "should execute the umount command" do
    @current_resource.stub!(:mounted).and_return(true)
    @provider.should_receive(:umount_fs).with.and_return(true)
    @provider.action_umount
  end
end

describe Chef::Provider::Mount, "action_remount" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Mount", 
      :null_object => true,
      :name => "chef",
      :mount_point => "chef"
    )
    @current_resource = mock("Chef::Resource::Mount",
      :null_object => true,
      :name => "chef",
      :mount_point => "chef",
      :supports => { :remount => false }
    )
    @provider = Chef::Provider::Mount.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:remount_fs).and_return(true)
    @current_resource.stub!(:supports).and_return({:remount => true})
  end
  
  it "should execute command for remount if remount is supported" do
    @current_resource.stub!(:mounted).and_return(true)
    @provider.should_receive(:remount_fs).and_return(true)
    @provider.remount_fs
  end
end

