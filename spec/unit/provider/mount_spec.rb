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

require 'spec_helper'

describe Chef::Provider::Mount do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    
    @new_resource = Chef::Resource::Mount.new('/tmp/foo')
    @new_resource.device      "/dev/sdz1"
    @new_resource.name        "/tmp/foo"
    @new_resource.mount_point "/tmp/foo"
    @new_resource.fstype      "ext3"
    
    @current_resource = Chef::Resource::Mount.new('/tmp/foo')
    @current_resource.device      "/dev/sdz1"
    @current_resource.name        "/tmp/foo"
    @current_resource.mount_point "/tmp/foo"
    @current_resource.fstype      "ext3"

    @provider = Chef::Provider::Mount.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
  end
  
  describe "when the target state is a mounted filesystem" do

    it "should mount the filesystem if it isn't mounted" do
      @current_resource.stub!(:mounted).and_return(false)
      @provider.should_receive(:mount_fs).with.and_return(true)
      @provider.run_action(:mount)
      @new_resource.should be_updated_by_last_action
    end

    it "should not mount the filesystem if it is mounted" do
      @current_resource.stub!(:mounted).and_return(true)
      @provider.should_not_receive(:mount_fs)
      @provider.run_action(:mount)
      @new_resource.should_not be_updated_by_last_action
    end

  end

  describe "when the target state is an unmounted filesystem" do
    it "should umount the filesystem if it is mounted" do
      @current_resource.stub!(:mounted).and_return(true)
      @provider.should_receive(:umount_fs).with.and_return(true)
      @provider.run_action(:umount)
      @new_resource.should be_updated_by_last_action
    end

    it "should not umount the filesystem if it is not mounted" do
      @current_resource.stub!(:mounted).and_return(false)
      @provider.should_not_receive(:umount_fs)
      @provider.run_action(:umount)
      @new_resource.should_not be_updated_by_last_action
    end
  end

  describe "when the filesystem should be remounted and the resource supports remounting" do
    before do
      @new_resource.supports[:remount] = true
    end
    
    it "should remount the filesystem if it is mounted" do
      @current_resource.stub!(:mounted).and_return(true)
      @provider.should_receive(:remount_fs).and_return(true)
      @provider.run_action(:remount)
      @new_resource.should be_updated_by_last_action
    end

    it "should not remount the filesystem if it is not mounted" do
      @current_resource.stub!(:mounted).and_return(false)
      @provider.should_not_receive(:remount_fs)
      @provider.run_action(:remount)
      @new_resource.should_not be_updated_by_last_action
    end
  end
  describe "when the filesystem should be remounted and the resource does not support remounting" do 
    before do 
      @new_resource.supports[:remount] = false
    end

    it "should fail to remount the filesystem" do
      @provider.should_not_receive(:remount_fs)
      lambda {@provider.run_action(:remount)}.should raise_error(Chef::Exceptions::UnsupportedAction)
      @new_resource.should_not be_updated_by_last_action
    end

  end
  describe "when enabling the filesystem to be mounted" do
    it "should enable the mount if it isn't enable" do
      @current_resource.stub!(:enabled).and_return(false)
      @provider.should_not_receive(:mount_options_unchanged?)
      @provider.should_receive(:enable_fs).and_return(true)
      @provider.run_action(:enable)
      @new_resource.should be_updated_by_last_action
    end

    it "should enable the mount if it is enabled and mount options have changed" do
      @current_resource.stub!(:enabled).and_return(true)
      @provider.should_receive(:mount_options_unchanged?).and_return(false)
      @provider.should_receive(:enable_fs).and_return(true)
      @provider.run_action(:enable)
      @new_resource.should be_updated_by_last_action
    end

    it "should not enable the mount if it is enabled and mount options have not changed" do
      @current_resource.stub!(:enabled).and_return(true)
      @provider.should_receive(:mount_options_unchanged?).and_return(true)
      @provider.should_not_receive(:enable_fs).and_return(true)
      @provider.run_action(:enable)
      @new_resource.should_not be_updated_by_last_action
    end
  end

  describe "when the target state is to disable the mount" do
    it "should disable the mount if it is enabled" do
      @current_resource.stub!(:enabled).and_return(true)
      @provider.should_receive(:disable_fs).with.and_return(true)
      @provider.run_action(:disable)
      @new_resource.should be_updated_by_last_action
    end

    it "should not disable the mount if it isn't enabled" do
      @current_resource.stub!(:enabled).and_return(false)
      @provider.should_not_receive(:disable_fs)
      @provider.run_action(:disable)
      @new_resource.should_not be_updated_by_last_action
    end
  end


  it "should delegates the mount implementation to subclasses" do
    lambda { @provider.mount_fs }.should raise_error(Chef::Exceptions::UnsupportedAction)
  end

  it "should delegates the umount implementation to subclasses" do
    lambda { @provider.umount_fs }.should raise_error(Chef::Exceptions::UnsupportedAction)
  end

  it "should delegates the remount implementation to subclasses" do
    lambda { @provider.remount_fs }.should raise_error(Chef::Exceptions::UnsupportedAction)
  end

  it "should delegates the enable implementation to subclasses" do
    lambda { @provider.enable_fs }.should raise_error(Chef::Exceptions::UnsupportedAction)
  end

  it "should delegates the disable implementation to subclasses" do
    lambda { @provider.disable_fs }.should raise_error(Chef::Exceptions::UnsupportedAction)
  end
end
