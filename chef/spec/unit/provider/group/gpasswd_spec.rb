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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

describe Chef::Provider::Group::Gpasswd, "modify_group_members" do
  before do
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, {})
    @new_resource = Chef::Resource::Group.new("wheel")
    @new_resource.members %w{lobster rage fist}
    @new_resource.append false
    @provider = Chef::Provider::Group::Gpasswd.new(@new_resource, @run_context)
    #@provider.stub!(:run_command).and_return(true)
  end

  describe "when determining the current group state" do
    before do
      # @node = Chef::Node.new
      # @new_resource = mock("Chef::Resource::Group", :null_object => true, :group_name => "aj")
      # @provider = Chef::Provider::Group::Gpasswd.new(@node, @new_resource)
      # File.stub!(:exists?).and_return(false)
    end

    it "should raise an error if the required binary /usr/sbin/groupadd doesn't exist" do
      File.should_receive(:exists?).with("/usr/sbin/groupadd").and_return(false)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Group)
    end
    it "should raise an error if the required binary /usr/sbin/groupmod doesn't exist" do
      File.should_receive(:exists?).with("/usr/sbin/groupadd").and_return(true)
      File.should_receive(:exists?).with("/usr/sbin/groupmod").and_return(false)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Group)
    end
    it "should raise an error if the required binary /usr/sbin/groupdel doesn't exist" do
      File.should_receive(:exists?).with("/usr/sbin/groupadd").and_return(true)
      File.should_receive(:exists?).with("/usr/sbin/groupmod").and_return(true)
      File.should_receive(:exists?).with("/usr/sbin/groupdel").and_return(false)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Group)
    end
    it "should raise an error if the required binary /usr/bin/gpasswd doesn't exist" do
      File.should_receive(:exists?).with("/usr/sbin/groupadd").and_return(true)
      File.should_receive(:exists?).with("/usr/sbin/groupmod").and_return(true)
      File.should_receive(:exists?).with("/usr/sbin/groupdel").and_return(true)
      File.should_receive(:exists?).with("/usr/bin/gpasswd").and_return(false)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Group)
    end

    it "shouldn't raise an error if the required binaries exist" do
      File.stub!(:exists?).and_return(true)
      lambda { @provider.load_current_resource }.should_not raise_error(Chef::Exceptions::Group)
    end
  end

  describe "after the group's current state is known" do
    before do
      @current_resource = @new_resource.dup
      @provider.current_resource = @new_resource
    end
    describe "when no group members are specified" do
      before do
        @new_resource.members([])
      end

      it "logs a message and does not modify group membership" do
        Chef::Log.should_receive(:debug).with("group[wheel] not changing group members, the group has no members")
        @provider.should_not_receive(:shell_out!)
        @provider.modify_group_members
      end
    end

    describe "when the resource specifies group members" do
      it "should log an appropriate debug message" do
        Chef::Log.should_receive(:debug).with("group[wheel] setting group members to lobster, rage, fist")
        @provider.stub!(:shell_out!)
        @provider.modify_group_members
      end

      it "should run gpasswd with the members joined by ',' followed by the target group" do
        @provider.should_receive(:shell_out!).with("gpasswd -M lobster,rage,fist wheel")
        @provider.modify_group_members
      end

      it "should run gpasswd individually for each user when the append option is set" do
        @new_resource.append(true)
        @provider.should_receive(:shell_out!).with("gpasswd -a lobster wheel")
        @provider.should_receive(:shell_out!).with("gpasswd -a rage wheel")
        @provider.should_receive(:shell_out!).with("gpasswd -a fist wheel")
        @provider.modify_group_members
      end

    end
  end
end
