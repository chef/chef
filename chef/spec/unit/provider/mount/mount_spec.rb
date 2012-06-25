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
require 'ostruct'

describe Chef::Provider::Mount::Mount do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Mount.new("/tmp/foo")
    @new_resource.device      "/dev/sdz1"
    @new_resource.device_type :device
    @new_resource.fstype      "ext3"

    @new_resource.supports :remount => false

    @provider = Chef::Provider::Mount::Mount.new(@new_resource, @run_context)

    ::File.stub!(:exists?).with("/dev/sdz1").and_return true
    ::File.stub!(:exists?).with("/tmp/foo").and_return true
  end

  describe "when discovering the current fs state" do
    before do
      @provider.stub!(:shell_out!).and_return(OpenStruct.new(:stdout => ''))
      ::File.stub!(:foreach).with("/etc/fstab")
    end

    it "should create a current resource with the same mount point and device" do
      @provider.load_current_resource
      @provider.current_resource.name.should == '/tmp/foo'
      @provider.current_resource.mount_point.should == '/tmp/foo'
      @provider.current_resource.device.should == '/dev/sdz1'
    end

    it "should accecpt device_type :uuid" do
      @new_resource.device_type :uuid
      @new_resource.device "d21afe51-a0fe-4dc6-9152-ac733763ae0a"
      @stdout_findfs = mock("STDOUT", :first => "/dev/sdz1")
      @provider.should_receive(:popen4).with("/sbin/findfs UUID=d21afe51-a0fe-4dc6-9152-ac733763ae0a").and_yield(@pid,@stdin,@stdout_findfs,@stderr).and_return(@status)
      @provider.load_current_resource()
      @provider.mountable?
    end

    describe "when dealing with network mounts" do
      { "nfs" => "nfsserver:/vol/path",
        "cifs" => "//cifsserver/share" }.each do |type, fs_spec|
        it "should detect network fs_spec (#{type})" do
          @new_resource.device fs_spec
          @provider.network_device?.should be_true
        end

        it "should ignore trailing slash and set mounted to true for network mount (#{type})" do
          @new_resource.device fs_spec
          @provider.stub!(:shell_out!).and_return(OpenStruct.new(:stdout => "#{fs_spec}/ on /tmp/foo type #{type} (rw)\n"))
          @provider.load_current_resource
          @provider.current_resource.mounted.should be_true
        end
      end
    end

    it "should raise an error if the mount device does not exist" do
      ::File.stub!(:exists?).with("/dev/sdz1").and_return false
      lambda { @provider.load_current_resource();@provider.mountable? }.should raise_error(Chef::Exceptions::Mount)
    end

    it "should not call mountable? with load_current_resource - CHEF-1565" do
      ::File.stub!(:exists?).with("/dev/sdz1").and_return false
      @provider.should_receive(:mounted?).and_return(true)
      @provider.should_receive(:enabled?).and_return(true)
      @provider.should_not_receive(:mountable?)
      @provider.load_current_resource
    end

    it "should raise an error if the mount device (uuid) does not exist" do
      @new_resource.device_type :uuid
      @new_resource.device "d21afe51-a0fe-4dc6-9152-ac733763ae0a"
      status_findfs = mock("Status", :exitstatus => 1)
      stdout_findfs = mock("STDOUT", :first => nil)
      @provider.should_receive(:popen4).with("/sbin/findfs UUID=d21afe51-a0fe-4dc6-9152-ac733763ae0a").and_yield(@pid,@stdin,stdout_findfs,@stderr).and_return(status_findfs)
      ::File.should_receive(:exists?).with("").and_return(false)
      lambda { @provider.load_current_resource();@provider.mountable? }.should raise_error(Chef::Exceptions::Mount)
    end

    it "should raise an error if the mount point does not exist" do
      ::File.stub!(:exists?).with("/tmp/foo").and_return false
      lambda { @provider.load_current_resource();@provider.mountable? }.should raise_error(Chef::Exceptions::Mount)
    end

    it "does not expect the device to exist for tmpfs" do
      @new_resource.fstype("tmpfs")
      @new_resource.device("whatever")
      lambda { @provider.load_current_resource() }.should_not raise_error
    end

    it "does not expect the device to exist for Fuse filesystems" do
      @new_resource.fstype("fuse")
      @new_resource.device("nilfs#xxx")
      lambda { @provider.load_current_resource() }.should_not raise_error
    end

    it "should set mounted true if the mount point is found in the mounts list" do
      @provider.stub!(:shell_out!).and_return(OpenStruct.new(:stdout => '/dev/sdz1 on /tmp/foo'))
      @provider.load_current_resource()
      @provider.current_resource.mounted.should be_true
    end

    it "should set mounted true if the symlink target of the device is found in the mounts list" do
      target = "/dev/mapper/target"

      ::File.stub!(:symlink?).with("#{@new_resource.device}").and_return(true)
      ::File.stub!(:readlink).with("#{@new_resource.device}").and_return(target)

      @provider.stub!(:shell_out!).and_return(OpenStruct.new(:stdout => "/dev/mapper/target on /tmp/foo type ext3 (rw)\n"))
      @provider.load_current_resource()
      @provider.current_resource.mounted.should be_true
    end

    it "should set mounted true if the mount point is found last in the mounts list" do
      mount = "/dev/sdy1 on #{@new_resource.mount_point} type ext3 (rw)\n"
      mount << "#{@new_resource.device} on #{@new_resource.mount_point} type ext3 (rw)\n"

      @provider.stub!(:shell_out!).and_return(OpenStruct.new(:stdout => mount))
      @provider.load_current_resource()
      @provider.current_resource.mounted.should be_true
    end

    it "should set mounted false if the mount point is not last in the mounts list" do
      mount = "#{@new_resource.device} on #{@new_resource.mount_point} type ext3 (rw)\n"
      mount << "/dev/sdy1 on #{@new_resource.mount_point} type ext3 (rw)\n"

      @provider.stub!(:shell_out!).and_return(OpenStruct.new(:stdout => mount))
      @provider.load_current_resource()
      @provider.current_resource.mounted.should be_false
    end

    it "mounted should be false if the mount point is not found in the mounts list" do
      @provider.stub!(:shell_out!).and_return(OpenStruct.new(:stdout => "/dev/sdy1 on /tmp/foo type ext3 (rw)\n"))
      @provider.load_current_resource()
      @provider.current_resource.mounted.should be_false
    end

    it "should set enabled to true if the mount point is last in fstab" do
      fstab1 = "/dev/sdy1  /tmp/foo  ext3  defaults  1 2\n"
      fstab2 = "#{@new_resource.device} #{@new_resource.mount_point}  ext3  defaults  1 2\n"

      ::File.stub!(:foreach).with("/etc/fstab").and_yield(fstab1).and_yield(fstab2)

      @provider.load_current_resource
      @provider.current_resource.enabled.should be_true
    end

    it "should set enabled to true if the mount point is not last in fstab and mount_point is a substring of another mount" do
      fstab1 = "#{@new_resource.device} #{@new_resource.mount_point}  ext3  defaults  1 2\n"
      fstab2 = "/dev/sdy1  /tmp/foo/bar  ext3  defaults  1 2\n"

      ::File.stub!(:foreach).with("/etc/fstab").and_yield(fstab1).and_yield(fstab2)

      @provider.load_current_resource
      @provider.current_resource.enabled.should be_true
    end

    it "should set enabled to true if the symlink target is in fstab" do
      target = "/dev/mapper/target"

      ::File.stub!(:symlink?).with("#{@new_resource.device}").and_return(true)
      ::File.stub!(:readlink).with("#{@new_resource.device}").and_return(target)

      fstab = "/dev/sdz1  /tmp/foo ext3  defaults  1 2\n"

      ::File.stub!(:foreach).with("/etc/fstab").and_yield fstab

      @provider.load_current_resource
      @provider.current_resource.enabled.should be_true
    end

    it "should set enabled to false if the mount point is not in fstab" do
      fstab = "/dev/sdy1  #{@new_resource.mount_point}  ext3  defaults  1 2\n"
      ::File.stub!(:foreach).with("/etc/fstab").and_yield fstab

      @provider.load_current_resource
      @provider.current_resource.enabled.should be_false
    end

    it "should ignore commented lines in fstab " do
       fstab = "\# #{@new_resource.device}  #{@new_resource.mount_point}  ext3  defaults  1 2\n"
       ::File.stub!(:foreach).with("/etc/fstab").and_yield fstab

       @provider.load_current_resource
       @provider.current_resource.enabled.should be_false
     end

    it "should set enabled to false if the mount point is not last in fstab" do
      line_1 = "#{@new_resource.device} #{@new_resource.mount_point}  ext3  defaults  1 2\n"
      line_2 = "/dev/sdy1 #{@new_resource.mount_point}  ext3  defaults  1 2\n"
      ::File.stub!(:foreach).with("/etc/fstab").and_yield(line_1).and_yield(line_2)

      @provider.load_current_resource
      @provider.current_resource.enabled.should be_false
    end
  end

  context "after the mount's state has been discovered" do
    before do
      @current_resource = Chef::Resource::Mount.new("/tmp/foo")
      @current_resource.device       "/dev/sdz1"
      @current_resource.device_type  :device
      @current_resource.fstype       "ext3"

      @provider.current_resource = @current_resource
    end

    describe "mount_fs" do
      it "should mount the filesystem if it is not mounted" do
        @provider.rspec_reset
        @provider.should_receive(:shell_out!).with("mount -t ext3 -o defaults /dev/sdz1 /tmp/foo")
        @provider.mount_fs()
      end

      it "should mount the filesystem with options if options were passed" do
        options = "rw,noexec,noauto"
        @new_resource.options(%w{rw noexec noauto})
        @provider.should_receive(:shell_out!).with("mount -t ext3 -o rw,noexec,noauto /dev/sdz1 /tmp/foo")
        @provider.mount_fs()
      end

      it "should mount the filesystem specified by uuid" do
        @new_resource.device "d21afe51-a0fe-4dc6-9152-ac733763ae0a"
        @new_resource.device_type :uuid
        @stdout_findfs = mock("STDOUT", :first => "/dev/sdz1")
        @provider.stub!(:popen4).with("/sbin/findfs UUID=d21afe51-a0fe-4dc6-9152-ac733763ae0a").and_yield(@pid,@stdin,@stdout_findfs,@stderr).and_return(@status)
        @stdout_mock = mock('stdout mock')
        @stdout_mock.stub!(:each).and_yield("#{@new_resource.device} on #{@new_resource.mount_point}")
        @provider.should_receive(:shell_out!).with("mount -t #{@new_resource.fstype} -o defaults -U #{@new_resource.device} #{@new_resource.mount_point}").and_return(@stdout_mock)
        @provider.mount_fs()
      end

      it "should not mount the filesystem if it is mounted" do
        @current_resource.stub!(:mounted).and_return(true)
        @provider.should_not_receive(:shell_out!)
        @provider.mount_fs()
      end

    end

    describe "umount_fs" do
      it "should umount the filesystem if it is mounted" do
        @current_resource.mounted(true)
        @provider.should_receive(:shell_out!).with("umount /tmp/foo")
        @provider.umount_fs()
      end

      it "should not umount the filesystem if it is not mounted" do
        @current_resource.mounted(false)
        @provider.should_not_receive(:shell_out!)
        @provider.umount_fs()
      end
    end

    describe "remount_fs" do
      it "should use mount -o remount if remount is supported" do
        @new_resource.supports({:remount => true})
        @current_resource.mounted(true)
        @provider.should_receive(:shell_out!).with("mount -o remount #{@new_resource.mount_point}")
        @provider.remount_fs
      end

      it "should umount and mount if remount is not supported" do
        @new_resource.supports({:remount => false})
        @current_resource.mounted(true)
        @provider.should_receive(:umount_fs)
        @provider.should_receive(:sleep).with(1)
        @provider.should_receive(:mount_fs)
        @provider.remount_fs()
      end

      it "should not try to remount at all if mounted is false" do
        @current_resource.mounted(false)
        @provider.should_not_receive(:shell_out!)
        @provider.should_not_receive(:umount_fs)
        @provider.should_not_receive(:mount_fs)
        @provider.remount_fs()
      end
    end

    describe "when enabling the fs" do
      it "should enable if enabled isn't true" do
        @current_resource.enabled(false)

        @fstab = StringIO.new
        ::File.stub!(:open).with("/etc/fstab", "a").and_yield(@fstab)
        @provider.enable_fs
        @fstab.string.should match(%r{^/dev/sdz1\s+/tmp/foo\s+ext3\s+defaults\s+0\s+2\s*$})
      end

      it "should not enable if enabled is true and resources match" do
        @current_resource.enabled(true)
        @current_resource.fstype("ext3")
        @current_resource.options(["defaults"])
        @current_resource.dump(0)
        @current_resource.pass(2)
        ::File.should_not_receive(:open).with("/etc/fstab", "a")

        @provider.enable_fs
      end

      it "should enable if enabled is true and resources do not match" do
        @current_resource.enabled(true)
        @current_resource.fstype("auto")
        @current_resource.options(["defaults"])
        @current_resource.dump(0)
        @current_resource.pass(2)
        @fstab = StringIO.new
        ::File.stub(:readlines).and_return([])
        ::File.should_receive(:open).once.with("/etc/fstab", "w").and_yield(@fstab)
        ::File.should_receive(:open).once.with("/etc/fstab", "a").and_yield(@fstab)

        @provider.enable_fs
      end
    end

    describe "when disabling the fs" do
      it "should disable if enabled is true" do
        @current_resource.enabled(true)

        other_mount = "/dev/sdy1  /tmp/foo  ext3  defaults  1 2\n"
        this_mount = "/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n"

        @fstab_read = [this_mount, other_mount]
        ::File.stub!(:readlines).with("/etc/fstab").and_return(@fstab_read)
        @fstab_write = StringIO.new
        ::File.stub!(:open).with("/etc/fstab", "w").and_yield(@fstab_write)

        @provider.disable_fs
        @fstab_write.string.should match(Regexp.escape(other_mount))
        @fstab_write.string.should_not match(Regexp.escape(this_mount))
      end

      it "should disable if enabled is true and ignore commented lines" do
        @current_resource.enabled(true)

        fstab_read = [%q{/dev/sdy1 /tmp/foo  ext3  defaults  1 2},
                      %q{/dev/sdz1 /tmp/foo  ext3  defaults  1 2},
                      %q{#/dev/sdz1 /tmp/foo  ext3  defaults  1 2}]
        fstab_write = StringIO.new

        ::File.stub!(:readlines).with("/etc/fstab").and_return(fstab_read)
        ::File.stub!(:open).with("/etc/fstab", "w").and_yield(fstab_write)

        @provider.disable_fs
        fstab_write.string.should match(%r{^/dev/sdy1 /tmp/foo  ext3  defaults  1 2$})
        fstab_write.string.should match(%r{^#/dev/sdz1 /tmp/foo  ext3  defaults  1 2$})
        fstab_write.string.should_not match(%r{^/dev/sdz1 /tmp/foo  ext3  defaults  1 2$})
      end

      it "should disable only the last entry if enabled is true" do
        @current_resource.stub!(:enabled).and_return(true)
        fstab_read = ["/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n",
                      "/dev/sdy1 /tmp/foo  ext3  defaults  1 2\n",
                      "/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n"]

        fstab_write = StringIO.new
        ::File.stub!(:readlines).with("/etc/fstab").and_return(fstab_read)
        ::File.stub!(:open).with("/etc/fstab", "w").and_yield(fstab_write)

        @provider.disable_fs
        fstab_write.string.should == "/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n/dev/sdy1 /tmp/foo  ext3  defaults  1 2\n"
      end

      it "should not disable if enabled is false" do
        @current_resource.stub!(:enabled).and_return(false)

        ::File.stub!(:readlines).with("/etc/fstab").and_return([])
        ::File.should_not_receive(:open).and_yield(@fstab)

        @provider.disable_fs
      end
    end
  end
end
