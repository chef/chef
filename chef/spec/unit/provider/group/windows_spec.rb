#
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Copyright:: Copyright (c) 2010 VMware, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

class Chef
  class Util
    class Windows
      class NetGroup
      end
    end
  end
end

describe Chef::Provider::Group::Windows, "create_group" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group", :null_object => true)
    @net_group = mock("Chef::Util::Windows::NetGroup",
      :null_object => true
    )
    Chef::Util::Windows::NetGroup.stub!(:new).and_return(@net_group)
    @net_group.stub!(:local_add)
    @provider = Chef::Provider::Group::Windows.new(@node, @new_resource)
  end
  
  it "should call @net_group.local_add" do
    @net_group.should_receive(:local_add)
    @provider.create_group
  end
end

describe Chef::Provider::Group::Windows, "manage_group" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group",
      :null_object => true,
      :members => [ "us" ])
    @current_resource = mock("Chef::Resource::Group",
      :null_object => true,
      :members => [ "all", "your", "base" ]
    )
    @net_group = mock("Chef::Util::Windows::NetGroup",
      :null_object => true
    )
    Chef::Util::Windows::NetGroup.stub!(:new).and_return(@net_group)
    @net_group.stub!(:local_add_members)
    @net_group.stub!(:local_set_members)
    @provider = Chef::Provider::Group::Windows.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end
  
  it "should call @net_group.local_set_members" do
    @new_resource.stub!(:append).and_return(false)
    @net_group.should_receive(:local_set_members).with(@new_resource.members)
    @provider.manage_group
  end

  it "should call @net_group.local_add_members" do
    @new_resource.stub!(:append).and_return(true)
    @net_group.should_receive(:local_add_members).with(@new_resource.members)
    @provider.manage_group
  end

  it "should call @net_group.local_set_members if append fails" do
    @new_resource.stub!(:append).and_return(true)
    @net_group.stub!(:local_add_members).and_raise(ArgumentError)
    @net_group.should_receive(:local_add_members).with(@new_resource.members)
    @net_group.should_receive(:local_set_members).with(@new_resource.members + @current_resource.members)
    @provider.manage_group
  end

end

describe Chef::Provider::Group::Windows, "remove_group" do
  before do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Group",
      :null_object => true,
      :group_name => "aj"
    )
    @net_group = mock("Chef::Util::Windows::NetGroup",
      :null_object => true
    )
    Chef::Util::Windows::NetGroup.stub!(:new).and_return(@net_group)
    @provider = Chef::Provider::Group::Windows.new(@node, @new_resource)
    @provider.stub!(:run_command).and_return(true)
  end
  
  it "should call @net_group.local_delete" do
    @net_group.should_receive(:local_delete)
    @provider.remove_group
  end
end
