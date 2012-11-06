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

describe Chef::Provider::Group::Groupadd, "set_options" do
  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Group.new("aj")
    @new_resource.gid(50)
    @new_resource.members(["root", "aj"])
    @new_resource.system false
    @current_resource = Chef::Resource::Group.new("aj")
    @current_resource.gid(50)
    @current_resource.members(["root", "aj"])
    @current_resource.system false
    @provider = Chef::Provider::Group::Groupadd.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
  end

  field_list = {
    :gid => "-g"
  }

  field_list.each do |attribute, option|
    it "should check for differences in #{attribute.to_s} between the current and new resources" do
        @new_resource.should_receive(attribute)
        @current_resource.should_receive(attribute)
        @provider.set_options
    end
    it "should set the option for #{attribute} if the new resources #{attribute} is not null" do
      @new_resource.stub!(attribute).and_return("wowaweea")
      @provider.set_options.should eql(" #{option} '#{@new_resource.send(attribute)}' #{@new_resource.group_name}")
    end
  end

  it "should combine all the possible options" do
    match_string = ""
    field_list.sort{ |a,b| a[0] <=> b[0] }.each do |attribute, option|
      @new_resource.stub!(attribute).and_return("hola")
      match_string << " #{option} 'hola'"
    end
    match_string << " aj"
    @provider.set_options.should eql(match_string)
  end

  describe "when we want to create a system group" do
    it "should not set groupadd_options '-r' when system is false" do
      @new_resource.system(false)
      @provider.groupadd_options.should_not =~ /-r/
    end

    it "should set groupadd -r if system is true" do
      @new_resource.system(true)
      @provider.groupadd_options.should == " -r"
    end
  end
end

describe Chef::Provider::Group::Groupadd, "create_group" do
  before do
    @node = Chef::Node.new
    @new_resource = Chef::Resource::Group.new("aj")
    @provider = Chef::Provider::Group::Groupadd.new(@node, @new_resource)
    @provider.stub!(:run_command).and_return(true)
    @provider.stub!(:set_options).and_return(" monkey")
    @provider.stub!(:groupadd_options).and_return("")
    @provider.stub!(:modify_group_members).and_return(true)
  end

  it "should run groupadd with the return of set_options" do
    @provider.should_receive(:run_command).with({ :command => "groupadd monkey" }).and_return(true)
    @provider.create_group
  end

  it "should modify the group members" do
    @provider.should_receive(:modify_group_members).and_return(true)
    @provider.create_group
  end
end

describe Chef::Provider::Group::Groupadd do
  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Group.new("aj")
    @provider = Chef::Provider::Group::Groupadd.new(@new_resource, @run_context)
    @provider.stub!(:run_command).and_return(true)
    @provider.stub!(:set_options).and_return(" monkey")
  end

  describe "manage group" do

    it "should run groupmod with the return of set_options" do
      @provider.stub!(:modify_group_members).and_return(true)
      @provider.should_receive(:run_command).with({ :command => "groupmod monkey" }).and_return(true)
      @provider.manage_group
    end

    it "should modify the group members" do
      @provider.should_receive(:modify_group_members).and_return(true)
      @provider.manage_group
    end
  end

  describe "remove_group" do

    it "should run groupdel with the new resources group name" do
      @provider.should_receive(:run_command).with({ :command => "groupdel aj" }).and_return(true)
      @provider.remove_group
    end
  end

  describe "modify_group_members" do

    it "should raise an error when calling modify_group_members" do
      lambda { @provider.modify_group_members }.should raise_error(Chef::Exceptions::Group, "you must override modify_group_members in #{@provider.to_s}")
    end
  end

  describe "load_current_resource" do
    before do
      File.stub!(:exists?).and_return(false)
      @provider.define_resource_requirements
    end
    it "should raise an error if the required binary /usr/sbin/groupadd doesn't exist" do
      File.should_receive(:exists?).with("/usr/sbin/groupadd").and_return(false)
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Group)
    end
    it "should raise an error if the required binary /usr/sbin/groupmod doesn't exist" do
      File.should_receive(:exists?).with("/usr/sbin/groupadd").and_return(true)
      File.should_receive(:exists?).with("/usr/sbin/groupmod").and_return(false)
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Group)
    end
    it "should raise an error if the required binary /usr/sbin/groupdel doesn't exist" do
      File.should_receive(:exists?).with("/usr/sbin/groupadd").and_return(true)
      File.should_receive(:exists?).with("/usr/sbin/groupmod").and_return(true)
      File.should_receive(:exists?).with("/usr/sbin/groupdel").and_return(false)
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Group)
    end

  end
end
