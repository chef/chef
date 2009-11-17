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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::Mount, "initialize" do

  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource", :null_object => true)
  end

  it "should return a Chef::Provider::Mount object" do
    provider = Chef::Provider::Mount.new(@node, @new_resource)
    provider.should be_a_kind_of(Chef::Provider::Mount)
  end

end

describe Chef::Provider::Mount, "action_mount" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Mount",
    :null_object => true,
    :device => "/dev/sdz1",
    :name => "/tmp/foo",
    :mount_point => "/tmp/foo",
    :fstype => "ext3",
    :mounted => false,
    :enabled => false
    )
    @current_resource = mock("Chef::Resource::Mount",
    :null_object => true,
    :device => "/dev/sdz1",
    :name => "/tmp/foo",
    :mount_point => "/tmp/foo",
    :fstype => "ext3",
    :mounted => false,
    :enabled => false
    )
    @provider = Chef::Provider::Mount.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:mount_fs).and_return(true)
  end

  it "should mount the filesystem if it isn't mounted" do
    @current_resource.stub!(:mounted).and_return(false)
    @provider.should_receive(:mount_fs).with.and_return(true)
    @provider.action_mount
  end

  it "should not mount the filesystem if it is mounted" do
    @current_resource.stub!(:mounted).and_return(true)
    @provider.should_not_receive(:mount_fs).with.and_return(true)
    @provider.action_mount
  end

end

describe Chef::Provider::Mount, "action_umount" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Mount",
    :null_object => true,
    :device => "/dev/sdz1",
    :name => "/tmp/foo",
    :mount_point => "/tmp/foo",
    :fstype => "ext3",
    :mounted => false,
    :enabled => false
    )
    @current_resource = mock("Chef::Resource::Mount",
    :null_object => true,
    :device => "/dev/sdz1",
    :name => "/tmp/foo",
    :mount_point => "/tmp/foo",
    :fstype => "ext3",
    :mounted => false,
    :enabled => false
    )
    @provider = Chef::Provider::Mount.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:umount_fs).and_return(true)
  end

  it "should umount the filesystem if it is mounted" do
    @current_resource.stub!(:mounted).and_return(true)
    @provider.should_receive(:umount_fs).with.and_return(true)
    @provider.action_umount
  end

  it "should not umount the filesystem if it is not mounted" do
    @current_resource.stub!(:mounted).and_return(false)
    @provider.should_not_receive(:umount_fs).with.and_return(true)
    @provider.action_umount
  end
end

describe Chef::Provider::Mount, "action_remount" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Mount",
    :null_object => true,
    :device => "/dev/sdz1",
    :name => "/tmp/foo",
    :mount_point => "/tmp/foo",
    :fstype => "ext3",
    :mounted => false,
    :enabled => false
    )
    @current_resource = mock("Chef::Resource::Mount",
    :null_object => true,
    :device => "/dev/sdz1",
    :name => "/tmp/foo",
    :mount_point => "/tmp/foo",
    :fstype => "ext3",
    :mounted => false,
    :enabled => false
    )
    @provider = Chef::Provider::Mount.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:remount_fs).and_return(true)
    @current_resource.stub!(:supports).and_return({:remount => true})
  end

  it "should remount the filesystem if remount is support and it is mounted" do
    @current_resource.stub!(:mounted).and_return(true)
    @provider.should_receive(:remount_fs).and_return(true)
    @provider.action_remount
  end

  it "should not remount the filesystem if it is not mounted" do
    @current_resource.stub!(:mounted).and_return(false)
    @provider.should_not_receive(:remount_fs).and_return(true)
    @provider.action_remount
  end
end

describe Chef::Provider::Mount, "action_enable" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Mount",
    :null_object => true,
    :device => "/dev/sdz1",
    :name => "/tmp/foo",
    :mount_point => "/tmp/foo",
    :fstype => "ext3",
    :mounted => false,
    :enabled => false
    )
    @current_resource = mock("Chef::Resource::Mount",
    :null_object => true,
    :device => "/dev/sdz1",
    :name => "/tmp/foo",
    :mount_point => "/tmp/foo",
    :fstype => "ext3",
    :mounted => false,
    :enabled => false
    )
    @provider = Chef::Provider::Mount.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:enable_fs).and_return(true)
  end

  it "should enable the mount if it isn't enable" do
    @current_resource.stub!(:enabled).and_return(false)
    @provider.should_receive(:enable_fs).with.and_return(true)
    @provider.action_enable
  end

  it "should not enable the mount if it is enabled" do
    @current_resource.stub!(:enabled).and_return(true)
    @provider.should_not_receive(:enable_fs).with.and_return(true)
    @provider.action_enable
  end
end

describe Chef::Provider::Mount, "action_disable" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Mount",
    :null_object => true,
    :device => "/dev/sdz1",
    :name => "/tmp/foo",
    :mount_point => "/tmp/foo",
    :fstype => "ext3",
    :mounted => false,
    :enabled => false
    )
    @current_resource = mock("Chef::Resource::Mount",
    :null_object => true,
    :device => "/dev/sdz1",
    :name => "/tmp/foo",
    :mount_point => "/tmp/foo",
    :fstype => "ext3",
    :mounted => false,
    :enabled => false
    )
    @provider = Chef::Provider::Mount.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:disable_fs).and_return(true)
  end

  it "should disable the mount if it is enabled" do
    @current_resource.stub!(:enabled).and_return(true)
    @provider.should_receive(:disable_fs).with.and_return(true)
    @provider.action_disable
  end

  it "should not disable the mount if it isn't enabled" do
    @current_resource.stub!(:enabled).and_return(false)
    @provider.should_not_receive(:disable_fs).with.and_return(true)
    @provider.action_disable
  end
end

%w{mount umount remount enable disable}.each do |act|
  act_string = "#{act}_fs"

  describe Chef::Provider::Service, act_string do
    before(:each) do
      @node = mock("Chef::Node", :null_object => true)
      @new_resource = mock("Chef::Resource::Mount",
      :null_object => true,
      :device => "/dev/sdz1",
      :name => "/tmp/foo",
      :mount_point => "/tmp/foo",
      :fstype => "ext3",
      :mounted => false
      )
      @current_resource = mock("Chef::Resource::Mount",
      :null_object => true,
      :device => "/dev/sdz1",
      :name => "/tmp/foo",
      :mount_point => "/tmp/foo",
      :fstype => "ext3",
      :mounted => false
      )
      @provider = Chef::Provider::Mount.new(@node, @new_resource)
      @provider.current_resource = @current_resource

    end

    it "should raise Chef::Exceptions::UnsupportedAction on an unsupported action" do
      lambda { @provider.send(act_string) }.should raise_error(Chef::Exceptions::UnsupportedAction)
    end
  end
end
