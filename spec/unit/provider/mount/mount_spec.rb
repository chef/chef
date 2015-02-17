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

    allow(::File).to receive(:exists?).with("/dev/sdz1").and_return true
    allow(::File).to receive(:exists?).with("/tmp/foo").and_return true
    allow(::File).to receive(:realpath).with("/dev/sdz1").and_return "/dev/sdz1"
    allow(::File).to receive(:realpath).with("/tmp/foo").and_return "/tmp/foo"
  end

  describe "when discovering the current fs state" do
    before do
      allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(:stdout => ''))
      allow(::File).to receive(:foreach).with("/etc/fstab")
    end

    it "should create a current resource with the same mount point and device" do
      @provider.load_current_resource
      expect(@provider.current_resource.name).to eq('/tmp/foo')
      expect(@provider.current_resource.mount_point).to eq('/tmp/foo')
      expect(@provider.current_resource.device).to eq('/dev/sdz1')
    end

    it "should accecpt device_type :uuid", :not_supported_on_solaris do
      @status = double(:stdout => "/dev/sdz1\n", :exitstatus => 1)
      @new_resource.device_type :uuid
      @new_resource.device "d21afe51-a0fe-4dc6-9152-ac733763ae0a"
      @stdout_findfs = double("STDOUT", :first => "/dev/sdz1")
      expect(@provider).to receive(:shell_out).with("/sbin/findfs UUID=d21afe51-a0fe-4dc6-9152-ac733763ae0a").and_return(@status)
      @provider.load_current_resource()
      @provider.mountable?
    end

    describe "when dealing with network mounts" do
      { "nfs" => "nfsserver:/vol/path",
        "cifs" => "//cifsserver/share" }.each do |type, fs_spec|
        it "should detect network fs_spec (#{type})" do
          @new_resource.device fs_spec
          expect(@provider.network_device?).to be_truthy
        end

        it "should ignore trailing slash and set mounted to true for network mount (#{type})" do
          @new_resource.device fs_spec
          allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(:stdout => "#{fs_spec}/ on /tmp/foo type #{type} (rw)\n"))
          @provider.load_current_resource
          expect(@provider.current_resource.mounted).to be_truthy
        end
      end
    end

    it "should raise an error if the mount device does not exist" do
      allow(::File).to receive(:exists?).with("/dev/sdz1").and_return false
      expect { @provider.load_current_resource();@provider.mountable? }.to raise_error(Chef::Exceptions::Mount)
    end

    it "should not call mountable? with load_current_resource - CHEF-1565" do
      allow(::File).to receive(:exists?).with("/dev/sdz1").and_return false
      expect(@provider).to receive(:mounted?).and_return(true)
      expect(@provider).to receive(:enabled?).and_return(true)
      expect(@provider).not_to receive(:mountable?)
      @provider.load_current_resource
    end

    it "should raise an error if the mount device (uuid) does not exist", :not_supported_on_solaris do
      status = double(:stdout => "", :exitstatus => 1)
      @new_resource.device_type :uuid
      @new_resource.device "d21afe51-a0fe-4dc6-9152-ac733763ae0a"
      expect(@provider).to receive(:shell_out).with("/sbin/findfs UUID=d21afe51-a0fe-4dc6-9152-ac733763ae0a").and_return(status)
      expect(::File).to receive(:exists?).with("").and_return(false)
      expect { @provider.load_current_resource();@provider.mountable? }.to raise_error(Chef::Exceptions::Mount)
    end

    it "should raise an error if the mount point does not exist" do
      allow(::File).to receive(:exists?).with("/tmp/foo").and_return false
      expect { @provider.load_current_resource();@provider.mountable? }.to raise_error(Chef::Exceptions::Mount)
    end

    [ "tmpfs", "fuse", "cgroup" ].each do |fstype|
      it "does not expect the device to exist for #{fstype}" do
        @new_resource.fstype(fstype)
        @new_resource.device("whatever")
        expect { @provider.load_current_resource();@provider.mountable? }.not_to raise_error
      end
    end

    it "does not expect the device to exist if it's none" do
      @new_resource.device("none")
      expect { @provider.load_current_resource();@provider.mountable? }.not_to raise_error
    end

    it "should set mounted true if the mount point is found in the mounts list" do
      allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(:stdout => "/dev/sdz1 on /tmp/foo type ext3 (rw)\n"))
      @provider.load_current_resource()
      expect(@provider.current_resource.mounted).to be_truthy
    end

    it "should set mounted false if another mount point beginning with the same path is found in the mounts list" do
      allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(:stdout => "/dev/sdz1 on /tmp/foobar type ext3 (rw)\n"))
      @provider.load_current_resource()
      expect(@provider.current_resource.mounted).to be_falsey
    end

    it "should set mounted true if the symlink target of the device is found in the mounts list" do
      # expand the target path to correct specs on Windows
      target = ::File.expand_path('/dev/mapper/target')

      allow(::File).to receive(:symlink?).with("#{@new_resource.device}").and_return(true)
      allow(::File).to receive(:readlink).with("#{@new_resource.device}").and_return(target)

      allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(:stdout => "#{target} on /tmp/foo type ext3 (rw)\n"))
      @provider.load_current_resource()
      expect(@provider.current_resource.mounted).to be_truthy
    end

    it "should set mounted true if the symlink target of the device is relative and is found in the mounts list - CHEF-4957" do
      target = "xsdz1"

      # expand the target path to correct specs on Windows
      absolute_target = ::File.expand_path("/dev/xsdz1")

      allow(::File).to receive(:symlink?).with("#{@new_resource.device}").and_return(true)
      allow(::File).to receive(:readlink).with("#{@new_resource.device}").and_return(target)

      allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(:stdout => "#{absolute_target} on /tmp/foo type ext3 (rw)\n"))
      @provider.load_current_resource()
      expect(@provider.current_resource.mounted).to be_truthy
    end

    it "should set mounted true if the mount point is found last in the mounts list" do
      mount = "/dev/sdy1 on #{@new_resource.mount_point} type ext3 (rw)\n"
      mount << "#{@new_resource.device} on #{@new_resource.mount_point} type ext3 (rw)\n"

      allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(:stdout => mount))
      @provider.load_current_resource()
      expect(@provider.current_resource.mounted).to be_truthy
    end

    it "should set mounted false if the mount point is not last in the mounts list" do
      mount = "#{@new_resource.device} on #{@new_resource.mount_point} type ext3 (rw)\n"
      mount << "/dev/sdy1 on #{@new_resource.mount_point} type ext3 (rw)\n"

      allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(:stdout => mount))
      @provider.load_current_resource()
      expect(@provider.current_resource.mounted).to be_falsey
    end

    it "mounted should be false if the mount point is not found in the mounts list" do
      allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(:stdout => "/dev/sdy1 on /tmp/foo type ext3 (rw)\n"))
      @provider.load_current_resource()
      expect(@provider.current_resource.mounted).to be_falsey
    end

    it "should set enabled to true if the mount point is last in fstab" do
      fstab1 = "/dev/sdy1  /tmp/foo  ext3  defaults  1 2\n"
      fstab2 = "#{@new_resource.device} #{@new_resource.mount_point}  ext3  defaults  1 2\n"

      allow(::File).to receive(:foreach).with("/etc/fstab").and_yield(fstab1).and_yield(fstab2)

      @provider.load_current_resource
      expect(@provider.current_resource.enabled).to be_truthy
    end

    it "should set enabled to true if the mount point is not last in fstab and mount_point is a substring of another mount" do
      fstab1 = "#{@new_resource.device} #{@new_resource.mount_point}  ext3  defaults  1 2\n"
      fstab2 = "/dev/sdy1  /tmp/foo/bar  ext3  defaults  1 2\n"

      allow(::File).to receive(:foreach).with("/etc/fstab").and_yield(fstab1).and_yield(fstab2)

      @provider.load_current_resource
      expect(@provider.current_resource.enabled).to be_truthy
    end

    it "should set enabled to true if the symlink target is in fstab" do
      target = "/dev/mapper/target"

      allow(::File).to receive(:symlink?).with("#{@new_resource.device}").and_return(true)
      allow(::File).to receive(:readlink).with("#{@new_resource.device}").and_return(target)

      fstab = "/dev/sdz1  /tmp/foo ext3  defaults  1 2\n"

      allow(::File).to receive(:foreach).with("/etc/fstab").and_yield fstab

      @provider.load_current_resource
      expect(@provider.current_resource.enabled).to be_truthy
    end

    it "should set enabled to true if the symlink target is relative and is in fstab - CHEF-4957" do
      target = "xsdz1"

      allow(::File).to receive(:symlink?).with("#{@new_resource.device}").and_return(true)
      allow(::File).to receive(:readlink).with("#{@new_resource.device}").and_return(target)

      fstab = "/dev/sdz1  /tmp/foo ext3  defaults  1 2\n"

      allow(::File).to receive(:foreach).with("/etc/fstab").and_yield fstab

      @provider.load_current_resource
      expect(@provider.current_resource.enabled).to be_truthy
    end

    it "should set enabled to false if the mount point is not in fstab" do
      fstab = "/dev/sdy1  #{@new_resource.mount_point}  ext3  defaults  1 2\n"
      allow(::File).to receive(:foreach).with("/etc/fstab").and_yield fstab

      @provider.load_current_resource
      expect(@provider.current_resource.enabled).to be_falsey
    end

    it "should ignore commented lines in fstab " do
       fstab = "\# #{@new_resource.device}  #{@new_resource.mount_point}  ext3  defaults  1 2\n"
       allow(::File).to receive(:foreach).with("/etc/fstab").and_yield fstab

       @provider.load_current_resource
       expect(@provider.current_resource.enabled).to be_falsey
     end

    it "should set enabled to false if the mount point is not last in fstab" do
      line_1 = "#{@new_resource.device} #{@new_resource.mount_point}  ext3  defaults  1 2\n"
      line_2 = "/dev/sdy1 #{@new_resource.mount_point}  ext3  defaults  1 2\n"
      allow(::File).to receive(:foreach).with("/etc/fstab").and_yield(line_1).and_yield(line_2)

      @provider.load_current_resource
      expect(@provider.current_resource.enabled).to be_falsey
    end

    it "should not mangle the mount options if the device in fstab is a symlink" do
      # expand the target path to correct specs on Windows
      target = "/dev/mapper/target"
      options = "rw,noexec,noauto"

      allow(::File).to receive(:symlink?).with(@new_resource.device).and_return(true)
      allow(::File).to receive(:readlink).with(@new_resource.device).and_return(target)

      fstab = "#{@new_resource.device} #{@new_resource.mount_point} #{@new_resource.fstype} #{options} 1 2\n"
      allow(::File).to receive(:foreach).with("/etc/fstab").and_yield fstab
      @provider.load_current_resource
      expect(@provider.current_resource.options).to eq(options.split(','))
    end

    it "should not mangle the mount options if the symlink target is in fstab" do
      target = ::File.expand_path("/dev/mapper/target")
      options = "rw,noexec,noauto"

      allow(::File).to receive(:symlink?).with(@new_resource.device).and_return(true)
      allow(::File).to receive(:readlink).with(@new_resource.device).and_return(target)

      fstab = "#{target} #{@new_resource.mount_point} #{@new_resource.fstype} #{options} 1 2\n"
      allow(::File).to receive(:foreach).with("/etc/fstab").and_yield fstab
      @provider.load_current_resource
      expect(@provider.current_resource.options).to eq(options.split(','))
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
        expect(@provider).to receive(:shell_out!).with("mount -t ext3 -o defaults /dev/sdz1 /tmp/foo")
        @provider.mount_fs()
      end

      it "should mount the filesystem with options if options were passed" do
        options = "rw,noexec,noauto"
        @new_resource.options(%w{rw noexec noauto})
        expect(@provider).to receive(:shell_out!).with("mount -t ext3 -o rw,noexec,noauto /dev/sdz1 /tmp/foo")
        @provider.mount_fs()
      end

      it "should mount the filesystem specified by uuid", :not_supported_on_solaris do
        status = double(:stdout => "/dev/sdz1\n", :exitstatus => 1)
        @new_resource.device "d21afe51-a0fe-4dc6-9152-ac733763ae0a"
        @new_resource.device_type :uuid
        allow(@provider).to receive(:shell_out).with("/sbin/findfs UUID=d21afe51-a0fe-4dc6-9152-ac733763ae0a").and_return(status)
        @stdout_mock = double('stdout mock')
        allow(@stdout_mock).to receive(:each).and_yield("#{@new_resource.device} on #{@new_resource.mount_point}")
        expect(@provider).to receive(:shell_out!).with("mount -t #{@new_resource.fstype} -o defaults -U #{@new_resource.device} #{@new_resource.mount_point}").and_return(@stdout_mock)
        @provider.mount_fs()
      end

      it "should not mount the filesystem if it is mounted" do
        allow(@current_resource).to receive(:mounted).and_return(true)
        expect(@provider).not_to receive(:shell_out!)
        @provider.mount_fs()
      end

    end

    describe "umount_fs" do
      it "should umount the filesystem if it is mounted" do
        @current_resource.mounted(true)
        expect(@provider).to receive(:shell_out!).with("umount /tmp/foo")
        @provider.umount_fs()
      end

      it "should not umount the filesystem if it is not mounted" do
        @current_resource.mounted(false)
        expect(@provider).not_to receive(:shell_out!)
        @provider.umount_fs()
      end
    end

    describe "remount_fs" do
      it "should use mount -o remount if remount is supported" do
        @new_resource.supports({:remount => true})
        @current_resource.mounted(true)
        expect(@provider).to receive(:shell_out!).with("mount -o remount,defaults #{@new_resource.mount_point}")
        @provider.remount_fs
      end

      it "should use mount -o remount with new mount options if remount is supported" do
        @new_resource.supports({:remount => true})
        options = "rw,noexec,noauto"
        @new_resource.options(%w{rw noexec noauto})
        @current_resource.mounted(true)
        expect(@provider).to receive(:shell_out!).with("mount -o remount,rw,noexec,noauto #{@new_resource.mount_point}")
        @provider.remount_fs
      end

      it "should umount and mount if remount is not supported" do
        @new_resource.supports({:remount => false})
        @current_resource.mounted(true)
        expect(@provider).to receive(:umount_fs)
        expect(@provider).to receive(:sleep).with(1)
        expect(@provider).to receive(:mount_fs)
        @provider.remount_fs()
      end

      it "should not try to remount at all if mounted is false" do
        @current_resource.mounted(false)
        expect(@provider).not_to receive(:shell_out!)
        expect(@provider).not_to receive(:umount_fs)
        expect(@provider).not_to receive(:mount_fs)
        @provider.remount_fs()
      end
    end

    describe "when enabling the fs" do
      it "should enable if enabled isn't true" do
        @current_resource.enabled(false)

        @fstab = StringIO.new
        allow(::File).to receive(:open).with("/etc/fstab", "a").and_yield(@fstab)
        @provider.enable_fs
        expect(@fstab.string).to match(%r{^/dev/sdz1\s+/tmp/foo\s+ext3\s+defaults\s+0\s+2\s*$})
      end

      it "should not enable if enabled is true and resources match" do
        @current_resource.enabled(true)
        @current_resource.fstype("ext3")
        @current_resource.options(["defaults"])
        @current_resource.dump(0)
        @current_resource.pass(2)
        expect(::File).not_to receive(:open).with("/etc/fstab", "a")

        @provider.enable_fs
      end

      it "should enable if enabled is true and resources do not match" do
        @current_resource.enabled(true)
        @current_resource.fstype("auto")
        @current_resource.options(["defaults"])
        @current_resource.dump(0)
        @current_resource.pass(2)
        @fstab = StringIO.new
        allow(::File).to receive(:readlines).and_return([])
        expect(::File).to receive(:open).once.with("/etc/fstab", "w").and_yield(@fstab)
        expect(::File).to receive(:open).once.with("/etc/fstab", "a").and_yield(@fstab)

        @provider.enable_fs
      end
    end

    describe "when disabling the fs" do
      it "should disable if enabled is true" do
        @current_resource.enabled(true)

        other_mount = "/dev/sdy1  /tmp/foo  ext3  defaults  1 2\n"
        this_mount = "/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n"

        @fstab_read = [this_mount, other_mount]
        allow(::File).to receive(:readlines).with("/etc/fstab").and_return(@fstab_read)
        @fstab_write = StringIO.new
        allow(::File).to receive(:open).with("/etc/fstab", "w").and_yield(@fstab_write)

        @provider.disable_fs
        expect(@fstab_write.string).to match(Regexp.escape(other_mount))
        expect(@fstab_write.string).not_to match(Regexp.escape(this_mount))
      end

      it "should disable if enabled is true and ignore commented lines" do
        @current_resource.enabled(true)

        fstab_read = [%q{/dev/sdy1 /tmp/foo  ext3  defaults  1 2},
                      %q{/dev/sdz1 /tmp/foo  ext3  defaults  1 2},
                      %q{#/dev/sdz1 /tmp/foo  ext3  defaults  1 2}]
        fstab_write = StringIO.new

        allow(::File).to receive(:readlines).with("/etc/fstab").and_return(fstab_read)
        allow(::File).to receive(:open).with("/etc/fstab", "w").and_yield(fstab_write)

        @provider.disable_fs
        expect(fstab_write.string).to match(%r{^/dev/sdy1 /tmp/foo  ext3  defaults  1 2$})
        expect(fstab_write.string).to match(%r{^#/dev/sdz1 /tmp/foo  ext3  defaults  1 2$})
        expect(fstab_write.string).not_to match(%r{^/dev/sdz1 /tmp/foo  ext3  defaults  1 2$})
      end

      it "should disable only the last entry if enabled is true" do
        allow(@current_resource).to receive(:enabled).and_return(true)
        fstab_read = ["/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n",
                      "/dev/sdy1 /tmp/foo  ext3  defaults  1 2\n",
                      "/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n",
                      "/dev/sdz1 /tmp/foobar  ext3  defaults  1 2\n"]

        fstab_write = StringIO.new
        allow(::File).to receive(:readlines).with("/etc/fstab").and_return(fstab_read)
        allow(::File).to receive(:open).with("/etc/fstab", "w").and_yield(fstab_write)

        @provider.disable_fs
        expect(fstab_write.string).to eq("/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n" +
          "/dev/sdy1 /tmp/foo  ext3  defaults  1 2\n" +
          "/dev/sdz1 /tmp/foobar  ext3  defaults  1 2\n")
      end

      it "should not disable if enabled is false" do
        allow(@current_resource).to receive(:enabled).and_return(false)

        allow(::File).to receive(:readlines).with("/etc/fstab").and_return([])
        expect(::File).not_to receive(:open).and_yield(@fstab)

        @provider.disable_fs
      end
    end
  end
end
