#
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Copyright:: Copyright 2010-2016, VMware, Inc.
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

class Chef
  class Util
    class Windows
      class NetGroup
      end
    end
  end
end

describe Chef::Provider::Group::Windows do
  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Group.new("staff")
    @net_group = double("Chef::Util::Windows::NetGroup")
    allow(Chef::Util::Windows::NetGroup).to receive(:new).and_return(@net_group)
    @provider = Chef::Provider::Group::Windows.new(@new_resource, @run_context)
  end

  describe "when creating the group" do
    it "should call @net_group.local_add" do
      expect(@net_group).to receive(:local_set_members).with([])
      expect(@net_group).to receive(:local_add)
      @provider.create_group
    end
  end

  describe "manage_group" do
    before do
      @new_resource.members([ "us" ])
      @current_resource = Chef::Resource::Group.new("staff")
      @current_resource.members %w{all your base}
      @new_resource.excluded_members %w{all}

      allow(Chef::Util::Windows::NetGroup).to receive(:new).and_return(@net_group)
      allow(@net_group).to receive(:local_add_members)
      allow(@net_group).to receive(:local_set_members)
      allow(@provider).to receive(:lookup_account_name)
      allow(@provider).to receive(:validate_member!).and_return(true)
      @provider.current_resource = @current_resource
    end

    it "should call @net_group.local_set_members" do
      @new_resource.append(false)
      expect(@net_group).to receive(:local_set_members).with(@new_resource.members)
      @provider.manage_group
    end

    it "should call @net_group.local_add_members" do
      @new_resource.append(true)
      expect(@net_group).to receive(:local_add_members).with(@new_resource.members)
      @provider.manage_group
    end

    it "should call @net_group.local_delete_members" do
      @new_resource.append(true)
      allow(@provider).to receive(:lookup_account_name).with("all").and_return("all")
      expect(@net_group).to receive(:local_delete_members).with(@new_resource.excluded_members)
      @provider.manage_group
    end
  end

  describe "remove_group" do
    before do
      allow(Chef::Util::Windows::NetGroup).to receive(:new).and_return(@net_group)
      allow(@provider).to receive(:run_command).and_return(true)
    end

    it "should call @net_group.local_delete" do
      expect(@net_group).to receive(:local_delete)
      @provider.remove_group
    end
  end
end

describe Chef::Provider::Group::Windows, "NetGroup" do
  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Group.new("Creating a new group")
    @new_resource.group_name "Remote Desktop Users"
  end
  it "sets group_name correctly" do
    expect(Chef::Util::Windows::NetGroup).to receive(:new).with("Remote Desktop Users")
    Chef::Provider::Group::Windows.new(@new_resource, @run_context)
  end
end
