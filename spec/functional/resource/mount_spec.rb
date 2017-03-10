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
require "functional/resource/base"
require "chef/mixin/shell_out"
require "tmpdir"

# run this test only for following platforms.
include_flag = !(%w{ubuntu centos aix solaris2}.include?(ohai[:platform]))

describe Chef::Resource::Mount, :requires_root, :skip_travis, :external => include_flag do
  # Disabled in travis because it refuses to let us mount a ramdisk. /dev/ramX does not
  # exist even after loading the kernel module

  include Chef::Mixin::ShellOut

  # Platform specific setup, cleanup and validation helpers.

  def setup_device_for_mount
    # use ramdisk for creating a test device for mount.
    # This can cleaner if we have chef resource/provider for ramdisk.
    case ohai[:platform]
    when "aix"
      # On AIX, we can't create a ramdisk inside a WPAR, so we use
      # a "namefs" mount against / to test
      # https://www-304.ibm.com/support/knowledgecenter/ssw_aix_71/com.ibm.aix.performance/namefs_file_sys.htm
      device = "/"
      fstype = "namefs"
    when "ubuntu", "centos"
      device = "/dev/ram1"
      shell_out("ls -1 /dev/ram*").stdout.each_line do |d|
        if shell_out("mount | grep #{d}").exitstatus == "1"
          # this device is not mounted, so use it.
          device = d
          break
        end
      end
      fstype = "tmpfs"
      shell_out!("mkfs -q #{device} 512")
    when "solaris2"
      device = "swap"
      fstype = "tmpfs"
    else
    end
    [device, fstype]
  end

  def cleanup_mount(mount_point)
    shell_out("umount #{mount_point}")
  end

  # platform specific validations.
  def mount_should_exist(mount_point, device, fstype = nil, options = nil)
    validation_cmd = "mount | grep #{mount_point} | grep #{device} "
    validation_cmd << " | grep #{fstype} " unless fstype.nil?
    validation_cmd << " | grep #{options.join(',')} " unless options.nil? || options.empty?
    expect(shell_out(validation_cmd).exitstatus).to eq(0)
  end

  def mount_should_not_exists(mount_point)
    expect(shell_out("mount").stdout).not_to include(mount_point)
  end

  def unix_mount_config_file
    case ohai[:platform]
    when "aix"
      mount_config = "/etc/filesystems"
    when "solaris2"
      mount_config = "/etc/vfstab"
    else
      mount_config = "/etc/fstab"
    end
  end

  def mount_should_be_enabled(mount_point, device)
    case ohai[:platform]
    when "aix"
      expect(shell_out("cat #{unix_mount_config_file} | grep \"#{mount_point}:\" ").exitstatus).to eq(0)
    else
      expect(shell_out("cat #{unix_mount_config_file} | grep \"#{mount_point}\" | grep \"#{device}\" ").exitstatus).to eq(0)
    end
  end

  def mount_should_be_disabled(mount_point)
    expect(shell_out("cat #{unix_mount_config_file}").stdout).not_to include("#{mount_point}:")
  end

  let(:new_resource) do
    new_resource = Chef::Resource::Mount.new(@mount_point, run_context)
    new_resource.device      @device
    new_resource.name        @mount_point
    new_resource.fstype      @fstype
    new_resource.options     "log=NULL" if ohai[:platform] == "aix"
    new_resource
  end

  let(:provider) do
    provider = new_resource.provider_for_action(new_resource.action)
    provider
  end

  let(:current_resource) do
    provider.load_current_resource
    provider.current_resource
  end

  # Actual tests begin here.
  before(:all) do
    @device, @fstype = setup_device_for_mount

    @mount_point = Dir.mktmpdir("testmount")

    # Make sure all the potentially leaked mounts are cleared up
    shell_out("mount").stdout.each_line do |line|
      if line.include? "testmount"
        line.split(" ").each do |section|
          cleanup_mount(section) if section.include? "testmount"
        end
      end
    end
  end

  after(:all) do
    Dir.rmdir(@mount_point)
  end

  after(:each) do
    cleanup_mount(new_resource.mount_point)
  end

  describe "when the target state is a mounted filesystem" do
    it "should mount the filesystem if it isn't mounted" do
      expect(current_resource.enabled).to be_falsey
      expect(current_resource.mounted).to be_falsey
      new_resource.run_action(:mount)
      expect(new_resource).to be_updated
      mount_should_exist(new_resource.mount_point, new_resource.device)
    end
  end

  # don't run the remount tests on solaris2 (tmpfs does not support remount)
  # Need to make sure the platforms we've already excluded are considered:
  skip_remount = include_flag || (ohai[:platform] == "solaris2")
  describe "when the filesystem should be remounted and the resource supports remounting", :external => skip_remount do
    it "should remount the filesystem if it is mounted" do
      new_resource.run_action(:mount)
      mount_should_exist(new_resource.mount_point, new_resource.device)

      new_resource.supports[:remount] = true
      new_resource.options "rw" if ohai[:platform] == "aix"
      new_resource.run_action(:remount)

      mount_should_exist(new_resource.mount_point, new_resource.device, nil, (ohai[:platform] == "aix") ? new_resource.options : nil)
    end
  end

  describe "when the target state is a unmounted filesystem" do
    it "should umount the filesystem if it is mounted" do
      new_resource.run_action(:mount)
      mount_should_exist(new_resource.mount_point, new_resource.device)

      new_resource.run_action(:umount)
      mount_should_not_exists(new_resource.mount_point)
    end
  end

  describe "when enabling the filesystem to be mounted" do
    after do
      new_resource.run_action(:disable)
    end

    it "should enable the mount if it isn't enable" do
      new_resource.run_action(:mount)
      new_resource.run_action(:enable)
      mount_should_be_enabled(new_resource.mount_point, new_resource.device)
    end
  end

  describe "when the target state is to disable the mount" do
    it "should disable the mount if it is enabled" do
      new_resource.run_action(:mount)
      new_resource.run_action(:enable)
      new_resource.run_action(:disable)
      mount_should_be_disabled(new_resource.mount_point)
    end
  end
end
