#
# Author:: Stephen Haynes (<sh@nomitor.com>)
# Copyright:: Copyright (c) 2009 OpsCode, Inc.
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

describe Chef::Provider::Group::Pw do
  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    
    @new_resource = Chef::Resource::Group.new("wheel")
    @new_resource.gid 50
    @new_resource.members [ "root", "aj"]

    @current_resource = Chef::Resource::Group.new("aj")
    @current_resource.gid 50
    @current_resource.members [ "root", "aj"]
    @provider = Chef::Provider::Group::Pw.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
  end
  
  describe "when setting options for the pw command" do
    it "does not set the gid option if gids match or are unmanaged" do
      @provider.set_options.should ==  " wheel"
    end
    
    it "sets the option for gid if it is not nil" do
      @new_resource.gid(42)
      @provider.set_options.should eql(" wheel -g '42'")
    end
  end

  describe "when creating a group" do
    it "should run pw groupadd with the return of set_options and set_members_option" do
      @new_resource.gid(23)
      @provider.should_receive(:run_command).with({ :command => "pw groupadd wheel -g '23' -M root,aj" }).and_return(true)
      @provider.create_group
    end
  end

  describe "when managing the group" do
  
    it "should run pw groupmod with the return of set_options" do
      @new_resource.gid(42)
      @provider.should_receive(:run_command).with({ :command => "pw groupmod wheel -g '42' -M root,aj" }).and_return(true)
      @provider.manage_group
    end

  end

  describe "when removing the group" do
    it "should run pw groupdel with the new resources group name" do
      @provider.should_receive(:run_command).with({ :command => "pw groupdel wheel" }).and_return(true)
      @provider.remove_group
    end
  end

  describe "when setting group membership" do
  
    describe "with an empty members array in both the new and current resource" do
      before do
        @new_resource.stub!(:members).and_return([])
        @current_resource.stub!(:members).and_return([])
      end
    
      it "should log an appropriate message" do
        Chef::Log.should_receive(:debug).with("group[wheel] not changing group members, the group has no members")
        @provider.set_members_option
      end
    
      it "should set no options" do
        @provider.set_members_option.should eql("")
      end
    end

    describe "with an empty members array in the new resource and existing members in the current resource" do
      before do
        @new_resource.stub!(:members).and_return([])
        @current_resource.stub!(:members).and_return(["all", "your", "base"])
      end
    
      it "should log an appropriate message" do
        Chef::Log.should_receive(:debug).with("group[wheel] removing group members all, your, base")
        @provider.set_members_option
      end
    
      it "should set the -d option with the members joined by ','" do
        @provider.set_members_option.should eql(" -d all,your,base")
      end
    end
  
    describe "with supplied members array in the new resource and an empty members array in the current resource" do
      before do
        @new_resource.stub!(:members).and_return(["all", "your", "base"])
        @current_resource.stub!(:members).and_return([])
      end
    
      it "should log an appropriate debug message" do
        Chef::Log.should_receive(:debug).with("group[wheel] setting group members to all, your, base")
        @provider.set_members_option
      end
    
      it "should set the -M option with the members joined by ','" do
        @provider.set_members_option.should eql(" -M all,your,base")
      end
    end
  end

  describe"load_current_resource" do
    before (:each) do 
      @provider.load_current_resource
      @provider.define_resource_requirements
    end
    it "should raise an error if the required binary /usr/sbin/pw doesn't exist" do
      File.should_receive(:exists?).with("/usr/sbin/pw").and_return(false)
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Group)
    end
  
    it "shouldn't raise an error if /usr/sbin/pw exists" do
      File.stub!(:exists?).and_return(true)
      lambda { @provider.process_resource_requirements }.should_not raise_error(Chef::Exceptions::Group)
    end
  end
end
