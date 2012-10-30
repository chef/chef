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

describe Chef::Provider::Group::Usermod do
  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Group.new("wheel")
    @new_resource.members [ "all", "your", "base" ]
    @provider = Chef::Provider::Group::Usermod.new(@new_resource, @run_context)
    @provider.stub!(:run_command)
  end
  
  describe "modify_group_members" do
  
    describe "with an empty members array" do
      before do
        @new_resource.stub!(:members).and_return([])
      end
    
      it "should log an appropriate message" do
        Chef::Log.should_receive(:debug).with("group[wheel] not changing group members, the group has no members")
        @provider.modify_group_members
      end
    end
  
    describe "with supplied members" do
      platforms = {
        "openbsd" => "-G",
        "netbsd" => "-G",
        "solaris" => "-a -G"
      }

      before do
        @new_resource.stub!(:members).and_return(["all", "your", "base"])
        File.stub!(:exists?).and_return(true)
      end

      it "should raise an error when setting the entire group directly" do
        @provider.define_resource_requirements
        @provider.load_current_resource
        @provider.instance_variable_set("@group_exists", true)
        @provider.action = :modify 
        lambda { @provider.run_action(@provider.process_resource_requirements) }.should raise_error(Chef::Exceptions::Group, "setting group members directly is not supported by #{@provider.to_s}, must set append true in group")
      end
    
      platforms.each do |platform, flags|
        it "should usermod each user when the append option is set on #{platform}" do
          @node.automatic_attrs[:platform] = platform
          @new_resource.stub!(:append).and_return(true)
          @provider.should_receive(:run_command).with({:command => "usermod #{flags} wheel all"})
          @provider.should_receive(:run_command).with({:command => "usermod #{flags} wheel your"})
          @provider.should_receive(:run_command).with({:command => "usermod #{flags} wheel base"})
          @provider.modify_group_members
        end
      end
    end
  end

  describe "when loading the current resource" do
    before(:each) do
      File.stub!(:exists?).and_return(false)
      @provider.define_resource_requirements
    end

    it "should raise an error if the required binary /usr/sbin/usermod doesn't exist" do
      File.stub!(:exists?).and_return(true)
      File.should_receive(:exists?).with("/usr/sbin/usermod").and_return(false)
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Group)
    end
  
    it "shouldn't raise an error if the required binaries exist" do
      File.stub!(:exists?).and_return(true)
      lambda { @provider.process_resource_requirements }.should_not raise_error(Chef::Exceptions::Group)
    end
  end
end
