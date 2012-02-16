#
# Author:: Joe Williams (<joe@joetify.com>)
# Copyright:: Copyright (c) 2009 Joe Williams
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
require 'ostruct'

describe "initialize" do

  before(:each) do
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, {})

    @new_resource = Chef::Resource::Mdadm.new('/dev/md1')
    @new_resource.devices ["/dev/sdz1","/dev/sdz2"]
    @new_resource.level   1
    @new_resource.chunk   256

    @provider = Chef::Provider::Mdadm.new(@new_resource, @run_context)
    #Chef::Resource::Mdadm.stub!(:new).and_return(@current_resource)

    # @status = mock("Status", :exitstatus => 0)
    # @provider.stub!(:popen4).and_return(@status)
    # @stdin = mock("STDIN", :null_object => true)
    # @stdout = mock("STDOUT", :null_object => true)
    # @stderr = mock("STDERR", :null_object => true)
    # @pid = mock("PID", :null_object => true)
  end

  describe "when determining the current metadevice status" do

    it "should set the current resources mount point to the new resources mount point" do
      @provider.stub!(:shell_out!).and_return(OpenStruct.new(:stdout => ''))
      @provider.load_current_resource()
      @provider.current_resource.name.should == '/dev/md1'
      @provider.current_resource.raid_device.should == '/dev/md1'
    end

    it "determines that the metadevice exists when mdadm output shows the metadevice" do
      @provider.stub!(:shell_out!).with("mdadm --detail --scan").and_return(OpenStruct.new(:stdout => '/dev/md1'))
      @provider.load_current_resource
      @provider.current_resource.exists.should be_true
    end
  end

  describe "after the metadevice status is known" do
    before(:each) do
      @current_resource = Chef::Resource::Mdadm.new('/dev/md1')
      @current_resource.devices ["/dev/sdz1","/dev/sdz2"]
      @current_resource.level   1
      @current_resource.chunk   256


      @provider.current_resource = @current_resource
    end

    describe "when creating the metadevice" do
      it "should create the raid device if it doesnt exist" do
        @current_resource.exists(false)
        expected_command = "yes | mdadm --create /dev/md1 --chunk=256 --level 1 --metadata=0.90 --raid-devices 2 /dev/sdz1 /dev/sdz2"
        @provider.should_receive(:shell_out!).with(expected_command)
        @provider.action_create
      end

      it "should not create the raid device if it does exist" do
        @current_resource.exists(true)
        @provider.should_not_receive(:shell_out!)
        @provider.action_create
      end
    end

    describe "when asembling the metadevice" do
      it "should assemble the raid device if it doesnt exist" do
        @current_resource.exists(false)
        expected_mdadm_cmd = "yes | mdadm --assemble /dev/md1 /dev/sdz1 /dev/sdz2"
        @provider.should_receive(:shell_out!).with(expected_mdadm_cmd)
        @provider.action_assemble
      end

        it "should not assemble the raid device if it doesnt exist" do
        @current_resource.exists(true)
        @provider.should_not_receive(:shell_out!)
        @provider.action_assemble
      end
    end

    describe "when stopping the metadevice" do

      it "should stop the raid device if it exists" do
        @current_resource.exists(true)
        expected_mdadm_cmd = "yes | mdadm --stop /dev/md1"
        @provider.should_receive(:shell_out!).with(expected_mdadm_cmd)
        @provider.action_stop
      end

      it "should not attempt to stop the raid device if it does not exist" do
        @current_resource.exists(false)
        @provider.should_not_receive(:shell_out!)
        @provider.action_stop
      end
    end
  end
end
