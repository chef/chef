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

describe Chef::Provider::Mount::Solaris do
  let(:node) { Chef::Node.new }

  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  let(:device_type) { :device }

  let(:fstype) { "ufs" }

  let(:device) { "/dev/dsk/c0t2d0s7" }

  let(:mountpoint) { "/mnt/foo" }

  let(:new_resource) {
    new_resource = Chef::Resource::Mount.new(mountpoint)
    new_resource.device      device
    new_resource.device_type device_type
    new_resource.fstype      fstype

    new_resource.supports :remount => false
    new_resource
  }

  let(:provider) {
    Chef::Provider::Mount::Solaris.new(new_resource, run_context)
  }

  let(:vfstab_file_contents) {
    <<-EOF.gsub /^\s*/, ''
    #device         device          mount           FS      fsck    mount   mount
    #to mount       to fsck         point           type    pass    at boot options
    #
    fd      -       /dev/fd fd      -       no      -
    /proc   -       /proc   proc    -       no      -
    # swap
    /dev/dsk/c0t0d0s1       -       -       swap    -       no      -
    # root
    /dev/dsk/c0t0d0s0       /dev/rdsk/c0t0d0s0      /       ufs     1       no      -
    # tmpfs
    swap    -       /tmp    tmpfs   -       yes     -
    # nfs
    cartman:/share2         -                       /cartman        nfs     -       yes     rw,soft
    # ufs
    /dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
    EOF
  }

  let(:vfstab_file) {
    t = Tempfile.new("rspec-vfstab")
    t.write(vfstab_file_contents)
    t.close
    t
  }

  # TODO: test CIFS/SMB mount:
  # //solarsystem/tmp on /mnt type smbfs read/write/setuid/devices/dev=5080000 on Tue Mar 29 11:40:18 2011

  let(:mount_output) {
    <<-EOF.gsub /^\s*/, ''
    /dev/dsk/c0t0d0s0 on / type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200000 on Tue Jul 31 22:34:46 2012
    /dev/dsk/c0t2d0s7 on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200007 on Tue Jul 31 22:34:46 2012
    EOF
  }

  before do
    stub_const("Chef::Provider::Mount::Solaris::VFSTAB", vfstab_file.path )
    provider.stub(:shell_out!).with("mount -v").and_return(OpenStruct.new(:stdout => mount_output))
    File.stub(:symlink?).with(device).and_return(false)
    File.stub(:exist?).with(device).and_return(true)
    File.stub(:exist?).with(mountpoint).and_return(true)
    expect(File).to_not receive(:exists?)
  end

  describe "#define_resource_requirements" do
    before do
      # we're not testing the actions so stub them all out
      [:mount_fs, :umount_fs, :remount_fs, :enable_fs, :disable_fs].each {|m| provider.stub(m) }
    end

    context "when the device_type is :label" do
      let(:device_type) { :label }

      it "should raise an error" do
        expect { provider.define_resource_requirements }.to raise_error(Chef::Exceptions::Mount)
      end
    end

    context "when the device_type is :uuid" do
      let(:device_type) { :uuid }

      it "should raise an error" do
        expect { provider.define_resource_requirements }.to raise_error(Chef::Exceptions::Mount)
      end
    end

    it "run_action(:mount) should raise an error if the device does not exist" do
      File.stub(:exist?).with(device).and_return(false)
      expect { provider.run_action(:mount) }.to raise_error(Chef::Exceptions::Mount)
    end

    it "run_action(:remount) should raise an error if the device does not exist" do
      File.stub(:exist?).with(device).and_return(false)
      expect { provider.run_action(:remount) }.to raise_error(Chef::Exceptions::Mount)
    end

    it "run_action(:mount) should raise an error if the mountpoint does not exist" do
      File.stub(:exist?).with(mountpoint).and_return false
      expect { provider.run_action(:mount) }.to raise_error(Chef::Exceptions::Mount)
    end

    it "run_action(:remount) should raise an error if the mountpoint does not exist" do
      File.stub(:exist?).with(mountpoint).and_return false
      expect { provider.run_action(:remount) }.to raise_error(Chef::Exceptions::Mount)
    end

    context "when the device is a tmpfs" do
      let(:fstype) { "tmpfs" }
      let(:device) { "swap" }

      before do
        expect(File).to_not receive(:exist?).with(device)
      end

      it "run_action(:mount) should not raise an error" do
        expect { provider.run_action(:mount) }.to_not raise_error
      end

      it "run_action(:remount) should not raise an error" do
        expect { provider.run_action(:remount) }.to_not raise_error
      end
    end

  end

  describe "#load_current_resource" do
    context "when loading a normal UFS filesystem" do

      before do
        provider.load_current_resource
      end

      it "should create a current_resource of type Chef::Resource::Mount" do
        expect(provider.current_resource).to be_a(Chef::Resource::Mount)
      end

      it "should set the name on the current_resource" do
        provider.current_resource.name.should == mountpoint
      end

      it "should set the mount_point on the current_resource" do
        provider.current_resource.mount_point.should == mountpoint
      end

      it "should set the device on the current_resource" do
        provider.current_resource.device.should == device
      end

      it "should set the device_type on the current_resource" do
        provider.current_resource.device_type.should == device_type
      end

      it "should set the mounted status on the current_resource" do
        expect(provider.current_resource.mounted).to be_true
      end

      it "should set the enabled status on the current_resource" do
        expect(provider.current_resource.enabled).to be_true
      end

      it "should set the fstype field on the current_resource" do
        expect(provider.current_resource.fstype).to eql("ufs")
      end

      it "should set the options field on the current_resource" do
        expect(provider.current_resource.options).to eql(["-", "noauto"])
      end

      it "should set the pass field on the current_resource" do
        expect(provider.current_resource.pass).to eql(2)
      end

      #    describe "when dealing with network mounts" do
      #      { "nfs" => "nfsserver:/vol/path",
      #        "cifs" => "//cifsserver/share" }.each do |type, fs_spec|
      #        it "should detect network fs_spec (#{type})" do
      #          new_resource.device fs_spec
      #          provider.network_device?.should be_true
      #        end
      #
      #        it "should ignore trailing slash and set mounted to true for network mount (#{type})" do
      #          new_resource.device fs_spec
      #          provider.stub(:shell_out!).and_return(OpenStruct.new(:stdout => "#{fs_spec}/ on /tmp/foo type #{type} (rw)\n"))
      #          provider.load_current_resource
      #          provider.current_resource.mounted.should be_true
      #        end
      #      end
      #    end

      it "should not throw an exception when the device does not exist - CHEF-1565" do
        File.stub(:exist?).with(device).and_return(false)
        expect { provider.load_current_resource }.to_not raise_error
      end

      it "should not throw an exception when the mount point does not exist" do
        File.stub(:exist?).with(mountpoint).and_return false
        expect { provider.load_current_resource }.to_not raise_error
      end
    end

    context "when the device is symlink" do

      let(:target) { "/dev/mapper/target" }

      let(:mount_output) {
        <<-EOF.gsub /^\s*/, ''
        #{target} on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200007 on Tue Jul 31 22:34:46 2012
        EOF
      }

      before do
        File.should_receive(:symlink?).with(device).at_least(:once).and_return(true)
        File.should_receive(:readlink).with(device).at_least(:once).and_return(target)

        provider.load_current_resource()
      end

      it "should set mounted true if the symlink target of the device is found in the mounts list" do
        expect(provider.current_resource.mounted).to be_true
      end
    end

    context "when the device is a relative symlink" do
      let(:target) { "foo" }

      let(:absolute_target) { File.expand_path(target, File.dirname(device)) }

      let(:mount_output) {
        <<-EOF.gsub /^\s*/, ''
        #{absolute_target} on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200007 on Tue Jul 31 22:34:46 2012
        EOF
      }

      before do
        File.should_receive(:symlink?).with(device).at_least(:once).and_return(true)
        File.should_receive(:readlink).with(device).at_least(:once).and_return(target)

        provider.load_current_resource()
      end

      it "should set mounted true if the symlink target of the device is found in the mounts list" do
        expect(provider.current_resource.mounted).to be_true
      end
    end

    context "when the matching mount point is last in the mounts list" do
      let(:mount_output) {
        <<-EOF.gsub /^\s*/, ''
        /dev/dsk/c0t0d0s0 on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200000 on Tue Jul 31 22:34:46 2012
        /dev/dsk/c0t2d0s7 on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200007 on Tue Jul 31 22:34:46 2012
        EOF
      }
      it "should set mounted true" do
        provider.load_current_resource()
        provider.current_resource.mounted.should be_true
      end
    end

    context "when the matching mount point is not last in the mounts list" do
      let(:mount_output) {
        <<-EOF.gsub /^\s*/, ''
        /dev/dsk/c0t2d0s7 on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200007 on Tue Jul 31 22:34:46 2012
        /dev/dsk/c0t0d0s0 on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200000 on Tue Jul 31 22:34:46 2012
        EOF
      }
      it "should set mounted false" do
        provider.load_current_resource()
        provider.current_resource.mounted.should be_false
      end
    end

    context "when the matching mount point is not in the mounts list (mountpoint wrong)" do
      let(:mount_output) {
        <<-EOF.gsub /^\s*/, ''
        /dev/dsk/c0t2d0s7 on /mnt/foob type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200007 on Tue Jul 31 22:34:46 2012
        EOF
      }
      it "should set mounted false" do
        provider.load_current_resource()
        provider.current_resource.mounted.should be_false
      end
    end

    context "when the matching mount point is not in the mounts list (raw device wrong)" do
      let(:mount_output) {
        <<-EOF.gsub /^\s*/, ''
        /dev/dsk/c0t2d0s72 on /mnt/foo type ufs read/write/setuid/intr/largefiles/xattr/onerror=panic/dev=2200007 on Tue Jul 31 22:34:46 2012
        EOF
      }
      it "should set mounted false" do
        provider.load_current_resource()
        provider.current_resource.mounted.should be_false
      end
    end

    context "when the mount point is last in fstab" do
      let(:vfstab_file_contents) {
        <<-EOF.gsub /^\s*/, ''
        /dev/dsk/c0t2d0s72       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
        /dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
        EOF
      }

      it "should set enabled to true" do
        provider.load_current_resource
        provider.current_resource.enabled.should be_true
      end
    end

    context "when the mount point is not last in fstab and is a substring of another mount" do
      let(:vfstab_file_contents) {
        <<-EOF.gsub /^\s*/, ''
        /dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
        /dev/dsk/c0t2d0s72       /dev/rdsk/c0t2d0s7      /mnt/foo/bar            ufs     2       yes     -
        EOF
      }

      it "should set enabled to true" do
        provider.load_current_resource
        provider.current_resource.enabled.should be_true
      end
    end

    context "when the mount point is not last in fstab" do
      let(:vfstab_file_contents) {
        <<-EOF.gsub /^\s*/, ''
        /dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
        /dev/dsk/c0t2d0s72       /dev/rdsk/c0t2d0s72      /mnt/foo            ufs     2       yes     -
        EOF
      }

      it "should set enabled to false" do
        provider.load_current_resource
        provider.current_resource.enabled.should be_false
      end
    end

    context "when the mount point is not in fstab, but the mountpoint is a substring of one that is" do
      let(:vfstab_file_contents) {
        <<-EOF.gsub /^\s*/, ''
        /dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foob            ufs     2       yes     -
        EOF
      }

      it "should set enabled to false" do
        provider.load_current_resource
        provider.current_resource.enabled.should be_false
      end
    end

    context "when the mount point is not in fstab, but the device is a substring of one that is" do
      let(:vfstab_file_contents) {
        <<-EOF.gsub /^\s*/, ''
        /dev/dsk/c0t2d0s72       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
        EOF
      }

      it "should set enabled to false" do
        provider.load_current_resource
        provider.current_resource.enabled.should be_false
      end
    end

    context "when the mountpoint line is commented out" do
      let(:vfstab_file_contents) {
        <<-EOF.gsub /^\s*/, ''
        #/dev/dsk/c0t2d0s7       /dev/rdsk/c0t2d0s7      /mnt/foo            ufs     2       yes     -
        EOF
      }

      it "should set enabled to false" do
        provider.load_current_resource
        provider.current_resource.enabled.should be_false
      end
    end

    it "should set enabled to true if the symlink target is in fstab" do
      target = "/dev/mapper/target"

      File.stub(:symlink?).with("#{new_resource.device}").and_return(true)
      File.stub(:readlink).with("#{new_resource.device}").and_return(target)

      fstab = "/dev/sdz1  /tmp/foo ext3  defaults  1 2\n"

      File.stub(:foreach).with("/etc/fstab").and_yield fstab

      provider.load_current_resource
      provider.current_resource.enabled.should be_true
    end

    it "should set enabled to true if the symlink target is relative and is in fstab - CHEF-4957" do
      target = "xsdz1"

      File.stub(:symlink?).with("#{new_resource.device}").and_return(true)
      File.stub(:readlink).with("#{new_resource.device}").and_return(target)

      fstab = "/dev/sdz1  /tmp/foo ext3  defaults  1 2\n"

      File.stub(:foreach).with("/etc/fstab").and_yield fstab

      provider.load_current_resource
      provider.current_resource.enabled.should be_true
    end

    it "should not mangle the mount options if the device in fstab is a symlink" do
      # expand the target path to correct specs on Windows
      target = "/dev/mapper/target"
      options = "rw,noexec,noauto"

      File.stub(:symlink?).with(new_resource.device).and_return(true)
      File.stub(:readlink).with(new_resource.device).and_return(target)

      fstab = "#{new_resource.device} #{new_resource.mount_point} #{new_resource.fstype} #{options} 1 2\n"
      File.stub(:foreach).with("/etc/fstab").and_yield fstab
      provider.load_current_resource
      provider.current_resource.options.should eq(options.split(','))
    end

    it "should not mangle the mount options if the symlink target is in fstab" do
      target = File.expand_path("/dev/mapper/target")
      options = "rw,noexec,noauto"

      File.stub(:symlink?).with(new_resource.device).and_return(true)
      File.stub(:readlink).with(new_resource.device).and_return(target)

      fstab = "#{target} #{new_resource.mount_point} #{new_resource.fstype} #{options} 1 2\n"
      File.stub(:foreach).with("/etc/fstab").and_yield fstab
      provider.load_current_resource
      provider.current_resource.options.should eq(options.split(','))
    end
  end

  context "after the mount's state has been discovered" do
    before do
      @current_resource = Chef::Resource::Mount.new("/tmp/foo")
      @current_resource.device       "/dev/sdz1"
      @current_resource.device_type  :device
      @current_resource.fstype       "ext3"

      provider.current_resource = @current_resource
    end

    describe "mount_fs" do
      it "should mount the filesystem if it is not mounted" do
        provider.should_receive(:shell_out!).with("mount -t ext3 -o defaults /dev/sdz1 /tmp/foo")
        provider.mount_fs()
      end

      it "should mount the filesystem with options if options were passed" do
        options = "rw,noexec,noauto"
        new_resource.options(%w{rw noexec noauto})
        provider.should_receive(:shell_out!).with("mount -t ext3 -o rw,noexec,noauto /dev/sdz1 /tmp/foo")
        provider.mount_fs()
      end

      it "should mount the filesystem specified by uuid" do
        new_resource.device "d21afe51-a0fe-4dc6-9152-ac733763ae0a"
        new_resource.device_type :uuid
        @stdout_findfs = double("STDOUT", :first => "/dev/sdz1")
        provider.stub(:popen4).with("/sbin/findfs UUID=d21afe51-a0fe-4dc6-9152-ac733763ae0a").and_yield(@pid,@stdin,@stdout_findfs,@stderr).and_return(@status)
        @stdout_mock = double('stdout mock')
        @stdout_mock.stub(:each).and_yield("#{new_resource.device} on #{new_resource.mount_point}")
        provider.should_receive(:shell_out!).with("mount -t #{new_resource.fstype} -o defaults -U #{new_resource.device} #{new_resource.mount_point}").and_return(@stdout_mock)
        provider.mount_fs()
      end

      it "should not mount the filesystem if it is mounted" do
        @current_resource.stub(:mounted).and_return(true)
        provider.should_not_receive(:shell_out!)
        provider.mount_fs()
      end

    end

    describe "umount_fs" do
      it "should umount the filesystem if it is mounted" do
        @current_resource.mounted(true)
        provider.should_receive(:shell_out!).with("umount /tmp/foo")
        provider.umount_fs()
      end

      it "should not umount the filesystem if it is not mounted" do
        @current_resource.mounted(false)
        provider.should_not_receive(:shell_out!)
        provider.umount_fs()
      end
    end

    describe "remount_fs" do
      it "should use mount -o remount if remount is supported" do
        new_resource.supports({:remount => true})
        @current_resource.mounted(true)
        provider.should_receive(:shell_out!).with("mount -o remount #{new_resource.mount_point}")
        provider.remount_fs
      end

      it "should umount and mount if remount is not supported" do
        new_resource.supports({:remount => false})
        @current_resource.mounted(true)
        provider.should_receive(:umount_fs)
        provider.should_receive(:sleep).with(1)
        provider.should_receive(:mount_fs)
        provider.remount_fs()
      end

      it "should not try to remount at all if mounted is false" do
        @current_resource.mounted(false)
        provider.should_not_receive(:shell_out!)
        provider.should_not_receive(:umount_fs)
        provider.should_not_receive(:mount_fs)
        provider.remount_fs()
      end
    end

    describe "when enabling the fs" do
      it "should enable if enabled isn't true" do
        @current_resource.enabled(false)

        @fstab = StringIO.new
        File.stub(:open).with("/etc/fstab", "a").and_yield(@fstab)
        provider.enable_fs
        @fstab.string.should match(%r{^/dev/sdz1\s+/tmp/foo\s+ext3\s+defaults\s+0\s+2\s*$})
      end

      it "should not enable if enabled is true and resources match" do
        @current_resource.enabled(true)
        @current_resource.fstype("ext3")
        @current_resource.options(["defaults"])
        @current_resource.dump(0)
        @current_resource.pass(2)
        File.should_not_receive(:open).with("/etc/fstab", "a")

        provider.enable_fs
      end

      it "should enable if enabled is true and resources do not match" do
        @current_resource.enabled(true)
        @current_resource.fstype("auto")
        @current_resource.options(["defaults"])
        @current_resource.dump(0)
        @current_resource.pass(2)
        @fstab = StringIO.new
        File.stub(:readlines).and_return([])
        File.should_receive(:open).once.with("/etc/fstab", "w").and_yield(@fstab)
        File.should_receive(:open).once.with("/etc/fstab", "a").and_yield(@fstab)

        provider.enable_fs
      end
    end

    describe "when disabling the fs" do
      it "should disable if enabled is true" do
        @current_resource.enabled(true)

        other_mount = "/dev/sdy1  /tmp/foo  ext3  defaults  1 2\n"
        this_mount = "/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n"

        @fstab_read = [this_mount, other_mount]
        File.stub(:readlines).with("/etc/fstab").and_return(@fstab_read)
        @fstab_write = StringIO.new
        File.stub(:open).with("/etc/fstab", "w").and_yield(@fstab_write)

        provider.disable_fs
        @fstab_write.string.should match(Regexp.escape(other_mount))
        @fstab_write.string.should_not match(Regexp.escape(this_mount))
      end

      it "should disable if enabled is true and ignore commented lines" do
        @current_resource.enabled(true)

        fstab_read = [%q{/dev/sdy1 /tmp/foo  ext3  defaults  1 2},
                      %q{/dev/sdz1 /tmp/foo  ext3  defaults  1 2},
                      %q{#/dev/sdz1 /tmp/foo  ext3  defaults  1 2}]
        fstab_write = StringIO.new

        File.stub(:readlines).with("/etc/fstab").and_return(fstab_read)
        File.stub(:open).with("/etc/fstab", "w").and_yield(fstab_write)

        provider.disable_fs
        fstab_write.string.should match(%r{^/dev/sdy1 /tmp/foo  ext3  defaults  1 2$})
        fstab_write.string.should match(%r{^#/dev/sdz1 /tmp/foo  ext3  defaults  1 2$})
        fstab_write.string.should_not match(%r{^/dev/sdz1 /tmp/foo  ext3  defaults  1 2$})
      end

      it "should disable only the last entry if enabled is true" do
        @current_resource.stub(:enabled).and_return(true)
        fstab_read = ["/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n",
                      "/dev/sdy1 /tmp/foo  ext3  defaults  1 2\n",
                      "/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n"]

        fstab_write = StringIO.new
        File.stub(:readlines).with("/etc/fstab").and_return(fstab_read)
        File.stub(:open).with("/etc/fstab", "w").and_yield(fstab_write)

        provider.disable_fs
        fstab_write.string.should == "/dev/sdz1 /tmp/foo  ext3  defaults  1 2\n/dev/sdy1 /tmp/foo  ext3  defaults  1 2\n"
      end

      it "should not disable if enabled is false" do
        @current_resource.stub(:enabled).and_return(false)

        File.stub(:readlines).with("/etc/fstab").and_return([])
        File.should_not_receive(:open).and_yield(@fstab)

        provider.disable_fs
      end
    end
  end
end
