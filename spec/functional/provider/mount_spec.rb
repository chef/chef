#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#

require 'spec_helper'
require 'chef/mixin/shell_out'

describe Chef::Provider::Mount::Mount do
  # Order the tests for proper cleanup and execution
  RSpec.configure do |config|
    config.order_groups_and_examples do |list|
      list.sort_by { |item| item.description }
    end
  end

  # Load ohai only once
  ohai = Ohai::System.new
  ohai.all_plugins

  include Chef::Mixin::ShellOut
  before(:each) do
    # TODO - this can better be written if we have resource/provider for ramdisk.
    if ohai[:platform] == 'aix'
      @ramdisk = shell_out!("mkramdisk 512").stdout

      # identify device, for /dev/rramdisk0 it is /dev/ramdisk0
      @device = @ramdisk.tr("\n","").gsub(/(?<=\/dev\/)r(?=ramdisk\d*)/, '')

      @fstype = "jfs"
      shell_out!("mkfs  -V #{@fstype} #{@device}")
    else
      @device = "/dev/ram1"
      @fstype = "tmpfs"
      shell_out!("mkfs -q #{@device} 512")
    end
    @mount_point = "/tmp/testmount"
    shell_out("rm -rf #{@mount_point}")
    shell_out!("mkdir -p #{@mount_point}")

    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    
    @new_resource = Chef::Resource::Mount.new(@mount_point)
    @new_resource.device      @device
    @new_resource.name        @mount_point
    @new_resource.fstype      @fstype
    @new_resource.options     "nointegrity" if ohai[:platform] == 'aix'

    providerClass = Chef::Platform.find_provider(ohai[:platform], ohai[:version], @new_resource)
    @provider = providerClass.new(@new_resource, @run_context)
  end

  after(:each) do
    if ohai[:platform] == 'aix'
      shell_out("rmramdisk #{@ramdisk}")
    end
  end

  describe "testcase 1: when the target state is a mounted filesystem" do
    it "should mount the filesystem if it isn't mounted" do
      @provider.load_current_resource
      @provider.current_resource.enabled.should be_false
      @provider.current_resource.mounted.should be_false
      @provider.should_receive(:mount_fs).and_call_original
      @provider.run_action(:mount)
      @provider.load_current_resource
      @provider.current_resource.mounted.should be_true
    end
  end

  describe "testcase 2: when the target state is a mounted filesystem" do
    it "should not mount the filesystem if it is mounted" do
      @provider.should_not_receive(:mount_fs)
      @provider.run_action(:mount)
    end
  end

  describe "testcase 3: when the filesystem should be remounted and the resource supports remounting" do
    before do
      @new_resource.supports[:remount] = true
    end
    
    it "should remount the filesystem if it is mounted" do
      @provider.should_receive(:remount_fs).and_call_original
      @provider.run_action(:remount)
      @provider.load_current_resource
      @provider.current_resource.mounted.should be_true
    end
  end

  describe "testcase 4: when the target state is a unmounted filesystem" do
    it "should umount the filesystem if it is mounted" do
      @provider.load_current_resource
      @provider.current_resource.mounted.should be_true
      @provider.should_receive(:umount_fs).and_call_original
      @provider.run_action(:umount)
      @provider.load_current_resource
      @provider.current_resource.mounted.should be_false
    end
  end

  describe "testcase 5: when the target state is a unmounted filesystem" do
    it "should not umount the filesystem if it is not mounted" do
      @provider.should_not_receive(:umount_fs)
      @provider.run_action(:umount)
    end
  end

  describe "testcase 6: when the resource supports remounting" do
    before do
      @new_resource.supports[:remount] = true
    end
    it "should not remount the filesystem if it is not mounted" do
      @provider.should_not_receive(:remount_fs)
      @provider.run_action(:remount)
    end
  end

  describe "testcase 7: when enabling the filesystem to be mounted" do
    # setup the mount for further tests.
    before do
      @provider.run_action(:mount)
    end

    it "should enable the mount if it isn't enable" do
      @provider.should_not_receive(:mount_options_unchanged?)
      @provider.should_receive(:enable_fs).and_call_original
      @provider.run_action(:enable)
      @provider.load_current_resource
      @provider.current_resource.enabled.should be_true
    end
  end

  describe "testcase 8: when enabling the filesystem to be mounted" do
    it "should enable the mount if it is enabled and mount options have changed" do
      @new_resource.options     "nodev"
      @provider.should_receive(:mount_options_unchanged?).and_call_original
      @provider.should_receive(:enable_fs).and_call_original
      @provider.run_action(:enable)
      @provider.load_current_resource
      @provider.current_resource.enabled.should be_true
    end
  end

  describe "testcase 9: when enabling the filesystem to be mounted" do
    it "should not enable the mount if it is enabled and mount options have not changed" do
      @new_resource.options     "nodev"
      @provider.load_current_resource
      @provider.should_receive(:mount_options_unchanged?).and_call_original
      @provider.should_not_receive(:enable_fs)
      @provider.run_action(:enable)
    end
  end

  describe "testcase 10: when the target state is to disable the mount" do
    it "should disable the mount if it is enabled" do
      @provider.should_receive(:disable_fs).and_call_original
      @provider.run_action(:disable)
      @provider.load_current_resource
      @provider.current_resource.enabled.should be_false
    end
  end

  describe "testcase 10: when the target state is to disable the mount" do
    # cleanup at the end
    after do
      @provider.run_action(:umount)
    end

    it "should not disable the mount if it isn't enabled" do
      @provider.should_not_receive(:disable_fs)
      @provider.run_action(:disable)
    end
  end
end

