#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "spec_helper"
require "ostruct"

describe Chef::Provider::Mount::Aix do

  before(:all) do
    @mounted_output = <<-MOUNT
  node       mounted        mounted over    vfs       date        options
-------- ---------------  ---------------  ------ ------------ ---------------
         /dev/sdz1         /tmp/foo         jfs2   Jul 17 13:22 rw,log=/dev/hd8
MOUNT

    @unmounted_output = <<-UNMOUNTED
  node       mounted        mounted over    vfs       date        options
-------- ---------------  ---------------  ------ ------------ ---------------
         /dev/sdz2         /                jfs2   Jul 17 13:22 rw,log=/dev/hd8
UNMOUNTED

    @conflict_mounted_output = <<-MOUNT
  node       mounted        mounted over    vfs       date        options
-------- ---------------  ---------------  ------ ------------ ---------------
         /dev/sdz3         /tmp/foo         jfs2   Jul 17 13:22 rw,log=/dev/hd8
MOUNT

    @enabled_output = <<-ENABLED
#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/tmp/foo:/dev/sdz1:jfs2::bootfs:10485760:rw:yes:no
ENABLED
  end

  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Mount.new("/tmp/foo")
    @new_resource.device      "/dev/sdz1"
    @new_resource.device_type :device
    @new_resource.fstype      "jfs2"

    @new_resource.supports :remount => false

    @provider = Chef::Provider::Mount::Aix.new(@new_resource, @run_context)

    allow(::File).to receive(:exists?).with("/dev/sdz1").and_return true
    allow(::File).to receive(:exists?).with("/tmp/foo").and_return true
  end

  def stub_mounted(provider, mounted_output)
    response = double("Mixlib::ShellOut command", :exitstatus => 0, :stdout => mounted_output, :stderr => "")
    expect(provider).to receive(:shell_out!).with("mount").and_return(response)
  end

  def stub_enabled(provider, enabled_output)
    response = double("Mixlib::ShellOut command", :exitstatus => 0, :stdout => enabled_output, :stderr => "")
    expect(provider).to receive(:shell_out).with("lsfs -c #{@new_resource.mount_point}").and_return(response)
  end

  def stub_mounted_enabled(provider, mounted_output, enabled_output)
    stub_mounted(provider, mounted_output)
    stub_enabled(provider, enabled_output)
  end

  describe "when discovering the current fs state" do
    it "should set current_resource.mounted to true if device is already mounted" do
      stub_mounted_enabled(@provider, @mounted_output, "")
      @provider.load_current_resource

      expect(@provider.current_resource.mounted).to be_truthy
    end

    it "should set current_resource.mounted to false if device is not mounted" do
      stub_mounted_enabled(@provider, @unmounted_output, "")

      @provider.load_current_resource

      expect(@provider.current_resource.mounted).to be_falsey
    end

    it "should set current_resource.mounted to false if the mount point is used for another device" do
      stub_mounted_enabled(@provider, @conflict_mounted_output, "")

      @provider.load_current_resource

      expect(@provider.current_resource.mounted).to be_falsey
    end
  end

  # tests for #enabled?
  it "should load current_resource with properties if device is already mounted and enabled" do
    stub_mounted_enabled(@provider, @mounted_output, @enabled_output)

    @provider.load_current_resource

    expect(@provider.current_resource.enabled).to be_truthy
    expect(@provider.current_resource.mounted).to be_truthy
    expect(@provider.current_resource.mount_point).to eql(@new_resource.mount_point)
    expect(@provider.current_resource.fstype).to eql("jfs2")
    expect(@provider.current_resource.options).to eql(["rw"])
  end

  describe "mount_fs" do
    it "should mount resource if it is not mounted" do
      stub_mounted_enabled(@provider, @unmounted_output, "")

      expect(@provider).to receive(:shell_out!).with("mount -v #{@new_resource.fstype} #{@new_resource.device} #{@new_resource.mount_point}")

      @provider.run_action(:mount)
    end

    it "should not mount resource if it is already mounted" do
      stub_mounted_enabled(@provider, @mounted_output, "")

      expect(@provider).not_to receive(:mount_fs)

      @provider.run_action(:mount)
    end
  end

  describe "umount_fs" do
    it "should umount resource if it is already mounted" do
      stub_mounted_enabled(@provider, @mounted_output, "")

      expect(@provider).to receive(:shell_out!).with("umount #{@new_resource.mount_point}")

      @provider.run_action(:umount)
    end

    it "should not umount resource if it is not mounted" do
      stub_mounted_enabled(@provider, @unmounted_output, "")

      expect(@provider).not_to receive(:umount_fs)

      @provider.run_action(:umount)
    end
  end

  describe "remount_fs" do
    it "should remount resource if it is already mounted and it supports remounting" do
      @new_resource.supports({ :remount => true })
      stub_mounted_enabled(@provider, @mounted_output, "")

      expect(@provider).to receive(:shell_out!).with("mount -o remount #{@new_resource.device} #{@new_resource.mount_point}")

      @provider.run_action(:remount)
    end

    it "should remount with new mount options if it is already mounted and it supports remounting" do
      @new_resource.supports({ :remount => true })
      @new_resource.options("nodev,rw")
      stub_mounted_enabled(@provider, @mounted_output, "")

      expect(@provider).to receive(:shell_out!).with("mount -o remount,nodev,rw #{@new_resource.device} #{@new_resource.mount_point}")

      @provider.run_action(:remount)
    end
  end

  describe "enable_fs" do
    it "should enable mount if it is mounted and not enabled" do
      @new_resource.options("nodev,rw")
      stub_mounted_enabled(@provider, @mounted_output, "")
      filesystems = StringIO.new
      allow(::File).to receive(:open).with("/etc/filesystems", "a").and_yield(filesystems)

      @provider.run_action(:enable)

      expect(filesystems.string).to match(%r{^/tmp/foo:\n\tdev\t\t= /dev/sdz1\n\tvfs\t\t= jfs2\n\tmount\t\t= false\n\toptions\t\t= nodev,rw\n$})
    end

    it "should not enable mount if it is mounted and already enabled and mount options are unchanged" do
      stub_mounted_enabled(@provider, @mounted_output, @enabled_output)
      @new_resource.options "rw"

      expect(@provider).not_to receive(:enable_fs)

      @provider.run_action(:enable)
    end
  end

  describe "disable_fs" do
    it "should disable mount if it is mounted and enabled" do
      stub_mounted_enabled(@provider, @mounted_output, @enabled_output)

      allow(::File).to receive(:open).with("/etc/filesystems", "r").and_return(<<-ETCFILESYSTEMS)
/tmp/foo:
  dev   = /dev/sdz1
  vfs   = jfs2
  log   = /dev/hd8
  mount   = true
  check   = true
  vol   = /opt
  free    = false
  quota   = no

/tmp/abc:
  dev   = /dev/sdz2
  vfs   = jfs2
  mount   = true
  options   = rw
ETCFILESYSTEMS

      filesystems = StringIO.new
      allow(::File).to receive(:open).with("/etc/filesystems", "w").and_yield(filesystems)

      @provider.run_action(:disable)

      expect(filesystems.string).to match(%r{^/tmp/abc:\s+dev\s+= /dev/sdz2\s+vfs\s+= jfs2\s+mount\s+= true\s+options\s+= rw\n$})
    end

    it "should not disable mount if it is not mounted" do
      stub_mounted_enabled(@provider, @unmounted_output, "")

      expect(@provider).not_to receive(:disable_fs)

      @provider.run_action(:disable)
    end
  end
end
