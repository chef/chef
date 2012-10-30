#
# Author:: Dreamcat4 (<dreamcat4@gmail.com>)
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

describe Chef::Provider::Group::Dscl do
  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Group.new("aj")
    @current_resource = Chef::Resource::Group.new("aj")
    @provider = Chef::Provider::Group::Dscl.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
    @status = mock("Process::Status", :exitstatus => 0) 
    @pid = 2342
    @stdin = StringIO.new
    @stdout = StringIO.new("\n")
    @stderr = StringIO.new("")
    @provider.stub!(:popen4).and_yield(@pid,@stdin,@stdout,@stderr).and_return(@status)
  end
  
  it "should run popen4 with the supplied array of arguments appended to the dscl command" do
    @provider.should_receive(:popen4).with("dscl . -cmd /Path arg1 arg2")
    @provider.dscl("cmd", "/Path", "arg1", "arg2")
  end

  it "should return an array of four elements - cmd, status, stdout, stderr" do
    dscl_retval = @provider.dscl("cmd /Path args")
    dscl_retval.should be_a_kind_of(Array)
    dscl_retval.should == ["dscl . -cmd /Path args",@status,"\n",""]
  end

  describe "safe_dscl" do
    before do
      @node = Chef::Node.new
      @provider = Chef::Provider::Group::Dscl.new(@node, @new_resource)
      @provider.stub!(:dscl).and_return(["cmd", @status, "stdout", "stderr"])
    end
 
    it "should run dscl with the supplied cmd /Path args" do
      @provider.should_receive(:dscl).with("cmd /Path args")
      @provider.safe_dscl("cmd /Path args")
    end

    describe "with the dscl command returning a non zero exit status for a delete" do
      before do
        @status = mock("Process::Status", :exitstatus => 1)
        @provider.stub!(:dscl).and_return(["cmd", @status, "stdout", "stderr"])
      end

      it "should return an empty string of standard output for a delete" do
        safe_dscl_retval = @provider.safe_dscl("delete /Path args")
        safe_dscl_retval.should be_a_kind_of(String)
        safe_dscl_retval.should == ""
      end

      it "should raise an exception for any other command" do
        lambda { @provider.safe_dscl("cmd /Path arguments") }.should raise_error(Chef::Exceptions::Group)
      end
    end

    describe "with the dscl command returning no such key" do
      before do
        @provider.stub!(:dscl).and_return(["cmd", @status, "No such key: ", "stderr"])
      end

      it "should raise an exception" do
        lambda { @provider.safe_dscl("cmd /Path arguments") }.should raise_error(Chef::Exceptions::Group)
      end
    end
 
    describe "with the dscl command returning a zero exit status" do
      it "should return the third array element, the string of standard output" do
        safe_dscl_retval = @provider.safe_dscl("cmd /Path args")
        safe_dscl_retval.should be_a_kind_of(String)
        safe_dscl_retval.should == "stdout"
      end
    end
  end

  describe "get_free_gid" do
    before do
      @node = Chef::Node.new
      @provider = Chef::Provider::Group::Dscl.new(@node, @new_resource)
      @provider.stub!(:safe_dscl).and_return("\naj      200\njt      201\n")
    end
  
    it "should run safe_dscl with list /Groups gid" do
      @provider.should_receive(:safe_dscl).with("list /Groups gid")
      @provider.get_free_gid
    end

    it "should return the first unused gid number on or above 200" do
      @provider.get_free_gid.should equal(202)
    end
  
    it "should raise an exception when the search limit is exhausted" do
      search_limit = 1
      lambda { @provider.get_free_gid(search_limit) }.should raise_error(RuntimeError)
    end
  end

  describe "gid_used?" do
    before do
      @node = Chef::Node.new
      @provider = Chef::Provider::Group::Dscl.new(@node, @new_resource)
      @provider.stub!(:safe_dscl).and_return("\naj      500\n")
    end

    it "should run safe_dscl with list /Groups gid" do
      @provider.should_receive(:safe_dscl).with("list /Groups gid")
      @provider.gid_used?(500)
    end
  
    it "should return true for a used gid number" do
      @provider.gid_used?(500).should be_true
    end

    it "should return false for an unused gid number" do
      @provider.gid_used?(501).should be_false
    end

    it "should return false if not given any valid gid number" do
      @provider.gid_used?(nil).should be_false
    end
  end

  describe "set_gid" do
    describe "with the new resource and a gid number which is already in use" do
      before do
        @provider.stub!(:gid_used?).and_return(true)
      end

      it "should raise an exception if the new resources gid is already in use" do
        lambda { @provider.set_gid }.should raise_error(Chef::Exceptions::Group)
      end
    end
  
    describe "with no gid number for the new resources" do
      it "should run get_free_gid and return a valid, unused gid number" do
        @provider.should_receive(:get_free_gid).and_return(501)
        @provider.set_gid
      end
    end

    describe "with blank gid number for the new resources" do
      before do
        @new_resource.instance_variable_set(:@gid, nil)
        @new_resource.stub!(:safe_dscl)
      end

      it "should run get_free_gid and return a valid, unused gid number" do
        @provider.should_receive(:get_free_gid).and_return(501)
        @provider.set_gid
      end
    end

    describe "with a valid gid number which is not already in use" do
      it "should run safe_dscl with create /Groups/group PrimaryGroupID gid" do
        @provider.stub(:get_free_gid).and_return(50)
        @provider.should_receive(:safe_dscl).with("list /Groups gid")
        @provider.should_receive(:safe_dscl).with("create /Groups/aj PrimaryGroupID 50").and_return(true)
        @provider.set_gid
      end
    end
  end

  describe "set_members" do

    describe "with existing members in the current resource and append set to false in the new resource" do
      before do
        @new_resource.stub!(:members).and_return([])
        @new_resource.stub!(:append).and_return(false)
        @current_resource.stub!(:members).and_return(["all", "your", "base"])
      end

      it "should log an appropriate message" do
        Chef::Log.should_receive(:debug).with("group[aj] removing group members all your base")
        @provider.set_members
      end

      it "should run safe_dscl with create /Groups/group GroupMembership to clear the Group's UID list" do
        @provider.should_receive(:safe_dscl).with("create /Groups/aj GroupMembers ''").and_return(true)
        @provider.should_receive(:safe_dscl).with("create /Groups/aj GroupMembership ''").and_return(true)
        @provider.set_members
      end
    end

    describe "with supplied members in the new resource" do
      before do
        @new_resource.members(["all", "your", "base"])
        @current_resource.members([])
      end

      it "should log an appropriate debug message" do
        Chef::Log.should_receive(:debug).with("group[aj] setting group members all, your, base")
        @provider.set_members
      end

      it "should run safe_dscl with append /Groups/group GroupMembership and group members all, your, base" do
        @provider.should_receive(:safe_dscl).with("create /Groups/aj GroupMembers ''").and_return(true)
        @provider.should_receive(:safe_dscl).with("append /Groups/aj GroupMembership all your base").and_return(true)
        @provider.should_receive(:safe_dscl).with("create /Groups/aj GroupMembership ''").and_return(true)
        @provider.set_members
      end
    end
  
    describe "with no members in the new resource" do
      before do
        @new_resource.append(true)
        @new_resource.members([])
      end

      it "should not call safe_dscl" do
        @provider.should_not_receive(:safe_dscl)
        @provider.set_members
      end
    end
  end

  describe "when loading the current system state" do
    before (:each) do
      @provider.load_current_resource
      @provider.define_resource_requirements
    end
    it "raises an error if the required binary /usr/bin/dscl doesn't exist" do
      File.should_receive(:exists?).with("/usr/bin/dscl").and_return(false)

      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Group)
    end

    it "doesn't raise an error if /usr/bin/dscl exists" do
      File.stub!(:exists?).and_return(true)
      lambda { @provider.process_resource_requirements }.should_not raise_error(Chef::Exceptions::Group)
    end
  end

  describe "when creating the group" do
    it "creates the group, password field, gid, and sets group membership" do
      @provider.should_receive(:set_gid).and_return(true)
      @provider.should_receive(:set_members).and_return(true)
      @provider.should_receive(:safe_dscl).with("create /Groups/aj Password '*'")
      @provider.should_receive(:safe_dscl).with("create /Groups/aj")
      @provider.create_group
    end
  end

  describe "managing the group" do
    it "should manage the group_name if it changed and the new resources group_name is not null" do
      @current_resource.group_name("oldval")
      @new_resource.group_name("newname")
      @provider.should_receive(:safe_dscl).with("create /Groups/newname")
      @provider.should_receive(:safe_dscl).with("create /Groups/newname Password '*'")
      @provider.manage_group
    end

    it "should manage the gid if it changed and the new resources gid is not null" do
      @current_resource.gid(23)
      @new_resource.gid(42)
      @provider.should_receive(:set_gid)
      @provider.manage_group
    end
    
    it "should manage the members if it changed and the new resources members is not null" do
      @current_resource.members(%{charlie root})
      @new_resource.members(%{crab revenge})
      @provider.should_receive(:set_members)
      @provider.manage_group
    end
  end

  describe "remove_group" do
    it "should run safe_dscl with delete /Groups/group and with the new resources group name" do
      @provider.should_receive(:safe_dscl).with("delete /Groups/aj").and_return(true)
      @provider.remove_group
    end
  end
end
