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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

describe Chef::Provider::Mount::Mount, "load_current_resource" do
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
    @new_resource.stub!(:supports).and_return({:remount => false})
    
    @current_resource = mock("Chef::Resource::Mount", 
      :null_object => true,
      :device => "/dev/sdz1",
      :name => "/tmp/foo",
      :mount_point => "/tmp/foo",
      :fstype => "ext3",
      :mounted => false
    )
    
    @provider = Chef::Provider::Mount::Mount.new(@node, @new_resource)
    Chef::Resource::Mount.stub!(:new).and_return(@current_resource)
    
    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end
  
  it "should create a current resource with the name of the new resource" do
    Chef::Resource::Mount.should_receive(:new).and_return(@current_resource)
    @provider.load_current_resource()
  end
  
  it "should set the current resources mount point to the new resources mount point" do
    @current_resource.should_receive(:mount_point).with(@new_resource.mount_point)
    @provider.load_current_resource()
  end
  
  it "should set mounted true if the mount point is found in the mounts list" do
    @stdout.stub!(:each).and_yield("#{@new_resource.device} on #{@new_resource.mount_point}")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(0)
    @current_resource.should_receive(:mounted).with(true)
    @provider.load_current_resource()
  end
  
  it "mounted should be false if the mount point is not found in the mounts list" do
    @stdout.stub!(:each).and_yield("#{@new_resource.mount_point} on #{@new_resource.mount_point}")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(0)
    @current_resource.should_receive(:mounted).with(false)
    @provider.load_current_resource()
  end
  
end

describe Chef::Provider::Mount::Mount, "mount_fs" do
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
    @new_resource.stub!(:supports).and_return({:remount => false})
    
    @current_resource = mock("Chef::Resource::Mount", 
      :null_object => true,
      :device => "/dev/sdz1",
      :name => "/tmp/foo",
      :mount_point => "/tmp/foo",
      :fstype => "ext3",
      :mounted => false
    )
    
    @provider = Chef::Provider::Mount::Mount.new(@node, @new_resource)
    Chef::Resource::Mount.stub!(:new).and_return(@current_resource)
    @provider.current_resource = @current_resource
    
    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end
  
  it "should mount the filesystem if it is not mounted" do
    @stdout.stub!(:each).and_yield("#{@new_resource.device} on #{@new_resource.mount_point}")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(0)
    @provider.should_receive(:run_command).with({:command => "mount -t #{@new_resource.fstype} #{@new_resource.device} #{@new_resource.mount_point}"})
    @provider.mount_fs()
  end
  
  it "should mount the filesystem with options if options were passed" do
    @stdout.stub!(:each).and_yield("#{@new_resource.mount_point} on #{@new_resource.mount_point}")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(0)
    @new_resource.stub!(:options).and_return("rw,noexec,noauto")
    @provider.should_receive(:run_command).with({:command => "mount -t #{@new_resource.fstype} -o #{@new_resource.options} #{@new_resource.device} #{@new_resource.mount_point}"})
    @provider.mount_fs()
  end
  
  it "should not mount the filesystem if it is mounted" do
    @current_resource.stub!(:mounted).and_return(true)
    @provider.should_not_receive(:run_command).with({:command => "mount -t #{@new_resource.fstype} #{@new_resource.device} #{@new_resource.mount_point}"})
    @provider.mount_fs()
  end
  
end

describe Chef::Provider::Mount::Mount, "umount_fs" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Mount", 
      :null_object => true,
      :device => "/dev/sdz1",
      :name => "/tmp/foo",
      :mount_point => "/tmp/foo",
      :fstype => "ext3",
      :mounted => true
    )
    @new_resource.stub!(:supports).and_return({:remount => false})
    
    @current_resource = mock("Chef::Resource::Mount", 
      :null_object => true,
      :device => "/dev/sdz1",
      :name => "/tmp/foo",
      :mount_point => "/tmp/foo",
      :fstype => "ext3",
      :mounted => true
    )
    
    @provider = Chef::Provider::Mount::Mount.new(@node, @new_resource)
    Chef::Resource::Mount.stub!(:new).and_return(@current_resource)
    @provider.current_resource = @current_resource
    
    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end
  
  it "should umount the filesystem if it is mounted" do
    @stdout.stub!(:each).and_yield("#{@new_resource.device} on #{@new_resource.mount_point}")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(0)
    @provider.should_receive(:run_command).with({:command => "umount #{@new_resource.mount_point}"})
    @provider.umount_fs()
  end

  it "should not umount the filesystem if it is not mounted" do
    @current_resource.stub!(:mounted).and_return(false)
    @provider.should_not_receive(:run_command).with({:command => "umount #{@new_resource.mount_point}"})
    @provider.umount_fs()
  end
end

describe Chef::Provider::Mount::Mount, "remount_fs" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Mount", 
      :null_object => true,
      :device => "/dev/sdz1",
      :name => "/tmp/foo",
      :mount_point => "/tmp/foo",
      :fstype => "ext3",
      :mounted => true
    )
    @new_resource.stub!(:supports).and_return({:remount => false})
    
    @current_resource = mock("Chef::Resource::Mount", 
      :null_object => true,
      :device => "/dev/sdz1",
      :name => "/tmp/foo",
      :mount_point => "/tmp/foo",
      :fstype => "ext3",
      :mounted => true
    )
    
    @provider = Chef::Provider::Mount::Mount.new(@node, @new_resource)
    Chef::Resource::Mount.stub!(:new).and_return(@current_resource)
    @provider.current_resource = @current_resource
    
    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)

  end

  it "should use mount -o remount if remount is supported" do
    @new_resource.stub!(:supports).and_return({:remount => true})
    @provider.should_receive(:run_command).with({:command => "mount -o remount #{@new_resource.mount_point}"})
    @provider.remount_fs
  end

  it "should umount and mount if remount is not supported" do
    @new_resource.stub!(:suports).and_return({:remount => false})
    @provider.should_receive(:umount_fs)
    @provider.should_receive(:sleep).with(1)
    @provider.should_receive(:mount_fs)
    @provider.remount_fs()
  end
  
  it "should not try to remount at all if mounted is false" do
    @current_resource.stub!(:mounted).and_return(false)
    @provider.should_not_receive(:run_command).with({:command => "mount -o remount #{@new_resource.mount_point}"})
    @provider.should_not_receive(:umount_fs)
    @provider.should_not_receive(:sleep).with(1)
    @provider.should_not_receive(:mount_fs)
    @provider.remount_fs()
  end
end
