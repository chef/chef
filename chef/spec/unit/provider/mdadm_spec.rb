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

require 'spec_helper'
require 'ostruct'

describe Chef::Provider::Mdadm do

  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Mdadm.new('/dev/md1')
    @new_resource.devices ["/dev/sdz1","/dev/sdz2"]
    @new_resource.level   1
    @new_resource.chunk   256

    @provider = Chef::Provider::Mdadm.new(@new_resource, @run_context)
  end

  describe "when determining the current metadevice status" do
    it "should set the current resources mount point to the new resources mount point" do
      @provider.stub!(:shell_out!).and_return(OpenStruct.new(:status => 0))
      @provider.load_current_resource
      @provider.current_resource.name.should == '/dev/md1'
      @provider.current_resource.raid_device.should == '/dev/md1'
    end

    it "determines that the metadevice exists when mdadm exit code is zero" do
      @provider.stub!(:shell_out!).with("mdadm --detail --test /dev/md1", :returns => [0,4]).and_return(OpenStruct.new(:status => 0))
      @provider.load_current_resource
      @provider.current_resource.exists.should be_true
    end

    it "determines that the metadevice does not exist when mdadm exit code is 4" do
      @provider.stub!(:shell_out!).with("mdadm --detail --test /dev/md1", :returns => [0,4]).and_return(OpenStruct.new(:status => 4))
      @provider.load_current_resource
      @provider.current_resource.exists.should be_false
    end
  end

  describe "after the metadevice status is known" do
    before(:each) do
      @current_resource = Chef::Resource::Mdadm.new('/dev/md1')
      @current_resource.devices ["/dev/sdz1","/dev/sdz2"]
      @current_resource.level   1
      @current_resource.chunk   256
      @provider.stub!(:load_current_resource).and_return(true)
      @provider.current_resource = @current_resource
    end

    describe "when creating the metadevice" do
      it "should create the raid device if it doesnt exist" do
        @current_resource.exists(false)
        expected_command = "yes | mdadm --create /dev/md1 --chunk=256 --level 1 --metadata=0.90 --raid-devices 2 /dev/sdz1 /dev/sdz2"
        @provider.should_receive(:shell_out!).with(expected_command)
        @provider.run_action(:create)
      end

      it "should specify a bitmap only if set" do
        @current_resource.exists(false)
        @new_resource.bitmap('grow')
        expected_command = "yes | mdadm --create /dev/md1 --chunk=256 --level 1 --metadata=0.90 --bitmap=grow --raid-devices 2 /dev/sdz1 /dev/sdz2"
        @provider.should_receive(:shell_out!).with(expected_command)
        @provider.run_action(:create)
        @new_resource.should be_updated_by_last_action
      end

      it "should not create the raid device if it does exist" do
        @current_resource.exists(true)
        @provider.should_not_receive(:shell_out!)
        @provider.run_action(:create)
        @new_resource.should_not be_updated_by_last_action
      end
    end

    describe "when asembling the metadevice" do
      it "should assemble the raid device if it doesnt exist" do
        @current_resource.exists(false)
        expected_mdadm_cmd = "yes | mdadm --assemble /dev/md1 /dev/sdz1 /dev/sdz2"
        @provider.should_receive(:shell_out!).with(expected_mdadm_cmd)
        @provider.run_action(:assemble)
        @new_resource.should be_updated_by_last_action
      end

        it "should not assemble the raid device if it doesnt exist" do
        @current_resource.exists(true)
        @provider.should_not_receive(:shell_out!)
        @provider.run_action(:assemble)
        @new_resource.should_not be_updated_by_last_action
      end
    end

    describe "when stopping the metadevice" do

      it "should stop the raid device if it exists" do
        @current_resource.exists(true)
        expected_mdadm_cmd = "yes | mdadm --stop /dev/md1"
        @provider.should_receive(:shell_out!).with(expected_mdadm_cmd)
        @provider.run_action(:stop)
        @new_resource.should be_updated_by_last_action
      end

      it "should not attempt to stop the raid device if it does not exist" do
        @current_resource.exists(false)
        @provider.should_not_receive(:shell_out!)
        @provider.run_action(:stop)
        @new_resource.should_not be_updated_by_last_action
      end
    end
  end
end
