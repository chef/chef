#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'functional/resource/base'
require 'chef/mixin/shell_out'
require 'tmpdir'

# run this test only for following platforms.
include_flag = !(['ubuntu', 'centos', 'aix'].include?(ohai[:platform]))

describe Chef::Resource::Mount, :requires_root, :external => include_flag do

  include Chef::Mixin::ShellOut

  # Platform specific setup, cleanup and validation helpers.

  def setup_device_for_mount
    # use ramdisk for creating a test device for mount.
    # This can cleaner if we have chef resource/provider for ramdisk.
    case ohai[:platform]
    when "aix"
      ramdisk = shell_out!("mkramdisk 16M").stdout

      # identify device, for /dev/rramdisk0 it is /dev/ramdisk0
      device = ramdisk.tr("\n","").gsub(/\/rramdisk/, '/ramdisk')

      fstype = "jfs2"
      shell_out!("mkfs  -V #{fstype} #{device}")
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
    else
    end
    [device, fstype]
  end

  def cleanup_device(device)
    case ohai[:platform]
    when "aix"
      ramdisk = device.gsub(/\/ramdisk/, '/rramdisk')
      shell_out("rmramdisk #{ramdisk}")
    else
    end
  end

  def cleanup_mount(mount_point)
    if windows?
    else
      shell_out("umount #{mount_point}")
    end
  end

  # platform specific validations.
  def mount_should_exists(mount_point, device, fstype = nil, options = nil)
    if windows?
    else
      # unix only validations
      validation_cmd = "mount | grep #{mount_point} | grep #{device} "
      validation_cmd << " | grep #{fstype} " unless fstype.nil?
      validation_cmd << " | grep #{options.join(',')} " unless options.nil? || options.empty?
      puts "validation_cmd = #{validation_cmd}"
      expect(shell_out(validation_cmd).exitstatus).to eq(0)
    end
  end

  def mount_should_not_exists(mount_point)
    if windows?
    else
      expect(shell_out("mount | grep #{mount_point}").exitstatus).to eq(1)
    end
  end

  def unix_mount_config_file
    case ohai[:platform]
    when 'aix'
      mount_config = "/etc/filesystems"
    else
      mount_config = "/etc/fstab"
    end
  end

  def mount_should_be_enabled(mount_point, device)
    if windows?
    else
      case ohai[:platform]
      when 'aix'
        expect(shell_out("cat #{unix_mount_config_file} | grep \"#{mount_point}:\" ").exitstatus).to eq(0)
      else
        expect(shell_out("cat #{unix_mount_config_file} | grep \"#{mount_point}\" | grep \"#{device}\" ").exitstatus).to eq(0)
      end
    end
  end

  def mount_should_be_disabled(mount_point)
    if windows?
    else
      expect(shell_out("cat #{unix_mount_config_file} | grep \"#{mount_point}:\"").exitstatus).to eq(1)
    end
  end

  let(:new_resource) do
    new_resource = Chef::Resource::Mount.new(@mount_point, run_context)
    new_resource.device      @device
    new_resource.name        @mount_point
    new_resource.fstype      @fstype
    new_resource.options     "log=NULL" if ohai[:platform] == 'aix'
    new_resource
  end

  let(:provider) do
    provider = new_resource.provider_for_action(new_resource.action)
    provider
  end

  def current_resource
    provider.load_current_resource
    provider.current_resource
  end

  # Actual tests begin here.
  before(:all) do
    @device, @fstype = setup_device_for_mount

    @mount_point = Dir.mktmpdir("testmount")
  end

  after(:all) do
    Dir.rmdir(@mount_point)
    cleanup_device(@device)
  end



  describe "when the target state is a mounted filesystem" do
    after do
      cleanup_mount(new_resource.mount_point)
    end

    it "should mount the filesystem if it isn't mounted" do
      current_resource.enabled.should be_false
      current_resource.mounted.should be_false
      new_resource.run_action(:mount)
      new_resource.should be_updated
      mount_should_exists(new_resource.mount_point, new_resource.device)
    end

  end

  describe "when the filesystem should be remounted and the resource supports remounting" do
    after do
      cleanup_mount(new_resource.mount_point)
    end

    it "should remount the filesystem if it is mounted" do
      new_resource.run_action(:mount)
      mount_should_exists(new_resource.mount_point, new_resource.device)

      new_resource.supports[:remount] = true
      new_resource.options "rw,log=NULL" if ohai[:platform] == 'aix'
      new_resource.run_action(:remount)

      mount_should_exists(new_resource.mount_point, new_resource.device, nil, (ohai[:platform] == 'aix') ? new_resource.options : nil)
    end
  end

  describe "when the target state is a unmounted filesystem" do
    it "should umount the filesystem if it is mounted" do
      new_resource.run_action(:mount)
      mount_should_exists(new_resource.mount_point, new_resource.device)

      new_resource.run_action(:umount)

      mount_should_not_exists(new_resource.mount_point)
    end
  end

  describe "when enabling the filesystem to be mounted" do
    before do
      new_resource.run_action(:mount)
    end

    after do
      new_resource.run_action(:disable)
      cleanup_mount(new_resource.mount_point)
    end

    it "should enable the mount if it isn't enable" do
      new_resource.run_action(:enable)
      mount_should_be_enabled(new_resource.mount_point, new_resource.device)
    end
  end

  describe "when the target state is to disable the mount" do
    before do
      new_resource.run_action(:mount)
      new_resource.run_action(:enable)
    end

    after do
      cleanup_mount(new_resource.mount_point)
    end

    it "should disable the mount if it is enabled" do
      new_resource.run_action(:disable)
      mount_should_be_disabled(new_resource.mount_point)
    end
  end
end
